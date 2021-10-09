/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// File: contracts/modules/multiSignatureClient.sol

/**
 * defrost
 * Copyright (C) 2020 defrost Options Protocol
 */
pragma solidity ^0.7.0;

interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
contract multiSignatureClient{
    uint256 private constant multiSignaturePositon = uint256(keccak256("org.Phoenix.multiSignature.storage"));
    constructor(address multiSignature) {
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

// File: contracts/modules/proxyOwner.sol

pragma solidity ^0.7.0;

/**
 * @title  proxyOwner Contract

 */

contract proxyOwner is multiSignatureClient{
    bytes32 private constant proxyOwnerPosition  = keccak256("org.Phoenix.Owner.storage");
    bytes32 private constant proxyOriginPosition  = keccak256("org.Phoenix.Origin.storage");
    uint256 private constant oncePosition  = uint256(keccak256("org.Phoenix.Once.storage"));
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    constructor(address multiSignature) multiSignatureClient(multiSignature) {
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

// File: contracts/defrostFactory/defrostFactoryData.sol

pragma solidity ^0.7.0;

abstract contract defrostFactoryData {
    uint256 constant internal currentVersion = 2;
    mapping(bytes32=>address) public vaultsMap;
    address[] public allVaults;
    address public reservePool;
    address public systemCoin;
    address public dsOracle;

    event CreateVaultPool(address indexed poolAddress,bytes32 indexed vaultID,address indexed collateral,uint256 debtCeiling,uint256 debtFloor,uint256 collateralRate,
    int256 stabilityFee,uint256 feeInterval);
}

// File: contracts/modules/SafeMath.sol

pragma solidity ^0.7.0;

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

// File: contracts/modules/Halt.sol

pragma solidity ^0.7.0;


abstract contract Halt is proxyOwner {
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
        onlyOrigin
    {
        halted = halt;
    }
}

// File: contracts/interface/IDSOracle.sol

pragma solidity ^0.7.0;

interface IDSOracle {
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param asset Asset for which to get the price
  * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
  */
    function getPrice(address asset) external view returns (uint256);
    function getPrices(uint256[] calldata assets) external view returns (uint256[]memory);
}
abstract contract ImportOracle is proxyOwner{
    IDSOracle internal _oracle;
    function oraclegetPrices(uint256[] memory assets) internal view returns (uint256[]memory){
        uint256[] memory prices = _oracle.getPrices(assets);
        uint256 len = assets.length;
        for (uint i=0;i<len;i++){
        require(prices[i] >= 100 && prices[i] <= 1e45,"oracle price error");
        }
        return prices;
    }
    function oraclePrice(address asset) internal view returns (uint256){
        uint256 price = _oracle.getPrice(asset);
        require(price >= 100 && price <= 1e45,"oracle price error");
        return price;
    }
    function getOracleAddress() public view returns(address){
        return address(_oracle);
    }
    function setOracleAddress(address oracle)public onlyOwner{
        _oracle = IDSOracle(oracle);
    }
}

// File: contracts/interface/ISystemCoin.sol

pragma solidity ^0.7.0;
interface ISystemCoin {
    function decimals() external view returns (uint256);
    function transfer(address,uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function mint(address,uint256) external;
    function burn(address,uint256) external;
    function setMinePool(address _MinePool) external;
}

// File: contracts/interestEngine/interestEngine.sol

pragma solidity ^0.7.0;

/**
 * @title interest engine.
 * @dev calculate interest by assets,compounded interest.
 *
 */
contract interestEngine{
    using SafeMath for uint256;

        //Special decimals for calculation
    uint256 constant rayDecimals = 1e27;

    uint256 public totalAssetAmount;
        // Maximum amount of debt that can be generated with this collateral type
    uint256 public assetCeiling;       // [rad]
    // Minimum amount of debt that must be generated by a SAFE using this collateral
    uint256 public assetFloor;         // [rad]
    //interest rate
    int256 internal interestRate;
    uint256 internal interestInterval;
    struct assetInfo{
        uint256 originAsset;
        uint256 assetAndInterest;
        uint256 interestRateOrigin;
    }
    // debt balance
    mapping(address=>assetInfo) public assetInfoMap;

        // latest time to settlement
    uint256 internal latestSettleTime;
    uint256 internal accumulatedRate;

    event SetInterestInfo(address indexed from,int256 _interestRate,uint256 _interestInterval);
    event AddAsset(address indexed recieptor,uint256 amount);
    event SubAsset(address indexed account,uint256 amount,uint256 subOrigin);
    /**
     * @dev retrieve Interest informations.
     * @return distributed Interest rate and distributed time interval.
     */
    function getInterestInfo()public view returns(int256,uint256){
        return (interestRate,interestInterval);
    }

    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     * @param _interestRate mineCoin distributed amount
     * @param _interestInterval mineCoin distributied time interval
     */
    function _setInterestInfo(int256 _interestRate,uint256 _interestInterval,uint256 maxRate,uint256 minRate)internal {
        if (accumulatedRate == 0){
            accumulatedRate = rayDecimals;
        }
        require(_interestRate<=1e27 && _interestRate>=-1e27,"input stability fee is too large");
        require(_interestInterval>0,"input mine Interval must larger than zero");
        uint256 newLimit = rpower(uint256(1e27+_interestRate),31536000/_interestInterval,rayDecimals);
        require(newLimit<=maxRate && newLimit>=minRate,"input stability fee is out of range");
        _interestSettlement();
        interestRate = _interestRate;
        interestInterval = _interestInterval;
        emit SetInterestInfo(msg.sender,_interestRate,_interestInterval);
    }
    function getAssetBalance(address account)public virtual view returns(uint256){
        if(assetInfoMap[account].interestRateOrigin == 0 || interestInterval == 0){
            return 0;
        }
        uint256 newRate = newAccumulatedRate();
        return assetInfoMap[account].assetAndInterest.mul(newRate)/assetInfoMap[account].interestRateOrigin;
    }
    /**
     * @dev mint mineCoin to account when account add collateral to collateral pool, only manager contract can modify database.
     * @param account user's account
     * @param amount the mine shared amount
     */
    function addAsset(address account,uint256 amount) internal settleAccount(account){
        assetInfoMap[account].originAsset = assetInfoMap[account].originAsset.add(amount);
        assetInfoMap[account].assetAndInterest = assetInfoMap[account].assetAndInterest.add(amount);
        totalAssetAmount = totalAssetAmount.add(amount);
        require(assetInfoMap[account].assetAndInterest >= assetFloor, "Debt is below the limit");
        require(totalAssetAmount <= assetCeiling, "vault debt is overflow");
        emit AddAsset(account,amount);
    }
    /**
     * @dev repay user's debt and taxes.
     * @param amount repay amount.
     */
    function subAsset(address account,uint256 amount)internal returns(uint256) {
        uint256 originBalance = assetInfoMap[account].originAsset;
        uint256 assetAndInterest = assetInfoMap[account].assetAndInterest;
        
        uint256 _subAsset;
        if(assetAndInterest == amount){
            _subAsset = originBalance;
            assetInfoMap[account].originAsset = 0;
            assetInfoMap[account].assetAndInterest = 0;
        }else if(assetAndInterest > amount){
            _subAsset = originBalance.mul(amount)/assetAndInterest;
            assetInfoMap[account].assetAndInterest = assetAndInterest.sub(amount);
            require(assetInfoMap[account].assetAndInterest >= assetFloor, "Debt is below the limit");
            assetInfoMap[account].originAsset = originBalance.sub(_subAsset);

        }else{
            require(false,"overflow asset balance");
        }
        totalAssetAmount = totalAssetAmount.sub(amount);
        emit SubAsset(account,amount,_subAsset);
        return _subAsset;
    }
    function rpower(uint256 x, uint256 n, uint256 base) internal pure returns (uint256 z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
    /**
     * @dev the auxiliary function for _mineSettlementAll.
     */    
    function _interestSettlement()internal{
        uint256 _interestInterval = interestInterval;
        if (_interestInterval>0){
            uint256 newRate = newAccumulatedRate();
            totalAssetAmount = totalAssetAmount.mul(newRate)/accumulatedRate;
            accumulatedRate = newRate;
            latestSettleTime = currentTime()/_interestInterval*_interestInterval;
        }else{
            latestSettleTime = currentTime();
        }
    }
    function newAccumulatedRate()internal virtual view returns (uint256){
        uint256 newRate = rpower(uint256(1e27+interestRate),(currentTime()-latestSettleTime)/interestInterval,rayDecimals);
        return accumulatedRate.mul(newRate)/rayDecimals;
    }
    /**
     * @dev settle user's debt balance.
     * @param account user's account
     */
    function settleUserInterest(address account)internal{
        assetInfoMap[account].assetAndInterest = _settlement(account);
        assetInfoMap[account].interestRateOrigin = accumulatedRate;
    }
    /**
     * @dev subfunction, settle user's latest tax amount.
     * @param account user's account
     */
    function _settlement(address account)internal virtual view returns (uint256) {
        if (assetInfoMap[account].interestRateOrigin == 0){
            return 0;
        }
        return assetInfoMap[account].assetAndInterest.mul(accumulatedRate)/assetInfoMap[account].interestRateOrigin;
    }
    modifier settleAccount(address account){
        _interestSettlement();
        settleUserInterest(account);
        _;
    }
    function currentTime() internal virtual view returns (uint256){
        return block.timestamp;
    }
}

// File: contracts/modules/ReentrancyGuard.sol

pragma solidity ^0.7.0;
abstract contract ReentrancyGuard {

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

// File: contracts/collateralVault/vaultEngineData.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;





abstract contract vaultEngineData is Halt,ImportOracle,ReentrancyGuard,interestEngine {
    bool public emergency = false;
    bytes32 public vaultID;
    //Special decimals for calculation
    uint256 constant calDecimals = 1e18;

    uint256 public collateralRate;
    uint256 public liquidationReward;
    uint256 public liquidationPenalty;

    //collateral balance
    mapping(address=>uint256) public collateralBalances;
    
    address public collateralToken;
    address public reservePool;
    ISystemCoin public systemCoin;

    event MintSystemCoin(address indexed sender,address indexed account,uint256 amount);
    event RepaySystemCoin(address indexed sender,address indexed account,uint256 amount);
    event Liquidate(address indexed sender,address indexed account,address indexed collateralToken,
        uint256 debt,uint256 punishment,uint256 amount);
    event Join(address indexed sender, address indexed account, uint256 amount);
    event Exit(address indexed sender, address indexed account, uint256 amount);
    event EmergencyExit(address indexed sender, address indexed account, uint256 amount);
    event SetLiquidationInfo(address indexed sender,uint256 _liquidationReward,uint256 _liquidationPenalty);
    event SetPoolLimitation(address indexed sender,uint256 _assetCeiling,uint256 _assetFloor);
}

// File: contracts/modules/IERC20.sol

/**
 * defrost
 * Copyright (C) 2020 defrost Options Protocol
 */
pragma solidity ^0.7.0;

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

// File: contracts/modules/Address.sol


pragma solidity ^0.7.0;
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: contracts/modules/safeErc20.sol

pragma solidity ^0.7.0;




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

// File: contracts/modules/safeTransfer.sol

pragma solidity ^0.7.0;

abstract contract safeTransfer{
    using SafeERC20 for IERC20;
    event Redeem(address indexed recieptor,address indexed token,uint256 amount);
    function getPayableAmount(address token,uint256 amount) internal returns (uint256) {
        if (token == address(0)){
            amount = msg.value;
        }else if (amount > 0){
            IERC20 oToken = IERC20(token);
            oToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        return amount;
    }
    /**
     * @dev An auxiliary foundation which transter amount stake coins to recieptor.
     * @param recieptor recieptor recieptor's account.
     * @param token token address
     * @param amount redeem amount.
     */
    function _redeem(address recieptor,address token,uint256 amount) internal{
        if (token == address(0)){
            address payable _payableAddr = address(uint160(recieptor));
            _payableAddr.transfer(amount);
        }else{
            IERC20 oToken = IERC20(token);
            oToken.safeTransfer(recieptor,amount);
        }
        emit Redeem(recieptor,token,amount);
    }
}

// File: contracts/collateralVault/vaultEngine.sol



/**
 * @title Tax calculate pool.
 * @dev Borrow system coin, your debt will be increased with interests every minute.
 *
 */
abstract contract vaultEngine is vaultEngineData,safeTransfer {
    using SafeMath for uint256;
    /**
     * @dev default function for foundation input miner coins.
     */
    receive()external payable{

    }
    function setStabilityFee(int256 stabilityFee,uint256 feeInterval)external onlyOrigin{
        _setInterestInfo(stabilityFee,feeInterval,12e26,8e26);
    }
    function getCollateralLeft(address account) external view returns (uint256){
        uint256 assetAndInterest =getAssetBalance(account).mul(collateralRate);
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 allCollateral = collateralBalances[account].mul(collateralPrice);
        if (allCollateral > assetAndInterest){
            return (allCollateral - assetAndInterest)/calDecimals;
        }
        return 0;
    }
    function canLiquidate(address account) external view returns (bool){
        uint256 assetAndInterest =getAssetBalance(account);
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 allCollateral = collateralBalances[account].mul(collateralPrice);
        return assetAndInterest.mul(collateralRate)>allCollateral;
    }
    function checkLiquidate(address account,uint256 removeCollateral,uint256 newMint) internal view returns(bool){
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 allCollateral = (collateralBalances[account].sub(removeCollateral)).mul(collateralPrice);
        uint256 assetAndInterest = assetInfoMap[account].assetAndInterest.add(newMint);
        return assetAndInterest.mul(collateralRate)<=allCollateral;
    }
}

// File: contracts/collateralVault/collateralVault.sol

contract collateralVault is vaultEngine {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    constructor (address multiSignature,bytes32 _vaultID,address _collateralToken,address _reservePool,address _systemCoin,address _dsOracle) proxyOwner(multiSignature){
        vaultID = _vaultID;
        collateralToken = _collateralToken;
        reservePool = _reservePool;
        systemCoin = ISystemCoin(_systemCoin);
        _oracle = IDSOracle(_dsOracle);
    }
    function initContract(int256 _stabilityFee,uint256 _feeInterval,uint256 _assetCeiling,uint256 _assetFloor,
        uint256 _collateralRate,uint256 _liquidationReward,uint256 _liquidationPenalty)external onlyOwner{
            require(_collateralRate >= 1e18 && _collateralRate<= 5e18 ,"Collateral Vault : collateral rate overflow!");
        assetCeiling = _assetCeiling;
        assetFloor = _assetFloor;
        collateralRate = _collateralRate;
        latestSettleTime = block.timestamp;
        accumulatedRate = rayDecimals;
        _setInterestInfo(_stabilityFee,_feeInterval,12e26,8e26);
        _setLiquidationInfo(_liquidationReward,_liquidationPenalty);
    }
    function setEmergency()external isHalted onlyOrigin{
        emergency = true;
    }
    function setLiquidationInfo(uint256 _liquidationReward,uint256 _liquidationPenalty)external onlyOrigin{
        _setLiquidationInfo(_liquidationReward,_liquidationPenalty);
    }
    function _setLiquidationInfo(uint256 _liquidationReward,uint256 _liquidationPenalty)internal {
        require(_liquidationPenalty<= _liquidationReward && _liquidationReward <= collateralRate-calDecimals,"Collateral Vault : Liquidate setting overflow!");
        liquidationReward = _liquidationReward;
        liquidationPenalty = _liquidationPenalty; 
        emit SetLiquidationInfo(msg.sender,_liquidationReward,_liquidationPenalty);
    }
    function setPoolLimitation(uint256 _assetCeiling,uint256 _assetFloor)external onlyOrigin{
        assetCeiling = _assetCeiling;
        assetFloor = _assetFloor;
        emit SetPoolLimitation(msg.sender,_assetCeiling,_assetFloor);
    }
    /**
    * @notice Join collateral in the system
    * @dev This function locks collateral in the adapter and creates a 'representation' of
    *      the locked collateral inside the system. This adapter assumes that the collateral
    *      has 18 decimals
    * @param account Account from which we transferFrom collateral and add it in the system
    * @param amount Amount of collateral to transfer in the system
    **/

    function join(address account, uint256 amount) notHalted nonReentrant payable external {
        _join(account,amount);
    }
    function _join(address account, uint256 amount) internal {
        collateralBalances[account] = collateralBalances[account].add(amount);
        amount = getPayableAmount(collateralToken,amount);
        emit Join(msg.sender, account, amount);
    }    
    /**
    * @notice Exit collateral from the system
    * @dev This function destroys the collateral representation from inside the system
    *      and exits the collateral from this adapter. The adapter assumes that the collateral
    *      has 18 decimals
    * @param account Account to which we transfer the collateral
    * @param amount Amount of collateral to transfer to 'account'
    **/
    function exit(address account, uint256 amount) notHalted nonReentrant settleAccount(msg.sender) external {
        require(checkLiquidate(msg.sender,0,amount),"collateral remove overflow!");
        collateralBalances[msg.sender] = collateralBalances[msg.sender].sub(amount);
        _redeem(account,collateralToken,amount);
        emit Exit(msg.sender, account, amount);
    }
    function emergencyExit(address account) isHalted nonReentrant external{
        require(emergency,"This contract is not at emergency state");
        uint256 amount = collateralBalances[msg.sender];
        _redeem(account,collateralToken,amount);
        collateralBalances[msg.sender] = 0;
        emit EmergencyExit(msg.sender, account, amount);
    }
    function getMaxBorrowAmount(address account,uint256 newAddCollateral) external view returns(uint256){
        uint256 allDebt =getAssetBalance(account);
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 newMint = collateralBalances[account].add(newAddCollateral).mul(collateralPrice)/collateralRate;
        if (newMint>allDebt){
            return newMint - allDebt;
        }
        return 0;
    }
    function mintSystemCoin(address account, uint256 amount) notHalted nonReentrant external{
        _mintSystemCoin(account,amount);
    }
    function _mintSystemCoin(address account, uint256 amount) settleAccount(msg.sender) internal{
        require(checkLiquidate(msg.sender,0,amount),"overflow liquidation limit!");
        systemCoin.mint(account,amount);
        addAsset(msg.sender,amount);
        emit MintSystemCoin(msg.sender,account,amount);
    }
    function joinAndMint(uint256 collateralamount, uint256 systemCoinAmount)payable notHalted nonReentrant settleAccount(msg.sender) external{
        _join(msg.sender,collateralamount);
        _mintSystemCoin(msg.sender,systemCoinAmount);
    }
    function repaySystemCoin(address account, uint256 amount) notHalted nonReentrant settleAccount(account) external{
        if(amount == uint256(-1)){
            amount = assetInfoMap[account].assetAndInterest;
        }
        _repaySystemCoin(account,amount);
        emit RepaySystemCoin(msg.sender,account,amount);
    }
    function _repaySystemCoin(address account, uint256 amount) internal{
        uint256 _repayDebt = subAsset(account,amount);
        if(amount>_repayDebt){
            require(systemCoin.transferFrom(msg.sender, reservePool, amount.sub(_repayDebt)),"systemCoin : transferFrom failed!");
            systemCoin.burn(msg.sender,_repayDebt);
        }else{
            systemCoin.burn(msg.sender,amount);
        }
        emit RepaySystemCoin(msg.sender,account,amount);
    }
    function liquidate(address account) notHalted settleAccount(account) nonReentrant external{        
        require(!checkLiquidate(account,0,0),"liquidation check error!");
        uint256 collateralPrice = oraclePrice(collateralToken);
        uint256 collateral = collateralBalances[account];
        uint256 allDebt = assetInfoMap[account].assetAndInterest;
        uint256 penalty = allDebt.mul(liquidationPenalty)/calDecimals;
        IERC20 oToken = IERC20(address(systemCoin));
        _repaySystemCoin(account,allDebt);
        oToken.safeTransferFrom(msg.sender, reservePool, penalty);
        allDebt += penalty;
        uint256 _payback = allDebt.mul(calDecimals+liquidationReward)/collateralPrice;
        _payback = _payback <= collateral ? _payback : collateral;
        collateralBalances[account] = collateralBalances[account].sub(_payback);
        _redeem(msg.sender,collateralToken,_payback);
        emit Liquidate(msg.sender,account,collateralToken,allDebt,penalty,_payback);  
    }
}

// File: contracts/systemCoin/Coin.sol



pragma solidity ^0.7.0;
contract Coin {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "Coin/account-not-authorized");
        _;
    }

    // --- ERC20 Data ---
    // The name of this coin
    string  public name;
    // The symbol of this coin
    string  public symbol;
    // The version of this Coin contract
    string  public version = "1";
    // The number of decimals that this coin has
    uint8   public constant decimals = 18;

    // The id of the chain where this coin was deployed
    uint256 public chainId;
    // The total supply of this coin
    uint256 public totalSupply;

    // Mapping of coin balances
    mapping (address => uint256)                      public balanceOf;
    // Mapping of allowances
    mapping (address => mapping (address => uint256)) public allowance;
    // Mapping of nonces used for permits
    mapping (address => uint256)                      public nonces;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Approval(address indexed src, address indexed guy, uint256 amount);
    event Transfer(address indexed src, address indexed dst, uint256 amount);

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Coin/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Coin/sub-underflow");
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(string memory name_,
        string memory symbol_,
        uint256 chainId_
      ) {
        authorizedAccounts[msg.sender] = 1;
        name          = name_;
        symbol        = symbol_;
        chainId       = chainId_;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
        emit AddAuthorization(msg.sender);
    }

    // --- Token ---
    /*
    * @notice Transfer coins to another address
    * @param dst The address to transfer coins to
    * @param amount The amount of coins to transfer
    */
    function transfer(address dst, uint256 amount) public virtual returns (bool) {
        return transferFrom(msg.sender, dst, amount);
    }
    /*
    * @notice Transfer coins from a source address to a destination address (if allowed)
    * @param src The address from which to transfer coins
    * @param dst The address that will receive the coins
    * @param amount The amount of coins to transfer
    */
    function transferFrom(address src, address dst, uint256 amount)
        public virtual returns (bool)
    {
        require(dst != address(0), "Coin/null-dst");
        require(dst != address(this), "Coin/dst-cannot-be-this-contract");
        require(balanceOf[src] >= amount, "Coin/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= amount, "Coin/insufficient-allowance");
            allowance[src][msg.sender] = subtract(allowance[src][msg.sender], amount);
        }
        balanceOf[src] = subtract(balanceOf[src], amount);
        balanceOf[dst] = addition(balanceOf[dst], amount);
        emit Transfer(src, dst, amount);
        return true;
    }
    /*
    * @notice Mint new coins
    * @param usr The address for which to mint coins
    * @param amount The amount of coins to mint
    */
    function mint(address usr, uint256 amount) public virtual isAuthorized {
        balanceOf[usr] = addition(balanceOf[usr], amount);
        totalSupply    = addition(totalSupply, amount);
        emit Transfer(address(0), usr, amount);
    }
    /*
    * @notice Burn coins from an address
    * @param usr The address that will have its coins burned
    * @param amount The amount of coins to burn
    */
    function burn(address usr, uint256 amount) public virtual {
        require(balanceOf[usr] >= amount, "Coin/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint256(-1)) {
            require(allowance[usr][msg.sender] >= amount, "Coin/insufficient-allowance");
            allowance[usr][msg.sender] = subtract(allowance[usr][msg.sender], amount);
        }
        balanceOf[usr] = subtract(balanceOf[usr], amount);
        totalSupply    = subtract(totalSupply, amount);
        emit Transfer(usr, address(0), amount);
    }
    /*
    * @notice Change the transfer/burn allowance that another address has on your behalf
    * @param usr The address whose allowance is changed
    * @param amount The new total allowance for the usr
    */
    function approve(address usr, uint256 amount) external returns (bool) {
        allowance[msg.sender][usr] = amount;
        emit Approval(msg.sender, usr, amount);
        return true;
    }


    // --- Approve by signature ---
    /*
    * @notice Submit a signed message that modifies an allowance for a specific address
    */
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "Coin/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Coin/invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "Coin/permit-expired");
        require(nonce == nonces[holder]++, "Coin/invalid-nonce");
        uint256 wad = allowed ? uint256(-1) : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
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

// File: contracts/interface/ICoinMinePool.sol


pragma solidity ^0.7.0;
interface ICoinMinePool {
//    function transferMinerCoin(address account,address recieptor)external;
    function changeUserbalance(address account,int256 amount) external;
}

// File: contracts/systemCoin/mineCoin.sol

pragma solidity ^0.7.0;



contract mineCoin is Coin {
        constructor(
        string memory name_,
        string memory symbol_,
        uint256 chainId_
      )  Coin(name_,symbol_,chainId_) {

      }
    ICoinMinePool public minePool;
    function setMinePool(address _minePool) external isAuthorized{
        minePool = ICoinMinePool(_minePool);
    }
        /*
        /**
     * @dev Move user's PPT to 'recipient' balance, a interface in ERC20. 
     * @param recipient recipient's account.
     * @param amount amount of PPT.
     */ 
     /*
    function transfer(address recipient, uint256 amount)public override returns (bool){
        if (address(minePool) != address(0)){
            minePool.transferMinerCoin(msg.sender,recipient);
        }
        bool success = super.transfer(recipient,amount);
        if (!success){
            return false;
        }

        return true;
    }
    */
    /*
        /**
     * @dev Move sender's PPT to 'recipient' balance, a interface in ERC20. 
     * @param sender sender's account.
     * @param recipient recipient's account.
     * @param amount amount of PPT.
     */ 
     /*
    function transferFrom(address sender, address recipient, uint256 amount)public override returns (bool){
        if (address(minePool) != address(0)){
            minePool.transferMinerCoin(sender,recipient);
        }
        bool success = super.transferFrom(sender,recipient,amount);
        if (!success){
            return false;
        }
        return true;            
    }
    */
        /**
     * @dev burn user's PPT when user redeem PPTCoin. 
     * @param account user's account.
     * @param amount amount of PPT.
     */ 
    function burn(address account, uint256 amount) public override {
        require(int256(amount) >= 0, "systemCoin : burn overflow");
        if (address(minePool) != address(0)){
            minePool.changeUserbalance(account,-int256(amount));
        }
        super.burn(account,amount);
    }
    /**
     * @dev mint user's PPT when user add collateral. 
     * @param account user's account.
     * @param amount amount of PPT.
     */ 
    function mint(address account, uint256 amount) public override {
        require(int256(amount) >= 0, "systemCoin : mint overflow");
        if (address(minePool) != address(0)){
            minePool.changeUserbalance(account,int256(amount));
        }
        super.mint(account,amount);
    }
}

// File: contracts/defrostFactory/defrostFactory.sol

pragma solidity ^0.7.0;



interface Authorization{
    function addAuthorization(address account) external;
}
contract defrostFactory is defrostFactoryData {
    /**
     * @dev constructor.
     */
    constructor(){

    }
    
    // function createVault(bytes32 vaultID,address collateral,uint256 debtCeiling,uint256 debtFloor,uint256 collateralRate,
    // int256 stabilityFee,uint256 feeInterval,uint256 liquidationReward,uint256 liquidationPenalty)external onlyOrigin returns(address){
    //     address vaultAddress = getVault(vaultID);
    //     require(vaultAddress == address(0),"this vault is already created!");
    //     return createVaultPool(vaultID,collateral,debtCeiling,debtFloor,collateralRate,
    //         stabilityFee,feeInterval,liquidationReward,liquidationPenalty);
    // }
    // function getVault(bytes32 vaultID)public view returns (address){
    //    return vaultsMap[vaultID];
    //}
    function getAllVaults()external view returns (address[] memory){
        return allVaults;
    }
    function createVaultPool(bytes32 vaultID,address collateral,uint256 debtCeiling,uint256 debtFloor,uint256 collateralRate,
    int256 stabilityFee,uint256 feeInterval,uint256 liquidationReward,uint256 liquidationPenalty)internal virtual returns(address){
        
        collateralVault vaultPool = new collateralVault(address(0x0),vaultID,collateral,reservePool,systemCoin,dsOracle);
        vaultPool.initContract(stabilityFee,feeInterval,debtCeiling,debtFloor,collateralRate,liquidationReward,liquidationPenalty);
        Authorization(systemCoin).addAuthorization(address(vaultPool));
        vaultsMap[vaultID] = address(vaultPool);
        emit CreateVaultPool(address(vaultPool),vaultID,collateral,debtCeiling,debtFloor,collateralRate,
            stabilityFee,feeInterval);
        return address(vaultPool);
    }
    
//     function createSystemCoin(string memory name_,
//         string memory symbol_,
//         uint256 chainId_)external onlyOrigin {
//         require(systemCoin == address(0),"systemCoin : systemCoin is already deployed!");
//         mineCoin coin = new mineCoin(name_,symbol_,chainId_);
//         systemCoin = address(coin);
//     }
//     function setSystemCoinMinePool(address minePool)external onlyOrigin{
//         mineCoin(systemCoin).setMinePool(minePool);
//     }
}