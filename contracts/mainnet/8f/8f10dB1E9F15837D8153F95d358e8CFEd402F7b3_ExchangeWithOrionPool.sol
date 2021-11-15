pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./utils/ReentrancyGuard.sol";
import "./libs/LibUnitConverter.sol";
import "./libs/LibValidator.sol";
import "./libs/MarginalFunctionality.sol";
import "./OrionVault.sol";
/**
 * @title Exchange
 * @dev Exchange contract for the Orion Protocol
 * @author @wafflemakr
 */

/*

  Overflow safety:
  We do not use SafeMath and control overflows by
  not accepting large ints on input.

  Balances inside contract are stored as int192.

  Allowed input amounts are int112 or uint112: it is enough for all
  practically used tokens: for instance if decimal unit is 1e18, int112
  allow to encode up to 2.5e15 decimal units.
  That way adding/subtracting any amount from balances won't overflow, since
  minimum number of operations to reach max int is practically infinite: ~1e24.

  Allowed prices are uint64. Note, that price is represented as
  price per 1e8 tokens. That means that amount*price always fit uint256,
  while amount*price/1e8 not only fit int192, but also can be added, subtracted
  without overflow checks: number of malicion operations to overflow ~1e13.
*/
contract Exchange is OrionVault, ReentrancyGuard {

    using LibValidator for LibValidator.Order;
    using SafeERC20 for IERC20;

    //  Flags for updateOrders
    //      All flags are explicit
    uint8 constant kSell = 0;
    uint8 constant kBuy = 1;    //  if 0 - then sell
    uint8 constant kCorrectMatcherFeeByOrderAmount = 2;

    // EVENTS
    event NewAssetTransaction(
        address indexed user,
        address indexed assetAddress,
        bool isDeposit,
        uint112 amount,
        uint64 timestamp
    );

    event NewTrade(
        address indexed buyer,
        address indexed seller,
        address baseAsset,
        address quoteAsset,
        uint64 filledPrice,
        uint192 filledAmount,
        uint192 amountQuote
    );

    // MAIN FUNCTIONS

    /**
     * @dev Since Exchange will work behind the Proxy contract it can not have constructor
     */
    function initialize() public payable initializer {
        OwnableUpgradeSafe.__Ownable_init();
    }

    /**
     * @dev set basic Exchange params
     * @param orionToken - base token address
     * @param priceOracleAddress - adress of PriceOracle contract
     * @param allowedMatcher - address which has authorization to match orders
     */
    function setBasicParams(address orionToken, address priceOracleAddress, address allowedMatcher) public onlyOwner {
      require((orionToken != address(0)) && (priceOracleAddress != address(0)), "E15");
      _orionToken = IERC20(orionToken);
      _oracleAddress = priceOracleAddress;
      _allowedMatcher = allowedMatcher;
    }


    /**
     * @dev set marginal settings
     * @param _collateralAssets - list of addresses of assets which may be used as collateral
     * @param _stakeRisk - risk coefficient for staken orion as uint8 (0=0, 255=1)
     * @param _liquidationPremium - premium for liquidator as uint8 (0=0, 255=1)
     * @param _priceOverdue - time after that price became outdated
     * @param _positionOverdue - time after that liabilities became overdue and may be liquidated
     */

    function updateMarginalSettings(address[] calldata _collateralAssets,
                                    uint8 _stakeRisk,
                                    uint8 _liquidationPremium,
                                    uint64 _priceOverdue,
                                    uint64 _positionOverdue) public onlyOwner {
      collateralAssets = _collateralAssets;
      stakeRisk = _stakeRisk;
      liquidationPremium = _liquidationPremium;
      priceOverdue = _priceOverdue;
      positionOverdue = _positionOverdue;
    }

    /**
     * @dev set risk coefficients for collateral assets
     * @param assets - list of assets
     * @param risks - list of risks as uint8 (0=0, 255=1)
     */
    function updateAssetRisks(address[] calldata assets, uint8[] calldata risks) public onlyOwner {
        for(uint256 i; i< assets.length; i++)
         assetRisks[assets[i]] = risks[i];
    }

    /**
     * @dev Deposit ERC20 tokens to the exchange contract
     * @dev User needs to approve token contract first
     * @param amount asset amount to deposit in its base unit
     */
    function depositAsset(address assetAddress, uint112 amount) external {
        //require(asset.transferFrom(msg.sender, address(this), uint256(amount)), "E6");
        IERC20(assetAddress).safeTransferFrom(msg.sender, address(this), uint256(amount));
        generalDeposit(assetAddress,amount);
    }

    /**
     * @notice Deposit ETH to the exchange contract
     * @dev deposit event will be emitted with the amount in decimal format (10^8)
     * @dev balance will be stored in decimal format too
     */
    function deposit() external payable {
        generalDeposit(address(0), uint112(msg.value));
    }

    /**
     * @dev internal implementation of deposits
     */
    function generalDeposit(address assetAddress, uint112 amount) internal {
        address user = msg.sender;
        bool wasLiability = assetBalances[user][assetAddress]<0;
        int112 safeAmountDecimal = LibUnitConverter.baseUnitToDecimal(
            assetAddress,
            amount
        );
        assetBalances[user][assetAddress] += safeAmountDecimal;
        if(amount>0)
          emit NewAssetTransaction(user, assetAddress, true, uint112(safeAmountDecimal), uint64(block.timestamp));
        if(wasLiability)
          MarginalFunctionality.updateLiability(user, assetAddress, liabilities, uint112(safeAmountDecimal), assetBalances[user][assetAddress]);

    }
    /**
     * @dev Withdrawal of remaining funds from the contract back to the address
     * @param assetAddress address of the asset to withdraw
     * @param amount asset amount to withdraw in its base unit
     */
    function withdraw(address assetAddress, uint112 amount)
        external
        nonReentrant
    {
        int112 safeAmountDecimal = LibUnitConverter.baseUnitToDecimal(
            assetAddress,
            amount
        );

        address user = msg.sender;

        assetBalances[user][assetAddress] -= safeAmountDecimal;

        require(assetBalances[user][assetAddress]>=0, "E1w1"); //TODO
        require(checkPosition(user), "E1w2"); //TODO

        uint256 _amount = uint256(amount);
        if(assetAddress == address(0)) {
          (bool success, ) = user.call{value:_amount}("");
          require(success, "E6w");
        } else {
          IERC20(assetAddress).safeTransfer(user, _amount);
        }


        emit NewAssetTransaction(user, assetAddress, false, uint112(safeAmountDecimal), uint64(block.timestamp));
    }


    /**
     * @dev Get asset balance for a specific address
     * @param assetAddress address of the asset to query
     * @param user user address to query
     */
    function getBalance(address assetAddress, address user)
        public
        view
        returns (int192)
    {
        return assetBalances[user][assetAddress];
    }


    /**
     * @dev Batch query of asset balances for a user
     * @param assetsAddresses array of addresses of the assets to query
     * @param user user address to query
     */
    function getBalances(address[] memory assetsAddresses, address user)
        public
        view
        returns (int192[] memory balances)
    {
        balances = new int192[](assetsAddresses.length);
        for (uint256 i; i < assetsAddresses.length; i++) {
            balances[i] = assetBalances[user][assetsAddresses[i]];
        }
    }

    /**
     * @dev Batch query of asset liabilities for a user
     * @param user user address to query
     */
    function getLiabilities(address user)
        public
        view
        returns (MarginalFunctionality.Liability[] memory liabilitiesArray)
    {
        return liabilities[user];
    }

    /**
     * @dev Return list of assets which can be used for collateral
     */
    function getCollateralAssets() public view returns (address[] memory) {
        return collateralAssets;
    }

    /**
     * @dev get hash for an order
     * @dev we use order hash as order id to prevent double matching of the same order
     */
    function getOrderHash(LibValidator.Order memory order) public pure returns (bytes32){
      return order.getTypeValueHash();
    }


    /**
     * @dev get filled amounts for a specific order
     */
    function getFilledAmounts(bytes32 orderHash, LibValidator.Order memory order)
        public
        view
        returns (int192 totalFilled, int192 totalFeesPaid)
    {
        totalFilled = int192(filledAmounts[orderHash]); //It is safe to convert here: filledAmounts is result of ui112 additions
        totalFeesPaid = int192(uint256(order.matcherFee)*uint112(totalFilled)/order.amount); //matcherFee is u64; safe multiplication here
    }


    /**
     * @notice Settle a trade with two orders, filled price and amount
     * @dev 2 orders are submitted, it is necessary to match them:
        check conditions in orders for compliance filledPrice, filledAmountbuyOrderHash
        change balances on the contract respectively with buyer, seller, matcbuyOrderHashher
     * @param buyOrder structure of buy side orderbuyOrderHash
     * @param sellOrder structure of sell side order
     * @param filledPrice price at which the order was settled
     * @param filledAmount amount settled between orders
     */
    function fillOrders(
        LibValidator.Order memory buyOrder,
        LibValidator.Order memory sellOrder,
        uint64 filledPrice,
        uint112 filledAmount
    ) public nonReentrant {
        // --- VARIABLES --- //
        // Amount of quote asset
        uint256 _amountQuote = uint256(filledAmount)*filledPrice/(10**8);
        require(_amountQuote<2**112-1, "E12G");
        uint112 amountQuote = uint112(_amountQuote);

        // Order Hashes
        bytes32 buyOrderHash = buyOrder.getTypeValueHash();
        bytes32 sellOrderHash = sellOrder.getTypeValueHash();

        // --- VALIDATIONS --- //

        // Validate signatures using eth typed sign V1
        require(
            LibValidator.checkOrdersInfo(
                buyOrder,
                sellOrder,
                msg.sender,
                filledAmount,
                filledPrice,
                block.timestamp,
                _allowedMatcher
            ),
            "E3G"
        );


        // --- UPDATES --- //

        //updateFilledAmount
        filledAmounts[buyOrderHash] += filledAmount; //it is safe to add ui112 to each other to get i192
        filledAmounts[sellOrderHash] += filledAmount;
        require(filledAmounts[buyOrderHash] <= buyOrder.amount, "E12B");
        require(filledAmounts[sellOrderHash] <= sellOrder.amount, "E12S");


        // Update User's balances
        updateOrderBalance(buyOrder, filledAmount, amountQuote, kBuy | kCorrectMatcherFeeByOrderAmount);
        updateOrderBalance(sellOrder, filledAmount, amountQuote, kSell | kCorrectMatcherFeeByOrderAmount);
        require(checkPosition(buyOrder.senderAddress), "Incorrect margin position for buyer");
        require(checkPosition(sellOrder.senderAddress), "Incorrect margin position for seller");


        emit NewTrade(
            buyOrder.senderAddress,
            sellOrder.senderAddress,
            buyOrder.baseAsset,
            buyOrder.quoteAsset,
            filledPrice,
            filledAmount,
            amountQuote
        );
    }

    /**
     * @dev wrapper for LibValidator methods, may be deleted.
     */
    function validateOrder(LibValidator.Order memory order)
        public
        pure
        returns (bool isValid)
    {
        isValid = order.isPersonalSign ? LibValidator.validatePersonal(order) : LibValidator.validateV3(order);
    }

    /**
     *  @notice update user balances and send matcher fee
     *  @param flags uint8, see constants for possible flags of order
     */
    function updateOrderBalance(
        LibValidator.Order memory order,
        uint112 filledAmount,
        uint112 amountQuote,
        uint8 flags
    ) internal {
        address user = order.senderAddress;
        bool isBuyer = ((flags & kBuy) != 0);

        int192 temp; // this variable will be used for temporary variable storage (optimization purpose)

        {

           //  Stack too deep
            bool isCorrectFee = ((flags & kCorrectMatcherFeeByOrderAmount) != 0);

            if(isCorrectFee)
            {
                // matcherFee: u64, filledAmount u128 => matcherFee*filledAmount fit u256
                // result matcherFee fit u64
                order.matcherFee = uint64(uint256(order.matcherFee)*filledAmount/order.amount); //rewrite in memory only
            }
        }

        if(filledAmount > 0)
        {

            if(!isBuyer)
              (filledAmount, amountQuote) = (amountQuote, filledAmount);

            (address firstAsset, address secondAsset) = isBuyer?
                                                         (order.quoteAsset, order.baseAsset):
                                                         (order.baseAsset, order.quoteAsset);
            int192 firstBalance = assetBalances[user][firstAsset];
            int192 secondBalance = assetBalances[user][secondAsset];
            //  'Stack too deep' correction
            //  WAS:
            //  bool firstInLiabilities = firstBalance<0;
            //  bool secondInLiabilities  = secondBalance<0;
            //  NOW:

            //  ENDFIX

            temp = assetBalances[user][firstAsset] - amountQuote;
            assetBalances[user][firstAsset] = temp;
            assetBalances[user][secondAsset] += filledAmount;
            //  'Stack too deep' correction
            //  WAS:
            //  if(!firstInLiabilities && (temp<0)){
            //  NOW:
            if(!(firstBalance<0) && (temp<0)){
            //  ENDFIX
              setLiability(user, firstAsset, temp);
            }
            //  'Stack too deep' correction
            //  WAS:
            //  if(secondInLiabilities) {
            //  NOW:
            if(secondBalance<0) {
            //  ENDFIX
              MarginalFunctionality.updateLiability(user, secondAsset, liabilities, filledAmount, assetBalances[user][secondAsset]);
            }
        }

        // User pay for fees
        bool feeAssetInLiabilities  = assetBalances[user][order.matcherFeeAsset]<0;
        temp = assetBalances[user][order.matcherFeeAsset] - order.matcherFee;
        assetBalances[user][order.matcherFeeAsset] = temp;
        if(!feeAssetInLiabilities && (temp<0)) {
            setLiability(user, order.matcherFeeAsset, temp);
        }
        assetBalances[order.matcherAddress][order.matcherFeeAsset] += order.matcherFee;
    }

    /**
     * @notice users can cancel an order
     * @dev write an orderHash in the contract so that such an order cannot be filled (executed)
     */
    /* Unused for now
    function cancelOrder(LibValidator.Order memory order) public {
        require(order.validateV3(), "E2");
        require(msg.sender == order.senderAddress, "Not owner");

        bytes32 orderHash = order.getTypeValueHash();

        require(!isOrderCancelled(orderHash), "E4");

        (
            int192 totalFilled, //uint totalFeesPaid

        ) = getFilledAmounts(orderHash);

        if (totalFilled > 0)
            orderStatus[orderHash] = Status.PARTIALLY_CANCELLED;
        else orderStatus[orderHash] = Status.CANCELLED;

        emit OrderUpdate(orderHash, msg.sender, orderStatus[orderHash]);

        assert(
            orderStatus[orderHash] == Status.PARTIALLY_CANCELLED ||
                orderStatus[orderHash] == Status.CANCELLED
        );
    }
    */

    /**
     * @dev check user marginal position (compare assets and liabilities)
     * @return isPositive - boolean whether liabilities are covered by collateral or not
     */
    function checkPosition(address user) public view returns (bool) {
        if(liabilities[user].length == 0)
          return true;
        return calcPosition(user).state == MarginalFunctionality.PositionState.POSITIVE;
    }

    /**
     * @dev internal methods which collect all variables used my MarginalFunctionality to one structure
     * @param user user address to query
     * @return UsedConstants - MarginalFunctionality.UsedConstants structure
     */
    function getConstants(address user)
             internal
             view
             returns (MarginalFunctionality.UsedConstants memory) {
       return MarginalFunctionality.UsedConstants(user,
                                                  _oracleAddress,
                                                  address(this),
                                                  address(_orionToken),
                                                  positionOverdue,
                                                  priceOverdue,
                                                  stakeRisk,
                                                  liquidationPremium);
    }

    /**
     * @dev calc user marginal position (compare assets and liabilities)
     * @param user user address to query
     * @return position - MarginalFunctionality.Position structure
     */
    function calcPosition(address user) public view returns (MarginalFunctionality.Position memory) {
        MarginalFunctionality.UsedConstants memory constants =
          getConstants(user);
        return MarginalFunctionality.calcPosition(collateralAssets,
                                           liabilities,
                                           assetBalances,
                                           assetRisks,
                                           constants);

    }

    /**
     * @dev method to cover some of overdue broker liabilities and get ORN in exchange
            same as liquidation or margin call
     * @param broker - broker which will be liquidated
     * @param redeemedAsset - asset, liability of which will be covered
     * @param amount - amount of covered asset
     */
    function partiallyLiquidate(address broker, address redeemedAsset, uint112 amount) public {
        MarginalFunctionality.UsedConstants memory constants =
          getConstants(broker);
        MarginalFunctionality.partiallyLiquidate(collateralAssets,
                                           liabilities,
                                           assetBalances,
                                           assetRisks,
                                           constants,
                                           redeemedAsset,
                                           amount);
    }

    /**
     * @dev method to add liability
     * @param user - user which created liability
     * @param asset - liability asset
     * @param balance - current negative balance
     */
    function setLiability(address user, address asset, int192 balance) internal {
        liabilities[user].push(
          MarginalFunctionality.Liability({
                                             asset: asset,
                                             timestamp: uint64(block.timestamp),
                                             outstandingAmount: uint192(-balance)})
        );
    }

    /**
     * @dev method to update liability forcing removing any liabilities if balance > 0
     * @param assetAddress - liability asset
     */
    function forceUpdateLiability(address assetAddress) public {
        address user = msg.sender;
        MarginalFunctionality.updateLiability(user, assetAddress, liabilities, 0, assetBalances[user][assetAddress]);
    }


    /**
     *  @dev  revert on fallback function
     */
    fallback() external {
        revert("E6");
    }

    /* Error Codes

        E1: Insufficient Balance, flavor S - stake
        E2: Invalid Signature, flavor B,S - buyer, seller
        E3: Invalid Order Info, flavor G - general, M - wrong matcher, M2 unauthorized matcher, As - asset mismatch, AmB/AmS - amount mismatch (buyer,seller), PrB/PrS - price mismatch(buyer,seller), D - direction mismatch,
        E4: Order expired, flavor B,S - buyer,seller
        E5: Contract not active,
        E6: Transfer error
        E7: Incorrect state prior to liquidation
        E8: Liquidator doesn't satisfy requirements
        E9: Data for liquidation handling is outdated
        E10: Incorrect state after liquidation
        E11: Amount overflow
        E12: Incorrect filled amount, flavor G,B,S: general(overflow), buyer order overflow, seller order overflow
        E14: Authorization error, sfs - seizeFromStake
        E15: Wrong passed params
    */

}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/MarginalFunctionality.sol";

// Base contract which contain state variable of the first version of Exchange
// deployed on mainnet. Changes of the state variables should be introduced 
// not in that contract but down the inheritance chain, to allow safe upgrades
// More info about safe upgrades here: 
// https://blog.openzeppelin.com/the-state-of-smart-contract-upgrades/#upgrade-patterns

contract ExchangeStorage {

    //order -> filledAmount
    mapping(bytes32 => uint192) public filledAmounts;


    // Get user balance by address and asset address
    mapping(address => mapping(address => int192)) internal assetBalances;
    // List of assets with negative balance for each user
    mapping(address => MarginalFunctionality.Liability[]) public liabilities;
    // List of assets which can be used as collateral and risk coefficients for them
    address[] internal collateralAssets;
    mapping(address => uint8) public assetRisks;
    // Risk coefficient for locked ORN
    uint8 public stakeRisk;
    // Liquidation premium
    uint8 public liquidationPremium;
    // Delays after which price and position become outdated
    uint64 public priceOverdue;
    uint64 public positionOverdue;

    // Base orion tokens (can be locked on stake)
    IERC20 _orionToken;
    // Address of price oracle contract
    address _oracleAddress;
    // Address from which matching of orders is allowed
    address _allowedMatcher;


}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./Exchange.sol";
import "./utils/orionpool/periphery/interfaces/IOrionPoolV2Router02Ext.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract ExchangeWithOrionPool is Exchange {

    using SafeERC20 for IERC20;

    address public _orionpoolRouter;
    mapping (address => bool) orionpoolAllowances;

    modifier initialized {
        require(_orionpoolRouter!=address(0), "_orionpoolRouter is not set");
        require(address(_orionToken)!=address(0), "_orionToken is not set");
        require(_oracleAddress!=address(0), "_oracleAddress is not set");
        require(_allowedMatcher!=address(0), "_allowedMatcher is not set");
        _;
    }

    function _safeIncreaseAllowance(address token) internal
    {
        if(token != address(0) && !orionpoolAllowances[token])
        {
            IERC20(token).safeIncreaseAllowance(_orionpoolRouter, 2**256-1);
            orionpoolAllowances[token] = true;
        }
    }

    /**
     * @dev set basic Exchange params
     * @param orionToken - base token address
     * @param priceOracleAddress - adress of PriceOracle contract
     * @param allowedMatcher - address which has authorization to match orders
     * @param orionpoolRouter - OrionPool Router address for changes through orionpool
     */
    function setBasicParams(address orionToken,
                            address priceOracleAddress,
                            address allowedMatcher,
                            address orionpoolRouter)
             public onlyOwner
             {
      _orionToken = IERC20(orionToken);
      _oracleAddress = priceOracleAddress;
      _allowedMatcher = allowedMatcher;
      _orionpoolRouter = orionpoolRouter;
    }

    //  Important catch-all afunction that should only accept ethereum and don't allow do something with it
    //      We accept ETH there only from out router.
    //      If router sends some ETH to us - it's just swap completed, and we don't need to do smth
    //      with ETH received - amount of ETH will be handled by ........... blah blah
    receive() external payable
    {
        require(msg.sender == _orionpoolRouter, "NPF");
    }

    /**
     * @notice (partially) settle buy order with OrionPool as counterparty
     * @dev order and orionpool path are submitted, it is necessary to match them:
        check conditions in order for compliance filledPrice and filledAmount
        change tokens via OrionPool
        check that final price after exchange not worse than specified in order
        change balances on the contract respectively
     * @param order structure of buy side orderbuyOrderHash
     * @param filledAmount amount of purchaseable token
     * @param path array of assets addresses (each consequent asset pair is change pair)
     */

    //  Just to avoid stack too deep error;
    struct OrderExecutionData
    {
        uint64      filledPrice;
        uint112     amountQuote;
        uint        tx_value;
    }

    function fillThroughOrionPool(
            LibValidator.Order memory order,
            uint112 filledAmount,
            uint64 blockchainFee,
            address[] calldata path
        ) public nonReentrant initialized {
        // Amount of quote asset
        uint256 _amountQuote = uint256(filledAmount)* order.price/(10**8);
        OrderExecutionData memory exec_data;

        if(order.buySide==1){ /* NOTE BUY ORDER ************************************************************/
            (int112 amountQuoteBaseUnits, int112 filledAmountBaseUnits) =
            (
                LibUnitConverter.decimalToBaseUnit(path[0], _amountQuote),
                LibUnitConverter.decimalToBaseUnit(path[path.length-1], filledAmount)
            );

            //  TODO: check
            //  require(IERC20(order.quoteAsset).balanceOf(address(this)) >= uint(amountQuoteBaseUnits), "NEGT");

            LibValidator.checkOrderSingleMatch(order, msg.sender, _allowedMatcher, filledAmount, block.timestamp, path, 1);

            //  Change fee only after order validation
            if(blockchainFee < order.matcherFee)
                order.matcherFee = blockchainFee;

            _safeIncreaseAllowance(order.quoteAsset);
            if(order.quoteAsset == address(0))
                exec_data.tx_value = uint(amountQuoteBaseUnits);

            try IOrionPoolV2Router02Ext(_orionpoolRouter).swapTokensForExactTokensAutoRoute{value: exec_data.tx_value}(
                                                        uint(filledAmountBaseUnits),
                                                        uint(amountQuoteBaseUnits),
                                                        path,
                                                        address(this)) //  order.expiration/1000
            returns(uint[] memory amounts)
            {
                exec_data.amountQuote = uint112(LibUnitConverter.baseUnitToDecimal(
                        path[0],
                        amounts[0]
                    ));

                //require(_amountQuote<2**112-1, "E12G"); //TODO
                uint256 _filledPrice = exec_data.amountQuote*(10**8)/filledAmount;
                require(_filledPrice<= order.price, "EX"); //TODO
                exec_data.filledPrice = uint64(_filledPrice); // since _filledPrice<buyOrder.price it fits uint64
                //uint112 amountQuote = uint112(_amountQuote);
            }
            catch(bytes memory)
            {
                filledAmount = 0;
                exec_data.filledPrice = order.price;
            }

            // Update User's balances
            updateOrderBalance(order, filledAmount, exec_data.amountQuote, kBuy);
            require(checkPosition(order.senderAddress), "Incorrect margin position for buyer");


        }else{ /* NOTE: SELL ORDER **************************************************************************/
            LibValidator.checkOrderSingleMatch(order, msg.sender, _allowedMatcher, filledAmount, block.timestamp, path, 0);

            //  Change fee only after order validation
            if(blockchainFee < order.matcherFee)
                order.matcherFee = blockchainFee;

            (int112 amountQuoteBaseUnits, int112 filledAmountBaseUnits) =
            (
                LibUnitConverter.decimalToBaseUnit(path[0], filledAmount),
                LibUnitConverter.decimalToBaseUnit(path[path.length-1], _amountQuote)
            );

            _safeIncreaseAllowance(order.baseAsset);
            if(order.baseAsset == address(0))
                exec_data.tx_value = uint(amountQuoteBaseUnits);

            try IOrionPoolV2Router02Ext(_orionpoolRouter).swapExactTokensForTokensAutoRoute{value: exec_data.tx_value}(
                uint(amountQuoteBaseUnits),
                uint(filledAmountBaseUnits),
                path,
                address(this))  //    order.expiration/1000)
            returns (uint[] memory amounts)
            {
                exec_data.amountQuote = uint112(LibUnitConverter.baseUnitToDecimal(
                        path[path.length-1],
                        amounts[path.length-1]
                    ));
                //require(_amountQuote<2**112-1, "E12G"); //TODO
                uint256 _filledPrice = exec_data.amountQuote*(10**8)/filledAmount;
                require(_filledPrice>= order.price, "EX"); //TODO
                exec_data.filledPrice = uint64(_filledPrice); // since _filledPrice<buyOrder.price it fits uint64
                //uint112 amountQuote = uint112(_amountQuote);
            }
            catch(bytes memory)
            {
                filledAmount = 0;
                exec_data.filledPrice = order.price;
            }

            // Update User's balances
            updateOrderBalance(order, filledAmount, exec_data.amountQuote, kSell);
            require(checkPosition(order.senderAddress), "Incorrect margin position for seller");
        }

        {   //  STack too deep workaround
            bytes32 orderHash = LibValidator.getTypeValueHash(order);
            uint192 total_amount = filledAmounts[orderHash];
            //  require(filledAmounts[orderHash]==0, "filledAmount already has some value"); //  Old way
            total_amount += filledAmount; //it is safe to add ui112 to each other to get i192
            require(total_amount >= filledAmount, "E12B_0");
            require(total_amount <= order.amount, "E12B");
            filledAmounts[orderHash] = total_amount;
        }

        emit NewTrade(
            order.senderAddress,
            address(1), //TODO //sellOrder.senderAddress,
            order.baseAsset,
            order.quoteAsset,
            exec_data.filledPrice,
            filledAmount,
            exec_data.amountQuote
        );

    }

    /*
        BUY LIMIT ORN/USDT
         path[0] = USDT
         path[1] = ORN
         is_exact_spend = false;

        SELL LIMIT ORN/USDT
         path[0] = ORN
         path[1] = USDT
         is_exact_spend = true;
    */

    event NewSwapOrionPool
    (
        address user,
        address asset_spend,
        address asset_receive,
        int112 amount_spent,
        int112 amount_received
    );

    function swapThroughOrionPool(
        uint112     amount_spend,
        uint112     amount_receive,
        address[] calldata   path,
        bool        is_exact_spend
    ) public nonReentrant initialized
    {
        (int112 amount_spend_base_units, int112 amount_receive_base_units) =
        (
            LibUnitConverter.decimalToBaseUnit(path[0], amount_spend),
            LibUnitConverter.decimalToBaseUnit(path[path.length-1], amount_receive)
        );

        //  Checks
        require(getBalance(path[0], msg.sender) >= amount_spend, "NEGS1");

        _safeIncreaseAllowance(path[0]);

        uint256 tx_value = path[0] == address(0) ? uint(amount_spend_base_units) : 0;

        uint[] memory amounts = is_exact_spend ?
        IOrionPoolV2Router02Ext(_orionpoolRouter).swapExactTokensForTokensAutoRoute
        {value: tx_value}
        (
            uint(amount_spend_base_units),
            uint(amount_receive_base_units),
            path,
            address(this)
        )
        :
        IOrionPoolV2Router02Ext(_orionpoolRouter).swapTokensForExactTokensAutoRoute
        {value: tx_value}
        (
            uint(amount_receive_base_units),
            uint(amount_spend_base_units),
            path,
            address(this)
        );

        //  Anyway user gave amounts[0] and received amounts[len-1]
        int112 amount_actually_spent = LibUnitConverter.baseUnitToDecimal(path[0], amounts[0]);
        int112 amount_actually_received = LibUnitConverter.baseUnitToDecimal(path[path.length-1], amounts[path.length-1]);

        int192 balance_in_spent = assetBalances[msg.sender][path[0]];
        require(amount_actually_spent >= 0 && balance_in_spent >= amount_actually_spent, "NEGS2_1");
        balance_in_spent -= amount_actually_spent;
        assetBalances[msg.sender][path[0]] = balance_in_spent;
        require(checkPosition(msg.sender), "NEGS2_2");

        address receiving_token = path[path.length - 1];
        int192 balance_in_received = assetBalances[msg.sender][receiving_token];
        bool is_need_update_liability = (balance_in_received < 0);
        balance_in_received += amount_actually_received;
        require(amount_actually_received >= 0 /* && balance_in_received >= amount_actually_received*/ , "NEGS2_3");
        assetBalances[msg.sender][receiving_token] = balance_in_received;

        if(is_need_update_liability)
            MarginalFunctionality.updateLiability(
                msg.sender,
                receiving_token,
                liabilities,
                uint112(amount_actually_received),
                assetBalances[msg.sender][receiving_token]
            );

        //  TODO: remove
        emit NewSwapOrionPool
        (
            msg.sender,
            path[0],
            receiving_token,
            amount_actually_spent,
            amount_actually_received
        );
    }

    function increaseAllowance(address token) public
    {
        IERC20(token).safeIncreaseAllowance(_orionpoolRouter, 2**256-1);
        orionpoolAllowances[token] = true;
    }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import "./ExchangeStorage.sol";

abstract contract OrionVault is ExchangeStorage, OwnableUpgradeSafe {

    enum StakePhase{ NOTSTAKED, LOCKED, RELEASING, READYTORELEASE, FROZEN }


    struct Stake {
      uint64 amount; // 100m ORN in circulation fits uint64
      StakePhase phase;
      uint64 lastActionTimestamp;
    }

    uint64 constant releasingDuration = 3600*24;
    mapping(address => Stake) private stakingData;


    /**
     * @dev Returns Stake with on-fly calculated StakePhase
     * @dev Note StakePhase may depend on time for some phases.
     * @param user address
     */
    function getStake(address user) public view returns (Stake memory stake){
        stake = stakingData[user];
        if(stake.phase == StakePhase.RELEASING && (block.timestamp - stake.lastActionTimestamp) > releasingDuration) {
          stake.phase = StakePhase.READYTORELEASE;
        }
    }

    /**
     * @dev Returns stake balance
     * @dev Note, this balance may be already unlocked
     * @param user address
     */
    function getStakeBalance(address user) public view returns (uint256) {
        return getStake(user).amount;
    }

    /**
     * @dev Returns stake phase
     * @param user address
     */
    function getStakePhase(address user) public view returns (StakePhase) {
        return getStake(user).phase;
    }

    /**
     * @dev Returns locked or frozen stake balance only
     * @param user address
     */
    function getLockedStakeBalance(address user) public view returns (uint256) {
      Stake memory stake = getStake(user);
      if(stake.phase == StakePhase.LOCKED || stake.phase == StakePhase.FROZEN)
        return stake.amount;
      return 0;
    }



    /**
     * @dev Change stake phase to frozen, blocking release
     * @param user address
     */
    function postponeStakeRelease(address user) external onlyOwner{
        Stake storage stake = stakingData[user];
        stake.phase = StakePhase.FROZEN;
    }

    /**
     * @dev Change stake phase to READYTORELEASE
     * @param user address
     */
    function allowStakeRelease(address user) external onlyOwner {
        Stake storage stake = stakingData[user];
        stake.phase = StakePhase.READYTORELEASE;
    }


    /**
     * @dev Request stake unlock for msg.sender
     * @dev If stake phase is LOCKED, that changes phase to RELEASING
     * @dev If stake phase is READYTORELEASE, that withdraws stake to balance
     * @dev Note, both unlock and withdraw is impossible if user has liabilities
     */
    function requestReleaseStake() public {
        address user = _msgSender();
        Stake memory current = getStake(user);
        require(liabilities[user].length == 0, "Can not release stake: user has liabilities");
        Stake storage stake = stakingData[_msgSender()];
        if(current.phase == StakePhase.READYTORELEASE) {
          assetBalances[user][address(_orionToken)] += stake.amount;
          stake.amount = 0;
          stake.phase = StakePhase.NOTSTAKED;
        } else if (current.phase == StakePhase.LOCKED) {
          stake.phase = StakePhase.RELEASING;
          stake.lastActionTimestamp = uint64(block.timestamp);
        } else {
          revert("Can not release funds from this phase");
        }
    }

    /**
     * @dev Lock some orions from exchange balance sheet
     * @param amount orions in 1e-8 units to stake
     */
    function lockStake(uint64 amount) public {
        address user = _msgSender();
        require(assetBalances[user][address(_orionToken)]>amount, "E1S");
        Stake storage stake = stakingData[user];

        assetBalances[user][address(_orionToken)] -= amount;
        stake.amount += amount;

        if(stake.phase != StakePhase.FROZEN) {
          stake.phase = StakePhase.LOCKED; //what is frozen should stay frozen
        }
        stake.lastActionTimestamp = uint64(block.timestamp);
    }

    /**
     * @dev send some orion from user's stake to receiver balance
     * @dev This function is used during liquidations, to reimburse liquidator
     *      with orions from stake for decreasing liabilities.
     * @dev Note, this function is used by MarginalFunctionality library, thus
     *      it can not be made private, but at the same time this function
     *      can only be called by contract itself. That way msg.sender check
     *      is critical.
     * @param user - user whose stake will be decreased
     * @param receiver - user which get orions
     * @param amount - amount of withdrawn tokens
     */
    function seizeFromStake(address user, address receiver, uint64 amount) public {
        require(msg.sender == address(this), "E14");
        Stake storage stake = stakingData[user];
        require(stake.amount >= amount, "UX"); //TODO
        stake.amount -= amount;
        assetBalances[receiver][address(_orionToken)] += amount;
    }

}

pragma solidity 0.7.4;

interface OrionVaultInterface {

    /**
     * @dev Returns locked or frozen stake balance only
     * @param user address
     */
    function getLockedStakeBalance(address user) external view returns (uint64);

    /**
     * @dev send some orion from user's stake to receiver balance
     * @dev This function is used during liquidations, to reimburse liquidator
     *      with orions from stake for decreasing liabilities.
     * @param user - user whose stake will be decreased
     * @param receiver - user which get orions
     * @param amount - amount of withdrawn tokens
     */
    function seizeFromStake(address user, address receiver, uint64 amount) external;

}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface PriceOracleDataTypes {
    struct PriceDataOut {
        uint64 price;
        uint64 timestamp;
    }

}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./PriceOracleDataTypes.sol";

interface PriceOracleInterface is PriceOracleDataTypes {
    function assetPrices(address) external view returns (PriceDataOut memory);
    function givePrices(address[] calldata assetAddresses) external view returns (PriceDataOut[] memory);
}

pragma solidity 0.7.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';


library LibUnitConverter {

    using SafeMath for uint;

    /**
        @notice convert asset amount from8 decimals (10^8) to its base unit
     */
    function decimalToBaseUnit(address assetAddress, uint amount) public view returns(int112 baseValue){
        uint256 result;

        if(assetAddress == address(0)){
            result =  amount.mul(1 ether).div(10**8); // 18 decimals
        } else {

          ERC20 asset = ERC20(assetAddress);
          uint decimals = asset.decimals();

          result = amount.mul(10**decimals).div(10**8);
        }

        require(result < uint256(type(int112).max), "LibUnitConverter: Too big value");
        baseValue = int112(result);
    }

    /**
        @notice convert asset amount from its base unit to 8 decimals (10^8)
     */
    function baseUnitToDecimal(address assetAddress, uint amount) public view returns(int112 decimalValue){
        uint256 result;

        if(assetAddress == address(0)){
            result = amount.mul(10**8).div(1 ether);
        } else {

            ERC20 asset = ERC20(assetAddress);
            uint decimals = asset.decimals();

            result = amount.mul(10**8).div(10**decimals);
        }
        require(result < uint256(type(int112).max), "LibUnitConverter: Too big value");
        decimalValue = int112(result);
    }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";

library LibValidator {

    using ECDSA for bytes32;

    string public constant DOMAIN_NAME = "Orion Exchange";
    string public constant DOMAIN_VERSION = "1";
    uint256 public constant CHAIN_ID = 1;
    bytes32
        public constant DOMAIN_SALT = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a557;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(
        abi.encodePacked(
            "EIP712Domain(string name,string version,uint256 chainId,bytes32 salt)"
        )
    );
    bytes32 public constant ORDER_TYPEHASH = keccak256(
        abi.encodePacked(
            "Order(address senderAddress,address matcherAddress,address baseAsset,address quoteAsset,address matcherFeeAsset,uint64 amount,uint64 price,uint64 matcherFee,uint64 nonce,uint64 expiration,uint8 buySide)"
        )
    );

    bytes32 public constant DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(DOMAIN_NAME)),
            keccak256(bytes(DOMAIN_VERSION)),
            CHAIN_ID,
            DOMAIN_SALT
        )
    );

    struct Order {
        address senderAddress;
        address matcherAddress;
        address baseAsset;
        address quoteAsset;
        address matcherFeeAsset;
        uint64 amount;
        uint64 price;
        uint64 matcherFee;
        uint64 nonce;
        uint64 expiration;
        uint8 buySide; // buy or sell
        bool isPersonalSign;
        bytes signature;
    }

    /**
     * @dev validate order signature
     */
    function validateV3(Order memory order) public pure returns (bool) {
        bytes32 domainSeparator = DOMAIN_SEPARATOR;

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                getTypeValueHash(order)
            )
        );

        return digest.recover(order.signature) == order.senderAddress;
    }

    /**
     * @return hash order
     */
    function getTypeValueHash(Order memory _order)
        internal
        pure
        returns (bytes32)
    {
        bytes32 orderTypeHash = ORDER_TYPEHASH;

        return
            keccak256(
                abi.encode(
                    orderTypeHash,
                    _order.senderAddress,
                    _order.matcherAddress,
                    _order.baseAsset,
                    _order.quoteAsset,
                    _order.matcherFeeAsset,
                    _order.amount,
                    _order.price,
                    _order.matcherFee,
                    _order.nonce,
                    _order.expiration,
                    _order.buySide
                )
            );
    }

    /**
     * @dev basic checks of matching orders against each other
     */
    function checkOrdersInfo(
        Order memory buyOrder,
        Order memory sellOrder,
        address sender,
        uint256 filledAmount,
        uint256 filledPrice,
        uint256 currentTime,
        address allowedMatcher
    ) public pure returns (bool success) {
        buyOrder.isPersonalSign ? require(validatePersonal(buyOrder), "E2BP") : require(validateV3(buyOrder), "E2B");
        sellOrder.isPersonalSign ? require(validatePersonal(sellOrder), "E2SP") : require(validateV3(sellOrder), "E2S");

        // Same matcher address
        require(
            buyOrder.matcherAddress == sender &&
                sellOrder.matcherAddress == sender,
            "E3M"
        );

        if(allowedMatcher != address(0)) {
          require(buyOrder.matcherAddress == allowedMatcher, "E3M2");
        }


        // Check matching assets
        require(
            buyOrder.baseAsset == sellOrder.baseAsset &&
                buyOrder.quoteAsset == sellOrder.quoteAsset,
            "E3As"
        );

        // Check order amounts
        require(filledAmount <= buyOrder.amount, "E3AmB");
        require(filledAmount <= sellOrder.amount, "E3AmS");

        // Check Price values
        require(filledPrice <= buyOrder.price, "E3");
        require(filledPrice >= sellOrder.price, "E3");

        // Check Expiration Time. Convert to seconds first
        require(buyOrder.expiration/1000 >= currentTime, "E4B");
        require(sellOrder.expiration/1000 >= currentTime, "E4S");

        require( buyOrder.buySide==1 && sellOrder.buySide==0, "E3D");
        success = true;
    }

    function getEthSignedOrderHash(Order memory _order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "order",
                    _order.senderAddress,
                    _order.matcherAddress,
                    _order.baseAsset,
                    _order.quoteAsset,
                    _order.matcherFeeAsset,
                    _order.amount,
                    _order.price,
                    _order.matcherFee,
                    _order.nonce,
                    _order.expiration,
                    _order.buySide
                )
            ).toEthSignedMessageHash();
    }

    function validatePersonal(Order memory order) public pure returns (bool) {

        bytes32 digest = getEthSignedOrderHash(order);
        return digest.recover(order.signature) == order.senderAddress;
    }

    function checkOrderSingleMatch(
        Order memory buyOrder,
        address sender,
        address allowedMatcher,
        uint112 filledAmount,
        uint256 currentTime,
        address[] memory path,
        uint8 isBuySide
    ) public pure returns (bool success) {
        buyOrder.isPersonalSign ? require(validatePersonal(buyOrder), "E2BP") : require(validateV3(buyOrder), "E2B");
        require(buyOrder.matcherAddress == sender && buyOrder.matcherAddress == allowedMatcher, "E3M2");
        if(buyOrder.buySide==1){
            require(
                buyOrder.baseAsset == path[path.length-1] &&
                buyOrder.quoteAsset == path[0],
                "E3As"
            );
        }else{
            require(
                buyOrder.quoteAsset == path[path.length-1] &&
                buyOrder.baseAsset == path[0],
                "E3As"
            );
        }
        require(filledAmount <= buyOrder.amount, "E3AmB");
        require(buyOrder.expiration/1000 >= currentTime, "E4B");
        require( buyOrder.buySide==isBuySide, "E3D");

    }
}

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "../PriceOracleInterface.sol";
import "../OrionVaultInterface.sol";


library MarginalFunctionality {

    // We have the following approach: when liability is created we store
    // timestamp and size of liability. If the subsequent trade will deepen
    // this liability or won't fully cover it timestamp will not change.
    // However once outstandingAmount is covered we check wether balance on
    // that asset is positive or not. If not, liability still in the place but
    // time counter is dropped and timestamp set to `now`.
    struct Liability {
        address asset;
        uint64 timestamp;
        uint192 outstandingAmount;
    }

    enum PositionState {
        POSITIVE,
        NEGATIVE, // weighted position below 0
        OVERDUE,  // liability is not returned for too long
        NOPRICE,  // some assets has no price or expired
        INCORRECT // some of the basic requirements are not met: too many liabilities, no locked stake, etc
    }

    struct Position {
        PositionState state;
        int256 weightedPosition; // sum of weighted collateral minus liabilities
        int256 totalPosition; // sum of unweighted (total) collateral minus liabilities
        int256 totalLiabilities; // total liabilities value
    }

    // Constants from Exchange contract used for calculations
    struct UsedConstants {
      address user;
      address _oracleAddress;
      address _orionVaultContractAddress;
      address _orionTokenAddress;
      uint64 positionOverdue;
      uint64 priceOverdue;
      uint8 stakeRisk;
      uint8 liquidationPremium;
    }


    /**
     * @dev method to multiply numbers with uint8 based percent numbers
     */
    function uint8Percent(int192 _a, uint8 b) internal pure returns (int192 c) {
        int a = int256(_a);
        int d = 255;
        c = int192((a>65536) ? (a/d)*b : a*b/d );
    }

    /**
     * @dev method to calc weighted and absolute collateral value
     * @notice it only count for assets in collateralAssets list, all other
               assets will add 0 to position.
     * @return outdated wether any price is outdated
     * @return weightedPosition in ORN
     * @return totalPosition in ORN
     */
    function calcAssets(address[] storage collateralAssets,
                        mapping(address => mapping(address => int192)) storage assetBalances,
                        mapping(address => uint8) storage assetRisks,
                        UsedConstants memory constants)
             internal view returns
        (bool outdated, int192 weightedPosition, int192 totalPosition) {
        uint256 collateralAssetsLength = collateralAssets.length;
        for(uint256 i = 0; i < collateralAssetsLength; i++) {
          address asset = collateralAssets[i];
          if(assetBalances[constants.user][asset]<0)
              continue; // will be calculated in calcLiabilities
          (uint64 price, uint64 timestamp) = (1e8, 0xfffffff000000000);

          if(asset != constants._orionTokenAddress) {
            PriceOracleInterface.PriceDataOut memory assetPriceData = PriceOracleInterface(constants._oracleAddress).assetPrices(asset);//TODO givePrices
            (price, timestamp) = (assetPriceData.price, assetPriceData.timestamp);
          }

          // balance: i192, price u64 => balance*price fits i256
          // since generally balance <= N*maxInt112 (where N is number operations with it),
          // assetValue <= N*maxInt112*maxUInt64/1e8.
          // That is if N<= 2**17 *1e8 = 1.3e13  we can neglect overflows here
          int192 assetValue = int192(int256(assetBalances[constants.user][asset])*price/1e8);
          // Overflows logic holds here as well, except that N is the number of
          // operations for all assets
          if(assetValue>0) {
            weightedPosition += uint8Percent(assetValue, assetRisks[asset]);
            totalPosition += assetValue;
            // if assetValue == 0  ignore outdated price
            outdated = outdated ||
                            ((timestamp + constants.priceOverdue) < block.timestamp);
          }
        }
        return (outdated, weightedPosition, totalPosition);
    }

    /**
     * @dev method to calc liabilities
     * @return outdated wether any price is outdated
     * @return overdue wether any liability is overdue
     * @return weightedPosition weightedLiability == totalLiability in ORN
     * @return totalPosition totalLiability in ORN
     */
    function calcLiabilities(mapping(address => Liability[]) storage liabilities,
                             mapping(address => mapping(address => int192)) storage assetBalances,
                             UsedConstants memory constants
                             )
             internal view returns
        (bool outdated, bool overdue, int192 weightedPosition, int192 totalPosition) {
        uint256 liabilitiesLength = liabilities[constants.user].length;
        for(uint256 i = 0; i < liabilitiesLength; i++) {
          Liability storage liability = liabilities[constants.user][i];
          PriceOracleInterface.PriceDataOut memory assetPriceData = PriceOracleInterface(constants._oracleAddress).assetPrices(liability.asset);//TODO givePrices
          (uint64 price, uint64 timestamp) = (assetPriceData.price, assetPriceData.timestamp);
          // balance: i192, price u64 => balance*price fits i256
          // since generally balance <= N*maxInt112 (where N is number operations with it),
          // assetValue <= N*maxInt112*maxUInt64/1e8.
          // That is if N<= 2**17 *1e8 = 1.3e13  we can neglect overflows here
          int192 liabilityValue = int192(
                                         int256(assetBalances[constants.user][liability.asset])
                                         *price/1e8
                                        );
          weightedPosition += liabilityValue; //already negative since balance is negative
          totalPosition += liabilityValue;
          overdue = overdue || ((liability.timestamp + constants.positionOverdue) < block.timestamp);
          outdated = outdated ||
                          ((timestamp + constants.priceOverdue) < block.timestamp);
        }

        return (outdated, overdue, weightedPosition, totalPosition);
    }

    /**
     * @dev method to calc Position
     * @return result position structure
     */
    function calcPosition(
                        address[] storage collateralAssets,
                        mapping(address => Liability[]) storage liabilities,
                        mapping(address => mapping(address => int192)) storage assetBalances,
                        mapping(address => uint8) storage assetRisks,
                        UsedConstants memory constants
                        )
             public view returns (Position memory result) {
        (bool outdatedPrice, int192 weightedPosition, int192 totalPosition) =
          calcAssets(collateralAssets,
                     assetBalances,
                     assetRisks,
                     constants);
        (bool _outdatedPrice, bool overdue, int192 _weightedPosition, int192 _totalPosition) =
           calcLiabilities(liabilities,
                           assetBalances,
                           constants
                           );
        uint64 lockedAmount = OrionVaultInterface(constants._orionVaultContractAddress)
                                  .getLockedStakeBalance(constants.user);
        int192 weightedStake = uint8Percent(int192(lockedAmount), constants.stakeRisk);
        weightedPosition += weightedStake;
        totalPosition += lockedAmount;

        weightedPosition += _weightedPosition;
        totalPosition += _totalPosition;
        outdatedPrice = outdatedPrice || _outdatedPrice;
        bool incorrect = (liabilities[constants.user].length>0) && (lockedAmount==0);
        if(_totalPosition<0) {
          result.totalLiabilities = _totalPosition;
        }
        if(weightedPosition<0) {
          result.state = PositionState.NEGATIVE;
        }
        if(outdatedPrice) {
          result.state = PositionState.NOPRICE;
        }
        if(overdue) {
          result.state = PositionState.OVERDUE;
        }
        if(incorrect) {
          result.state = PositionState.INCORRECT;
        }
        result.weightedPosition = weightedPosition;
        result.totalPosition = totalPosition;
    }

    /**
     * @dev method removes liability
     */
    function removeLiability(address user,
                             address asset,
                             mapping(address => Liability[]) storage liabilities)
        public      {
        uint256 length = liabilities[user].length;
        for (uint256 i = 0; i < length; i++) {
          if (liabilities[user][i].asset == asset) {
            if (length>1) {
              liabilities[user][i] = liabilities[user][length - 1];
            }
            liabilities[user].pop();
            break;
          }
        }
    }

    /**
     * @dev method update liability
     * @notice implement logic for outstandingAmount (see Liability description)
     */
    function updateLiability(address user,
                             address asset,
                             mapping(address => Liability[]) storage liabilities,
                             uint112 depositAmount,
                             int192 currentBalance)
        public      {
        if(currentBalance>=0) {
            removeLiability(user,asset,liabilities);
        } else {
            uint256 i;
            uint256 liabilitiesLength=liabilities[user].length;
            for(; i<liabilitiesLength-1; i++) {
                if(liabilities[user][i].asset == asset)
                  break;
              }
            Liability storage liability = liabilities[user][i];
            if(depositAmount>=liability.outstandingAmount) {
                liability.outstandingAmount = uint192(-currentBalance);
                liability.timestamp = uint64(block.timestamp);
            } else {
                liability.outstandingAmount -= depositAmount;
            }
        }
    }


    /**
     * @dev partially liquidate, that is cover some asset liability to get
            ORN from meisbehaviour broker
     */
    function partiallyLiquidate(address[] storage collateralAssets,
                                mapping(address => Liability[]) storage liabilities,
                                mapping(address => mapping(address => int192)) storage assetBalances,
                                mapping(address => uint8) storage assetRisks,
                                UsedConstants memory constants,
                                address redeemedAsset,
                                uint112 amount) public {
        //Note: constants.user - is broker who will be liquidated
        Position memory initialPosition = calcPosition(collateralAssets,
                                           liabilities,
                                           assetBalances,
                                           assetRisks,
                                           constants);
        require(initialPosition.state == PositionState.NEGATIVE ||
                initialPosition.state == PositionState.OVERDUE  , "E7");
        address liquidator = msg.sender;
        require(assetBalances[liquidator][redeemedAsset]>=amount,"E8");
        require(assetBalances[constants.user][redeemedAsset]<0,"E15");
        assetBalances[liquidator][redeemedAsset] -= amount;
        assetBalances[constants.user][redeemedAsset] += amount;
        if(assetBalances[constants.user][redeemedAsset] >= 0)
          removeLiability(constants.user, redeemedAsset, liabilities);
        PriceOracleInterface.PriceDataOut memory assetPriceData = PriceOracleInterface(constants._oracleAddress).assetPrices(redeemedAsset);
        (uint64 price, uint64 timestamp) = (assetPriceData.price, assetPriceData.timestamp);
        require((timestamp + constants.priceOverdue) > block.timestamp, "E9"); //Price is outdated

        reimburseLiquidator(amount, price, liquidator, assetBalances, constants);
        Position memory finalPosition = calcPosition(collateralAssets,
                                           liabilities,
                                           assetBalances,
                                           assetRisks,
                                           constants);
        require( int(finalPosition.state)<3 && //POSITIVE,NEGATIVE or OVERDUE
                 (finalPosition.weightedPosition>initialPosition.weightedPosition),
                 "E10");//Incorrect state position after liquidation
       if(finalPosition.state == PositionState.POSITIVE)
         require (finalPosition.weightedPosition<10e8,"Can not liquidate to very positive state");

    }

    /**
     * @dev reimburse liquidator with ORN: first from stake, than from broker balance
     */
    function reimburseLiquidator(
                       uint112 amount,
                       uint64 price,
                       address liquidator,
                       mapping(address => mapping(address => int192)) storage assetBalances,
                       UsedConstants memory constants)
             internal
             {
        int192 _orionAmount = int192(int256(amount)*price/1e8);
        _orionAmount += uint8Percent(_orionAmount,constants.liquidationPremium); //Liquidation premium
        require(_orionAmount == int64(_orionAmount), "E11");
        int64 orionAmount = int64(_orionAmount);
        // There is only 100m Orion tokens, fits i64
        int64 onBalanceOrion = int64(assetBalances[constants.user][constants._orionTokenAddress]);
        (int64 fromBalance, int64 fromStake) = (onBalanceOrion>orionAmount)?
                                                 (orionAmount, 0) :
                                                 (onBalanceOrion>0)?
                                                   (onBalanceOrion, orionAmount-onBalanceOrion) :
                                                   (0, orionAmount);

        if(fromBalance>0) {
          assetBalances[constants.user][constants._orionTokenAddress] -= int192(fromBalance);
          assetBalances[liquidator][constants._orionTokenAddress] += int192(fromBalance);
        }
        if(fromStake>0) {
          OrionVaultInterface(constants._orionVaultContractAddress).seizeFromStake(constants.user, liquidator, uint64(fromStake));
        }
    }
}

/**
Copied from @openzeppelin/contracts-ethereum-package to update pragma statements
 */

pragma solidity ^0.7.0;
import "./Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

/**
Copied from @openzeppelin/contracts-ethereum-package to update pragma statements
 */


pragma solidity ^0.7.0;


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
contract Initializable {

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

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

/**
Copied from @openzeppelin/contracts-ethereum-package to update pragma statements
 */

pragma solidity ^0.7.0;

import "./Context.sol";
import "./Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

contract ReentrancyGuard {

    bytes32 private constant REENTRANCY_MUTEX_POSITION = 0xe855346402235fdd185c890e68d2c4ecad599b88587635ee285bce2fda58dacb;

    string private constant ERROR_REENTRANT = "REENTRANCY_REENTRANT_CALL";

    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }


    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!getStorageBool(REENTRANCY_MUTEX_POSITION), ERROR_REENTRANT);

        // Lock mutex before function call
        setStorageBool(REENTRANCY_MUTEX_POSITION,true);

        // Perform function call
        _;

        // Unlock mutex after function call
        setStorageBool(REENTRANCY_MUTEX_POSITION, false);
    }
}

pragma solidity >=0.6.2;

interface IOrionPoolV2Router02Ext {
    function swapExactTokensForTokensAutoRoute(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint[] memory amounts);
    function swapTokensForExactTokensAutoRoute(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to
    ) external payable returns (uint[] memory amounts);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        (bool success, ) = recipient.call{ value: amount }("");
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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

