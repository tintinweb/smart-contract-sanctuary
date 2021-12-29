// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "../../shared/weth/IWETH.sol";
import "../../shared/uniswap/IUniswapV3Factory.sol";
import "../../shared/uniswap/IQuoter.sol";
import "../../shared/uniswap/ISwapRouter.sol";
import "../../shared/core/interfaces/IIdeaTokenExchange.sol";
import "../../shared/core/interfaces/IIdeaTokenFactory.sol";
import "../../shared/core/interfaces/IIdeaTokenVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MultiAction
 * @author Alexander Schlindwein
 *
 * Allows to bundle multiple actions into one tx
 */
contract MultiAction {

    // IdeaTokenExchange contract
    IIdeaTokenExchange _ideaTokenExchange;
    // IdeaTokenFactory contract
    IIdeaTokenFactory _ideaTokenFactory;
    // IdeaTokenVault contract
    IIdeaTokenVault _ideaTokenVault;
    // Dai contract
    IERC20 public _dai;
    // IUniswapV3Factory contract
    IUniswapV3Factory public _uniswapV3Factory;
    // IQuoter contract
    IQuoter public _uniswapV3Quoter;
    // ISwapRouter contract
    ISwapRouter public _uniswapV3SwapRouter;
    // WETH contract
    IWETH public _weth;
    // Uniswap V3 Low pool fee
    uint24 public constant LOW_POOL_FEE = 500;
    // Uniswap V3 Medium pool fee
    uint24 public constant MEDIUM_POOL_FEE = 3000;
    // Uniswap V3 High pool fee
    uint24 public constant HIGH_POOL_FEE = 10000;

    /**
     * @param ideaTokenExchange The address of the IdeaTokenExchange contract
     * @param ideaTokenFactory The address of the IdeaTokenFactory contract
     * @param ideaTokenVault The address of the IdeaTokenVault contract
     * @param dai The address of the Dai token
     * @param swapRouter The address of the SwapRouter contract
     * @param quoter The address of the Quoter contract
     * @param weth The address of the WETH token
     */
    constructor(address ideaTokenExchange,
                address ideaTokenFactory,
                address ideaTokenVault,
                address dai,
                address swapRouter,
                address quoter,
                address weth) public {

        require(ideaTokenExchange != address(0) &&
                ideaTokenFactory != address(0) &&
                ideaTokenVault != address(0) &&
                dai != address(0) &&
                swapRouter != address(0) &&
                quoter != address(0) &&
                weth != address(0),
                "invalid-params");

        _ideaTokenExchange = IIdeaTokenExchange(ideaTokenExchange);
        _ideaTokenFactory = IIdeaTokenFactory(ideaTokenFactory);
        _ideaTokenVault = IIdeaTokenVault(ideaTokenVault);
        _dai = IERC20(dai);
        _uniswapV3SwapRouter = ISwapRouter(swapRouter);
        _uniswapV3Factory = IUniswapV3Factory(ISwapRouter(swapRouter).factory());
        _uniswapV3Quoter = IQuoter(quoter);
        _weth = IWETH(weth);
    }

    /**
     * Converts inputCurrency to Dai on Uniswap and buys IdeaTokens
     *
     * @param inputCurrency The input currency
     * @param ideaToken The IdeaToken to buy
     * @param amount The amount of IdeaTokens to buy
     * @param fallbackAmount The amount of IdeaTokens to buy if the original amount cannot be bought
     * @param cost The maximum cost in input currency
     * @param lockDuration The duration in seconds to lock the tokens
     * @param recipient The recipient of the IdeaTokens
     */
    function convertAndBuy(address inputCurrency,
                           address ideaToken,
                           uint amount,
                           uint fallbackAmount,
                           uint cost,
                           uint lockDuration,
                           address recipient) external payable {

        IIdeaTokenExchange exchange = _ideaTokenExchange;

        uint buyAmount = amount;
        uint buyCost = exchange.getCostForBuyingTokens(ideaToken, amount);
        uint requiredInput = getInputForOutputInternal(inputCurrency, address(_dai), buyCost);

        if(requiredInput > cost) {
            buyCost = exchange.getCostForBuyingTokens(ideaToken, fallbackAmount);
            requiredInput = getInputForOutputInternal(inputCurrency, address(_dai), buyCost);
            require(requiredInput <= cost, "slippage");
            buyAmount = fallbackAmount;
        }

        convertAndBuyInternal(inputCurrency, ideaToken, requiredInput, buyAmount, buyCost, lockDuration, recipient);
    }

    /**
     * Sells IdeaTokens and converts Dai to outputCurrency
     *
     * @param outputCurrency The output currency
     * @param ideaToken The IdeaToken to sell
     * @param amount The amount of IdeaTokens to sell
     * @param minPrice The minimum price to receive for selling in outputCurrency
     * @param recipient The recipient of the funds
     */
    function sellAndConvert(address outputCurrency,
                            address ideaToken,
                            uint amount,
                            uint minPrice,
                            address payable recipient) external {
        
        IIdeaTokenExchange exchange = _ideaTokenExchange;
        IERC20 dai = _dai;

        uint sellPrice = exchange.getPriceForSellingTokens(ideaToken, amount);
        uint output = getOutputForInputInternal(address(dai), outputCurrency, sellPrice);
        require(output >= minPrice, "slippage");

        pullERC20Internal(ideaToken, msg.sender, amount);
        exchange.sellTokens(ideaToken, amount, sellPrice, address(this));

        convertInternal(address(dai), outputCurrency, sellPrice, output);
        if(outputCurrency == address(0)) {
            recipient.transfer(output);
        } else {
            require(IERC20(outputCurrency).transfer(recipient, output), "transfer");
        }
    }

    /**
     * Converts `inputCurrency` to Dai, adds a token and buys the added token
     * 
     * @param tokenName The name for the new IdeaToken
     * @param marketID The ID of the market where the new token will be added
     * @param inputCurrency The input currency to use for the purchase of the added token
     * @param amount The amount of IdeaTokens to buy
     * @param fallbackAmount The amount of IdeaTokens to buy if the original amount cannot be bought
     * @param cost The maximum cost in input currency
     * @param lockDuration The duration in seconds to lock the tokens
     * @param recipient The recipient of the IdeaTokens
     */
    function convertAddAndBuy(string calldata tokenName,
                              uint marketID,
                              address inputCurrency,
                              uint amount,
                              uint fallbackAmount,
                              uint cost,
                              uint lockDuration,
                              address recipient) external payable {

        IERC20 dai = _dai;

        uint buyAmount = amount;
        uint buyCost = getBuyCostFromZeroSupplyInternal(marketID, buyAmount);
        uint requiredInput = getInputForOutputInternal(inputCurrency, address(dai), buyCost);

        if(requiredInput > cost) {
            buyCost = getBuyCostFromZeroSupplyInternal(marketID, fallbackAmount);
            requiredInput = getInputForOutputInternal(inputCurrency, address(dai), buyCost);
            require(requiredInput <= cost, "slippage");
            buyAmount = fallbackAmount;
        }

        address ideaToken = addTokenInternal(tokenName, marketID);
        convertAndBuyInternal(inputCurrency, ideaToken, requiredInput, buyAmount, buyCost, lockDuration, recipient);
    }

    /**
     * Adds a token and buys it
     * 
     * @param tokenName The name for the new IdeaToken
     * @param marketID The ID of the market where the new token will be added
     * @param amount The amount of IdeaTokens to buy
     * @param lockDuration The duration in seconds to lock the tokens
     * @param recipient The recipient of the IdeaTokens
     */
    function addAndBuy(string calldata tokenName, uint marketID, uint amount, uint lockDuration, address recipient) external {
        uint cost = getBuyCostFromZeroSupplyInternal(marketID, amount);
        pullERC20Internal(address(_dai), msg.sender, cost);

        address ideaToken = addTokenInternal(tokenName, marketID);
        
        if(lockDuration > 0) {
            buyAndLockInternal(ideaToken, amount, cost, lockDuration, recipient);
        } else {
            buyInternal(ideaToken, amount, cost, recipient);
        }
    }

    /**
     * Buys a IdeaToken and locks it in the IdeaTokenVault
     *
     * @param ideaToken The IdeaToken to buy
     * @param amount The amount of IdeaTokens to buy
     * @param fallbackAmount The amount of IdeaTokens to buy if the original amount cannot be bought
     * @param cost The maximum cost in input currency
     * @param recipient The recipient of the IdeaTokens
     */
    function buyAndLock(address ideaToken, uint amount, uint fallbackAmount, uint cost, uint lockDuration, address recipient) external {

        IIdeaTokenExchange exchange = _ideaTokenExchange;

        uint buyAmount = amount;
        uint buyCost = exchange.getCostForBuyingTokens(ideaToken, amount);
        if(buyCost > cost) {
            buyCost = exchange.getCostForBuyingTokens(ideaToken, fallbackAmount);
            require(buyCost <= cost, "slippage");
            buyAmount = fallbackAmount;
        }

        pullERC20Internal(address(_dai), msg.sender, buyCost);
        buyAndLockInternal(ideaToken, buyAmount, buyCost, lockDuration, recipient);
    }

    /**
     * Converts `inputCurrency` to Dai on Uniswap and buys an IdeaToken, optionally locking it in the IdeaTokenVault
     *
     * @param inputCurrency The input currency to use
     * @param ideaToken The IdeaToken to buy
     * @param input The amount of `inputCurrency` to sell
     * @param amount The amount of IdeaTokens to buy
     * @param cost The cost in Dai for purchasing `amount` IdeaTokens
     * @param lockDuration The duration in seconds to lock the tokens
     * @param recipient The recipient of the IdeaTokens
     */
    function convertAndBuyInternal(address inputCurrency, address ideaToken, uint input, uint amount, uint cost, uint lockDuration, address recipient) internal {
        if(inputCurrency != address(0)) {
            pullERC20Internal(inputCurrency, msg.sender, input);
        }

        convertInternal(inputCurrency, address(_dai), input, cost);

        if(lockDuration > 0) {
            buyAndLockInternal(ideaToken, amount, cost, lockDuration, recipient);
        } else {
            buyInternal(ideaToken, amount, cost, recipient);
        }

        /*
            If the user has paid with ETH and we had to fallback there will be ETH left.
            Refund the remaining ETH to the user.
        */
        if(address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    /**
     * Buys and locks an IdeaToken in the IdeaTokenVault
     *
     * @param ideaToken The IdeaToken to buy
     * @param amount The amount of IdeaTokens to buy
     * @param cost The cost in Dai for the purchase of `amount` IdeaTokens
     * @param recipient The recipient of the locked IdeaTokens
     */
    function buyAndLockInternal(address ideaToken, uint amount, uint cost, uint lockDuration, address recipient) internal {

        IIdeaTokenVault vault = _ideaTokenVault;
    
        buyInternal(ideaToken, amount, cost, address(this));
        require(IERC20(ideaToken).approve(address(vault), amount), "approve");
        vault.lock(ideaToken, amount, lockDuration, recipient);
    }

    /**
     * Buys an IdeaToken
     *
     * @param ideaToken The IdeaToken to buy
     * @param amount The amount of IdeaTokens to buy
     * @param cost The cost in Dai for the purchase of `amount` IdeaTokens
     * @param recipient The recipient of the bought IdeaTokens 
     */
    function buyInternal(address ideaToken, uint amount, uint cost, address recipient) internal {

        IIdeaTokenExchange exchange = _ideaTokenExchange;

        require(_dai.approve(address(exchange), cost), "approve");
        exchange.buyTokens(ideaToken, amount, amount, cost, recipient);
    }

    /**
     * Adds a new IdeaToken
     *
     * @param tokenName The name of the new token
     * @param marketID The ID of the market where the new token will be added
     *
     * @return The address of the new IdeaToken
     */
    function addTokenInternal(string memory tokenName, uint marketID) internal returns (address) {

        IIdeaTokenFactory factory = _ideaTokenFactory;

        factory.addToken(tokenName, marketID, msg.sender);
        return address(factory.getTokenInfo(marketID, factory.getTokenIDByName(tokenName, marketID) ).ideaToken);
    }

    /**
     * Transfers ERC20 from an address to this contract
     *
     * @param token The ERC20 token to transfer
     * @param from The address to transfer from
     * @param amount The amount of tokens to transfer
     */
    function pullERC20Internal(address token, address from, uint amount) internal {
        require(IERC20(token).allowance(from, address(this)) >= amount, "insufficient-allowance");
        require(IERC20(token).transferFrom(from, address(this), amount), "transfer");
    }

    /**
     * Returns the cost for buying IdeaTokens on a given market from zero supply
     *
     * @param marketID The ID of the market on which the IdeaToken is listed
     * @param amount The amount of IdeaTokens to buy
     *
     * @return The cost for buying IdeaTokens on a given market from zero supply
     */
    function getBuyCostFromZeroSupplyInternal(uint marketID, uint amount) internal view returns (uint) {
        MarketDetails memory marketDetails = _ideaTokenFactory.getMarketDetailsByID(marketID);
        require(marketDetails.exists, "invalid-market");

        return _ideaTokenExchange.getCostsForBuyingTokens(marketDetails, 0, amount, false).total;
    }

    /**
     * Returns the required input to get a given output from an Uniswap swap
     *
     * @param inputCurrency The input currency
     * @param outputCurrency The output currency
     * @param outputAmount The desired output amount 
     *
     * @return The required input to get a `outputAmount` from an Uniswap swap
     */
    function getInputForOutputInternal(address inputCurrency, address outputCurrency, uint outputAmount) internal returns (uint) {
        (,, uint cheapestAmountIn) = getOutputPathInternal(inputCurrency, outputCurrency, outputAmount);
        return cheapestAmountIn;
    }

    /**
     * Returns the Uniswap path from `inputCurrency` to `outputCurrency`
     *
     * @param inputCurrency The input currency
     * @param outputCurrency The output currency
     * @param outputAmount The desired output amount
     *
     * @return The Uniswap path from `outputCurrency` to `inputCurrency`
     */
    function getOutputPathInternal(address inputCurrency, address outputCurrency, uint outputAmount) internal returns (address[] memory, uint24[] memory, uint) {
        inputCurrency = inputCurrency == address(0) ? address(_weth) : inputCurrency;
        outputCurrency = outputCurrency == address(0) ? address(_weth) : outputCurrency;

        address[] memory path = new address[](2);
        uint24[] memory fees = new uint24[](1);
        uint256 cheapestAmountIn;
        uint256 amountIn;

        if(_uniswapV3Factory.getPool(inputCurrency, outputCurrency, LOW_POOL_FEE) != address(0)) {
            path[0] = inputCurrency;
            path[1] = outputCurrency;
            fees[0] = LOW_POOL_FEE;

            try _uniswapV3Quoter.quoteExactOutputSingle(inputCurrency, outputCurrency, LOW_POOL_FEE, outputAmount, 0) returns (uint256 result) {
                cheapestAmountIn = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }
        }
        if(_uniswapV3Factory.getPool(inputCurrency, outputCurrency, MEDIUM_POOL_FEE) != address(0)) {
            try _uniswapV3Quoter.quoteExactOutputSingle(inputCurrency, outputCurrency, MEDIUM_POOL_FEE, outputAmount, 0) returns (uint256 result) {
              amountIn = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }
            
            if(cheapestAmountIn == 0 || amountIn < cheapestAmountIn) {
                cheapestAmountIn = amountIn;
                path[0] = inputCurrency;
                path[1] = outputCurrency;
                fees[0] = MEDIUM_POOL_FEE;
            }
        }
        if(_uniswapV3Factory.getPool(inputCurrency, outputCurrency, HIGH_POOL_FEE) != address(0)) {
            try _uniswapV3Quoter.quoteExactOutputSingle(inputCurrency, outputCurrency, HIGH_POOL_FEE, outputAmount, 0) returns (uint256 result) {
              amountIn = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

            if(cheapestAmountIn == 0 || amountIn < cheapestAmountIn) {
                cheapestAmountIn = amountIn;
                path[0] = inputCurrency;
                path[1] = outputCurrency;
                fees[0] = HIGH_POOL_FEE;
            }
        }
        /*if(cheapestAmountIn != 0) { 
            return (path, fees, cheapestAmountIn);
        }*/

        // Direct path does not exist
        // Check for 3-hop path: input -> weth -> output
        uint24[] memory hopFees = new uint24[](2);
        uint cheapestAmountInForWethToDai;
        if(_uniswapV3Factory.getPool(address(_weth), outputCurrency, LOW_POOL_FEE) != address(0)) {
            hopFees[1] = LOW_POOL_FEE;
            try _uniswapV3Quoter.quoteExactOutputSingle(address(_weth), outputCurrency, LOW_POOL_FEE, outputAmount, 0) returns (uint256 result) {
              cheapestAmountInForWethToDai = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }
        } 
        if(_uniswapV3Factory.getPool(address(_weth), outputCurrency, MEDIUM_POOL_FEE) != address(0)){
            try _uniswapV3Quoter.quoteExactOutputSingle(address(_weth), outputCurrency, MEDIUM_POOL_FEE, outputAmount, 0) returns (uint256 result) {
              amountIn = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

            if(cheapestAmountInForWethToDai == 0 || amountIn < cheapestAmountInForWethToDai) {
                hopFees[1] = MEDIUM_POOL_FEE;
                cheapestAmountInForWethToDai = amountIn;
            }
        }
        if(_uniswapV3Factory.getPool(address(_weth), outputCurrency, HIGH_POOL_FEE) != address(0)) {
            try _uniswapV3Quoter.quoteExactOutputSingle(address(_weth), outputCurrency, HIGH_POOL_FEE, outputAmount, 0) returns (uint256 result) {
              amountIn = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

            if(cheapestAmountInForWethToDai == 0 || amountIn < cheapestAmountInForWethToDai) {
                hopFees[1] = HIGH_POOL_FEE;
                cheapestAmountInForWethToDai = amountIn;
            }
        }
        if (cheapestAmountIn == 0 && cheapestAmountInForWethToDai == 0) {
            revert("no-path");
        }
        uint cheapestAmountInForWeth;
        if (cheapestAmountInForWethToDai != 0) {
            if(_uniswapV3Factory.getPool(inputCurrency, address(_weth), LOW_POOL_FEE) != address(0)) {
                hopFees[0] = LOW_POOL_FEE;
                try _uniswapV3Quoter.quoteExactOutputSingle(inputCurrency, address(_weth), LOW_POOL_FEE, cheapestAmountInForWethToDai, 0) returns (uint256 result) {
                  cheapestAmountInForWeth = result;
                } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }
            }
            if(_uniswapV3Factory.getPool(inputCurrency, address(_weth), MEDIUM_POOL_FEE) != address(0)) {
                try _uniswapV3Quoter.quoteExactOutputSingle(inputCurrency, address(_weth), MEDIUM_POOL_FEE, cheapestAmountInForWethToDai, 0) returns (uint256 result) {
                  amountIn = result;
                } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

                if(cheapestAmountInForWeth == 0 || amountIn < cheapestAmountInForWeth) {
                    hopFees[0] = MEDIUM_POOL_FEE;
                    cheapestAmountInForWeth = amountIn;
                }
            }
            if(_uniswapV3Factory.getPool(inputCurrency, address(_weth), HIGH_POOL_FEE) != address(0)) {
                try _uniswapV3Quoter.quoteExactOutputSingle(inputCurrency, address(_weth), HIGH_POOL_FEE, cheapestAmountInForWethToDai, 0) returns (uint256 result) {
                  amountIn = result;
                } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

                if(cheapestAmountInForWeth == 0 || amountIn < cheapestAmountInForWeth) {
                    hopFees[0] = HIGH_POOL_FEE;
                    cheapestAmountInForWeth = amountIn;
                }
            }
        }
        if (cheapestAmountIn == 0 && cheapestAmountInForWeth == 0) { 
            revert("no-path");
        }
        // 3-hop path does not exist return two hop path
        if (cheapestAmountInForWeth == 0 || cheapestAmountInForWethToDai == 0) {
            return (path, fees, cheapestAmountIn);
        }
        address[] memory hopPath = new address[](3);
        hopPath[0] = inputCurrency;
        hopPath[1] = address(_weth);
        hopPath[2] = outputCurrency;
        // Exact Output Multihop Swap requires path to be encoded in reverse
        bytes memory encodedPath = abi.encodePacked(hopPath[2], hopFees[1], hopPath[1], hopFees[0], hopPath[0]);
        cheapestAmountInForWeth = _uniswapV3Quoter.quoteExactOutput(encodedPath, outputAmount);
        // check whether 3-hop path is cheaper or single hop doesnt exist
        if (cheapestAmountInForWeth < cheapestAmountIn || cheapestAmountIn == 0) {
            return (hopPath, hopFees, cheapestAmountInForWeth); 
        }
        return (path, fees, cheapestAmountIn);
    }

    /**
     * Returns the output for a given input for an Uniswap swap
     *
     * @param inputCurrency The input currency
     * @param outputCurrency The output currency
     * @param inputAmount The desired input amount 
     *
     * @return The output for `inputAmount` for an Uniswap swap
     */
    function getOutputForInputInternal(address inputCurrency, address outputCurrency, uint inputAmount) internal returns (uint) {
        (,, uint cheapestAmountOut) = getInputPathInternal(inputCurrency, outputCurrency, inputAmount);
        return cheapestAmountOut;
    }

    /**
     * Returns the Uniswap path from `inputCurrency` to `outputCurrency`
     *
     * @param inputCurrency The input currency
     * @param outputCurrency The output currency
     *
     * @return The Uniswap path from `inputCurrency` to `outputCurrency`
     */
    function getInputPathInternal(address inputCurrency, address outputCurrency, uint inputAmount) internal returns (address[] memory, uint24[] memory, uint) {
        inputCurrency = inputCurrency == address(0) ? address(_weth) : inputCurrency;
        outputCurrency = outputCurrency == address(0) ? address(_weth) : outputCurrency;

        address[] memory path = new address[](2);
        uint24[] memory fees = new uint24[](1);
        uint256 cheapestAmountOut;
        uint256 amountOut;

        if(_uniswapV3Factory.getPool(inputCurrency, outputCurrency, LOW_POOL_FEE) != address(0)) {
            path[0] = inputCurrency;
            path[1] = outputCurrency;
            fees[0] = LOW_POOL_FEE;

            try _uniswapV3Quoter.quoteExactInputSingle(inputCurrency, outputCurrency, LOW_POOL_FEE, inputAmount, 0) returns (uint256 result) {
              cheapestAmountOut = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }
        }
        if(_uniswapV3Factory.getPool(inputCurrency, outputCurrency, MEDIUM_POOL_FEE) != address(0)) {
            try _uniswapV3Quoter.quoteExactInputSingle(inputCurrency, outputCurrency, MEDIUM_POOL_FEE, inputAmount, 0) returns (uint256 result) {
              amountOut = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

            if(amountOut > cheapestAmountOut) {
                cheapestAmountOut = amountOut;
                path[0] = inputCurrency;
                path[1] = outputCurrency;
                fees[0] = MEDIUM_POOL_FEE;
            }
        }
        if(_uniswapV3Factory.getPool(inputCurrency, outputCurrency, HIGH_POOL_FEE) != address(0)) {
            try _uniswapV3Quoter.quoteExactInputSingle(inputCurrency, outputCurrency, HIGH_POOL_FEE, inputAmount, 0) returns (uint256 result) {
              amountOut = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

            if(amountOut > cheapestAmountOut) {
                cheapestAmountOut = amountOut;
                path[0] = inputCurrency;
                path[1] = outputCurrency;
                fees[0] = HIGH_POOL_FEE;
            }
        }

        // Direct path does not exist
        // Check for 3-hop path: input -> weth -> output
        uint24[] memory hopFees = new uint24[](2);
        uint cheapestAmountOutForInputToWeth;
        if(_uniswapV3Factory.getPool(inputCurrency, address(_weth), LOW_POOL_FEE) != address(0)) {
            hopFees[0] = LOW_POOL_FEE;
            try _uniswapV3Quoter.quoteExactInputSingle(inputCurrency, address(_weth), LOW_POOL_FEE, inputAmount, 0) returns (uint256 result) {
              cheapestAmountOutForInputToWeth = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }
        } 
        if(_uniswapV3Factory.getPool(inputCurrency, address(_weth), MEDIUM_POOL_FEE) != address(0)) {
            try _uniswapV3Quoter.quoteExactInputSingle(inputCurrency, address(_weth), MEDIUM_POOL_FEE, inputAmount, 0) returns (uint256 result) {
              amountOut = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

            if(amountOut > cheapestAmountOutForInputToWeth) {
                hopFees[0] = MEDIUM_POOL_FEE;
                cheapestAmountOutForInputToWeth = amountOut;
            }
        }
        if(_uniswapV3Factory.getPool(inputCurrency, address(_weth), HIGH_POOL_FEE) != address(0)) {
            try _uniswapV3Quoter.quoteExactInputSingle(inputCurrency, address(_weth), HIGH_POOL_FEE, inputAmount, 0) returns (uint256 result) {
              amountOut = result;
            } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

            if(amountOut > cheapestAmountOutForInputToWeth) {
                hopFees[0] = HIGH_POOL_FEE;
                cheapestAmountOutForInputToWeth = amountOut;
            }
        } 

        if (cheapestAmountOut == 0 && cheapestAmountOutForInputToWeth == 0) {
            revert("no-path");
        }

        uint cheapestAmountOutForWeth;
        if (cheapestAmountOutForInputToWeth != 0) {
            if(_uniswapV3Factory.getPool(address(_weth), outputCurrency, LOW_POOL_FEE) != address(0)) {
                hopFees[1] = LOW_POOL_FEE;
                try _uniswapV3Quoter.quoteExactInputSingle(address(_weth), outputCurrency, LOW_POOL_FEE, cheapestAmountOutForInputToWeth, 0) returns (uint256 result) {
                  cheapestAmountOutForWeth = result;
                } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }
            }
            if(_uniswapV3Factory.getPool(address(_weth), outputCurrency, MEDIUM_POOL_FEE) != address(0)) {
                try _uniswapV3Quoter.quoteExactInputSingle(address(_weth), outputCurrency, MEDIUM_POOL_FEE, cheapestAmountOutForInputToWeth, 0) returns (uint256 result) {
                  amountOut = result;
                } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

                if(amountOut > cheapestAmountOutForWeth) {
                    hopFees[1] = MEDIUM_POOL_FEE;
                    cheapestAmountOutForWeth = amountOut;
                }
            }
            if(_uniswapV3Factory.getPool(address(_weth), outputCurrency, HIGH_POOL_FEE) != address(0)) {
                try _uniswapV3Quoter.quoteExactInputSingle(address(_weth), outputCurrency, HIGH_POOL_FEE, cheapestAmountOutForInputToWeth, 0) returns (uint256 result) {
                  amountOut = result;
                } catch Error(string memory /*reason*/) { } catch (bytes memory /*lowLevelData*/) { }

                if(amountOut > cheapestAmountOutForWeth) {
                    hopFees[1] = HIGH_POOL_FEE;
                    cheapestAmountOutForWeth = amountOut;
                }
            }
        }

        if (cheapestAmountOut == 0 && cheapestAmountOutForWeth == 0) { 
            revert("no-path");
        }
        // if 3-hop path does not exist return single hop
        if (cheapestAmountOutForWeth == 0 || cheapestAmountOutForInputToWeth == 0){
            return (path, fees, cheapestAmountOut);
        }
        // 3-hop path exists
        address[] memory hopPath = new address[](3);
        hopPath[0] = inputCurrency;
        hopPath[1] = address(_weth);
        hopPath[2] = outputCurrency;
        bytes memory encodedPath = abi.encodePacked(hopPath[0], hopFees[0], hopPath[1], hopFees[1], hopPath[2]);
        cheapestAmountOutForWeth = _uniswapV3Quoter.quoteExactInput(encodedPath, inputAmount);
        // check whether output is greater for 3-hop path
        if (cheapestAmountOutForWeth > cheapestAmountOut) {
            return (hopPath, hopFees, cheapestAmountOutForWeth);
        }
        return (path, fees, cheapestAmountOut);
    }

    /**
     * Converts from `inputCurrency` to `outputCurrency` using Uniswap
     *
     * @param inputCurrency The input currency
     * @param outputCurrency The output currency
     * @param inputAmount The input amount
     * @param outputAmount The output amount
     */
    function convertInternal(address inputCurrency, address outputCurrency, uint inputAmount, uint outputAmount) internal {
        
        IWETH weth = _weth;
        ISwapRouter router = _uniswapV3SwapRouter;

        (address[] memory path, uint24[] memory fees, ) = getInputPathInternal(inputCurrency, outputCurrency, inputAmount);
    
        IERC20 inputERC20;
        if(inputCurrency == address(0)) {
            // If the input is ETH we convert to WETH
            weth.deposit{value: inputAmount}();
            inputERC20 = IERC20(address(weth));
        } else {
            inputERC20 = IERC20(inputCurrency);
        }

        require(inputERC20.approve(address(router), inputAmount), "router-approve");

        if(path.length == 2 && fees.length == 1) {
            ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: path[0],
                tokenOut: path[1],
                fee: fees[0],
                recipient: address(this),
                deadline: block.timestamp + 1,
                amountIn: inputAmount,
                amountOutMinimum: outputAmount,
                sqrtPriceLimitX96: 0
            });
            router.exactInputSingle(params);
        }
        else { 
            bytes memory encodedPath = abi.encodePacked(path[0], fees[0], path[1], fees[1], path[2]);
            ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: encodedPath,
                recipient: address(this),
                deadline: block.timestamp + 1,
                amountIn: inputAmount,
                amountOutMinimum: outputAmount
            });
            router.exactInput(params);
        }

        if(outputCurrency == address(0)) {
            // If the output is ETH we withdraw from WETH
            weth.withdraw(outputAmount);
        }
    }

    /**
     * Fallback required for WETH withdraw. Fails if sender is not WETH contract
     */
    receive() external payable {
        require(msg.sender == address(_weth));
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

/**
 * @title IIdeaToken
 * @author Alexander Schlindwein
 *
 * @dev Simplified interface for WETH
 */
interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.9;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    function factory() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "./IIdeaTokenFactory.sol";

/**
 * @title IIdeaTokenExchange
 * @author Alexander Schlindwein
 */

struct CostAndPriceAmounts {
    uint total;
    uint raw;
    uint tradingFee;
    uint platformFee;
}

interface IIdeaTokenExchange {
    function sellTokens(address ideaToken, uint amount, uint minPrice, address recipient) external;
    function getPriceForSellingTokens(address ideaToken, uint amount) external view returns (uint);
    function getPricesForSellingTokens(MarketDetails memory marketDetails, uint supply, uint amount, bool feesDisabled) external pure returns (CostAndPriceAmounts memory);
    function buyTokens(address ideaToken, uint amount, uint fallbackAmount, uint cost, address recipient) external;
    function getCostForBuyingTokens(address ideaToken, uint amount) external view returns (uint);
    function getCostsForBuyingTokens(MarketDetails memory marketDetails, uint supply, uint amount, bool feesDisabled) external pure returns (CostAndPriceAmounts memory);
    function setTokenOwner(address ideaToken, address owner) external;
    function setPlatformOwner(uint marketID, address owner) external;
    function withdrawTradingFee() external;
    function withdrawTokenInterest(address token) external;
    function withdrawPlatformInterest(uint marketID) external;
    function withdrawPlatformFee(uint marketID) external;
    function getInterestPayable(address token) external view returns (uint);
    function getPlatformInterestPayable(uint marketID) external view returns (uint);
    function getPlatformFeePayable(uint marketID) external view returns (uint);
    function getTradingFeePayable() external view returns (uint);
    function setAuthorizer(address authorizer) external;
    function isTokenFeeDisabled(address ideaToken) external view returns (bool);
    function setTokenFeeKillswitch(address ideaToken, bool set) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IIdeaToken.sol";
import "../nameVerifiers/IIdeaTokenNameVerifier.sol";

/**
 * @title IIdeaTokenFactory
 * @author Alexander Schlindwein
 */

struct IDPair {
    bool exists;
    uint marketID;
    uint tokenID;
}

struct TokenInfo {
    bool exists;
    uint id;
    string name;
    IIdeaToken ideaToken;
}

struct MarketDetails {
    bool exists;
    uint id;
    string name;

    IIdeaTokenNameVerifier nameVerifier;
    uint numTokens;

    uint baseCost;
    uint priceRise;
    uint hatchTokens;
    uint tradingFeeRate;
    uint platformFeeRate;

    bool allInterestToPlatform;
}

interface IIdeaTokenFactory {
    function addMarket(string calldata marketName, address nameVerifier,
                       uint baseCost, uint priceRise, uint hatchTokens,
                       uint tradingFeeRate, uint platformFeeRate, bool allInterestToPlatform) external;

    function addToken(string calldata tokenName, uint marketID, address lister) external;

    function isValidTokenName(string calldata tokenName, uint marketID) external view returns (bool);
    function getMarketIDByName(string calldata marketName) external view returns (uint);
    function getMarketDetailsByID(uint marketID) external view returns (MarketDetails memory);
    function getMarketDetailsByName(string calldata marketName) external view returns (MarketDetails memory);
    function getMarketDetailsByTokenAddress(address ideaToken) external view returns (MarketDetails memory);
    function getNumMarkets() external view returns (uint);
    function getTokenIDByName(string calldata tokenName, uint marketID) external view returns (uint);
    function getTokenInfo(uint marketID, uint tokenID) external view returns (TokenInfo memory);
    function getTokenIDPair(address token) external view returns (IDPair memory);
    function setTradingFee(uint marketID, uint tradingFeeRate) external;
    function setPlatformFee(uint marketID, uint platformFeeRate) external;
    function setNameVerifier(uint marketID, address nameVerifier) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title IIdeaTokenVault
 * @author Alexander Schlindwein
 */

struct LockedEntry {
    uint lockedUntil;
    uint lockedAmount;
}
    
interface IIdeaTokenVault {
    function lock(address ideaToken, uint amount, uint duration, address recipient) external;
    function withdraw(address ideaToken, uint[] calldata untils, address recipient) external;
    function getLockedEntries(address ideaToken, address user, uint maxEntries) external view returns (LockedEntry[] memory);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IIdeaToken
 * @author Alexander Schlindwein
 */
interface IIdeaToken is IERC20 {
    function initialize(string calldata __name, address owner) external;
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

/**
 * @title IIdeaTokenNameVerifier
 * @author Alexander Schlindwein
 *
 * Interface for token name verifiers
 */
interface IIdeaTokenNameVerifier {
    function verifyTokenName(string calldata name) external pure returns (bool);
}