/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface PriceFeedInterface {
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

pragma solidity 0.8.4;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.4;

contract SmartHoldERC20 {
    address public immutable owner = msg.sender;
    uint256 public immutable createdAt = block.timestamp;
    mapping(string => uint256) public lockForDaysDurations;
    mapping(string => int256) public minExpectedPrices;
    mapping(string => int256) public pricePrecisions;
    mapping(string => address) public priceFeeds;
    mapping(string => address) public tokenAddresses;
    string[] public tokens;

    modifier restricted() {
        require(msg.sender == owner, "Access denied!");
        _;
    }

    function configureToken(
        string memory _symbol,
        address _tokenAddress,
        uint256 _lockForDays,
        address _feedAddress,
        int256 _minExpectedPrice,
        int256 _pricePrecision
    ) public restricted {
        require(_lockForDays > 0, "Invalid lockForDays value.");
        require(_minExpectedPrice >= 0, "Invalid minExpectedPrice value.");

        bool alreadyConfigured = lockForDaysDurations[_symbol] != 0;
        bool correctFeedAddress = !alreadyConfigured ||
            priceFeeds[_symbol] == _feedAddress;
        bool correctNewPrice = !alreadyConfigured ||
            (minExpectedPrices[_symbol] <= _minExpectedPrice);
        require(
            !alreadyConfigured || (correctFeedAddress && correctNewPrice),
            "Price feed already configured"
        );

        if (
            (_feedAddress == address(0) && _minExpectedPrice != 0) ||
            (_minExpectedPrice == 0 && _feedAddress != address(0))
        ) {
            require(false, "Invalid price configuration!");
        }

        if (_feedAddress != address(0)) {
            // check feed address interface
            PriceFeedInterface(_feedAddress).latestRoundData();
        }

        if (!alreadyConfigured) {
            tokens.push(_symbol);
        }

        lockForDaysDurations[_symbol] = _lockForDays;
        tokenAddresses[_symbol] = _tokenAddress;
        priceFeeds[_symbol] = _feedAddress;
        minExpectedPrices[_symbol] = _minExpectedPrice;
        pricePrecisions[_symbol] = _pricePrecision;
    }

    function getPrice(string memory _symbol) public view returns (int256) {
        if (priceFeeds[_symbol] == address(0)) {
            return 0;
        }

        (, int256 price, , , ) = PriceFeedInterface(priceFeeds[_symbol])
        .latestRoundData();
        return price / pricePrecisions[_symbol];
    }

    function canWithdraw(string memory _symbol) public view returns (bool) {
        require(lockForDaysDurations[_symbol] != 0, "Token not yet configured");

        uint256 releaseAt = createdAt +
            (lockForDaysDurations[_symbol] * 1 days);

        if (releaseAt < block.timestamp) {
            return true;
        } else if (minExpectedPrices[_symbol] == 0) {
            return false;
        } else if (minExpectedPrices[_symbol] < getPrice(_symbol)) {
            return true;
        } else return false;
    }

    function checkPriceFeed(address _feedAddress, int256 _precision)
        public
        view
        returns (int256)
    {
        (, int256 price, , , ) = PriceFeedInterface(_feedAddress)
        .latestRoundData();
        return price / _precision;
    }

    function getConfiguredTokensCount() public view returns (uint256) {
        return tokens.length;
    }

    function withdraw(string memory _symbol) external restricted {
        require(canWithdraw(_symbol), "You cannot withdraw yet.");

        if (keccak256(bytes(_symbol)) == keccak256(bytes("ETH"))) {
            payable(owner).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddresses[_symbol]);
            uint256 tokenBalance = token.balanceOf(address(this));
            token.transfer(owner, tokenBalance);
        }
    }

    receive() external payable {}
}