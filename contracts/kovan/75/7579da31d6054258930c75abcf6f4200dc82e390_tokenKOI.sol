/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

pragma solidity >=0.4.22 <0.9.0;
contract tokenKOI{
    address private _minter;
    string private   _name;
    string private   _symbol;  
    uint8 private _decimals=18;
    uint256 public _totalSupply=10000000;
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        _minter =msg.sender;
    }
    
    mapping(address => uint ) internal _balances;
    mapping (address => mapping (address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8 ) {
        return _decimals;
    }

     function totalSupply() public view   returns (uint256) {
        return _totalSupply;
    }
    function mint(address receiver,uint amount)public{
        require(msg.sender==_minter);
        require (amount<1e60);
        _balances[receiver]+=amount;
    }
    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }
    function transfer(address _to, uint256 _value) public  returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (_balances[msg.sender] >= _value && _value > 0) {
            _balances[msg.sender] -= _value;
            _balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (_balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            _balances[_to] += _value;
            _balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    

    function approve(address _spender, uint256 _value) public payable returns (bool success) {
        allowed[msg.sender][_spender] = _value;
         emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public  view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    

}