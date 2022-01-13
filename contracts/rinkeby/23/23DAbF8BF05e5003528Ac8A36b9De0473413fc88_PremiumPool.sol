// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IExchangeAgent.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IPremiumPool.sol";

contract PremiumPool is IPremiumPool, ReentrancyGuard {
    address public owner;
    address public exchangeAgent;
    address public UNO_TOKEN;
    address public USDC_TOKEN;
    mapping(address => bool) public availableCurrencies;
    address[] public availableCurrencyList;
    mapping(address => bool) public whiteList;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) public SSRP_PREMIUM;
    mapping(address => uint256) public SSIP_PREMIUM;
    mapping(address => uint256) public BACK_BURN_UNO_PREMIUM;
    uint256 public SSRP_PREMIUM_ETH;
    uint256 public SSIP_PREMIUM_ETH;
    uint256 public BACK_BURN_PREMIUM_ETH;

    uint256 private MAX_INTEGER = type(uint256).max;

    event PremiumWithdraw(address indexed _currency, address indexed _to, uint256 _amount);
    event LogBuyBackAndBurn(address indexed _operator, address indexed _premiumPool, uint256 _unoAmount);
    event LogCollectPremium(address indexed _from, address _premiumCurrency, uint256 _premiumAmount);
    event LogDepositToSyntheticSSRPRewarder(address indexed _rewarder, uint256 _ethAmountDeposited);
    event LogDepositToSyntheticSSIPRewarder(address indexed _rewarder, address indexed _currency, uint256 _amountDeposited);
    event LogAddCurrency(address indexed _premiumPool, address indexed _currency);
    event LogRemoveCurrency(address indexed _premiumPool, address indexed _currency);
    event LogMaxApproveCurrency(address indexed _premiumPool, address indexed _currency, address indexed _to);
    event LogMaxDestroyCurrencyAllowance(address indexed _premiumPool, address indexed _currency, address indexed _to);
    event LogAddWhiteList(address indexed _premiumPool, address indexed _whiteListAddress);
    event LogRemoveWhiteList(address indexed _premiumPool, address indexed _whiteListAddress);

    constructor(
        address _exchangeAgent,
        address _unoToken,
        address _usdcToken
    ) {
        require(_exchangeAgent != address(0), "UnoRe: zero exchangeAgent address");
        require(_unoToken != address(0), "UnoRe: zero UNO address");
        require(_usdcToken != address(0), "UnoRe: zero USDC address");
        exchangeAgent = _exchangeAgent;
        owner = msg.sender;
        UNO_TOKEN = _unoToken;
        USDC_TOKEN = _usdcToken;
        whiteList[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UnoRe: PremiumPool Forbidden");
        _;
    }

    modifier onlyAvailableCurrency(address _currency) {
        require(availableCurrencies[_currency], "UnoRe: not allowed currency");
        _;
    }

    modifier onlyWhiteList() {
        require(whiteList[msg.sender], "UnoRe: not white list address");
        _;
    }

    receive() external payable {}

    function collectPremiumInETH() external payable override nonReentrant onlyWhiteList {
        uint256 _premiumAmount = msg.value;
        uint256 _premium_SSRP = (_premiumAmount * 1000) / 10000;
        uint256 _premium_SSIP = (_premiumAmount * 7000) / 10000;
        SSRP_PREMIUM_ETH = SSRP_PREMIUM_ETH + _premium_SSRP;
        SSIP_PREMIUM_ETH = SSIP_PREMIUM_ETH + _premium_SSIP;
        BACK_BURN_PREMIUM_ETH = BACK_BURN_PREMIUM_ETH + (_premiumAmount - _premium_SSRP - _premium_SSIP);
        emit LogCollectPremium(msg.sender, address(0), _premiumAmount);
    }

    function collectPremium(address _premiumCurrency, uint256 _premiumAmount)
        external
        override
        nonReentrant
        onlyAvailableCurrency(_premiumCurrency)
        onlyWhiteList
    {
        require(IERC20(_premiumCurrency).balanceOf(msg.sender) >= _premiumAmount, "UnoRe: premium balance overflow");
        TransferHelper.safeTransferFrom(_premiumCurrency, msg.sender, address(this), _premiumAmount);
        uint256 _premium_SSRP = (_premiumAmount * 1000) / 10000;
        uint256 _premium_SSIP = (_premiumAmount * 7000) / 10000;
        SSRP_PREMIUM[_premiumCurrency] = SSRP_PREMIUM[_premiumCurrency] + _premium_SSRP;
        SSIP_PREMIUM[_premiumCurrency] = SSIP_PREMIUM[_premiumCurrency] + _premium_SSIP;
        BACK_BURN_UNO_PREMIUM[_premiumCurrency] =
            BACK_BURN_UNO_PREMIUM[_premiumCurrency] +
            (_premiumAmount - _premium_SSRP - _premium_SSIP);
        emit LogCollectPremium(msg.sender, _premiumCurrency, _premiumAmount);
    }

    function depositToSyntheticSSRPRewarder(address _rewarder) external payable onlyOwner nonReentrant {
        require(_rewarder != address(0), "UnoRe: zero address");
        uint256 usdcAmountToDeposit = 0;
        if (SSRP_PREMIUM_ETH > 0) {
            TransferHelper.safeTransferETH(exchangeAgent, SSRP_PREMIUM_ETH);
            uint256 convertedAmount = IExchangeAgent(exchangeAgent).convertForToken(address(0), USDC_TOKEN, SSRP_PREMIUM_ETH);
            usdcAmountToDeposit += convertedAmount;
            SSRP_PREMIUM_ETH = 0;
        }
        for (uint256 ii = 0; ii < availableCurrencyList.length; ii++) {
            if (SSRP_PREMIUM[availableCurrencyList[ii]] > 0) {
                if (availableCurrencyList[ii] == USDC_TOKEN) {
                    usdcAmountToDeposit += SSRP_PREMIUM[availableCurrencyList[ii]];
                } else {
                    uint256 convertedUSDCAmount = IExchangeAgent(exchangeAgent).convertForToken(
                        availableCurrencyList[ii],
                        USDC_TOKEN,
                        SSRP_PREMIUM[availableCurrencyList[ii]]
                    );
                    usdcAmountToDeposit += convertedUSDCAmount;
                }
                SSRP_PREMIUM[availableCurrencyList[ii]] = 0;
            }
        }
        if (usdcAmountToDeposit > 0) {
            TransferHelper.safeTransfer(USDC_TOKEN, _rewarder, usdcAmountToDeposit);
            emit LogDepositToSyntheticSSRPRewarder(_rewarder, usdcAmountToDeposit);
        }
    }

    function depositToSyntheticSSIPRewarder(address _currency, address _rewarder) external payable onlyOwner nonReentrant {
        require(_rewarder != address(0), "UnoRe: zero address");
        if (_currency == address(0) && SSIP_PREMIUM_ETH > 0) {
            TransferHelper.safeTransferETH(_rewarder, SSIP_PREMIUM_ETH);
            SSIP_PREMIUM_ETH = 0;
            emit LogDepositToSyntheticSSIPRewarder(_rewarder, _currency, SSIP_PREMIUM_ETH);
        } else {
            if (availableCurrencies[_currency] && SSIP_PREMIUM[_currency] > 0) {
                TransferHelper.safeTransfer(_currency, _rewarder, SSIP_PREMIUM[_currency]);
                SSIP_PREMIUM[_currency] = 0;
                emit LogDepositToSyntheticSSIPRewarder(_rewarder, _currency, SSIP_PREMIUM[_currency]);
            }
        }
    }

    function buyBackAndBurn() external onlyOwner {
        uint256 unoAmount = 0;
        if (BACK_BURN_PREMIUM_ETH > 0) {
            TransferHelper.safeTransferETH(exchangeAgent, BACK_BURN_PREMIUM_ETH);
            unoAmount += IExchangeAgent(exchangeAgent).convertForToken(address(0), UNO_TOKEN, BACK_BURN_PREMIUM_ETH);
            BACK_BURN_PREMIUM_ETH = 0;
        }
        for (uint256 ii = 0; ii < availableCurrencyList.length; ii++) {
            if (BACK_BURN_UNO_PREMIUM[availableCurrencyList[ii]] > 0) {
                uint256 convertedAmount = IExchangeAgent(exchangeAgent).convertForToken(
                    availableCurrencyList[ii],
                    UNO_TOKEN,
                    BACK_BURN_UNO_PREMIUM[availableCurrencyList[ii]]
                );
                unoAmount += convertedAmount;
                BACK_BURN_UNO_PREMIUM[availableCurrencyList[ii]] = 0;
            }
        }
        if (unoAmount > 0) {
            TransferHelper.safeTransfer(UNO_TOKEN, burnAddress, unoAmount);
        }
        emit LogBuyBackAndBurn(msg.sender, address(this), unoAmount);
    }

    function withdrawPremium(
        address _currency,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        require(_to != address(0), "UnoRe: zero address");
        require(_amount > 0, "UnoRe: zero amount");
        if (_currency == address(0)) {
            require(address(this).balance >= _amount, "UnoRe: Insufficient Premium");
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            require(IERC20(_currency).balanceOf(address(this)) >= _amount, "UnoRe: Insufficient Premium");
            TransferHelper.safeTransfer(_currency, _to, _amount);
        }
        emit PremiumWithdraw(_currency, _to, _amount);
    }

    function addCurrency(address _currency) external onlyOwner {
        require(!availableCurrencies[_currency], "Already available");
        availableCurrencies[_currency] = true;
        availableCurrencyList.push(_currency);
        maxApproveCurrency(_currency, exchangeAgent);
        emit LogAddCurrency(address(this), _currency);
    }

    function removeCurrency(address _currency) external onlyOwner {
        require(availableCurrencies[_currency], "Not available yet");
        availableCurrencies[_currency] = false;
        uint256 len = availableCurrencyList.length;
        address lastCurrency = availableCurrencyList[len - 1];
        for (uint256 ii = 0; ii < len; ii++) {
            if (_currency == availableCurrencyList[ii]) {
                availableCurrencyList[ii] = lastCurrency;
                availableCurrencyList.pop();
                destroyCurrencyAllowance(_currency, exchangeAgent);
                return;
            }
        }
        emit LogRemoveCurrency(address(this), _currency);
    }

    function maxApproveCurrency(address _currency, address _to) public onlyOwner nonReentrant {
        if (IERC20(_currency).allowance(address(this), _to) < MAX_INTEGER) {
            TransferHelper.safeApprove(_currency, _to, MAX_INTEGER);
            emit LogMaxApproveCurrency(address(this), _currency, _to);
        }
    }

    function destroyCurrencyAllowance(address _currency, address _to) public onlyOwner nonReentrant {
        if (IERC20(_currency).allowance(address(this), _to) > 0) {
            TransferHelper.safeApprove(_currency, _to, 0);
            emit LogMaxDestroyCurrencyAllowance(address(this), _currency, _to);
        }
    }

    function addWhiteList(address _whiteListAddress) external onlyOwner {
        require(_whiteListAddress != address(0), "UnoRe: zero address");
        require(!whiteList[_whiteListAddress], "UnoRe: white list already");
        whiteList[_whiteListAddress] = true;
        emit LogAddWhiteList(address(this), _whiteListAddress);
    }

    function removeWhiteList(address _whiteListAddress) external onlyOwner {
        require(_whiteListAddress != address(0), "UnoRe: zero address");
        require(whiteList[_whiteListAddress], "UnoRe: white list removed or unadded already");
        whiteList[_whiteListAddress] = false;
        emit LogRemoveWhiteList(address(this), _whiteListAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IExchangeAgent {
    function USDC_TOKEN() external view returns (address);

    function getTokenAmountForUSDC(address _token, uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForUSDC(uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForToken(address _token, uint256 _tokenAmount) external view returns (uint256);

    function getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external view returns (uint256);

    function convertForToken(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external returns (uint256);

    function convertForETH(address _token, uint256 _convertAmount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IPremiumPool {
    function collectPremium(address _premiumCurrency, uint256 _premiumAmount) external;

    function collectPremiumInETH() external payable;

    function withdrawPremium(
        address _currency,
        address _to,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
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