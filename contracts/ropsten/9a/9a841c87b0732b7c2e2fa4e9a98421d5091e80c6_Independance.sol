/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity ^0.5.0;

contract Independance {
    
    address admin;
    constructor (uint256 _qty, string memory _name, string memory _symbol, uint8 _decimal) public {
        totalsupply = _qty;
        // All the tokens are to be in account of deployer.
        balances[msg.sender] = totalsupply;
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
        admin = msg.sender; // deployer
    }
     
    string name_;
    function name() public view returns (string memory) {
        return name_;
    }
    string symbol_;
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    uint8 decimal_;
    function decimals() public view returns (uint8) {
        return decimal_;
    }


    uint256 totalsupply;
    // Returns the total token supply.
    function totalSupply() public view returns (uint256) {
        return totalsupply;
    }
    
    mapping ( address => uint256) balances;
    //Returns the account balance of another account with address _owner
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // sender of message is transferring some token (_value) to a beneficiary account (_to).
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require( balances[msg.sender] >= _value, "Insuffcient balance");
      //  balances[msg.sender] = balances[msg.sender] - _value;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }
    // run by Spender.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require( balances[_from] >= _value, "Insuffcient balance");
        require ( allowed[_from][msg.sender] >= _value, "Not enough allowance remaining");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
        
    }
    
    // run by owner .
    
    mapping (address => mapping (address => uint256)) allowed;
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    // Run by anyone.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // Spender - 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // Owner - 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // To - 0xdD870fA1b7C4700F2BD7f44238821C26f7392148

    modifier onlyAdmin {
        require( msg.sender == admin, "Only admin");
        _;
    }
    
    function mint(uint256 _qty) public onlyAdmin {
        totalsupply += _qty;
        // 1. new qty can go to deployer
        balances[admin] += _qty;
        // 2. new qty to msg.sender
       // balances[msg.sender] += _qty;
        // 3. new qty to any third party.
        //balances[_newaddr] += _qty;
        
    }
    
    function burn(uint256 _qty) public onlyAdmin {
        require( balances[admin] >= _qty, "Not enough tokens to burn");
        totalsupply -= _qty;
        balances[admin] -= _qty;
    
    }
    
    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }
    
}