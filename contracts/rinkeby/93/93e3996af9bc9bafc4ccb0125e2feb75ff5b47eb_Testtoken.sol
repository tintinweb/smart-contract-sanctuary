/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is  IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
   
    mapping(address => bool) public _isEXcludedfromfee;

    uint256 private _totalSupply;
    uint256 private _icosupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;
    address private _ICO;
    address private _feeaddress;

    constructor (string memory name_, string memory symbol_ , address owner){
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _owner = owner;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        //require(_isEXcludedfromfee[sender] != true, 'is excluded from fee');
        (uint256 tAmount, uint256 fee) = transferfee_(amount, _isEXcludedfromfee[sender]);
       // uint256 fee = amount.mul(5).div(100);
       // _transferfee(sender,fee);
        _balances[sender] = _balances[sender].sub(tAmount, "ERC20: transfer amount exceeds balance");
        _balances[_feeaddress] = _balances[_feeaddress].add(fee);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

function transferfee_(uint256 amount,bool takeFee) internal virtual returns(uint256,uint256){
    //if excluded from fee, we don't need to do calculation
    // if not, we have to calculate
     uint256 fee = 0;
     uint256 tAmount;
    if(!takeFee){
       fee = amount.mul(5).div(100);
       tAmount = amount.add(fee.mul(2));
       return(tAmount, fee);
    } else {
        fee = 0;
    }
    return(amount,fee);
   
}

    // below won't work

    // function _transferfee(address transferfee,uint256 fee_amount) internal virtual {
    //     require(_isEXcludedfromfee[transferfee] != true, 'is excluded from fee');
    //     _balances[transferfee] = _balances[transferfee].add(fee_amount);
       
    // }
   
    function setfeeaddress(address feeaddress) public onlyowner {
        _feeaddress = feeaddress;
    }


    function getfeeaddress() public view returns (address) {
        return _feeaddress;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _icosupply = _totalSupply.div(5);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
   
   
    function whoisowner() public view returns(address){
        return _owner;
    }
   
    modifier onlyowner {
        require(msg.sender == _owner, "only owner is autorized");
        _;
    }
   
    function setICO(address _icoaddress) public virtual onlyowner {
        _ICO = _icoaddress;
        _icosupply = _totalSupply.div(5);
        _balances[_ICO] = _balances[_ICO].add(_icosupply);
        _balances[_owner] = _balances[_owner].sub(_icosupply);
       
    }
   
   
   
    function excludefromfee(address _exc) public onlyowner {
        _isEXcludedfromfee[_exc] = true;
    }
   
    function isexcudedfromfee(address check) public view returns(bool) {
        return _isEXcludedfromfee[check];
    }
   
    function getICO() public view returns(address) {
        return _ICO;
    }
       
}

contract Testtoken is ERC20 {

    constructor () ERC20("BAF Testing Token", "BAF Test", msg.sender){
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}