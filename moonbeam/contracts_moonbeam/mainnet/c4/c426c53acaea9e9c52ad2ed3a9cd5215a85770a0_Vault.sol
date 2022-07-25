/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-03-29
*/

// File: Vault.sol


pragma solidity ^0.5.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
      if (a == 0) {
        return 0;
      }
      c = a * b;
      assert(c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
      c = a + b;
      assert(c >= a);
      return c;
    }
}

contract TOKEN {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function burnFrom(address account, uint256 amount) public;
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Vault is Ownable {
    using SafeMath for uint256;

    event onBackingRedeem(
        address indexed customerAddress,
        uint256 burntAmount,
        uint256 timestamp
    );
    
    event onTokenListing(
        address indexed tokenAddress,
        uint256 timestamp
    );
    
    event onBackingDeposit(
        address indexed tokenAddress,
        uint256 amount,
        uint256 timestamp
    );
    
    address[] public tokenList; //to help with iteration
    mapping(address => TOKEN) private acceptedTokens;
    
    uint256 public leverage = 1;
    
    TOKEN pad;
    
    constructor() public {
      pad = TOKEN(address(0x59193512877E2EC3bB27C178A8888Cfac62FB32D)); //Pad Address
    }
    
    function() payable external {
        revert();
    }
    
    function checkAndTransferToken(address _tokenAddress, uint256 _amount) private {
        require(acceptedTokens[_tokenAddress].transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }
    
    function redeemBacking(uint256 _burnAmount) public returns (uint256) {
        address payable _customerAddress = msg.sender;
        uint256 _padSupply = getPadSupply();
       
        pad.burnFrom(_customerAddress, _burnAmount);
        
        for (uint i = 0; i<tokenList.length; i++) {
            uint256 tokenBalance = TOKEN(tokenList[i]).balanceOf(address(this));
            uint256 backingAmount = tokenBalance.mul(_burnAmount).mul(leverage).div(_padSupply);
            acceptedTokens[tokenList[i]].transfer(_customerAddress, backingAmount);
        }
        
        emit onBackingRedeem(_customerAddress, _burnAmount, now);
        
    }

    function listToken(address _tokenAddress) onlyOwner external returns  (address [] memory) {
        require(acceptedTokens[_tokenAddress] == TOKEN(address(0)), 'This token is already listed.');
        acceptedTokens[_tokenAddress] = TOKEN(address(_tokenAddress));
        tokenList.push(_tokenAddress);
        return tokenList;
    }
    
    //manipulating arrays is costly and this function is only present in case a wrong token address is listed as a mistake.
    function delistToken(address _tokenAddress) onlyOwner external returns (address  [] memory) {
        require(acceptedTokens[_tokenAddress] != TOKEN(address(0)), 'This token is not listed.');
        acceptedTokens[_tokenAddress] = TOKEN(address(0));
         for (uint i = 0; i<tokenList.length; i++) {
            if(tokenList[i] == _tokenAddress) {
                tokenList[i] = tokenList[tokenList.length-1]; //overrides the element we want to delete with the last one
                delete tokenList[tokenList.length-1]; //deletes the last one
                tokenList.length --;
            }
        }
        return tokenList;
    }
    
    function updateLeverage(uint256 _leverage) onlyOwner external returns (bool) {
        require(_leverage >= 1 && _leverage <= 3, "Invalid leverage value.");
        leverage = _leverage;
        return true;
    }
    
    //transfering any accepted token directly to the contract also works (but wont emit an event)
    function addBacking(address _tokenAddress, uint256 _amount) public {
        require(_amount > 0, "must be a positive value");
        checkAndTransferToken(_tokenAddress, _amount);
        emit onBackingDeposit(_tokenAddress, _amount, now);
    }


    function getPadSupply() public view returns (uint256) {
        return pad.totalSupply();
    }
    
}