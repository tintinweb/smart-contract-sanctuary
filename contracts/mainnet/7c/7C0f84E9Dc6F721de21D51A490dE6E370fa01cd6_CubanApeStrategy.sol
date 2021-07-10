// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISushiSwap {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract CubanApeStrategy is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 private constant _WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // 18 decimals
    ISushiSwap private constant _sSwap = ISushiSwap(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    // Farms
    IERC20 private constant _renDOGE = IERC20(0x3832d2F059E55934220881F831bE501D180671A7); // 8 decimals
    IERC20 private constant _MATIC = IERC20(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0); // 18 decimals
    IERC20 private constant _AAVE = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9); // 18 decimals
    IERC20 private constant _SUSHI = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2); // 18 decimals
    IERC20 private constant _AXS = IERC20(0xBB0E17EF65F82Ab018d8EDd776e8DD940327B28b); // 18 decimals
    IERC20 private constant _INJ = IERC20(0xe28b3B32B6c345A34Ff64674606124Dd5Aceca30); // 18 decimals
    IERC20 private constant _ALCX = IERC20(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF); // 18 decimals

    // Others
    address public vault;
    uint256[] public weights; // [renDOGE, MATIC, AAVE, SUSHI, AXS, INJ, ALCX]
    uint256 private constant DENOMINATOR = 10000;
    bool public isVesting;

    event AmtToInvest(uint256 _amount); // In ETH
    // composition in ETH: renDOGE, MATIC, AAVE, SUSHI, AXS, INJ, ALCX
    event CurrentComposition(uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    event TargetComposition(uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    constructor(uint256[] memory _weights) {
        weights = _weights;

        _WETH.safeApprove(address(_sSwap), type(uint256).max);
        _renDOGE.safeApprove(address(_sSwap), type(uint256).max);
        _MATIC.safeApprove(address(_sSwap), type(uint256).max);
        _AAVE.safeApprove(address(_sSwap), type(uint256).max);
        _SUSHI.safeApprove(address(_sSwap), type(uint256).max);
        _AXS.safeApprove(address(_sSwap), type(uint256).max);
        _INJ.safeApprove(address(_sSwap), type(uint256).max);
        _ALCX.safeApprove(address(_sSwap), type(uint256).max);
    }

    /// @notice Function to set vault address that interact with this contract. This function can only execute once when deployment.
    /// @param _vault Address of vault contract 
    function setVault(address _vault) external onlyOwner {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    /// @notice Function to invest ETH into farms
    /// @param _amount Amount to invest in ETH
    function invest(uint256 _amount) external onlyVault {
        _WETH.safeTransferFrom(address(vault), address(this), _amount);
        emit AmtToInvest(_amount);

        // Due to the stack too deep error, pools are present in array
        uint256[] memory _pools = getFarmsPool();
        uint256 _totalPool = _amount.add(_getTotalPool());
        // Calculate target composition for each farm
        uint256[] memory _poolsTarget = new uint256[](7);
        for (uint256 _i=0 ; _i<7 ; _i++) {
            _poolsTarget[_i] = _totalPool.mul(weights[_i]).div(DENOMINATOR);
        }
        emit CurrentComposition(_pools[0], _pools[1], _pools[2], _pools[3], _pools[4], _pools[5], _pools[6]);
        emit TargetComposition(_poolsTarget[0], _poolsTarget[1], _poolsTarget[2], _poolsTarget[3], _poolsTarget[4], _poolsTarget[5], _poolsTarget[6]);
        // If there is no negative value(need to swap out from farm in order to drive back the composition)
        // We proceed with invest funds into 7 farms and drive composition back to target
        // Else, we invest all the funds into the farm that is furthest from target composition
        if (
            _poolsTarget[0] > _pools[0] &&
            _poolsTarget[1] > _pools[1] &&
            _poolsTarget[2] > _pools[2] &&
            _poolsTarget[3] > _pools[3] &&
            _poolsTarget[4] > _pools[4] &&
            _poolsTarget[5] > _pools[5] &&
            _poolsTarget[6] > _pools[6]
        ) {
            // Invest ETH into renDOGE
            _invest(_poolsTarget[0].sub(_pools[0]), _renDOGE);
            // Invest ETH into MATIC
            _invest(_poolsTarget[1].sub(_pools[1]), _MATIC);
            // Invest ETH into AAVE
            _invest(_poolsTarget[2].sub(_pools[2]), _AAVE);
            // Invest ETH into SUSHI
            _invest(_poolsTarget[3].sub(_pools[3]), _SUSHI);
            // Invest ETH into AXS
            _invest(_poolsTarget[4].sub(_pools[4]), _AXS);
            // Invest ETH into INJ
            _invest(_poolsTarget[5].sub(_pools[5]), _INJ);
            // Invest ETH into ALCX
            _invest(_poolsTarget[6].sub(_pools[6]), _ALCX);
        } else {
            // Invest all the funds to the farm that is furthest from target composition
            uint256 _furthest;
            uint256 _farmIndex;
            uint256 _diff;
            // 1. Find out the farm that is furthest from target composition
            if (_poolsTarget[0] > _pools[0]) {
                _furthest = _poolsTarget[0].sub(_pools[0]);
                _farmIndex = 0;
            }
            if (_poolsTarget[1] > _pools[1]) {
                _diff = _poolsTarget[1].sub(_pools[1]);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 1;
                }
            }
            if (_poolsTarget[2] > _pools[2]) {
                _diff = _poolsTarget[2].sub(_pools[2]);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 2;
                }
            }
            if (_poolsTarget[3] > _pools[3]) {
                _diff = _poolsTarget[3].sub(_pools[3]);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 3;
                }
            }
            if (_poolsTarget[4] > _pools[4]) {
                _diff = _poolsTarget[4].sub(_pools[4]);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 4;
                }
            }
            if (_poolsTarget[5] > _pools[5]) {
                _diff = _poolsTarget[5].sub(_pools[5]);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 5;
                }
            }
            if (_poolsTarget[6] > _pools[6]) {
                _diff = _poolsTarget[6].sub(_pools[6]);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 6;
                }
            }
            // 2. Put all the yield into the farm that is furthest from target composition
            if (_farmIndex == 0) {
                _invest(_amount, _renDOGE);
            } else if (_farmIndex == 1) {
                _invest(_amount, _MATIC);
            } else if (_farmIndex == 2) {
                _invest(_amount, _AAVE);
            } else if (_farmIndex == 3) {
                _invest(_amount, _SUSHI);
            } else if (_farmIndex == 4) {
                _invest(_amount, _AXS);
            } else if (_farmIndex == 5) {
                _invest(_amount, _INJ);
            } else {
                _invest(_amount, _ALCX);
            }
        }
    }

    /// @notice Function to invest funds into farm
    /// @param _amount Amount to invest in ETH
    /// @param _farm Farm to invest
    function _invest(uint256 _amount, IERC20 _farm) private {
        _swapExactTokensForTokens(address(_WETH), address(_farm), _amount);
    }

    /// @notice Function to withdraw Stablecoins from farms if withdraw amount > amount keep in vault
    /// @param _amount Amount to withdraw in ETH
    /// @return Amount of actual withdraw in ETH
    function withdraw(uint256 _amount) external onlyVault returns (uint256) {
        uint256 _withdrawAmt;
        if (!isVesting) {
            uint256 _totalPool = _getTotalPool();
            _swapExactTokensForTokens(address(_renDOGE), address(_WETH), (_renDOGE.balanceOf(address(this))).mul(_amount).div(_totalPool));
            _swapExactTokensForTokens(address(_MATIC), address(_WETH), (_MATIC.balanceOf(address(this))).mul(_amount).div(_totalPool));
            _swapExactTokensForTokens(address(_AAVE), address(_WETH), (_AAVE.balanceOf(address(this))).mul(_amount).div(_totalPool));
            _swapExactTokensForTokens(address(_SUSHI), address(_WETH), (_SUSHI.balanceOf(address(this))).mul(_amount).div(_totalPool));
            _swapExactTokensForTokens(address(_AXS), address(_WETH), (_AXS.balanceOf(address(this))).mul(_amount).div(_totalPool));
            _swapExactTokensForTokens(address(_INJ), address(_WETH), (_INJ.balanceOf(address(this))).mul(_amount).div(_totalPool));
            _swapExactTokensForTokens(address(_ALCX), address(_WETH), (_ALCX.balanceOf(address(this))).mul(_amount).div(_totalPool));
            _withdrawAmt = _WETH.balanceOf(address(this));
        } else {
            _withdrawAmt = _amount;
        }
        _WETH.safeTransfer(address(vault), _withdrawAmt);
        return _withdrawAmt;
    }

    /// @notice Function to release WETH to vault by swapping out farm
    /// @param _amount Amount of WETH to release
    /// @param _farmIndex Type of farm to swap out (0: renDOGE, 1: MATIC, 2: AAVE, 3: SUSHI, 4: AXS, 5: INJ, 6: ALCX)
    function releaseETHToVault(uint256 _amount, uint256 _farmIndex) external onlyVault returns (uint256) {
        if (_farmIndex == 0) {
            _swapTokensForExactTokens(address(_renDOGE), address(_WETH), _amount);
        } else if (_farmIndex == 1) {
            _swapTokensForExactTokens(address(_MATIC), address(_WETH), _amount);
        } else if (_farmIndex == 2) {
            _swapTokensForExactTokens(address(_AAVE), address(_WETH), _amount);
        } else if (_farmIndex == 3) {
            _swapTokensForExactTokens(address(_SUSHI), address(_WETH), _amount);
        } else if (_farmIndex == 4) {
            _swapTokensForExactTokens(address(_AXS), address(_WETH), _amount);
        } else if (_farmIndex == 5) {
            _swapTokensForExactTokens(address(_INJ), address(_WETH), _amount);
        } else {
            _swapTokensForExactTokens(address(_ALCX), address(_WETH), _amount);
        }
        uint256 _WETHBalance = _WETH.balanceOf(address(this));
        _WETH.safeTransfer(address(vault), _WETHBalance);
        return _WETHBalance;
    }

    /// @notice Function to withdraw all funds from all farms and swap to WETH
    function emergencyWithdraw() external onlyVault {
        _swapExactTokensForTokens(address(_renDOGE), address(_WETH), _renDOGE.balanceOf(address(this)));
        _swapExactTokensForTokens(address(_MATIC), address(_WETH), _MATIC.balanceOf(address(this)));
        _swapExactTokensForTokens(address(_AAVE), address(_WETH), _AAVE.balanceOf(address(this)));
        _swapExactTokensForTokens(address(_SUSHI), address(_WETH), _SUSHI.balanceOf(address(this)));
        _swapExactTokensForTokens(address(_AXS), address(_WETH), _AXS.balanceOf(address(this)));
        _swapExactTokensForTokens(address(_INJ), address(_WETH), _INJ.balanceOf(address(this)));
        _swapExactTokensForTokens(address(_ALCX), address(_WETH), _ALCX.balanceOf(address(this)));

        isVesting = true;
    }

    /// @notice Function to invest WETH into farms
    function reinvest() external onlyVault {
        isVesting = false;

        uint256 _WETHBalance = _WETH.balanceOf(address(this));
        _invest(_WETHBalance.mul(weights[0]).div(DENOMINATOR), _renDOGE);
        _invest(_WETHBalance.mul(weights[1]).div(DENOMINATOR), _MATIC);
        _invest(_WETHBalance.mul(weights[2]).div(DENOMINATOR), _AAVE);
        _invest(_WETHBalance.mul(weights[3]).div(DENOMINATOR), _SUSHI);
        _invest(_WETHBalance.mul(weights[4]).div(DENOMINATOR), _AXS);
        _invest(_WETHBalance.mul(weights[5]).div(DENOMINATOR), _INJ);
        _invest(_WETH.balanceOf(address(this)), _ALCX);
    }

    /// @notice Function to approve vault to migrate funds from this contract to new strategy contract
    function approveMigrate() external onlyOwner {
        require(isVesting, "Not in vesting state");
        _WETH.safeApprove(address(vault), type(uint256).max);
    }

    /// @notice Function to set weight of farms
    /// @param _weights Array with new weight(percentage) of farms (7 elements, DENOMINATOR = 10000)
    function setWeights(uint256[] memory _weights) external onlyVault {
        weights = _weights;
    }

    /// @notice Function to swap tokens with Sushi
    /// @param _tokenA Token to be swapped
    /// @param _tokenB Token to be received
    /// @param _amountIn Amount of token to be swapped
    /// @return _amounts Array that contains amounts of swapped tokens
    function _swapExactTokensForTokens(address _tokenA, address _tokenB, uint256 _amountIn) private returns (uint256[] memory _amounts) {
        address[] memory _path = _getPath(_tokenA, _tokenB);
        uint256[] memory _amountsOut = _sSwap.getAmountsOut(_amountIn, _path);
        if (_amountsOut[1] > 0) {
            _amounts = _sSwap.swapExactTokensForTokens(_amountIn, 0, _path, address(this), block.timestamp);
        }
    }

    /// @notice Function to swap tokens with Sushi
    /// @param _tokenA Token to be swapped
    /// @param _tokenB Token to be received
    /// @param _amountOut Amount of token to be received
    /// @return _amounts Array that contains amounts of swapped tokens
    function _swapTokensForExactTokens(address _tokenA, address _tokenB, uint256 _amountOut) private returns (uint256[] memory _amounts) {
        address[] memory _path = _getPath(_tokenA, _tokenB);
        uint256[] memory _amountsOut = _sSwap.getAmountsIn(_amountOut, _path);
        if (_amountsOut[1] > 0) {
            _amounts = _sSwap.swapTokensForExactTokens(_amountOut, type(uint256).max, _path, address(this), block.timestamp);
        }
    }

    /// @notice Function to get path for Sushi swap functions
    /// @param _tokenA Token to be swapped
    /// @param _tokenB Token to be received
    /// @return Array of addresses
    function _getPath(address _tokenA, address _tokenB) private pure returns (address[] memory) {
        address[] memory _path = new address[](2);
        _path[0] = _tokenA;
        _path[1] = _tokenB;
        return _path;
    }

    /// @notice Get total pool in USD (sum of 7 tokens)
    /// @return Total pool in USD (6 decimals)
    function getTotalPoolInUSD() public view returns (uint256) {
        IChainlink _pricefeed = IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);  // ETH/USD
        return _getTotalPool().mul(uint256(_pricefeed.latestAnswer())).div(1e20);
    }

    /// @notice Get total pool (sum of 7 tokens)
    /// @return Total pool in ETH
    function _getTotalPool() private view returns (uint256) {
        if (!isVesting) {
            uint256[] memory _pools = getFarmsPool();
            return _pools[0].add(_pools[1]).add(_pools[2]).add(_pools[3]).add(_pools[4]).add(_pools[5]).add(_pools[6]);
        } else {
            return _WETH.balanceOf(address(this));
        }
    }

    /// @notice Get current farms pool (current composition)
    /// @return Each farm pool in ETH in an array
    function getFarmsPool() public view returns (uint256[] memory) {
        uint256[] memory _pools = new uint256[](7);
        // renDOGE
        uint256[] memory _renDOGEPrice = _sSwap.getAmountsOut(1e8, _getPath(address(_renDOGE), address(_WETH)));
        _pools[0] = (_renDOGE.balanceOf(address(this))).mul(_renDOGEPrice[1]).div(1e8);
        // MATIC
        uint256[] memory _MATICPrice = _sSwap.getAmountsOut(1e18, _getPath(address(_MATIC), address(_WETH)));
        _pools[1] = (_MATIC.balanceOf(address(this))).mul(_MATICPrice[1]).div(1e18);
        // AAVE
        uint256[] memory _AAVEPrice = _sSwap.getAmountsOut(1e18, _getPath(address(_AAVE), address(_WETH)));
        _pools[2] = (_AAVE.balanceOf(address(this))).mul(_AAVEPrice[1]).div(1e18);
        // SUSHI
        uint256[] memory _SUSHIPrice = _sSwap.getAmountsOut(1e18, _getPath(address(_SUSHI), address(_WETH)));
        _pools[3] = (_SUSHI.balanceOf(address(this))).mul(_SUSHIPrice[1]).div(1e18);
        // AXS
        uint256[] memory _AXSPrice = _sSwap.getAmountsOut(1e18, _getPath(address(_AXS), address(_WETH)));
        _pools[4] = (_AXS.balanceOf(address(this))).mul(_AXSPrice[1]).div(1e18);
        // INJ
        uint256[] memory _INJPrice = _sSwap.getAmountsOut(1e18, _getPath(address(_INJ), address(_WETH)));
        _pools[5] = (_INJ.balanceOf(address(this))).mul(_INJPrice[1]).div(1e18);
        // ALCX
        uint256[] memory _ALCXPrice = _sSwap.getAmountsOut(1e18, _getPath(address(_ALCX), address(_WETH)));
        _pools[6] = (_ALCX.balanceOf(address(this))).mul(_ALCXPrice[1]).div(1e18);

        return _pools;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}