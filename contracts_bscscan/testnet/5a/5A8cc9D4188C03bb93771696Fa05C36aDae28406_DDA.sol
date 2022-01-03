/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

pragma solidity ^0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferPledge(address indexed from, address indexed to, uint256 value);
    event ActiveAccount(address indexed account,address indexed refer);
    event Book(address indexed owner,address indexed bookAddr);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library TransferHelper {

    function safeApprove(address token, address to, uint value) internal returns (bool){
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint value) internal returns (bool){
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

contract DDA is IERC20 ,Ownable{
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    using SafeMath for uint256;
    using TransferHelper for address;
    mapping (address => uint256) private _balances;
    mapping (address => address) private _refers;
    address[] private _actives;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 private _price = 5*10**17; //18wei
    IERC20 USDTTOKEN;
    address private _master = address(0xE130EDF73Df4fdA0e7ab8ed7cd247C3397759497);
    address private _USDT = address(0x9C78aF2604Eda77CA236880946E3144a78042817);


    constructor () public{
        _name = "DDA Token";
        _symbol = "DDA";
        _decimals = 6;
        USDTTOKEN = IERC20(_USDT);
       _refers[msg.sender]=msg.sender;
        _mint(msg.sender, 10000000 * (10 ** uint256(decimals())));
    }

    function pledge(uint256 amount,uint256 rate) public{
        require(amount > 0,"error"); 
        require(rate > 0 && rate < 100 ,"error");
        uint256 usdtBalance = USDTTOKEN.balanceOf(msg.sender);
        require(usdtBalance >= amount,"USDT balance not enough");
        // uint256 rateALL=100;
        // uint256 ddaAmount = amount.mul(rate).div(rateALL.sub(rate));
        uint256 ddaAmount = amount;
        uint256 ddaBalance = _balances[msg.sender];
        require(ddaBalance >= ddaBalance,"DDA balance not enough");
        require(address(USDTTOKEN).safeTransferFrom(msg.sender,_master,amount));
        _balances[msg.sender] = _balances[msg.sender].sub(ddaAmount);
        emit TransferPledge(msg.sender,msg.sender,ddaAmount);
    }

    function active(address refer) public returns(uint code){
        if(_refers[refer] == address(0)){
            return 1;
        }
        if(msg.sender == refer){
            return 2;
        }
        if(_refers[msg.sender]!=address(0)){
            return 3;
        }
        _refers[msg.sender]=refer;
        _actives.push(msg.sender);
        emit ActiveAccount(msg.sender,refer);
        return 0;
    }

    function isActive() view public returns(bool status){
        return _refers[msg.sender] != address(0);
    }

    function activeAllList() public view returns(address[] memory keys,address[] memory values){
        address[] memory list=new address[](_actives.length);
        for(uint i=0;i<_actives.length;i++){
            address key=_actives[i];
            address addr=_refers[key];
            list[i]=addr;
        }
        return(_actives,list);
    }

    function activeRefer(address addr) public view returns(address refer){
        return _refers[addr];
    }

    function book(address bookAddr,uint256 amount) public {
        _transfer(msg.sender,_master,amount);
        emit Book(msg.sender,bookAddr);
    }

    function updateActive(address addr,address refer) external onlyOwner{
        _refers[addr] = refer;
    }
    
    function setPrice(uint256 price) external onlyOwner{
        require(price>0,"Rate must more than 0");
        _price=price;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
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
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

}