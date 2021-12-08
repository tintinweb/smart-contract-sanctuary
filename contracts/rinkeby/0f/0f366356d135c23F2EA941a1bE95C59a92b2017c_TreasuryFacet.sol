// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Facet.sol";

interface IBondCalculator {
    function valuation(address pair_, uint256 amount_)
        external
        view
        returns (uint256 _value);
}

interface IERC20Mintable {
    function decimals() external view returns (uint256);

    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;

    function burnFrom(address account_, uint256 amount_) external;
}

contract TreasuryFacet is Facet {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed token, uint256 amount, uint256 value);
    event Withdrawal(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event RepayDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event ReservesManaged(address indexed token, uint256 amount);
    event ReservesUpdated(uint256 indexed totalReserves);
    event ReservesAudited(uint256 indexed totalReserves);
    event RewardsMinted(
        address indexed caller,
        address indexed recipient,
        uint256 amount
    );
    event ChangeQueued(MANAGING indexed managing, address queued);
    event ChangeActivated(
        MANAGING indexed managing,
        address activated,
        bool result
    );

    enum MANAGING {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        DEBTOR,
        REWARDMANAGER,
        NNECC
    }

    function initializeTreasury(
        address _Necc,
        address _nNecc,
        address _NDOL,
        uint256 _blocksNeededForQueue
    ) external {
        onlyGov();
        require(_Necc != address(0));
        require(_nNecc != address(0));
        s.nNecc = _nNecc;
        s.Necc = _Necc;

        s.isReserveToken[_NDOL] = true;
        s.reserveTokens.push(_NDOL);

        s.blocksNeededForQueue = _blocksNeededForQueue;
    }

    /**
        @notice send epoch reward to staking contract
     */
    function mintRewards(address _recipient, uint256 _amount) external {
        require(s.isRewardManager[msg.sender], "Treasury: Not approved");
        require(_amount <= excessReserves(), "Treasury: Insufficient reserves");

        IERC20Mintable(s.Necc).mint(_recipient, _amount);

        emit RewardsMinted(msg.sender, _recipient, _amount);
    }

    /**
        @notice allow approved address to deposit an asset for Necc
        @param _amount uint
        @param _token address
        @param _profit uint
        @return send_ uint
     */
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256 send_) {
        require(
            s.isReserveToken[_token] || s.isLiquidityToken[_token],
            "Treasury: Not accepted"
        );
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        if (s.isReserveToken[_token]) {
            require(s.isReserveDepositor[msg.sender], "Treasury: Not approved");
        } else {
            require(
                s.isLiquidityDepositor[msg.sender],
                "Treasury: Not approved"
            );
        }

        uint256 value = valueOfToken(_token, _amount);
        // mint Necc needed and store amount of rewards for distribution
        send_ = value.sub(_profit);
        IERC20Mintable(s.Necc).mint(msg.sender, send_);

        s.totalReserves = s.totalReserves.add(value);
        emit ReservesUpdated(s.totalReserves);

        emit Deposit(_token, _amount, value);

        return send_;
    }

    /**
        @notice allow approved address to burn Necc for reserves
        @param _amount uint
        @param _token address
     */
    function withdraw(uint256 _amount, address _token) external {
        require(s.isReserveToken[_token], "Treasury: Not accepted"); // Only reserves can be used for redemptions
        require(
            s.isReserveSpender[msg.sender] == true,
            "Treasury: Not approved"
        );

        uint256 _value = valueOfToken(_token, _amount);
        IERC20Mintable(s.Necc).burnFrom(msg.sender, _value);

        s.totalReserves = s.totalReserves.sub(_value);
        emit ReservesUpdated(s.totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_token, _amount, _value);
    }

    /**
        @notice allow approved address to borrow reserves
        @param _amount uint
        @param _token address
     */
    function incurDebt(uint256 _amount, address _token) external {
        require(s.isDebtor[msg.sender], "Treasury: Not approved");
        require(s.isReserveToken[_token], "Treasury: Not accepted");

        uint256 _value = valueOfToken(_token, _amount);

        uint256 maximumDebt = IERC20(s.sNecc).balanceOf(msg.sender); // Can only borrow against sNecc held
        uint256 availableDebt = maximumDebt.sub(s.debtorBalance[msg.sender]);
        require(_value <= availableDebt, "Exceeds debt limit");

        s.debtorBalance[msg.sender] = s.debtorBalance[msg.sender].add(_value);
        s.totalDebt = s.totalDebt.add(_value);

        s.totalReserves = s.totalReserves.sub(_value);
        emit ReservesUpdated(s.totalReserves);

        IERC20(_token).transfer(msg.sender, _amount);

        emit CreateDebt(msg.sender, _token, _amount, _value);
    }

    /**
        @notice allow approved address to repay borrowed reserves with reserves
        @param _amount uint
        @param _token address
     */
    function repayDebtWithReserve(uint256 _amount, address _token) external {
        require(s.isDebtor[msg.sender], "Treasury: Not approved");
        require(s.isReserveToken[_token], "Treasury: Not accepted");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _value = valueOfToken(_token, _amount);
        s.debtorBalance[msg.sender] = s.debtorBalance[msg.sender].sub(_value);
        s.totalDebt = s.totalDebt.sub(_value);

        s.totalReserves = s.totalReserves.add(_value);
        emit ReservesUpdated(s.totalReserves);

        emit RepayDebt(msg.sender, _token, _amount, _value);
    }

    /**
        @notice allow approved address to repay borrowed reserves with Necc
        @param _amount uint
     */
    function repayDebtWithNecc(uint256 _amount) external {
        require(s.isDebtor[msg.sender], "Treasury: Not approved");

        IERC20Mintable(s.Necc).burnFrom(msg.sender, _amount);

        s.debtorBalance[msg.sender] = s.debtorBalance[msg.sender].sub(_amount);
        s.totalDebt = s.totalDebt.sub(_amount);

        emit RepayDebt(msg.sender, s.Necc, _amount, _amount);
    }

    /**
        @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
     */
    function manage(address _token, uint256 _amount) external {
        if (s.isLiquidityToken[_token]) {
            require(s.isLiquidityManager[msg.sender], "Treasury: Not approved");
        } else {
            require(s.isReserveManager[msg.sender], "Treasury: Not approved");
        }

        uint256 _value = valueOfToken(_token, _amount);
        (_token, _amount);
        require(_value <= excessReserves(), "Treasury: Insufficient reserves");

        s.totalReserves = s.totalReserves.sub(_value);
        emit ReservesUpdated(s.totalReserves);

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit ReservesManaged(_token, _amount);
    }

    /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
    function excessReserves() public view returns (uint256) {
        return
            s.totalReserves.sub(IERC20(s.Necc).totalSupply().sub(s.totalDebt));
    }

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external {
        onlyGov();
        uint256 reserves;
        for (uint256 i = 0; i < s.reserveTokens.length; i++) {
            reserves = reserves.add(
                valueOfToken(
                    s.reserveTokens[i],
                    IERC20(s.reserveTokens[i]).balanceOf(address(this))
                )
            );
        }
        for (uint256 i = 0; i < s.liquidityTokens.length; i++) {
            reserves = reserves.add(
                valueOfToken(
                    s.liquidityTokens[i],
                    IERC20(s.liquidityTokens[i]).balanceOf(address(this))
                )
            );
        }
        s.totalReserves = reserves;
        emit ReservesUpdated(reserves);
        emit ReservesAudited(reserves);
    }

    /**
        @notice returns Necc valuation of asset
        @param _token address
        @param _amount uint
        @return _value uint
     */
    function valueOfToken(address _token, uint256 _amount)
        public
        view
        returns (uint256 _value)
    {
        if (s.isReserveToken[_token]) {
            // convert amount to match Necc decimals
            _value = _amount.mul(10**IERC20Mintable(s.Necc).decimals()).div(
                10**IERC20Mintable(_token).decimals()
            );
        } else if (s.isLiquidityToken[_token]) {
            _value = IBondCalculator(address(this)).valuation(_token, _amount);
        }
    }

    /**
        @notice queue address to change boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
    function queue(MANAGING _managing, address _address)
        external
        returns (bool)
    {
        onlyGov();
        require(_address != address(0));
        if (_managing == MANAGING.RESERVEDEPOSITOR) {
            // 0
            s.reserveDepositorQueue[_address] = block.number.add(
                s.blocksNeededForQueue
            );
        } else if (_managing == MANAGING.RESERVESPENDER) {
            // 1
            s.reserveSpenderQueue[_address] = block.number.add(
                s.blocksNeededForQueue
            );
        } else if (_managing == MANAGING.RESERVETOKEN) {
            // 2
            s.reserveTokenQueue[_address] = block.number.add(
                s.blocksNeededForQueue
            );
        } else if (_managing == MANAGING.RESERVEMANAGER) {
            // 3
            s.ReserveManagerQueue[_address] = block.number.add(
                s.blocksNeededForQueue.mul(2)
            );
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
            // 4
            s.LiquidityDepositorQueue[_address] = block.number.add(
                s.blocksNeededForQueue
            );
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
            // 5
            s.LiquidityTokenQueue[_address] = block.number.add(
                s.blocksNeededForQueue
            );
        } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
            // 6
            s.LiquidityManagerQueue[_address] = block.number.add(
                s.blocksNeededForQueue.mul(2)
            );
        } else if (_managing == MANAGING.DEBTOR) {
            // 7
            s.debtorQueue[_address] = block.number.add(s.blocksNeededForQueue);
        } else if (_managing == MANAGING.REWARDMANAGER) {
            // 8
            s.rewardManagerQueue[_address] = block.number.add(
                s.blocksNeededForQueue
            );
        } else if (_managing == MANAGING.NNECC) {
            // 9
            s.sNeccQueue = block.number.add(s.blocksNeededForQueue);
        } else return false;

        emit ChangeQueued(_managing, _address);
        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
    function toggle(MANAGING _managing, address _address)
        external
        returns (bool)
    {
        onlyGov();
        require(_address != address(0));
        bool _result;
        if (_managing == MANAGING.RESERVEDEPOSITOR) {
            // 0
            if (
                requirements(
                    s.reserveDepositorQueue,
                    s.isReserveDepositor,
                    _address
                )
            ) {
                s.reserveDepositorQueue[_address] = 0;
                if (!listContains(s.reserveDepositors, _address)) {
                    s.reserveDepositors.push(_address);
                }
            }
            _result = !s.isReserveDepositor[_address];
            s.isReserveDepositor[_address] = _result;
        } else if (_managing == MANAGING.RESERVESPENDER) {
            // 1
            if (
                requirements(
                    s.reserveSpenderQueue,
                    s.isReserveSpender,
                    _address
                )
            ) {
                s.reserveSpenderQueue[_address] = 0;
                if (!listContains(s.reserveSpenders, _address)) {
                    s.reserveSpenders.push(_address);
                }
            }
            _result = !s.isReserveSpender[_address];
            s.isReserveSpender[_address] = _result;
        } else if (_managing == MANAGING.RESERVETOKEN) {
            // 2
            if (requirements(s.reserveTokenQueue, s.isReserveToken, _address)) {
                s.reserveTokenQueue[_address] = 0;
                if (!listContains(s.reserveTokens, _address)) {
                    s.reserveTokens.push(_address);
                }
            }
            _result = !s.isReserveToken[_address];
            s.isReserveToken[_address] = _result;
        } else if (_managing == MANAGING.RESERVEMANAGER) {
            // 3
            if (
                requirements(
                    s.ReserveManagerQueue,
                    s.isReserveManager,
                    _address
                )
            ) {
                s.reserveManagers.push(_address);
                s.ReserveManagerQueue[_address] = 0;
                if (!listContains(s.reserveManagers, _address)) {
                    s.reserveManagers.push(_address);
                }
            }
            _result = !s.isReserveManager[_address];
            s.isReserveManager[_address] = _result;
        } else if (_managing == MANAGING.LIQUIDITYDEPOSITOR) {
            // 4
            if (
                requirements(
                    s.LiquidityDepositorQueue,
                    s.isLiquidityDepositor,
                    _address
                )
            ) {
                s.liquidityDepositors.push(_address);
                s.LiquidityDepositorQueue[_address] = 0;
                if (!listContains(s.liquidityDepositors, _address)) {
                    s.liquidityDepositors.push(_address);
                }
            }
            _result = !s.isLiquidityDepositor[_address];
            s.isLiquidityDepositor[_address] = _result;
        } else if (_managing == MANAGING.LIQUIDITYTOKEN) {
            // 5
            if (
                requirements(
                    s.LiquidityTokenQueue,
                    s.isLiquidityToken,
                    _address
                )
            ) {
                s.LiquidityTokenQueue[_address] = 0;
                if (!listContains(s.liquidityTokens, _address)) {
                    s.liquidityTokens.push(_address);
                }
            }
            _result = !s.isLiquidityToken[_address];
            s.isLiquidityToken[_address] = _result;
        } else if (_managing == MANAGING.LIQUIDITYMANAGER) {
            // 6
            if (
                requirements(
                    s.LiquidityManagerQueue,
                    s.isLiquidityManager,
                    _address
                )
            ) {
                s.LiquidityManagerQueue[_address] = 0;
                if (!listContains(s.liquidityManagers, _address)) {
                    s.liquidityManagers.push(_address);
                }
            }
            _result = !s.isLiquidityManager[_address];
            s.isLiquidityManager[_address] = _result;
        } else if (_managing == MANAGING.DEBTOR) {
            // 7
            if (requirements(s.debtorQueue, s.isDebtor, _address)) {
                s.debtorQueue[_address] = 0;
                if (!listContains(s.debtors, _address)) {
                    s.debtors.push(_address);
                }
            }
            _result = !s.isDebtor[_address];
            s.isDebtor[_address] = _result;
        } else if (_managing == MANAGING.REWARDMANAGER) {
            // 8
            if (
                requirements(s.rewardManagerQueue, s.isRewardManager, _address)
            ) {
                s.rewardManagerQueue[_address] = 0;
                if (!listContains(s.rewardManagers, _address)) {
                    s.rewardManagers.push(_address);
                }
            }
            _result = !s.isRewardManager[_address];
            s.isRewardManager[_address] = _result;
        } else if (_managing == MANAGING.NNECC) {
            // 9
            s.sNeccQueue = 0;
            s.sNecc = _address;
            _result = true;
        } else return false;

        emit ChangeActivated(_managing, _address, _result);
        return true;
    }

    /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param _address address
        @return bool 
     */
    function requirements(
        mapping(address => uint256) storage queue_,
        mapping(address => bool) storage status_,
        address _address
    ) internal view returns (bool) {
        if (!status_[_address]) {
            require(queue_[_address] != 0, "Must queue");
            require(queue_[_address] <= block.number, "Queue not expired");
            return true;
        }
        return false;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains(address[] storage _list, address _token)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _token) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.10;

import "../../lib/LibTreasuryStorage.sol";
import "../../lib/LibDiamond.sol";

contract Facet {
    LibTreasuryStorage.Storage internal s;

    function onlyGov() internal view {
        LibDiamond.enforceIsContractOwner();
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// import "hardhat/console.sol";

library LibTreasuryStorage {
    bytes32 constant STORAGE_POSITION = keccak256("necc.dao.treasury.storage");

    // Single global store
    struct Storage {
        address Necc;
        address nNecc;
        address sNecc;
        uint256 blocksNeededForQueue;
        address[] reserveTokens; // Push only, beware false-positives.
        uint256 sNeccQueue; // Delays change to sNecc address
        uint256 totalReserves; // Risk-free value of all assets
        uint256 totalDebt;
        mapping(address => bool) isReserveToken;
        mapping(address => uint256) reserveTokenQueue; // Delays changes to mapping.
        address[] reserveDepositors; // Push only, beware false-positives. Only for viewing.
        mapping(address => bool) isReserveDepositor;
        mapping(address => uint256) reserveDepositorQueue; // Delays changes to mapping.
        address[] reserveSpenders; // Push only, beware false-positives. Only for viewing.
        mapping(address => bool) isReserveSpender;
        mapping(address => uint256) reserveSpenderQueue; // Delays changes to mapping.
        address[] liquidityTokens; // Push only, beware false-positives.
        mapping(address => bool) isLiquidityToken;
        mapping(address => uint256) LiquidityTokenQueue; // Delays changes to mapping.
        address[] liquidityDepositors; // Push only, beware false-positives. Only for viewing.
        mapping(address => bool) isLiquidityDepositor;
        mapping(address => uint256) LiquidityDepositorQueue; // Delays changes to mapping.
        address[] reserveManagers; // Push only, beware false-positives. Only for viewing.
        mapping(address => bool) isReserveManager;
        mapping(address => uint256) ReserveManagerQueue; // Delays changes to mapping.
        address[] liquidityManagers; // Push only, beware false-positives. Only for viewing.
        mapping(address => bool) isLiquidityManager;
        mapping(address => uint256) LiquidityManagerQueue; // Delays changes to mapping.
        address[] debtors; // Push only, beware false-positives. Only for viewing.
        mapping(address => bool) isDebtor;
        mapping(address => uint256) debtorQueue; // Delays changes to mapping.
        mapping(address => uint256) debtorBalance;
        address[] rewardManagers; // Push only, beware false-positives. Only for viewing.
        mapping(address => bool) isRewardManager;
        mapping(address => uint256) rewardManagerQueue; // Delays changes to mapping.
        // Always add new storage variable to the end of this struct
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

library LibDiamond {
    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: invalid contract owner"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}