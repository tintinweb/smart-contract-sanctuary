pragma solidity ^0.4.17;

/* ERC20 contract interface */
/* With ERC23/ERC223 Extensions */
/* Fully backward compatible with ERC20 */
/* Recommended implementation used at https://github.com/Dexaran/ERC223-token-standard/tree/Recommended */
contract ERC20 {
    uint public totalSupply;

    // ERC223 and ERC20 functions and events
    function balanceOf(address who) public constant returns (uint);
    function totalSupply() constant public returns (uint256 _supply);
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string customFallback) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);

    // ERC223 functions
    function name() constant public returns (string _name);
    function symbol() constant public returns (string _symbol);
    function decimals() constant public returns (uint8 _decimals);

    // ERC20 functions and events
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * Include SafeMath Lib
 */
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y)
            revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y) {
            revert();
        }
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        if (x > MAX_UINT256 / y) {
            revert();
        }
        return x * y;
    }
}

/*
 * Contract that is working with ERC223 tokens
 */
 contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);

      /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
    }
}

/*
 * EDOGE is an ERC20 token with ERC223 Extensions
 */
contract TERATO is ERC20, SafeMath {

    string public name = "TERATO";

    string public symbol = "TERA";

    uint8 public decimals = 8;

    uint256 public totalSupply = 68000000 * 10**8;

    address public owner;


    bool public tokenCreated = false;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    function TERATO() public {

        // Security check in case EVM has future flaw or exploit to call constructor multiple times
        // Ensure token gets created once only
        require(tokenCreated == false);
        tokenCreated = true;

        owner = msg.sender;
        balances[owner] = totalSupply;

        // Final sanity check to ensure owner balance is greater than zero
        require(balances[owner] > 0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    // Function to access name of token .sha
    function name() constant public returns (string _name) {
        return name;
    }
    // Function to access symbol of token .
    function symbol() constant public returns (string _symbol) {
        return symbol;
    }
    // Function to access decimals of token .
    function decimals() constant public returns (uint8 _decimals) {
        return decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() constant public returns (uint256 _totalSupply) {
        return totalSupply;
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {

        if (isContract(_to)) {
            if (balanceOf(msg.sender) < _value) {
                revert();
            }
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data);
            Transfer(msg.sender, _to, _value, _data);
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) public  returns (bool success) {

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) public returns (bool success) {
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    // assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    // function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) {
            revert();
        }
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) {
            revert();
        }
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // Get balance of the address provided
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    // Allow transfers if the owner provided an allowance
    // Prevent from any transfers if token is not yet unlocked
    // Use SafeMath for the main logic
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Protect against wrapping uints.
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        balances[_from] = safeSub(balanceOf(_from), _value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}