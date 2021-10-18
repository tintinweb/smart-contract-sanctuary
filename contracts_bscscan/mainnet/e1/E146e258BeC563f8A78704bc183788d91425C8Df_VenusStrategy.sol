// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error OwnableOnlyOwnerAllowedToCall();
error OwnableOnlyPendingOwnerAllowedToCall();
error OwnableOwnerZeroAddress();
error OwnableCantOwnItself();

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event PendingOwnershipTransition(address indexed owner, address indexed newOwner);
    event OwnershipTransited(address indexed owner, address indexed newOwner);

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnableOnlyOwnerAllowedToCall();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
        emit PendingOwnershipTransition(address(0), owner);
        emit OwnershipTransited(address(0), owner);
    }

    function transitOwnership(address newOwner, bool force) public onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableOwnerZeroAddress();
        }
        if (newOwner == address(this)) {
            revert OwnableCantOwnItself();
        }

        pendingOwner = newOwner;
        if (!force) {
            emit PendingOwnershipTransition(owner, newOwner);
        } else {
            owner = newOwner;
            emit OwnershipTransited(owner, newOwner);
        }
    }

    function acceptOwnership() public {
        if (msg.sender != pendingOwner) {
            revert OwnableOnlyPendingOwnerAllowedToCall();
        }

        owner = pendingOwner;
        emit OwnershipTransited(owner, pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBEP20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function getOwner() external view returns (address);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface INamedBEP20 is IBEP20 {
    function name() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IBEP20} from "./../interfaces/IBEP20.sol";

error FireDAOBnbTransferNotAllowed();
error FireDAOStrategyUnsupportedToken(IBEP20 token);

interface IStrategy {
    function invest(IBEP20 token, uint256 amount) external;

    function harvest(IBEP20 token) external;

    function divest(IBEP20 token, uint256 amount) external;

    function getInvestedAmount(IBEP20 token) external returns (uint256 investedAmount);

    function estimateTotalValue(IBEP20 token) external returns (uint256 totalValue);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error CallToNonContract(address target);

library Address {
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.call(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function delegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.delegatecall(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(account)
        }

        return codeSize > 0;
    }

    function verifyCallResult(
        bool success,
        bytes memory returnData,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returnData;
        } else {
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(returnData, 32), returnDataSize)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./../interfaces/IBEP20.sol";
import "./../libraries/SafeBEP20.sol";

interface IPancakeSwapRouter {
    function addLiquidity(
        IBEP20 tokenA,
        IBEP20 tokenB,
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IBEP20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, IBEP20[] calldata path) external view returns (uint256[] memory amounts);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (IBEP20);
}

library PancakeSwap {
    using SafeBEP20 for IBEP20;

    IPancakeSwapRouter internal constant ROUTER = IPancakeSwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    uint256 internal constant SENSIBLE_DEFAULT_SLIPPAGE_TOLERANCE = 5e15; // 0.5 %
    uint256 internal constant SENSIBLE_DEFAULT_SWAP_DEADLINE = 20 minutes;
    uint256 private constant ONE = 100e16;

    function swap(
        IBEP20 from,
        IBEP20 to,
        uint256 amount,
        uint256 slippageTolerance,
        uint256 swapDeadline
    ) internal returns (uint256 swappedAmount) {
        from.approve(address(ROUTER), amount);

        (IBEP20[] memory path, uint256 estimatedSwapAmount) = estimateSwap(from, to, amount);
        uint256[] memory amounts = ROUTER.swapExactTokensForTokens(
            amount,
            (estimatedSwapAmount * (ONE - slippageTolerance)) / ONE,
            path,
            address(this),
            block.timestamp + swapDeadline
        );
        swappedAmount = amounts[amounts.length - 1];
    }

    function estimateSwap(
        IBEP20 from,
        IBEP20 to,
        uint256 amount
    ) internal view returns (IBEP20[] memory path, uint256 estimatedSwappedAmount) {
        IBEP20 wrappedBnb = ROUTER.WETH();

        bool isDirectSwap = (from == wrappedBnb || to == wrappedBnb);
        path = new IBEP20[](isDirectSwap ? 2 : 3);
        path[0] = from;
        path[path.length - 1] = to;
        if (!isDirectSwap) {
            path[1] = wrappedBnb;
        }

        uint256[] memory amounts = ROUTER.getAmountsOut(amount, path);
        estimatedSwappedAmount = amounts[amounts.length - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./../interfaces/IBEP20.sol";
import "./Address.sol";

error SafeBEP20NoReturnData();

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        callWithOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
    }

    function callWithOptionalReturn(IBEP20 token, bytes memory data) internal {
        address tokenAddress = address(token);

        bytes memory returnData = tokenAddress.functionCall(data, "SafeBEP20: low-level call failed");
        if (returnData.length > 0) {
            if (!abi.decode(returnData, (bool))) {
                revert SafeBEP20NoReturnData();
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.9;

import "./../helpers/Ownable.sol";
import {IBEP20} from "./../interfaces/IBEP20.sol";
import "./../interfaces/IStrategy.sol";
import "./../libraries/Math.sol";
import "./../libraries/SafeBEP20.sol";
import {PancakeSwap} from "./../libraries/PancakeSwap.sol";

interface IVToken is IBEP20 {
    function mint(uint256 amount) external returns (uint256);

    function redeemUnderlying(uint256 amount) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function underlying() external view returns (IBEP20);
}

interface IUnitroller {
    function enterMarkets(IVToken[] calldata vTokens) external returns (uint256[] memory);

    function claimVenus(address account) external;

    function checkMembership(address account, IVToken vToken) external view returns (bool);

    function venusAccrued(address account) external view returns (uint256);

    function treasuryPercent() external view returns (uint256);

    function getXVSAddress() external view returns (IBEP20 xvs);
}

error FireDAOVenusStrategyVTokenMintFailed(IVToken vToken, uint256 amount);
error FireDAOVenusStrategyRedeemUnderlyingFailed(IVToken vToken, uint256 amount);

contract VenusStrategy is IStrategy, Ownable {
    using SafeBEP20 for IBEP20;
    using PancakeSwap for IBEP20;

    IUnitroller public constant UNITROLLER = IUnitroller(0xfD36E2c2a6789Db23113685031d7F16329158384);
    uint256 private constant ONE = 100e16;

    receive() external payable {
        revert FireDAOBnbTransferNotAllowed();
    }

    function salvage(IBEP20 token) external onlyOwner {
        token.safeTransfer(owner, token.balanceOf(address(this)));
    }

    function invest(IBEP20 token, uint256 amount) public override {
        IVToken vToken = getVTokenByUnderlyingToken(token);
        enterMarketIfNeeded(vToken);

        if (vToken.mint(amount) != 0) {
            revert FireDAOVenusStrategyVTokenMintFailed(vToken, amount);
        }
    }

    function divest(IBEP20 token, uint256 amount) public override {
        IVToken vToken = getVTokenByUnderlyingToken(token);

        uint256 amountToRedeem = (amount * ONE) / (ONE - UNITROLLER.treasuryPercent());
        if (vToken.redeemUnderlying(amountToRedeem) != 0) {
            revert FireDAOVenusStrategyRedeemUnderlyingFailed(vToken, amountToRedeem);
        }
    }

    function getInvestedAmount(IBEP20 token) public override returns (uint256 investedAmount) {
        IVToken vToken = getVTokenByUnderlyingToken(token);
        investedAmount = vToken.balanceOfUnderlying(address(this));
    }

    function estimateTotalValue(IBEP20 token) public override returns (uint256 totalValue) {
        IBEP20 xvs = UNITROLLER.getXVSAddress();
        IVToken vToken = getVTokenByUnderlyingToken(token);

        uint256 estimatedSwappedAmount;
        uint256 xvsAccrued = UNITROLLER.venusAccrued(address(this));
        if (xvsAccrued > 0) {
            (, estimatedSwappedAmount) = xvs.estimateSwap(vToken.underlying(), xvsAccrued);
        }

        uint256 balanceOfUnderlying = vToken.balanceOfUnderlying(address(this));
        totalValue = balanceOfUnderlying + estimatedSwappedAmount;
    }

    function harvest(IBEP20 token) public override {
        IVToken vToken = getVTokenByUnderlyingToken(token);
        UNITROLLER.claimVenus(address(this));

        IBEP20 xvs = UNITROLLER.getXVSAddress();
        uint256 balance = xvs.balanceOf(address(this));
        if (balance > 0) {
            balance = xvs.swap(
                vToken.underlying(),
                balance,
                PancakeSwap.SENSIBLE_DEFAULT_SLIPPAGE_TOLERANCE,
                PancakeSwap.SENSIBLE_DEFAULT_SWAP_DEADLINE
            );
            if (vToken.mint(balance) != 0) {
                revert FireDAOVenusStrategyVTokenMintFailed(vToken, balance);
            }
        }
    }

    function enterMarketIfNeeded(IVToken vToken) internal {
        if (!UNITROLLER.checkMembership(address(this), vToken)) {
            IVToken[] memory vTokens = new IVToken[](1);
            vTokens[0] = vToken;
            UNITROLLER.enterMarkets(vTokens);

            vToken.underlying().approve(address(vToken), type(uint256).max);
        }
    }

    function getVTokenByUnderlyingToken(IBEP20 underlyingToken) internal pure returns (IVToken vToken) {
        // DAI
        if (underlyingToken == IBEP20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3)) {
            return IVToken(0x334b3eCB4DCa3593BCCC3c7EBD1A1C1d1780FBF1);
        }
        // USDT
        if (underlyingToken == IBEP20(0x55d398326f99059fF775485246999027B3197955)) {
            return IVToken(0xfD5840Cd36d94D7229439859C0112a4185BC0255);
        }
        // USDC
        if (underlyingToken == IBEP20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d)) {
            return IVToken(0xecA88125a5ADbe82614ffC12D0DB554E2e2867C8);
        }
        // BUSD
        if (underlyingToken == IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)) {
            return IVToken(0x95c78222B3D6e262426483D42CfA53685A67Ab9D);
        }

        revert FireDAOStrategyUnsupportedToken(underlyingToken);
    }
}