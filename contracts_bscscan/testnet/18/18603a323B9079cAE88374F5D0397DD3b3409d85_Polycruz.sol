/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity ^0.5.17;

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

contract BEP20Detailed is IBEP20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
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
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

}

contract Context {

    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    event ExcludedFromFee(address indexed account);
    
    event IncludedInFee(address indexed account);

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping ( address => bool) internal _isExcludedFromFee;

    uint256 private _totalSupply;

    address private _owner;

    address public feeTo;

    constructor (address _feeTo) public {
        address msgSender = _msgSender();
        _owner = msgSender;
        feeTo = _feeTo;
        _isExcludedFromFee[feeTo] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function Owner() public view  returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(Owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transfer(_owner,newOwner,balanceOf(_owner));
        _isExcludedFromFee[_owner] = false;
        _owner = newOwner;
        _isExcludedFromFee[newOwner] = true;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

     function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        (uint256 tAmount, uint256 fee) = transferFee(amount, _isExcludedFromFee[sender]);
        _balances[sender] = _balances[sender].sub(tAmount, "BEP20: transfer amount exceeds balance");
        _burn(sender, fee);
        _balances[recipient] = _balances[recipient].add(amount);
        _balances[feeTo] = _balances[feeTo].add(fee);
        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, feeTo, fee);
    }

 function transferFee(uint256 amount, bool takefee) internal pure returns(uint256, uint256){
        uint256 fee = 0;
        if(!takefee) {
            fee = amount.mul(5).div(100);
            uint256 totalAmount = amount.add(fee.mul(2));
            return (totalAmount, fee);
        }   
        return (amount, fee);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account,uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludedInFee(account);
    }
}

contract Polycruz is BEP20, BEP20Detailed {
    constructor(address feeTo) BEP20Detailed("POLYCRUZ", "CRUZ", 12) BEP20(feeTo) public {
        _mint(msg.sender, 1000000000000 * 10 ** 12);
        _isExcludedFromFee[msg.sender] = true;

    }
}