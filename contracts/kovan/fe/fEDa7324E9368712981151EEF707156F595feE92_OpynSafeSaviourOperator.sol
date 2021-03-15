// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract ERC20Like {
    uint256 public totalSupply;

    function balanceOf(address guy) public virtual returns (uint256);

    function approve(address guy, uint256 wad) public virtual returns (bool);

    function transfer(address dst, uint256 wad) public virtual returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

pragma experimental ABIEncoderV2;

enum ActionType {
    OpenVault,
    MintShortOption,
    BurnShortOption,
    DepositLongOption,
    WithdrawLongOption,
    DepositCollateral,
    WithdrawCollateral,
    SettleVault,
    Redeem,
    Call
}

struct ActionArgs {
    ActionType actionType;
    address owner;
    address secondAddress;
    address asset;
    uint256 vaultId;
    uint256 amount;
    uint256 index;
    bytes data;
}

abstract contract OpynV2ControllerLike {
    function operate(ActionArgs[] calldata _actions) external virtual;

    function getPayout(address _otoken, uint256 _amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract OpynV2OTokenLike {
    function getOtokenDetails()
        external
        view
        virtual
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract OpynV2WhitelistLike {
    function isWhitelistedOtoken(address _otoken) external view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract SAFESaviourRegistryLike {
    mapping(address => uint256) public authorizedAccounts;

    function markSave(bytes32 collateralType, address safeHandler) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract UniswapV2Router02Like {
    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

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
contract SafeMath {
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

pragma experimental ABIEncoderV2;

import '../interfaces/OpynV2OTokenLike.sol';
import '../interfaces/OpynV2ControllerLike.sol';
import '../interfaces/OpynV2WhitelistLike.sol';
import '../interfaces/UniswapV2Router02Like.sol';
import '../interfaces/SAFESaviourRegistryLike.sol';
import '../interfaces/ERC20Like.sol';
import '../math/SafeMath.sol';

contract OpynSafeSaviourOperator is SafeMath {
    // The Opyn v2 Controller to interact with oTokens
    OpynV2ControllerLike public opynV2Controller;
    // The Opyn v2 Whitelist to check oTokens' validity
    OpynV2WhitelistLike public opynV2Whitelist;
    // The Uniswap v2 router 02 to swap collaterals
    UniswapV2Router02Like public uniswapV2Router02;
    // oToken type selected by each SAFE
    mapping(address => address) public oTokenSelection;
    // Entity whitelisting allowed saviours
    SAFESaviourRegistryLike public saviourRegistry;

    // Events
    event ToggleOToken(address oToken, uint256 whitelistState);

    constructor(
        address opynV2Controller_,
        address opynV2Whitelist_,
        address uniswapV2Router02_,
        address saviourRegistry_
    ) {
        require(opynV2Controller_ != address(0), 'OpynSafeSaviour/null-opyn-v2-controller');
        require(opynV2Whitelist_ != address(0), 'OpynSafeSaviour/null-opyn-v2-whitelist');
        require(uniswapV2Router02_ != address(0), 'OpynSafeSaviour/null-uniswap-v2-router02');
        require(saviourRegistry_ != address(0), 'OpynSafeSaviour/null-saviour-registry');

        opynV2Controller = OpynV2ControllerLike(opynV2Controller_);
        opynV2Whitelist = OpynV2WhitelistLike(opynV2Whitelist_);
        uniswapV2Router02 = UniswapV2Router02Like(uniswapV2Router02_);
        saviourRegistry = SAFESaviourRegistryLike(saviourRegistry_);
    }

    function isOTokenPutOption(address _otoken) external view returns (bool) {
        (, , , , , bool isPut) = OpynV2OTokenLike(_otoken).getOtokenDetails();
        return isPut;
    }

    function getOpynPayout(address _otoken, uint256 _amount) external view returns (uint256) {
        return opynV2Controller.getPayout(_otoken, _amount);
    }

    modifier isSaviourRegistryAuthorized() {
        require(saviourRegistry.authorizedAccounts(msg.sender) == 1, 'OpynSafeSaviour/account-not-authorized');
        _;
    }

    function redeemAndSwapOTokens(
        address _otoken,
        uint256 _amountIn,
        uint256 _amountOut,
        address _safeCollateral
    ) external {
        ERC20Like(_otoken).transferFrom(msg.sender, address(this), _amountIn);

        (address oTokenCollateral, , , , , ) = OpynV2OTokenLike(_otoken).getOtokenDetails();

        uint256 redeemedOTokenCollateral;

        {
            // Opyn Redeem

            uint256 preRedeemBalance = ERC20Like(oTokenCollateral).balanceOf(address(this));

            // Build Opyn Action
            ActionArgs[] memory redeemAction = new ActionArgs[](1);
            redeemAction[0].actionType = ActionType.Redeem;
            redeemAction[0].owner = address(0);
            redeemAction[0].secondAddress = address(this);
            redeemAction[0].asset = _otoken;
            redeemAction[0].vaultId = 0;
            redeemAction[0].amount = _amountIn;

            // Trigger oToken collateral redeem
            opynV2Controller.operate(redeemAction);

            redeemedOTokenCollateral = sub(ERC20Like(oTokenCollateral).balanceOf(address(this)), preRedeemBalance);
        }

        uint256 swappedSafeCollateral;

        {
            // Uniswap swap

            // Retrieve pre-swap WETH balance
            uint256 safeCollateralBalance = ERC20Like(_safeCollateral).balanceOf(address(this));

            // Path argument for the uniswap router
            address[] memory path = new address[](2);
            path[0] = oTokenCollateral;
            path[1] = _safeCollateral;

            ERC20Like(oTokenCollateral).approve(address(uniswapV2Router02), redeemedOTokenCollateral);

            uniswapV2Router02.swapExactTokensForTokens(
                redeemedOTokenCollateral,
                _amountOut,
                path,
                address(this),
                block.timestamp
            );

            // Retrieve post-swap WETH balance. Would overflow and throw if balance decreased
            swappedSafeCollateral = sub(ERC20Like(_safeCollateral).balanceOf(address(this)), safeCollateralBalance);
        }

        ERC20Like(_safeCollateral).transfer(msg.sender, swappedSafeCollateral);
    }

    function oTokenWhitelist(address _otoken) external view returns (bool) {
        return opynV2Whitelist.isWhitelistedOtoken(_otoken);
    }

    function getOTokenAmountToApprove(
        address _otoken,
        uint256 _requiredOutputAmount,
        address _safeCollateralAddress
    ) external view returns (uint256) {
        (address oTokenCollateralAddress, , , , , ) = OpynV2OTokenLike(_otoken).getOtokenDetails();

        address[] memory path = new address[](2);
        path[0] = oTokenCollateralAddress;
        path[1] = _safeCollateralAddress;

        uint256 oTokenCollateralAmountRequired = uniswapV2Router02.getAmountsIn(_requiredOutputAmount, path)[0];

        uint256 payoutPerToken = opynV2Controller.getPayout(_otoken, 1);

        require(payoutPerToken > 0, 'OpynSafeSaviour/no-collateral-to-redeem');

        uint256 amountToApprove = div(oTokenCollateralAmountRequired, payoutPerToken);

        // Integer division rounds to zero, better ensure we get at least the required amount
        if (mul(amountToApprove, payoutPerToken) < _requiredOutputAmount) {
            amountToApprove += 1;
        }

        return amountToApprove;
    }
}