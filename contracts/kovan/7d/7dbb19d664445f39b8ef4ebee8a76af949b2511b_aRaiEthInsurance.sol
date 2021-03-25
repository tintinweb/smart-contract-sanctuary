/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity ^0.6.7;

library Errors{
    string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
    string public constant MATH_ADDITION_OVERFLOW = '49';
    string public constant MATH_DIVISION_BY_ZERO = '50';
}

library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
    * @return One ray, 1e27
    **/
    function ray() internal pure returns (uint256) {
        return RAY;
    }

    /**
    * @return One wad, 1e18
    **/

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    /**
    * @return Half ray, 1e27/2
    **/
    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    /**
    * @return Half ray, 1e18/2
    **/
    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    /**
    * @dev Multiplies two wad, rounding half up to the nearest wad
    * @param a Wad
    * @param b Wad
    * @return The result of a*b, in wad
    **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
        return 0;
        }

        require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * b + halfWAD) / WAD;
    }

    /**
    * @dev Divides two wad, rounding half up to the nearest wad
    * @param a Wad
    * @param b Wad
    * @return The result of a/b, in wad
    **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * WAD + halfB) / b;
    }

    /**
    * @dev Multiplies two ray, rounding half up to the nearest ray
    * @param a Ray
    * @param b Ray
    * @return The result of a*b, in ray
    **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
        return 0;
        }

        require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * b + halfRAY) / RAY;
    }

    /**
    * @dev Divides two ray, rounding half up to the nearest ray
    * @param a Ray
    * @param b Ray
    * @return The result of a/b, in ray
    **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * RAY + halfB) / b;
    }

    /**
    * @dev Casts ray down to wad
    * @param a Ray
    * @return a casted to wad, rounded half up to the nearest wad
    **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

        return result / WAD_RAY_RATIO;
    }

    /**
    * @dev Converts wad up to ray
    * @param a Wad
    * @return a converted in ray
    **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
        return result;
    }
}

contract SafeMath{
        /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ReentrancyGuard {

    /**
    * @dev We use a single lock for the whole contract.
    */
    bool private rentrancy_lock = false;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * @notice If you mark a function `nonReentrant`, you should also
    * mark it `external`. Calling one nonReentrant function from
    * another is not supported. Instead, you can implement a
    * `private` function doing the actual work, and a `external`
    * wrapper marked as `nonReentrant`.
    */
    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

}

interface ILendingPool{
    
      function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
      ) external;
    
      /**
      * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
      * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
      * @param asset The address of the underlying asset to withdraw
      * @param amount The underlying amount to be withdrawn
      *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
      * @param to Address that will receive the underlying, same as msg.sender if the user
      *   wants to receive it on his own wallet, or a different address if the beneficiary is a
      *   different wallet
      * @return The final amount withdrawn
      **/
      function withdraw(
        address asset,
        uint256 amount,
        address to
      ) external returns (uint256);

      function getReserveNormalizedIncome(address asset) external view returns (uint256);
}

interface IAToken{
    
    function scaledBalanceOf(address user) external view returns (uint256);
    
    function balanceOf(address user) external view returns (uint256);
    
    function POOL() external view returns (ILendingPool);
       
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
    
    function approve(address spender, uint256 value) external;
}

interface IWETHGateway {
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address onBehalfOf
    ) external;

    function repayETH(
        address lendingPool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function borrowETH(
        address lendingPool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external;
}

interface IGebSafeManager{
    function ownsSAFE(uint256 safeId) view external returns (address);
    function safeCan(address owner, uint256 safeId, address saviour) view external returns (uint);
    function safes(uint256 safeId) view external returns (address);
}

interface ISAFEEngine{

    function collateralTypes(bytes32) external view returns (
        uint256 debtAmount,        // [wad]
        uint256 accumulatedRate,   // [ray]
        uint256 safetyPrice,       // [ray]
        uint256 debtCeiling,       // [rad]
        uint256 debtFloor,         // [rad]
        uint256 liquidationPrice   // [ray]
    );
    function safes(bytes32,address) external view returns (
        uint256 lockedCollateral,  // [wad]
        uint256 generatedDebt      // [wad]
    );
    function confiscateSAFECollateralAndDebt(bytes32,address,address,address,int256,int256) external;
    function canModifySAFE(address, address) external view returns (bool);
    function approveSAFEModification(address) external;
    function denySAFEModification(address) external;

    function modifySAFECollateralization(
        bytes32 collateralType,
        address safe,
        address collateralSource,
        address debtDestination,
        int256 deltaCollateral,
        int256 deltaDebt
    ) external;
}

interface SAFESaviourRegistry{

    function markSave(bytes32 collateralType, address handler) external;

}

interface ILiquidationEngine{
    function safeSaviours(address saviour) external view returns (uint);
}

interface IOracleRelayer{
    function collateralTypes(bytes32 collateralType) external view returns (address, uint256, uint256);
    function safetyCRatio(bytes32 collateralType) external view returns (uint256);
    function liquidationCRatio(bytes32 collateralType) external view returns (uint256);
    function redemptionPrice() external returns (uint256);
}

interface ICollateralJoin {
    function safeEngine() external view returns (address); // fine
    function collateralType() external view returns (bytes32);
    function collateral() external view returns (address);
    function decimals() external view returns (uint256);
    function contractEnabled() external view returns (uint256);
    function join(address, uint256) payable external;
}

interface IPriceFeed{
    function priceSource() external view returns (address);
    function getResultWithValidity() external view returns (uint256,bool);
}

interface IERC20{
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function deposit() external payable;
    function balanceOf(address) external returns (uint256); 
}

contract aRaiEthInsurance is SafeMath, ReentrancyGuard {
    
    using WadRayMath for uint256;
    
    // Checks whether a saviour contract has been approved by governance in the LiquidationEngine
    modifier liquidationEngineApproved(address saviour) {
        require(liquidationEngine.safeSaviours(saviour) == 1, "SafeSaviour/not-approved-in-liquidation-engine");
        _;
    }
    // Checks whether someone controls a safe handler inside the GebSafeManager
    modifier controlsSAFE(address owner, uint256 safeID) {
        require(owner != address(0), "SafeSaviour/null-owner");
        require(either(owner == safeManager.ownsSAFE(safeID), safeManager.safeCan(safeManager.ownsSAFE(safeID), safeID, owner) == 1), "SafeSaviour/not-owning-safe");

        _;
    }

    IERC20 public collateralToken;

    ILiquidationEngine   public liquidationEngine;
    IOracleRelayer       public oracleRelayer;
    IGebSafeManager      public safeManager;
    ISAFEEngine          public safeEngine;
    SAFESaviourRegistry  public saviourRegistry;
    ICollateralJoin      public collateralJoin;
    IAToken              public aToken;
    ILendingPool         public POOL;
    IWETHGateway         public wethGatway;
    
    // The amount of tokens the keeper gets in exchange for the gas spent to save a SAFE
    uint256 public keeperPayout;          // [wad]
    // The minimum fiat value that the keeper must get in exchange for saving a SAFE
    uint256 public minKeeperPayoutValue;  // [wad]
    /*
      The proportion between the keeperPayout (if it's in collateral) and the amount of collateral that's in a SAFE to be saved.
      Alternatively, it can be the proportion between the fiat value of keeperPayout and the fiat value of the profit that a keeper
      could make if a SAFE is liquidated right now. It ensures there's no incentive to intentionally put a SAFE underwater and then
      save it just to make a profit that's greater than the one from participating in collateral auctions
    */
    uint256 public payoutToSAFESize;
    // The default collateralization ratio a SAFE should have after it's saved
    uint256 public defaultDesiredCollateralizationRatio;  // [percentage]

    mapping(bytes32 => mapping(address => uint256)) public desiredCollateralizationRatios;


    mapping(address => uint256) internal aTokenPrincipalBalance;

    // --- Events ---
    event Deposit(address indexed caller, address indexed safeHandler, uint256 amount);
    event Withdraw(address indexed caller, uint256 indexed safeID, address indexed safeHandler, uint256 amount);


    // --- Constants ---
    
    uint256 public constant ONE               = 1;
    uint256 public constant HUNDRED           = 100;
    uint256 public constant THOUSAND          = 1000;
    uint256 public constant CRATIO_SCALE_DOWN = 10**25;
    uint256 public constant WAD_COMPLEMENT    = 10**9;
    uint256 public constant WAD               = 10**18;
    uint256 public constant RAY               = 10**27;
    uint256 public constant MAX_CRATIO        = 1000;
    uint256 public constant MAX_UINT          = uint(-1);


    constructor(
        address collateralJoin_,
        address liquidationEngine_,
        address oracleRelayer_,
        address safeEngine_,
        address safeManager_,
        address saviourRegistry_,
        uint256 keeperPayout_,
        uint256 minKeeperPayoutValue_,
        uint256 payoutToSAFESize_,
        uint256 defaultDesiredCollateralizationRatio_,
        address aTokenAddress,
        address wethGatewayAddress
    ) public {
        require(collateralJoin_ != address(0), "GeneralTokenReserveSafeSaviour/null-collateral-join");
        require(liquidationEngine_ != address(0), "GeneralTokenReserveSafeSaviour/null-liquidation-engine");
        require(oracleRelayer_ != address(0), "GeneralTokenReserveSafeSaviour/null-oracle-relayer");
        require(safeEngine_ != address(0), "GeneralTokenReserveSafeSaviour/null-safe-engine");
        require(safeManager_ != address(0), "GeneralTokenReserveSafeSaviour/null-safe-manager");
        require(saviourRegistry_ != address(0), "GeneralTokenReserveSafeSaviour/null-saviour-registry");
        require(keeperPayout_ > 0, "GeneralTokenReserveSafeSaviour/invalid-keeper-payout");
        require(defaultDesiredCollateralizationRatio_ > 0, "GeneralTokenReserveSafeSaviour/null-default-cratio");
        require(payoutToSAFESize_ > 1, "GeneralTokenReserveSafeSaviour/invalid-payout-to-safe-size");
        require(minKeeperPayoutValue_ > 0, "GeneralTokenReserveSafeSaviour/invalid-min-payout-value");

        keeperPayout         = keeperPayout_;
        payoutToSAFESize     = payoutToSAFESize_;
        minKeeperPayoutValue = minKeeperPayoutValue_;

        liquidationEngine    = ILiquidationEngine(liquidationEngine_);
        collateralJoin       = ICollateralJoin(collateralJoin_);
        oracleRelayer        = IOracleRelayer(oracleRelayer_);
        safeEngine           = ISAFEEngine(safeEngine_);
        safeManager          = IGebSafeManager(safeManager_);
        saviourRegistry      = SAFESaviourRegistry(saviourRegistry_);
        collateralToken      = IERC20(collateralJoin.collateral());
        aToken               = IAToken(aTokenAddress);
        POOL                 = ILendingPool(address(aToken.POOL()));
        wethGatway           = IWETHGateway(wethGatewayAddress);

        uint256 scaledLiquidationRatio = oracleRelayer.liquidationCRatio(collateralJoin.collateralType()) / CRATIO_SCALE_DOWN;

        require(scaledLiquidationRatio > 0, "GeneralTokenReserveSafeSaviour/invalid-scaled-liq-ratio");
        require(both(defaultDesiredCollateralizationRatio_ > scaledLiquidationRatio, defaultDesiredCollateralizationRatio_ <= MAX_CRATIO), "GeneralTokenReserveSafeSaviour/invalid-default-desired-cratio");
        require(collateralJoin.decimals() == 18, "GeneralTokenReserveSafeSaviour/invalid-join-decimals");
        require(collateralJoin.contractEnabled() == 1, "GeneralTokenReserveSafeSaviour/join-disabled");

        defaultDesiredCollateralizationRatio = defaultDesiredCollateralizationRatio_;
    }

    fallback() external payable {}

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y) }
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Events ---
    event SetDesiredCollateralizationRatio(address indexed caller, uint256 indexed safeID, address indexed safeHandler, uint256 cRatio);
    event SaveSAFE(address indexed keeper, bytes32 indexed collateralType, address indexed safeHandler, uint256 collateralAddedOrDebtRepaid);
    
    
    function collateralCover(address safeHandler) virtual view public returns(uint256) {
        return aTokenPrincipalBalance[safeHandler].rayMul(POOL.getReserveNormalizedIncome(aToken.UNDERLYING_ASSET_ADDRESS())); 
    }

    function getKeeperPayoutValue() virtual view public returns (uint256){
        
        (address ethFSM,,) = oracleRelayer.collateralTypes(collateralJoin.collateralType());
        
        (uint256 priceFeedValue, bool hasValidValue) = IPriceFeed(IPriceFeed(ethFSM).priceSource()).getResultWithValidity();

        if(!either(hasValidValue, priceFeedValue == 0)){
            return 0;
        }

        return mul(keeperPayout, priceFeedValue) / WAD;
    }


    function keeperPayoutExceedsMinValue() virtual view public returns (bool){

        (address ethFSM,,) = oracleRelayer.collateralTypes(collateralJoin.collateralType());
        (uint256 priceFeedValue, bool hasValidValue) = IPriceFeed(IPriceFeed(ethFSM).priceSource()).getResultWithValidity();

        if(!either(hasValidValue, priceFeedValue == 0)){
            return false;
        }

        return (minKeeperPayoutValue <= mul(keeperPayout, priceFeedValue) / WAD);
    }



    function canSave(address safeHandler) external returns (bool){
        uint256 tokenAmountUsed = tokenAmountUsedToSave(safeHandler);

        if (tokenAmountUsed == MAX_UINT) {
            return false;
        }

        return collateralCover(safeHandler) >= add(tokenAmountUsed, keeperPayout);
    }


    function tokenAmountUsedToSave(address safeHandler) public returns (uint256 tokenAmountUsed){

        (uint256 depositedcollateralToken, uint256 safeDebt) =
          ISAFEEngine(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), safeHandler);

        (address ethFSM,,) = oracleRelayer.collateralTypes(collateralJoin.collateralType());
        
        (uint256 priceFeedValue, bool hasValidValue) = IPriceFeed(ethFSM).getResultWithValidity();

        // If the SAFE doesn't have debt or if the price feed is faulty, abort
        if (either(safeDebt == 0, either(priceFeedValue == 0, !hasValidValue))) {
            tokenAmountUsed = MAX_UINT;
            return tokenAmountUsed;
        }

        // Calculate the value of the debt equivalent to the value of the collateralToken that would need to be in the SAFE after it's saved
        uint256 targetCRatio = (desiredCollateralizationRatios[collateralJoin.collateralType()][safeHandler] == 0) ?
          defaultDesiredCollateralizationRatio : desiredCollateralizationRatios[collateralJoin.collateralType()][safeHandler];



        uint256 scaledDownDebtValue = mul(add(mul(oracleRelayer.redemptionPrice(), safeDebt) / RAY, ONE), targetCRatio) / HUNDRED;

        // Compute the amount of collateralToken the SAFE needs to get to the desired CRatio
        uint256 collateralTokenAmountNeeded = mul(scaledDownDebtValue, WAD) / priceFeedValue;

        // If the amount of collateralToken needed is lower than the amount that's currently in the SAFE, return 0
        if (collateralTokenAmountNeeded <= depositedcollateralToken) {
          return 0;
        } else {
          // Otherwise return the delta
          return sub(collateralTokenAmountNeeded, depositedcollateralToken);
        }

    }

    function setDesiredCollateralizationRatio(uint256 safeID, uint256 cRatio) external controlsSAFE(msg.sender, safeID) {
            uint256 scaledLiquidationRatio = oracleRelayer.liquidationCRatio(collateralJoin.collateralType()) / CRATIO_SCALE_DOWN;
            address safeHandler = safeManager.safes(safeID);

            // Check that the scaled liquidationCRatio is non null and that the proposed 
            // cRatio is greater than the liquidation one and smaller or equal to MAX_CRATIO
            require(scaledLiquidationRatio > 0, "GeneralTokenReserveSafeSaviour/invalid-scaled-liq-ratio");
            require(scaledLiquidationRatio < cRatio, "GeneralTokenReserveSafeSaviour/invalid-desired-cratio");
            require(cRatio <= MAX_CRATIO, "GeneralTokenReserveSafeSaviour/exceeds-max-cratio");

            // Store the new desired cRatio for the specific SAFE
            desiredCollateralizationRatios[collateralJoin.collateralType()][safeHandler] = cRatio;

            emit SetDesiredCollateralizationRatio(msg.sender, safeID, safeHandler, cRatio);
    }


    function deposit(uint256 safeID) external payable liquidationEngineApproved(address(this)) nonReentrant {
        
        require(msg.value>0, "Not enough ether");
        
        // Check that the SAFE exists inside GebSafeManager
        address safeHandler = safeManager.safes(safeID);
        require(safeHandler != address(0), "GeneralTokenReserveSafeSaviour/null-handler");

        // Check that the SAFE has debt
        (, uint256 safeDebt) =
          ISAFEEngine(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), safeHandler);
        require(safeDebt > 0, "GeneralTokenReserveSafeSaviour/safe-does-not-have-debt");


        uint256 preBalance = aToken.scaledBalanceOf(address(this));
        
        wethGatway.depositETH{value: msg.value}(address(POOL), address(this), uint16(0));
        
        uint256 minted = sub(aToken.scaledBalanceOf(address(this)), preBalance);
        
        aTokenPrincipalBalance[safeHandler] = add(aTokenPrincipalBalance[safeHandler], minted);
        
        emit Deposit(msg.sender, safeHandler, msg.value);

    }
    
    function withdraw(uint256 safeID, uint256 aTokenAmount) external controlsSAFE(msg.sender, safeID) nonReentrant{
        
        require(aTokenAmount > 0, "GeneralTokenReserveSafeSaviour/null-collateralToken-amount");

        address safeHandler = safeManager.safes(safeID);

        require(collateralCover(safeHandler) >= aTokenAmount, "Not enough aTokens");

        aToken.approve(address(wethGatway), aTokenAmount);
        
        uint256 preBalance = aToken.scaledBalanceOf(address(this));
        
        wethGatway.withdrawETH(address(POOL), aTokenAmount, msg.sender);
        
        uint256 usedTokens = sub(preBalance, aToken.scaledBalanceOf(address(this)));
        
        aTokenPrincipalBalance[safeHandler] = sub(aTokenPrincipalBalance[safeHandler], usedTokens);
        
        emit Withdraw(msg.sender, safeID, safeHandler, aTokenAmount);

    }

    // --- Functions to Implement ---
    function saveSAFE(address payable keeper, bytes32 collateralType, address safeHandler) virtual external returns (bool,uint256,uint256){
        
        require(address(liquidationEngine) == msg.sender, "GeneralTokenReserveSafeSaviour/caller-not-liquidation-engine");
        require(keeper != address(0), "GeneralTokenReserveSafeSaviour/null-keeper-address");

        if (both(both(collateralType == "", safeHandler == address(0)), keeper == address(liquidationEngine))) {
            return (true, uint(-1), uint(-1));
        }

        require(collateralType == collateralJoin.collateralType(), "GeneralTokenReserveSafeSaviour/invalid-collateral-type");

        // Check that the fiat value of the keeper payout is high enough
        require(keeperPayoutExceedsMinValue(), "GeneralTokenReserveSafeSaviour/small-keeper-payout-value");


        // Check that the amount of collateral locked in the safe is bigger than the keeper's payout
        (uint256 safeLockedCollateral,) =
          ISAFEEngine(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), safeHandler);
        require(safeLockedCollateral >= mul(keeperPayout, payoutToSAFESize), "GeneralTokenReserveSafeSaviour/tiny-safe");

        // Compute and check the validity of the amount of collateralToken used to save the SAFE
        uint256 tokenAmountUsed = tokenAmountUsedToSave(safeHandler);
        require(both(tokenAmountUsed != MAX_UINT, tokenAmountUsed != 0), "GeneralTokenReserveSafeSaviour/invalid-tokens-used-to-save");

        // Check that there's enough collateralToken added as to cover both the keeper's payout and the amount used to save the SAFE
        require( collateralCover(safeHandler) >= add(keeperPayout, tokenAmountUsed), "GeneralTokenReserveSafeSaviour/not-enough-cover-deposited");

        aToken.approve(address(wethGatway), add(keeperPayout, tokenAmountUsed));
        
        uint256 preBalance = aToken.scaledBalanceOf(address(this));
        
        wethGatway.withdrawETH(address(POOL), add(keeperPayout, tokenAmountUsed), address(this));
        
        uint256 usedTokens = sub(preBalance, aToken.scaledBalanceOf(address(this)));

        // Update the remaining cover
        aTokenPrincipalBalance[safeHandler] = sub(aTokenPrincipalBalance[safeHandler], usedTokens);        

        // create weth for eth
        collateralToken.deposit{value: tokenAmountUsed}();
        
        require(collateralToken.balanceOf(address(this)) >= tokenAmountUsed, "GeneralTokenReserveSafeSaviour/wrapping-eth-failed");

        // Mark the SAFE in the registry as just being saved
        saviourRegistry.markSave(collateralType, safeHandler);

        // Approve collateralToken to the collateral join contract
        collateralToken.approve(address(collateralJoin), tokenAmountUsed);

        // Join collateralToken in the system and add it in the saved SAFE
        collateralJoin.join(address(this), tokenAmountUsed);
        safeEngine.modifySAFECollateralization(
          collateralJoin.collateralType(),
          safeHandler,
          address(this),
          address(0),
          int256(tokenAmountUsed),
          int256(0)
        );
        
        // send the fee to keeper
        keeper.transfer(keeperPayout);

        emit SaveSAFE(keeper, collateralType, safeHandler, tokenAmountUsed);

        return (true, tokenAmountUsed, keeperPayout);

    }


}