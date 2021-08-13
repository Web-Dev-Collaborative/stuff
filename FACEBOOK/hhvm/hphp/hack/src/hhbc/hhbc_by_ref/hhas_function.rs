// Copyright (c) Facebook, Inc. and its affiliates.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the "hack" directory of this source tree.

use ffi::Slice;
use hhbc_by_ref_hhas_attribute::HhasAttribute;
use hhbc_by_ref_hhas_body::HhasBody;
use hhbc_by_ref_hhas_coeffects::HhasCoeffects;
use hhbc_by_ref_hhas_param::HhasParam;
use hhbc_by_ref_hhas_pos::HhasSpan;
use hhbc_by_ref_hhbc_id::function::FunctionType;

use bitflags::bitflags;

#[derive(Debug)]
pub struct HhasFunction<'arena> {
    pub attributes: Slice<'arena, HhasAttribute<'arena>>,
    pub name: FunctionType<'arena>,
    pub body: HhasBody<'arena>,
    pub span: HhasSpan,
    pub coeffects: HhasCoeffects,
    pub flags: HhasFunctionFlags,
}

bitflags! {
    #[repr(C)]
    pub struct HhasFunctionFlags: u8 {
        const ASYNC =          1 << 1;
        const GENERATOR =      1 << 2;
        const PAIR_GENERATOR = 1 << 3;
        const NO_INJECTION =   1 << 4;
        const INTERCEPTABLE =  1 << 5;
        const MEMOIZE_IMPL =   1 << 6;
        const RX_DISABLED =    1 << 7;
    }
}

impl<'arena> HhasFunction<'arena> {
    pub fn is_async(&self) -> bool {
        self.flags.contains(HhasFunctionFlags::ASYNC)
    }

    pub fn is_generator(&self) -> bool {
        self.flags.contains(HhasFunctionFlags::GENERATOR)
    }

    pub fn is_pair_generator(&self) -> bool {
        self.flags.contains(HhasFunctionFlags::PAIR_GENERATOR)
    }

    pub fn is_interceptable(&self) -> bool {
        self.flags.contains(HhasFunctionFlags::INTERCEPTABLE)
    }

    pub fn is_no_injection(&self) -> bool {
        self.flags.contains(HhasFunctionFlags::NO_INJECTION)
    }

    pub fn is_memoize_impl(&self) -> bool {
        self.flags.contains(HhasFunctionFlags::MEMOIZE_IMPL)
    }

    pub fn rx_disabled(&self) -> bool {
        self.flags.contains(HhasFunctionFlags::RX_DISABLED)
    }

    pub fn with_body<F, T>(&mut self, body: HhasBody<'arena>, f: F) -> T
    where
        F: FnOnce() -> T,
    {
        let old_body = std::mem::replace(&mut self.body, body);
        let ret = f();
        self.body = old_body;
        ret
    }

    pub fn params(&self) -> &[HhasParam<'arena>] {
        self.body.params.as_ref()
    }
}
