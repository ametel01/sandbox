use core::integer::{u256_wide_mul, u512_safe_divmod_by_u256};
use core::zeroable::NonZero;

#[test]
fn test_mul_mod_u256() {
    let mul_res = u256_wide_mul(
        21888242871839275222246405745257275088548364400416034343698204186575808495617,
        218882428718392752222464745257275088696311157297823662689037894645226208583
    );
    let modulus: u256 =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    let (q, r, _, _, _, _, _) = u512_safe_divmod_by_u256(mul_res, modulus.try_into().unwrap());
    let q = u256 { low: q.limb0, high: q.limb1 };
    println!("q = {}", q);
    println!("rem = {}", r);
}
