use core::option::OptionTrait;
use core::traits::TryInto;
use core::integer::BoundedInt;
use core::integer::{
    u256_wide_mul, u512_safe_divmod_by_u256, u512, u256_overflow_sub, u256_overflowing_add
};

const P: u256 = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

fn mod_exponent_optimized(base: u256, exp: u256) -> u256 {
    // Since mod is prime, we can use Fermat's Little Theorem to reduce the exponent modulo (mod-1)
    let mut exp = exp % (P - 1); // Reduce the exponent

    // Initialize the result of the exponentiation
    let mut result = 1;
    let mut base = base % P; // Reduce the base modulo mod initially

    // Binary exponentiation
    loop {
        if exp == 0 {
            break;
        }

        if (exp % 2) != 0 { // If the least significant bit is 1, multiply the base with the result
            let (_, r, _, _, _, _, _) = u512_safe_divmod_by_u256(
                u256_wide_mul(result, base), P.try_into().unwrap()
            );
            result = r;
        }
        let (_, b, _, _, _, _, _) = u512_safe_divmod_by_u256(
            u256_wide_mul(base, base), P.try_into().unwrap()
        ); // Square the base
        base = b;
        exp /= 2; // Right shift the exponent
    };
    result
}

