pragma solidity ^0.5.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "./../Account.sol";

//---DSR Interface---
contract PotLike {
    function chi() external view returns (uint256);
    function dsr() external view returns (uint256);
    function rho() external view returns (uint256);
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
    function pie(address) public view returns (uint);
}

contract JoinLike {
    function join(address, uint) external;
    function exit(address, uint) external;
    function vat() public returns (VatLike);
    function dai() public returns (IERC20);
}

contract VatLike {
    function hope(address) external;
    function dai(address) public view returns (uint);

}

contract MathLib {
    // Supporting Math functions
    uint constant RAY = 10 ** 27;
    uint256 constant ONE = 10 ** 27;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    
     function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / ONE;
    }
    
    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}
// Manages the interactions with DSR
contract DSRLending is Account, MathLib {
    using SafeMath for uint256;
    
    // ERC20 Smart Contract 
    PotLike public pot;
    JoinLike public daiJoin;
    IERC20 public daiToken;
    VatLike  public vat;
    
    // Kovan Test Addresses
    // PotLike: 0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb
    // JoinLike: 0x5AA71a3ae1C0bd6ac27A1f28e1415fFFB6F15B8c
    // Vatlike: 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9
    // Gemlike: 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
    constructor(address _potlike, address _joinlike, address _vatlike, address _gemlike) public {
        pot = PotLike(address(_potlike));
        daiJoin = JoinLike(address(_joinlike));
        daiToken = IERC20(address(_gemlike));
        vat = VatLike(address(_vatlike));
        
        vat.hope(address(_joinlike));
        vat.hope(address(_potlike));

        daiToken.approve(_joinlike, uint(-1));
    }

    // Get the available balance that the admin earned
    function getAdminAccountBalance() public view returns (uint256) {
        
        uint256 contractBalance = getContractBalance();
        
        return contractBalance - totalUserBalance; 
    }
    
    // Withdraw the interest earned
    function adminWithdraw() public onlyOwner {
        uint256 balance = getAdminAccountBalance();
        
        _redeemUnderlying(balance);
        
        // Send token to User
        require(daiToken.transfer(msg.sender, balance), "Something went wrong");
    }
    
    // Withdraw the current locked balance for a user
    function withdraw() public {
        uint256 totalBalance = _withdraw();
        
        _redeemUnderlying(totalBalance);
        
        // Send token to User
        require(daiToken.transfer(msg.sender, totalBalance), "Something went wrong");
    }
    
    
    function _transfer(address _to, uint256 _value, uint256 _duration) internal {
        super._transfer(_to, _value, _duration);

        require(daiToken.transferFrom(msg.sender, address(this), _value), "Something went wrong");
        
        // Transfer token to lending protocol
        _stake(_value);
    }
    
    //---Fulcrum Calls---
    function _stake(uint256 _balance) internal {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        daiJoin.join(address(this), _balance);
        pot.join(mul(_balance, RAY) / chi);
    }
    
    function _redeemUnderlying(uint256 _balance) internal {
        uint chi = (now > pot.rho()) ? pot.drip() : pot.chi();
        pot.exit(mul(_balance, RAY) / chi);
        daiJoin.exit(msg.sender, daiJoin.vat().dai(address(this)) / RAY);
    }
    
    function getContractBalance() public view returns (uint256) {
        uint256 pie = pot.pie(address(this)); 
       uint256 chi = pot.chi();
       
       // Drip call to always get the updated interest balance
       uint256 rho = pot.rho();
       uint256 tmp = rmul(rpow(pot.dsr(), now - rho, ONE), chi);

       return pie * tmp / RAY;
    }
}
