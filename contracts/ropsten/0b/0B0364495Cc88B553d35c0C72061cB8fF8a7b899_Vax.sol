/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity 0.5.0;

contract Vax {
    
    address admin;
    constructor (uint256 _qty, string memory _name,
                    string memory _symbol, uint8 _decimal) public {
        tsupply = _qty;
        admin = msg.sender;
        balances[msg.sender] = tsupply;
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
        
    }
    string name_;
    function name() public view returns (string memory){
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
    
    uint256 tsupply;
    function totalSupply() public view returns (uint256){
        return tsupply;
    }
    mapping (address => uint256) balances;
    function balanceOf(address _user) public view returns (uint256 balance) {
            return balances[_user];
    }
    event Transfer(address indexed Sender, address indexed Receipient, uint256 NumTokens);
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender] >= _value, "Insufficient balance");
        //balances[msg.sender] = balances[msg.sender] - _value;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from]>= _value, "Not enough tokens to spend");
        require(allowed[_from][msg.sender]>= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
        
    }
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping(address => mapping(address => uint256)) allowed;
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    
    
    
    // Mint - Add totalSupply
    
    modifier onlyAdmin {
        require(msg.sender==admin, "Only admin");
        _;
    }
    function mint(uint256 _qty, address _to) public onlyAdmin returns(bool) {
        tsupply += _qty;
        balances[_to] += _qty;
        return true;
    }
    
    function burn(uint256 _qty) public onlyAdmin returns(bool){
        require(balances[admin] >= _qty, "Not enough tokens to burn");
        tsupply -= _qty;
        balances[admin] -= _qty;
        return true;
    }
    
    // Owner - 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // Spender - 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // _to - 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c
    /*
        a = a-b; 
        a-=b;
        
        a = a+b;
        a += b;
        */
}