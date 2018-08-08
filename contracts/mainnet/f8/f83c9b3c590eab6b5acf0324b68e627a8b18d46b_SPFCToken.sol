pragma solidity ^0.4.22;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 _value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
// ----------------------------------------------------------------------------
// ERC Token Standard #223 Interface
// https://github.com/Dexaran/ERC223-token-standard/token/ERC223/ERC223_interface.sol
// ----------------------------------------------------------------------------
contract ERC223Interface {
    uint public totalSupply;
    function transfer(address to, uint value, bytes data) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
/**
 * @title Owned
 * @dev To verify ownership
 */
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}
/**
 * As part of the ERC223 standard we need to call the fallback of the token
 */
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
contract TimeVaultInterface is ERC20Interface, ERC223Interface {
    function timeVault(address who) public constant returns (uint);
    function getNow() public constant returns (uint);
    function transferByOwner(address to, uint _value, uint timevault) public returns (bool);
}
/**
 * All meta information for the Token must be defined here so that it can be accessed from both sides of proxy
 */
contract SPFCTokenType {
    uint public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;

    mapping(address => uint) timevault;
    mapping(address => mapping(address => uint)) allowed;

    // Token release switch
    bool public released;

    // The date before the release must be finalized (a unix timestamp)
    uint public globalTimeVault;

    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract ERC20Token is ERC20Interface, ERC223Interface, SPFCTokenType {
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
            return transferToAddress(_to, _value, false);
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
    function transferToAddress(address _to, uint _value, bool withAllowance) private returns (bool success) {
        transferIfRequirementsMet(msg.sender, _to, _value, withAllowance);
        emit Transfer(msg.sender, _to, _value);
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

    // Function to verify that all the requirements to transfer are satisfied
    // The destination is not the null address
    // The tokens have been released for sale
    // The sender&#39;s tokens are not locked in a timevault
    function checkTransferRequirements(address _to, uint _value) private view {
        require(_to != address(0));
        require(released == true);
        require(now > globalTimeVault);
        if (timevault[msg.sender] != 0)
        {
            require(now > timevault[msg.sender]);
        }
        require(balanceOf(msg.sender) >= _value);
    }

    // Do the transfer if the requirements are met
    function transferIfRequirementsMet(address _from, address _to, uint _value, bool withAllowances) private {
        checkTransferRequirements(_to, _value);
        if ( withAllowances)
        {
            require (_value <= allowed[_from][msg.sender]);
        }
        balances[_from] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
    }

    // Transfer from one address to another taking into account ERC223 condition to verify that the to address is a contract or not
    function transferFrom(address from, address to, uint value) public returns (bool) {
        bytes memory empty;
        if (isContract(to)) {
            return transferToContract(to, value, empty, true);
        }
        else {
            return transferToAddress(to, value, true);
        }
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        return true;
    }
}
contract TimeVaultToken is  owned, TimeVaultInterface, ERC20Token {

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
contract OwnershipTransferrable is TimeVaultToken {

    event OwnershipTransferred(address indexed _from, address indexed _to);


    function transferOwnership(address newOwner) onlyOwner public {
        transferByOwner(newOwner, balanceOf(owner), 0);
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

}
contract VersionedToken is owned {
    address public upgradableContractAddress;

    /**
     * Constructor:
     *  initialVersion - the address of the initial version of the implementation for the contract
     *
     * Note that this implementation must be visible to the relay contact even though it will not be a subclass
     * do this by importing the main contract that implements it.  If the code is not visible it will not
     * always be accessible through the delegatecall() function.  And even if it is, it will take an unlimited amount
     * of gas to process the call.
     *
     * In our case this it is SPFCTokenImpl.sol
     * e.g.
     *    import "SPFCToken.sol"
     *
     * Please note: IMPORTANT
     * do not implement any function called "update()" otherwise it will break the Versioning system
     */
    constructor(address initialImplementation) public {
        upgradableContractAddress = initialImplementation;
    }

    /**
     * update
     * Call to upgrade the implementation version of this constract
     *  newVersion: this is the address of the new implementation for the contract
     */

    function upgradeToken(address newImplementation) onlyOwner public {
        upgradableContractAddress = newImplementation;
    }

    /**
     * This is the fallback function that is called whenever a contract is called but can&#39;t find the called function.
     * In this case we delegate the call to the implementing contract SPFCTokenImpl
     *
     * Instead of using delegatecall() in Solidity we use the assembly because it allows us to return values to the caller
     */
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
contract SPFCToken is VersionedToken, SPFCTokenType {
    string public name;
    string public symbol;

    constructor(address _tokenOwner, string _tokenName, string _tokenSymbol, uint _totalSupply, uint _decimals, uint _globalTimeVaultOpeningTime, address _initialImplementation) VersionedToken(_initialImplementation)  public {
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** uint(decimals);
        // Allocate initial balance to the owner
        balances[_tokenOwner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
        globalTimeVault = _globalTimeVaultOpeningTime;
        released = false;

    }
}
contract SPFCTokenImpl is StandardTokenExt {
    /** Name and symbol were updated. */
    event UpdatedTokenInformation(string newName, string newSymbol);

    string public name;
    string public symbol;

    /**
     * One way function to perform the final token release.
     */
    function releaseTokenTransfer(bool _value) onlyOwner public {
        released = _value;
    }

    function setGlobalTimeVault(uint _globalTimeVaultOpeningTime) onlyOwner public {
        globalTimeVault = _globalTimeVaultOpeningTime;
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
    function setTokenInformation(string _tokenName, string _tokenSymbol) onlyOwner public {
        name = _tokenName;
        symbol = _tokenSymbol;
        emit UpdatedTokenInformation(name, symbol);
    }
}