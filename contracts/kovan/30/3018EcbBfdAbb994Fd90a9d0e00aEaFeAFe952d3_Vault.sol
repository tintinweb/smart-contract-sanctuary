// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IStableCoin is IERC20 {
    function mint(address _to, uint256 _value) external;

    function burn(uint256 _value) external;

    function burnFrom(address _from, uint256 _value) external;
}

interface IOracle {
    function update() external returns (bool);

    function eth_usd() external view returns (int128);

    function eth_usd_18() external view returns (uint256);

    function last_update_time() external view returns (uint256);

    function last_update_remote() external view returns (bool);
}

interface ICryptoPunks {
    function transferPunk(address _to, uint256 _punk_index) external;

    function punkIndexToAddress(uint256 _punk_index)
        external
        view
        returns (address);
}

contract Vault is Ownable, ReentrancyGuard {
    using SafeERC20 for IStableCoin;

    event PositionOpened(address owner, uint256 index);
    event Borrowed(address owner, uint256 index, uint256 amount);
    event Repaid(address owner, uint256 index, uint256 amount);
    event PositionClosed(address owner, uint256 index);
    event Liquidated(address liquidator, address owner, uint256 index);

    enum PunkType {
        FLOOR,
        APE,
        ALIENS,
        CUSTOM
    }

    struct Position {
        bool use_insurance;
        uint256 debt_principal;
        uint256 debt_interest;
        uint256 time_debt;
    }

    address public stablecoin;
    address public cryptopunks;
    address public dao;
    address public oracle;

    uint256 public time_last_oracle_update;

    uint256 public apr_rate;
    uint256 public collateralization_rate;
    uint256 public insurance_borrow_rate;
    uint256 public insurance_liquidate_rate;
    uint256 public compounding_interval_secs;

    uint256 constant SEC_MINUTE = 60;
    uint256 constant SECS_MINUTE = 60;
    uint256 constant SECS_15M = 60 * 15;
    uint256 constant SECS_30M = 60 * 30;
    uint256 constant SECS_HOUR = 3600;
    uint256 constant SECS_DAY = 86400;
    uint256 constant SECS_WEEK = 86400 * 7;
    uint256 constant SECS_YEAR = 86400 * 365;

    mapping(address => mapping(uint256 => Position)) public positions;
    mapping(uint256 => address) public positions_punk;

    uint256 public total_positions;
    uint256 public total_minted;
    uint256 public total_repaid;
    uint256 public total_liquidated;

    uint256 public eth_usd_18;
    mapping(PunkType => uint256) public punk_type_values;
    mapping(uint256 => uint256) public punk_values;
    mapping(PunkType => uint256) public punk_values_usd;
    mapping(uint256 => PunkType) public punk_dictionary;

    uint256 public tick_i;
    uint256 public tick_chunk_size;

    modifier validPunkIndex(uint256 punk_index) {
        require(punk_index < 10000, "invalid_punk");
        _;
    }

    modifier onlyDao() {
        require(msg.sender == dao, "only dao");
        _;
    }

    constructor(
        address _stablecoin,
        address _cryptopunks,
        address _dao,
        address _oracle
    ) Ownable() ReentrancyGuard() {
        tick_i = 0;
        tick_chunk_size = 500;

        stablecoin = _stablecoin;
        cryptopunks = _cryptopunks;
        dao = _dao;
        oracle = _oracle;

        apr_rate = 2; // 2%
        collateralization_rate = 33; // 33%
        insurance_borrow_rate = 1; // 1%
        insurance_liquidate_rate = 25; // 25%
        compounding_interval_secs = SECS_HOUR;

        // default values (in eth) for punk types
        punk_type_values[PunkType.FLOOR] = 50 * 10**18;
        punk_type_values[PunkType.APE] = 2000 * 10**18;
        punk_type_values[PunkType.ALIENS] = 4000 * 10**18;

        // update price oracle
        IOracle(oracle).update();
        eth_usd_18 = IOracle(oracle).eth_usd_18();

        // define aliens
        uint16[9] memory aliens = [
            635,
            2890,
            3100,
            3443,
            5822,
            5905,
            6089,
            7523,
            7804
        ];
        for (uint16 i = 0; i < aliens.length; i++) {
            punk_dictionary[aliens[i]] = PunkType.ALIENS;
        }

        // define apes
        uint16[24] memory apes = [
            372,
            1021,
            2140,
            2243,
            2386,
            2460,
            2491,
            2711,
            2924,
            4156,
            4178,
            4464,
            5217,
            5314,
            5577,
            5795,
            6145,
            6915,
            6965,
            7191,
            8219,
            8498,
            9265,
            9280
        ];
        for (uint16 i = 0; i < apes.length; i++) {
            punk_dictionary[apes[i]] = PunkType.APE;
        }
    }

    function _update_oracle_pricing() internal {
        IOracle(oracle).update();
        eth_usd_18 = IOracle(oracle).eth_usd_18();
    }

    function update_oracle_pricing() external {
        time_last_oracle_update = block.timestamp;
        _update_oracle_pricing();
    }

    function set_tick_chunk_size(uint256 _tick_chunk_size) external onlyOwner {
        tick_chunk_size = _tick_chunk_size;
    }

    function set_apr_rate(uint256 _apr_rate) external onlyOwner {
        apr_rate = _apr_rate;
    }

    function set_collateralization_rate(uint256 _collateralization_rate)
        external
        onlyOwner
    {
        collateralization_rate = _collateralization_rate;
    }

    function set_insurance_borrow_rate(uint256 _insurance_borrow_rate)
        external
        onlyOwner
    {
        insurance_borrow_rate = _insurance_borrow_rate;
    }

    function set_insurance_liquidate_rate(uint256 _insurance_liquidate_rate)
        external
        onlyOwner
    {
        insurance_liquidate_rate = _insurance_liquidate_rate;
    }

    function set_compounding_interval_secs(uint256 _compounding_interval_secs)
        external
        onlyOwner
    {
        compounding_interval_secs = _compounding_interval_secs;
    }

    function set_punk_type(uint256 _punk_index, PunkType _type)
        external
        validPunkIndex(_punk_index)
        onlyOwner
    {
        punk_dictionary[_punk_index] = _type;
    }

    function set_punk_type_value(PunkType _type, uint256 _amount_eth)
        external
        onlyOwner
    {
        require(punk_type_values[_type] > 0, "invalid_punk_type");

        punk_type_values[_type] = _amount_eth;
    }

    function set_punk_value(uint256 _punk_index, uint256 _amount_eth)
        external
        validPunkIndex(_punk_index)
        onlyOwner
    {
        punk_dictionary[_punk_index] = PunkType.CUSTOM;
        punk_values[_punk_index] = _amount_eth;
    }

    function _get_punk_type(uint256 _punk_index)
        internal
        view
        returns (PunkType punk_type)
    {
        return punk_dictionary[_punk_index];
    }

    function _get_punk_value(uint256 _punk_index)
        internal
        view
        returns (uint256)
    {
        PunkType punk_type = _get_punk_type(_punk_index);
        return
            punk_type == PunkType.CUSTOM
                ? punk_values[_punk_index]
                : punk_type_values[punk_type];
    }

    function _get_punk_value_usd(uint256 _punk_index)
        internal
        view
        returns (uint256)
    {
        uint256 punk_value = _get_punk_value(_punk_index);
        return (punk_value * eth_usd_18) / 10**18;
    }

    function _get_punk_owner(uint256 _punk_index)
        internal
        view
        returns (address)
    {
        return ICryptoPunks(cryptopunks).punkIndexToAddress(_punk_index);
    }

    function get_punk_owner(uint256 _punk_index)
        external
        view
        returns (address)
    {
        return _get_punk_owner(_punk_index);
    }

    struct PunkInfo {
        uint256 index;
        PunkType punk_type;
        address owner;
        uint256 punk_value_eth;
        uint256 punk_value_usd;
    }

    function get_punk_info(uint256 _punk_index)
        external
        view
        returns (PunkInfo memory punk_info)
    {
        punk_info = PunkInfo(
            _punk_index,
            _get_punk_type(_punk_index),
            _get_punk_owner(_punk_index),
            _get_punk_value(_punk_index),
            _get_punk_value_usd(_punk_index)
        );
    }

    function _get_collateralized_punk_value(uint256 _punk_index)
        internal
        view
        returns (uint256 colat_value)
    {
        uint256 asset_value = _get_punk_value_usd(_punk_index);
        colat_value = (asset_value * collateralization_rate) / 100;
    }

    function _get_debt_interest(uint256 _punk_index)
        internal
        view
        returns (uint256 debt_interest)
    {
        address pos_owner = positions_punk[_punk_index];
        Position memory position = positions[pos_owner][_punk_index];

        // check if there is debt
        if (position.debt_principal > 0) {
            uint256 interest_base_amt = position.debt_principal +
                position.debt_interest;
            uint256 interest_per_year = ((interest_base_amt * apr_rate) / 100);
            uint256 interest_per_second = interest_per_year / SECS_YEAR;
            uint256 time_difference_secs = (block.timestamp -
                position.time_debt);

            if (time_difference_secs > compounding_interval_secs) {
                uint256 new_interest = time_difference_secs *
                    interest_per_second;

                debt_interest = position.debt_interest + new_interest;
            }
        }
    }

    function _update_debt_interest(uint256 _punk_index) internal {
        address pos_owner = positions_punk[_punk_index];
        uint256 debt_interest = _get_debt_interest(_punk_index);
        if (positions[pos_owner][_punk_index].debt_interest != debt_interest) {
            positions[pos_owner][_punk_index].debt_interest = debt_interest;
            positions[pos_owner][_punk_index].time_debt = block.timestamp;
        }
    }

    struct PositionPreview {
        address owner;
        uint256 punk_index;
        PunkType punk_type;
        uint256 punk_value_usd;
        uint256 apr_rate;
        uint256 collateralization_rate;
        uint256 insurance_borrow_rate;
        uint256 insurance_liquidate_rate;
        uint256 credit_limit;
        uint256 debt_principal;
        uint256 debt_interest;
        bool use_insurance;
    }

    function show_position(uint256 _punk_index)
        external
        view
        validPunkIndex(_punk_index)
        returns (PositionPreview memory preview)
    {
        address pos_owner = positions_punk[_punk_index];
        require(pos_owner != address(0), "position_not_exist");

        preview = PositionPreview(
            pos_owner,
            _punk_index,
            _get_punk_type(_punk_index),
            _get_punk_value_usd(_punk_index),
            apr_rate,
            collateralization_rate,
            insurance_borrow_rate,
            insurance_liquidate_rate,
            _get_collateralized_punk_value(_punk_index),
            positions[pos_owner][_punk_index].debt_principal,
            _get_debt_interest(_punk_index),
            positions[pos_owner][_punk_index].use_insurance
        );
    }

    function open_position(uint256 _punk_index, bool _use_insurance)
        external
        validPunkIndex(_punk_index)
    {
        require(msg.sender == _get_punk_owner(_punk_index), "punk_not_owned");
        require(
            positions_punk[_punk_index] == address(0),
            "position_already_exists"
        );

        _update_oracle_pricing();

        positions[msg.sender][_punk_index] = Position(_use_insurance, 0, 0, 0);
        positions_punk[_punk_index] = msg.sender;
        total_positions++;

        emit PositionOpened(msg.sender, _punk_index);
    }

    function borrow(uint256 _punk_index, uint256 _amount)
        external
        validPunkIndex(_punk_index)
        nonReentrant
    {
        require(msg.sender == positions_punk[_punk_index], "unauthorized");
        require(
            _get_punk_owner(_punk_index) == address(this),
            "punk_not_deposited"
        );

        Position memory position = positions[msg.sender][_punk_index];

        _update_oracle_pricing();
        _update_debt_interest(_punk_index);

        uint256 credit_limit = _get_collateralized_punk_value(_punk_index);

        uint256 total_debt = position.debt_principal + position.debt_interest;
        require(total_debt + _amount <= credit_limit, "insufficient_credit");

        // mint stablecoin
        if (position.use_insurance) {
            uint256 insurance_amount = (_amount * insurance_borrow_rate) / 100;
            // insurance amount to dao
            IStableCoin(stablecoin).mint(dao, insurance_amount);
            // remaining amount to user
            IStableCoin(stablecoin).mint(
                msg.sender,
                _amount - insurance_amount
            );
        } else {
            IStableCoin(stablecoin).mint(msg.sender, _amount);
        }

        total_minted += _amount;
        positions[msg.sender][_punk_index].debt_principal += _amount;
        positions[msg.sender][_punk_index].time_debt = block.timestamp;

        emit Borrowed(msg.sender, _punk_index, _amount);
    }

    function repay(uint256 _punk_index, uint256 _amount)
        external
        validPunkIndex(_punk_index)
        nonReentrant
    {
        require(msg.sender == positions_punk[_punk_index], "unauthorized");
        require(
            _get_punk_owner(_punk_index) == address(this),
            "punk_not_deposited"
        );

        Position memory position = positions[msg.sender][_punk_index];

        _update_oracle_pricing();
        _update_debt_interest(_punk_index);

        uint256 debt_principal = position.debt_principal;
        uint256 debt_interest = position.debt_interest;

        require(debt_principal + debt_interest > 0, "position_not_borrowed");

        // send payment to vault
        IStableCoin(stablecoin).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        total_repaid += _amount;

        uint256 cur_amount = _amount;
        uint256 paid_interest;
        uint256 paid_principal;
        // pay interest
        if (debt_interest > 0) {
            if (cur_amount >= debt_interest) {
                positions[msg.sender][_punk_index].debt_interest = 0;
                cur_amount -= debt_interest;
                paid_interest = debt_interest;
            } else {
                positions[msg.sender][_punk_index].debt_interest -= cur_amount;
                paid_interest = cur_amount;
                cur_amount = 0;
            }
        }

        if (debt_principal > 0 && cur_amount > 0) {
            if (cur_amount >= debt_principal) {
                positions[msg.sender][_punk_index].debt_principal = 0;
                cur_amount -= debt_principal;
                paid_principal = debt_principal;
            } else {
                positions[msg.sender][_punk_index].debt_principal -= cur_amount;
                paid_principal = cur_amount;
                cur_amount = 0;
            }
        }

        // check if position was fully repaid
        if (
            positions[msg.sender][_punk_index].debt_principal == 0 &&
            positions[msg.sender][_punk_index].debt_interest == 0
        ) {
            positions[msg.sender][_punk_index].time_debt = 0;
        }

        // transfer remainings back to user
        if (cur_amount > 0) {
            IStableCoin(stablecoin).safeTransfer(msg.sender, cur_amount);
        }

        // transfer interest to dao
        if (paid_interest > 0) {
            IStableCoin(stablecoin).safeTransfer(dao, paid_interest);
        }

        // burn principal payment
        if (paid_principal > 0) {
            IStableCoin(stablecoin).burn(paid_principal);
        }

        emit Repaid(msg.sender, _punk_index, _amount - cur_amount);
    }

    function close_position(uint256 _punk_index)
        external
        validPunkIndex(_punk_index)
    {
        Position memory position = positions[msg.sender][_punk_index];
        require(msg.sender == positions_punk[_punk_index], "unauthorized");
        require(position.time_debt == 0, "position_not_repaid");

        positions_punk[_punk_index] = address(0);

        // transfer punk back to owner if punk was deposited
        if (_get_punk_owner(_punk_index) == address(this)) {
            ICryptoPunks(cryptopunks).transferPunk(msg.sender, _punk_index);
        }

        emit PositionClosed(msg.sender, _punk_index);
    }

    function liquidate(uint256 _punk_index, uint256 _amount)
        external
        validPunkIndex(_punk_index)
        nonReentrant
    {
        require(
            positions_punk[_punk_index] != address(0),
            "position_not_exist"
        );
        require(
            _get_punk_owner(_punk_index) == address(this),
            "punk_not_deposited"
        );

        address pos_owner = positions_punk[_punk_index];
        Position memory position = positions[pos_owner][_punk_index];

        _update_oracle_pricing();
        _update_debt_interest(_punk_index);

        uint256 debt_principal = position.debt_principal;
        uint256 debt_interest = position.debt_interest;

        require(debt_principal + debt_interest > 0, "position_not_borrowed");
        require(
            debt_principal + debt_interest >
                _get_collateralized_punk_value(_punk_index),
            "position_not_liquidatable"
        );

        IStableCoin(stablecoin).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        total_repaid += _amount;

        uint256 punk_value_usd = _get_punk_value_usd(_punk_index);
        uint256 liquidation_fee = position.use_insurance
            ? (punk_value_usd * insurance_liquidate_rate) / 100
            : 0;

        uint256 total_amount = debt_principal + debt_interest + liquidation_fee;
        require(total_amount <= _amount, "insufficient_amount");

        // transfer remainings back to liquidator
        if (total_amount < _amount) {
            IStableCoin(stablecoin).safeTransfer(
                msg.sender,
                _amount - total_amount
            );
        }

        // transfer liquiation fee + interest to dao
        if (debt_interest + liquidation_fee > 0) {
            IStableCoin(stablecoin).safeTransfer(
                dao,
                debt_interest + liquidation_fee
            );
        }

        // burn principal payment
        if (debt_principal > 0) {
            IStableCoin(stablecoin).burn(debt_principal);
        }

        // transfer punk to liquidator
        ICryptoPunks(cryptopunks).transferPunk(msg.sender, _punk_index);

        delete positions[pos_owner][_punk_index];
        positions_punk[_punk_index] = address(0);

        emit Liquidated(msg.sender, pos_owner, _punk_index);
    }

    function tick() external returns (uint256) {
        _update_oracle_pricing();

        if (tick_i > 9999) tick_i = 0;

        uint256 found = 0;

        for (uint256 i = 0; i < tick_chunk_size; i++) {
            uint256 _punk_index = tick_i;
            tick_i++;

            if (_punk_index > 9999) {
                tick_i = 0;
                continue;
            }

            if (positions_punk[_punk_index] == address(0)) {
                continue;
            }

            found++;

            _update_debt_interest(_punk_index);
        }

        return found;
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

/*
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

