pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
    address public pendingOwner;

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: openzeppelin-solidity/contracts/ownership/HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2052454d434f6012">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this Ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {
    /**
    * @dev Constructor that rejects incoming Ether
    * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
    * leave out payable, then Solidity will allow inheriting contracts to implement a payable
    * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
    * we could use assembly to access msg.value.
    */
    constructor() public payable {
        require(msg.value == 0);
    }

    /**
     * @dev Disallows direct send by setting a default function without the `payable` flag.
     */
    function() external {
    }

    /**
     * @dev Transfer all Ether held by the contract to the owner.
     */
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

// File: openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
    using SafeERC20 for ERC20Basic;

    /**
     * @dev Reclaim all ERC20Basic compatible tokens
     * @param token ERC20Basic The address of the token contract
     */
    function reclaimToken(ERC20Basic token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.safeTransfer(owner, balance);
    }
}

// File: openzeppelin-solidity/contracts/ownership/HasNoTokens.sol

/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="afddcac2ccc0ef9d">[email&#160;protected]</a>π.com>
 * @dev This blocks incoming ERC223 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {
    /**
     * @dev Reject all ERC223 compatible tokens
     * @param _from address The address that is transferring the tokens
     * @param _value uint256 the amount of the specified token
     * @param _data Bytes The data passed from the caller.
     */
    function tokenFallback(address _from, uint256 _value, bytes _data) external pure {
        _from;
        _value;
        _data;
        revert();
    }
}

// File: contracts/AddressList.sol

contract AddressList is Claimable {
    string public name;
    mapping(address => bool) public onList;

    constructor(string _name, bool nullValue) public {
        name = _name;
        onList[0x0] = nullValue;
    }

    event ChangeWhiteList(address indexed to, bool onList);

    // Set whether _to is on the list or not. Whether 0x0 is on the list
    // or not cannot be set here - it is set once and for all by the constructor.
    function changeList(address _to, bool _onList) onlyOwner public {
        require(_to != 0x0);
        if (onList[_to] != _onList) {
            onList[_to] = _onList;
            emit ChangeWhiteList(_to, _onList);
        }
    }
}

// File: contracts/NamableAddressList.sol

contract NamableAddressList is AddressList {
    constructor(string _name, bool nullValue)
    AddressList(_name, nullValue) public {}

    function changeName(string _name) onlyOwner public {
        name = _name;
    }
}

// File: openzeppelin-solidity/contracts/ownership/HasNoContracts.sol

/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4d3f28202e220d7f">[email&#160;protected]</a>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable{
    /**
     * @dev Reclaim ownership of Ownable contracts
     * @param contractAddr The address of the Ownable to be reclaimed.
     */
    function reclaimContract(address contractAddr) external onlyOwner {
        Ownable contractInst = Ownable(contractAddr);
        contractInst.transferOwnership(owner);
    }
}

// File: openzeppelin-solidity/contracts/ownership/NoOwner.sol

/**
 * @title Base contract for contracts that should not own things.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a6d4c3cbc5c9e694">[email&#160;protected]</a>π.com>
 * @dev Solves a class of errors where a contract accidentally becomes owner of Ether, Tokens or
 * Owned contracts. See respective base contracts for details.
 */
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

// File: contracts/BalanceSheet.sol

// A wrapper around the balanceOf mapping.
contract BalanceSheet is Claimable {
    using SafeMath for uint256;

    mapping(address => uint256) public balanceOf;

    function addBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].add(_value);
    }

    function subBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].sub(_value);
    }

    function setBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = _value;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Claimable {
    using SafeMath for uint256;

    BalanceSheet public balances;

    uint256 totalSupply_;

    function setBalanceSheet(address sheet) external onlyOwner {
        balances = BalanceSheet(sheet);
        balances.claimOwnership();
    }

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        transferAllArgsNoAllowance(msg.sender, _to, _value);
        return true;
    }

    function transferAllArgsNoAllowance(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(_from != address(0));
        require(_value <= balances.balanceOf(_from));

        // SafeMath.sub will throw if there is not enough balance.
        balances.subBalance(_from, _value);
        balances.addBalance(_to, _value);
        emit Transfer(_from, _to, _value);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances.balanceOf(_owner);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken{
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances.balanceOf(msg.sender));
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances.subBalance(burner, _value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

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

// File: contracts/AllowanceSheet.sol

// A wrapper around the allowanceOf mapping.
contract AllowanceSheet is Claimable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public allowanceOf;

    function addAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].add(_value);
    }

    function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].sub(_value);
    }

    function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = _value;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

contract StandardToken is ERC20, BasicToken {
    AllowanceSheet public allowances;

    function setAllowanceSheet(address sheet) external onlyOwner {
        allowances = AllowanceSheet(sheet);
        allowances.claimOwnership();
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        transferAllArgsYesAllowance(_from, _to, _value, msg.sender);
        return true;
    }

    function transferAllArgsYesAllowance(address _from, address _to, uint256 _value, address spender) internal {
        require(_value <= allowances.allowanceOf(_from, spender));

        allowances.subAllowance(_from, spender, _value);
        transferAllArgsNoAllowance(_from, _to, _value);
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
    function approve(address _spender, uint256 _value) public returns (bool) {
        approveAllArgs(_spender, _value, msg.sender);
        return true;
    }

    function approveAllArgs(address _spender, uint256 _value, address _tokenHolder) internal {
        allowances.setAllowance(_tokenHolder, _spender, _value);
        emit Approval(_tokenHolder, _spender, _value);
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances.allowanceOf(_owner, _spender);
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
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        increaseApprovalAllArgs(_spender, _addedValue, msg.sender);
        return true;
    }

    function increaseApprovalAllArgs(address _spender, uint _addedValue, address tokenHolder) internal {
        allowances.addAllowance(tokenHolder, _spender, _addedValue);
        emit Approval(tokenHolder, _spender, allowances.allowanceOf(tokenHolder, _spender));
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
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        decreaseApprovalAllArgs(_spender, _subtractedValue, msg.sender);
        return true;
    }

    function decreaseApprovalAllArgs(address _spender, uint _subtractedValue, address tokenHolder) internal {
        uint oldValue = allowances.allowanceOf(tokenHolder, _spender);
        if (_subtractedValue > oldValue) {
            allowances.setAllowance(tokenHolder, _spender, 0);
        } else {
            allowances.subAllowance(tokenHolder, _spender, _subtractedValue);
        }
        emit Approval(tokenHolder, _spender, allowances.allowanceOf(tokenHolder, _spender));
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable{
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

// File: contracts/DelegateERC20.sol

contract DelegateERC20 {
    function delegateTotalSupply() public view returns (uint256);

    function delegateBalanceOf(address who) public view returns (uint256);

    function delegateTransfer(address to, uint256 value, address origSender) public returns (bool);

    function delegateAllowance(address owner, address spender) public view returns (uint256);

    function delegateTransferFrom(address from, address to, uint256 value, address origSender) public returns (bool);

    function delegateApprove(address spender, uint256 value, address origSender) public returns (bool);

    function delegateIncreaseApproval(address spender, uint addedValue, address origSender) public returns (bool);

    function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) public returns (bool);
}

// File: contracts/CanDelegate.sol

contract CanDelegate is StandardToken {
    // If this contract needs to be upgraded, the new contract will be stored
    // in &#39;delegate&#39; and any ERC20 calls to this contract will be delegated to that one.
    DelegateERC20 public delegate;

    event DelegateToNewContract(address indexed newContract);

    // Can undelegate by passing in newContract = address(0)
    function delegateToNewContract(DelegateERC20 newContract) public onlyOwner {
        delegate = newContract;
        emit DelegateToNewContract(newContract);
    }

    // If a delegate has been designated, all ERC20 calls are forwarded to it
    function transfer(address to, uint256 value) public returns (bool) {
        if (delegate == address(0)) {
            return super.transfer(to, value);
        } else {
            return delegate.delegateTransfer(to, value, msg.sender);
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (delegate == address(0)) {
            return super.transferFrom(from, to, value);
        } else {
            return delegate.delegateTransferFrom(from, to, value, msg.sender);
        }
    }

    function balanceOf(address who) public view returns (uint256) {
        if (delegate == address(0)) {
            return super.balanceOf(who);
        } else {
            return delegate.delegateBalanceOf(who);
        }
    }

    function approve(address spender, uint256 value) public returns (bool) {
        if (delegate == address(0)) {
            return super.approve(spender, value);
        } else {
            return delegate.delegateApprove(spender, value, msg.sender);
        }
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        if (delegate == address(0)) {
            return super.allowance(_owner, spender);
        } else {
            return delegate.delegateAllowance(_owner, spender);
        }
    }

    function totalSupply() public view returns (uint256) {
        if (delegate == address(0)) {
            return super.totalSupply();
        } else {
            return delegate.delegateTotalSupply();
        }
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        if (delegate == address(0)) {
            return super.increaseApproval(spender, addedValue);
        } else {
            return delegate.delegateIncreaseApproval(spender, addedValue, msg.sender);
        }
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        if (delegate == address(0)) {
            return super.decreaseApproval(spender, subtractedValue);
        } else {
            return delegate.delegateDecreaseApproval(spender, subtractedValue, msg.sender);
        }
    }
}

// File: contracts/StandardDelegate.sol

contract StandardDelegate is StandardToken, DelegateERC20 {
    address public delegatedFrom;

    modifier onlySender(address source) {
        require(msg.sender == source);
        _;
    }

    function setDelegatedFrom(address addr) onlyOwner public {
        delegatedFrom = addr;
    }

    // All delegate ERC20 functions are forwarded to corresponding normal functions
    function delegateTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    function delegateBalanceOf(address who) public view returns (uint256) {
        return balanceOf(who);
    }

    function delegateTransfer(address to, uint256 value, address origSender) onlySender(delegatedFrom) public returns (bool) {
        transferAllArgsNoAllowance(origSender, to, value);
        return true;
    }

    function delegateAllowance(address owner, address spender) public view returns (uint256) {
        return allowance(owner, spender);
    }

    function delegateTransferFrom(address from, address to, uint256 value, address origSender) onlySender(delegatedFrom) public returns (bool) {
        transferAllArgsYesAllowance(from, to, value, origSender);
        return true;
    }

    function delegateApprove(address spender, uint256 value, address origSender) onlySender(delegatedFrom) public returns (bool) {
        approveAllArgs(spender, value, origSender);
        return true;
    }

    function delegateIncreaseApproval(address spender, uint addedValue, address origSender) onlySender(delegatedFrom) public returns (bool) {
        increaseApprovalAllArgs(spender, addedValue, origSender);
        return true;
    }

    function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) onlySender(delegatedFrom) public returns (bool) {
        decreaseApprovalAllArgs(spender, subtractedValue, origSender);
        return true;
    }
}

// File: contracts/TrueVND.sol

contract TrueVND is NoOwner, BurnableToken, CanDelegate, StandardDelegate, PausableToken {
    string public name = "TrueVND";
    string public symbol = "TVND";
    uint8 public constant decimals = 18;

    AddressList public canReceiveMintWhiteList;
    AddressList public canBurnWhiteList;
    AddressList public blackList;
    AddressList public noFeesList;
    address public staker;

    uint256 public burnMin = 1000 * 10 ** uint256(decimals);
    uint256 public burnMax = 20000000 * 10 ** uint256(decimals);

    uint80 public transferFeeNumerator = 8;
    uint80 public transferFeeDenominator = 10000;
    uint80 public mintFeeNumerator = 0;
    uint80 public mintFeeDenominator = 10000;
    uint256 public mintFeeFlat = 0;
    uint80 public burnFeeNumerator = 0;
    uint80 public burnFeeDenominator = 10000;
    uint256 public burnFeeFlat = 0;

    event ChangeBurnBoundsEvent(uint256 newMin, uint256 newMax);
    event Mint(address indexed to, uint256 amount);
    event WipedAccount(address indexed account, uint256 balance);

    constructor() public {
        totalSupply_ = 0;
        staker = msg.sender;
    }

    function setLists(AddressList _canReceiveMintWhiteList, AddressList _canBurnWhiteList, AddressList _blackList, AddressList _noFeesList) onlyOwner public {
        canReceiveMintWhiteList = _canReceiveMintWhiteList;
        canBurnWhiteList = _canBurnWhiteList;
        blackList = _blackList;
        noFeesList = _noFeesList;
    }

    function changeName(string _name, string _symbol) onlyOwner public {
        name = _name;
        symbol = _symbol;
    }

    // Burning functions as withdrawing money from the system. The platform will keep track of who burns coins,
    // and will send them back the equivalent amount of money (rounded down to the nearest cent).
    function burn(uint256 _value) public {
        require(canBurnWhiteList.onList(msg.sender));
        require(_value >= burnMin);
        require(_value <= burnMax);
        uint256 fee = payStakingFee(msg.sender, _value, burnFeeNumerator, burnFeeDenominator, burnFeeFlat, 0x0);
        uint256 remaining = _value.sub(fee);
        super.burn(remaining);
    }

    // Create _amount new tokens and transfer them to _to.
    // Based on code by OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/MintableToken.sol
    function mint(address _to, uint256 _amount) onlyOwner public {
        require(canReceiveMintWhiteList.onList(_to));
        totalSupply_ = totalSupply_.add(_amount);
        balances.addBalance(_to, _amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        payStakingFee(_to, _amount, mintFeeNumerator, mintFeeDenominator, mintFeeFlat, 0x0);
    }

    // Change the minimum and maximum amount that can be burned at once. Burning
    // may be disabled by setting both to 0 (this will not be done under normal
    // operation, but we can&#39;t add checks to disallow it without losing a lot of
    // flexibility since burning could also be as good as disabled
    // by setting the minimum extremely high, and we don&#39;t want to lock
    // in any particular cap for the minimum)
    function changeBurnBounds(uint newMin, uint newMax) onlyOwner public {
        require(newMin <= newMax);
        burnMin = newMin;
        burnMax = newMax;
        emit ChangeBurnBoundsEvent(newMin, newMax);
    }

    // A blacklisted address can&#39;t call transferFrom
    function transferAllArgsYesAllowance(address _from, address _to, uint256 _value, address spender) internal {
        require(!blackList.onList(spender));
        super.transferAllArgsYesAllowance(_from, _to, _value, spender);
    }

    // transfer and transferFrom both ultimately call this function, so we
    // check blacklist and pay staking fee here.
    function transferAllArgsNoAllowance(address _from, address _to, uint256 _value) internal {
        require(!blackList.onList(_from));
        require(!blackList.onList(_to));
        super.transferAllArgsNoAllowance(_from, _to, _value);
        payStakingFee(_to, _value, transferFeeNumerator, transferFeeDenominator, burnFeeFlat, _from);
    }

    function wipeBlacklistedAccount(address account) public onlyOwner {
        require(blackList.onList(account));
        uint256 oldValue = balanceOf(account);
        balances.setBalance(account, 0);
        totalSupply_ = totalSupply_.sub(oldValue);
        emit WipedAccount(account, oldValue);
    }

    function payStakingFee(address payer, uint256 value, uint80 numerator, uint80 denominator, uint256 flatRate, address otherParticipant) private returns (uint256) {
        if (noFeesList.onList(payer) || noFeesList.onList(otherParticipant)) {
            return 0;
        }
        uint256 stakingFee = value.mul(numerator).div(denominator).add(flatRate);
        if (stakingFee > 0) {
            super.transferAllArgsNoAllowance(payer, staker, stakingFee);
        }
        return stakingFee;
    }

    function changeStakingFees(uint80 _transferFeeNumerator,
        uint80 _transferFeeDenominator,
        uint80 _mintFeeNumerator,
        uint80 _mintFeeDenominator,
        uint256 _mintFeeFlat,
        uint80 _burnFeeNumerator,
        uint80 _burnFeeDenominator,
        uint256 _burnFeeFlat) public onlyOwner {
        require(_transferFeeDenominator != 0);
        require(_mintFeeDenominator != 0);
        require(_burnFeeDenominator != 0);
        transferFeeNumerator = _transferFeeNumerator;
        transferFeeDenominator = _transferFeeDenominator;
        mintFeeNumerator = _mintFeeNumerator;
        mintFeeDenominator = _mintFeeDenominator;
        mintFeeFlat = _mintFeeFlat;
        burnFeeNumerator = _burnFeeNumerator;
        burnFeeDenominator = _burnFeeDenominator;
        burnFeeFlat = _burnFeeFlat;
    }

    function changeStaker(address newStaker) public onlyOwner {
        require(newStaker != address(0));
        staker = newStaker;
    }
}

// File: contracts/TimeLockedController.sol

// The TimeLockedController contract is intended to be the initial Owner of the TrueVND
// contract and TrueVND&#39;s AddressLists. It splits ownership into two accounts: an "admin" account and an
// "owner" account. The admin of TimeLockedController can initiate minting TrueVND.
// However, these transactions must be stored for ~1 day&#39;s worth of blocks first before they can be forwarded to the
// TrueVND contract. In the event that the admin account is compromised, this setup allows the owner of TimeLockedController
// (which can be stored extremely securely since it is never used in normal operation) to replace the admin.
// Once a day has passed, requests can be finalized by the admin.
// Requests initiated by an admin that has since been deposed cannot be finalized.
// The admin is also able to update TrueVND&#39;s AddressLists (without a day&#39;s delay).
// The owner can mint without the day&#39;s delay, and also change other aspects of TrueVND like the staking fees.
contract TimeLockedController is HasNoEther, HasNoTokens, Claimable {
    using SafeMath for uint256;

    uint public constant blocksDelay = 24 * 60 * 60 / 15; // 5760 blocks

    struct MintOperation {
        address to;
        uint256 amount;
        address admin;
        uint deferBlock;
    }

    address public admin;
    TrueVND public trueVND;
    MintOperation[] public mintOperations;

    modifier onlyAdminOrOwner() {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    event MintOperationEvent(address indexed _to, uint256 amount, uint deferBlock, uint opIndex);
    event TransferChildEvent(address indexed _child, address indexed _newOwner);
    event ReclaimEvent(address indexed other);
    event ChangeBurnBoundsEvent(uint newMin, uint newMax);
    event WipedAccount(address indexed account);
    event ChangeStakingFeesEvent(uint80 _transferFeeNumerator,
        uint80 _transferFeeDenominator,
        uint80 _mintFeeNumerator,
        uint80 _mintFeeDenominator,
        uint256 _mintFeeFlat,
        uint80 _burnFeeNumerator,
        uint80 _burnFeeDenominator,
        uint256 _burnFeeFlat);
    event ChangeStakerEvent(address newStaker);
    event DelegateEvent(DelegateERC20 delegate);
    event SetDelegatedFromEvent(address source);
    event ChangeTrueVNDEvent(TrueVND newContract);
    event ChangeNameEvent(string name, string symbol);
    event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);

    // admin initiates a request to mint _amount TrueVND for account _to
    function requestMint(address _to, uint256 _amount) public onlyAdminOrOwner {
        uint deferBlock = block.number;
        if (msg.sender != owner) {
            deferBlock = deferBlock.add(blocksDelay);
        }
        MintOperation memory op = MintOperation(_to, _amount, admin, deferBlock);
        emit MintOperationEvent(_to, _amount, deferBlock, mintOperations.length);
        mintOperations.push(op);
    }

    // after a day, admin finalizes mint request by providing the
    // index of the request (visible in the MintOperationEvent accompanying the original request)
    function finalizeMint(uint index) public onlyAdminOrOwner {
        MintOperation memory op = mintOperations[index];
        require(op.admin == admin);
        //checks that the requester&#39;s adminship has not been revoked
        require(op.deferBlock <= block.number);
        //checks that enough time has elapsed
        address to = op.to;
        uint256 amount = op.amount;
        delete mintOperations[index];
        trueVND.mint(to, amount);
    }

    // Transfer ownership of _child to _newOwner
    // Can be used e.g. to upgrade this TimeLockedController contract.
    function transferChild(Ownable _child, address _newOwner) public onlyOwner {
        emit TransferChildEvent(_child, _newOwner);
        _child.transferOwnership(_newOwner);
    }

    // Transfer ownership of a contract from trueVND
    // to this TimeLockedController. Can be used e.g. to reclaim balance sheet
    // in order to transfer it to an upgraded TrueVND contract.
    function requestReclaim(Ownable other) public onlyOwner {
        emit ReclaimEvent(other);
        trueVND.reclaimContract(other);
    }

    // Change the minimum and maximum amounts that TrueVND users can
    // burn to newMin and newMax
    function changeBurnBounds(uint newMin, uint newMax) public onlyOwner {
        emit ChangeBurnBoundsEvent(newMin, newMax);
        trueVND.changeBurnBounds(newMin, newMax);
    }

    function wipeBlacklistedAccount(address account) public onlyOwner {
        emit WipedAccount(account);
        trueVND.wipeBlacklistedAccount(account);
    }

    // Change the transaction fees charged on transfer/mint/burn
    function changeStakingFees(uint80 _transferFeeNumerator,
        uint80 _transferFeeDenominator,
        uint80 _mintFeeNumerator,
        uint80 _mintFeeDenominator,
        uint256 _mintFeeFlat,
        uint80 _burnFeeNumerator,
        uint80 _burnFeeDenominator,
        uint256 _burnFeeFlat) public onlyOwner {
        emit ChangeStakingFeesEvent(_transferFeeNumerator,
            _transferFeeDenominator,
            _mintFeeNumerator,
            _mintFeeDenominator,
            _mintFeeFlat,
            _burnFeeNumerator,
            _burnFeeDenominator,
            _burnFeeFlat);
        trueVND.changeStakingFees(_transferFeeNumerator,
            _transferFeeDenominator,
            _mintFeeNumerator,
            _mintFeeDenominator,
            _mintFeeFlat,
            _burnFeeNumerator,
            _burnFeeDenominator,
            _burnFeeFlat);
    }

    // Change the recipient of staking fees to newStaker
    function changeStaker(address newStaker) public onlyOwner {
        emit ChangeStakerEvent(newStaker);
        trueVND.changeStaker(newStaker);
    }

    // Future ERC20 calls to trueVND be delegated to _delegate
    function delegateToNewContract(DelegateERC20 delegate) public onlyOwner {
        emit DelegateEvent(delegate);
        trueVND.delegateToNewContract(delegate);
    }

    // Incoming delegate* calls from _source will be accepted by trueVND
    function setDelegatedFrom(address _source) public onlyOwner {
        emit SetDelegatedFromEvent(_source);
        trueVND.setDelegatedFrom(_source);
    }

    // Update this contract&#39;s trueVND pointer to newContract (e.g. if the
    // contract is upgraded)
    function setTrueVND(TrueVND newContract) public onlyOwner {
        emit ChangeTrueVNDEvent(newContract);
        trueVND = newContract;
    }

    // change trueVND&#39;s name and symbol
    function changeName(string name, string symbol) public onlyOwner {
        emit ChangeNameEvent(name, symbol);
        trueVND.changeName(name, symbol);
    }

    // Replace the current admin with newAdmin
    function transferAdminship(address newAdmin) public onlyOwner {
        emit AdminshipTransferred(admin, newAdmin);
        admin = newAdmin;
    }

    // Swap out TrueVND&#39;s address lists
    function setLists(AddressList _canReceiveMintWhiteList, AddressList _canBurnWhiteList, AddressList _blackList, AddressList _noFeesList) onlyOwner public {
        trueVND.setLists(_canReceiveMintWhiteList, _canBurnWhiteList, _blackList, _noFeesList);
    }

    // Update a whitelist/blacklist
    function updateList(address list, address entry, bool flag) public onlyAdminOrOwner {
        AddressList(list).changeList(entry, flag);
    }

    // Rename a whitelist/blacklist
    function renameList(address list, string name) public onlyAdminOrOwner {
        NamableAddressList(list).changeName(name);
    }

    // Claim ownership of an arbitrary Claimable contract
    function issueClaimOwnership(address _other) public onlyAdminOrOwner {
        Claimable other = Claimable(_other);
        other.claimOwnership();
    }
}