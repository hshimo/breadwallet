//
//  NSData+Hash.m
//  BreadWallet
//
//  Created by Aaron Voisine on 5/13/13.
//  Copyright (c) 2013 Aaron Voisine <voisine@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "NSData+Hash.h"
#import <CommonCrypto/CommonDigest.h>

// bitwise left rotation
#define r(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

// five basic ripemd functions
#define f(x, y, z) ((x) ^ (y) ^ (z))
#define g(x, y, z) (((x) & (y)) | (~(x) & (z)))
#define h(x, y, z) (((x) | ~(y)) ^ (z))
#define i(x, y, z) (((x) & (z)) | ((y) & ~(z)))
#define j(x, y, z) ((x) ^ ((y) | ~(z)))

// ten basic ripemd operations
#define ff(a, b, c, d, e, x, s) ((a) += f((b), (c), (d)) + (x), (a) = r((a), (s)) + (e), (c) = r((c), 10))
#define gg(a, b, c, d, e, x, s) ((a) += g((b), (c), (d)) + (x) + 0x5a827999u, (a) = r((a), (s)) + (e), (c) = r((c), 10))
#define hh(a, b, c, d, e, x, s) ((a) += h((b), (c), (d)) + (x) + 0x6ed9eba1u, (a) = r((a), (s)) + (e), (c) = r((c), 10))
#define ii(a, b, c, d, e, x, s) ((a) += i((b), (c), (d)) + (x) + 0x8f1bbcdcu, (a) = r((a), (s)) + (e), (c) = r((c), 10))
#define jj(a, b, c, d, e, x, s) ((a) += j((b), (c), (d)) + (x) + 0xa953fd4eu, (a) = r((a), (s)) + (e), (c) = r((c), 10))
#define fff(a, b, c, d, e, x, s) ((a) += f((b), (c), (d)) + (x), (a) = r((a), (s)) + (e), (c) = r((c), 10))
#define ggg(a, b, c, d, e, x, s) ((a) += g((b), (c), (d)) + (x) + 0x7a6d76e9u, (a) = r((a), (s)) + (e), (c) = r((c),10))
#define hhh(a, b, c, d, e, x, s) ((a) += h((b), (c), (d)) + (x) + 0x6d703ef3u, (a) = r((a), (s)) + (e), (c) = r((c),10))
#define iii(a, b, c, d, e, x, s) ((a) += i((b), (c), (d)) + (x) + 0x5c4dd124u, (a) = r((a), (s)) + (e), (c) = r((c),10))
#define jjj(a, b, c, d, e, x, s) ((a) += j((b), (c), (d)) + (x) + 0x50a28be6u, (a) = r((a), (s)) + (e), (c) = r((c),10))

static void RMDcompress(uint32_t *buf, uint32_t *x)
{
    uint32_t a = buf[0], b = buf[1], c = buf[2], d = buf[3], e = buf[4],
             k = buf[0], l = buf[1], m = buf[2], n = buf[3], o = buf[4];
    
    // round 1
    ff(a, b, c, d, e, x[0], 11), ff(e, a, b, c, d, x[1], 14), ff(d, e, a, b, c, x[2], 15), ff(c, d, e, a, b, x[3], 12);
    ff(b, c, d, e, a, x[4], 5),  ff(a, b, c, d, e, x[5], 8),  ff(e, a, b, c, d, x[6], 7),  ff(d, e, a, b, c, x[7], 9);
    ff(c, d, e, a, b, x[8], 11), ff(b, c, d, e, a, x[9], 13), ff(a, b, c, d, e, x[10],14), ff(e, a, b, c, d, x[11], 15);
    ff(d, e, a, b, c, x[12], 6), ff(c, d, e, a, b, x[13], 7), ff(b, c, d, e, a, x[14], 9), ff(a, b, c, d, e, x[15], 8);
    
    // round 2
    gg(e, a, b, c, d, x[7], 7),  gg(d, e, a, b, c, x[4], 6),  gg(c, d, e, a, b, x[13], 8), gg(b, c, d, e, a, x[1], 13);
    gg(a, b, c, d, e, x[10],11), gg(e, a, b, c, d, x[6], 9),  gg(d, e, a, b, c, x[15], 7), gg(c, d, e, a, b, x[3], 15);
    gg(b, c, d, e, a, x[12], 7), gg(a, b, c, d, e, x[0], 12), gg(e, a, b, c, d, x[9], 15), gg(d, e, a, b, c, x[5], 9);
    gg(c, d, e, a, b, x[2], 11), gg(b, c, d, e, a, x[14], 7), gg(a, b, c, d, e, x[11],13), gg(e, a, b, c, d, x[8], 12);
    
    // round 3
    hh(d, e, a, b, c, x[3], 11), hh(c, d, e, a, b, x[10],13), hh(b, c, d, e, a, x[14], 6), hh(a, b, c, d, e, x[4], 7);
    hh(e, a, b, c, d, x[9], 14), hh(d, e, a, b, c, x[15], 9), hh(c, d, e, a, b, x[8], 13), hh(b, c, d, e, a, x[1], 15);
    hh(a, b, c, d, e, x[2], 14), hh(e, a, b, c, d, x[7], 8),  hh(d, e, a, b, c, x[0], 13), hh(c, d, e, a, b, x[6], 6);
    hh(b, c, d, e, a, x[13], 5), hh(a, b, c, d, e, x[11],12), hh(e, a, b, c, d, x[5], 7),  hh(d, e, a, b, c, x[12], 5);
    
    // round 4
    ii(c, d, e, a, b, x[1], 11), ii(b, c, d, e, a, x[9], 12), ii(a, b, c, d, e, x[11],14), ii(e, a, b, c, d, x[10], 15);
    ii(d, e, a, b, c, x[0], 14), ii(c, d, e, a, b, x[8], 15), ii(b, c, d, e, a, x[12], 9), ii(a, b, c, d, e, x[4], 8);
    ii(e, a, b, c, d, x[13], 9), ii(d, e, a, b, c, x[3], 14), ii(c, d, e, a, b, x[7], 5),  ii(b, c, d, e, a, x[15], 6);
    ii(a, b, c, d, e, x[14], 8), ii(e, a, b, c, d, x[5], 6),  ii(d, e, a, b, c, x[6], 5),  ii(c, d, e, a, b, x[2], 12);
    
    // round 5
    jj(b, c, d, e, a, x[4], 9),  jj(a, b, c, d, e, x[0], 15), jj(e, a, b, c, d, x[5], 5),  jj(d, e, a, b, c, x[9], 11);
    jj(c, d, e, a, b, x[7], 6),  jj(b, c, d, e, a, x[12], 8), jj(a, b, c, d, e, x[2], 13), jj(e, a, b, c, d, x[10], 12);
    jj(d, e, a, b, c, x[14], 5), jj(c, d, e, a, b, x[1], 12), jj(b, c, d, e, a, x[3], 13), jj(a, b, c, d, e, x[8], 14);
    jj(e, a, b, c, d, x[11],11), jj(d, e, a, b, c, x[6], 8),  jj(c, d, e, a, b, x[15], 5), jj(b, c, d, e, a, x[13], 6);
    
    // parallel round 1
    jjj(k, l, m, n, o, x[5], 8), jjj(o, k, l, m, n, x[14],9), jjj(n, o, k, l, m, x[7], 9), jjj(m, n, o, k, l, x[0], 11);
    jjj(l, m, n, o, k, x[9],13), jjj(k, l, m, n, o, x[2],15), jjj(o, k, l, m, n,x[11],15), jjj(n, o, k, l, m, x[4], 5);
    jjj(m, n, o, k, l, x[13],7), jjj(l, m, n, o, k, x[6], 7), jjj(k, l, m, n, o, x[15],8), jjj(o, k, l, m, n, x[8], 11);
    jjj(n, o, k, l, m, x[1],14), jjj(m, n, o, k, l,x[10],14), jjj(l, m, n, o, k, x[3],12), jjj(k, l, m, n, o, x[12], 6);
    
    // parallel round 2
    iii(o, k, l, m, n, x[6], 9), iii(n, o, k, l, m,x[11],13), iii(m, n, o, k, l, x[3],15), iii(l, m, n, o, k, x[7], 7);
    iii(k, l, m, n, o, x[0],12), iii(o, k, l, m, n, x[13],8), iii(n, o, k, l, m, x[5], 9), iii(m, n, o, k, l, x[10],11);
    iii(l, m, n, o, k, x[14],7), iii(k, l, m, n, o, x[15],7), iii(o, k, l, m, n, x[8],12), iii(n, o, k, l, m, x[12], 7);
    iii(m, n, o, k, l, x[4], 6), iii(l, m, n, o, k, x[9],15), iii(k, l, m, n, o, x[1],13), iii(o, k, l, m, n, x[2], 11);
    
    // parallel round 3
    hhh(n, o, k, l, m, x[15],9), hhh(m, n, o, k, l, x[5], 7), hhh(l, m, n, o, k, x[1],15), hhh(k, l, m, n, o, x[3], 11);
    hhh(o, k, l, m, n, x[7], 8), hhh(n, o, k, l, m, x[14],6), hhh(m, n, o, k, l, x[6], 6), hhh(l, m, n, o, k, x[9], 14);
    hhh(k, l, m, n, o,x[11],12), hhh(o, k, l, m, n, x[8],13), hhh(n, o, k, l, m, x[12],5), hhh(m, n, o, k, l, x[2], 14);
    hhh(l, m, n, o, k,x[10],13), hhh(k, l, m, n, o, x[0],13), hhh(o, k, l, m, n, x[4], 7), hhh(n, o, k, l, m, x[13], 5);
    
    // parallel round 4
    ggg(m, n, o, k, l, x[8],15), ggg(l, m, n, o, k, x[6], 5), ggg(k, l, m, n, o, x[4], 8), ggg(o, k, l, m, n, x[1], 11);
    ggg(n, o, k, l, m, x[3],14), ggg(m, n, o, k, l,x[11],14), ggg(l, m, n, o, k, x[15],6), ggg(k, l, m, n, o, x[0], 14);
    ggg(o, k, l, m, n, x[5], 6), ggg(n, o, k, l, m, x[12],9), ggg(m, n, o, k, l, x[2],12), ggg(l, m, n, o, k, x[13], 9);
    ggg(k, l, m, n, o, x[9],12), ggg(o, k, l, m, n, x[7], 5), ggg(n, o, k, l, m,x[10],15), ggg(m, n, o, k, l, x[14], 8);
    
    // parallel round 5
    fff(l, m, n, o, k, x[12],8), fff(k, l, m, n, o, x[15],5), fff(o, k, l, m, n,x[10],12), fff(n, o, k, l, m, x[4], 9);
    fff(m, n, o, k, l, x[1],12), fff(l, m, n, o, k, x[5], 5), fff(k, l, m, n, o, x[8],14), fff(o, k, l, m, n, x[7], 6);
    fff(n, o, k, l, m, x[6], 8), fff(m, n, o, k, l, x[2],13), fff(l, m, n, o, k, x[13],6), fff(k, l, m, n, o, x[14], 5);
    fff(o, k, l, m, n, x[0],15), fff(n, o, k, l, m, x[3],13), fff(m, n, o, k, l, x[9],11), fff(l, m, n, o, k, x[11],11);
    
    // combine results
    n += c + buf[1]; // final result for buf[0]
    buf[1] = buf[2] + d + o, buf[2] = buf[3] + e + k, buf[3] = buf[4] + a + l, buf[4] = buf[0] + b + m, buf[0] = n;
}

static void RMD160(const void *data, uint32_t len, uint8_t *md)
{
    uint32_t x[16], buf[] = { 0x67452301u, 0xefcdab89u, 0x98badcfeu, 0x10325476u, 0xc3d2e1f0u };
    
    for (uint32_t l = len; l > 63; l -= 64) { // process data in 16 word chunks
        for (uint32_t i = 0; i < 16; i++) {
            x[i] = CFSwapInt32LittleToHost(*(uint32_t *)data);
            data = (uint32_t *)data + 1;
        }
        
        RMDcompress(buf, x);
    } // length mod 64 bytes left
    
    memset(x, 0, sizeof(x));
    
    for (uint32_t i = 0; i < (len & 63); i++) { // put bytes from data into x
        x[i >> 2] ^= (uint32_t)*(uint8_t *)data << (8*(i & 3)); // byte i goes into word x[i/4] at pos 8*(i mod 4)
        data = (uint8_t *)data + 1;
    }
    
    x[(len >> 2) & 15] ^= (uint32_t)1 << (8*(len & 3) + 7); // append the bit m_n == 1
    
    if ((len & 63) > 55) {
        RMDcompress(buf, x); // length goes to next block
        memset(x, 0, sizeof(x));
    }
    
    x[14] = len << 3, x[15] = len >> 29; // append length in bits
    RMDcompress(buf, x);
    
    for (uint32_t i = 0; i < RMD160_DIGEST_LENGTH; i += 4) {
        *(uint32_t *)&md[i] = CFSwapInt32HostToLittle(buf[i >> 2]);
    }
}

@implementation NSData (Hash)

- (NSData *)SHA1
{
    NSMutableData *d = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];

    CC_SHA1(self.bytes, (CC_LONG)self.length, d.mutableBytes);

    return d;
}

- (NSData *)SHA256
{
    NSMutableData *d = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(self.bytes, (CC_LONG)self.length, d.mutableBytes);
    
    return d;
}

- (NSData *)SHA256_2
{
    NSMutableData *d = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(self.bytes, (CC_LONG)self.length, d.mutableBytes);
    CC_SHA256(d.bytes, (CC_LONG)d.length, d.mutableBytes);
    
    return d;
}

- (NSData *)RMD160
{
    NSMutableData *d = [NSMutableData dataWithLength:RMD160_DIGEST_LENGTH];
    
    RMD160(self.bytes, (uint32_t)self.length, d.mutableBytes);
    
    return d;
}

- (NSData *)hash160
{
    return self.SHA256.RMD160;
}

- (NSData *)reverse
{
    NSUInteger l = self.length;
    NSMutableData *d = [NSMutableData dataWithLength:l];
    uint8_t *b1 = d.mutableBytes;
    const uint8_t *b2 = self.bytes;
    
    for (NSUInteger i = 0; i < l; i++) {
        b1[i] = b2[l - i - 1];
    }
    
    return d;
}

@end
