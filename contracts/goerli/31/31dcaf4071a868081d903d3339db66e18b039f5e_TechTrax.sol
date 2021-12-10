/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity 0.5.0;

contract TechTrax {
 
    address owner;
    constructor (uint256 _qty) public {
        owner = msg.sender;
        tsupply = _qty;
        balances[msg.sender] = tsupply;
        name_   = "TechTrax";
        symbol_ = "TTX0";
        decimals_ = 0;
 
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
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require( balances[_from]>= _value, "Insufficient balance with owner");
        // check if allowance is available
        require( allowed[_from][msg.sender] >= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    mapping (address => mapping (address => uint256)) allowed;
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
    // Function for increase allowance.
    function increaseAllowance(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] += _value;
        return true;
    }
 
    function decresingAllowance(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] -= _value;
        return true;
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
 
    modifier onlyOwner {
        require( msg.sender == owner, "Only Owner");
        _;
    }
    // Mint
 
    function mint(uint256 _qty) public onlyOwner returns (bool) {
        tsupply += _qty;
        // Newly minted token to some specified address .
        //balances[_to] += _qty;
        // newly minted token to msg.sender
        //balances[msg.sender] += _qty;
        // to contract deployer
        balances[owner] += _qty;
        return true;
    }
 
 
    // Burn
   
    function burn(uint256 _qty) public onlyOwner returns (bool) {
        require(balances[msg.sender] >= _qty, " Not enough tokens to burn");
        tsupply -= _qty;
        balances[owner] -= _qty;
        return true;
 
    }
}
 
// Owner - 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// Spender 1 - 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// Spender 2 - 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// Beneficiary - 0xdD870fA1b7C4700F2BD7f44238821C26f7392148