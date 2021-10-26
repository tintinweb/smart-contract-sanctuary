// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IBlizztFarm.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/ILiquidityPoolLocker.sol";

contract BlizztICO {

    address immutable private blizztWallet;                     // Blizzt master wallet
    address immutable private blizztToken;                      // Blizzt token address
    address immutable private blizztFarm;                       // Blizzt ICO farm
    address immutable private liquidityPoolLocker;              // Uniswap LP locker
    uint256 immutable private maxICOTokens;                     // Max ICO tokens to sell
    uint256 immutable private icoStartDate;                     // ICO start date
    uint256 immutable private icoEndDate;                       // ICO end date
    uint256 immutable private tokensPerDollar;                  // ICO tokens per $ invested
    AggregatorV3Interface private priceFeedMATICUSD;            // Chainlink price feeder MATIC/USD
    IUniswapV2Router02 immutable private uniswapRouter;

    uint256 public icoTokensBought;                             // Tokens sold
    uint256 public tokenListingDate;                            // Token listing date

    uint64 private icoFinishedDate;
    uint32 internal constant _1_YEAR_BLOCKS = 2300000;          // Calculated with an average of 6400 blocks/day

    event onTokensBought(address _buyer, uint256 _tokens, uint256 _paymentAmount);
    event onWithdrawICOFunds(uint256 _maticbalance);
    event onICOFinished(uint256 _date);
    event onTokenListed(uint256 _ethOnUniswap, uint256 _tokensOnUniswap, address _lpToken, uint256 _date);

    /**
     * @notice Constructor
     * @param _wallet               --> Blizzt master wallet
     * @param _token                --> Blizzt token address
     * @param _liquidityPoolLocker  --> Uniswap LP locker
     * @param _icoStartDate         --> ICO start date
     * @param _icoEndDate           --> ICO end date
     * @param _maxICOTokens         --> Number of tokens selling in this ICO
     * @param _tokensPerDollar      --> 
     * @param _uniswapRouter        -->
     */
    constructor(address _wallet, address _token, address _farm, address _liquidityPoolLocker, uint256 _icoStartDate, uint256 _icoEndDate, uint256 _maxICOTokens, uint256 _tokensPerDollar, address _uniswapRouter) {
        blizztWallet = _wallet;
        blizztToken = _token;
        blizztFarm = _farm;
        liquidityPoolLocker = _liquidityPoolLocker;
        icoStartDate = _icoStartDate;
        icoEndDate = _icoEndDate;
        maxICOTokens = _maxICOTokens;
        tokensPerDollar = _tokensPerDollar;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        _setPriceFeeders();

        IERC20(_token).approve(_farm, _maxICOTokens);
    }

    /**
     * @notice Buy function. Used to buy tokens using MATIC
     */
    function buy() external payable {
        _buy();
    }

    /**
    * @notice This function automates the token listing in Quickswap
    * and initializes the rewards farm for the ICO buyers
    */  
    function listTokenInUniswapAndStake() external {
        require(_isICOActive() == false, "ico is not ended");
        require(tokenListingDate == 0, "the bonus offering and uniswap paring can only be done once per ISO");
        //require(block.timestamp > icoFinishedDate + 30 days, "30 days until listing");    // TODO. Removed for testing

        (uint256 ethOnUniswap, uint256 tokensOnUniswap, address lpToken) = _createUniswapPair(); 
        
        tokenListingDate = block.timestamp;

        payable(blizztWallet).transfer(address(this).balance);
        
        _setupFarm();
        
        emit onTokenListed(ethOnUniswap, tokensOnUniswap, lpToken, block.timestamp);
    }

    /**
    * @notice Call by anyone if the ICO finish without sell all the tokens
    */  
    function closeICO() external {
        if ((block.timestamp > icoEndDate) && (icoFinishedDate == 0)) {
            icoFinishedDate = uint64(icoEndDate);
        }
    }

    /**
     * @notice Returns the number of tokens and user has bought
     * @param _user --> User account
     * @return Returns the user token balance in wei units
     */
    function getUserBoughtTokens(address _user) external view returns(uint256) {
        return IBlizztFarm(blizztFarm).deposited(_user);
    }

    /**
     * @notice Returns the crypto numbers in the ICO
     * @return blizzt Returns the Blizzt tokens balance in the contract
     * @return matic Returns the MATICs balance in the contract
     */
    function getICOData() external view returns(uint256 blizzt, uint256 matic) {
        blizzt = IERC20(blizztToken).balanceOf(address(this));
        matic = address(this).balance;
    }

    /**
     * @notice Public function that returns ETHUSD par
     * @return Returns the how much USDs are in 1 ETH in weis
     */
    function getUSDMATICPrice() external view returns(uint256) {
        return _getUSDMATICPrice();
    }

    /**
     * @notice External - Is ICO active?
     * @return Returns true or false
     */
    function isICOActive() external view returns(bool) {
        return _isICOActive();
    }

    function _buy() internal {
        require(_isICOActive() == true, "ICONotActive");

        // Buy Blizzt tokens with MATIC
        (uint256 tokensBought, uint256 paid, bool icoFinished) = _buyTokensWithMATIC();

        // Send the tokens to the farm contract
        IBlizztFarm(blizztFarm).deposit(msg.sender, tokensBought);
        icoTokensBought += tokensBought;
        
        emit onTokensBought(msg.sender, tokensBought, paid);

        if (icoFinished) {
            icoFinishedDate = uint64(block.timestamp);
            emit onICOFinished(block.timestamp);
        }
    }

    function _buyTokensWithMATIC() internal returns (uint256, uint256, bool) {
        uint256 usdMATIC = _getUSDMATICPrice();
        uint256 amountToPay = msg.value;
        uint256 paidUSD = msg.value * usdMATIC / 10**18;
        uint256 paidTokens = paidUSD * tokensPerDollar;
        uint256 availableTokens = maxICOTokens - icoTokensBought;
        bool lastTokens = (availableTokens < paidTokens);
        if (lastTokens) {
            paidUSD = availableTokens * paidUSD / paidTokens;
            paidTokens = availableTokens;
            amountToPay = paidUSD * 10 ** 18 / usdMATIC;
            
            payable(msg.sender).transfer(msg.value - amountToPay);  // Return ETHs for the tokens user couldn't buy
        }

        return (paidTokens, amountToPay, lastTokens);
    }

    /**
    * @dev This function creates a uniswap pair and handles liquidity provisioning.
    * Returns the uniswap token leftovers.
    */  
    function _createUniswapPair() internal returns (uint256, uint256, address) {     
        uint256 maticOnUniswap = address(this).balance / 3;
        uint256 tokensOnUniswap = icoTokensBought / 3;

        IERC20(blizztToken).approve(address(uniswapRouter), tokensOnUniswap);

        IUniswapV2Factory factory = IUniswapV2Factory(uniswapRouter.factory());
        address lpToken = factory.createPair(blizztToken, uniswapRouter.WETH());

        uniswapRouter.addLiquidityETH{value: maticOnUniswap}(
            blizztToken,
            tokensOnUniswap,
            0,
            0,
            address(this),
            block.timestamp
        );

        // Lock the LP for 1 year to avoid a rug pull from the team
        ILiquidityPoolLocker(liquidityPoolLocker).lockLP(blizztWallet, lpToken);

        return (maticOnUniswap, tokensOnUniswap, lpToken);
    }

    function _setupFarm() internal {
        IBlizztFarm(blizztFarm).initialSetup(block.number, _1_YEAR_BLOCKS);
        IBlizztFarm(blizztFarm).add(1, blizztToken);
        
        // 10% extra rewards for staking in the farm until the end
        uint256 tokensToFarm = icoTokensBought / 10;
        IERC20(blizztToken).approve(blizztFarm, tokensToFarm);
        IBlizztFarm(blizztFarm).fund(tokensToFarm);
    }

    /**
     * @notice Uses Chainlink to query the USDETH price
     * @return Returns the ETH amount in weis
     */
    function _getUSDMATICPrice() internal view returns(uint256) {
        (, int price, , , ) = priceFeedMATICUSD.latestRoundData();

        return uint256(price * 10**10);
    }

    /**
     * @notice Internal function that queries the chainId
     * @return Returns the chainId (1 - Mainnet, 4 - Rinkeby testnet)
     */
    function _getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /**
     * @notice Internal - Is ICO active?
     * @return Returns true or false
     */
    function _isICOActive() internal view returns(bool) {
        if ((block.timestamp < icoStartDate) || (block.timestamp > icoEndDate) || (icoFinishedDate > 0)) return false;
        else return true;
    }

    function _setPriceFeeders() internal {
        uint256 chainId = _getChainId();
        if (chainId == 1) {
            priceFeedMATICUSD = AggregatorV3Interface(0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676);
        } else if (chainId == 4) {
            priceFeedMATICUSD = AggregatorV3Interface(0x7794ee502922e2b723432DDD852B3C30A911F021);
        }
    }

    receive() external payable {
        // Call function buy if someone sends directly ethers to the contract
        _buy();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILiquidityPoolLocker {
    function lockLP(address _owner, address _token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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
pragma solidity ^0.8.7;

interface IBlizztFarm {
    function initialSetup(uint256 _startBlock, uint256 _numBlocks) external;
    function add(uint256 _allocPoint, address _lpToken) external;
    function fund(uint256 _amount) external;
    function deposit(address _user, uint256 _amount) external;
    function deposited(address _user) external view returns (uint256);
}