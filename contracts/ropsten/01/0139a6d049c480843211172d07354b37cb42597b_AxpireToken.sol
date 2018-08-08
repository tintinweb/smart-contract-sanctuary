pragma solidity ^0.4.15;
//Owner Contract-For Defining Owner and Transferring Ownership
contract Ownable {
    address public owner;

    function Ownable() public {
        owner = 0x2e1977127F682723C778bBcac576A4aF2c0e790d;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}



//Token Format
contract ERC20 is Ownable {
    using SafeMath for uint256;
    //Public Variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;


    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) public allowed;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    //Constructor
    function ERC20(
    uint256 _initialSupply,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol
    ) public
    {

        balances[0x2e1977127F682723C778bBcac576A4aF2c0e790d] = _initialSupply;
        totalSupply = _initialSupply;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        name = _tokenName;
    }

    /* public methods */
    function transfer(address _to, uint256 _value) public  returns (bool) {


        bool status = transferInternal(msg.sender, _to, _value);

        require(status == true);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {


        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {


        TokenRecipient spender = TokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {


        if (allowed[_from][msg.sender] < _value) {
            return false;
        }

        bool _success = transferInternal(_from, _to, _value);

        if (_success) {
            allowed[_from][msg.sender] -= _value;
        }

        return _success;
    }

    /*constant functions*/
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _address) public constant returns (uint256 balance) {
        return balances[_address];
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* internal functions*/
    function setBalance(address _holder, uint256 _amount) internal {
        balances[_holder] = _amount;
    }

    function transferInternal(address _from, address _to, uint256 _value) internal returns (bool success) {

        if (_value == 0) {
            Transfer(_from, _to, _value);

            return true;
        }

        if (balances[_from] < _value) {
            return false;
        }

        setBalance(_from, balances[_from].sub(_value));
        setBalance(_to, balances[_to].add(_value));

        Transfer(_from, _to, _value);

        return true;
    }
}

contract ERC223 {
    event Transfer(address indexed from, address indexed to, uint value, bytes  data);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string customFallback) public returns (bool ok);
}


contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}


/******************************************/
/** Axpire TOKEN **/
/******************************************/
contract AxpireToken is ERC223,ERC20 {

    uint256 initialSupply= 350000000 * 10**8;
    string tokenName="aXpire Token";
    string tokenSymbol="AXP";
    uint8 decimalUnits=8;

    //Constructor
    function AxpireToken() public
    ERC20(initialSupply, tokenName, decimalUnits, tokenSymbol)
    {
        owner = 0x2e1977127F682723C778bBcac576A4aF2c0e790d;
        //Assigning total no of tokens
        balances[owner] = initialSupply;
        totalSupply = initialSupply;
    }


    function transfer(address to, uint256 value, bytes data) public returns (bool success) {

        bool status = transferInternal(msg.sender, to, value, data);

        return status;
    }

    function transfer(address to, uint value, bytes data, string customFallback) public returns (bool success) {

        bool status = transferInternal(msg.sender, to, value, data, true, customFallback);

        return status;
    }

    // rollback changes to transferInternal for transferFrom
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        if (allowed[_from][msg.sender] < _value) {
            return false;
        }

        bool _success = super.transferInternal(_from, _to, _value);

        if (_success) {
            allowed[_from][msg.sender] -= _value;
        }

        return _success;
    }

    function transferInternal(address from, address to, uint256 value, bytes data) internal returns (bool success) {
        return transferInternal(from, to, value, data, false, "");
    }

    function transferInternal(
    address from,
    address to,
    uint256 value,
    bytes data,
    bool useCustomFallback,
    string customFallback
    )
    internal returns (bool success)
    {
        bool status = super.transferInternal(from, to, value);

        if (status) {
            if (isContract(to)) {
                ContractReceiver receiver = ContractReceiver(to);

                if (useCustomFallback) {
                    // solhint-disable-next-line avoid-call-value
                    require(receiver.call.value(0)(bytes4(keccak256(customFallback)), from, value, data) == true);
                } else {
                    receiver.tokenFallback(from, value, data);
                }
            }

            Transfer(from, to, value, data);
        }

        return status;
    }

    function transferInternal(address from, address to, uint256 value) internal returns (bool success) {

        bytes memory data;

        return transferInternal(from, to, value, data, false, "");
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool) {
        uint length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
        length := extcodesize(_addr)
        }
        return (length > 0);
    }

}