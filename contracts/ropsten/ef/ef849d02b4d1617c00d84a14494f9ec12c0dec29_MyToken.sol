/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity >=0.4.0 < 0.7.0;

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor ( ) public {
    address msgSender = msg.sender;
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msgSender);
     }
    function owner( ) public view returns (address) {
        return _owner;
    }
    modifier onlyOwner( ) {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership( ) public virtual onlyOwner{
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract MyToken is Ownable {
    
    uint256 public _totalSupply;
    string public _name;
    string public _symbol;
    uint256 public _decemials;
    
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decemials = 18;
        _mint(msg.sender,3000*(10**_decemials));
        // _totalSupply = 3000*(10**_decemials);
        // _balances[msg.sender] = 3000*(10**_decemials);
    }
    
    event Mint(address account, uint256 amount);
    
    function _mint(address account, uint256 amount) public onlyOwner {
        _totalSupply = _totalSupply+amount;
        _balances[account] = _balances[account]+amount;
        emit Mint(account,amount);
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function _transfer(address sender, address recipient, uint256 amount) internal{
        _balances[sender] = _balances[sender]-amount;
        _balances[recipient] = _balances[recipient]+amount;
    }
    
    function transfer(address recipient, uint256 amount) public {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
    }
    
    event Apporval(address indexed owner, address indexed spender, uint256 value);
    
    function approve(address spender, uint256 amount) public returns(bool) {
        _allowances[msg.sender][spender]= amount;
        emit Apporval(msg.sender,spender,amount);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool){
        approve(spender,_allowances[msg.sender][spender]+addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool){
        approve(spender,_allowances[msg.sender][spender]-subtractedValue);
        return true;
    }
    
    function TransferFrom(address sender, address recipient, uint256 amount) public{
        _transfer(sender,recipient,amount);
        emit Transfer(sender,recipient,amount);   
    }
    
    
}