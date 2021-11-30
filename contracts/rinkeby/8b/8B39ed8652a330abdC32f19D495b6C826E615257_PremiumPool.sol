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
import "./interfaces/IExchangeAgent.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IPremiumPool.sol";

contract PremiumPool is IPremiumPool {
    address public owner;
    address public exchangeAgent;
    address public UNO_TOKEN;
    address public USDT_TOKEN;
    address public constant burnAddres = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnableRate;
    uint256 private constant BURNABLE_RATE_PRECISION = 100;

    event PremiumWithdraw(address indexed _currency, address indexed _to, uint256 _amount);
    event LogSwapUNOToUSDT(address indexed _swaper, uint256 _swapAmountInUNO, uint256 _swapAmountInUSDT, uint256 _burnAmount);

    constructor(
        address _exchangeAgent,
        address _unoToken,
        address _usdtToken
    ) {
        exchangeAgent = _exchangeAgent;
        owner = msg.sender;
        UNO_TOKEN = _unoToken;
        USDT_TOKEN = _usdtToken;
        burnableRate = 20 * BURNABLE_RATE_PRECISION;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UnoRe: PremiumPool Forbidden");
        _;
    }

    receive() external payable {}

    function swapUNOToUSDT() external onlyOwner {
        uint256 unoBalance = IERC20(UNO_TOKEN).balanceOf(address(this));
        uint256 amountForSwap = (unoBalance * (100 * BURNABLE_RATE_PRECISION - burnableRate)) / (100 * BURNABLE_RATE_PRECISION);
        TransferHelper.safeApprove(UNO_TOKEN, exchangeAgent, amountForSwap);
        uint256 swapAmount = IExchangeAgent(exchangeAgent).tokenConvertForUSDTWithTwapPrice(UNO_TOKEN, amountForSwap);
        uint256 restBalance = IERC20(UNO_TOKEN).balanceOf(address(this));
        TransferHelper.safeTransfer(UNO_TOKEN, burnAddres, restBalance);
        emit LogSwapUNOToUSDT(msg.sender, amountForSwap, swapAmount, restBalance);
    }

    function setPremiumBurnPCT(uint256 _burnPCT) external onlyOwner {
        require(_burnPCT > 0, "UnoRe: zero burnPCT");
        burnableRate = _burnPCT * BURNABLE_RATE_PRECISION;
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
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IExchangeAgent {
    function USDT_TOKEN() external view returns (address);

    function getTokenAmountForUSDT(address _token, uint256 _inputAmount) external view returns (uint256);

    function tokenConvertForUSDTWithTwapPrice(address _token, uint256 _convertAmount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IPremiumPool {
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