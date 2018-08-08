pragma solidity ^0.4.24;
 
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data);
}
 
contract SDD_Erc223Token is SafeMath, Owned {    
    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);

    mapping(address => uint) balances;
    
    //address public owner    = msg.sender;
    string public name    = "SDD Erc223";
    string public symbol  = "SDD";
    uint8 public decimals = 8;
    uint256 public totalSupply;
    
    function SDD_Erc223Token()
    {
        totalSupply = 10000000000 * 10**uint(decimals);
        balances[owner] = totalSupply;        
        //balances[owner] = 10000000000 * (10 ** decimals);
        //totalSupply = balances[owner];
    }
        
    // Function to access name of token .
    function name() constant returns (string _name) {
        return name;
    }
    // Function to access symbol of token .
    function symbol() constant returns (string _symbol) {
        return symbol;
    }
    // Function to access decimals of token .
    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    
    
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) returns (bool success) {
        
        if(isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert();
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            assert(_to.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
  

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
  
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) returns (bool success) {
        
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        assembly {
                //retrieve the size of the code on target address, this needs assembly
                length := extcodesize(_addr)
        }
        return (length>0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }


    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}