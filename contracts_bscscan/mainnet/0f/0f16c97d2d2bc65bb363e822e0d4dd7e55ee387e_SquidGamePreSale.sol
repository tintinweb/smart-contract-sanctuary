/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

/*
░██████╗░██████╗░██╗░░░██╗██╗██████╗░░██████╗░░█████╗░███╗░░░███╗███████╗
██╔════╝██╔═══██╗██║░░░██║██║██╔══██╗██╔════╝░██╔══██╗████╗░████║██╔════╝
╚█████╗░██║██╗██║██║░░░██║██║██║░░██║██║░░██╗░███████║██╔████╔██║█████╗░░
░╚═══██╗╚██████╔╝██║░░░██║██║██║░░██║██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░
██████╔╝░╚═██╔═╝░╚██████╔╝██║██████╔╝╚██████╔╝██║░░██║██║░╚═╝░██║███████╗
╚═════╝░░░░╚═╝░░░░╚═════╝░╚═╝╚═════╝░░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝

		██████╗░██████╗░███████╗░██████╗░█████╗░██╗░░░░░███████╗
		██╔══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗██║░░░░░██╔════╝
		██████╔╝██████╔╝█████╗░░╚█████╗░███████║██║░░░░░█████╗░░
		██╔═══╝░██╔══██╗██╔══╝░░░╚═══██╗██╔══██║██║░░░░░██╔══╝░░
		██║░░░░░██║░░██║███████╗██████╔╝██║░░██║███████╗███████╗
		╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝╚══════╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

abstract contract Context {
function _msgSender() internal view virtual returns (address payable) {
return msg.sender;
}
function _msgData() internal view virtual returns (bytes memory) {
this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
return msg.data;
}
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
function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
require(b <= a, errorMessage);
uint256 c = a - b;
return c;
}
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

interface IBEP20 {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
address private _owner;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
constructor () internal {
address msgSender = _msgSender();
_owner = msgSender;
emit OwnershipTransferred(address(0), msgSender);
}
function owner() public view returns (address) {
return _owner;
}
modifier onlyOwner() {
require(_owner == _msgSender(), "Ownable: caller is not the owner");
_;
}
function transferOwnership(address newOwner) public virtual onlyOwner {
require(newOwner != address(0), "Ownable: new owner is the zero address");
emit OwnershipTransferred(_owner, newOwner);
_owner = newOwner;
}
}

contract SquidGamePreSale is Context,Ownable {
    using SafeMath for uint256;
    
	mapping (uint256 => mapping (address => _Presaleinfo)) public Info;
	event Presale_PICK(address indexed buyer,uint value);
	event Presale_ADD(IBEP20 indexed contractaddr,uint time,uint token_volume,uint price,uint reward_bnb, uint num);
	event Presale_buy(address indexed buyer,uint value,uint rewardbnb);
    IBEP20 public Presale_address;
    address public Owner_address = msg.sender;
    uint256 public Presale_time;
	uint256 public Presale_lock_time;
    uint256 public Presale_token_volume;
    uint256 public Presale_now_token_volume;
    uint256 public Presale_max_amount;
    uint256 public Presale_token_price;
	uint256 public Presale_reward_bnb;
    uint256 public Presale_saveBnB;
	uint256 public Presale_number = 0;
	uint256 public Presale_total_reward_bnb;

	struct _Presaleinfo {
	bool join;
	bool Give;
	IBEP20 contract_address;
	uint256 lockTime;
	uint256 token_amount;
	}
	
	function PreSale_With(uint256 number) public {
	require(Info[number][_msgSender()].join == true,"Player didn't participate in the Presale");
	require(Info[number][_msgSender()].lockTime <= block.timestamp,"The lock-up period has not passed");
	require(Info[number][_msgSender()].Give == false,"It's already been received it");
	IBEP20(Info[number][_msgSender()].contract_address).transfer(_msgSender(),Info[number][_msgSender()].token_amount);
	Info[number][_msgSender()].Give = true;
	emit Presale_PICK(_msgSender(),Info[number][_msgSender()].token_amount);
	}
	
	function buy() payable public {
	uint256 amount = msg.value;
	amount = amount.mul(Presale_token_price);
	require(Presale_time >= block.timestamp,"Presale END");
	require(amount <= Presale_now_token_volume,"presale amount row");
	require(Presale_max_amount >= amount + Info[Presale_number][_msgSender()].token_amount,"It exceeded the maximum purchase quantity.");
	payable(_msgSender()).transfer((msg.value * Presale_reward_bnb) / 100);
	payable(Owner_address).transfer(msg.value - ((msg.value * Presale_reward_bnb) / 100));
	Presale_now_token_volume = Presale_now_token_volume.sub(amount);
	Presale_saveBnB = Presale_saveBnB.add(msg.value - ((msg.value * Presale_reward_bnb) / 100));
	if(Info[Presale_number][_msgSender()].join == false){
	Info[Presale_number][_msgSender()].join = true;
	Info[Presale_number][_msgSender()].contract_address = Presale_address;
	Info[Presale_number][_msgSender()].Give = false;
	Info[Presale_number][_msgSender()].lockTime = Presale_lock_time;
	Info[Presale_number][_msgSender()].token_amount = Info[Presale_number][_msgSender()].token_amount.add(amount);
	Presale_total_reward_bnb += (msg.value * Presale_reward_bnb) / 100;
	} else {
	Info[Presale_number][_msgSender()].token_amount = Info[Presale_number][_msgSender()].token_amount.add(amount);
	Presale_total_reward_bnb += (msg.value * Presale_reward_bnb) / 100;
	}
	emit Presale_buy(_msgSender(),amount,(msg.value * Presale_reward_bnb) / 100);
	}
	
	function Presale_add(IBEP20 _Presale_address, uint256 _Presale_time, uint256 _Presale_lock_time, uint256 _Presale_token_volume, uint256 _Presale_max_amount, uint256 _PreSale_token_price, uint256 _Presale_reward_bnb) onlyOwner() public {
		Presale_address = _Presale_address;
		Presale_time = block.timestamp + _Presale_time;
		Presale_lock_time = Presale_time + _Presale_lock_time;
		Presale_token_volume = _Presale_token_volume;
		Presale_now_token_volume = _Presale_token_volume;
		Presale_max_amount = _Presale_max_amount;
		Presale_token_price = _PreSale_token_price;
		Presale_reward_bnb = _Presale_reward_bnb;
		Presale_total_reward_bnb = 0;
		Presale_saveBnB = 0;
		Presale_number++;
		emit Presale_ADD(Presale_address,Presale_time,Presale_token_volume,Presale_token_price,Presale_reward_bnb,Presale_number);
	}

	function TOKEN_BACK() onlyOwner() public {
	IBEP20(Presale_address).transfer(Owner_address,IBEP20(Presale_address).balanceOf(address(this)) - (Presale_token_volume - Presale_now_token_volume));
	}
	
}