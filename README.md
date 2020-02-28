[![built-with openzeppelin](https://img.shields.io/badge/built%20with-OpenZeppelin-3677FF)](https://docs.openzeppelin.com/)

![Header](assets/LogoTitle.png)


A layer one protocol for Ethereum that allows smart contract owners the ability to earn interest off of the balance in their smart contracts.

# How to use

Integrating is straightforward. Import either `DSRLending` or `FulcrumLending` into your Dapp.

From there, whenever you accept an ERC20 token within your smart contract, replace the following code 

```
erc20ContractInterface.transferFrom(_from, _to, _value)
```

with 

```
_transfer(address _to, uint256 _value, uint256 _duration)
```

The user that receives the token can then withdraw the underlying balance through

```
function withdraw() public
```

For additional reference, please see the example app `Listing.sol`

# Risks

**Technical risk** — These smart contracts have not been audited or tested thoroughly and thus not ready for main net use. Furthermore, DeFi is still relatively new and could have bugs or security vulnerabilities.


**Borrower Default risk** — You are funding a liquidity pool from which users can borrow. In order to borrow from the liquidity pool, borrowers must post collateral, the value of which is greater than the value they are borrowing (i.e. borrowers are “over-collateralized”). Nevertheless, if the value of the collateral that borrowers have posted rapidly falls, there may be insufficient collateral value left over to repay the loans these borrowers have taken, and you may lose some or all of your investment.


**Interest Rate risk** — interest rates on these lending platforms are variable, meaning they can fluctuate even after you have deposited money or taken out a loan. This means that as a depositor you may earn less than the interest rate you saw at the time you deposited, or that as a borrower you will be responsible for paying a much higher interest rate than you saw when you first borrowed money.

# TODO:

- Integrate with Compound [cTokens]

- Integrate with Aave [aTokens]
