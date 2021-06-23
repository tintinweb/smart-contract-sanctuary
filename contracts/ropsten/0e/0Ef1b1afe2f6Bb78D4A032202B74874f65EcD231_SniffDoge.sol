/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.5.0;

contract SniffDoge {
    
    address admin;
    constructor (uint256 _qty, string memory _name, string memory _symbol, uint8 _decimal) public {
        tsupply = _qty*10**decimal_;
        // _qty is the number of complete tokens , followed by decimal places in totalsupply.
        // _qty = 1000, decimal_ = 4, complete tokens = 1000/10**4  = 0.1 
        balances[msg.sender] = tsupply;
        admin = msg.sender;
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
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
        // 10**18 wei = 1 ether, eth can have 18 places of decimal, 
        // 1 wei = 0.000000000000000001 eth.
        return decimal_;
    }

    uint256 tsupply;
    function totalSupply() public view returns (uint256) {
        return tsupply;
    }
    
    mapping ( address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require( balances[msg.sender] >= _value, "Insufficient balance");
        //balances[msg.sender] = balances[msg.sender] - _value;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
        /*
        a = a+1 ; // if old value of a = 10 , new value is 10+1 = 11.
        a += 1;
        
        b = b - 10 ; // If old value of b = 100, new value is 100 - 10 = 90.
        b -= 10;
        */
        
    }
    
    // Mint & Burn functions to increase or decrease the total supply.
    
    modifier onlyAdmin {
        require( msg.sender == admin, "Only admin is authorized");
        _;
    }
    
    function mint(uint256 _addNumTokens) public onlyAdmin {
        tsupply += _addNumTokens;
        balances[admin] += _addNumTokens;
        //balances[msg.sender] += _addNumTokens;
        
    }
    
    function burn(uint256 _subNumTokens) public onlyAdmin {
        require( balances[admin] >= _subNumTokens, "Not enough tokens to burn");
        tsupply -= _subNumTokens;
        balances[admin] -= _subNumTokens;
        
    }
    
    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    } 
    
    function renounceAdmin() public onlyAdmin {
        admin = address(0);
    }
    
    
    // Owner - Owner of tokens
    // Spender - Authorized by owner to spend on his behalf.
    //  Beneficiary - Receiver of tokens.
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (balances[_from] >= _value, "Insufficient balance");
        require( allowed[_from][msg.sender] >= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer (_from, _to, _value);
        return true;
    }

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping ( address => mapping (address => uint256)) allowed;
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
}