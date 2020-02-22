pragma solidity ^0.5.0;
import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../node_modules/@openzeppelin/contracts/math/SafeMath.sol";
import "./../Account.sol";

contract FulcrumInterface {
    function mintWithEther(address receiver) external payable returns (uint256 mintAmount);
    function burnToEther(address payable receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
    function mint(address receiver, uint256 depositAmount) external returns (uint256 mintAmount); 
    function burn(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
    function assetBalanceOf(address _owner) public view returns (uint256);
}

// Manages the interactions with the Fulcrum Protocol
// Manages one erc20 token. (Usually DAI)
contract FulcrumLending is Account {
    using SafeMath for uint256;
    
    IERC20 public erc20Contract;
    FulcrumInterface public fulcrumContract;

    // Kovan Test Addresses
    // Dai ERC20 Address: 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
    // Fulcrum: 0x6c1E2B0f67e00c06c8e2BE7Dc681Ab785163fF4D
    constructor(address _fulcrumAddress, address _erc20Address) public {
        erc20Contract = IERC20(address(_fulcrumAddress));
        fulcrumContract = FulcrumInterface(address(_erc20Address));
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
        require(erc20Contract.transfer(msg.sender, balance), "Something went wrong");
    }
    
    // Withdraw the current locked balance for a user
    function withdraw() public {
        uint256 totalBalance = _withdraw();
        
        _redeemUnderlying(totalBalance);
        
        // Send token to User
        require(erc20Contract.transfer(msg.sender, totalBalance), "Something went wrong");
    }
    
    
    function _transfer(address _to, uint256 _value, uint256 _duration) internal {
        super._transfer(_to, _value, _duration);

        require(erc20Contract.transferFrom(msg.sender, address(this), _value), "Something went wrong");
        
        // Transfer token to lending protocol
        _stake(_value);
    }
    
    //---Fulcrum Calls---
    
    function _stake(uint256 _balance) internal {
        erc20Contract.approve(address(fulcrumContract), _balance);
        fulcrumContract.mint(address(this), _balance);
    }
    
    function _redeemUnderlying(uint256 _balance) internal {
        fulcrumContract.burn(address(this), _balance);
    }
    
    function getContractBalance() public view returns (uint256) {
        return fulcrumContract.assetBalanceOf(address(this));
    }
}
