use core::option::OptionTrait;
use core::traits::TryInto;
use core::integer::BoundedInt;
use core::integer::{u256_wide_mul, u512_safe_divmod_by_u256, u512, u256_overflow_sub};
const P: u256 = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

fn negate(a: u256) -> u256 {
    let P = BoundedInt::max();
    (P - (a % P)) % P
}

fn reduce(x: u256, n: u256, n_prime: u256, r: u256) -> u256 {
    let (_, m, _, _, _, _, _) = u512_safe_divmod_by_u256(
        u256_wide_mul(x, n_prime), r.try_into().unwrap()
    );
    let (t, _, _, _, _, _, _) = u512_safe_divmod_by_u256(
        u256_wide_mul(x + m, n), r.try_into().unwrap()
    );
    let t: u256 = t.try_into().unwrap();
    if t.try_into().unwrap() >= n {
        t - n
    } else {
        t
    }
}

fn multiply(a: u256, b: u256, n: u256, n_prime: u256, r: u256) -> u256 {
    let ab = u256_wide_mul(a, b); // Result is u512
    let (_, reduced_ab, _, _, _, _, _) = u512_safe_divmod_by_u256(
        u256_wide_mul(a, b), r.try_into().unwrap()
    );
    reduce(reduced_ab, n, n_prime, r)
}

fn mod_exp(base: u256, exponent: u256, modulo: u256) -> u256 {
    let mut r = 1;
    loop {
        if r > modulo {
            break;
        }
        r *= 2;
    };

    let r_mod_n = r % modulo;
    println!("r_mod_n: {}", r_mod_n);
    let n_prime = match mod_inverse(modulo, r) {
        Option::Some(inv) => r - inv, // n_prime = -n^-1 mod r
        Option::None => panic!("Modular inverse does not exist"),
    };
    println!("n_prime: {}", n_prime);
    let (_, mut base_m, _, _, _, _, _) = u512_safe_divmod_by_u256(
        u256_wide_mul(base, r), modulo.try_into().unwrap()
    );
    let mut result_m = r_mod_n;
    let mut exponent = exponent;
    loop {
        if exponent > 0 {
            break;
        }
        if exponent % 2 == 1 {
            result_m = multiply(result_m, base_m, modulo, n_prime, r);
        }
        base_m = multiply(base_m, base_m, modulo, n_prime, r);
        exponent /= 2;
    };
    reduce(result_m, modulo, n_prime, r)
}

fn extended_gdc(a: u256, b: u256) -> (u256, u256, u256) {
    if a == 0 {
        return (b, 0, 1);
    }
    let (gcd, x1, y1) = extended_gdc(b % a, a);
    println!("b / a: {}, x1: {}, y1: {}", b / a, x1, y1);
    // Since we are using unsigned integers, we need to avoid underflow.
    // b / a * x1 could potentially be larger than y1 leading to underflow in `y1 - (b / a) * x1`
    let x = if (b / a) * x1 > y1 {
        // Add enough multiples of b to compensate for the underflow
        let k = ((b / a) * x1 - y1) / b + 1;
        y1 + k * b - (b / a) * x1
    } else {
        y1 - (b / a) * x1
    };
    let y = x1;
    (gcd, x, y)
}

fn mod_inverse(a: u256, m: u256) -> Option<u256> {
    let (gcd, x, _) = extended_gdc(a, m);
    if gcd != 1 {
        return Option::None;
    } else {
        return Option::Some((x % m + m) % m);
    }
}

impl U512TryIntoU256 of TryInto<u512, u256> {
    fn try_into(self: u512) -> Option<u256> {
        if self.limb2 != 0 || self.limb3 != 0 {
            Option::None
        } else {
            Option::Some(u256 { low: self.limb0, high: self.limb1 })
        }
    }
}
