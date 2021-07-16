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

// File: contracts\optionsFactory\optionsFactoryData.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */


contract optionsFactoryData is versionUpdater,proxyOperator{

    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    string public baseCoinName;
    uint256 constant public optionsPoolID = 0;
    uint256 constant public collateralPoolID = 1;
    uint256 constant public optionsManagerID = 2;
    uint256 constant public PPTTokenID = 3;
    uint256 constant public MinePoolID = 4;
    struct proxyInfo {
        address implementation;
        address payable[] proxyList;
    }
    mapping(uint256=>proxyInfo) public proxyinfoMap;
    struct managerInfo {
        address optionsManager;
        address collateralPool;
        address optionsPool;
        address pptCoin;
    }
    managerInfo[] internal optionsManagerInfo;
    address public optionsCal;
    address public phxOracle;
    uint64 public PPTTimeLimit;
    uint8 public PPTname;
    address public impliedVolatility;
    address public optionsPrice;
    address public vestingPool;
    event CreateOptionsManager(address indexed optionsManager,address collateralPool,address optionsPool,address pptCoin);
}

// File: contracts\PhoenixModules\proxy\phxProxy.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
/**
 * @title  phxProxy Contract

 */

contract phxProxy is proxyOwner {
    bytes32 private constant implementPositon = keccak256("org.Phoenix.implementation.storage");
    event Upgraded(address indexed implementation,uint256 indexed version);
    constructor(address implementation_,address multiSignature) proxyOwner(multiSignature) public {

        // Creator of the contract is admin during initialization
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("initialize()"));
        _setImplementation(implementation_);
        require(success);
    }
    function proxyType() public pure returns (uint256){
        return 2;
    }
    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementPositon;
        assembly {
            impl := sload(position)
        }
    }
    function _setImplementation(address _newImplementation) internal 
    {
        (bool success, bytes memory returnData) = _newImplementation.delegatecall(abi.encodeWithSignature("implementationVersion()"));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        uint256 version_ = abi.decode(returnData, (uint256));
        require (version_>version(),"upgrade version number must be greater than current version");
        bytes32 position = implementPositon;
        assembly {
            sstore(position, _newImplementation)
        }
        _setVersion(version_);
        emit Upgraded(_newImplementation,version_);
    }
    function upgradeTo(address _newImplementation)public OwnerOrOrigin{
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation,"upgrade implementation is not changed!");
        (bool success,) = _newImplementation.delegatecall(abi.encodeWithSignature("update()"));
        _setImplementation(_newImplementation);
        require(success);
    }
    function () payable external {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
        let ptr := mload(0x40)
        calldatacopy(ptr, 0, calldatasize)
        let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
        let size := returndatasize
        returndatacopy(ptr, 0, size)

        switch result
        case 0 { revert(ptr, size) }
        default { return(ptr, size) }
        }
    }
}

// File: contracts\PhoenixModules\ERC20\IERC20.sol

pragma solidity =0.5.16;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

      /**
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string calldata _name, string calldata _symbol)external;

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

// File: contracts\PhoenixModules\PPTCoin\IPPTCoin.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IPPTCoin {
    function lockedBalanceOf(address account) external view returns (uint256);
    function getLockedBalance(address account) external view returns (uint256,uint256);
    function setTimeLimitation(uint256 _limitation) external;
    function changeTokenName(string calldata _name, string calldata _symbol,uint8 _decimals)external;
    function lockedWorthOf(address account) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function setMinePool(address acceleratedMinePool) external;
    function getTotalLockedWorth() external view returns (uint256);
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)external returns (uint256,uint256);
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)external; 
}

// File: contracts\PhoenixModules\modules\Address.sol

pragma solidity =0.5.16;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call.value(value )(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts\OptionsPool\IOptionsPool.sol

pragma solidity =0.5.16;
interface IOptionsPool {
//    function getOptionBalances(address user) external view returns(uint256[]);
    function initAddresses(address optionsCalAddr,address oracleAddr,address optionsPriceAddr,address ivAddress,uint32[] calldata underlyings)external;
    function createOptions(address from,address settlement,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) external returns(uint256);
    function setSharedState(uint256 newFirstOption,int256[] calldata latestNetWorth,address[] calldata whiteList) external;
    function getUnderlyingTotalOccupiedCollateral(uint32 underlying) external view returns (uint256,uint256,uint256);
    function getTotalOccupiedCollateral() external view returns (uint256);
//    function buyOptionCheck(uint32 expiration,uint32 underlying)external view;
    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)external;
    function getOptionsById(uint256 optionsId)external view returns(uint256,address,uint8,uint32,uint256,uint256,uint256);
    function getExerciseWorth(uint256 optionsId,uint256 amount)external view returns(uint256);
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList) external view returns(int256[] memory);
    function getOptionInfoLength()external view returns (uint256);
    function getNetWrothCalInfo(address[] calldata whiteList)external view returns(uint256,int256[] memory);
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList)
            external returns(int256[] memory,uint256[] memory,uint256);
    function optionsLatestNetWorth(address settlement)external view returns(int256);
    function getBurnedFullPay(uint256 optionID,uint256 amount) external view returns(address,uint256);

}

// File: contracts\CollateralPool\ICollateralPool.sol

pragma solidity =0.5.16;

interface ICollateralPool {
    function addNetWorthBalances(address[] calldata whiteList,int256[] calldata newNetworth)external;
    function setOptionsPoolAddress(address _optionsPool)external;
    function getFeeRateAll()external view returns (uint32[] memory);
    function getUserPayingUsd(address user)external view returns (uint256);
    function getUserInputCollateral(address user,address collateral)external view returns (uint256);
    //function getNetWorthBalance(address collateral)external view returns (int256);
    function getCollateralBalance(address collateral)external view returns (uint256);

    //add
    function addUserInputCollateral(address user,uint256 amountUSD,address collateral,uint256 amount)external;
    function addNetWorthBalance(address collateral,int256 amount)external;
    function addCollateralBalance(address collateral,uint256 amount)external;
    
    function transferPaybackAndFee(address recieptor,address settlement,uint256 payback,uint256 feeType)external;

    function buyOptionsPayfor(address payable recieptor,address settlement,uint256 settlementAmount,uint256 allPay)external;
    function transferPayback(address recieptor,address settlement,uint256 payback)external;
    function transferPaybackBalances(address account,uint256 redeemWorth,address[] calldata tmpWhiteList,uint256[] calldata colBalances,
        uint256[] calldata PremiumBalances,uint256[] calldata prices)external;
    function getCollateralAndPremiumBalances(address account,uint256 userTotalWorth,address[] calldata tmpWhiteList,
        uint256[] calldata _RealBalances,uint256[] calldata prices) external view returns(uint256[] memory,uint256[] memory);
    function addTransactionFee(address collateral,uint256 amount,uint256 feeType)external returns (uint256);

    function getAllRealBalance(address[] calldata whiteList)external view returns(int256[] memory);
    function getRealBalance(address settlement)external view returns(int256);
    function getNetWorthBalance(address settlement)external view returns(uint256);
}

// File: contracts\OptionsManager\IOptionsManager.sol

pragma solidity =0.5.16;
interface IOptionsManager {
    function initAddresses(address[] calldata collateral,uint256[] calldata rate,address oracleAddr,address optionsPriceAddr,address optionsPoolAddr,address collateralPoolAddr,address PPTCoinAddr) external;
}

// File: contracts\optionsFactory\optionsFactory.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */










/**
 * @title leverage contract factory.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract optionsFactory is optionsFactoryData{
    using SafeMath for uint256;
    using Address for address;
    /**
     * @dev constructor.
     */
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }

    function initialize() public{
        versionUpdater.initialize();
        //debug
        PPTTimeLimit = 3600;
        PPTname = 65;
    }
    function update() public versionUpdate {
    }

    function setImplementAddress(string memory _baseCoinName,
        address _optionsCalImpl,address _optionsPoolImpl,address _collateralPoolImpl,address _optionsManagerImpl,address _PPTCoinImpl,
        address acceleratedMinePool,address phxVestingPool,address _phxOracle,address _volatility,address _optionsPrice)public originOnce{
        baseCoinName = _baseCoinName;
        proxyinfoMap[optionsPoolID].implementation = _optionsPoolImpl;
        proxyinfoMap[collateralPoolID].implementation = _collateralPoolImpl;
        proxyinfoMap[optionsManagerID].implementation = _optionsManagerImpl;
        proxyinfoMap[PPTTokenID].implementation = _PPTCoinImpl;
        proxyinfoMap[MinePoolID].implementation = acceleratedMinePool;
        optionsCal = _optionsCalImpl;
        vestingPool = phxVestingPool;  
        phxOracle = _phxOracle;
        impliedVolatility = _volatility;
        optionsPrice = _optionsPrice;
    }
    function createOptionsManager(address[] calldata collateral,uint256[] calldata rate,uint32[] calldata underlyings)external onlyOrigin {
        address payable optionsPool = createOptionsPool(underlyings);
        address pptCoin = createPPTCoin();
        address payable collateralPool = createCollateralPool(optionsPool);
        address payable optionsManager = createPhxProxy(optionsManagerID);
        proxyOperator(collateralPool).setManager(optionsManager);
        proxyOperator(optionsPool).setManager(optionsManager);
        proxyOperator(pptCoin).setManager(optionsManager);
        IOptionsManager(optionsManager).initAddresses(collateral,rate,phxOracle,optionsPrice,
            optionsPool,collateralPool,pptCoin);
        optionsManagerInfo.push(managerInfo(optionsManager,collateralPool,optionsPool,pptCoin));
        emit CreateOptionsManager(optionsManager,collateralPool,optionsPool,pptCoin);
    }
    function getOptionsMangerLength()external view returns (uint256){
        return optionsManagerInfo.length;
    }
    function getOptionsMangerAddress(uint256 index)external view returns (address,address,address,address){
        require(index<optionsManagerInfo.length,"options manager index is overflow!");
        return (optionsManagerInfo[index].optionsManager,optionsManagerInfo[index].collateralPool,
            optionsManagerInfo[index].optionsPool,optionsManagerInfo[index].pptCoin);
    }
    function createCollateralPool(address optionsPool)internal returns(address payable){
        address payable collateralPool = createPhxProxy(collateralPoolID);
        ICollateralPool(collateralPool).setOptionsPoolAddress(optionsPool);
        proxyOperator(optionsPool).setOperator(99, collateralPool);
        return collateralPool;        
    }
    function createOptionsPool(uint32[] memory underlyings)internal returns(address payable){
        address payable optionsPool = createPhxProxy(optionsPoolID);
        IOptionsPool(optionsPool).initAddresses(optionsCal,phxOracle,optionsPrice,impliedVolatility,underlyings);
        return optionsPool;
    }
    function createPPTCoin()internal returns(address){
        address payable newCoin = createPhxProxy(PPTTokenID);
        string memory tokenName = string(abi.encodePacked("PPT_", PPTname));
        PPTname++;
        IPPTCoin(newCoin).changeTokenName(tokenName,tokenName,18);
        IPPTCoin(newCoin).setTimeLimitation(PPTTimeLimit);
        address minePool = createAcceleratedMinePool();
        proxyOperator(minePool).setManager(newCoin);
        IPPTCoin(newCoin).setMinePool(minePool);
        return newCoin;
    }
    function createAcceleratedMinePool()internal returns(address){
        address payable newCoin = createPhxProxy(MinePoolID);
        IAcceleratedMinePool(newCoin).setPHXVestingPool(vestingPool);
        return newCoin;
    }
    function createPhxProxy(uint256 index) internal returns (address payable){
        proxyInfo storage curInfo = proxyinfoMap[index];
        phxProxy newProxy = new phxProxy(curInfo.implementation,getMultiSignatureAddress());
        curInfo.proxyList.push(address(newProxy));
        return address(newProxy);
    }
    function setContractsInfo(uint256 index,bytes memory data)internal{
        proxyInfo storage curInfo = proxyinfoMap[index];
        uint256 len = curInfo.proxyList.length;
        for(uint256 i = 0;i<len;i++){
            Address.functionCall(curInfo.proxyList[i],data,"setContractsInfo error");
        }
    }
    function setPHXVestingPool(address _PHXVestingPool) public onlyOrigin{
        vestingPool = _PHXVestingPool;
        setContractsInfo(MinePoolID,abi.encodeWithSignature("setPHXVestingPool(address)",_PHXVestingPool));
    }
    function setOracleAddress(address _phxOracle)public onlyOrigin{
        phxOracle = _phxOracle;
        setContractsInfo(optionsPoolID,abi.encodeWithSignature("setOracleAddress(address)",_phxOracle));
        setContractsInfo(optionsManagerID,abi.encodeWithSignature("setOracleAddress(address)",_phxOracle));
    }
    function setPPTTimeLimit(uint32 _PPTTimeLimit) public onlyOrigin{
        PPTTimeLimit = _PPTTimeLimit;
        setContractsInfo(PPTTokenID,abi.encodeWithSignature("setTimeLimitation(uint256)",_PPTTimeLimit));
    }
    function upgradePhxProxy(uint256 index,address implementation) public onlyOrigin{
        proxyInfo storage curInfo = proxyinfoMap[index];
        curInfo.implementation = implementation;
        uint256 len = curInfo.proxyList.length;
        for(uint256 i = 0;i<len;i++){
            phxProxy(curInfo.proxyList[i]).upgradeTo(implementation);
        }        
    }

}