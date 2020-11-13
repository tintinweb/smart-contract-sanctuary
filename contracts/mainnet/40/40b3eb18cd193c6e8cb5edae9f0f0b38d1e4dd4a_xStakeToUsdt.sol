pragma solidity 0.6.12;

// SPDX-License-Identifier: BSD-3-Clause

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address payable public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool);
}

interface USDT {
    function transfer(address to, uint amount) external;
    function transferFrom(address _from, address _to, uint _amount) external;
}

contract xStakeToUsdt is Ownable {
    using SafeMath for uint;
    
    address public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public xstakeAddress = 0xb6aa337C9005FBf3a10Edde47DDde3541adb79Cb;
    
    function swap(uint _amount) payable public {
        require(msg.value >= 1e16, "Invalid ETH fee for swap.");
        owner.transfer(msg.value);
        uint usdtAmount = _amount.div(1e12);
        require(usdtAmount > 0, "Invalid USDT amount to transfer");
        require(Token(xstakeAddress).transferFrom(msg.sender, owner, _amount), "Cannot transfer tokens");
        USDT(usdtAddress).transferFrom(owner, msg.sender, usdtAmount);
    }
    
    function transferAnyERC20Token(address _token, address _to, uint _amount) public onlyOwner {
        Token(_token).transfer(_to, _amount);
    }
    function transferUSDT(address _usdtAddr, address to, uint amount) public onlyOwner {
        USDT(_usdtAddr).transfer(to, amount);
    }
}