/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity 0.5.0;
 
contract Techfac {

    address owner;
 
    constructor (uint256 _qty) public {
 
        owner = msg.sender;
        tsupply = _qty;
        balances[msg.sender] = tsupply;
        name_   = "TechTrax";
        symbol_ = "TGP";
        decimals_ = 2;
 
    }
 
    string name_;
    function name() public view returns (string memory) {
        return name_;
    }
    string symbol_;
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    uint8 decimals_;
    function decimals() public view returns (uint8) {
        return decimals_;
    }
    uint256 tsupply ;
    function totalSupply() public view returns (uint256) {
        return tsupply;
    }
    mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    function transfer(address _to, uint256 _value) public returns (bool success) {
          require( balances[msg.sender]>= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value );
        return true;
 
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
            require(balances[_from] >= _value, "Insufficient Funds with owner");
            // check if allowence
            require( allowed[_from][msg.sender] >= _value, "Not enough allowence");

            balances[_from] -= _value;
            balances[_to] += _value; 

            allowed[_from][msg.sender] -= _value;

            emit Transfer(_from, _to, _value);
            return true;
    }

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping(address => mapping(address => uint256)) allowed;
    
    function approve(address _spender, uint256 _value) public returns(bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowence(address _owner, address _spender) public view returns(uint256 remaning){
            return allowed[_owner][_spender];
    }
    //function for increase allowance
    
    function increaseAllowence(address _spender,uint256 _value) public returns(bool){
           allowed[msg.sender][_spender] += _value;
           return true; 
    }
    //function for decrease allowance

  function decreaseAllowence(address _spender,uint256 _value) public returns(bool){
           allowed[msg.sender][_spender] -= _value;
           return true; 
    }
    modifier onlyOwner{
        require(msg.sender == owner, "Unauthorized Action");
        _;
    }
    // Mint

    function mint(uint256 _qty/*, address _to*/) public onlyOwner returns (bool){
        tsupply += _qty;

        // Newly minted tokens to specified address
        //balances[_to] += _qty;

        // Newly minted to msg.sender
        balances[msg.sender] += _qty;

        // to who ran the contract
        //balances[owner] += _qty;

        return true; 
    }

    // Burn

    function burn(uint256 _qty) public onlyOwner returns (bool){
        
        // check if burning amount is less than owner's balances
        require(balances[msg.sender]>= _qty, "not enough tokens to burn");

        tsupply -= _qty;
        balances[owner] -= _qty;
        return true;
    }
 
}