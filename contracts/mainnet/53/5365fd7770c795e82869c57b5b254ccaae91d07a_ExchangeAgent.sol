/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// File: interfaces/IExchangeAgent.sol



pragma solidity ^0.8.0;

interface IExchangeAgent {
    function getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _desiredAmount
    ) external returns (uint256);

    function getTokenAmountForUSDC(address _token, uint256 _desiredAmount) external returns (uint256);

    function getETHAmountForUSDC(uint256 _desiredAmount) external view returns (uint256);

    function getTokenAmountForETH(address _token, uint256 _desiredAmount) external returns (uint256);

    function swapTokenWithETH(
        address _token,
        uint256 _amount,
        uint256 _desiredAmount
    ) external;

    function swapTokenWithToken(
        address _token0,
        address _token1,
        uint256 _amount,
        uint256 _desiredAmount
    ) external;
}

// File: interfaces/ITwapOraclePriceFeed.sol


pragma solidity 0.8.0;

interface ITwapOraclePriceFeed {
    function update() external;

    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

// File: interfaces/ITwapOraclePriceFeedFactory.sol


pragma solidity 0.8.0;

interface ITwapOraclePriceFeedFactory {
    function twapOraclePriceFeedList(address _pair) external view returns (address);

    function getTwapOraclePriceFeed(address _token0, address _token1) external view returns (address twapOraclePriceFeed);
}

// File: interfaces/IUniswapV2Factory.sol



pragma solidity 0.8.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// File: interfaces/IUniswapV2Pair.sol


pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// File: libs/TransferHelper.sol



pragma solidity 0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: ExchangeAgent.sol


pragma solidity ^0.8.0;










/**
 * @dev This smart contract is for getting CVR_ETH, CVR_USDT price
 */
contract ExchangeAgent is Ownable, IExchangeAgent, ReentrancyGuard {
    event AddGateway(address _sender, address _gateway);
    event RemoveGateway(address _sender, address _gateway);
    event AddAvailableCurrency(address _sender, address _currency);
    event RemoveAvailableCurrency(address _sender, address _currency);
    event UpdateSlippage(address _sender, uint256 _slippage);
    event WithdrawAsset(address _user, address _to, address _token, uint256 _amount);
    event UpdateSlippageRate(address _user, uint256 _slippageRate);

    mapping(address => bool) public whiteList; // white listed CoverCompared gateways

    // available currencies in CoverCompared, token => bool
    // for now we allow CVR
    mapping(address => bool) public availableCurrencies;

    address public immutable CVR_ADDRESS;
    address public immutable USDC_ADDRESS;
    /**
     * We are using Uniswap V2 TWAP oracle - so it should be WETH addres in Uniswap V2
     */
    address public immutable WETH;
    address public immutable UNISWAP_FACTORY;
    address public immutable TWAP_ORACLE_PRICE_FEED_FACTORY;

    uint256 public SLIPPPAGE_RAGE;
    /**
     * when users try to use CVR to buy products, we will discount some percentage(25% at first stage)
     */
    uint256 public discountPercentage = 75;

    constructor(
        address _CVR_ADDRESS,
        address _USDC_ADDRESS,
        address _WETH,
        address _UNISWAP_FACTORY,
        address _TWAP_ORACLE_PRICE_FEED_FACTORY
    ) {
        CVR_ADDRESS = _CVR_ADDRESS;
        USDC_ADDRESS = _USDC_ADDRESS;
        WETH = _WETH;
        UNISWAP_FACTORY = _UNISWAP_FACTORY;
        TWAP_ORACLE_PRICE_FEED_FACTORY = _TWAP_ORACLE_PRICE_FEED_FACTORY;
        SLIPPPAGE_RAGE = 100;
    }

    receive() external payable {}

    modifier onlyWhiteListed(address _gateway) {
        require(whiteList[_gateway], "Only white listed addresses are acceptable");
        _;
    }

    /**
     * @dev If users use CVR, they will pay _discountPercentage % of cost.
     */
    function setDiscountPercentage(uint256 _discountPercentage) external onlyOwner {
        require(_discountPercentage <= 100, "Exceeded value");
        discountPercentage = _discountPercentage;
    }

    /**
     * @dev Get needed _token0 amount for _desiredAmount of _token1
     * _desiredAmount should consider decimals based on _token1
     */
    function _getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _desiredAmount
    ) private view returns (uint256) {
        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(_token0, _token1);
        require(pair != address(0), "There's no pair");

        address twapOraclePriceFeed = ITwapOraclePriceFeedFactory(TWAP_ORACLE_PRICE_FEED_FACTORY).getTwapOraclePriceFeed(
            _token0,
            _token1
        );

        require(twapOraclePriceFeed != address(0), "There's no twap oracle for this pair");

        uint256 neededAmount = ITwapOraclePriceFeed(twapOraclePriceFeed).consult(_token1, _desiredAmount);
        if (_token0 == CVR_ADDRESS) {
            neededAmount = (neededAmount * discountPercentage) / 100;
        }

        return neededAmount;
    }

    /**
     * @dev Get needed _token0 amount for _desiredAmount of _token1
     */
    function getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _desiredAmount
    ) external view override returns (uint256) {
        return _getNeededTokenAmount(_token0, _token1, _desiredAmount);
    }

    function getETHAmountForUSDC(uint256 _desiredAmount) external view override returns (uint256) {
        return _getNeededTokenAmount(WETH, USDC_ADDRESS, _desiredAmount);
    }

    /**
     * get needed _token amount for _desiredAmount of USDC
     */
    function getTokenAmountForUSDC(address _token, uint256 _desiredAmount) external view override returns (uint256) {
        return _getNeededTokenAmount(_token, USDC_ADDRESS, _desiredAmount);
    }

    /**
     * get needed _token amount for _desiredAmount of ETH
     */
    function getTokenAmountForETH(address _token, uint256 _desiredAmount) external view override returns (uint256) {
        return _getNeededTokenAmount(_token, WETH, _desiredAmount);
    }

    /**
     * @param _amount: this one is the value with decimals
     */
    function swapTokenWithETH(
        address _token,
        uint256 _amount,
        uint256 _desiredAmount
    ) external override onlyWhiteListed(msg.sender) nonReentrant {
        // store CVR in this exchagne contract
        // send eth to buy gateway based on the uniswap price
        require(availableCurrencies[_token], "Token should be added in available list");
        _swapTokenWithToken(_token, WETH, _amount, _desiredAmount);
    }

    function swapTokenWithToken(
        address _token0,
        address _token1,
        uint256 _amount,
        uint256 _desiredAmount
    ) external override onlyWhiteListed(msg.sender) nonReentrant {
        require(availableCurrencies[_token0], "Token should be added in available list");
        _swapTokenWithToken(_token0, _token1, _amount, _desiredAmount);
    }

    /**
     * @dev exchange _amount of _token0 with _token1 by twap oracle price
     */
    function _swapTokenWithToken(
        address _token0,
        address _token1,
        uint256 _amount,
        uint256 _desiredAmount
    ) private {
        address twapOraclePriceFeed = ITwapOraclePriceFeedFactory(TWAP_ORACLE_PRICE_FEED_FACTORY).getTwapOraclePriceFeed(
            _token0,
            _token1
        );

        uint256 swapAmount = ITwapOraclePriceFeed(twapOraclePriceFeed).consult(_token0, _amount);
        uint256 availableMinAmount = (_desiredAmount * (10000 - SLIPPPAGE_RAGE)) / 10000;
        if (_token0 == CVR_ADDRESS) {
            availableMinAmount = (availableMinAmount * discountPercentage) / 100;
        }
        require(swapAmount > availableMinAmount, "Overflow min amount");

        TransferHelper.safeTransferFrom(_token0, msg.sender, address(this), _amount);

        if (_token1 == WETH) {
            TransferHelper.safeTransferETH(msg.sender, _desiredAmount);
        } else {
            TransferHelper.safeTransfer(_token1, msg.sender, _desiredAmount);
        }
    }

    function addWhiteList(address _gateway) external onlyOwner {
        require(!whiteList[_gateway], "Already white listed");
        whiteList[_gateway] = true;
        emit AddGateway(msg.sender, _gateway);
    }

    function removeWhiteList(address _gateway) external onlyOwner {
        require(whiteList[_gateway], "Not white listed");
        whiteList[_gateway] = false;
        emit RemoveGateway(msg.sender, _gateway);
    }

    function addCurrency(address _currency) external onlyOwner {
        require(!availableCurrencies[_currency], "Already available");
        availableCurrencies[_currency] = true;
        emit AddAvailableCurrency(msg.sender, _currency);
    }

    function removeCurrency(address _currency) external onlyOwner {
        require(availableCurrencies[_currency], "Not available yet");
        availableCurrencies[_currency] = false;
        emit RemoveAvailableCurrency(msg.sender, _currency);
    }

    function setSlippageRate(uint256 _slippageRate) external onlyOwner {
        require(_slippageRate > 0 && _slippageRate < 100, "Overflow range");
        SLIPPPAGE_RAGE = _slippageRate * 100;
        emit UpdateSlippageRate(msg.sender, _slippageRate);
    }

    function withdrawAsset(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        if (_token == address(0)) {
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            TransferHelper.safeTransfer(_token, _to, _amount);
        }
        emit WithdrawAsset(owner(), _to, _token, _amount);
    }
}