pragma solidity ^0.4.23;

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 *
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 */

library ECRecoveryLibrary {

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * @dev and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(
            "\x19Ethereum Signed Message:\n32",
            hash
        );
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMathLibrary {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    bool public paused = false;

    event Pause();

    event Unpause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

interface TokenReceiver {
    function tokenFallback(address _from, uint _value) external returns(bool);
}

contract Token is Pausable {
    using SafeMathLibrary for uint;

    using ECRecoveryLibrary for bytes32;

    uint public decimals = 18;

    mapping (address => uint) balances;

    mapping (address => mapping (address => uint)) allowed;

    mapping(bytes => bool) signatures;

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

    event DelegatedTransfer(address indexed from, address indexed to, address indexed delegate, uint amount, uint fee);

    function () {
        revert();
    }

    /**
    * @dev Gets the balance of the specified address.
    *
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) constant public returns (uint) {
        return balances[_owner];
    }

    /**
    * @dev transfer token for a specified address
    *
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) whenNotPaused public returns (bool) {
        require(_to != address(0) && _value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        callTokenFallback(_to, msg.sender, _value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function delegatedTransfer(bytes _signature, address _to, uint _value, uint _fee, uint _nonce) whenNotPaused public returns (bool) {
        require(_to != address(0) && signatures[_signature] == false);

        bytes32 hashedTx = hashDelegatedTransfer(_to, _value, _fee, _nonce);
        address from = hashedTx.recover(_signature);

        require(from != address(0) && _value.add(_fee) <= balances[from]);

        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        signatures[_signature] = true;

        callTokenFallback(_to, from, _value);

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit DelegatedTransfer(from, _to, msg.sender, _value, _fee);
        return true;
    }

    function hashDelegatedTransfer(address _to, uint _value, uint _fee, uint _nonce) public view returns (bytes32) {
        /* “45b56ba6”: delegatedTransfer(bytes,address,uint,uint,uint) */ // orig: 48664c16
        return keccak256(bytes4(0x45b56ba6), address(this), _to, _value, _fee, _nonce);
    }

    /**
     * @dev Transfer tokens from one address to another
     *
     * @param _from The address which you want to send tokens from
     * @param _to The address which you want to transfer to
     * @param _value the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint _value) whenNotPaused public returns (bool ok) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        callTokenFallback(_to, _from, _value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value) whenNotPaused public returns (bool ok) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) constant public returns (uint) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) whenNotPaused public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) whenNotPaused public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function callTokenFallback(address _contract, address _from, uint _value) internal {
        if (isContract(_contract)) {
            require(contracts[_contract] != address(0) && balances[_contract] >= contractHoldBalance);
            TokenReceiver receiver = TokenReceiver(_contract);
            require(receiver.tokenFallback(_from, _value));
        }
    }

    function isContract(address _address) internal view returns(bool) {
        uint length;
        assembly {
            length := extcodesize(_address)
        }
        return (length > 0);
    }

    // contract => owner
    mapping (address => address) contracts;

    uint contractHoldBalance = 500 * 10 ** decimals;

    function setContractHoldBalance(uint _value) whenNotPaused onlyOwner public returns(bool) {
        contractHoldBalance = _value;
        return true;
    }

    function register(address _contract) whenNotPaused public returns(bool) {
        require(isContract(_contract) && contracts[_contract] == address(0) && balances[msg.sender] >= contractHoldBalance);
        balances[msg.sender] = balances[msg.sender].sub(contractHoldBalance);
        balances[_contract] = balances[_contract].add(contractHoldBalance);
        contracts[_contract] = msg.sender;
        return true;
    }

    function unregister(address _contract) whenNotPaused public returns(bool) {
        require(isContract(_contract) && contracts[_contract] == msg.sender);
        balances[_contract] = balances[_contract].sub(contractHoldBalance);
        balances[msg.sender] = balances[msg.sender].add(contractHoldBalance);
        delete contracts[_contract];
        return true;
    }
}

contract CATT is Token {
    string public name = "Content Aggregation Transfer Token";

    string public symbol = "CATT";

    uint public totalSupply = 5000000000 * 10 ** decimals;

    constructor() public {
        balances[owner] = totalSupply;
    }
}