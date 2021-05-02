/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT AND GPL-3.0

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

// File: contracts/dex/interfaces/ICryptoChangeDexV1.sol

pragma solidity >=0.5.16 <0.8.4;

interface ICryptoChangeDexV1 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event ExactEthForTokensSwapped(uint256 amountIn, uint256 amountOut);
    event ExactTokensForEthSwapped(uint256 amountIn, uint256 amountOut);
    event ExactTokensForTokensSwapped(address indexed from, uint256 amountIn, uint256 amountOut);

    event EthDeposited(address indexed from, uint256 amount);

    //    function token() external view returns (address);
}

// File: contracts/dex/libraries/Util.sol

pragma solidity >=0.5.16 <0.8.4;

library Util {
    enum SwapType { ExactEthForTokens, ExactTokensForEth, ExactTokensForTokens }
}

// File: contracts/dex/libraries/CryptoChangeV1Library.sol

pragma solidity >=0.5.16 <0.8.4;

library CryptoChangeV1Library {
    function getAmounts(
        uint256 amount,
        address[] memory path,
        Util.SwapType swapType
    ) internal returns (uint256[] memory amounts) {
        amounts = new uint256[](2);
        if (swapType == Util.SwapType.ExactEthForTokens) {
            amounts[0] = msg.value;
            amounts[1] = amounts[0];
        }
        if (swapType == Util.SwapType.ExactTokensForEth) {
            amounts[0] = amount;
            amounts[1] = amounts[0];
        }
        if (swapType == Util.SwapType.ExactTokensForTokens) {
            amounts[0] = amount;
            amounts[1] = amounts[0];
        }
    }
}

// File: contracts/dex/libraries/CryptoChangeV1Validator.sol

pragma solidity >=0.5.16 <0.8.4;

library CryptoChangeV1Validator {
    function validateSwapExactEthForTokens(uint256[] memory amounts, address[] memory path) internal view {
        uint256 amountIn = amounts[0];
        uint256 amountOut = amounts[1];

        // Input amount must be specified
        require(amountIn > 0, 'CryptoChangeV1Validator: INPUT_ETHER_REQUIRED');
        // 1 token must be present in the path
        require(path.length == 1, 'CryptoChangeV1Validator: INVALID_PATH');

        uint256 dexBalanceForToken = IERC20(path[0]).balanceOf(address(this));
        // The CryptoChange DEX must have enough token in its reserves
        require(amountOut <= dexBalanceForToken, 'CryptoChangeV1Validator: RESERVE_INSUFFICIENT_TOKEN');
    }

    function validateSwapExactTokensForEth(uint256[] memory amounts, address[] memory path) internal view {
        uint256 amountIn = amounts[0];
        uint256 amountOut = amounts[1];

        // Input amount must be specified
        require(amountIn > 0, 'CryptoChangeV1Validator: INPUT_TOKENS_REQUIRED');
        // 1 token must be present in the path
        require(path.length == 1, 'CryptoChangeV1Validator: INVALID_PATH');

        uint256 allowance = IERC20(path[0]).allowance(msg.sender, address(this));
        // The CryptoChange DEX must be allowed to spend the user's tokens
        require(allowance >= amountIn, 'CryptoChangeV1Validator: CHECK_TOKEN_ALLOWANCE');

        // The CryptoChange DEX must have enough ETH in its reserves
        require(address(this).balance >= amountOut, 'CryptoChangeV1Validator: RESERVE_INSUFFICIENT_ETHER');
    }

    function validateSwapExactTokensForTokens(uint256[] memory amounts, address[] memory path) internal view {
        uint256 amountIn = amounts[0];
        uint256 amountOut = amounts[1];

        // Input amount must be specified
        require(amountIn > 0, 'CryptoChangeV1Validator: INPUT_TOKENS_REQUIRED');
        // 2 tokens must be present in the path
        require(path.length == 2, 'CryptoChangeV1Validator: INVALID_PATH');

        address token0 = path[0];
        address token1 = path[1];

        uint256 allowance = IERC20(token0).allowance(msg.sender, address(this));
        // The CryptoChange DEX must be allowed to spend the user's tokens
        require(allowance >= amountIn, 'CryptoChangeV1Validator: CHECK_TOKEN0_ALLOWANCE');

        // The CryptoChange DEX must have enough token1 in its reserves
        require(
            IERC20(token1).balanceOf(address(this)) >= amountOut,
            'CryptoChangeV1Validator: RESERVE_INSUFFICIENT_TOKEN1'
        );
    }
}

// File: contracts/dex/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferEth(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, 'TransferHelper::safeTransferEth: ETH transfer failed');
    }
}

// File: @chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol

pragma solidity ^0.7.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/admin-keys/AdminKeys.sol

pragma solidity >=0.5.16 <0.8.4;

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
abstract contract AdminKeys is Ownable {
    event AdminKeyAdded(address indexed from, address addressAdded);
    event AdminKeyRemoved(address indexed from, address addressRemoved);

    mapping(address => uint256) internal admins;

    /**
     * @dev Only admin+ level users can call this.
     */
    function isAdminKey(address addy) public view onlyAdminOrOwner returns (bool) {
        return admins[addy] != 0;
    }

    /**
     * @dev Only admin+ level users can call this.
     */
    function addAdminKey(address addy) public onlyAdminOrOwner {
        require(addy != owner(), 'AdminKeys: OWNER_IS_ADMIN_BY_DEFAULT');
        admins[addy] = 1;

        emit AdminKeyAdded(msg.sender, addy);
    }

    /**
     * @dev Only admin+ level users can call this.
     */
    function removeAdminKey(address addy) public onlyAdminOrOwner {
        require(addy != owner(), 'AdminKeys: OWNER_NOT_ALLOWED');
        admins[addy] = 0;

        emit AdminKeyRemoved(msg.sender, addy);
    }

    modifier onlyAdminOrOwner() {
        require(
            owner() == _msgSender() || admins[_msgSender()] != 0, //
            'AdminKeys: CALLER_NOT_OWNER_NOR_ADMIN'
        );
        _;
    }
}

// File: contracts/price-feeds/PriceFeeds.sol

pragma solidity >=0.5.16 <0.8.4;

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
abstract contract PriceFeeds is AdminKeys {
    struct PriceFeed {
        bool configured;
        AggregatorV3Interface feed;
    }

    event TokenPriceFeedAdded(address indexed from, address token, address priceFeed);
    event TokenPriceFeedRemoved(address indexed from, address token);
    event EthPriceFeedAdded(address indexed from, address priceFeed);
    event EthPriceFeedRemoved(address indexed from);

    mapping(IERC20 => PriceFeed) internal tokenPriceFeeds;
    PriceFeed internal ethPriceFeed;

    /**
     * @dev Only admin+ level users can call this.
     */
    function addTokenPriceFeed(address token, address priceFeed) public onlyAdminOrOwner {
        tokenPriceFeeds[IERC20(token)] = PriceFeed(true, AggregatorV3Interface(priceFeed));

        emit TokenPriceFeedAdded(msg.sender, token, priceFeed);
    }

    /**
     * @dev Only admin+ level users can call this.
     */
    function removeTokenPriceFeed(address token) public onlyAdminOrOwner {
        tokenPriceFeeds[IERC20(token)] = PriceFeed(false, AggregatorV3Interface(address(0)));

        emit TokenPriceFeedRemoved(msg.sender, token);
    }

    /**
     * @dev Any user can call this.
     */
    function getTokenPriceFeed(address token) public view returns (address) {
        return address(tokenPriceFeeds[IERC20(token)].feed);
    }

    /**
     * @dev Only admin+ level users can call this.
     */
    function addEthPriceFeed(address priceFeed) public onlyAdminOrOwner {
        ethPriceFeed = PriceFeed(true, AggregatorV3Interface(priceFeed));

        emit EthPriceFeedAdded(msg.sender, priceFeed);
    }

    /**
     * @dev Only admin+ level users can call this.
     */
    function removeEthPriceFeed() public onlyAdminOrOwner {
        ethPriceFeed = PriceFeed(false, AggregatorV3Interface(address(0)));

        emit EthPriceFeedRemoved(msg.sender);
    }

    /**
     * @dev Any user can call this.
     */
    function getEthPriceFeed() public view returns (address) {
        return address(ethPriceFeed.feed);
    }

    /**
     * Returns the latest round data for a Price Feed.
     *
     * Any user can call this.
     */
    function getPriceFeedLatestRoundData(address priceFeed)
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return AggregatorV3Interface(priceFeed).latestRoundData();
    }
}

// File: contracts/dex/CryptoChangeDexV1.sol

pragma solidity >=0.5.16 <0.8.4;

contract CryptoChangeDexV1 is ICryptoChangeDexV1, PriceFeeds {
    /**
     * @dev The user can send Ether and get tokens in exchange.
     *
     * The ETH balance of the contract is auto-updated.
     */
    function swapExactEthForTokens(address[] calldata path)
        public
        payable
        validatePriceFeeds(path, Util.SwapType.ExactEthForTokens)
        returns (uint256[] memory amounts)
    {
        amounts = CryptoChangeV1Library.getAmounts(0, path, Util.SwapType.ExactEthForTokens);
        CryptoChangeV1Validator.validateSwapExactEthForTokens(amounts, path);

        uint256 amountIn = amounts[0];
        uint256 amountOut = amounts[1];

        TransferHelper.safeTransfer(path[0], msg.sender, amountOut);

        emit ExactEthForTokensSwapped(amountIn, amountOut);
    }

    /**
     * @dev The user swap tokens and get Ether in exchange.
     */
    function swapExactTokensForEth(uint256 amount, address[] calldata path)
        public
        validatePriceFeeds(path, Util.SwapType.ExactTokensForEth)
        returns (uint256[] memory amounts)
    {
        amounts = CryptoChangeV1Library.getAmounts(amount, path, Util.SwapType.ExactTokensForEth);
        CryptoChangeV1Validator.validateSwapExactTokensForEth(amounts, path);

        uint256 amountIn = amounts[0];
        uint256 amountOut = amounts[1];

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
        TransferHelper.safeTransferEth(msg.sender, amountOut);

        emit ExactTokensForEthSwapped(amountIn, amountOut);
    }

    /**
     * @dev The user swaps a token for another.
     */
    function swapExactTokensForTokens(uint256 amount, address[] calldata path)
        public
        validatePriceFeeds(path, Util.SwapType.ExactTokensForTokens)
        returns (uint256[] memory amounts)
    {
        amounts = CryptoChangeV1Library.getAmounts(amount, path, Util.SwapType.ExactTokensForTokens);
        CryptoChangeV1Validator.validateSwapExactTokensForTokens(amounts, path);

        uint256 amountIn = amounts[0];
        uint256 amountOut = amounts[1];

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
        TransferHelper.safeTransfer(path[1], msg.sender, amountOut);

        emit ExactTokensForTokensSwapped(msg.sender, amountIn, amountOut);
    }

    function depositETH() external payable {
        emit EthDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Any user can call this.
     */
    function isAdminAccount() public view returns (bool) {
        return admins[msg.sender] != 0 || owner() == msg.sender;
    }

    ///////////////
    // Modifiers //
    ///////////////

    modifier validatePriceFeeds(address[] memory path, Util.SwapType swapType) {
        require(path.length > 0, 'CryptoChangeDexV1: ONE_PATH_REQUIRED');
        if (swapType == Util.SwapType.ExactEthForTokens) {
            require(tokenPriceFeeds[IERC20(path[0])].configured, 'CryptoChangeDexV1: TOKEN_PRICE_FEED_REQUIRED');
            require(ethPriceFeed.configured, 'CryptoChangeDexV1: ETH_PRICE_FEED_REQUIRED');
        }

        if (swapType == Util.SwapType.ExactTokensForEth) {
            require(tokenPriceFeeds[IERC20(path[0])].configured, 'CryptoChangeDexV1: TOKEN_PRICE_FEED_REQUIRED');
            require(ethPriceFeed.configured, 'CryptoChangeDexV1: ETH_PRICE_FEED_REQUIRED');
        }

        if (swapType == Util.SwapType.ExactTokensForTokens) {
            require(path.length == 2, 'CryptoChangeDexV1: TWO_PATHS_REQUIRED');
            require(tokenPriceFeeds[IERC20(path[0])].configured, 'CryptoChangeDexV1: TOKEN0_PRICE_FEED_REQUIRED');
            require(tokenPriceFeeds[IERC20(path[1])].configured, 'CryptoChangeDexV1: TOKEN1_PRICE_FEED_REQUIRED');
        }
        _;
    }
}