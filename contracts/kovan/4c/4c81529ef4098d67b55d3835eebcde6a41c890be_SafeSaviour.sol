/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity ^0.6.2;

contract SafeMath {
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

interface ICEther{
    function mint() external payable returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function isCToken() external returns (bool);
}

interface IERC20{
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function deposit() external payable;
    function balanceOf(address) external returns (uint256); 
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
    function redemptionPrice() external view returns (uint256);
}

interface ICollateralJoin {
    function safeEngine() external view returns (address);
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

contract SafeSaviour is SafeMath, ReentrancyGuard {
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

    // --- Variables ---
    IERC20 public collateralToken;

    ILiquidationEngine   public liquidationEngine;
    IOracleRelayer       public oracleRelayer;
    IGebSafeManager      public safeManager;
    ISAFEEngine          public safeEngine;
    SAFESaviourRegistry  public saviourRegistry;
    ICollateralJoin      public collateralJoin;
    ICEther              public cToken;

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


    uint256 public totalCover = 0;
    // Desired CRatios for each SAFE after they're saved
    mapping(bytes32 => mapping(address => uint256)) public desiredCollateralizationRatios;


    mapping (address => uint256) collateralCover;

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
        address cTokenAddress
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

        liquidationEngine    = ILiquidationEngine(liquidationEngine_); // 0xf84e07E4CE57F8A4dEA5585B172a5a60B595821E
        collateralJoin       = ICollateralJoin(collateralJoin_); // 0xad4AB4Cb7b8aDC45Bf2873507fC8700f3dFB9Dd3
        oracleRelayer        = IOracleRelayer(oracleRelayer_); // 0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851
        safeEngine           = ISAFEEngine(safeEngine_); // 0x7f63fE955fFF8EA474d990f1Fc8979f2C650edbE
        safeManager          = IGebSafeManager(safeManager_); // 0x807C8eCb73d9c8203d2b1369E678098B9370F2EA
        saviourRegistry      = SAFESaviourRegistry(saviourRegistry_); // 0xB19bc2e13Bd6BAeeE8c0D8282387221D7f9b8833
        collateralToken      = IERC20(collateralJoin.collateral()); // 0xd0A1E359811322d97991E03f863a0C30C2cF029C
        cToken               = ICEther(cTokenAddress);

        uint256 scaledLiquidationRatio = oracleRelayer.liquidationCRatio(collateralJoin.collateralType()) / CRATIO_SCALE_DOWN;

        require(scaledLiquidationRatio > 0, "GeneralTokenReserveSafeSaviour/invalid-scaled-liq-ratio");
        require(both(defaultDesiredCollateralizationRatio_ > scaledLiquidationRatio, defaultDesiredCollateralizationRatio_ <= MAX_CRATIO), "GeneralTokenReserveSafeSaviour/invalid-default-desired-cratio");
        require(collateralJoin.decimals() == 18, "GeneralTokenReserveSafeSaviour/invalid-join-decimals");
        require(collateralJoin.contractEnabled() == 1, "GeneralTokenReserveSafeSaviour/join-disabled");
        require(cToken.isCToken(), "GeneralTokenReserveSafeSaviour/invalid-ctoken-address");

        defaultDesiredCollateralizationRatio = defaultDesiredCollateralizationRatio_;
    }


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
        require(collateralCover[safeHandler] >= add(keeperPayout, tokenAmountUsed), "GeneralTokenReserveSafeSaviour/not-enough-cover-deposited");

        require(cToken.redeemUnderlying(add(keeperPayout, tokenAmountUsed))==0, "GeneralTokenReserveSafeSaviour/cToken-not-redeemable");

        // Update the remaining cover
        collateralCover[safeHandler] = sub(collateralCover[safeHandler], add(keeperPayout, tokenAmountUsed));
        totalCover = sub(totalCover, add(keeperPayout, tokenAmountUsed));
        
        saviourRegistry.markSave(collateralType, safeHandler);

        collateralToken.deposit{value: tokenAmountUsed}();

        require(collateralToken.balanceOf(address(this)) >= tokenAmountUsed, "GeneralTokenReserveSafeSaviour/wrapping-eth-failed");

        // Approve collateralToken to the collateral join contract
        collateralToken.approve(address(collateralJoin), 0);
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
        
        keeper.transfer(keeperPayout);

        return (true, tokenAmountUsed, keeperPayout);

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



    function canSave(address safeHandler) virtual view external returns (bool){
        uint256 tokenAmountUsed = tokenAmountUsedToSave(safeHandler);

        if (tokenAmountUsed == MAX_UINT) {
            return false;
        }

        return (collateralCover[safeHandler] >= add(tokenAmountUsed, keeperPayout));
    }


    function tokenAmountUsedToSave(address safeHandler) view public returns (uint256 tokenAmountUsed){

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


    function deposit(uint256 safeID) payable external liquidationEngineApproved(address(this)) nonReentrant {

        require(msg.value > 0, "Incorrect Amount");

        // Check that the SAFE exists inside GebSafeManager
        address safeHandler = safeManager.safes(safeID);
        require(safeHandler != address(0), "GeneralTokenReserveSafeSaviour/null-handler");

        // Check that the SAFE has debt
        (, uint256 safeDebt) =
          ISAFEEngine(collateralJoin.safeEngine()).safes(collateralJoin.collateralType(), safeHandler);
        require(safeDebt > 0, "GeneralTokenReserveSafeSaviour/safe-does-not-have-debt");

        // Update the collateralToken balance used to cover the SAFE and transfer collateralToken to this contract
        collateralCover[safeHandler] = add(collateralCover[safeHandler], msg.value);
        totalCover = add(totalCover, msg.value);

        cToken.mint{value: msg.value}();

        emit Deposit(msg.sender, safeHandler, msg.value);
    }


    function withdraw(uint256 safeID, uint256 collateralTokenAmount) external controlsSAFE(msg.sender, safeID) nonReentrant{
        
        require(collateralTokenAmount > 0, "GeneralTokenReserveSafeSaviour/null-collateralToken-amount");

        address safeHandler = safeManager.safes(safeID);
        require(collateralCover[safeHandler] >= collateralTokenAmount, "GeneralTokenReserveSafeSaviour/not-enough-to-withdraw");
        
        collateralCover[safeHandler] = sub(collateralCover[safeHandler], collateralTokenAmount);

        require(cToken.redeemUnderlying(collateralTokenAmount) == 0, "GeneralTokenReserveSafeSaviour/not-redeemable-ctoken");

        address payable sender = payable(msg.sender);

        sender.transfer(collateralTokenAmount);

        totalCover = sub(totalCover, collateralTokenAmount);

        emit Withdraw(msg.sender, safeID, safeHandler, collateralTokenAmount);

    }

}