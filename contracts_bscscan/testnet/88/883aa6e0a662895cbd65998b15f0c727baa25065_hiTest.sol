/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the BSC standard as defined in the EIP.
 */
interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract hiTest is Ownable {
  using SafeMath for uint256;
  struct Buyer {
	uint256 amountBNB;
    uint256 bought;
  }
  IERC20 public buyToken;
  address public support;
  uint256 public totalbuyers;
  uint256 public totalBNB;
  uint256 public amount1BNB = 400000;

  uint256 public sBlock;
  uint256 public eBlock;
  mapping (address => Buyer) public buyers;
  event Buy(address user);
  constructor(address _buyToken) public {
    support = msg.sender;
    buyToken = IERC20(_buyToken);
  }

  function buy() public payable {
       require(msg.sender != address(0));
	   require(msg.value >= 0.1 ether && msg.value <= 10 ether, "Invalid Fee");
	   uint256 _msgValue = msg.value;
       uint256 amount = _msgValue.mul(amount1BNB);
	   
       require(amount > 0, 'Invalid Amount');
       require(IERC20(buyToken).balanceOf(address(this)) >= amount, 'Invalid Balance');
	   require(IERC20(buyToken).transfer(msg.sender, amount), 'Buy token is failed');
	   buyers[msg.sender].amountBNB += _msgValue;
	   totalBNB += _msgValue;
	   if (buyers[msg.sender].bought == 0) {
			totalbuyers++;
	   }
	   buyers[msg.sender].bought += amount;

	   emit Buy(msg.sender);
 
  }

  function balanceOf(address user) public view returns (uint256) {
    return buyers[user].bought;
  }
  
  function availabe() public view returns (uint256) {
    return IERC20(buyToken).balanceOf(address(this));
  }
  

  function setToken1BNB(uint256 _amount) public onlyOwner() {
	  amount1BNB = _amount;
  }
  
  function wipe() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  
  function remainToken() public onlyOwner() {
    address payable _owner = msg.sender;
    IERC20(buyToken).transfer(_owner, availabe());
  }
}