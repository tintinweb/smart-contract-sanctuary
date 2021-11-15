// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../Token/ERC20/IERC20.sol";

// TODO. Mañana comentar todas las funciones...

contract XifraICO {

    address immutable private xifraWallet;                      // Xifra wallet
    address immutable private xifraToken;                       // Xifra token address
    address immutable private usdtToken;                        // USDT token address
    address immutable private usdcToken;                        // USDC token address
    uint256 immutable private minTokensBuyAllowed;              // Minimum tokens allowed
    uint256 immutable private maxICOTokens;                     // Max ICO tokens to sell
    uint256 immutable private icoMaxDate;                       // ICO Max date
    AggregatorV3Interface internal priceFeed;                   // Chainlink price feeder ETH/USD

    uint256 public icoTokensBought;                             // Tokens sold
    uint256 public tokenListingDate;                            // Token listing date
    mapping(address => uint256) private userBoughtTokens;       // Mapping to store all the buys
    mapping(address => uint256) private userWithdrawTokens;     // Mapping to store the user tokens withdraw

    bool private icoFinished;
    uint32 internal constant _1_MONTH_IN_SECONDS = 2592000;
    uint32 internal constant _2_MONTHS_IN_SECONDS = 2 * _1_MONTH_IN_SECONDS;
    uint32 internal constant _4_MONTHS_IN_SECONDS = 4 * _1_MONTH_IN_SECONDS;
    uint32 internal constant _6_MONTHS_IN_SECONDS = 6 * _1_MONTH_IN_SECONDS;
    uint32 internal constant _9_MONTHS_IN_SECONDS = 9 * _1_MONTH_IN_SECONDS;
    uint32 internal constant _12_MONTHS_IN_SECONDS = 12 * _1_MONTH_IN_SECONDS;

    uint256 internal constant _MIN_COINS_FOR_VESTING = 53333 * 10 ** 18;

    event onTokensBought(address _buyer, uint256 _tokens, uint256 _paymentAmount, address _tokenPayment);
    event onWithdrawICOFunds(uint256 _usdtBalance, uint256 _usdcBalance, uint256 _ethbalance);
    event onWithdrawBoughtTokens(address _user, uint256 _maxTokensAllowed);
    event onICOFinished(uint256 _date);

    /**
     * @notice Constructor
     * @param _wallet               --> Xifra master wallet
     * @param _token                --> Xifra token address
     * @param _icoMaxDate           --> ICO end date
     * @param _usdtToken            --> USDT token address
     * @param _usdcToken            --> USDC token address
     * @param _minTokensBuyAllowed  --> Minimal amount of tokens allowed to buy
     * @param _maxICOTokens         --> Number of tokens selling in this ICO
     * @param _tokenListingDate     --> Token listing date for the ICO vesting
     */
    constructor(address _wallet, address _token, uint256 _icoMaxDate, address _usdtToken, address _usdcToken, uint256 _minTokensBuyAllowed, uint256 _maxICOTokens, uint256 _tokenListingDate) {
        xifraWallet = _wallet;
        xifraToken = _token;
        icoMaxDate = _icoMaxDate;
        usdtToken = _usdtToken;
        usdcToken = _usdcToken;
        minTokensBuyAllowed = _minTokensBuyAllowed;
        maxICOTokens = _maxICOTokens;
        /* TODO. Change for mainnet deployment
        if (_getChainId() == 1) priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        else if (_getChainId() == 4) priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        */
        if (_getChainId() == 1) priceFeed = AggregatorV3Interface(0x0000000000000000000000000000000000000000);
        else if (_getChainId() == 4) priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        tokenListingDate = _tokenListingDate;
    }

    /**
     * @notice Buy function. Used to buy tokens using ETH, USDT or USDC
     * @param _paymentAmount    --> Result of multiply number of tokens to buy per price per token. Must be always multiplied per 1000 to avoid decimals 
     * @param _tokenPayment     --> Address of the payment token (or 0x0 if payment is ETH)
     */
    function buy(uint256 _paymentAmount, address _tokenPayment) external payable {
        require(_isICOActive() == true, "ICONotActive");
               
        uint256 paidTokens = 0;

        if (msg.value == 0) {
            // Stable coin payment
            require(_paymentAmount > 0, "BadPayment");
            require(_tokenPayment == usdtToken || _tokenPayment == usdcToken, "TokenNotSupported");
            require(IERC20(_tokenPayment).transferFrom(msg.sender, address(this), _paymentAmount));
            paidTokens = _paymentAmount * 2666666666666666667 / 1000000000000000000;   // 0.375$ per token in the ICO
        } else {
            // ETH Payment
            uint256 usdETH = _getUSDETHPrice();
            uint256 paidUSD = msg.value * usdETH / 10**18;
            paidTokens = paidUSD * 2666666666666666666 / 1000000000000000000;   // 0.375$ per token in the ICO
        }

        require((paidTokens + 1*10**18) >= minTokensBuyAllowed, "BadTokensQuantity");    // One extra token as threshold rounding decimals
        require(maxICOTokens - icoTokensBought >= paidTokens, "NoEnoughTokensInICO");
        userBoughtTokens[msg.sender] += paidTokens;
        icoTokensBought += paidTokens;
        if (maxICOTokens - icoTokensBought < minTokensBuyAllowed) {
            // We finish the ICO
            icoFinished = true;
            emit onICOFinished(block.timestamp);
        }

        emit onTokensBought(msg.sender, paidTokens, _paymentAmount, _tokenPayment);
    }

    /**
     * @notice Withdraw user tokens when the vesting rules allow it
     */
    function withdrawBoughtTokens() external {
        require(_isICOActive() == false, "ICONotActive");
        require(userBoughtTokens[msg.sender] > 0, "NoBalance");
        require(block.timestamp >= tokenListingDate, "TokenNoListedYet");

        uint256 boughtBalance = userBoughtTokens[msg.sender];
        uint256 maxTokensAllowed = 0;
        if ((block.timestamp >= tokenListingDate) && (block.timestamp < tokenListingDate + _2_MONTHS_IN_SECONDS)) {
            if (boughtBalance <= _MIN_COINS_FOR_VESTING) {
                maxTokensAllowed = boughtBalance;
            } else {
                uint maxTokens = boughtBalance * 20 / 100;
                if (userWithdrawTokens[msg.sender] < maxTokens) {
                    maxTokensAllowed = maxTokens - userWithdrawTokens[msg.sender];
                }
            }
        } else if ((block.timestamp >= tokenListingDate + _2_MONTHS_IN_SECONDS) && (block.timestamp < tokenListingDate + _4_MONTHS_IN_SECONDS)) {
            uint256 maxTokens = boughtBalance * 30 / 100;
            if (userWithdrawTokens[msg.sender] < maxTokens) {
                maxTokensAllowed = maxTokens - userWithdrawTokens[msg.sender];
            }
        } else if ((block.timestamp >= tokenListingDate + _4_MONTHS_IN_SECONDS) && (block.timestamp < tokenListingDate + _6_MONTHS_IN_SECONDS)) {
            uint256 maxTokens = boughtBalance * 50 / 100;
            if (userWithdrawTokens[msg.sender] < maxTokens) {
                maxTokensAllowed = maxTokens - userWithdrawTokens[msg.sender];
            }
        } else if ((block.timestamp >= tokenListingDate + _6_MONTHS_IN_SECONDS) && (block.timestamp < tokenListingDate + _9_MONTHS_IN_SECONDS)) {
            uint256 maxTokens = boughtBalance * 60 / 100;
            if (userWithdrawTokens[msg.sender] < maxTokens) {
                maxTokensAllowed = maxTokens - userWithdrawTokens[msg.sender];
            }
        } else if ((block.timestamp >= tokenListingDate + _9_MONTHS_IN_SECONDS) && (block.timestamp < tokenListingDate + _12_MONTHS_IN_SECONDS)) {
            uint256 maxTokens = boughtBalance * 80 / 100;
            if (userWithdrawTokens[msg.sender] < maxTokens) {
                maxTokensAllowed = maxTokens - userWithdrawTokens[msg.sender];
            }
        } else {
            uint256 maxTokens = boughtBalance;
            if (userWithdrawTokens[msg.sender] < maxTokens) {
                maxTokensAllowed = maxTokens - userWithdrawTokens[msg.sender];
            }
        }

        require(maxTokensAllowed > 0, "NoTokensToWithdraw");

        userWithdrawTokens[msg.sender] += maxTokensAllowed;
        require(IERC20(xifraToken).transfer(msg.sender, maxTokensAllowed));

        emit onWithdrawBoughtTokens(msg.sender, maxTokensAllowed);
    }

    /**
     * @notice Returns the crypto numbers and balance in the ICO contract
     */
    function withdrawICOFunds() external {
        require(_isICOActive() == false, "ICONotActive");
        
        uint256 usdtBalance = IERC20(usdtToken).balanceOf(address(this));
        require(IERC20(usdtToken).transfer(xifraWallet, usdtBalance));

        uint256 usdcBalance = IERC20(usdcToken).balanceOf(address(this));
        require(IERC20(usdcToken).transfer(xifraWallet, usdcBalance));

        uint256 ethbalance = address(this).balance;
        payable(xifraWallet).transfer(ethbalance);

        emit onWithdrawICOFunds(usdtBalance, usdcBalance, ethbalance);
    }

    /**
     * @notice Withdraw the unsold Xifra tokens to the Xifra wallet when the ICO is finished
     */
    function withdrawICOTokens() external {
        require(_isICOActive() == false, "ICONotActive");
        require(msg.sender == xifraWallet, "OnlyXifra");

        uint256 balance = maxICOTokens - icoTokensBought;
        require(IERC20(xifraToken).transfer(xifraWallet, balance));
    }

    /**
     * @notice OnlyOwner function. Change the listing date to start the vesting
     * @param _tokenListDate --> New listing date in UnixDateTime UTC format
     */
    function setTokenListDate(uint256 _tokenListDate) external {
        require(msg.sender == xifraWallet, "BadOwner");
        require(block.timestamp <= tokenListingDate, "TokenListedYet");

        tokenListingDate = _tokenListDate;
    }

    /**
     * @notice Returns the number of tokens and user has bought
     * @param _user --> User account
     * @return Returns the user token balance in wei units
     */
    function getUserBoughtTokens(address _user) external view returns(uint256) {
        return userBoughtTokens[_user];
    }

    /**
     * @notice Returns the number of tokens and user has withdrawn
     * @param _user --> User account
     * @return Returns the user token withdrawns in wei units
     */
    function getUserWithdrawnTokens(address _user) external view returns(uint256) {
        return userWithdrawTokens[_user];
    }

    /**
     * @notice Returns the crypto numbers in the ICO
     * @return xifra Returns the Xifra tokens balance in the contract
     * @return eth Returns the ETHs balance in the contract
     * @return usdt Returns the USDTs balance in the contract
     * @return usdc Returns the USDCs balance in the contract
     */
    function getICOData() external view returns(uint256 xifra, uint256 eth, uint256 usdt, uint256 usdc) {
        xifra = IERC20(xifraToken).balanceOf(address(this));
        usdt = IERC20(usdtToken).balanceOf(address(this));
        usdc = IERC20(usdcToken).balanceOf(address(this));
        eth = address(this).balance;
    }

    /**
     * @notice Traslate a payment in USD to ETHs
     * @param _paymentAmount --> Payment amount in USD
     * @return Returns the ETH amount in weis
     */
    function calculateETHPayment(uint256 _paymentAmount) external view returns(uint256) {
        uint256 usdETH = _getUSDETHPrice();
        return (_paymentAmount * 10 ** 18) / usdETH;
    }

    /**
     * @notice Get the vesting unlock dates
     * @param _period --> There are 6 periods (0,1,2,3,4,5)
     * @return _date Returns the date in UnixDateTime UTC format
     */
    function getVestingDate(uint256 _period) external view returns(uint256 _date) {
        if (_period == 0) {
            _date = tokenListingDate;
        } else if (_period == 1) {
            _date = tokenListingDate + _2_MONTHS_IN_SECONDS;
        } else if (_period == 2) {
            _date = tokenListingDate + _4_MONTHS_IN_SECONDS;
        } else if (_period == 3) {
            _date = tokenListingDate + _6_MONTHS_IN_SECONDS;
        } else if (_period == 4) {
            _date = tokenListingDate + _9_MONTHS_IN_SECONDS;
        } else if (_period == 5) {
            _date = tokenListingDate + _12_MONTHS_IN_SECONDS;
        }
    }

    /**
     * @notice Public function that returns ETHUSD par
     * @return Returns the how much USDs are in 1 ETH in weis
     */
    function getUSDETHPrice() external view returns(uint256) {
        return _getUSDETHPrice();
    }

    /**
     * @notice Uses Chainlink to query the USDETH price
     * @return Returns the ETH amount in weis (Fixed value of 3932.4 USDs in localhost development environments)
     */
    function _getUSDETHPrice() internal view returns(uint256) {
        int price = 0;

        if (address(priceFeed) != address(0)) {
            (, price, , , ) = priceFeed.latestRoundData();
        } else {
            // For local testing
            price = 393240000000;
        }

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
        if ((block.timestamp > icoMaxDate) || (icoFinished == true)) return false;
        else return true;
    }

    /**
     * @notice External - Is ICO active?
     * @return Returns true or false
     */
    function isICOActive() external view returns(bool) {
        return _isICOActive();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

