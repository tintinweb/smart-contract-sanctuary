//SourceUnit: trc20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
 
        uint256 c = a * b;
        require(c / a == b);
 
        return c;
    }
 
    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
 
        return c;
    }
 
    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
 
        return c;
    }
 
    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
 
        return c;
    }
 
    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
interface ITRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract  DSTC is ITRC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances; //授权   *
    mapping (address => bool) private _blackList;
    uint256 private _totalSupply;
    string public  name;
    string public  symbol;
    uint256 public decimals;
    address public initiator;
    address public temporaryInitiator;
    using SafeMath for uint256;
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    constructor (address _initiator, uint256 _total) public {
            _totalSupply = _total * 10 ** 18;
            name = 'DSTC';
            symbol = 'DSTC';
            decimals = 18;
            initiator = _initiator;
            _balances[_initiator] = _totalSupply; 
    }
    modifier onlyCLevel() {
        require(_blackList[msg.sender] != true , 'error : You are on the blacklist');
        _;
    }
    function totalSupply() public view override returns(uint256){
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns(uint256){
        return _balances[account];
    }
    function transfer(address recipient,uint256 amount) public onlyCLevel override returns(bool){
        require(recipient != address(1),'error: address  error');
        require(amount <= _balances[msg.sender],'error: not sufficient funds');
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(msg.sender,recipient,amount);
        return true;
    }
    function allowance(address owner,address spender) public view override returns(uint256){ // *
        return _allowances[owner][spender];
    }
    function approve(address spender,uint256 amount) public onlyCLevel override returns(bool){ //*
        require(spender != address(1),'error: address  error');
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender,address recipient,uint256 amount) public onlyCLevel override returns(bool){
        require(sender != address(1),'error: address  error: address  error');
        require(recipient != address(1),'error: address  error: address  error');
        require(_allowances[sender][msg.sender] >= amount,'error: Insufficient quantity of authorization');
        require(_balances[sender] >= amount,'error: address  not sufficient funds');
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        emit Transfer(sender,recipient,amount);
        return true;
    }
    function destroy(uint256 amounts) public onlyCLevel returns(bool){
        require(amounts <= _balances[msg.sender],'error');
        _balances[msg.sender] = _balances[msg.sender].sub(amounts);
        _totalSupply = _totalSupply.sub(amounts);
        emit Transfer(msg.sender,address(0),amounts);
        return true;
    }
    function addBlackList(address user) public returns(bool) {
        require(initiator == address(msg.sender),"error : insufficient privileges");
        _blackList[user] = true;
    }
    function removeBlackList(address user) public returns(bool) {
        require(initiator == address(msg.sender),"error : insufficient privileges");
        _blackList[user] = false;
    }
    function  changeInitiator(address _temporaryInitiator) public returns(bool) {
        require(initiator == address(msg.sender),"error : insufficient privileges");
        temporaryInitiator = _temporaryInitiator;
    }
    function  receiveInitiator() public returns(bool) {
        require(temporaryInitiator == address(msg.sender),"error : insufficient privileges");
        initiator = address(msg.sender);
    }
}