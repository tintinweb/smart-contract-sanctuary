// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

/**
 * @dev Implementation of a PointOfSale.
 *  This contract works as a PointOfSale for a set of pre-defined products with prices.
 *  It provides a simple solution for merchants to process payments with on-chain data
 *  on any EVM powered network.
 *
 *  The contract must work together with a backend API to use events as triggers to deliver
 *  the purchased products. It has an internal system to track purchases and requires users
 *  to register the deliver point outside of the network.
 */
contract Shop is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* STRUCTS */

    struct Sale {
        uint256 product;
        address token;
        uint256 tokenPrice;
        uint256 wethPrice;
        uint256 productPrice;
        uint256 time;
    }

    struct Product {
        uint256 id;
        string image;
        uint256 price;
        bool available;
    }

    /* MAPS FOR TRACKING */

    // Registered users.
    // This serves as a second verification to make sure all users have
    // registered a place (email) to redeem the purchase.
    // Emails are not registered here, this should only include a hash
    // of the email that will be verified to verify.
    mapping(address => bytes32) public users;

    // User purchases map
    mapping(address => Sale[]) history;

    // A map of products IDs with prices.
    mapping(uint256 => Product) products;
    uint256[] productsList;

    /* CONST */

    address public immutable router;
    IUniswapV2Factory public immutable factory;

    // Token to receive for all purchases.
    address public immutable chargeToken;
    address public immutable prefToken;
    address public immutable WETH;

    uint256 public fee;
    uint256 public feeForPrefToken;

    bool public initialized;
    bool public buyBackAndBurn;

    /* Events */
    event Purchase(address addr, uint256 product);
    event PurchaseCustomOrder(address addr, uint256 orderId, uint256 payed_price);

    /* CONSTRUCTOR */
    constructor(address _router, address _factory, address _receiveToken, address _prefToken, address _weth) {
        router = _router;
        factory = IUniswapV2Factory(_factory);
        chargeToken = _receiveToken;
        prefToken = _prefToken;
        WETH = _weth;

        initialized = false;
        buyBackAndBurn = false;
        fee = 4;
        feeForPrefToken = 3;
    }

    // getUserHash returns the specified user hash
    function getUserHash(address _user) public view returns (bytes32) {
        return users[_user];
    }

    // getEmailHash returns the hashed result of the email, this is external to use with
    // front-end compare against registered email.
    function getEmailHash(string calldata email) public pure returns (bytes32) {
        return keccak256(abi.encode(email));
    }

    // getProduct returns product information from the id
    function getProduct(uint256 _id) public view returns(Product memory) {
        return products[_id];
    }

    // getProductsList returns all product ids
    function getProductsList() public view returns(uint256[] memory) {
        return productsList;
    }

    // getUserHistory returns the user purchases history
    function getUserHistory() public view returns (Sale[] memory) {
        return history[msg.sender];
    }

    function getProductPrice(uint256 _id) public view returns (uint256) {
        return products[_id].price;
    }

    // getProductPricesOnSpecificTokenForCustomOrder gives the price custom order using any token.
    // This returns two prices: final order price and token price.
    // Slippage is delegated to the user to prevent high slippage tokens (SafeMoon, PitBull, etc) to fail transactions.
    function getProductPricesOnSpecificTokenForCustomOrder(uint256 _price, address _token, uint256 slippage) public view returns (uint256, uint256) {
        // Check if the token the user wants is preferable and allows lower fee.
        uint256 saleFee;
        if (_token == prefToken) {
            saleFee = feeForPrefToken;
        } else {
            saleFee = fee;
        }

        require(_price != 0, "POS: getProductPricesOnSpecificTokenForCustomOrder specific order price cannot be 0");

        uint256 finalPrice = _price.add(_price.mul(saleFee).div(100));

        // If the token submitted is the same as the chargeToken return the data.
        if (_token == chargeToken) {
            return (finalPrice, 0);
        }

        uint256 wethPrice = calcWethPrice(finalPrice, slippage);

        // If token is WETH return the data;
        if (_token == WETH) {
            return (finalPrice, wethPrice);
        }

        uint256 tokenPrice = calcTokenPrice(_token, wethPrice, slippage);

        return (finalPrice, tokenPrice);
    }

    // getProductPricesOnSpecificToken gives the price of a product using any token.
    // This function returns: chargeTokenPrice, WETH price and Token Price.
    // Slippage is delegated to the user to prevent high slippage tokens (SafeMoon, PitBull, etc) to fail transactions.
    function getProductPricesOnSpecificToken(uint256 _id, address _token, uint256 slippage) public view returns (uint256, uint256, uint256) {
        // Get pairs to calculate route price

        // Check if the token the user wants is preferable and allows lower fee.
        uint256 saleFee;
        if (_token == prefToken) {
            saleFee = feeForPrefToken;
        } else {
            saleFee = fee;
        }

        // Calculate final price
        require(products[_id].price != 0, "POS: getProductPricesOnSpecificToken product doesn't exist");

        uint256 finalPrice = products[_id].price.add(products[_id].price.mul(saleFee).div(100));

        // If the token submitted is the same as the chargeToken return the data.
        if (_token == chargeToken) {
            return (finalPrice,0,0);
        }

        uint256 wethPrice = calcWethPrice(finalPrice, slippage);

        // If token is WETH return the data;
        if (_token == WETH) {
            return (finalPrice, wethPrice, 0);
        }

        uint256 tokenPrice = calcTokenPrice(_token, wethPrice, slippage);

        return (finalPrice, wethPrice, tokenPrice);
    }

    function calcWethPrice(uint256 chargePrice, uint256 slippage) internal view returns (uint256) {
        // Calculate the amount of WETH user needs to pay to purchase the product (with fee and slippage)
        (uint112 chargeTokenReserves, uint112 wethReserves,) = IUniswapV2Pair(factory.getPair(chargeToken, WETH)).getReserves();
        uint256 wethPrice = chargePrice.mul(wethReserves).div(chargeTokenReserves);

        return wethPrice.add(wethPrice.mul(slippage).div(100));
    }

    function calcTokenPrice(address _token, uint256 wethPrice, uint256 slippage) internal view returns (uint256) {
        // Check that the token the user wants to use has a pair against WETH.
        address tokenSalePair = factory.getPair(_token, WETH);
        require(tokenSalePair != address(0), "POS: getProductPriceOnSpecificToken pair doesn't exist for this token");

        // Calculate the amount of token user needs to pay to achieve the WETH amount
        (uint112 tokenReserves, uint112 wethTokenReserves,) = IUniswapV2Pair(tokenSalePair).getReserves();
        uint256 tokenPrice = wethPrice.mul(tokenReserves).div(wethTokenReserves);

        return tokenPrice.add(tokenPrice.mul(slippage).div(100));
    }

    //*****************************************//

    // setInitialize sets the initialization
    function setInitialize(bool _init) public onlyOwner {
        initialized = _init;
    }

    // setBuyBackAndBurn enables buy back and burn
    function setBuyBackAndBurn(bool _set) public onlyOwner {
        buyBackAndBurn = _set;
    }

    // buyCustomOrder submits the token to perform trades and submit a Purchase event
    function buyCustomOrder(uint256 _orderID, address _token, uint256 slippage, uint256 _orderPrice) public {
        require(initialized, "POS: Shop is closed, please try again later");

        // Fetch price
        (uint256 finalPrice, uint256 tokenPrice) = getProductPricesOnSpecificTokenForCustomOrder(_orderPrice, _token, slippage);

        // Perform trades
        if (_token == chargeToken) {
            IERC20(chargeToken).safeTransferFrom(msg.sender, address(this), finalPrice);

            // If the token purchase is made with chargeToken and buyBackAndBurn is enabled submit buyBackBurn.
            if (buyBackAndBurn) {
                buyBackAndBurnTokens(finalPrice);
            }

            emit PurchaseCustomOrder(msg.sender, _orderID, finalPrice);

        } else if (_token == WETH) {

            IERC20(WETH).safeTransferFrom(msg.sender, address(this), tokenPrice);

            swapWETHToChargeToken(finalPrice, tokenPrice);

            emit PurchaseCustomOrder(msg.sender, _orderID, finalPrice);

        } else {

            IERC20(_token).safeTransferFrom(msg.sender, address(this), tokenPrice);

            swapTokenToChargeToken(_token, finalPrice, tokenPrice);

            emit PurchaseCustomOrder(msg.sender, _orderID, finalPrice);

        }

    }

    // buy submits the token perform trades and submit the Purchase event
    function buy(uint256 _id, address _token, uint256 slippage) public {
        require(initialized, "POS: Shop is closed, please try again later");

        // Make sure user is registered
        require(users[msg.sender] != "", "POS: buy user is not registered on-chain");

        // Fetch prices
        (uint256 chargePrice, uint256 wethPrice, uint256 tokenPrice) = getProductPricesOnSpecificToken(_id, _token, slippage);

        // Perform trades
        if (_token == chargeToken) {
            IERC20(chargeToken).safeTransferFrom(msg.sender, address(this), chargePrice);

            // If the token purchase is made with chargeToken and buyBackAndBurn is enabled
            // submit buyBackBurn.
            if (buyBackAndBurn) {
                buyBackAndBurnTokens(chargePrice);
            }

            addSaleToUserHistory(_id, _token, tokenPrice, wethPrice, chargePrice);
            emit Purchase(msg.sender, _id);

        } else if (_token == WETH) {

            IERC20(WETH).safeTransferFrom(msg.sender, address(this), wethPrice);

            swapWETHToChargeToken(chargePrice, wethPrice);

            addSaleToUserHistory(_id, _token, tokenPrice, wethPrice, chargePrice);
            emit Purchase(msg.sender, _id);

        } else {

            IERC20(_token).safeTransferFrom(msg.sender, address(this), tokenPrice);

            swapTokenToChargeToken(_token, chargePrice, tokenPrice);

            addSaleToUserHistory(_id, _token, tokenPrice, wethPrice, chargePrice);
            emit Purchase(msg.sender, _id);

        }

    }

    function buyBackAndBurnTokens(uint256 chargePrice) internal {
        // Just buy 1% of the prefToken and burn it

        // Use 1% to buy
        uint256 amountBuy = chargePrice.div(100);
        address[] memory path = new address[](3);
        path[0] = chargeToken;
        path[1] = WETH;
        path[2] = prefToken;


        // Check allowance and approve if needed
        uint256 allowance = IERC20(chargeToken).allowance(address(this), router);
        if (allowance < amountBuy) {
            IERC20(chargeToken).approve(router, uint256(-1));
        }

        IUniswapV2Router02(router).swapExactTokensForTokens(amountBuy, 0, path, address(this), block.timestamp + 2000);

        IERC20(prefToken).transfer(address(0xdeAD00000000000000000000000000000000dEAd), IERC20(prefToken).balanceOf(address(this)));
    }

    function swapWETHToChargeToken(uint256 chargePrice, uint256 wethPrice) internal {

        // Change all WETH to Charge Token
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = chargeToken;

        // Check allowance and approve if needed
        uint256 allowance = IERC20(WETH).allowance(address(this), router);
        if (allowance < wethPrice) {
            IERC20(WETH).approve(router, uint256(-1));
        }

        IUniswapV2Router02(router).swapExactTokensForTokens(wethPrice, chargePrice, path, address(this), block.timestamp + 200);

        if (buyBackAndBurn) {
            buyBackAndBurnTokens(chargePrice);
        }

    }

    function swapTokenToChargeToken(address _token, uint256 chargePrice, uint256 tokenAmount) internal {

        // Change all Token to Charge Token
        address[] memory path = new address[](3);
        path[0] = _token;
        path[1] = WETH;
        path[2] = chargeToken;

        uint256 allowance = IERC20(_token).allowance(address(this), router);
        if (allowance < tokenAmount) {
            IERC20(_token).approve(router, uint256(-1));
        }

        IUniswapV2Router02(router).swapExactTokensForTokens(tokenAmount, chargePrice, path, address(this), block.timestamp + 200);

        if (buyBackAndBurn) {
            buyBackAndBurnTokens(chargePrice);
        }

    }

    function addSaleToUserHistory(uint256 _id, address _token, uint256 tokenPrice, uint256 wethPrice, uint256 chargePrice) internal {
        Sale memory sale = Sale(_id, _token, tokenPrice, wethPrice, chargePrice, block.timestamp);
        history[msg.sender].push(sale);
    }


    // register to hash email into the internal map
    // If the user calls again it replaces the information.
    function register(string calldata email) public {
        users[msg.sender] = getEmailHash(email);
    }

    // setFee modifies the fee for all tokens.
    function setFee(uint256 newFee) public onlyOwner {
        fee = newFee;
    }

    // setFeeForPrefToken modifies the fee for the preferable token.
    function setFeeForPrefToken(uint256 newFee) public onlyOwner {
        feeForPrefToken = newFee;
    }

    // claim sends the chargeToken to the owner
    function claim() public onlyOwner {
        uint256 balance = IERC20(chargeToken).balanceOf(address(this));
        IERC20(chargeToken).safeTransfer(owner(), balance);
    }

    // addBulkProducts adds the products to the catalogue (Maximum of 200 products). Overrides if already exist.
    function addBulkProducts(Product[] memory _products) public onlyOwner {
        uint256 length = _products.length;
        require(length < 200, "POS: addBulkProducts can only add a maximum of 200 products");
        for (uint256 i = 0; i < length; i++) {
            addProduct(_products[i]);
        }
    }

    // addProduct adds a specific product to the catalogue, overrides if exist.
    function addProduct(Product memory _product) public onlyOwner {
        // Check if product already exist
        if (products[_product.id].id == 0 && products[_product.id].price == 0) {
            productsList.push(_product.id);
        }
        products[_product.id] = _product;
    }
}