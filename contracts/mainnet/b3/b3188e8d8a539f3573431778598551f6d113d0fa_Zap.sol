// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20, SafeMath} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {AccessControlDefended} from "./common/AccessControlDefended.sol";

import {ISett} from "./interfaces/ISett.sol";
import {IBadgerSettPeak, IByvWbtcPeak} from "./interfaces/IPeak.sol";
import {IbBTC} from "./interfaces/IbBTC.sol";
import {IbyvWbtc} from "./interfaces/IbyvWbtc.sol";

contract Zap is AccessControlDefended {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IBadgerSettPeak public constant settPeak = IBadgerSettPeak(0x41671BA1abcbA387b9b2B752c205e22e916BE6e3);
    IByvWbtcPeak public constant byvWbtcPeak = IByvWbtcPeak(0x825218beD8BE0B30be39475755AceE0250C50627);
    IbBTC public constant ibbtc = IbBTC(0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F);

    IERC20 public constant ren = IERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    IERC20 public constant wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    struct Pool {
        IERC20 lpToken;
        ICurveFi deposit;
        ISett sett;
    }
    Pool[4] public pools;

    constructor() public {
        pools[0] = Pool({ // crvRenWBTC [ ren, wbtc ]
            lpToken: IERC20(0x49849C98ae39Fff122806C06791Fa73784FB3675),
            deposit: ICurveFi(0x93054188d876f558f4a66B2EF1d97d16eDf0895B),
            sett: ISett(0x6dEf55d2e18486B9dDfaA075bc4e4EE0B28c1545)
        });
        pools[1] = Pool({ // crvRenWSBTC [ ren, wbtc, sbtc ]
            lpToken: IERC20(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3),
            deposit: ICurveFi(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714),
            sett: ISett(0xd04c48A53c111300aD41190D63681ed3dAd998eC)
        });
        pools[2] = Pool({ // tbtc-sbtcCrv [ tbtc, ren, wbtc, sbtc ]
            lpToken: IERC20(0x64eda51d3Ad40D56b9dFc5554E06F94e1Dd786Fd),
            deposit: ICurveFi(0xaa82ca713D94bBA7A89CEAB55314F9EfFEdDc78c),
            sett: ISett(0xb9D076fDe463dbc9f915E5392F807315Bf940334)
        });
        pools[3] = Pool({ // Exclusive to wBTC
            lpToken: wbtc,
            deposit: ICurveFi(0x0),
            sett: ISett(0x4b92d19c11435614CD49Af1b589001b7c08cD4D5) // byvWbtc
        });

        // Since we don't hold any tokens in this contract, we can optimize gas usage in mint calls by providing infinite approvals
        for (uint i = 0; i < pools.length; i++) {
            Pool memory pool = pools[i];
            pool.lpToken.safeApprove(address(pool.sett), uint(-1));
            if (i < 3) {
                ren.safeApprove(address(pool.deposit), uint(-1));
                wbtc.safeApprove(address(pool.deposit), uint(-1));
                IERC20(address(pool.sett)).safeApprove(address(settPeak), uint(-1));
            } else {
                IERC20(address(pool.sett)).safeApprove(address(byvWbtcPeak), uint(-1));
            }
        }
    }

    /**
    * @notice Mint ibbtc with wBTC / renBTC
    * @param token wBTC or renBTC address
    * @param amount wBTC or renBTC amount
    * @param poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv, 3=yvWbtc
    * @param idx Index of the token in the curve pool while adding liquidity; redundant for yvWbtc
    * @param minOut Minimum amount of ibbtc to mint. Use for capping slippage while adding liquidity to curve pool.
    * @return _ibbtc Minted ibbtc amount
    */
    function mint(IERC20 token, uint amount, uint poolId, uint idx, uint minOut)
        external
        defend
        blockLocked
        returns(uint _ibbtc)
    {
        Pool memory pool = pools[poolId];

        token.safeTransferFrom(msg.sender, address(this), amount);

        if (poolId < 3) { // setts
            _addLiquidity(pool.deposit, amount, poolId + 2, idx); // pools are such that the #tokens they support is +2 from their poolId.
            pool.sett.deposit(pool.lpToken.balanceOf(address(this)));
            _ibbtc = settPeak.mint(poolId, pool.sett.balanceOf(address(this)), new bytes32[](0));
        } else if (poolId == 3) { // byvwbtc
            IbyvWbtc(address(pool.sett)).deposit(new bytes32[](0)); // pulls all available
            _ibbtc = byvWbtcPeak.mint(pool.sett.balanceOf(address(this)), new bytes32[](0));
        } else {
            revert("INVALID_POOL_ID");
        }

        require(_ibbtc >= minOut, "INSUFFICIENT_IBBTC"); // used for capping slippage in curve pools
        IERC20(address(ibbtc)).safeTransfer(msg.sender, _ibbtc);
    }

    /**
    * @dev Add liquidity to curve btc pools
    * @param amount wBTC / renBTC amount
    * @param pool Curve btc pool
    * @param numTokens # supported tokens for the curve pool
    * @param idx Index of the supported token in the curve pool in question
    */
    function _addLiquidity(ICurveFi pool, uint amount, uint numTokens, uint idx) internal {
        if (numTokens == 2) {
            uint[2] memory amounts;
            amounts[idx] = amount;
            pool.add_liquidity(amounts, 0);
        }

        if (numTokens == 3) {
            uint[3] memory amounts;
            amounts[idx] = amount;
            pool.add_liquidity(amounts, 0);
        }

        if (numTokens == 4) {
            uint[4] memory amounts;
            amounts[idx] = amount;
            pool.add_liquidity(amounts, 0);
        }
    }

    /**
    * @notice Calculate the most optimal route and expected ibbtc amount when minting with wBTC / renBtc.
    * @dev Use returned params poolId, idx and bBTC in the call to mint(...)
           The last param `minOut` in mint(...) should be a bit more than the returned bBTC value.
           For instance 0.2% - 1% higher depending on slippage tolerange.
    * @param amount renBTC amount
    * @return poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv, 3=byvwbtc
    * @return idx Index of the supported token in the curve pool (poolId). Should be ignored for poolId=3
    * @return bBTC Expected ibbtc. Not for precise calculations. Doesn't factor in (deposit) fee charged by the curve pool / byvwbtc.
    * @return fee Fee being charged by ibbtc system. Denominated in corresponding sett token
    */
    function calcMint(address token, uint amount) external view returns(uint poolId, uint idx, uint bBTC, uint fee) {
        if (token == address(ren)) {
            return calcMintWithRen(amount);
        }
        if (token == address(wbtc)) {
            return calcMintWithWbtc(amount);
        }
        revert("INVALID_TOKEN");
    }

    /**
    * @notice Calculate the most optimal route and expected ibbtc amount when minting with renBTC.
    * @dev Use returned params poolId, idx and bBTC in the call to mint(...)
           The last param `minOut` in mint(...) should be a bit more than the returned bBTC value.
           For instance 0.2% - 1% higher depending on slippage tolerange.
    * @param amount renBTC amount
    * @return poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv
    * @return idx Index of the supported token in the curve pool (poolId)
    * @return bBTC Expected ibbtc. Not for precise calculations. Doesn't factor in fee charged by the curve pool
    * @return fee Fee being charged by ibbtc system. Denominated in corresponding sett token
    */
    function calcMintWithRen(uint amount) public view returns(uint poolId, uint idx, uint bBTC, uint fee) {
        uint _ibbtc;
        uint _fee;

        // poolId=0, idx=0
        (bBTC, fee) = curveLPToIbbtc(0, pools[0].deposit.calc_token_amount([amount,0], true));

        (_ibbtc, _fee) = curveLPToIbbtc(1, pools[1].deposit.calc_token_amount([amount,0,0], true));
        if (_ibbtc > bBTC) {
            bBTC = _ibbtc;
            fee = _fee;
            poolId = 1;
            // idx=0
        }

        (_ibbtc, _fee) = curveLPToIbbtc(2, pools[2].deposit.calc_token_amount([0,amount,0,0], true));
        if (_ibbtc > bBTC) {
            bBTC = _ibbtc;
            fee = _fee;
            poolId = 2;
            idx = 1;
        }
    }

    /**
    * @notice Calculate the most optimal route and expected ibbtc amount when minting with wBTC.
    * @dev Use returned params poolId, idx and bBTC in the call to mint(...)
           The last param `minOut` in mint(...) should be a bit more than the returned bBTC value.
           For instance 0.2% - 1% higher depending on slippage tolerange.
    * @param amount renBTC amount
    * @return poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv, 3=byvwbtc
    * @return idx Index of the supported token in the curve pool (poolId). Should be ignored for poolId=3
    * @return bBTC Expected ibbtc. Not for precise calculations. Doesn't factor in (deposit) fee charged by the curve pool / byvwbtc.
    * @return fee Fee being charged by ibbtc system. Denominated in corresponding sett token
    */
    function calcMintWithWbtc(uint amount) public view returns(uint poolId, uint idx, uint bBTC, uint fee) {
        uint _ibbtc;
        uint _fee;

        // poolId=0
        (bBTC, fee) = curveLPToIbbtc(0, pools[0].deposit.calc_token_amount([0,amount], true));
        idx = 1;

        (_ibbtc, _fee) = curveLPToIbbtc(1, pools[1].deposit.calc_token_amount([0,amount,0], true));
        if (_ibbtc > bBTC) {
            bBTC = _ibbtc;
            fee = _fee;
            poolId = 1;
            // idx=1
        }

        (_ibbtc, _fee) = curveLPToIbbtc(2, pools[2].deposit.calc_token_amount([0,0,amount,0], true));
        if (_ibbtc > bBTC) {
            bBTC = _ibbtc;
            fee = _fee;
            poolId = 2;
            idx = 2;
        }

        // for byvwbtc, sett.pricePerShare returns a wbtc value, as opposed to lpToken amount in setts
        (_ibbtc, _fee) = byvWbtcPeak.calcMint(amount.mul(1e8).div(IbyvWbtc(address(pools[3].sett)).pricePerShare()));
        if (_ibbtc > bBTC) {
            bBTC = _ibbtc;
            fee = _fee;
            poolId = 3;
            // idx value will be ignored anyway
        }
    }

    /**
    * @dev Curve LP token amount to expected ibbtc amount
    */
    function curveLPToIbbtc(uint poolId, uint _lp) public view returns(uint bBTC, uint fee) {
        Pool memory pool = pools[poolId];
        uint _sett = _lp.mul(1e18).div(pool.sett.getPricePerFullShare());
        return settPeak.calcMint(poolId, _sett);
    }
}

interface ICurveFi {
    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount) external;
    function calc_token_amount(uint[2] calldata amounts, bool isDeposit) external view returns(uint);

    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;
    function calc_token_amount(uint[3] calldata amounts, bool isDeposit) external view returns(uint);

    function add_liquidity(uint[4] calldata amounts, uint min_mint_amount) external;
    function calc_token_amount(uint[4] calldata amounts, bool isDeposit) external view returns(uint);
}

interface IyvWbtc {
    function deposit(uint) external;
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

pragma solidity 0.6.11;

import {GovernableProxy} from "./proxy/GovernableProxy.sol";

contract AccessControlDefended is GovernableProxy {
    mapping (address => bool) public approved;
    mapping(address => uint256) public blockLock;
    uint256[50] private __gap;

    modifier defend() {
        require(msg.sender == tx.origin || approved[msg.sender], "ACCESS_DENIED");
        _;
    }

    modifier blockLocked() {
        require(blockLock[msg.sender] < block.number, "BLOCK_LOCKED");
        _;
    }

    function _lockForBlock(address account) internal {
        blockLock[account] = block.number;
    }

    function approveContractAccess(address account) external onlyGovernance {
        approved[account] = true;
    }

    function revokeContractAccess(address account) external onlyGovernance {
        approved[account] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISett is IERC20 {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _shares) external;
    function withdrawAll() external;
    function approveContractAccess(address account) external;

    function getPricePerFullShare() external view returns (uint256);
    function balance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IPeak {
    function portfolioValue() external view returns (uint);
}

interface IBadgerSettPeak is IPeak {
    function mint(uint poolId, uint inAmount, bytes32[] calldata merkleProof)
        external
        returns(uint outAmount);

    function calcMint(uint poolId, uint inAmount)
        external
        view
        returns(uint bBTC, uint fee);
}

interface IByvWbtcPeak is IPeak {
    function mint(uint inAmount, bytes32[] calldata merkleProof)
        external
        returns(uint outAmount);

    function calcMint(uint inAmount)
        external
        view
        returns(uint bBTC, uint fee);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IbBTC is IERC20 {
    function mint(address account, uint amount) external;
    function burn(address account, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IbyvWbtc is IERC20 {
    function pricePerShare() external view returns (uint);
    function deposit(bytes32[] calldata merkleProof) external;
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

pragma solidity 0.6.11;

contract GovernableProxy {
    bytes32 constant OWNER_SLOT = keccak256("proxy.owner");

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _transferOwnership(msg.sender);
    }

    modifier onlyGovernance() {
        require(owner() == msg.sender, "NOT_OWNER");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address _owner) {
        bytes32 position = OWNER_SLOT;
        assembly {
            _owner := sload(position)
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function transferOwnership(address newOwner) external onlyGovernance {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "OwnableProxy: new owner is the zero address");
        emit OwnershipTransferred(owner(), newOwner);
        bytes32 position = OWNER_SLOT;
        assembly {
            sstore(position, newOwner)
        }
    }
}

{
  "optimizer": {
    "enabled": false,
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
  "libraries": {}
}