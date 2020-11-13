pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/Interfaces/ERC20.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../common/Interfaces/Medianizer.sol";
import "../common/BaseWithStorage/Admin.sol";
import "../Catalyst/ERC20GroupCatalyst.sol";
import "../Catalyst/ERC20GroupGem.sol";
import "./PurchaseValidator.sol";


/// @title StarterPack contract that supports SAND, DAI and ETH as payment
/// @notice This contract manages the purchase and distribution of StarterPacks (bundles of Catalysts and Gems)
contract StarterPackV1 is Admin, MetaTransactionReceiver, PurchaseValidator {
    using SafeMathWithRequire for uint256;
    uint256 internal constant DAI_PRICE = 44000000000000000;
    uint256 private constant DECIMAL_PLACES = 1 ether;

    ERC20 internal immutable _sand;
    Medianizer private immutable _medianizer;
    ERC20 private immutable _dai;
    ERC20Group internal immutable _erc20GroupCatalyst;
    ERC20Group internal immutable _erc20GroupGem;

    bool _sandEnabled;
    bool _etherEnabled;
    bool _daiEnabled;

    uint256[] private _starterPackPrices;
    uint256[] private _previousStarterPackPrices;
    uint256 private _gemPrice;
    uint256 private _previousGemPrice;

    // The timestamp of the last pricechange
    uint256 private _priceChangeTimestamp;

    address payable internal _wallet;

    // The delay between calling setPrices() and when the new prices come into effect.
    // Minimizes the effect of price changes on pending TXs
    uint256 private constant PRICE_CHANGE_DELAY = 1 hours;

    event Purchase(address indexed buyer, Message message, uint256 price, address token, uint256 amountPaid);

    event SetPrices(uint256[] prices, uint256 gemPrice);

    struct Message {
        uint256[] catalystIds;
        uint256[] catalystQuantities;
        uint256[] gemIds;
        uint256[] gemQuantities;
        uint256 nonce;
    }

    // ////////////////////////// Functions ////////////////////////

    /// @notice Set the wallet receiving the proceeds
    /// @param newWallet Address of the new receiving wallet
    function setReceivingWallet(address payable newWallet) external {
        require(newWallet != address(0), "WALLET_ZERO_ADDRESS");
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _wallet = newWallet;
    }

    /// @notice Enable / disable DAI payment for StarterPacks
    /// @param enabled Whether to enable or disable
    function setDAIEnabled(bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _daiEnabled = enabled;
    }

    /// @notice Return whether DAI payments are enabled
    /// @return Whether DAI payments are enabled
    function isDAIEnabled() external view returns (bool) {
        return _daiEnabled;
    }

    /// @notice Enable / disable ETH payment for StarterPacks
    /// @param enabled Whether to enable or disable
    function setETHEnabled(bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _etherEnabled = enabled;
    }

    /// @notice Return whether ETH payments are enabled
    /// @return Whether ETH payments are enabled
    function isETHEnabled() external view returns (bool) {
        return _etherEnabled;
    }

    /// @dev Enable / disable the specific SAND payment for StarterPacks
    /// @param enabled Whether to enable or disable
    function setSANDEnabled(bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _sandEnabled = enabled;
    }

    /// @notice Return whether SAND payments are enabled
    /// @return Whether SAND payments are enabled
    function isSANDEnabled() external view returns (bool) {
        return _sandEnabled;
    }

    /// @notice Purchase StarterPacks with SAND
    /// @param buyer The destination address for the purchased Catalysts and Gems and the address that will pay for the purchase; if not metaTx then buyer must be equal to msg.sender
    /// @param message A message containing information about the Catalysts and Gems to be purchased
    /// @param signature A signed message specifying tx details

    function purchaseWithSand(
        address buyer,
        Message calldata message,
        bytes calldata signature
    ) external {
        require(msg.sender == buyer || _metaTransactionContracts[msg.sender], "INVALID_SENDER");
        require(_sandEnabled, "SAND_IS_NOT_ENABLED");
        require(buyer != address(0), "DESTINATION_ZERO_ADDRESS");
        require(
            isPurchaseValid(buyer, message.catalystIds, message.catalystQuantities, message.gemIds, message.gemQuantities, message.nonce, signature),
            "INVALID_PURCHASE"
        );

        uint256 amountInSand = _calculateTotalPriceInSand(message.catalystIds, message.catalystQuantities, message.gemQuantities);
        _handlePurchaseWithERC20(buyer, _wallet, address(_sand), amountInSand);
        _erc20GroupCatalyst.batchTransferFrom(address(this), buyer, message.catalystIds, message.catalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), buyer, message.gemIds, message.gemQuantities);
        emit Purchase(buyer, message, amountInSand, address(_sand), amountInSand);
    }

    /// @notice Purchase StarterPacks with Ether
    /// @param buyer The destination address for the purchased Catalysts and Gems and the address that will pay for the purchase; if not metaTx then buyer must be equal to msg.sender
    /// @param message A message containing information about the Catalysts and Gems to be purchased
    /// @param signature A signed message specifying tx details
    function purchaseWithETH(
        address buyer,
        Message calldata message,
        bytes calldata signature
    ) external payable {
        require(msg.sender == buyer || _metaTransactionContracts[msg.sender], "INVALID_SENDER");
        require(_etherEnabled, "ETHER_IS_NOT_ENABLED");
        require(buyer != address(0), "DESTINATION_ZERO_ADDRESS");
        require(buyer != address(this), "DESTINATION_STARTERPACKV1_CONTRACT");
        require(
            isPurchaseValid(buyer, message.catalystIds, message.catalystQuantities, message.gemIds, message.gemQuantities, message.nonce, signature),
            "INVALID_PURCHASE"
        );

        uint256 amountInSand = _calculateTotalPriceInSand(message.catalystIds, message.catalystQuantities, message.gemQuantities);
        uint256 ETHRequired = getEtherAmountWithSAND(amountInSand);
        require(msg.value >= ETHRequired, "NOT_ENOUGH_ETHER_SENT");

        _wallet.transfer(ETHRequired);
        _erc20GroupCatalyst.batchTransferFrom(address(this), buyer, message.catalystIds, message.catalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), buyer, message.gemIds, message.gemQuantities);
        emit Purchase(buyer, message, amountInSand, address(0), ETHRequired);

        if (msg.value - ETHRequired > 0) {
            // refund extra
            (bool success, ) = msg.sender.call{value: msg.value - ETHRequired}("");
            require(success, "REFUND_FAILED");
        }
    }

    /// @notice Purchase StarterPacks with DAI
    /// @param buyer The destination address for the purchased Catalysts and Gems and the address that will pay for the purchase; if not metaTx then buyer must be equal to msg.sender
    /// @param message A message containing information about the Catalysts and Gems to be purchased
    /// @param signature A signed message specifying tx details
    function purchaseWithDAI(
        address buyer,
        Message calldata message,
        bytes calldata signature
    ) external {
        require(msg.sender == buyer || _metaTransactionContracts[msg.sender], "INVALID_SENDER");
        require(_daiEnabled, "DAI_IS_NOT_ENABLED");
        require(buyer != address(0), "DESTINATION_ZERO_ADDRESS");
        require(buyer != address(this), "DESTINATION_STARTERPACKV1_CONTRACT");
        require(
            isPurchaseValid(buyer, message.catalystIds, message.catalystQuantities, message.gemIds, message.gemQuantities, message.nonce, signature),
            "INVALID_PURCHASE"
        );

        uint256 amountInSand = _calculateTotalPriceInSand(message.catalystIds, message.catalystQuantities, message.gemQuantities);
        uint256 DAIRequired = amountInSand.mul(DAI_PRICE).div(DECIMAL_PLACES);
        _handlePurchaseWithERC20(buyer, _wallet, address(_dai), DAIRequired);
        _erc20GroupCatalyst.batchTransferFrom(address(this), buyer, message.catalystIds, message.catalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), buyer, message.gemIds, message.gemQuantities);
        emit Purchase(buyer, message, amountInSand, address(_dai), DAIRequired);
    }

    /// @notice Enables admin to withdraw all remaining tokens
    /// @param to The destination address for the purchased Catalysts and Gems
    /// @param catalystIds The IDs of the catalysts to be transferred
    /// @param gemIds The IDs of the gems to be transferred
    function withdrawAll(
        address to,
        uint256[] calldata catalystIds,
        uint256[] calldata gemIds
    ) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");

        address[] memory catalystAddresses = new address[](catalystIds.length);
        for (uint256 i = 0; i < catalystIds.length; i++) {
            catalystAddresses[i] = address(this);
        }
        address[] memory gemAddresses = new address[](gemIds.length);
        for (uint256 i = 0; i < gemIds.length; i++) {
            gemAddresses[i] = address(this);
        }
        uint256[] memory unsoldCatalystQuantities = _erc20GroupCatalyst.balanceOfBatch(catalystAddresses, catalystIds);
        uint256[] memory unsoldGemQuantities = _erc20GroupGem.balanceOfBatch(gemAddresses, gemIds);

        _erc20GroupCatalyst.batchTransferFrom(address(this), to, catalystIds, unsoldCatalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), to, gemIds, unsoldGemQuantities);
    }

    /// @notice Enables admin to change the prices of the StarterPack bundles
    /// @param prices Array of new prices that will take effect after a delay period
    /// @param gemPrice New price for gems that will take effect after a delay period

    function setPrices(uint256[] calldata prices, uint256 gemPrice) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _previousStarterPackPrices = _starterPackPrices;
        _starterPackPrices = prices;
        _previousGemPrice = _gemPrice;
        _gemPrice = gemPrice;
        _priceChangeTimestamp = now;
        emit SetPrices(prices, gemPrice);
    }

    /// @notice Get current StarterPack prices
    /// @return pricesBeforeSwitch Array of prices before price change
    /// @return pricesAfterSwitch Array of prices after price change
    /// @return gemPriceBeforeSwitch Gem price before price change
    /// @return gemPriceAfterSwitch Gem price after price change
    /// @return switchTime The time the latest price change will take effect, being the time of the price change plus the price change delay

    function getPrices()
        external
        view
        returns (
            uint256[] memory pricesBeforeSwitch,
            uint256[] memory pricesAfterSwitch,
            uint256 gemPriceBeforeSwitch,
            uint256 gemPriceAfterSwitch,
            uint256 switchTime
        )
    {
        switchTime = 0;
        if (_priceChangeTimestamp != 0) {
            switchTime = _priceChangeTimestamp + PRICE_CHANGE_DELAY;
        }
        return (_previousStarterPackPrices, _starterPackPrices, _previousGemPrice, _gemPrice, switchTime);
    }

    /// @notice Returns the amount of ETH for a specific amount of SAND
    /// @param sandAmount An amount of SAND
    /// @return The amount of ETH
    function getEtherAmountWithSAND(uint256 sandAmount) public view returns (uint256) {
        uint256 ethUsdPair = _getEthUsdPair();
        return sandAmount.mul(DAI_PRICE).div(ethUsdPair);
    }

    // ////////////////////////// Internal ////////////////////////

    /// @dev Gets the ETHUSD pair from the Medianizer contract
    /// @return The pair as an uint256
    function _getEthUsdPair() internal view returns (uint256) {
        bytes32 pair = _medianizer.read();
        return uint256(pair);
    }

    /// @dev Function to calculate the total price in SAND of the StarterPacks to be purchased
    /// @dev The price of each StarterPack relates to the catalystId
    /// @param catalystIds Array of catalystIds to be purchase
    /// @param catalystQuantities Array of quantities of those catalystIds to be purchased
    /// @return Total price in SAND
    function _calculateTotalPriceInSand(
        uint256[] memory catalystIds,
        uint256[] memory catalystQuantities,
        uint256[] memory gemQuantities
    ) internal returns (uint256) {
        require(catalystIds.length == catalystQuantities.length, "INVALID_INPUT");
        (uint256[] memory prices, uint256 gemPrice) = _priceSelector();
        uint256 totalPrice;
        for (uint256 i = 0; i < catalystIds.length; i++) {
            uint256 id = catalystIds[i];
            uint256 quantity = catalystQuantities[i];
            totalPrice = totalPrice.add(prices[id].mul(quantity));
        }
        for (uint256 i = 0; i < gemQuantities.length; i++) {
            uint256 quantity = gemQuantities[i];
            totalPrice = totalPrice.add(gemPrice.mul(quantity));
        }
        return totalPrice;
    }

    /// @dev Function to determine whether to use old or new prices
    /// @return Array of prices

    function _priceSelector() internal returns (uint256[] memory, uint256) {
        uint256[] memory prices;
        uint256 gemPrice;
        // No price change:
        if (_priceChangeTimestamp == 0) {
            prices = _starterPackPrices;
            gemPrice = _gemPrice;
        } else {
            // Price change delay has expired.
            if (now > _priceChangeTimestamp + PRICE_CHANGE_DELAY) {
                _priceChangeTimestamp = 0;
                prices = _starterPackPrices;
                gemPrice = _gemPrice;
            } else {
                // Price change has occured:
                prices = _previousStarterPackPrices;
                gemPrice = _previousGemPrice;
            }
        }
        return (prices, gemPrice);
    }

    /// @dev Function to handle purchase with SAND or DAI
    function _handlePurchaseWithERC20(
        address buyer,
        address payable paymentRecipient,
        address tokenAddress,
        uint256 amount
    ) internal {
        ERC20 token = ERC20(tokenAddress);
        uint256 amountForDestination = amount;
        require(token.transferFrom(buyer, paymentRecipient, amountForDestination), "PAYMENT_TRANSFER_FAILED");
    }

    // /////////////////// CONSTRUCTOR ////////////////////

    constructor(
        address starterPackAdmin,
        address sandContractAddress,
        address initialMetaTx,
        address payable initialWalletAddress,
        address medianizerContractAddress,
        address daiTokenContractAddress,
        address erc20GroupCatalystAddress,
        address erc20GroupGemAddress,
        address initialSigningWallet,
        uint256[] memory initialStarterPackPrices,
        uint256 initialGemPrice
    ) public PurchaseValidator(initialSigningWallet) {
        _setMetaTransactionProcessor(initialMetaTx, true);
        _wallet = initialWalletAddress;
        _admin = starterPackAdmin;
        _sand = ERC20(sandContractAddress);
        _medianizer = Medianizer(medianizerContractAddress);
        _dai = ERC20(daiTokenContractAddress);
        _erc20GroupCatalyst = ERC20Group(erc20GroupCatalystAddress);
        _erc20GroupGem = ERC20Group(erc20GroupGemAddress);
        _starterPackPrices = initialStarterPackPrices;
        _previousStarterPackPrices = initialStarterPackPrices;
        _gemPrice = initialGemPrice;
        _previousGemPrice = initialGemPrice;
        _sandEnabled = true; // Sand is enabled by default
        _etherEnabled = true; // Ether is enabled by default
    }
}
