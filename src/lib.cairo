use core::integer::BoundedInt;
const P: u256 = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

fn negate(a: u256) -> u256 {
    let P = BoundedInt::max();
    (P - (a % P)) % P
}

