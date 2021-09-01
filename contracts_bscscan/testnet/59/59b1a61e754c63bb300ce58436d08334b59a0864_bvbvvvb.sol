/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function battleReward(address recipient, uint256 amount) external returns (bool);
	function addCharacter(bytes32 _characterID, bytes32  _chId, address _chOwner, uint _chRare) external returns (bool);
	function changeOwner(bytes32 _characterID, bytes32 _chId, address  _oldOwner, address  _newOwner) external returns (bool);
	function checkPermission (bytes32 _characterID, address _chOwner) external view returns (bool);
	function getCharacterRare (bytes32 _characterID, bytes32 _chId) external view returns (uint);
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

contract bvbvvvb is Ownable {
  using SafeMath for uint256;
  IERC20 public buyToken;
  address public support;
  address public token;

  event BuyEgg(address user);
  event MarketBuy(address user);
  event Reward(address user);
  event HatchEgg(address user);
  
  constructor(address _buyToken) public {
    support = msg.sender;
    buyToken = IERC20(_buyToken);

  }
  
  //buy
  function buyEgg(uint256 amount) external {
       require(msg.sender != address(0), 'INVALID ADDRESS');

	   emit BuyEgg(msg.sender);
 
  }
  
  //hatch
  function hatchEgg(bytes32 id, uint r) external {
       require(msg.sender != address(0), 'INVALID ADDRESS');
	   emit HatchEgg(msg.sender);
  }
  
  //mint
  function getReward(uint256 reward, bytes32 id, uint r) external {
	   require(reward > 0, 'INVALID REWARD');

	   emit Reward(msg.sender);
  }
  
  //marketbuy
  function buyCharacter(address seller,  uint256 amount, bytes32 id) external {
       require(msg.sender != address(0) , 'INVALID ADDRESS');
	   emit MarketBuy(msg.sender);
  }

}