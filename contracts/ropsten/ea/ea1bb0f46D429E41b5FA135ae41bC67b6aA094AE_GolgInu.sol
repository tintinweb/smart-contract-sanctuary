/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity 0.5.0;

contract GolgInu {
    
    // a fungible crypto token. ERC20 token
    address admin;
    constructor (uint256 _qty) public {
        tsupply = _qty;
        balances[msg.sender] = tsupply;
        name_ = "GolgInu";
        symbol_ = "GGU";
        decimal_ = 0;
        admin = msg.sender;
    }

    string name_;
    function name() public view returns (string memory) {
        return name_;
    }
    string symbol_;
    function symbol() public view returns (string memory){
        return symbol_;
    }
    uint8 decimal_;
    function decimals() public view returns (uint8){
        return decimal_;
    }
    
    uint256 tsupply;    // Total token supply
    function totalSupply() public view returns (uint256) {
        return tsupply;        
    }
    
    mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender]>= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }
    
    // transferFrom - From an owner to beneficiary by a spender.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from]>= _value, "Insufficient balance");
        require(allowed[_from][msg.sender] >= _value, "Not enough allowance remaining");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    // approve - Owner gives approval to spender to spend an allowance.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping (address => mapping(address => uint256)) allowed;
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    // Increase or Decrease allowance
    
    function increaseAllowance(address _spender, uint256 _increaseQty) public returns(bool success){
        allowed[msg.sender][_spender] += _increaseQty;
        emit Approval(msg.sender, _spender, _increaseQty);
        return true;
    }
    function decreaseAllowance(address _spender, uint256 _decreaseQty) public returns(bool success){
        allowed[msg.sender][_spender] -= _decreaseQty;
        emit Approval(msg.sender, _spender, _decreaseQty);
        return true;
    }
    
    // allowance - one can check the remaining allowance between an owner & spender.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
    // Mint & burn
    
    function mint( uint256 _mintQty) public {
        require ( msg.sender == admin, "You are not authorized");
        tsupply += _mintQty;
        balances[msg.sender] += _mintQty;
      //  balances[_to] += _mintQty;
      //  balances[admin] += _mintQty;
    }
    
    function burn(uint256 _burnQty) public {
        require ( msg.sender == admin, "You are not authorized");
        require (balances[msg.sender] >= _burnQty, "Not enough tokens to burn");
        tsupply -= _burnQty;
        balances[msg.sender] -= _burnQty;
    }
}