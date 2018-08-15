pragma solidity ^0.4.11;

contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    function transfer(address to, uint value, bytes data)public ;
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
/**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
 

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure  returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  
}

contract StandardAuth is ERC223Interface {
    address      public  owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

/**
 * @title Reference implementation of the ERC223 standard token.
 */
contract StandardToken is StandardAuth {
    using SafeMath for uint;

    mapping(address => uint) balances; // List of user balances.
    mapping(address => bool) optionPoolMembers; //
    string public name;
    string public symbol;
    uint8 public decimals = 9;
    uint256 public totalSupply;
    uint256 public optionPoolMembersUnlockTime = 1534168800;
    address public optionPool;
    uint256 public optionPoolTotalMax;
    uint256 public optionPoolTotal = 0;
    uint256 public optionPoolMembersAmount = 0;
    
    modifier verifyTheLock {
        if(optionPoolMembers[msg.sender] == true) {
            if(now < optionPoolMembersUnlockTime) {
                revert();
            } else {
                _;
            }
        } else {
            _;
        }
    }
    
    // Function to access name of token .
    function name() public view returns (string _name) {
        return name;
    }
    // Function to access symbol of token .
    function symbol() public view returns (string _symbol) {
        return symbol;
    }
    // Function to access decimals of token .
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }
    // Function to access option pool of tokens .
    function optionPool() public view returns (address _optionPool) {
        return optionPool;
    }
    // Function to access option option pool total of tokens .
    function optionPoolTotal() public view returns (uint256 _optionPoolTotal) {
        return optionPoolTotal;
    }
    // Function to access option option pool total max of tokens .
    function optionPoolTotalMax() public view returns (uint256 _optionPoolTotalMax) {
        return optionPoolTotalMax;
    }
    
    function optionPoolBalance() public view returns (uint256 _optionPoolBalance) {
        return balances[optionPool];
    }
    
    function verifyOptionPoolMembers(address _add) public view returns (bool _verifyResults) {
        return optionPoolMembers[_add];
    }
    
    function optionPoolMembersAmount() public view returns (uint _optionPoolMembersAmount) {
        return optionPoolMembersAmount;
    }
    
    function optionPoolMembersUnlockTime() public view returns (uint _optionPoolMembersUnlockTime) {
        return optionPoolMembersUnlockTime;
    }
  
    constructor(uint256 _initialAmount, string _tokenName, string _tokenSymbol, address _tokenOptionPool, uint256 _tokenOptionPoolTotalMax) public  {
        balances[msg.sender] = _initialAmount;               //
        totalSupply = _initialAmount;                        //
        name = _tokenName;                                   //
        symbol = _tokenSymbol;                               //
        optionPool = _tokenOptionPool;
        optionPoolTotalMax = _tokenOptionPoolTotalMax;
    }
   
    function _verifyOptionPoolIncome(address _to, uint _value) private returns (bool _verifyIncomeResults) {
        if(msg.sender == optionPool && _to == owner){
          return false;
        }
        if(_to == optionPool) {
            if(optionPoolTotal + _value <= optionPoolTotalMax){
                optionPoolTotal = optionPoolTotal.add(_value);
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }
    
    function _verifyOptionPoolDefray(address _to) private returns (bool _verifyDefrayResults) {
        if(msg.sender == optionPool) {
            if(optionPoolMembers[_to] != true){
              optionPoolMembers[_to] = true;
              optionPoolMembersAmount++;
            }
        }
        
        return true;
    }
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes _data) public verifyTheLock {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }
        
        if (balanceOf(msg.sender) < _value) revert();
        require(_verifyOptionPoolIncome(_to, _value));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        _verifyOptionPoolDefray(_to);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn&#39;t contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value) public verifyTheLock {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }
        
        if (balanceOf(msg.sender) < _value) revert();
        require(_verifyOptionPoolIncome(_to, _value));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        _verifyOptionPoolDefray(_to);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
    }
    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
}