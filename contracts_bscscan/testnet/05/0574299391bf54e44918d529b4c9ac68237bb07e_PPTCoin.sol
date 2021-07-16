/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// File: contracts\PhoenixModules\modules\SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    uint256 constant internal calDecimal = 1e18; 
    function mulPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(mul(mul(prices[1],value),calDecimal),prices[0]) :
            div(mul(mul(prices[0],value),calDecimal),prices[1]);
    }
    function divPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(div(mul(prices[0],value),calDecimal),prices[1]) :
            div(div(mul(prices[1],value),calDecimal),prices[0]);
    }
}

// File: contracts\PhoenixModules\multiSignature\multiSignatureClient.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
contract multiSignatureClient{
    uint256 private constant multiSignaturePositon = uint256(keccak256("org.Phoenix.multiSignature.storage"));
    event DebugEvent(address indexed from,bytes32 msgHash,uint256 value,uint256 value1);
    constructor(address multiSignature) public {
        require(multiSignature != address(0),"multiSignatureClient : Multiple signature contract address is zero!");
        saveValue(multiSignaturePositon,uint256(multiSignature));
    }    
    function getMultiSignatureAddress()public view returns (address){
        return address(getValue(multiSignaturePositon));
    }
    modifier validCall(){
        checkMultiSignature();
        _;
    }
    function checkMultiSignature() internal {
        uint256 value;
        assembly {
            value := callvalue()
        }
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, address(this),value,msg.data));
        address multiSign = getMultiSignatureAddress();
        uint256 index = getValue(uint256(msgHash));
        uint256 newIndex = IMultiSignature(multiSign).getValidSignature(msgHash,index);
        require(newIndex > index, "multiSignatureClient : This tx is not aprroved");
        saveValue(uint256(msgHash),newIndex);
    }
    function saveValue(uint256 position,uint256 value) internal 
    {
        assembly {
            sstore(position, value)
        }
    }
    function getValue(uint256 position) internal view returns (uint256 value) {
        assembly {
            value := sload(position)
        }
    }
}

// File: contracts\PhoenixModules\proxyModules\proxyOwner.sol

pragma solidity =0.5.16;

/**
 * @title  proxyOwner Contract

 */

contract proxyOwner is multiSignatureClient{
    bytes32 private constant ownerExpiredPosition = keccak256("org.Phoenix.ownerExpired.storage");
    bytes32 private constant versionPositon = keccak256("org.Phoenix.version.storage");
    bytes32 private constant proxyOwnerPosition  = keccak256("org.Phoenix.Owner.storage");
    bytes32 private constant proxyOriginPosition  = keccak256("org.Phoenix.Origin.storage");
    uint256 private constant oncePosition  = uint256(keccak256("org.Phoenix.Once.storage"));
    uint256 private constant ownerExpired =  90 days;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    constructor(address multiSignature) multiSignatureClient(multiSignature) public{
        _setProxyOwner(msg.sender);
        _setProxyOrigin(tx.origin);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */

    function transferOwnership(address _newOwner) public onlyOwner
    {
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        emit OwnershipTransferred(owner(),_newOwner);
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
        position = ownerExpiredPosition;
        uint256 expired = now+ownerExpired;
        assembly {
            sstore(position, expired)
        }
    }
    function owner() public view returns (address _owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            _owner := sload(position)
        }
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require (isOwner(),"proxyOwner: caller must be the proxy owner and a contract and not expired");
        _;
    }
    function transferOrigin(address _newOrigin) public onlyOrigin
    {
        _setProxyOrigin(_newOrigin);
    }
    function _setProxyOrigin(address _newOrigin) internal 
    {
        emit OriginTransferred(txOrigin(),_newOrigin);
        bytes32 position = proxyOriginPosition;
        assembly {
            sstore(position, _newOrigin)
        }
    }
    function txOrigin() public view returns (address _origin) {
        bytes32 position = proxyOriginPosition;
        assembly {
            _origin := sload(position)
        }
    }
    function ownerExpiredTime() public view returns (uint256 _expired) {
        bytes32 position = ownerExpiredPosition;
        assembly {
            _expired := sload(position)
        }
    }
    modifier originOnce() {
        require (msg.sender == txOrigin(),"proxyOwner: caller is not the tx origin!");
        uint256 key = oncePosition+uint32(msg.sig);
        require (getValue(key)==0, "proxyOwner : This function must be invoked only once!");
        saveValue(key,1);
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == owner() && isContract(msg.sender);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOrigin() {
        require (msg.sender == txOrigin(),"proxyOwner: caller is not the tx origin!");
        checkMultiSignature();
        _;
    }
    modifier OwnerOrOrigin(){
        if (isOwner()){
        }else if(msg.sender == txOrigin()){
            checkMultiSignature();
        }else{
            require(false,"proxyOwner: caller is not owner or origin");
        }
        _;
    }
    function _setVersion(uint256 version_) internal 
    {
        bytes32 position = versionPositon;
        assembly {
            sstore(position, version_)
        }
    }
    function version() public view returns(uint256 version_){
        bytes32 position = versionPositon;
        assembly {
            version_ := sload(position)
        }
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts\PhoenixModules\proxyModules\initializable.sol

pragma solidity =0.5.16;
/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract initializable {

    /**
    * @dev Indicates that the contract has been initialized.
    */
    bool private initialized;

    /**
    * @dev Indicates that the contract is in the process of being initialized.
    */
    bool private initializing;

    /**
    * @dev Modifier to use in the initializer function of a contract.
    */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool wasInitializing = initializing;
        initializing = true;
        initialized = true;

        _;
        initializing = wasInitializing;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        assembly { cs := extcodesize(address) }
        return cs == 0;
    }

}

// File: contracts\PhoenixModules\proxyModules\versionUpdater.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */


contract versionUpdater is proxyOwner,initializable {
    function implementationVersion() public pure returns (uint256);
    function initialize() public initializer versionUpdate {

    }
    modifier versionUpdate(){
        require(implementationVersion() > version() &&  ownerExpiredTime()>now,"New version implementation is already updated!");
        _;
    }
}

// File: contracts\PhoenixModules\ERC20\Erc20Data.sol

pragma solidity =0.5.16;
contract Erc20Data{
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\PhoenixModules\proxyModules\timeLimitation.sol

pragma solidity =0.5.16;


contract timeLimitation is proxyOwner {
    
    /**
     * @dev PPT has burn time limit. When user's balance is moved in som coins, he will wait `timeLimited` to burn PPT. 
     * latestTransferIn is user's latest time when his balance is moved in.
     */
    struct addressInfo {
        uint128 time;
        bool bIgnoreFrom;
        bool bIgnoreTo;
    }
    mapping(address=>addressInfo) internal addressTimeMap;
    uint256 public limitation;
    /**
     * @dev set time limitation, only owner can invoke. 
     * @param _limitation new time limitation.
     */ 
    function setTimeLimitation(uint256 _limitation) public OwnerOrOrigin {
        limitation = _limitation;
    }
    function getAccountInfo(address account) public view returns(bool,bool){
        return (addressTimeMap[account].bIgnoreFrom,addressTimeMap[account].bIgnoreTo);
    }
    function setAccountInfo(address account,bool bIgnoreFrom,bool bIgnoreTo) public OwnerOrOrigin{
        addressTimeMap[account].bIgnoreFrom = bIgnoreFrom;
        addressTimeMap[account].bIgnoreTo = bIgnoreTo;
    }
    function setTransferTimeLimitation(address from,address to) internal{
        if (!addressTimeMap[from].bIgnoreFrom && !addressTimeMap[to].bIgnoreTo){
            addressTimeMap[to].time = uint128(now);
        }
    }
    /**
     * @dev Retrieve user's start time for burning. 
     * @param account user's account.
     */ 
    function getTimeLimitation(address account) public view returns (uint256){
        return addressTimeMap[account].time+limitation;
    }
    modifier OutLimitation(address account) {
        require(addressTimeMap[account].time+limitation<now,"Time limitation is not expired!");
        _;
    }    
}

// File: contracts\PhoenixModules\acceleratedMinePool\IAcceleratedMinePool.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IAcceleratedMinePool {
    function setPHXVestingPool(address _accelerator) external;
    function changeAcceleratedInfo(address account,uint256[] calldata newRates,uint256 maxLockedPeriod) external;
    function transferPPTCoin(address account,address recieptor) external;
    function changePPTStake(address account) external;
}

// File: contracts\PhoenixModules\proxyModules\proxyOperator.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract proxyOperator is proxyOwner {
    mapping(uint256=>address) internal _operators;
    uint256 internal constant managerIndex = 0;
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator,uint256 indexed index);
    modifier onlyManager() {
        require(msg.sender == _operators[managerIndex], "Operator: caller is not the manager");
        _;
    }
    modifier onlyOperator(uint256 index) {
        require(_operators[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    modifier onlyOperator2(uint256 index1,uint256 index2) {
        require(_operators[index1] == msg.sender || _operators[index2] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    modifier onlyOperator3(uint256 index1,uint256 index2,uint256 index3) {
        require(_operators[index1] == msg.sender || _operators[index2] == msg.sender || _operators[index3] == msg.sender,
            "Operator: caller is not the eligible Operator");
        _;
    }
    function setManager(address newManager) public onlyOwner{
        _setOperator(managerIndex,newManager);
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address newAddress)public OwnerOrOrigin{
        require(index>0, "Index must greater than 0");
        _setOperator(index,newAddress);
    }
    function _setOperator(uint256 index,address newAddress) internal {
        emit OperatorTransferred(_operators[index], newAddress,index);
        _operators[index] = newAddress;
    }
    function getOperator(uint256 index)public view returns (address) {
        return _operators[index];
    }
}

// File: contracts\PhoenixModules\proxyModules\poolLimit.sol

pragma solidity >=0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */


contract poolLimit is proxyOwner {
    uint256 public totalLimit;
    uint256 public userLimit;
    function modifyLimitation(uint256 _totalLimit,uint256 _userLimit)public OwnerOrOrigin {
        totalLimit = _totalLimit;
        userLimit = _userLimit;
    }
    modifier belowTotalLimit(uint256 allInput){
        require(allInput<=totalLimit, "Input amount is exceeded pool total limit!");
        _;
    }
    modifier belowUserLimit(uint256 userInput){
        require(userInput<=userLimit, "Input amount is exceeded user limit!");
        _;
    }
}

// File: contracts\PhoenixModules\PPTCoin\PPTData.sol

pragma solidity =0.5.16;






/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
contract PPTData is Erc20Data,timeLimitation,poolLimit,proxyOperator,versionUpdater{
    /**
    * @dev lock mechanism is used when user redeem collateral and left collateral is insufficient.
    * _totalLockedWorth stores total locked worth, priced in USD.
    * lockedBalances stores user's locked PPTCoin.
    * lockedTotalWorth stores user's locked worth, priced in USD. For locked PPTCoin's net worth is constant when It was locked.
    */
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    uint256 internal _totalLockedWorth;
    IAcceleratedMinePool public minePool;
    mapping (address => uint256) internal lockedBalances;
    mapping (address => uint256) internal lockedTotalWorth;
    /**
     * @dev Emitted when `owner` locked  `amount` PPT, which net worth is  `worth` in USD. 
     */
    event AddLocked(address indexed owner, uint256 amount,uint256 worth);
    /**
     * @dev Emitted when `owner` burned locked  `amount` PPT, which net worth is  `worth` in USD. 
     */
    event BurnLocked(address indexed owner, uint256 amount,uint256 worth);

}

// File: contracts\PhoenixModules\PPTCoin\SharedCoin.sol

pragma solidity =0.5.16;


/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
contract SharedCoin is PPTData  {
    using SafeMath for uint256;
    /**
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string memory _name, string memory _symbol,uint8 _decimals)
        public
        onlyOwner
    {
        //check parameter in ico minter contract
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
    public
    returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
    public
    returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
/*
    function burn(uint256 amount) public onlyOwner returns (bool){
        _burn(msg.sender, amount);
        return true;
    }
    function mint(address account,uint256 amount) public onlyOwner returns (bool){
        _mint(account,amount);
        return true;
    }
    */
    /**
     * @dev add `recipient`'s balance to iterable mapping balances.
     */
    function _addBalance(address recipient, uint256 amount) internal {
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[recipient] = balances[recipient].add(amount);
    }
    /**
     * @dev add `recipient`'s balance to iterable mapping balances.
     */
    function _subBalance(address recipient, uint256 amount) internal {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        balances[recipient] = balances[recipient].sub(amount);
    }
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _subBalance(sender,amount);
        _addBalance(recipient,amount);
        setTransferTimeLimitation(sender,recipient);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _addBalance(account,amount);
        setTransferTimeLimitation(address(0),account);
        emit Transfer(address(0), account, amount);
    }
    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _subBalance(account,amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

// File: contracts\PhoenixModules\PPTCoin\PPTCoin.sol

pragma solidity =0.5.16;


/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */

/**
 * @title PPTCoin is Phoenix collateral Pool token, implement ERC20 interface.
 * @dev ERC20 token. Its inside value is collatral pool net worth.
 *
 */
contract PPTCoin is SharedCoin {
    using SafeMath for uint256;
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }
    function initialize() public{
        versionUpdater.initialize();
        _totalSupply = 0;
        decimals = 18;
        totalLimit = uint256(-1);
        userLimit = uint256(-1);
    }
    function setMinePool(address acceleratedMinePool) external onlyOwner{
        minePool = IAcceleratedMinePool(acceleratedMinePool);
    }
    function update() public versionUpdate{
    }
    /**
     * @dev Retrieve total locked worth. 
     */ 
    function getTotalLockedWorth() public view returns (uint256) {
        return _totalLockedWorth;
    }
    /**
     * @dev Retrieve user's locked balance. 
     * @param account user's account.
     */ 
    function lockedBalanceOf(address account) public view returns (uint256) {
        return lockedBalances[account];
    }
    /**
     * @dev Retrieve user's locked net worth. 
     * @param account user's account.
     */ 
    function lockedWorthOf(address account) public view returns (uint256) {
        return lockedTotalWorth[account];
    }
    /**
     * @dev Retrieve user's locked balance and locked net worth. 
     * @param account user's account.
     */ 
    function getLockedBalance(address account) public view returns (uint256,uint256) {
        return (lockedBalances[account],lockedTotalWorth[account]);
    }

    /**
     * @dev Move user's PPT to locked balance, when user redeem collateral. 
     * @param account user's account.
     * @param amount amount of locked PPT.
     * @param lockedWorth net worth of locked PPT.
     */ 
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)public onlyManager {
        burn(account,amount);
        _addLockBalance(account,amount,lockedWorth);
    }
    /**
     * @dev Move user's PPT to 'recipient' balance, a interface in ERC20. 
     * @param recipient recipient's account.
     * @param amount amount of PPT.
     */ 
    function transfer(address recipient, uint256 amount)public returns (bool){
        SharedCoin.transfer(recipient,amount);
        if (address(minePool) != address(0)){
            minePool.transferPPTCoin(msg.sender,recipient);
        }
        return true;
    }
        /**
     * @dev Move sender's PPT to 'recipient' balance, a interface in ERC20. 
     * @param sender sender's account.
     * @param recipient recipient's account.
     * @param amount amount of PPT.
     */ 
    function transferFrom(address sender, address recipient, uint256 amount)public returns (bool){
        SharedCoin.transferFrom(sender,recipient,amount);
        if (address(minePool) != address(0)){
            minePool.transferPPTCoin(sender,recipient);
        }
        return true;            
    }
    /**
     * @dev burn user's PPT when user redeem PPTCoin. 
     * @param account user's account.
     * @param amount amount of PPT.
     */ 
    function burn(address account, uint256 amount) public onlyManager OutLimitation(account) {
        SharedCoin._burn(account,amount);
        if (address(minePool) != address(0)){
            minePool.changePPTStake(account);
        }
    }
    /**
     * @dev mint user's PPT when user add collateral. 
     * @param account user's account.
     * @param amount amount of PPT.
     */ 
    function mint(address account, uint256 amount) public onlyManager belowTotalLimit(_totalSupply+amount) belowUserLimit(balances[account]+amount) {
        SharedCoin._mint(account,amount);
        if (address(minePool) != address(0)){
            minePool.changePPTStake(account);
        }
    }
    /**
     * @dev An auxiliary function, add user's locked balance. 
     * @param account user's account.
     * @param amount amount of PPT.
     * @param lockedWorth net worth of PPT.
     */ 
    function _addLockBalance(address account, uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].add(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].add(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.add(lockedWorth);
        emit AddLocked(account, amount,lockedWorth);
    }
    /**
     * @dev An auxiliary function, deduct user's locked balance. 
     * @param account user's account.
     * @param amount amount of PPT.
     * @param lockedWorth net worth of PPT.
     */ 
    function _subLockBalance(address account,uint256 amount,uint256 lockedWorth)internal {
        lockedBalances[account]= lockedBalances[account].sub(amount);
        lockedTotalWorth[account]= lockedTotalWorth[account].sub(lockedWorth);
        _totalLockedWorth = _totalLockedWorth.sub(lockedWorth);
        emit BurnLocked(account, amount,lockedWorth);
    }
    /**
     * @dev An interface of redeem locked PPT, when user redeem collateral, only manager contract can invoke. 
     * @param account user's account.
     * @param tokenAmount amount of PPT.
     * @param leftCollateral left available collateral in collateral pool, priced in USD.
     */ 
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)public onlyManager OutLimitation(account) returns (uint256,uint256){
        if (leftCollateral == 0){
            return(0,0);
        }
        uint256 lockedAmount = lockedBalances[account];
        uint256 lockedWorth = lockedTotalWorth[account];
        if (lockedAmount == 0 || lockedWorth == 0){
            return (0,0);
        }
        uint256 redeemWorth = 0;
        uint256 lockedBurn = 0;
        uint256 lockedPrice = lockedWorth/lockedAmount;
        if (lockedAmount >= tokenAmount){
            lockedBurn = tokenAmount;
            redeemWorth = tokenAmount*lockedPrice;
        }else{
            lockedBurn = lockedAmount;
            redeemWorth = lockedWorth;
        }
        if (redeemWorth > leftCollateral) {
            lockedBurn = leftCollateral/lockedPrice;
            redeemWorth = lockedBurn*lockedPrice;
        }
        if (lockedBurn > 0){
            _subLockBalance(account,lockedBurn,redeemWorth);
            return (lockedBurn,redeemWorth);
        }
        return (0,0);
    }
}