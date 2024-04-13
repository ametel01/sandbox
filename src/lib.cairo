use core::option::OptionTrait;
use core::traits::TryInto;
use core::integer::BoundedInt;
use core::integer::{u256_wide_mul, u512_safe_divmod_by_u256, u512};

const P: u256 = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

#[derive(Copy, Debug, Drop)]
struct Point {
    x: u256,
    y: u256,
}

fn mod_exp(base: u256, exp: u256) -> u256 {
    // Since mod is prime, we can use Fermat's Little Theorem to reduce the exponent modulo (mod-1)
    let mut exp = exp % (P - 1); // Reduce the exponent
    let mut base = base % P; // Reduce the base modulo mod initially

    pow(base, exp)
}

fn mod_inv(a: u256) -> u256 {
    pow(a, P - 2)
}

fn ec_add(p1: Point, p2: Point) -> Point {
    if p1.x.is_zero() && p1.y.is_zero() {
        return p2;
    }
    if p2.x == 0 && p2.y == 0 {
        return p1;
    }

    let x1 = p1.x;
    let y1 = p1.y;
    let x2 = p2.x;
    let y2 = p2.y;

    if x1 == x2 && y1 == (P - y2) % P {
        return Point { x: 0, y: 0 }; // Point at infinity
    }

    let mut s: u256 = 0;
    if x1 == x2 && y1 == y2 {
        // Point doubling
        let (_, t1, _, _, _, _, _) = u512_safe_divmod_by_u256(
            u256_wide_mul(x1, x2), P.try_into().unwrap()
        ); // x1 * x1
        let (_, t2, _, _, _, _, _) = u512_safe_divmod_by_u256(
            u256_wide_mul(t1, mod_inv(2 * y1)), P.try_into().unwrap()
        ); // x1 * x1 * mod_inv(2 * y1)
        let (_, t3, _, _, _, _, _) = u512_safe_divmod_by_u256(
            u256_wide_mul(3, t2), P.try_into().unwrap()
        ); // 3 * t2

        s = t3 % P;
    } else {
        // Point addition
        let (_, r, _, _, _, _, _) = u512_safe_divmod_by_u256(
            u256_wide_mul(y2 + P - y1, mod_inv(x2 + P - x1)), P.try_into().unwrap()
        );
        s = r;
    }

    let (_, r, _, _, _, _, _) = u512_safe_divmod_by_u256(
        u256_wide_mul(s, s), P.try_into().unwrap()
    );
    let x3 = (r + P - x1 + P - x2) % P;

    let (_, r, _, _, _, _, _) = u512_safe_divmod_by_u256(
        u256_wide_mul(s, x1 + P - x3), P.try_into().unwrap()
    ); // s * ((x1 + p - x3) % p)
    let y3 = (r + P - y1) % P;

    Point { x: x3, y: y3 }
}

fn pow(mut base: u256, mut exp: u256) -> u256 {
    let mut result = 1;
    loop {
        if exp.is_zero() {
            break;
        }

        if !(exp % 2)
            .is_zero() { // If the least significant bit is 1, multiply the base with the result
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
