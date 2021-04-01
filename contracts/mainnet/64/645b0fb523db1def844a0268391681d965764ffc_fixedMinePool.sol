/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// File: contracts\modules\SafeMath.sol

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
}

// File: contracts\modules\Ownable.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\modules\Halt.sol

pragma solidity =0.5.16;


contract Halt is Ownable {
    
    bool private halted = false; 
    
    modifier notHalted() {
        require(!halted,"This contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted,"This contract is not halted");
        _;
    }
    
    /// @notice function Emergency situation that requires 
    /// @notice contribution period to stop or not.
    function setHalt(bool halt) 
        public 
        onlyOwner
    {
        halted = halt;
    }
}

// File: contracts\modules\whiteList.sol

pragma solidity >=0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */
    /**
     * @dev Implementation of a whitelist which filters a eligible uint32.
     */
library whiteListUint32 {
    /**
     * @dev add uint32 into white list.
     * @param whiteList the storage whiteList.
     * @param temp input value
     */

    function addWhiteListUint32(uint32[] storage whiteList,uint32 temp) internal{
        if (!isEligibleUint32(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    /**
     * @dev remove uint32 from whitelist.
     */
    function removeWhiteListUint32(uint32[] storage whiteList,uint32 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible uint256.
     */
library whiteListUint256 {
    // add whiteList
    function addWhiteListUint256(uint256[] storage whiteList,uint256 temp) internal{
        if (!isEligibleUint256(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListUint256(uint256[] storage whiteList,uint256 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible address.
     */
library whiteListAddress {
    // add whiteList
    function addWhiteListAddress(address[] storage whiteList,address temp) internal{
        if (!isEligibleAddress(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListAddress(address[] storage whiteList,address temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleAddress(address[] memory whiteList,address temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexAddress(address[] memory whiteList,address temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}

// File: contracts\modules\Operator.sol

pragma solidity =0.5.16;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Operator is Ownable {
    mapping(uint256=>address) private _operators;
    /**
     * @dev modifier, Only indexed operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperator(uint256 index) {
        require(_operators[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address addAddress)public onlyOwner{
        _operators[index] = addAddress;
    }
    function getOperator(uint256 index)public view returns (address) {
        return _operators[index];
    }
}

// File: contracts\modules\AddressWhiteList.sol

pragma solidity >=0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */


    /**
     * @dev Implementation of a whitelist filters a eligible address.
     */
contract AddressWhiteList is Halt {

    using whiteListAddress for address[];
    // The eligible adress list
    address[] internal whiteList;
    /**
     * @dev Implementation of add an eligible address into the whitelist.
     * @param addAddress new eligible address.
     */
    function addWhiteList(address addAddress)public onlyOwner{
        whiteList.addWhiteListAddress(addAddress);
    }
    /**
     * @dev Implementation of revoke an invalid address from the whitelist.
     * @param removeAddress revoked address.
     */
    function removeWhiteList(address removeAddress)public onlyOwner returns (bool){
        return whiteList.removeWhiteListAddress(removeAddress);
    }
    /**
     * @dev Implementation of getting the eligible whitelist.
     */
    function getWhiteList()public view returns (address[] memory){
        return whiteList;
    }
    /**
     * @dev Implementation of testing whether the input address is eligible.
     * @param tmpAddress input address for testing.
     */    
    function isEligibleAddress(address tmpAddress) public view returns (bool){
        return whiteList.isEligibleAddress(tmpAddress);
    }
}

// File: contracts\modules\ReentrancyGuard.sol

pragma solidity =0.5.16;
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;
  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

// File: contracts\modules\initializable.sol

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

// File: contracts\fixedMinePool\fixedMinePoolData.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */





/**
 * @title new Finnexus Options Pool token mine pool.
 * @dev A smart-contract which distribute some mine coins when you stake some FPT-A and FPT-B coins.
 *      Users who both stake some FPT-A and FPT-B coins will get more bonus in mine pool.
 *      Users who Lock FPT-B coins will get several times than normal miners.
 */
contract fixedMinePoolData is initializable,Operator,Halt,AddressWhiteList,ReentrancyGuard {
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;

    //The timestamp when the minepool begin.
    uint256 internal _startTime;
    //Single locked period duration.
    uint256 internal constant _period = 30 days;
    //The lock duration when user stake flexible FPT-B in this pool.
    uint256 internal _flexibleExpired;

    //The max locked peroid when user stake locked FPT-B coin.
    uint256 constant internal _maxPeriod = 3;
    //The max loop when user does nothing to this pool for long long time .
    uint256 constant internal _maxLoop = 120;
    //the mine distribution's ratio to FPT-A coin 
    uint256 constant internal _FPTARatio = 1000;
    //the mine distribution's ratio to FPT-B coin 
    uint256 constant internal _FPTBRatio = 1000;
    //the mine distribution's ratio to FPT-A and FPT-B coin repetition
    uint256 constant internal _RepeatRatio = 20000;
    //the accumulated weight each period has.
    uint256 constant internal periodWeight = 1000;
    uint256 constant internal baseWeight = 5000;

    // FPT-A address
    address internal _FPTA;
    // FPT-B address
    address internal _FPTB;

    struct userInfo {
        //user's FPT-A staked balance
        uint256 _FPTABalance;
        //user's FPT-B staked balance
        uint256 _FPTBBalance;
        //Period ID start at 1. if a PeriodID equals zero, it means your FPT-B is flexible staked.
        //User's max locked period id;
        uint256 maxPeriodID;
        //User's max locked period timestamp. Flexible FPT-B is locked _flexibleExpired seconds;
        uint256 lockedExpired;
        //User's mine distribution.You can get base mine proportion by your distribution divided by total distribution.
        uint256 distribution;
        //User's settled mine coin balance.
        mapping(address=>uint256) minerBalances;
        //User's latest settled distribution net worth.
        mapping(address=>uint256) minerOrigins;
        //user's latest settlement period for each token.
        mapping(address=>uint256) settlePeriod;
    }
    struct tokenMineInfo {
        //mine distribution amount
        uint256 mineAmount;
        //mine distribution time interval
        uint256 mineInterval;
        //mine distribution first period
        uint256 startPeriod;
        //mine coin latest settlement time
        uint256 latestSettleTime;
        // total mine distribution till latest settlement time.
        uint256 totalMinedCoin;
        //latest distribution net worth;
        uint256 minedNetWorth;
        //period latest distribution net worth;
        mapping(uint256=>uint256) periodMinedNetWorth;
    }

    //User's staking and mining info.
    mapping(address=>userInfo) internal userInfoMap;
    //each mine coin's mining info.
    mapping(address=>tokenMineInfo) internal mineInfoMap;
    //total weight distribution which is used to calculate total mined amount.
    mapping(uint256=>uint256) internal weightDistributionMap;
    //total Distribution
    uint256 internal totalDistribution;

    struct premiumDistribution {
        //total premium distribution in each period
        uint256 totalPremiumDistribution;
        //User's premium distribution in each period
        mapping(address=>uint256) userPremiumDistribution;

    }
    // premium mining info in each period.
    mapping(uint256=>premiumDistribution) internal premiumDistributionMap;
    //user's latest redeemed period index in the distributedPeriod list.
    struct premiumInfo {
        mapping(address=>uint256) lastPremiumIndex;
        mapping(address=>uint256) premiumBalance;
        //period id list which is already distributed by owner.
        uint64[] distributedPeriod;
        //total permium distributed by owner.
        uint256 totalPremium;
        //total premium distributed by owner in each period.
        mapping(uint256=>uint256) periodPremium;
    }
    mapping(address=>premiumInfo) internal premiumMap;
    address[] internal premiumCoinList;

    /**
     * @dev Emitted when `account` stake `amount` FPT-A coin.
     */
    event StakeFPTA(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `from` airdrop `recieptor` `amount` FPT-B coin.
     */
    event LockAirDrop(address indexed from,address indexed recieptor,uint256 amount);
    /**
     * @dev Emitted when `account` stake `amount` FPT-B coin and locked `lockedPeriod` periods.
     */
    event StakeFPTB(address indexed account,uint256 amount,uint256 lockedPeriod);
    /**
     * @dev Emitted when `account` unstake `amount` FPT-A coin.
     */
    event UnstakeFPTA(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `account` unstake `amount` FPT-B coin.
     */
    event UnstakeFPTB(address indexed account,uint256 amount);
    /**
     * @dev Emitted when `account` change `lockedPeriod` locked periods for FPT-B coin.
     */
    event ChangeLockedPeriod(address indexed account,uint256 lockedPeriod);
    /**
     * @dev Emitted when owner `account` distribute `amount` premium in `periodID` period.
     */
    event DistributePremium(address indexed account,address indexed premiumCoin,uint256 indexed periodID,uint256 amount);
    /**
     * @dev Emitted when `account` redeem `amount` premium.
     */
    event RedeemPremium(address indexed account,address indexed premiumCoin,uint256 amount);

    /**
     * @dev Emitted when `account` redeem `value` mineCoins.
     */
    event RedeemMineCoin(address indexed account, address indexed mineCoin, uint256 value);

}

// File: contracts\ERC20\IERC20.sol

pragma solidity =0.5.16;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
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

// File: contracts\modules\Address.sol

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

// File: contracts\ERC20\safeErc20.sol

// SPDX-License-Identifier: MIT
pragma solidity =0.5.16;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts\fixedMinePool\fixedMinePool.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * FinNexus
 * Copyright (C) 2020 FinNexus Options Protocol
 */




/**
 * @title FNX period mine pool.
 * @dev A smart-contract which distribute some mine coins when user stake FPT-A and FPT-B coins.
 *
 */
contract fixedMinePool is fixedMinePoolData {
    using SafeMath for uint256;
    /**
     * @dev constructor.
     * @param FPTA FPT-A coin's address,staking coin
     * @param FPTB FPT-B coin's address,staking coin
     * @param startTime the start time when this mine pool begin.
     */
    constructor(address FPTA,address FPTB,uint256 startTime)public{
        _FPTA = FPTA;
        _FPTB = FPTB;
        _startTime = startTime;
        initialize();
    }
    /**
     * @dev default function for foundation input miner coins.
     */
    function()external payable{

    }
    function update()public onlyOwner{
    }
    /**
     * @dev initial function when the proxy contract deployed.
     */
    function initialize() initializer public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        _flexibleExpired = 7 days;
    }
    /**
     * @dev setting function.
     * @param FPTA FPT-A coin's address,staking coin
     * @param FPTB FPT-B coin's address,staking coin
     * @param startTime the start time when this mine pool begin.
     */
    function setAddresses(address FPTA,address FPTB,uint256 startTime) public onlyOwner {
        _FPTA = FPTA;
        _FPTB = FPTB;
        _startTime = startTime;
    }
    /**
     * @dev getting function. Retrieve FPT-A coin's address
     */
    function getFPTAAddress()public view returns (address) {
        return _FPTA;
    }
    /**
     * @dev getting function. Retrieve FPT-B coin's address
     */
    function getFPTBAddress()public view returns (address) {
        return _FPTB;
    }
    /**
     * @dev getting function. Retrieve mine pool's start time.
     */
    function getStartTime()public view returns (uint256) {
        return _startTime;
    }
    /**
     * @dev getting current mine period ID.
     */
    function getCurrentPeriodID()public view returns (uint256) {
        return getPeriodIndex(currentTime());
    }
    /**
     * @dev getting user's staking FPT-A balance.
     * @param account user's account
     */
    function getUserFPTABalance(address account)public view returns (uint256) {
        return userInfoMap[account]._FPTABalance;
    }
    /**
     * @dev getting user's staking FPT-B balance.
     * @param account user's account
     */
    function getUserFPTBBalance(address account)public view returns (uint256) {
        return userInfoMap[account]._FPTBBalance;
    }
    /**
     * @dev getting user's maximium locked period ID.
     * @param account user's account
     */
    function getUserMaxPeriodId(address account)public view returns (uint256) {
        return userInfoMap[account].maxPeriodID;
    }
    /**
     * @dev getting user's locked expired time. After this time user can unstake FPTB coins.
     * @param account user's account
     */
    function getUserExpired(address account)public view returns (uint256) {
        return userInfoMap[account].lockedExpired;
    }
    /**
     * @dev getting whole pool's mine production weight ratio.
     *      Real mine production equals base mine production multiply weight ratio.
     */
    function getMineWeightRatio()public view returns (uint256) {
        if(totalDistribution > 0) {
            return getweightDistribution(getPeriodIndex(currentTime()))*1000/totalDistribution;
        }else{
            return 1000;
        }
    }
    /**
     * @dev getting whole pool's mine shared distribution. All these distributions will share base mine production.
     */
    function getTotalDistribution() public view returns (uint256){
        return totalDistribution;
    }
    /**
     * @dev foundation redeem out mine coins.
     * @param mineCoin mineCoin address
     * @param amount redeem amount.
     */
    function redeemOut(address mineCoin,uint256 amount)public onlyOwner{
        _redeem(msg.sender,mineCoin,amount);
    }
    /**
     * @dev An auxiliary foundation which transter amount mine coins to recieptor.
     * @param recieptor recieptor recieptor's account.
     * @param mineCoin mineCoin address
     * @param amount redeem amount.
     */
    function _redeem(address payable recieptor,address mineCoin,uint256 amount) internal{
        if (mineCoin == address(0)){
            recieptor.transfer(amount);
        }else{
            IERC20 token = IERC20(mineCoin);
            uint256 preBalance = token.balanceOf(address(this));
            SafeERC20.safeTransfer(token,recieptor,amount);
//            token.transfer(recieptor,amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(preBalance - afterBalance == amount,"settlement token transfer error!");
        }
    }
    /**
     * @dev retrieve total distributed mine coins.
     * @param mineCoin mineCoin address
     */
    function getTotalMined(address mineCoin)public view returns(uint256){
        return mineInfoMap[mineCoin].totalMinedCoin.add(_getLatestMined(mineCoin));
    }
    /**
     * @dev retrieve minecoin distributed informations.
     * @param mineCoin mineCoin address
     * @return distributed amount and distributed time interval.
     */
    function getMineInfo(address mineCoin)public view returns(uint256,uint256){
        return (mineInfoMap[mineCoin].mineAmount,mineInfoMap[mineCoin].mineInterval);
    }
    /**
     * @dev retrieve user's mine balance.
     * @param account user's account
     * @param mineCoin mineCoin address
     */
    function getMinerBalance(address account,address mineCoin)public view returns(uint256){
        return userInfoMap[account].minerBalances[mineCoin].add(_getUserLatestMined(mineCoin,account));
    }
    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     * @param mineCoin mineCoin address
     * @param _mineAmount mineCoin distributed amount
     * @param _mineInterval mineCoin distributied time interval
     */
    function setMineCoinInfo(address mineCoin,uint256 _mineAmount,uint256 _mineInterval)public onlyOwner {
        require(_mineAmount<1e30,"input mine amount is too large");
        require(_mineInterval>0,"input mine Interval must larger than zero");
        _mineSettlement(mineCoin);
        mineInfoMap[mineCoin].mineAmount = _mineAmount;
        mineInfoMap[mineCoin].mineInterval = _mineInterval;
        if (mineInfoMap[mineCoin].startPeriod == 0){
            mineInfoMap[mineCoin].startPeriod = getPeriodIndex(currentTime());
        }
        addWhiteList(mineCoin);
    }

    /**
     * @dev user redeem mine rewards.
     * @param mineCoin mine coin address
     * @param amount redeem amount.
     */
    function redeemMinerCoin(address mineCoin,uint256 amount)public nonReentrant notHalted {
        _mineSettlement(mineCoin);
        _settleUserMine(mineCoin,msg.sender);
        _redeemMineCoin(mineCoin,msg.sender,amount);
    }
    /**
     * @dev subfunction for user redeem mine rewards.
     * @param mineCoin mine coin address
     * @param recieptor recieptor's account
     * @param amount redeem amount.
     */
    function _redeemMineCoin(address mineCoin,address payable recieptor,uint256 amount) internal {
        require (amount > 0,"input amount must more than zero!");
        userInfoMap[recieptor].minerBalances[mineCoin] = 
            userInfoMap[recieptor].minerBalances[mineCoin].sub(amount);
        _redeem(recieptor,mineCoin,amount);
        emit RedeemMineCoin(recieptor,mineCoin,amount);
    }

    /**
     * @dev settle all mine coin.
     */    
    function _mineSettlementAll()internal{
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            _mineSettlement(whiteList[i]);
        }
    }
    /**
     * @dev convert timestamp to period ID.
     * @param _time timestamp. 
     */ 
    function getPeriodIndex(uint256 _time) public view returns (uint256) {
        if (_time<_startTime){
            return 0;
        }
        return _time.sub(_startTime).div(_period)+1;
    }
    /**
     * @dev convert period ID to period's finish timestamp.
     * @param periodID period ID. 
     */
    function getPeriodFinishTime(uint256 periodID)public view returns (uint256) {
        return periodID.mul(_period).add(_startTime);
    }
    function getCurrentTotalAPY(address mineCoin)public view returns (uint256) {
        if (totalDistribution == 0 || mineInfoMap[mineCoin].mineInterval == 0){
            return 0;
        }
        uint256 baseMine = mineInfoMap[mineCoin].mineAmount.mul(365 days)/mineInfoMap[mineCoin].mineInterval;
        return baseMine.mul(getweightDistribution(getPeriodIndex(currentTime())))/totalDistribution;
    }
    /**
     * @dev Calculate user's current APY.
     * @param account user's account.
     * @param mineCoin mine coin address
     */
    function getUserCurrentAPY(address account,address mineCoin)public view returns (uint256) {
        if (totalDistribution == 0 || mineInfoMap[mineCoin].mineInterval == 0){
            return 0;
        }
        uint256 baseMine = mineInfoMap[mineCoin].mineAmount.mul(365 days).mul(
                userInfoMap[account].distribution)/totalDistribution/mineInfoMap[mineCoin].mineInterval;
        return baseMine.mul(getPeriodWeight(getPeriodIndex(currentTime()),userInfoMap[account].maxPeriodID))/1000;
    }
    /**
     * @dev Calculate average locked time.
     */
    function getAverageLockedTime()public view returns (uint256) {
        if (totalDistribution == 0){
            return 0;
        }
        uint256 i = _maxPeriod-1;
        uint256 nowIndex = getPeriodIndex(currentTime());
        uint256[] memory periodLocked = new uint256[](_maxPeriod);
        for (;;i--){
            periodLocked[i] = weightDistributionMap[nowIndex+i];
            for(uint256 j=i+1;j<_maxPeriod;j++){
                if (periodLocked[j]>0){
                    periodLocked[i] = periodLocked[i].sub(periodLocked[j].mul(getPeriodWeight(i,j)-1000)/1000);
                }
            }
            periodLocked[i] = periodLocked[i]*1000/(getPeriodWeight(nowIndex,nowIndex)-1000);
            if (i == 0){
                break;
            }
        }
        uint256 allLockedPeriod = 0;
        for(i=0;i<_maxPeriod;i++){
            allLockedPeriod = allLockedPeriod.add(periodLocked[i].mul(getPeriodFinishTime(nowIndex+i).sub(currentTime())));
        }
        return allLockedPeriod.div(totalDistribution);
    }

    /**
     * @dev the auxiliary function for _mineSettlementAll.
     * @param mineCoin mine coin address
     */    
    function _mineSettlement(address mineCoin)internal{
        uint256 latestTime = mineInfoMap[mineCoin].latestSettleTime;
        uint256 curIndex = getPeriodIndex(latestTime);
        if (curIndex == 0){
            latestTime = _startTime;
        }
        uint256 nowIndex = getPeriodIndex(currentTime());
        if (nowIndex == 0){
            return;
        }
        for (uint256 i=0;i<_maxLoop;i++){
            // If the fixed distribution is zero, we only need calculate 
            uint256 finishTime = getPeriodFinishTime(curIndex);
            if (finishTime < currentTime()){
                _mineSettlementPeriod(mineCoin,curIndex,finishTime.sub(latestTime));
                latestTime = finishTime;
            }else{
                _mineSettlementPeriod(mineCoin,curIndex,currentTime().sub(latestTime));
                latestTime = currentTime();
                break;
            }
            curIndex++;
            if (curIndex > nowIndex){
                break;
            }
        }
        mineInfoMap[mineCoin].periodMinedNetWorth[nowIndex] = mineInfoMap[mineCoin].minedNetWorth;
        uint256 _mineInterval = mineInfoMap[mineCoin].mineInterval;
        if (_mineInterval>0){
            mineInfoMap[mineCoin].latestSettleTime = currentTime()/_mineInterval*_mineInterval;
        }else{
            mineInfoMap[mineCoin].latestSettleTime = currentTime();
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlement. Calculate and record a period mine production. 
     * @param mineCoin mine coin address
     * @param periodID period time
     * @param mineTime covered time.
     */  
    function _mineSettlementPeriod(address mineCoin,uint256 periodID,uint256 mineTime)internal{
        uint256 totalDistri = totalDistribution;
        if (totalDistri > 0){
            uint256 latestMined = _getPeriodMined(mineCoin,mineTime);
            if (latestMined>0){
                mineInfoMap[mineCoin].minedNetWorth = mineInfoMap[mineCoin].minedNetWorth.add(latestMined.mul(calDecimals)/totalDistri);
                mineInfoMap[mineCoin].totalMinedCoin = mineInfoMap[mineCoin].totalMinedCoin.add(latestMined.mul(
                    getweightDistribution(periodID))/totalDistri);
            }
        }
        mineInfoMap[mineCoin].periodMinedNetWorth[periodID] = mineInfoMap[mineCoin].minedNetWorth;
    }
    /**
     * @dev Calculate and record user's mine production. 
     * @param mineCoin mine coin address
     * @param account user's account
     */  
    function _settleUserMine(address mineCoin,address account) internal {
        uint256 nowIndex = getPeriodIndex(currentTime());
        if (nowIndex == 0){
            return;
        }
        if(userInfoMap[account].distribution>0){
            uint256 userPeriod = userInfoMap[account].settlePeriod[mineCoin];
            if(userPeriod == 0){
                userPeriod = 1;
            }
            if (userPeriod < mineInfoMap[mineCoin].startPeriod){
                userPeriod = mineInfoMap[mineCoin].startPeriod;
            }
            for (uint256 i = 0;i<_maxLoop;i++){
                _settlementPeriod(mineCoin,account,userPeriod);
                if (userPeriod >= nowIndex){
                    break;
                }
                userPeriod++;
            }
        }
        userInfoMap[account].minerOrigins[mineCoin] = _getTokenNetWorth(mineCoin,nowIndex);
        userInfoMap[account].settlePeriod[mineCoin] = nowIndex;
    }
    /**
     * @dev the auxiliary function for _settleUserMine. Calculate and record a period mine production. 
     * @param mineCoin mine coin address
     * @param account user's account
     * @param periodID period time
     */ 
    function _settlementPeriod(address mineCoin,address account,uint256 periodID) internal {
        uint256 tokenNetWorth = _getTokenNetWorth(mineCoin,periodID);
        if (totalDistribution > 0){
            userInfoMap[account].minerBalances[mineCoin] = userInfoMap[account].minerBalances[mineCoin].add(
                _settlement(mineCoin,account,periodID,tokenNetWorth));
        }
        userInfoMap[account].minerOrigins[mineCoin] = tokenNetWorth;
    }
    /**
     * @dev retrieve each period's networth. 
     * @param mineCoin mine coin address
     * @param periodID period time
     */ 
    function _getTokenNetWorth(address mineCoin,uint256 periodID)internal view returns(uint256){
        return mineInfoMap[mineCoin].periodMinedNetWorth[periodID];
    }

    /**
     * @dev the auxiliary function for getMinerBalance. Calculate mine amount during latest time phase.
     * @param mineCoin mine coin address
     * @param account user's account
     */ 
    function _getUserLatestMined(address mineCoin,address account)internal view returns(uint256){
        uint256 userDistri = userInfoMap[account].distribution;
        if (userDistri == 0){
            return 0;
        }
        uint256 userperiod = userInfoMap[account].settlePeriod[mineCoin];
        if (userperiod < mineInfoMap[mineCoin].startPeriod){
            userperiod = mineInfoMap[mineCoin].startPeriod;
        }
        uint256 origin = userInfoMap[account].minerOrigins[mineCoin];
        uint256 latestMined = 0;
        uint256 nowIndex = getPeriodIndex(currentTime());
        uint256 userMaxPeriod = userInfoMap[account].maxPeriodID;
        uint256 netWorth = _getTokenNetWorth(mineCoin,userperiod);

        for (uint256 i=0;i<_maxLoop;i++){
            if(userperiod > nowIndex){
                break;
            }
            if (totalDistribution == 0){
                break;
            }
            netWorth = getPeriodNetWorth(mineCoin,userperiod,netWorth);
            latestMined = latestMined.add(userDistri.mul(netWorth.sub(origin)).mul(getPeriodWeight(userperiod,userMaxPeriod))/1000/calDecimals);
            origin = netWorth;
            userperiod++;
        }
        return latestMined;
    }
    /**
     * @dev the auxiliary function for _getUserLatestMined. Calculate token net worth in each period.
     * @param mineCoin mine coin address
     * @param periodID Period ID
     * @param preNetWorth The previous period's net worth.
     */ 
    function getPeriodNetWorth(address mineCoin,uint256 periodID,uint256 preNetWorth) internal view returns(uint256) {
        uint256 latestTime = mineInfoMap[mineCoin].latestSettleTime;
        uint256 curPeriod = getPeriodIndex(latestTime);
        if(periodID < curPeriod){
            return mineInfoMap[mineCoin].periodMinedNetWorth[periodID];
        }else{
            if (preNetWorth<mineInfoMap[mineCoin].periodMinedNetWorth[periodID]){
                preNetWorth = mineInfoMap[mineCoin].periodMinedNetWorth[periodID];
            }
            uint256 finishTime = getPeriodFinishTime(periodID);
            if (finishTime >= currentTime()){
                finishTime = currentTime();
            }
            if(periodID > curPeriod){
                latestTime = getPeriodFinishTime(periodID-1);
            }
            if (totalDistribution == 0){
                return preNetWorth;
            }
            uint256 periodMind = _getPeriodMined(mineCoin,finishTime.sub(latestTime));
            return preNetWorth.add(periodMind.mul(calDecimals)/totalDistribution);
        }
    }
    /**
     * @dev the auxiliary function for getTotalMined. Calculate mine amount during latest time phase .
     * @param mineCoin mine coin address
     */ 
    function _getLatestMined(address mineCoin)internal view returns(uint256){
        uint256 latestTime = mineInfoMap[mineCoin].latestSettleTime;
        uint256 curIndex = getPeriodIndex(latestTime);
        uint256 latestMined = 0;
        for (uint256 i=0;i<_maxLoop;i++){
            if (totalDistribution == 0){
                break;
            }
            uint256 finishTime = getPeriodFinishTime(curIndex);
            if (finishTime < currentTime()){
                latestMined = latestMined.add(_getPeriodWeightMined(mineCoin,curIndex,finishTime.sub(latestTime)));
            }else{
                latestMined = latestMined.add(_getPeriodWeightMined(mineCoin,curIndex,currentTime().sub(latestTime)));
                break;
            }
            curIndex++;
            latestTime = finishTime;
        }
        return latestMined;
    }
    /**
     * @dev Calculate mine amount
     * @param mineCoin mine coin address
     * @param mintTime mine duration.
     */ 
    function _getPeriodMined(address mineCoin,uint256 mintTime)internal view returns(uint256){
        uint256 _mineInterval = mineInfoMap[mineCoin].mineInterval;
        if (totalDistribution > 0 && _mineInterval>0){
            uint256 _mineAmount = mineInfoMap[mineCoin].mineAmount;
            mintTime = mintTime/_mineInterval;
            uint256 latestMined = _mineAmount.mul(mintTime);
            return latestMined;
        }
        return 0;
    }
    /**
     * @dev Calculate mine amount multiply weight ratio in each period.
     * @param mineCoin mine coin address
     * @param mineCoin period ID.
     * @param mintTime mine duration.
     */ 
    function _getPeriodWeightMined(address mineCoin,uint256 periodID,uint256 mintTime)internal view returns(uint256){
        if (totalDistribution > 0){
            return _getPeriodMined(mineCoin,mintTime).mul(getweightDistribution(periodID))/totalDistribution;
        }
        return 0;
    }
    /**
     * @dev Auxiliary function, calculate user's latest mine amount.
     * @param mineCoin the mine coin address
     * @param account user's account
     * @param tokenNetWorth the latest token net worth
     */
    function _settlement(address mineCoin,address account,uint256 periodID,uint256 tokenNetWorth)internal view returns (uint256) {
        uint256 origin = userInfoMap[account].minerOrigins[mineCoin];
        uint256 userMaxPeriod = userInfoMap[account].maxPeriodID;
        require(tokenNetWorth>=origin,"error: tokenNetWorth logic error!");
        return userInfoMap[account].distribution.mul(tokenNetWorth-origin).mul(getPeriodWeight(periodID,userMaxPeriod))/1000/calDecimals;
    }
    /**
     * @dev Stake FPT-A coin and get distribution for mining.
     * @param amount FPT-A amount that transfer into mine pool.
     */
    function stakeFPTA(uint256 amount)public minePoolStarted nonReentrant notHalted{
        amount = getPayableAmount(_FPTA,amount);
        require(amount > 0, 'stake amount is zero');
        removeDistribution(msg.sender);
        userInfoMap[msg.sender]._FPTABalance = userInfoMap[msg.sender]._FPTABalance.add(amount);
        addDistribution(msg.sender);
        emit StakeFPTA(msg.sender,amount);
    }
    /**
     * @dev Air drop to user some FPT-B coin and lock one period and get distribution for mining.
     * @param user air drop's recieptor.
     * @param ftp_b_amount FPT-B amount that transfer into mine pool.
     */
    function lockAirDrop(address user,uint256 ftp_b_amount) minePoolStarted notHalted external{
        if (msg.sender == getOperator(1)){
            lockAirDrop_base(user,ftp_b_amount);
        }else if (msg.sender == getOperator(2)){
            lockAirDrop_stake(user,ftp_b_amount);
        }else{
            require(false ,"Operator: caller is not the eligible Operator");
        }
    }
    function lockAirDrop_base(address user,uint256 ftp_b_amount) internal{
        uint256 curPeriod = getPeriodIndex(currentTime());
        uint256 maxId = userInfoMap[user].maxPeriodID;
        uint256 lockedPeriod = curPeriod > maxId ? curPeriod : maxId;
        ftp_b_amount = getPayableAmount(_FPTB,ftp_b_amount);
        require(ftp_b_amount > 0, 'stake amount is zero');
        removeDistribution(user);
        userInfoMap[user]._FPTBBalance = userInfoMap[user]._FPTBBalance.add(ftp_b_amount);
        userInfoMap[user].maxPeriodID = lockedPeriod;
        userInfoMap[user].lockedExpired = getPeriodFinishTime(lockedPeriod);
        addDistribution(user);
        emit LockAirDrop(msg.sender,user,ftp_b_amount);
    } 
    function lockAirDrop_stake(address user,uint256 lockedPeriod) internal validPeriod(lockedPeriod) {
        uint256 curPeriod = getPeriodIndex(currentTime());
        uint256 userMaxPeriod = curPeriod+lockedPeriod-1;

        require(userMaxPeriod>=userInfoMap[user].maxPeriodID, "lockedPeriod cannot be smaller than current locked period");
        if(userInfoMap[user].maxPeriodID<curPeriod && lockedPeriod == 1){
            require(getPeriodFinishTime(getCurrentPeriodID()+lockedPeriod)>currentTime() + _flexibleExpired, 'locked time must greater than flexible expiration');
        }
        uint256 ftp_a_amount = IERC20(_FPTA).balanceOf(msg.sender);
        ftp_a_amount = getPayableAmount(_FPTA,ftp_a_amount);
        uint256 ftp_b_amount = IERC20(_FPTB).balanceOf(msg.sender);
        ftp_b_amount = getPayableAmount(_FPTB,ftp_b_amount);
        require(ftp_a_amount > 0 || ftp_b_amount > 0, 'stake amount is zero');
        removeDistribution(user);
        userInfoMap[user]._FPTABalance = userInfoMap[user]._FPTABalance.add(ftp_a_amount);
        userInfoMap[user]._FPTBBalance = userInfoMap[user]._FPTBBalance.add(ftp_b_amount);
        if (userInfoMap[user]._FPTBBalance > 0)
        {
            if (lockedPeriod == 0){
                userInfoMap[user].maxPeriodID = 0;
                if (ftp_b_amount>0){
                    userInfoMap[user].lockedExpired = currentTime().add(_flexibleExpired);
                }
            }else{
                userInfoMap[user].maxPeriodID = userMaxPeriod;
                userInfoMap[user].lockedExpired = getPeriodFinishTime(userMaxPeriod);
            }
        }
        addDistribution(user);
        emit StakeFPTA(user,ftp_a_amount);
        emit StakeFPTB(user,ftp_b_amount,lockedPeriod);
    } 
    /**
     * @dev Stake FPT-B coin and lock locedPreiod and get distribution for mining.
     * @param amount FPT-B amount that transfer into mine pool.
     * @param lockedPeriod locked preiod number.
     */
    function stakeFPTB(uint256 amount,uint256 lockedPeriod)public validPeriod(lockedPeriod) minePoolStarted nonReentrant notHalted{
        uint256 curPeriod = getPeriodIndex(currentTime());
        uint256 userMaxPeriod = curPeriod+lockedPeriod-1;
        require(userMaxPeriod>=userInfoMap[msg.sender].maxPeriodID, "lockedPeriod cannot be smaller than current locked period");
        if(userInfoMap[msg.sender].maxPeriodID<curPeriod && lockedPeriod == 1){
            require(getPeriodFinishTime(getCurrentPeriodID()+lockedPeriod)>currentTime() + _flexibleExpired, 'locked time must greater than 15 days');
        }
        amount = getPayableAmount(_FPTB,amount);
        require(amount > 0, 'stake amount is zero');
        removeDistribution(msg.sender);
        userInfoMap[msg.sender]._FPTBBalance = userInfoMap[msg.sender]._FPTBBalance.add(amount);
        if (lockedPeriod == 0){
            userInfoMap[msg.sender].maxPeriodID = 0;
            userInfoMap[msg.sender].lockedExpired = currentTime().add(_flexibleExpired);
        }else{
            userInfoMap[msg.sender].maxPeriodID = userMaxPeriod;
            userInfoMap[msg.sender].lockedExpired = getPeriodFinishTime(userMaxPeriod);
        }
        addDistribution(msg.sender);
        emit StakeFPTB(msg.sender,amount,lockedPeriod);
    }
    /**
     * @dev withdraw FPT-A coin.
     * @param amount FPT-A amount that withdraw from mine pool.
     */
    function unstakeFPTA(uint256 amount)public nonReentrant notHalted{
        require(amount > 0, 'unstake amount is zero');
        require(userInfoMap[msg.sender]._FPTABalance >= amount,
            'unstake amount is greater than total user stakes');
        removeDistribution(msg.sender);
        userInfoMap[msg.sender]._FPTABalance = userInfoMap[msg.sender]._FPTABalance - amount;
        addDistribution(msg.sender);
        _redeem(msg.sender,_FPTA,amount);
        emit UnstakeFPTA(msg.sender,amount);
    }
    /**
     * @dev withdraw FPT-B coin.
     * @param amount FPT-B amount that withdraw from mine pool.
     */
    function unstakeFPTB(uint256 amount)public nonReentrant notHalted minePoolStarted periodExpired(msg.sender){
        require(amount > 0, 'unstake amount is zero');
        require(userInfoMap[msg.sender]._FPTBBalance >= amount,
            'unstake amount is greater than total user stakes');
        removeDistribution(msg.sender);
        userInfoMap[msg.sender]._FPTBBalance = userInfoMap[msg.sender]._FPTBBalance - amount;
        addDistribution(msg.sender);
        _redeem(msg.sender,_FPTB,amount);
        emit UnstakeFPTB(msg.sender,amount);
    }
    /**
     * @dev Add FPT-B locked period.
     * @param lockedPeriod FPT-B locked preiod number.
     */
    function changeFPTBLockedPeriod(uint256 lockedPeriod)public validPeriod(lockedPeriod) minePoolStarted notHalted{
        require(userInfoMap[msg.sender]._FPTBBalance > 0, "stake FPTB balance is zero");
        uint256 curPeriod = getPeriodIndex(currentTime());
        require(curPeriod+lockedPeriod-1>=userInfoMap[msg.sender].maxPeriodID, "lockedPeriod cannot be smaller than current locked period");
        removeDistribution(msg.sender); 
        if (lockedPeriod == 0){
            userInfoMap[msg.sender].maxPeriodID = 0;
            userInfoMap[msg.sender].lockedExpired = currentTime().add(_flexibleExpired);
        }else{
            userInfoMap[msg.sender].maxPeriodID = curPeriod+lockedPeriod-1;
            userInfoMap[msg.sender].lockedExpired = getPeriodFinishTime(curPeriod+lockedPeriod-1);
        }
        addDistribution(msg.sender);
        emit ChangeLockedPeriod(msg.sender,lockedPeriod);
    }
    /**
     * @dev Auxiliary function. getting user's payment
     * @param settlement user's payment coin.
     * @param settlementAmount user's payment amount.
     */
    function getPayableAmount(address settlement,uint256 settlementAmount) internal returns (uint256) {
        if (settlement == address(0)){
            settlementAmount = msg.value;
        }else if (settlementAmount > 0){
            IERC20 oToken = IERC20(settlement);
            uint256 preBalance = oToken.balanceOf(address(this));
            SafeERC20.safeTransferFrom(oToken,msg.sender, address(this), settlementAmount);
            //oToken.transferFrom(msg.sender, address(this), settlementAmount);
            uint256 afterBalance = oToken.balanceOf(address(this));
            require(afterBalance-preBalance==settlementAmount,"settlement token transfer error!");
        }
        return settlementAmount;
    }
    /**
     * @dev Auxiliary function. Clear user's distribution amount.
     * @param account user's account.
     */
    function removeDistribution(address account) internal {
        uint256 addrLen = whiteList.length;
        for(uint256 i=0;i<addrLen;i++){
            _mineSettlement(whiteList[i]);
            _settleUserMine(whiteList[i],account);
        }
        uint256 distri = calculateDistribution(account);
        totalDistribution = totalDistribution.sub(distri);
        uint256 nowId = getPeriodIndex(currentTime());
        uint256 endId = userInfoMap[account].maxPeriodID;
        for(;nowId<=endId;nowId++){
            weightDistributionMap[nowId] = weightDistributionMap[nowId].sub(distri.mul(getPeriodWeight(nowId,endId)-1000)/1000);
        }
        userInfoMap[account].distribution =  0;
        removePremiumDistribution(account);
    }
    /**
     * @dev Auxiliary function. Add user's distribution amount.
     * @param account user's account.
     */
    function addDistribution(address account) internal {
        uint256 distri = calculateDistribution(account);
        uint256 nowId = getPeriodIndex(currentTime());
        uint256 endId = userInfoMap[account].maxPeriodID;
        for(;nowId<=endId;nowId++){
            weightDistributionMap[nowId] = weightDistributionMap[nowId].add(distri.mul(getPeriodWeight(nowId,endId)-1000)/1000);
        }
        userInfoMap[account].distribution =  distri;
        totalDistribution = totalDistribution.add(distri);
        addPremiumDistribution(account);
    }
    /**
     * @dev Auxiliary function. calculate user's distribution.
     * @param account user's account.
     */
    function calculateDistribution(address account) internal view returns (uint256){
        uint256 fptAAmount = userInfoMap[account]._FPTABalance;
        uint256 fptBAmount = userInfoMap[account]._FPTBBalance;
        uint256 repeat = (fptAAmount>fptBAmount*10) ? fptBAmount*10 : fptAAmount;
        return _FPTARatio.mul(fptAAmount).add(_FPTBRatio.mul(fptBAmount)).add(
            _RepeatRatio.mul(repeat));
    }
    /**
     * @dev Auxiliary function. get weight distribution in each period.
     * @param periodID period ID.
     */
    function getweightDistribution(uint256 periodID)internal view returns (uint256) {
        return weightDistributionMap[periodID].add(totalDistribution);
    }
    /**
     * @dev Auxiliary function. get mine weight ratio from current period to one's maximium period.
     * @param currentID current period ID.
     * @param maxPeriod user's maximium period ID.
     */
    function getPeriodWeight(uint256 currentID,uint256 maxPeriod) public pure returns (uint256) {
        if (maxPeriod == 0 || currentID > maxPeriod){
            return 1000;
        }
        uint256 curLocked = maxPeriod-currentID;
        if(curLocked == 0){
            return 1600;
        }else if(curLocked == 1){
            return 3200;
        }else{
            return 5000;
        }
    }

    /**
     * @dev retrieve total distributed options premium.
     */
    function getTotalPremium(address premiumCoin)public view returns(uint256){
        return premiumMap[premiumCoin].totalPremium;
    }

    /**
     * @dev user redeem his options premium rewards.
     */
    function redeemPremium()public nonReentrant notHalted {
        for (uint256 i=0;i<premiumCoinList.length;i++){
            address premiumCoin = premiumCoinList[i];
            settlePremium(msg.sender,premiumCoin);
            uint256 amount = premiumMap[premiumCoin].premiumBalance[msg.sender];
            if (amount > 0){
                premiumMap[premiumCoin].premiumBalance[msg.sender] = 0;
                _redeem(msg.sender,premiumCoin,amount);
                emit RedeemPremium(msg.sender,premiumCoin,amount);
            }
        }
    }
    /**
     * @dev user redeem his options premium rewards.
     * @param amount redeem amount.
     */
    function redeemPremiumCoin(address premiumCoin,uint256 amount)public nonReentrant notHalted {
        require(amount > 0,"redeem amount must be greater than zero");
        settlePremium(msg.sender,premiumCoin);
        premiumMap[premiumCoin].premiumBalance[msg.sender] = premiumMap[premiumCoin].premiumBalance[msg.sender].sub(amount);
        _redeem(msg.sender,premiumCoin,amount);
        emit RedeemPremium(msg.sender,premiumCoin,amount);
    }

    /**
     * @dev get user's premium balance.
     * @param account user's account
     */ 
    function getUserLatestPremium(address account,address premiumCoin)public view returns(uint256){
        return premiumMap[premiumCoin].premiumBalance[account].add(_getUserPremium(account,premiumCoin));
    }
    /**
     * @dev the auxiliary function for getUserLatestPremium. Calculate latest time phase premium.
     */ 
    function _getUserPremium(address account,address premiumCoin)internal view returns(uint256){
        uint256 FPTBBalance = userInfoMap[account]._FPTBBalance;
        if (FPTBBalance > 0){
            uint256 lastIndex = premiumMap[premiumCoin].lastPremiumIndex[account];
            uint256 nowIndex = getPeriodIndex(currentTime());
            uint256 endIndex = lastIndex+_maxLoop < premiumMap[premiumCoin].distributedPeriod.length ? lastIndex+_maxLoop : premiumMap[premiumCoin].distributedPeriod.length;
            uint256 LatestPremium = 0;
            for (; lastIndex< endIndex;lastIndex++){
                uint256 periodID = premiumMap[premiumCoin].distributedPeriod[lastIndex];
                if (periodID == nowIndex || premiumDistributionMap[periodID].totalPremiumDistribution == 0 ||
                    premiumDistributionMap[periodID].userPremiumDistribution[account] == 0){
                    continue;
                }
                LatestPremium = LatestPremium.add(premiumMap[premiumCoin].periodPremium[periodID].mul(premiumDistributionMap[periodID].userPremiumDistribution[account]).div(
                    premiumDistributionMap[periodID].totalPremiumDistribution));
            }        
            return LatestPremium;
        }
        return 0;
    }
    /**
     * @dev Distribute premium from foundation.
     * @param premiumCoin premium token address
     * @param periodID period ID
     * @param amount premium amount.
     */ 
    function distributePremium(address premiumCoin, uint256 periodID,uint256 amount)public onlyOperator(0) {
        amount = getPayableAmount(premiumCoin,amount);
        require(amount > 0, 'Distribution amount is zero');
        require(premiumMap[premiumCoin].periodPremium[periodID] == 0 , "This period is already distributed!");
        uint256 nowIndex = getPeriodIndex(currentTime());
        require(nowIndex > periodID, 'This period is not finished');
        whiteListAddress.addWhiteListAddress(premiumCoinList,premiumCoin);
        premiumMap[premiumCoin].periodPremium[periodID] = amount;
        premiumMap[premiumCoin].totalPremium = premiumMap[premiumCoin].totalPremium.add(amount);
        premiumMap[premiumCoin].distributedPeriod.push(uint64(periodID));
        emit DistributePremium(msg.sender,premiumCoin,periodID,amount);
    }
    /**
     * @dev Auxiliary function. Clear user's premium distribution amount.
     * @param account user's account.
     */ 
    function removePremiumDistribution(address account) internal {
        for (uint256 i=0;i<premiumCoinList.length;i++){
            settlePremium(account,premiumCoinList[i]);
        }
        uint256 beginTime = currentTime(); 
        uint256 nowId = getPeriodIndex(beginTime);
        uint256 endId = userInfoMap[account].maxPeriodID;
        uint256 FPTBBalance = userInfoMap[account]._FPTBBalance;
        if (FPTBBalance> 0 && nowId<endId){
            for(;nowId<endId;nowId++){
                uint256 finishTime = getPeriodFinishTime(nowId);
                uint256 periodDistribution = finishTime.sub(beginTime).mul(FPTBBalance);
                premiumDistributionMap[nowId].totalPremiumDistribution = premiumDistributionMap[nowId].totalPremiumDistribution.sub(periodDistribution);
                premiumDistributionMap[nowId].userPremiumDistribution[account] = premiumDistributionMap[nowId].userPremiumDistribution[account].sub(periodDistribution);
                beginTime = finishTime;
            }
        }
    }
    /**
     * @dev Auxiliary function. Calculate and record user's premium.
     * @param account user's account.
     */ 
    function settlePremium(address account,address premiumCoin)internal{
        premiumMap[premiumCoin].premiumBalance[account] = premiumMap[premiumCoin].premiumBalance[account].add(getUserLatestPremium(account,premiumCoin));
        premiumMap[premiumCoin].lastPremiumIndex[account] = premiumMap[premiumCoin].distributedPeriod.length;
    }
    /**
     * @dev Auxiliary function. Add user's premium distribution amount.
     * @param account user's account.
     */ 
    function addPremiumDistribution(address account) internal {
        uint256 beginTime = currentTime(); 
        uint256 nowId = getPeriodIndex(beginTime);
        uint256 endId = userInfoMap[account].maxPeriodID;
        uint256 FPTBBalance = userInfoMap[account]._FPTBBalance;
        for(;nowId<endId;nowId++){
            uint256 finishTime = getPeriodFinishTime(nowId);
            uint256 periodDistribution = finishTime.sub(beginTime).mul(FPTBBalance);
            premiumDistributionMap[nowId].totalPremiumDistribution = premiumDistributionMap[nowId].totalPremiumDistribution.add(periodDistribution);
            premiumDistributionMap[nowId].userPremiumDistribution[account] = premiumDistributionMap[nowId].userPremiumDistribution[account].add(periodDistribution);
            beginTime = finishTime;
        }

    }
    /**
     * @dev Throws if user's locked expired timestamp is less than now.
     */
    modifier periodExpired(address account){
        require(userInfoMap[account].lockedExpired < currentTime(),'locked period is not expired');

        _;
    }
    /**
     * @dev Throws if input period number is greater than _maxPeriod.
     */
    modifier validPeriod(uint256 period){
        require(period >= 0 && period <= _maxPeriod, 'locked period must be in valid range');
        _;
    }
    /**
     * @dev Throws if minePool is not start.
     */
    modifier minePoolStarted(){
        require(currentTime()>=_startTime, 'mine pool is not start');
        _;
    }
    /**
     * @dev get now timestamp.
     */
    function currentTime() internal view returns (uint256){
        return now;
    }
}