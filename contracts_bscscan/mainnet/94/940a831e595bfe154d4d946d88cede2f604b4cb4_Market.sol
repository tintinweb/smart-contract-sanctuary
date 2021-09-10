// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";

import "./MarketErrors.sol";
import "./IVault.sol";
import "./IExchangeOrderList.sol";
import "./ISellOrderList.sol";

import "./MiniINFTList.sol";
import "./MiniIAddressesProvider.sol";

/**
 * @title Market contract
 * - Owned by the MochiLab
 * @author MochiLab
 **/
contract Market is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant SAFE_NUMBER = 1e12;
    MiniIAddressesProvider public addressesProvider;
    MiniINFTList public nftList;
    ISellOrderList public sellOrderList;
    IVault public vault;
    IExchangeOrderList public exchangeOrderList;
    address public moma;

    mapping(address => bool) public acceptedToken;
    uint256 internal _regularFeeNumerator;
    uint256 internal _regularFeeDenominator;
    uint256 internal _momaFeeNumerator;
    uint256 internal _momaFeeDenominator;

    event RegularFeeUpdated(uint256 numerator, uint256 denominator);
    event MOMAFeeUpdated(uint256 numerator, uint256 denominator);

    modifier onlyMarketAdmin() {
        require(addressesProvider.getAdmin() == msg.sender, MarketErrors.CALLER_NOT_MARKET_ADMIN);
        _;
    }

    /**
     * @dev Function is invoked by the proxy contract when the Market contract is added to the
     * AddressesProvider of the market.
     * - Caching the address of the AddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of AddressesProvider
     * @param regularFeeNumerator The fee numerator
     * @param regularFeeDenominator The fee denominator
     **/
    function initialize(
        address provider,
        address momaToken,
        uint256 momaFeeNumerator,
        uint256 momaFeeDenominator,
        uint256 regularFeeNumerator,
        uint256 regularFeeDenominator
    ) external initializer {
        require(
            momaFeeDenominator >= momaFeeNumerator && regularFeeDenominator >= regularFeeNumerator,
            MarketErrors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR
        );
        addressesProvider = MiniIAddressesProvider(provider);
        nftList = MiniINFTList(addressesProvider.getNFTList());
        sellOrderList = ISellOrderList(addressesProvider.getSellOrderList());
        exchangeOrderList = IExchangeOrderList(addressesProvider.getExchangeOrderList());
        vault = IVault(addressesProvider.getVault());

        moma = momaToken;
        _momaFeeNumerator = momaFeeNumerator;
        _momaFeeDenominator = momaFeeDenominator;
        _regularFeeNumerator = regularFeeNumerator;
        _regularFeeDenominator = regularFeeDenominator;
    }

    /**
     * @dev Accept a token as an exchange unit on the Market
     * - Can only be called by market admin
     * @param token Token address
     **/
    function acceptToken(address token) external onlyMarketAdmin {
        require(acceptedToken[token] == false, MarketErrors.TOKEN_ALREADY_ACCEPTED);
        if (token != address(0)) {
            IERC20(token).safeApprove(address(vault), type(uint256).max);
        }
        vault.setupRewardToken(token);
        acceptedToken[token] = true;
    }

    /**
     * @dev Revoke a token so it cannot be circulated on the Market
     * - Can only be called by market admin
     * @param token Token address
     **/
    function revokeToken(address token) external onlyMarketAdmin {
        require(acceptedToken[token] == true, MarketErrors.TOKEN_ALREADY_REVOKED);
        if (token != address(0)) {
            IERC20(token).approve(address(vault), 0);
        }
        acceptedToken[token] = false;
    }

    /**
     * @dev Update fee for transactions
     * - Can only be called by market admin
     * @param numerator The fee numerator
     * @param denominator The fee denominator
     **/
    function updateRegularFee(uint256 numerator, uint256 denominator) external onlyMarketAdmin {
        require(denominator >= numerator, MarketErrors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR);
        _regularFeeNumerator = numerator;
        _regularFeeDenominator = denominator;
        emit RegularFeeUpdated(numerator, denominator);
    }

    /**
     * @dev Update fee for transactions
     * - Can only be called by market admin
     * @param numerator The fee numerator
     * @param denominator The fee denominator
     **/
    function updateMomaFee(uint256 numerator, uint256 denominator) external onlyMarketAdmin {
        require(denominator >= numerator, MarketErrors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR);
        _momaFeeNumerator = numerator;
        _momaFeeDenominator = denominator;
        emit MOMAFeeUpdated(numerator, denominator);
    }

    /**
     * @dev Create a sell order
     * - Can be called at anyone
     * @param nftAddress The address of nft contract
     * @param tokenId The tokenId of nft
     * @param amount The amount of nft seller wants to sell
     * @param price The price offered by seller
     * @param token The token that seller wants to be paid for
     **/
    function createSellOrder(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address token
    ) external nonReentrant {
        require(nftList.isAcceptedNFT(nftAddress), MarketErrors.NFT_NOT_ACCEPTED);
        require(price > 0, MarketErrors.PRICE_IS_ZERO);
        require(acceptedToken[token] == true, MarketErrors.TOKEN_NOT_ACCEPTED);

        _transferAsset(nftAddress, tokenId, amount, msg.sender, address(this), "0x");

        sellOrderList.addSellOrder(nftAddress, tokenId, amount, payable(msg.sender), price, token);
    }

    /**
     * @dev Cancel a sell order
     * - Can only be called by seller
     * @param sellId Sell order id
     **/
    function cancelSellOrder(uint256 sellId) external nonReentrant {
        SellOrderType.SellOrder memory sellOrder = sellOrderList.getSellOrderById(sellId);
        require(sellOrder.seller == msg.sender, MarketErrors.CALLER_NOT_SELLER);
        require(sellOrder.isActive == true, MarketErrors.SELL_ORDER_NOT_ACTIVE);

        _transferAsset(
            sellOrder.nftAddress,
            sellOrder.tokenId,
            sellOrder.amount - sellOrder.soldAmount,
            address(this),
            sellOrder.seller,
            "0x"
        );

        sellOrderList.deactiveSellOrder(sellId);
    }

    function removeSellOrder(uint256 sellId) external onlyMarketAdmin {
        SellOrderType.SellOrder memory sellOrder = sellOrderList.getSellOrderById(sellId);
        require(sellOrder.isActive == true, MarketErrors.SELL_ORDER_NOT_ACTIVE);

        _transferAsset(
            sellOrder.nftAddress,
            sellOrder.tokenId,
            sellOrder.amount - sellOrder.soldAmount,
            address(this),
            sellOrder.seller,
            "0x"
        );

        sellOrderList.deactiveSellOrder(sellId);
    }

    /**
     * @dev Buy 1 nft through the respective sell order
     * -  Can be called at anyone
     * @param sellId Sell order id
     * @param amount The amount buyer wants to buy
     **/
    function buy(
        uint256 sellId,
        uint256 amount,
        address receiver,
        bytes calldata data
    ) external payable nonReentrant {
        SellOrderType.SellOrder memory sellOrder = sellOrderList.getSellOrderById(sellId);

        require(sellOrder.seller != msg.sender, MarketErrors.CALLER_IS_SELLER);
        require(sellOrder.isActive == true, MarketErrors.SELL_ORDER_NOT_ACTIVE);

        require(amount > 0, MarketErrors.AMOUNT_IS_ZERO);
        require(
            amount <= sellOrder.amount - sellOrder.soldAmount,
            MarketErrors.AMOUNT_IS_NOT_ENOUGH
        );
        uint256 amountToken = amount * sellOrder.price;

        _transferAndDepositMoney(
            sellOrder.token,
            amountToken,
            sellOrder.seller,
            sellOrder.nftAddress
        );

        _transferAsset(
            sellOrder.nftAddress,
            sellOrder.tokenId,
            amount,
            address(this),
            receiver,
            data
        );

        sellOrderList.completeSellOrder(sellId, msg.sender, amount);
    }

    /**
     * @dev Update price of a sell order
     * - Can only be called by seller
     * @param id Sell order id
     * @param newPrice The new price of sell order
     **/
    function updatePrice(uint256 id, uint256 newPrice) external nonReentrant {
        SellOrderType.SellOrder memory sellOrder = sellOrderList.getSellOrderById(id);
        require(sellOrder.seller == msg.sender, MarketErrors.CALLER_NOT_SELLER);
        require(sellOrder.isActive == true, MarketErrors.SELL_ORDER_NOT_ACTIVE);
        require(sellOrder.price != newPrice, MarketErrors.PRICE_NOT_CHANGE);

        sellOrderList.updatePrice(id, newPrice);
    }

    /**
     * @dev Create an exchange order
     * - Can be called at anyone
     * @param nftAddresses The addresses of source nft and destination nft
     * @param tokenIds The tokenIds of source nft and destination nft
     * @param nftAmounts The amount of source nft and destination nft
     * @param tokens The token that seller wants to be paid for
     * @param prices The price that seller wants
     * @param users Users address
     * @param data Calldata that seller wants to execute when he receives destination nft
     **/
    function createExchangeOrder(
        address[] memory nftAddresses,
        uint256[] memory tokenIds,
        uint256[] memory nftAmounts,
        address[] memory tokens,
        uint256[] memory prices,
        address[] memory users,
        bytes[] memory data
    ) external nonReentrant {
        require(
            nftAddresses.length == tokenIds.length &&
                tokenIds.length == nftAmounts.length &&
                nftAmounts.length == tokens.length &&
                tokens.length == prices.length &&
                prices.length == data.length &&
                users.length == 1,
            MarketErrors.PARAMETERS_NOT_MATCH
        );
        require(msg.sender == users[0], MarketErrors.PARAMETERS_NOT_MATCH);

        require(data[0].length == 0, MarketErrors.INVALID_CALLDATA);

        for (uint256 i = 0; i < nftAddresses.length; i++) {
            require(nftList.isAcceptedNFT(nftAddresses[i]), MarketErrors.NFT_NOT_ACCEPTED);
            if (nftList.isERC1155(nftAddresses[i]) == true) {
                require(nftAmounts[i] > 0, MarketErrors.AMOUNT_IS_ZERO);
            } else {
                require(nftAmounts[i] == 1, MarketErrors.AMOUNT_IS_NOT_EQUAL_ONE);
            }
            if (i > 0 && prices[i] > 0) {
                require(acceptedToken[tokens[i]] == true, MarketErrors.TOKEN_NOT_ACCEPTED);
            }
        }

        _transferAsset(
            nftAddresses[0],
            tokenIds[0],
            nftAmounts[0],
            msg.sender,
            address(this),
            "0x"
        );

        exchangeOrderList.addExchangeOrder(
            nftAddresses,
            tokenIds,
            nftAmounts,
            tokens,
            prices,
            users,
            data
        );
    }

    /**
     * @dev Cancel an exchange order
     * - Can only be called by seller
     * @param exchangeId Exchange order id
     **/
    function cancelExchangeOrder(uint256 exchangeId) external nonReentrant {
        ExchangeOrderType.ExchangeOrder memory exchangeOrder = exchangeOrderList
            .getExchangeOrderById(exchangeId);
        require(exchangeOrder.users[0] == msg.sender, MarketErrors.CALLER_NOT_SELLER);
        require(exchangeOrder.isActive == true, MarketErrors.EXCHANGE_ORDER_NOT_ACTIVE);

        _transferAsset(
            exchangeOrder.nftAddresses[0],
            exchangeOrder.tokenIds[0],
            exchangeOrder.nftAmounts[0],
            address(this),
            exchangeOrder.users[0],
            "0x"
        );

        exchangeOrderList.deactiveExchangeOrder(exchangeId);
    }

    function removeExchangeOrder(uint256 exchangeId) external onlyMarketAdmin {
        ExchangeOrderType.ExchangeOrder memory exchangeOrder = exchangeOrderList
            .getExchangeOrderById(exchangeId);
        require(exchangeOrder.isActive == true, MarketErrors.EXCHANGE_ORDER_NOT_ACTIVE);

        _transferAsset(
            exchangeOrder.nftAddresses[0],
            exchangeOrder.tokenIds[0],
            exchangeOrder.nftAmounts[0],
            address(this),
            exchangeOrder.users[0],
            "0x"
        );

        exchangeOrderList.deactiveExchangeOrder(exchangeId);
    }

    /**
     * @dev Purchase an exchange order
     * -  Can be called at anyone
     * @param exchangeId Exchange order id
     * @param data Calldata that buyer wants to execute upon receiving the nft
     **/
    function exchange(
        uint256 exchangeId,
        uint256 destinationId,
        address receiver,
        bytes memory data
    ) external payable nonReentrant {
        ExchangeOrderType.ExchangeOrder memory exchangeOrder = exchangeOrderList
            .getExchangeOrderById(exchangeId);
        require(exchangeOrder.users[0] != msg.sender, MarketErrors.CALLER_IS_SELLER);
        require(exchangeOrder.isActive == true, MarketErrors.EXCHANGE_ORDER_NOT_ACTIVE);
        require(
            destinationId > 0 && destinationId < exchangeOrder.nftAddresses.length,
            MarketErrors.INVALID_DESTINATION
        );

        _transferAndDepositMoney(
            exchangeOrder.tokens[destinationId],
            exchangeOrder.prices[destinationId],
            exchangeOrder.users[0],
            exchangeOrder.nftAddresses[0]
        );

        _transferAsset(
            exchangeOrder.nftAddresses[destinationId],
            exchangeOrder.tokenIds[destinationId],
            exchangeOrder.nftAmounts[destinationId],
            msg.sender,
            exchangeOrder.users[0],
            exchangeOrder.data[destinationId]
        );

        _transferAsset(
            exchangeOrder.nftAddresses[0],
            exchangeOrder.tokenIds[0],
            exchangeOrder.nftAmounts[0],
            address(this),
            receiver,
            data
        );

        exchangeOrderList.completeExchangeOrder(exchangeId, destinationId, msg.sender);
    }

    /**
     * @dev Get regular fee
     * - external view function
     * @return Regular fee numerator and denominator
     **/
    function getRegularFee() external view returns (uint256, uint256) {
        return (_regularFeeNumerator, _regularFeeDenominator);
    }

    /**
     * @dev Get moma fee
     * - external view function
     * @return Moma fee numerator and denominator
     **/
    function getMomaFee() external view returns (uint256, uint256) {
        return (_momaFeeNumerator, _momaFeeDenominator);
    }

    /**
     * @dev Calculate fee
     * - internal view function, called inside buy(), exchange() function
     * @param token The  token address
     * @param price The price of transaction
     **/
    function _calculateFee(address token, uint256 price) internal view returns (uint256 fee) {
        if (token == moma) {
            fee = ((price * SAFE_NUMBER * _momaFeeNumerator) / _momaFeeDenominator) / SAFE_NUMBER;
        } else {
            fee =
                ((price * SAFE_NUMBER * _regularFeeNumerator) / _regularFeeDenominator) /
                SAFE_NUMBER;
        }
    }

    function _transferAndDepositMoney(
        address token,
        uint256 amount,
        address seller,
        address nftAddress
    ) internal {
        uint256 fee = _calculateFee(token, amount);

        if (token == address(0)) {
            require(msg.value == amount, MarketErrors.VALUE_NOT_EQUAL_PRICE);
            payable(seller).transfer(amount - fee);

            if (fee > 0) {
                vault.deposit{value: fee}(nftAddress, seller, msg.sender, token, fee);
            }
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(token).safeTransfer(seller, amount - fee);

            if (fee > 0) {
                vault.deposit(nftAddress, seller, msg.sender, token, fee);
            }
        }
    }

    function _transferAsset(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        address from,
        address to,
        bytes memory data
    ) internal {
        if (nftList.isERC1155(nftAddress) == true) {
            require(amount > 0, MarketErrors.AMOUNT_IS_ZERO);
            IERC1155(nftAddress).safeTransferFrom(from, to, tokenId, amount, data);
        } else {
            require(amount == 1, MarketErrors.AMOUNT_IS_NOT_EQUAL_ONE);
            IERC721(nftAddress).safeTransferFrom(from, to, tokenId, data);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}