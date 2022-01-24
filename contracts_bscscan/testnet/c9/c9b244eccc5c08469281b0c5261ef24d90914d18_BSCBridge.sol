/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//Remix style import
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

contract BSCBridge {
    using SafeMath for uint256;

    IERC20 private mainToken;

    IUniswapV2Router02 public uniswapV2Router;

    bool public autoLiquidateForGasEnabled = true;

    address public gateway;
    address public owner;
    address public bridgeFeeCollector;
    address public uniswapV2Pair;

    // a bridge fee of 20 would be a 2% tax
    // a bridge fee of 1 would be a 0.1% tax
    uint public BRIDGE_FEE = 20;
    // default to automatically liquidate half of the fee to be used as gas
    uint public AUTOLIQUIDATE_FEE = 500;
    // never liquidate more than 50k tokens at a time by default
    uint256 public maxAutoLiqAmount = 50000e9;
    // never liquidate less than 10k tokens at a time by default
    uint256 public minAutoLiqAmount = 10000e9;
    // dont auto liquidate if you have enough gas for the next tx
    // default 0.1 ETH as the threshold for enough gas
    uint256 public minEthBalance = 100000000000000000;
    // track how much of the bridge balance belongs to the bridge
    uint256 public bridgeBalance = 0;

    event AutoLiquidateForGas(uint amount, uint indexed timestamp);
    event TokensLocked(address indexed requester, bytes32 indexed mainDepositHash, uint amount, uint timestamp);
    event TokensUnlocked(address indexed requester, bytes32 indexed sideDepositHash, uint amount, uint timestamp);

    constructor (address _mainToken, address _gateway) {
        mainToken = IERC20(_mainToken);
        gateway = _gateway;
        owner = msg.sender;
        bridgeFeeCollector = msg.sender;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapV2Router = _uniswapV2Router;
    }

    function lockTokens (address _requester, uint _bridgedAmount, bytes32 _mainDepositHash) onlyGateway external {
        emit TokensLocked(_requester, _mainDepositHash, _bridgedAmount, block.timestamp);
    }

    function unlockTokens (address _requester, uint _bridgedAmount, bytes32 _sideDepositHash) onlyGateway external {
        uint bridgeFee = _bridgedAmount.mul(BRIDGE_FEE).div(1000);
        uint transferAmount = _bridgedAmount.sub(bridgeFee);

        if (bridgeFee > 0) {
            if (autoLiquidateForGasEnabled) {
                uint256 autoLiqFee = bridgeFee.mul(AUTOLIQUIDATE_FEE).div(1000);
                mainToken.transfer(address(this), autoLiqFee);
                bridgeBalance = bridgeBalance.add(autoLiqFee);
                
                uint256 spendableAmountForGas = bridgeBalance;
                bool enoughGasInTank = gateway.balance >= minEthBalance;

                if (spendableAmountForGas >= minAutoLiqAmount && !enoughGasInTank) {
                    if (spendableAmountForGas > maxAutoLiqAmount) {
                        spendableAmountForGas = maxAutoLiqAmount;
                    }
                    swapTokensForEth(spendableAmountForGas);
                    bridgeBalance = bridgeBalance.sub(spendableAmountForGas);
                    emit AutoLiquidateForGas(spendableAmountForGas, block.timestamp);
                }

                mainToken.transfer(bridgeFeeCollector, bridgeFee.sub(autoLiqFee));
            } else {
                mainToken.transfer(bridgeFeeCollector, bridgeFee);
            }
        }

        mainToken.transfer(_requester, transferAmount);
        emit TokensUnlocked(_requester, _sideDepositHash, _bridgedAmount, block.timestamp);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(mainToken);
        path[1] = uniswapV2Router.WETH();

        mainToken.approve(address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            gateway,
            block.timestamp
        );
    }

    function setAutoLiquidateForGas (bool _enabled) onlyOwner external {
        autoLiquidateForGasEnabled = _enabled;
    }

    function setMaxAutoLiqAmount(uint256 _amount) onlyOwner external {
        maxAutoLiqAmount = _amount;
    }

    function setMinEthBalance(uint256 _amount) onlyOwner external {
        minEthBalance = _amount;
    }

    function setUniswapRouter (address _newRouter) onlyOwner external {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            address(_newRouter)
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
    }

    function setBridgeFee (uint256 _fee) onlyGateway external {
        BRIDGE_FEE = _fee;
    }

    function setBridgeFeeCollector (address _newBridgeFeeCollector) onlyOwner external {
        bridgeFeeCollector = _newBridgeFeeCollector;
    }

    function setGateway (address _newGateway) onlyOwner external {
        gateway = _newGateway;
    }

    function withdrawTokenToOwner(address _tokenAddress, uint256 _amount) onlyOwner external {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(balance >= _amount, "Insufficient token balance");
        IERC20(_tokenAddress).transfer(owner, _amount);
    }

    function withdrawEthToOwner (uint256 _amount) onlyOwner external {
        require(_amount <= address(this).balance, "Not enough ETH in contract balance");
        payable(owner).transfer(_amount);
    }

    modifier onlyGateway {
        require(msg.sender == gateway, "only gateway can execute this function");
        _;
    }

    modifier onlyOwner {
      require(msg.sender == owner, "Only owner can execute this function");
      _;
    }

    receive() external payable {}
}