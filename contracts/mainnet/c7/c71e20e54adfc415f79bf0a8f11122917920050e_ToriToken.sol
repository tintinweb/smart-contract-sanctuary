/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.2;
// tested in solidity 0.5.8
// using openzeppelin-solidity-2.2.0

// import "../../utils/Address.sol";
/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


// import "../../math/SafeMath.sol";
/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



// import "./IERC20.sol";
/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // &#39;safeIncreaseAllowance&#39; and &#39;safeDecreaseAllowance&#39;
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must equal true).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity&#39;s return data size checking mechanism, since
        // we&#39;re implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.

        require(address(token).isContract());

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)));
        }
    }
}
/////////////////////////////////////////////////////////////////////////
// ownership/Ownable.sol
///////////////////////////////////////////////////////////////////////
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses&#39; tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender&#39;s allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}
/////////////////////////////////////////////////////////////////////////
// ERC20Detailed
///////////////////////////////////////////////////////////////////////
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/////////////////////////////////////////////////////////////////////////
// ownership/Ownable.sol
///////////////////////////////////////////////////////////////////////
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor (address Owner) internal {
        _owner = Owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    // function transferOwnership(address newOwner) public onlyOwner {
    //     _transferOwnership(newOwner);
    // }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    // function _transferOwnership(address newOwner) internal {
    //     require(newOwner != address(0));
    //     emit OwnershipTransferred(_owner, newOwner);
    //     _owner = newOwner;
    // }
}

/////////////////////////////////////////////////////////////////////////
// LockerPool Contract
/////////////////////////////////////////////////////////////////////////
contract LockerPool is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public lockMonths;

    uint256 public INITIAL_LOCK_AMOUNT;

    uint256 public lockDays;
    uint256 public lockDaysTime;

    modifier checkBeneficiaryExist(address _addr) {
        require(beneficiaryList.length-1 != 0);
        require(userBeneficiaryMap[_addr] != 0);
        require(beneficiaryList[userBeneficiaryMap[_addr]].beneficiaryAddr == _addr);
        _;
    }

    function balanceOfPool() public view returns (uint256){
        return token.balanceOf(address(this));
    }

    function getRemainAmount() public view returns (uint256) {
        return INITIAL_LOCK_AMOUNT.sub(getAllocatedAmount());
    }

    function totalBeneficiaryCount() public view returns (uint256) {
        return beneficiaryList.length-1;
    }

    function getAllocatedAmount() public view returns (uint256){
        uint256 _beneficiaryCount = beneficiaryList.length;
        uint256 totalValue;
        for (uint256 i=1; i < _beneficiaryCount; i++) { // start from 1, for using 0 as null
            totalValue = totalValue.add(beneficiaryList[i].initialAmount);
        }
        return totalValue;
    }

    function _checkIsReleasable(address addr, uint256 releasingPointId) internal view returns(bool){
        if (beneficiaryList[userBeneficiaryMap[addr]].releasingPointStateList[releasingPointId] == false &&
            now >= beneficiaryList[userBeneficiaryMap[addr]].releasingPointDateList[releasingPointId]) {
                return true;
        }
        else{
            return false;
        }
    }

    function checkIsReleasableById(uint256 id, uint256 releasingPointId) internal view returns(bool){
        if (beneficiaryList[id].releasingPointStateList[releasingPointId] == false &&
            now >= beneficiaryList[id].releasingPointDateList[releasingPointId]) {
                return true;
        }
        else{
            return false;
        }
    }

    function getUnlockedAmountPocket(address addr) public checkBeneficiaryExist(addr) view returns (uint256) {

        uint256 totalValue;
        for (uint256 i=0; i < lockMonths; i++) {

            if (_checkIsReleasable(addr, i)){
                totalValue = totalValue.add(beneficiaryList[userBeneficiaryMap[addr]].releasingPointValueList[i]);
            }
        }
        return totalValue;
    }

    function getTransferCompletedAmount() public view returns (uint256) {
        uint256 _beneficiaryCount = beneficiaryList.length;
        uint256 totalValue;
        for (uint256 i=1; i < _beneficiaryCount; i++) { // start from 1, for using 0 as null
            totalValue = totalValue.add(beneficiaryList[i].transferCompletedAmount);
        }
        return totalValue;
    }

    function getReleasingPoint(uint256 beneficiaryId, uint256 index) public view returns (uint256 _now, uint256 date, uint256 value, bool state, bool releasable){
        return (now, beneficiaryList[beneficiaryId].releasingPointDateList[index], beneficiaryList[beneficiaryId].releasingPointValueList[index], beneficiaryList[beneficiaryId].releasingPointStateList[index], checkIsReleasableById(beneficiaryId, index));
    }

    event AllocateLockupToken(address indexed beneficiaryAddr, uint256 initialAmount, uint256 lockupPeriodStartDate, uint256 releaseStartDate, uint256 releaseEndDate, uint256 id);

    struct Beneficiary {
        uint256 id;
        address beneficiaryAddr;
        uint256 initialAmount;
        uint256 transferCompletedAmount;
        uint256 lockupPeriodStartDate;  // ownerGivedDate
        uint256 releaseStartDate; // lockupPeriodEnxDate
        uint256[] releasingPointDateList;
        uint256[] releasingPointValueList;
        bool[] releasingPointStateList;
        uint256 releaseEndDate;
        uint8 bType;
    }

    Beneficiary[] public beneficiaryList;
    mapping (address => uint256) public userBeneficiaryMap;
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor (uint256 _lockMonths, uint256 _lockAmount, address poolOwner, address tokenAddr) public Ownable(poolOwner){
        require(36 >= _lockMonths); // optional
        token = IERC20(tokenAddr);
        lockMonths = _lockMonths;
        INITIAL_LOCK_AMOUNT = _lockAmount;
        lockDays = lockMonths * 30;  // 1 mounth ~= 30 days
        lockDaysTime = lockDays * 60 * 60 * 24; // 1 day == 86400 sec
        beneficiaryList.length = beneficiaryList.length.add(1); // start from 1, for using 0 as null
    }

    function allocateLockupToken(address _beneficiaryAddr, uint256 amount, uint8 _type) onlyOwner public returns (uint256 _beneficiaryId) {
        require(userBeneficiaryMap[_beneficiaryAddr] == 0);  // already check
        require(getRemainAmount() >= amount);
        Beneficiary memory beneficiary = Beneficiary({
            id: beneficiaryList.length,
            beneficiaryAddr: _beneficiaryAddr,
            initialAmount: amount,
            transferCompletedAmount: 0,
            lockupPeriodStartDate: uint256(now), // now == block.timestamp
            releaseStartDate: uint256(now).add(lockDaysTime),
            releasingPointDateList: new uint256[](lockMonths), // not return in ABCI v1
            releasingPointValueList: new uint256[](lockMonths),
            releasingPointStateList: new bool[](lockMonths),
            releaseEndDate: 0,
            bType: _type
            });

        beneficiary.releaseEndDate = beneficiary.releaseStartDate.add(lockDaysTime);
        uint256 remainAmount = beneficiary.initialAmount;
        for (uint256 i=0; i < lockMonths; i++) {
            beneficiary.releasingPointDateList[i] = beneficiary.releaseStartDate.add(lockDaysTime.div(lockMonths).mul(i.add(1)));
            beneficiary.releasingPointStateList[i] = false;
            if (i.add(1) != lockMonths){
                beneficiary.releasingPointValueList[i] = uint256(beneficiary.initialAmount.div(lockMonths));
                remainAmount = remainAmount.sub(beneficiary.releasingPointValueList[i]);
            }
            else{
                beneficiary.releasingPointValueList[i] = remainAmount;
            }
        }

        beneficiaryList.push(beneficiary);
        userBeneficiaryMap[_beneficiaryAddr] = beneficiary.id;

        emit AllocateLockupToken(beneficiary.beneficiaryAddr, beneficiary.initialAmount, beneficiary.lockupPeriodStartDate, beneficiary.releaseStartDate, beneficiary.releaseEndDate, beneficiary.id);
        return beneficiary.id;
    }
    event Claim(address indexed beneficiaryAddr, uint256 indexed beneficiaryId, uint256 value);
    function claim () public checkBeneficiaryExist(msg.sender) returns (uint256) {
        uint256 unlockedAmount = getUnlockedAmountPocket(msg.sender);
        require(unlockedAmount > 0);

        uint256 totalValue;
        for (uint256 i=0; i < lockMonths; i++) {
            if (_checkIsReleasable(msg.sender, i)){
                beneficiaryList[userBeneficiaryMap[msg.sender]].releasingPointStateList[i] = true;
                totalValue = totalValue.add(beneficiaryList[userBeneficiaryMap[msg.sender]].releasingPointValueList[i]);
            }
        }
        require(unlockedAmount == totalValue);
        token.safeTransfer(msg.sender, totalValue);
        beneficiaryList[userBeneficiaryMap[msg.sender]].transferCompletedAmount = beneficiaryList[userBeneficiaryMap[msg.sender]].transferCompletedAmount.add(totalValue);
        emit Claim(beneficiaryList[userBeneficiaryMap[msg.sender]].beneficiaryAddr, beneficiaryList[userBeneficiaryMap[msg.sender]].id, totalValue);
        return totalValue;
    }
}

/////////////////////////////////////////////////////////////////////////
// ToriToken Contract
/////////////////////////////////////////////////////////////////////////
contract ToriToken is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 4000000000 * (10 ** uint256(DECIMALS));

    uint256 public remainReleased = INITIAL_SUPPLY;

    address private _owner;

    // no lockup ( with addresses )
    address public initialSale = 0x4dEF0A02D30cdf62AB6e513e978dB8A58ed86B53;
    address public saleCPool = 0xF3963A437E0e156e8102414DE3a9CC6E38829ea1;
    address public ecoPool = 0xf6e25f35C3c5cF40035B7afD1e9F5198594f600e;
    address public reservedPool = 0x557e4529D5784D978fCF7A5a20a184a78AF597D5;
    address public marketingPool = 0xEeE05AfD6E1e02b6f86Dd1664689cC46Ab0D7B20;

    uint256 public initialSaleAmount = 600000000 ether;
    uint256 public saleCPoolAmount = 360000000 ether;
    uint256 public ecoPoolAmount = 580000000 ether;
    uint256 public reservedPoolAmount = 600000000 ether;
    uint256 public marketingPoolAmount = 80000000 ether;

    // with lockup ( with addresses )
    address public saleBPoolOwner = 0xB7F1ea2af2a9Af419F093f62bDD67Df914b0ff2E;
    address public airDropPoolOwner = 0x590d6d6817ed53142BF69F16725D596dAaE9a6Ce;
    address public companyPoolOwner = 0x1b0E91D484eb69424100A48c74Bfb450ea494445;
    address public productionPartnerPoolOwner = 0x0c0CD85EA55Ea1B6210ca89827FA15f9F10D56F6;
    address public advisorPoolOwner = 0x68F0D15D17Aa71afB14d72C97634977495dF4d0E;
    address public teamPoolOwner = 0x5A353e276F68558bEA884b13017026A6F1067951;

    uint256 public saleBPoolAmount = 420000000 ether;
    uint256 public airDropPoolAmount = 200000000 ether;
    uint256 public companyPoolAmount = 440000000 ether;
    uint256 public productionPartnerPoolAmount = 200000000 ether;
    uint256 public advisorPoolAmount = 120000000 ether;
    uint256 public teamPoolAmount = 400000000 ether;

    uint8 public saleBPoolLockupPeriod = 12;
    uint8 public airDropPoolLockupPeriod = 3;
    uint8 public companyPoolLockupPeriod = 12;
    uint8 public productionPartnerPoolLockupPeriod = 6;
    uint8 public advisorPoolLockupPeriod = 12;
    uint8 public teamPoolLockupPeriod = 24;

    LockerPool public saleBPool;
    LockerPool public airDropPool;
    LockerPool public companyPool;
    LockerPool public productionPartnerPool;
    LockerPool public advisorPool;
    LockerPool public teamPool;

    bool private _deployedOuter;
    bool private _deployedInner;

    function deployLockersOuter() public {
        require(!_deployedOuter);
        saleBPool = new LockerPool(saleBPoolLockupPeriod, saleBPoolAmount, saleBPoolOwner, address(this));
        airDropPool = new LockerPool(airDropPoolLockupPeriod, airDropPoolAmount, airDropPoolOwner, address(this));
        productionPartnerPool = new LockerPool(productionPartnerPoolLockupPeriod, productionPartnerPoolAmount, productionPartnerPoolOwner, address(this));
        _deployedOuter = true;
        _mint(address(saleBPool), saleBPoolAmount);
        _mint(address(airDropPool), airDropPoolAmount);
        _mint(address(productionPartnerPool), productionPartnerPoolAmount);
    }

    function deployLockersInner() public {
        require(!_deployedInner);
        companyPool = new LockerPool(companyPoolLockupPeriod, companyPoolAmount, companyPoolOwner, address(this));
        advisorPool = new LockerPool(advisorPoolLockupPeriod, advisorPoolAmount, advisorPoolOwner, address(this));
        teamPool = new LockerPool(teamPoolLockupPeriod, teamPoolAmount, teamPoolOwner, address(this));
        _deployedInner = true;
        _mint(address(companyPool), companyPoolAmount);
        _mint(address(advisorPool), advisorPoolAmount);
        _mint(address(teamPool), teamPoolAmount);
    }

    constructor () public ERC20Detailed("Storichain", "TORI", DECIMALS) {
        _mint(address(initialSale), initialSaleAmount);
        _mint(address(saleCPool), saleCPoolAmount);
        _mint(address(ecoPool), ecoPoolAmount);
        _mint(address(reservedPool), reservedPoolAmount);
        _mint(address(marketingPool), marketingPoolAmount);
        _deployedOuter = false;
        _deployedInner = false;
    }
}