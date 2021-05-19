
# Currency Density

*You are robbing a bank and can only carry **100 pounds** of currency out of the vault. Once inside, you see that the bank has organized its money into large piles of **Dimes**, **Quarters**, and **Half Dollars**. How do you pack your bag, taking from these piles, so that you maximize the amount of money you get?*

---

The answer is that it does not matter how you pack your bag, as all three of the listed coins have the same "value density" (i.e: 100 pounds of dimes is worth exactly as much as 100 pounds of quarters and 100 pounds of half dollars).

| Coin Name      | Coin Value in Cents | Coin Weight in Grams | Density (cents/gram) |
|----------------|---------------------|----------------------|----------------------|
| Penny          | 1                   | 2.500                | 0.400                |
| Nickel         | 5                   | 5.000                | 1.000                |
| Dime           | 10                  | 2.268                | <span style="color: #006400; font-weight: bolder">4.409</span>                |
| Quarter Dollar | 25                  | 5.670                | <span style="color: #006400; font-weight: bolder">4.409</span>                |
| Half Dollar    | 50                  | 11.340               | <span style="color: #006400; font-weight: bolder">4.409</span>                |
| Dollar         | 100                 | 8.1                  | 12.3                 |

Consult the [United States Mint's currency specifications](https://www.usmint.gov/learn/coin-and-medal-programs/coin-specifications) for proof.


By the way, the bag you take from the bank will have just shy of two grand.

```
100 (lb) * 453.59 (g/lb) * 4.409 (cents/g) * 0.01 (dollar/cent) = 1999.88 dollars
```