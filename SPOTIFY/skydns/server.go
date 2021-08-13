// Copyright (c) 2014 The SkyDNS Authors. All rights reserved.
// Use of this source code is governed by The MIT License (MIT) that can be
// found in the LICENSE file.

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net"
	"strings"
	"sync"
	"time"

	"github.com/coreos/go-etcd/etcd"
	"github.com/miekg/dns"
	"github.com/skynetservices/skydns/cache"
	"github.com/skynetservices/skydns/msg"
)

type server struct {
	client *etcd.Client
	config *Config
	group  *sync.WaitGroup
	scache *cache.Cache
	rcache *cache.Cache
}

// NewServer returns a new SkyDNS server.
func NewServer(config *Config, client *etcd.Client) *server {
	return &server{client: client, config: config, group: new(sync.WaitGroup),
		scache: cache.New(config.SCache, 0),
		rcache: cache.New(config.RCache, config.RCacheTtl),
	}
}

// Run is a blocking operation that starts the server listening on the DNS ports.
func (s *server) Run() error {
	mux := dns.NewServeMux()
	mux.Handle(".", s)

	s.group.Add(2)
	go runDNSServer(s.group, mux, "tcp", s.config.DnsAddr, s.config.ReadTimeout)
	go runDNSServer(s.group, mux, "udp", s.config.DnsAddr, s.config.ReadTimeout)
	if s.config.DNSSEC == "" {
		s.config.log.Printf("ready for queries on %s for %s [rcache %d]", s.config.Domain, s.config.DnsAddr, s.config.RCache)
	} else {
		s.config.log.Printf("ready for queries on %s for %s [rcache %d], signing with %s [scache %d]", s.config.Domain, s.config.DnsAddr, s.config.RCache, s.config.DNSSEC, s.config.SCache)
	}

	s.group.Wait()
	return nil
}

// Stop stops a server.
func (s *server) Stop() {
	// TODO(miek)
	//s.group.Add(-2)
}

func runDNSServer(group *sync.WaitGroup, mux *dns.ServeMux, net, addr string, readTimeout time.Duration) {
	defer group.Done()

	server := &dns.Server{
		Addr:        addr,
		Net:         net,
		Handler:     mux,
		ReadTimeout: readTimeout,
	}
	if err := server.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}

// ServeDNS is the handler for DNS requests, responsible for parsing DNS request, possibly forwarding
// it to a real dns server and returning a response.
func (s *server) ServeDNS(w dns.ResponseWriter, req *dns.Msg) {
	m := new(dns.Msg)
	m.SetReply(req)
	m.Authoritative = true
	m.RecursionAvailable = true
	m.Compress = true
	bufsize := uint16(512)
	dnssec := false
	if o := req.IsEdns0(); o != nil {
		bufsize = o.UDPSize()
		dnssec = o.Do()
	}
	if bufsize < 512 {
		bufsize = 512
	}
	// Check cache first.
	key := cache.QuestionKey(req.Question[0])
	a1, e1, exp, hit := s.rcache.Search(key)
	if hit {
		// Cache hit! \o/
		if time.Since(exp) < 0 {
			m.Answer = a1
			m.Extra = e1
			if dnssec {
				StatsDnssecOkCount.Inc(1)
				if s.config.PubKey != nil {
					s.Denial(m)
					s.sign(m, bufsize)
				}
			}
			if err := w.WriteMsg(m); err != nil {
				s.config.log.Errorf("failure to return reply %q", err)
			}
			return
		}
		// Expired! /o\
		s.rcache.Remove(key)
	}

	q := req.Question[0]
	name := strings.ToLower(q.Name)
	StatsRequestCount.Inc(1)
	if verbose {
		s.config.log.Infof("received DNS Request for %q from %q with type %d", q.Name, w.RemoteAddr(), q.Qtype)
	}
	// If the qname is local.dns.skydns.local. and s.config.Local != "", substitute that name.
	if s.config.Local != "" && name == s.config.localDomain {
		name = s.config.Local
	}

	if q.Qtype == dns.TypePTR && strings.HasSuffix(name, ".in-addr.arpa.") || strings.HasSuffix(name, ".ip6.arpa.") {
		s.ServeDNSReverse(w, req)
		return
	}

	if q.Qclass != dns.ClassCHAOS && !strings.HasSuffix(name, s.config.Domain) {
		s.ServeDNSForward(w, req)
		return
	}

	defer func() {
		if m.Rcode == dns.RcodeServerFailure {
			if err := w.WriteMsg(m); err != nil {
				s.config.log.Errorf("failure to return reply %q", err)
			}
			return
		}
		// Set TTL to the minimum of the RRset.
		minttl := s.config.Ttl
		if len(m.Answer) > 1 {
			for _, r := range m.Answer {
				if r.Header().Ttl < minttl {
					minttl = r.Header().Ttl
				}
			}
			for _, r := range m.Answer {
				r.Header().Ttl = minttl
			}
		}

		s.rcache.InsertMessage(cache.QuestionKey(req.Question[0]), m.Answer, m.Extra)

		if dnssec {
			StatsDnssecOkCount.Inc(1)
			if s.config.PubKey != nil {
				s.Denial(m)
				s.sign(m, bufsize)
			}
		}
		if m.Len() > int(bufsize) {
			// TODO(miek): this is a little brain dead, better is to not added
			// RRs in the message in the first place.
			m.Truncated = true
		}
		if err := w.WriteMsg(m); err != nil {
			s.config.log.Errorf("failure to return reply %q", err)
		}
	}()

	if name == s.config.Domain {
		if q.Qtype == dns.TypeSOA {
			m.Answer = []dns.RR{s.NewSOA()}
			return
		}
		if q.Qtype == dns.TypeDNSKEY {
			if s.config.PubKey != nil {
				m.Answer = []dns.RR{s.config.PubKey}
				return
			}
		}
	}
	if q.Qclass == dns.ClassCHAOS {
		if q.Qtype == dns.TypeTXT {
			switch name {
			case "authors.bind.":
				fallthrough
			case s.config.Domain:
				hdr := dns.RR_Header{Name: q.Name, Rrtype: dns.TypeTXT, Class: dns.ClassCHAOS, Ttl: 0}
				authors := []string{"Erik St. Martin", "Brian Ketelsen", "Miek Gieben", "Michael Crosby"}
				for _, a := range authors {
					m.Answer = append(m.Answer, &dns.TXT{Hdr: hdr, Txt: []string{a}})
				}
				for j := 0; j < len(authors)*(int(dns.Id())%4+1); j++ {
					q := int(dns.Id()) % len(authors)
					p := int(dns.Id()) % len(authors)
					if q == p {
						p = (p + 1) % len(authors)
					}
					m.Answer[q], m.Answer[p] = m.Answer[p], m.Answer[q]
				}
				return
			case "version.bind.":
				fallthrough
			case "version.server.":
				hdr := dns.RR_Header{Name: q.Name, Rrtype: dns.TypeTXT, Class: dns.ClassCHAOS, Ttl: 0}
				m.Answer = []dns.RR{&dns.TXT{Hdr: hdr, Txt: []string{"SkyDNS 2.0.0"}}}
				return
			case "hostname.bind.":
				fallthrough
			case "id.server.":
				// TODO(miek): machine name to return
				hdr := dns.RR_Header{Name: q.Name, Rrtype: dns.TypeTXT, Class: dns.ClassCHAOS, Ttl: 0}
				m.Answer = []dns.RR{&dns.TXT{Hdr: hdr, Txt: []string{"localhost"}}}
				return
			}
		}
		// still here, fail
		m.SetReply(req)
		m.SetRcode(req, dns.RcodeServerFailure)
		return
	}

	switch q.Qtype {
	case dns.TypeNS:
		if name != s.config.Domain {
			break
		}
		// Lookup s.config.DnsDomain
		records, extra, err := s.NSRecords(q, s.config.dnsDomain)
		if err != nil {
			if e, ok := err.(*etcd.EtcdError); ok {
				if e.ErrorCode == 100 {
					s.NameError(m, req)
					return
				}
			}
		}
		m.Answer = append(m.Answer, records...)
		m.Extra = append(m.Extra, extra...)
	case dns.TypeA, dns.TypeAAAA:
		records, err := s.AddressRecords(q, name, nil)
		if err != nil {
			if e, ok := err.(*etcd.EtcdError); ok {
				if e.ErrorCode == 100 {
					s.NameError(m, req)
					return
				}
			}
			if err.Error() == "incomplete CNAME chain" {
				// We can not complete the CNAME internally, *iff* there is a
				// external name in the set, take it, and try to resolve it externally.
				if len(records) == 0 {
					s.NameError(m, req)
					return
				}
				target := ""
				for _, r := range records {
					if v, ok := r.(*dns.CNAME); ok {
						if !dns.IsSubDomain(s.config.Domain, v.Target) {
							target = v.Target
							break
						}
					}
				}
				if target == "" {
					s.NameError(m, req)
					return
				}
				m1, e1 := s.Lookup(target, req.Question[0].Qtype, bufsize, dnssec)
				if e1 != nil {
					s.config.log.Errorf("%q", err)
					s.NameError(m, req)
					return
				}
				records = append(records, m1.Answer...)
			}
		}
		m.Answer = append(m.Answer, records...)
	case dns.TypeCNAME:
		records, err := s.CNAMERecords(q, name)
		if err != nil {
			if e, ok := err.(*etcd.EtcdError); ok {
				if e.ErrorCode == 100 {
					s.NameError(m, req)
					return
				}
			}
		}
		m.Answer = append(m.Answer, records...)
	default:
		fallthrough // also catch other types, so that they return NODATA
	case dns.TypeSRV, dns.TypeANY:
		records, extra, err := s.SRVRecords(q, name, bufsize, dnssec)
		if err != nil {
			if e, ok := err.(*etcd.EtcdError); ok {
				if e.ErrorCode == 100 {
					s.NameError(m, req)
					return
				}
			}
		}
		// if we are here again, check the types, because an answer may only
		// be given for SRV or ANY. All other types should return NODATA, the
		// NXDOMAIN part is handled in the above code. TODO(miek): yes this
		// can be done in a more elegant manor.
		if q.Qtype == dns.TypeSRV || q.Qtype == dns.TypeANY {
			m.Answer = append(m.Answer, records...)
			m.Extra = append(m.Extra, extra...)
		}
	}

	if len(m.Answer) == 0 { // NODATA response
		StatsNoDataCount.Inc(1)
		m.Ns = []dns.RR{s.NewSOA()}
		m.Ns[0].Header().Ttl = s.config.MinTtl
	}
}

func (s *server) AddressRecords(q dns.Question, name string, previousRecords []dns.RR) (records []dns.RR, err error) {
	path, star := msg.PathWithWildcard(name)
	r, err := s.client.Get(path, false, true)
	if err != nil {
		return nil, err
	}
	if !r.Node.Dir { // single element
		serv := new(msg.Service)
		if err := json.Unmarshal([]byte(r.Node.Value), serv); err != nil {
			s.config.log.Infof("failed to parse json: %s", err.Error())
			return nil, err
		}
		ip := net.ParseIP(serv.Host)
		ttl := s.calculateTtl(r.Node, serv)
		serv.Ttl = ttl
		serv.Key = r.Node.Key
		switch {
		case ip == nil:
			// Try to resolve as CNAME if it's not an IP.
			newRecord := serv.NewCNAME(q.Name, dns.Fqdn(serv.Host))
			if len(previousRecords) > 7 {
				s.config.log.Errorf("CNAME lookup limit of 8 exceeded for %s", newRecord)
				return nil, fmt.Errorf("exceeded CNAME lookup limit")
			}
			if s.isDuplicateCNAME(newRecord, previousRecords) {
				s.config.log.Errorf("CNAME loop detected for record %s", newRecord)
				return nil, fmt.Errorf("detected CNAME loop")
			}

			records = append(records, newRecord)
			nextRecords, err := s.AddressRecords(dns.Question{Name: dns.Fqdn(serv.Host), Qtype: q.Qtype, Qclass: q.Qclass}, strings.ToLower(dns.Fqdn(serv.Host)), append(previousRecords, newRecord))
			if err != nil {
				// This means we can not complete the CNAME, this is OK, but
				// if we return an error this will trigger an NXDOMAIN.
				// We also don't want to return the CNAME, because of the
				// no other data rule. So return nothing and let NODATA
				// kick in (via a hack).
				return records, fmt.Errorf("incomplete CNAME chain")
			}
			records = append(records, nextRecords...)
		case ip.To4() != nil && q.Qtype == dns.TypeA:
			records = append(records, serv.NewA(q.Name, ip.To4()))
		case ip.To4() == nil && q.Qtype == dns.TypeAAAA:
			records = append(records, serv.NewAAAA(q.Name, ip.To16()))
		}
		return records, nil
	}
	nodes, err := s.loopNodes(&r.Node.Nodes, strings.Split(msg.Path(name), "/"), star, nil)
	if err != nil {
		s.config.log.Infof("failed to parse json: %s", err.Error())
		return nil, err
	}
	for _, serv := range nodes {
		ip := net.ParseIP(serv.Host)
		switch {
		case ip == nil:
		case ip.To4() != nil && q.Qtype == dns.TypeA:
			records = append(records, serv.NewA(q.Name, ip.To4()))
		case ip.To4() == nil && q.Qtype == dns.TypeAAAA:
			records = append(records, serv.NewAAAA(q.Name, ip.To16()))
		}
	}
	if s.config.RoundRobin {
		switch l := len(records); l {
		case 2:
			if dns.Id()%2 == 0 {
				records[0], records[1] = records[1], records[0]
			}
		default:
			// Do a minimum of l swap, maximum of 4l swaps
			for j := 0; j < l*(int(dns.Id())%4+1); j++ {
				q := int(dns.Id()) % l
				p := int(dns.Id()) % l
				if q == p {
					p = (p + 1) % l
				}
				records[q], records[p] = records[p], records[q]
			}
		}
	}
	return records, nil
}

// NSRecords returns NS records from etcd.
func (s *server) NSRecords(q dns.Question, name string) (records []dns.RR, extra []dns.RR, err error) {
	path, star := msg.PathWithWildcard(name)
	r, err := s.client.Get(path, false, true)
	if err != nil {
		return nil, nil, err
	}
	if !r.Node.Dir { // single element
		serv := new(msg.Service)
		if err := json.Unmarshal([]byte(r.Node.Value), serv); err != nil {
			s.config.log.Infof("failed to parse json: %s", err.Error())
			return nil, nil, err
		}
		ip := net.ParseIP(serv.Host)
		ttl := s.calculateTtl(r.Node, serv)
		serv.Key = r.Node.Key
		serv.Ttl = ttl
		switch {
		case ip == nil:
			return nil, nil, fmt.Errorf("NS record must be an IP address")
		case ip.To4() != nil:
			serv.Host = msg.Domain(serv.Key)
			records = append(records, serv.NewNS(q.Name, serv.Host))
			extra = append(extra, serv.NewA(serv.Host, ip.To4()))
		case ip.To4() == nil:
			serv.Host = msg.Domain(serv.Key)
			records = append(records, serv.NewNS(q.Name, serv.Host))
			extra = append(extra, serv.NewAAAA(serv.Host, ip.To16()))
		}
		return records, extra, nil
	}

	sx, err := s.loopNodes(&r.Node.Nodes, strings.Split(msg.Path(name), "/"), star, nil)
	if err != nil || len(sx) == 0 {
		return nil, nil, err
	}
	for _, serv := range sx {
		ip := net.ParseIP(serv.Host)
		switch {
		case ip == nil:
			return nil, nil, fmt.Errorf("NS record must be an IP address")
		case ip.To4() != nil:
			serv.Host = msg.Domain(serv.Key)
			records = append(records, serv.NewNS(q.Name, serv.Host))
			extra = append(extra, serv.NewA(serv.Host, ip.To4()))
		case ip.To4() == nil:
			serv.Host = msg.Domain(serv.Key)
			records = append(records, serv.NewNS(q.Name, serv.Host))
			extra = append(extra, serv.NewAAAA(serv.Host, ip.To16()))
		}
	}
	return records, extra, nil
}

// SRVRecords returns SRV records from etcd.
// If the Target is not an name but an IP address, an name is created .
func (s *server) SRVRecords(q dns.Question, name string, bufsize uint16, dnssec bool) (records []dns.RR, extra []dns.RR, err error) {
	path, star := msg.PathWithWildcard(name)
	r, err := s.client.Get(path, false, true)
	if err != nil {
		return nil, nil, err
	}
	if !r.Node.Dir { // single element
		serv := new(msg.Service)
		if err := json.Unmarshal([]byte(r.Node.Value), serv); err != nil {
			s.config.log.Infof("failed to parse json: %s", err.Error())
			return nil, nil, err
		}
		ip := net.ParseIP(serv.Host)
		ttl := s.calculateTtl(r.Node, serv)
		if serv.Priority == 0 {
			serv.Priority = int(s.config.Priority)
		}
		serv.Key = r.Node.Key
		serv.Ttl = ttl
		switch {
		case ip == nil:
			srv := serv.NewSRV(q.Name, uint16(100))
			records = append(records, srv)
			if !dns.IsSubDomain(s.config.Domain, srv.Target) {
				m1, e1 := s.Lookup(srv.Target, dns.TypeA, bufsize, dnssec)
				if e1 == nil {
					extra = append(extra, m1.Answer...)
				}
				m1, e1 = s.Lookup(srv.Target, dns.TypeAAAA, bufsize, dnssec)
				if e1 == nil {
					// If we have seen CNAME's we *assume* that they already added.
					for _, a := range m1.Answer {
						if _, ok := a.(*dns.CNAME); !ok {
							extra = append(extra, a)
						}
					}
				}
			}
		case ip.To4() != nil:
			serv.Host = msg.Domain(serv.Key)
			records = append(records, serv.NewSRV(q.Name, uint16(100)))
			extra = append(extra, serv.NewA(serv.Host, ip.To4()))
		case ip.To4() == nil:
			serv.Host = msg.Domain(serv.Key)
			records = append(records, serv.NewSRV(q.Name, uint16(100)))
			extra = append(extra, serv.NewAAAA(serv.Host, ip.To16()))
		}
		return records, extra, nil
	}

	sx, err := s.loopNodes(&r.Node.Nodes, strings.Split(msg.Path(name), "/"), star, nil)
	if err != nil || len(sx) == 0 {
		return nil, nil, err
	}
	// Looping twice to get the right weight vs priority
	w := make(map[int]int)
	for _, serv := range sx {
		weight := 100
		if serv.Weight != 0 {
			weight = serv.Weight
		}
		if _, ok := w[serv.Priority]; !ok {
			w[serv.Priority] = weight
			continue
		}
		w[serv.Priority] += weight
	}
	lookup := make(map[string]bool)
	for _, serv := range sx {
		w1 := 100.0 / float64(w[serv.Priority])
		if serv.Weight == 0 {
			w1 *= 100
		} else {
			w1 *= float64(serv.Weight)
		}
		weight := uint16(math.Floor(w1))
		ip := net.ParseIP(serv.Host)
		switch {
		case ip == nil:
			srv := serv.NewSRV(q.Name, weight)
			records = append(records, srv)
			if _, ok := lookup[srv.Target]; !ok {
				if !dns.IsSubDomain(s.config.Domain, srv.Target) {
					m1, e1 := s.Lookup(srv.Target, dns.TypeA, bufsize, dnssec)
					if e1 == nil {
						extra = append(extra, m1.Answer...)
					}
					m1, e1 = s.Lookup(srv.Target, dns.TypeAAAA, bufsize, dnssec)
					if e1 == nil {
						// If we have seen CNAME's we *assume* that they are already added.
						for _, a := range m1.Answer {
							if _, ok := a.(*dns.CNAME); !ok {
								extra = append(extra, a)
							}
						}
					}
				}
			}
			lookup[srv.Target] = true
		case ip.To4() != nil:
			serv.Host = msg.Domain(serv.Key)
			records = append(records, serv.NewSRV(q.Name, weight))
			extra = append(extra, serv.NewA(serv.Host, ip.To4()))
		case ip.To4() == nil:
			serv.Host = msg.Domain(serv.Key)
			records = append(records, serv.NewSRV(q.Name, weight))
			extra = append(extra, serv.NewAAAA(serv.Host, ip.To16()))
		}
	}
	return records, extra, nil
}

func (s *server) CNAMERecords(q dns.Question, name string) (records []dns.RR, err error) {
	path, _ := msg.PathWithWildcard(name) // no wildcards here
	r, err := s.client.Get(path, false, true)
	if err != nil {
		return nil, err
	}
	if !r.Node.Dir {
		serv := new(msg.Service)
		if err := json.Unmarshal([]byte(r.Node.Value), serv); err != nil {
			s.config.log.Infof("failed to parse json: %s", err.Error())
			return nil, err
		}
		ip := net.ParseIP(serv.Host)
		ttl := s.calculateTtl(r.Node, serv)
		serv.Key = r.Node.Key
		serv.Ttl = ttl
		if ip == nil {
			records = append(records, serv.NewCNAME(q.Name, dns.Fqdn(serv.Host)))
		}
	}
	return records, nil
}

func (s *server) PTRRecords(q dns.Question) (records []dns.RR, err error) {
	name := strings.ToLower(q.Name)
	path, star := msg.PathWithWildcard(name)
	if star {
		return nil, fmt.Errorf("reverse can not contain wildcards")
	}
	r, err := s.client.Get(path, false, false)
	if err != nil {
		// if server has a forward, forward the query
		return nil, err
	}
	if r.Node.Dir {
		return nil, fmt.Errorf("reverse should not be a directory")
	}
	serv := new(msg.Service)
	if err := json.Unmarshal([]byte(r.Node.Value), serv); err != nil {
		s.config.log.Infof("failed to parse json: %s", err.Error())
		return nil, err
	}
	ttl := uint32(r.Node.TTL)
	if ttl == 0 {
		ttl = s.config.Ttl
	}
	serv.Key = r.Node.Key
	// If serv.Host is parseble as a IP address we should not return anything.
	// TODO(miek).
	records = append(records, serv.NewPTR(q.Name, ttl))
	return records, nil
}

// SOA returns a SOA record for this SkyDNS instance.
func (s *server) NewSOA() dns.RR {
	return &dns.SOA{Hdr: dns.RR_Header{Name: s.config.Domain, Rrtype: dns.TypeSOA, Class: dns.ClassINET, Ttl: s.config.Ttl},
		Ns:      "ns.dns." + s.config.Domain,
		Mbox:    s.config.Hostmaster,
		Serial:  uint32(time.Now().Truncate(time.Hour).Unix()),
		Refresh: 28800,
		Retry:   7200,
		Expire:  604800,
		Minttl:  s.config.MinTtl,
	}
}

type bareService struct {
	Host     string
	Port     int
	Priority int
	Weight   int
}

// skydns/local/skydns/east/staging/web
// skydns/local/skydns/west/production/web
//
// skydns/local/skydns/*/*/web
// skydns/local/skydns/*/web

// loopNodes recursively loops through the nodes and returns all the values. The nodes' keyname
// will be match against any wildcards when star is true.
func (s *server) loopNodes(n *etcd.Nodes, nameParts []string, star bool, bx map[bareService]bool) (sx []*msg.Service, err error) {
	if bx == nil {
		bx = make(map[bareService]bool)
	}
Nodes:
	for _, n := range *n {
		if n.Dir {
			nodes, err := s.loopNodes(&n.Nodes, nameParts, star, bx)
			if err != nil {
				return nil, err
			}
			sx = append(sx, nodes...)
			continue
		}
		if star {
			keyParts := strings.Split(n.Key, "/")
			for i, n := range nameParts {
				if i > len(keyParts)-1 {
					// name is longer than key
					continue Nodes
				}
				if n == "*" {
					continue
				}
				if keyParts[i] != n {
					continue Nodes
				}
			}
		}
		serv := new(msg.Service)
		if err := json.Unmarshal([]byte(n.Value), serv); err != nil {
			return nil, err
		}
		b := bareService{serv.Host, serv.Port, serv.Priority, serv.Weight}
		if _, ok := bx[b]; ok {
			continue
		}
		bx[b] = true
		serv.Ttl = s.calculateTtl(n, serv)
		if serv.Priority == 0 {
			serv.Priority = int(s.config.Priority)
		}
		serv.Key = n.Key
		sx = append(sx, serv)
	}
	return sx, nil
}

func (s *server) isDuplicateCNAME(r *dns.CNAME, records []dns.RR) bool {
	for _, rec := range records {
		if v, ok := rec.(*dns.CNAME); ok {
			if v.Target == r.Target {
				return true
			}
		}
	}
	return false
}

// calculateTtl returns the smaller of the etcd TTL and the service's
// TTL. If neither of these are set (have a zero value), the server
// default is used.
func (s *server) calculateTtl(node *etcd.Node, serv *msg.Service) uint32 {
	etcdTtl := uint32(node.TTL)

	if etcdTtl == 0 && serv.Ttl == 0 {
		return s.config.Ttl
	}
	if etcdTtl == 0 {
		return serv.Ttl
	}
	if serv.Ttl == 0 {
		return etcdTtl
	}
	if etcdTtl < serv.Ttl {
		return etcdTtl
	}
	return serv.Ttl
}

func (s *server) NameError(m, req *dns.Msg) {
	m.SetRcode(req, dns.RcodeNameError)
	m.Ns = []dns.RR{s.NewSOA()}
	m.Ns[0].Header().Ttl = s.config.MinTtl
	StatsNameErrorCount.Inc(1)
}
