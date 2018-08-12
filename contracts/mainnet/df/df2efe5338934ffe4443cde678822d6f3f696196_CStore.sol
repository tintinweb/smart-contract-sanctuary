/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Owned
 * @author Adria Massanet <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1d7c796f747c5d7e7279787e727369786569337472">[email&#160;protected]</a>>
 * @notice The Owned contract has an owner address, and provides basic
 *  authorization control functions, this simplifies & the implementation of
 *  user permissions; this contract has three work flows for a change in
 *  ownership, the first requires the new owner to validate that they have the
 *  ability to accept ownership, the second allows the ownership to be
 *  directly transferred without requiring acceptance, and the third allows for
 *  the ownership to be removed to allow for decentralization
 */
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

    /**
     * @dev The constructor sets the `msg.sender` as the`owner` of the contract
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev `owner` is the only address that can call a function with this
     * modifier
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev In this 1st option for ownership transfer `proposeOwnership()` must
     *  be called first by the current `owner` then `acceptOwnership()` must be
     *  called by the `newOwnerCandidate`
     * @notice `onlyOwner` Proposes to transfer control of the contract to a
     *  new owner
     * @param _newOwnerCandidate The address being proposed as the new owner
     */
    function proposeOwnership(address _newOwnerCandidate) external onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        emit OwnershipRequested(msg.sender, newOwnerCandidate);
    }

    /**
     * @notice Can only be called by the `newOwnerCandidate`, accepts the
     *  transfer of ownership
     */
    function acceptOwnership() external {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * @dev In this 2nd option for ownership transfer `changeOwnership()` can
     *  be called and it will immediately assign ownership to the `newOwner`
     * @notice `owner` can step down and assign some other address to this role
     * @param _newOwner The address of the new owner
     */
    function changeOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * @dev In this 3rd option for ownership transfer `removeOwnership()` can
     *  be called and it will immediately assign ownership to the 0x0 address;
     *  it requires a 0xdece be input as a parameter to prevent accidental use
     * @notice Decentralizes the contract, this operation cannot be undone
     * @param _dac `0xdac` has to be entered for this function to work
     */
    function removeOwnership(address _dac) external onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        emit OwnershipRemoved();
    }
}

contract ERC820Registry {
    function getManager(address addr) public view returns(address);
    function setManager(address addr, address newManager) public;
    function getInterfaceImplementer(address addr, bytes32 iHash) public constant returns (address);
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;
}

contract ERC820Implementer {
    ERC820Registry public erc820Registry;

    constructor(address _registry) public {
        erc820Registry = ERC820Registry(_registry);
    }

    function setInterfaceImplementation(string ifaceLabel, address impl) internal {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        erc820Registry.setInterfaceImplementer(this, ifaceHash, impl);
    }

    function interfaceAddr(address addr, string ifaceLabel) internal constant returns(address) {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        return erc820Registry.getInterfaceImplementer(addr, ifaceHash);
    }

    function delegateManagement(address newManager) internal {
        erc820Registry.setManager(this, newManager);
    }
}

/**
 * @title Safe Guard Contract
 * @author Panos
 */
contract SafeGuard is Owned {

    event Transaction(address indexed destination, uint value, bytes data);

    /**
     * @dev Allows owner to execute a transaction.
     */
    function executeTransaction(address destination, uint value, bytes data)
    public
    onlyOwner
    {
        require(externalCall(destination, value, data.length, data));
        emit Transaction(destination, value, data);
    }

    /**
     * @dev call has been separated into its own function in order to take advantage
     *  of the Solidity&#39;s code generator to produce a loop that copies tx.data into memory.
     */
    function externalCall(address destination, uint value, uint dataLength, bytes data)
    private
    returns (bool) {
        bool result;
        assembly { // solhint-disable-line no-inline-assembly
        let x := mload(0x40)   // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
            sub(gas, 34710), // 34710 is the value that solidity is currently emitting
            // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
            // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
            destination,
            value,
            d,
            dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
            x,
            0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}

/**
 * @title ERC664 Standard Balances Contract
 * @author chrisfranko
 */
contract ERC664Balances is SafeGuard {
    using SafeMath for uint256;

    uint256 public totalSupply;

    event BalanceAdj(address indexed module, address indexed account, uint amount, string polarity);
    event ModuleSet(address indexed module, bool indexed set);

    mapping(address => bool) public modules;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    modifier onlyModule() {
        require(modules[msg.sender]);
        _;
    }

    /**
     * @notice Constructor to create ERC664Balances
     * @param _initialAmount Database initial amount
     */
    constructor(uint256 _initialAmount) public {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
    }

    /**
     * @notice Set allowance of `_spender` in behalf of `_sender` at `_value`
     * @param _sender Owner account
     * @param _spender Spender account
     * @param _value Value to approve
     * @return Operation status
     */
    function setApprove(address _sender, address _spender, uint256 _value) external onlyModule returns (bool) {
        allowed[_sender][_spender] = _value;
        return true;
    }

    /**
     * @notice Decrease allowance of `_spender` in behalf of `_from` at `_value`
     * @param _from Owner account
     * @param _spender Spender account
     * @param _value Value to decrease
     * @return Operation status
     */
    function decApprove(address _from, address _spender, uint _value) external onlyModule returns (bool) {
        allowed[_from][_spender] = allowed[_from][_spender].sub(_value);
        return true;
    }

    /**
    * @notice Increase total supply by `_val`
    * @param _val Value to increase
    * @return Operation status
    */
    function incTotalSupply(uint _val) external onlyOwner returns (bool) {
        totalSupply = totalSupply.add(_val);
        return true;
    }

    /**
     * @notice Decrease total supply by `_val`
     * @param _val Value to decrease
     * @return Operation status
     */
    function decTotalSupply(uint _val) external onlyOwner returns (bool) {
        totalSupply = totalSupply.sub(_val);
        return true;
    }

    /**
     * @notice Set/Unset `_acct` as an authorized module
     * @param _acct Module address
     * @param _set Module set status
     * @return Operation status
     */
    function setModule(address _acct, bool _set) external onlyOwner returns (bool) {
        modules[_acct] = _set;
        emit ModuleSet(_acct, _set);
        return true;
    }

    /**
     * @notice Get `_acct` balance
     * @param _acct Target account to get balance.
     * @return The account balance
     */
    function getBalance(address _acct) external view returns (uint256) {
        return balances[_acct];
    }

    /**
     * @notice Get allowance of `_spender` in behalf of `_owner`
     * @param _owner Owner account
     * @param _spender Spender account
     * @return Allowance
     */
    function getAllowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @notice Get if `_acct` is an authorized module
     * @param _acct Module address
     * @return Operation status
     */
    function getModule(address _acct) external view returns (bool) {
        return modules[_acct];
    }

    /**
     * @notice Get total supply
     * @return Total supply
     */
    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    /**
     * @notice Increment `_acct` balance by `_val`
     * @param _acct Target account to increment balance.
     * @param _val Value to increment
     * @return Operation status
     */
    function incBalance(address _acct, uint _val) public onlyModule returns (bool) {
        balances[_acct] = balances[_acct].add(_val);
        emit BalanceAdj(msg.sender, _acct, _val, "+");
        return true;
    }

    /**
     * @notice Decrement `_acct` balance by `_val`
     * @param _acct Target account to decrement balance.
     * @param _val Value to decrement
     * @return Operation status
     */
    function decBalance(address _acct, uint _val) public onlyModule returns (bool) {
        balances[_acct] = balances[_acct].sub(_val);
        emit BalanceAdj(msg.sender, _acct, _val, "-");
        return true;
    }
}

/**
 * @title ERC664 Database Contract
 * @author Panos
 */
contract CStore is ERC664Balances, ERC820Implementer {

    mapping(address => mapping(address => bool)) private mAuthorized;

    /**
     * @notice Database construction
     * @param _totalSupply The total supply of the token
     * @param _registry The ERC820 Registry Address
     */
    constructor(uint256 _totalSupply, address _registry) public
    ERC664Balances(_totalSupply)
    ERC820Implementer(_registry) {
        setInterfaceImplementation("ERC664Balances", this);
    }

    /**
     * @notice Increase total supply by `_val`
     * @param _val Value to increase
     * @return Operation status
     */
    // solhint-disable-next-line no-unused-vars
    function incTotalSupply(uint _val) external onlyOwner returns (bool) {
        return false;
    }

    /**
     * @notice Decrease total supply by `_val`
     * @param _val Value to decrease
     * @return Operation status
     */
    // solhint-disable-next-line no-unused-vars
    function decTotalSupply(uint _val) external onlyOwner returns (bool) {
        return false;
    }

    /**
     * @notice moving `_amount` from `_from` to `_to`
     * @param _from The sender address
     * @param _to The receiving address
     * @param _amount The moving amount
     * @return bool The move result
     */
    function move(address _from, address _to, uint256 _amount) external
    onlyModule
    returns (bool) {
        balances[_from] = balances[_from].sub(_amount);
        emit BalanceAdj(msg.sender, _from, _amount, "-");
        balances[_to] = balances[_to].add(_amount);
        emit BalanceAdj(msg.sender, _to, _amount, "+");
        return true;
    }

    /**
     * @notice Setting operator `_operator` for `_tokenHolder`
     * @param _operator The operator to set status
     * @param _tokenHolder The token holder to set operator
     * @param _status The operator status
     * @return bool Status of operation
     */
    function setOperator(address _operator, address _tokenHolder, bool _status) external
    onlyModule
    returns (bool) {
        mAuthorized[_operator][_tokenHolder] = _status;
        return true;
    }

    /**
     * @notice Getting operator `_operator` for `_tokenHolder`
     * @param _operator The operator address to get status
     * @param _tokenHolder The token holder address
     * @return bool Operator status
     */
    function getOperator(address _operator, address _tokenHolder) external
    view
    returns (bool) {
        return mAuthorized[_operator][_tokenHolder];
    }

    /**
     * @notice Increment `_acct` balance by `_val`
     * @param _acct Target account to increment balance.
     * @param _val Value to increment
     * @return Operation status
     */
    // solhint-disable-next-line no-unused-vars
    function incBalance(address _acct, uint _val) public onlyModule returns (bool) {
        return false;
    }

    /**
     * @notice Decrement `_acct` balance by `_val`
     * @param _acct Target account to decrement balance.
     * @param _val Value to decrement
     * @return Operation status
     */
    // solhint-disable-next-line no-unused-vars
    function decBalance(address _acct, uint _val) public onlyModule returns (bool) {
        return false;
    }
}