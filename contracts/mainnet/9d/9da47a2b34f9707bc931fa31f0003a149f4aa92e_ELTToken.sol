pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 _value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
// ----------------------------------------------------------------------------
// ERC Token Standard #223 Interface
// https://github.com/Dexaran/ERC223-token-standard/token/ERC223/ERC223_interface.sol
// ----------------------------------------------------------------------------
contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) constant public returns (uint);
    function transfer(address to, uint value, bytes data) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
contract ELTTokenType {
    uint public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;

    mapping(address => uint) timevault;
    mapping(address => mapping(address => uint)) allowed;
    
    // Token release switch
    bool public released;
    
    // The date before the release must be finalized or upgrade path will be forced
    uint public releaseFinalizationDate;
}
contract ContractReceiver {
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
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
/**
 * @title Owned
 * @dev To verify ownership
 */
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
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
}
contract ERC20Token is ERC20Interface, ERC223Interface, ELTTokenType {
    using SafeMath for uint;

    function transfer(address _to, uint _value) public returns (bool success) {
        bytes memory empty;
        return transfer(_to, _value, empty);
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data, false);
        }
        else {
            return transferToAddress(_to, _value, _data, false);
        }
    }
    
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     */
    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }


    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly
        {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
    

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data, bool withAllowance) private returns (bool success) {
        transferIfRequirementsMet(msg.sender, _to, _value, withAllowance);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data, bool withAllowance) private returns (bool success) {
        transferIfRequirementsMet(msg.sender, _to, _value, withAllowance);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function checkTransferRequirements(address _from, address _to, uint _value) private view {
        require(_to != address(0));
        require(released == true);
        require(now > releaseFinalizationDate);
        if (timevault[msg.sender] != 0)
        {
            require(now > timevault[msg.sender]);
        }
        if (balanceOf(_from) < _value) revert();
    }

    function transferIfRequirementsMet(address _from, address _to, uint _value, bool withAllowances) private {
        checkTransferRequirements(_from, _to, _value);
        if ( withAllowances)
        {
            require (_value <= allowed[_from][msg.sender]);
        }
        balances[_from] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
    }
    
    function transferFrom(address from, address to, uint value) public returns (bool) {
        bytes memory empty;
        if (isContract(to)) {
            return transferToContract(to, value, empty, true);
        }
        else {
            return transferToAddress(to, value, empty, true);
        }
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        return true;
      }
}
contract TimeVaultInterface is ERC20Interface, ERC223Interface {
    function timeVault(address who) public constant returns (uint);
    function getNow() public constant returns (uint);
    function transferByOwner(address to, uint _value, uint timevault) public returns (bool);
}
contract TimeVaultToken is owned, ERC20Token, TimeVaultInterface {
    function transferByOwner(address to, uint value, uint earliestReTransferTime) onlyOwner public returns (bool) {
        transfer(to, value);
        timevault[to] = earliestReTransferTime;
        return true;
    }

    function timeVault(address owner) public constant returns (uint earliestTransferTime) {
        return timevault[owner];
    }

    function getNow() public constant returns (uint blockchainTimeNow) {
        return now;
    }

}
contract StandardToken is TimeVaultToken {
    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}
contract StandardTokenExt is StandardToken {
    
    /* Interface declaration */
    function isToken() public pure returns (bool weAre) {
        return true;
    }
}
contract VersionedToken is owned {
    address public upgradableContractAddress;

    function VersionedToken(address initialVersion) public {
        upgradableContractAddress = initialVersion;
    }

    function update(address newVersion) onlyOwner public {
        upgradableContractAddress = newVersion;
    }

    function() public {
        address upgradableContractMem = upgradableContractAddress;
        bytes memory functionCall = msg.data;

        assembly {
        // Load the first 32 bytes of the functionCall bytes array which represents the size of the bytes array
            let functionCallSize := mload(functionCall)

        // Calculate functionCallDataAddress which starts at the second 32 byte block in the functionCall bytes array
            let functionCallDataAddress := add(functionCall, 0x20)

        // delegatecall(gasAllowed, callAddress, inMemAddress, inSizeBytes, outMemAddress, outSizeBytes) returns/pushes to stack (1 on success, 0 on failure)
            let functionCallResult := delegatecall(gas, upgradableContractMem, functionCallDataAddress, functionCallSize, 0, 0)

            let freeMemAddress := mload(0x40)

            switch functionCallResult
            case 0 {
            // revert(fromMemAddress, sizeInBytes) ends execution and returns value
                revert(freeMemAddress, 0)
            }
            default {
            // returndatacopy(toMemAddress, fromMemAddress, sizeInBytes)
                returndatacopy(freeMemAddress, 0x0, returndatasize)
            // return(fromMemAddress, sizeInBytes)
                return (freeMemAddress, returndatasize)
            }
        }
    }
}
contract ELTToken is VersionedToken, ELTTokenType {
    string public name;
    string public symbol;
    
    function ELTToken(address _owner, string _name, string _symbol, uint _totalSupply, uint _decimals, uint _releaseFinalizationDate, address _initialVersion) VersionedToken(_initialVersion) public {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        decimals = _decimals;

        // Allocate initial balance to the owner
        balances[_owner] = _totalSupply;

        releaseFinalizationDate = _releaseFinalizationDate;
        released = false;
    }
}
contract ELTTokenImpl is StandardTokenExt {
    /** Name and symbol were updated. */
    event UpdatedTokenInformation(string newName, string newSymbol);

    string public name;
    string public symbol;
    
    function ELTTokenImpl() public {
    }

    /**
     * One way function to perform the final token release.
     */
    function releaseTokenTransfer(bool _value) onlyOwner public {
        released = _value;
    }

    function setreleaseFinalizationDate(uint _value) onlyOwner public {
        releaseFinalizationDate = _value;
    }

    /**
     * Owner can update token information here.
     *
     * It is often useful to conceal the actual token association, until
     * the token operations, like central issuance or reissuance have been completed.
     * In this case the initial token can be supplied with empty name and symbol information.
     *
     * This function allows the token owner to rename the token after the operations
     * have been completed and then point the audience to use the token contract.
     */
    function setTokenInformation(string _name, string _symbol) onlyOwner public {
        name = _name;
        symbol = _symbol;
        emit UpdatedTokenInformation(name, symbol);
    }
}