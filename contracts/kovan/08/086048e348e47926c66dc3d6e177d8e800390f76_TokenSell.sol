/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

pragma solidity 0.8.6;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

abstract contract Ownable is Context {
    address public Owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    modifier onlyOwner() {
        require(Owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(Owner, address(0));
        Owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(Owner, newOwner);
        Owner = newOwner;
    }
}

interface Token {
    function transfer(address, uint256) external returns (bool);
}

contract TokenSell is Ownable {
    using SafeMath for uint256;
    
    uint256 public FundsRaised;
    uint256 public MaximumFunds = 1e21;
    uint256 public MinimumBNBAmount = 25e16;
    uint256 public MaximumBNBAmount = 2e18;
    
    function Buy() public payable {
        require(msg.value > MinimumBNBAmount || msg.value < MaximumBNBAmount, "Enter valid BNB amount.");
        require(FundsRaised < MaximumFunds, "Token Sell Completed.");
        
        if (msg.value < MinimumBNBAmount || msg.value > MaximumBNBAmount) { // if BNB amount less then 0.25 or more then 2, then the amount will transfer back to sender..
            payable(msg.sender).transfer(msg.value);
        } else
        
        FundsRaised = FundsRaised.add(msg.value);
    }
    
    // function to allow admin to claim BNB from this address..
    function transferBNB(address payable recipient) public onlyOwner {
        recipient.transfer(address(this).balance);
    }
    
    // function to allow admin to claim BEP20 tokens from this contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20: amount must be greater than 0");
        require(recipient != address(0), "ERC20: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }
    
    function setMaximumFunds(uint256 amount) public onlyOwner {
        MaximumFunds = amount;
    }
    
    function setMaximumBNB(uint256 amount) public onlyOwner {
        MaximumBNBAmount = amount;
    }
    
    function setMinimumBNB(uint256 amount) public onlyOwner {
        MinimumBNBAmount = amount;
    }
    
    receive() external payable {
        Buy();
    }
}