package netflix.ocelli.stats;

import java.util.Random;

/**
 * Implementation of the Frugal2U Algorithm.
 * 
 * Reference:
 *  Ma, Qiang, S. Muthukrishnan, and Mark Sandler. "Frugal Streaming for
 *    Estimating Quantiles." Space-Efficient Data Structures, Streams, and
 *    Algorithms. Springer Berlin Heidelberg, 2013. 77-96.
 * 
 * Original code: <https://github.com/dgryski/go-frugal>
 * More info: http://blog.aggregateknowledge.com/2013/09/16/sketch-of-the-day-frugal-streaming/
 * 
 * @author Maycon Viana Bordin <mayconbordin@gmail.com>
 */
public class Frugal2UQuantiles implements Quantiles {

    private final Quantile quantiles[];

    public Frugal2UQuantiles(Quantile[] quantiles) {
        this.quantiles = quantiles;
    }
    
    public Frugal2UQuantiles(double[] quantiles, int initialEstimate) {
        this.quantiles = new Quantile[quantiles.length];
        for (int i=0; i<quantiles.length; i++) {
            this.quantiles[i] = new Quantile(initialEstimate, quantiles[i]);
        }
    }
    
    @Override
    public synchronized void insert(int value) {
        for (Quantile q : quantiles) {
            q.insert(value);
        }
    }

    public int get(double q) {
        for (Quantile quantile : quantiles) {
            if (quantile.q == q)
                return quantile.m;
        }
        
        return 0;
    }
    
    public class Quantile {
        int m;
        double q;
        int step = 1;
        int sign = 0;
        Random r = new Random(new Random().nextInt());
        
        Quantile(int estimate, double quantile) {
            m = estimate;
            q = quantile;
        }
        
        void insert(int s) {
            if (sign == 0) {
                m = s;
                sign = 1;
                return;
            }
            
            if (s > m && r.nextDouble() > 1-q) {
                step += sign * f(step);
                
                if (step > 0) {
                    m += step;
                } else {
                    m += 1;
                }
                
                if (m > s) {
                    step += (s - m);
                    m = s;
                }
                
                if (sign < 0) {
                    step = 1;
                }
                
                sign = 1;
            } else if (s < m && r.nextDouble() > q) {
                step += -sign * f(step);
                
                if (step > 0) {
                    m -= step;
                } else {
                    m--;
                }
                
                if (m < s) {
                    step += (m - s);
                    m = s;
                }
                
                if (sign > 0) {
                    step = 1;
                }
                
                sign = -1;
            }
        }
        
        int f(int step) {
            return 1;
        }
    }
}
