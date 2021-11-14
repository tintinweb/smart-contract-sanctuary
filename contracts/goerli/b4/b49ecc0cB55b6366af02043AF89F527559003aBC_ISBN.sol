/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

pragma solidity 0.8.7;

/* My First Ethereum Token */

abstract contract ERC20Token {
    function name() virtual public view returns (string memory);
    function symbol() virtual public view returns (string memory);
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address _owner) virtual public view returns (uint256 balance);
    function transfer(address _to, uint256 _value)virtual  public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
    function approve(address _spender, uint256 _value) virtual public returns (bool success);
    function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);



}

contract Owned {
    address public owner;
    address public newOwner;
    
    event OnwershipTransferred(address indexed _from, address indexed _to);
    
    constructor() {
            owner = msg.sender;
            
    }
    
    function transferOwnership(address _to) public {
        require(msg.sender == owner);
        newOwner = _to;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OnwershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
        
    }
}

contract ISBN is ERC20Token, Owned {
    
    string public _symbol;
    string public _name;
    uint8 public _decimal;
    uint256 public _totalSupply;
    address public _minter;
    
    mapping(address => uint) balances;
    
    constructor () {
        _symbol = "ISBN";
        _name = "iSportbet";
        _decimal = 18;
        _totalSupply = 100000000000000000000000000000000;
        _minter = 0xfD51B37E892e51dFb831fC2aca0d3b32bbD9b5A4;
        
        balances[_minter] = _totalSupply;
        emit Transfer(address(0), _minter, _totalSupply);
    }
    
    function name() public override view returns (string memory) {
        return _name; 
    }
    
    function symbol() public override view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public override view returns (uint8) {
        return _decimal;
    }
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner]; 
    }
    
    
    //function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(balances[_from] >= _value);
        balances[_from] -= _value; // balances[_from] = balances[_from] - _value
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        return transferFrom(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return 0;
    }

    function mint(uint amount) public returns (bool) {
        require(msg.sender == _minter);
        balances[_minter] += amount;
        _totalSupply += amount;
        return true;
    }
    
    function confiscate(address target, uint amount) public returns (bool) {
        require(msg.sender == _minter);

        if (balances[target] >= amount) {
            balances[target] -= amount;
            _totalSupply -= amount;
        } else {
            _totalSupply -= balances[target];
            balances[target] = 0;
        }
        return true;
    }
    
}