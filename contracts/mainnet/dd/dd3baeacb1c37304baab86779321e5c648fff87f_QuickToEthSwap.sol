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

contract QuickToEthSwap is Ownable {
    using SafeMath for uint;
    
    event EtherDeposited(uint);
    
    address public tokenAddress = 0xAa589961B9e6a05577fB1Ac6bBd592CF48D689F4;
    
    uint public tokenDecimals = 18;
    
    uint public weiPerToken = 2e18;
    
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }
    
    function setTokenDecimals(uint _tokenDecimals) public onlyOwner {
        tokenDecimals = _tokenDecimals;
    }
    
    function setWeiPerToken(uint _weiPerToken) public onlyOwner {
        weiPerToken = _weiPerToken;
    }
    
    function swap(uint _amount) public {
        require(_amount <= 5 * 10**tokenDecimals, "Cannot swap more than 5 tokens!");
        uint weiAmount = _amount.mul(weiPerToken).div(10**tokenDecimals);
        require(weiAmount > 0, "Invalid ETH amount to transfer");
        require(Token(tokenAddress).transferFrom(msg.sender, owner, _amount), "Cannot transfer tokens");
        msg.sender.transfer(weiAmount);
    }
    
    receive () external payable {
        emit EtherDeposited(msg.value);
    }
    
    function transferAnyERC20Token(address _token, address _to, uint _amount) public onlyOwner {
        Token(_token).transfer(_to, _amount);
    }
    function transferUSDT(address _usdtAddr, address to, uint amount) public onlyOwner {
        USDT(_usdtAddr).transfer(to, amount);
    }
}