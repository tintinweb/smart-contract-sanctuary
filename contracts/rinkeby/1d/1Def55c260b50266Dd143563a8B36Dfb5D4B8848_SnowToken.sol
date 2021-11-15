// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Snow DAO Token
/// @notice ERC20 with piecewise-linear mining supply.
/// @dev Based on the ERC-20 token standard as defined at
//      https://eips.ethereum.org/EIPS/eip-20

contract SnowToken is IERC20 {
    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);

    event SetMinter(address minter);

    event SetAdmin(address admin);

    string public name;
    string public symbol;

    uint256 public decimals;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public total_supply;

    address public minter;
    address public admin;

    // General constants
    uint256 constant YEAR = 86400 * 365;

    // Allocation:
    // =========
    // * shareholders - 30%
    // * emplyees - 3%
    // * DAO-controlled reserve - 5%
    // * Early users - 5%
    // == 43% ==
    // left for inflation: 57%

    // Supply parameters
    uint256 constant INITIAL_SUPPLY = 1_303_030_303;
    uint256 constant INITIAL_RATE = (274_815_283 * 10**18) / YEAR; // leading to 43% premine
    uint256 constant RATE_REDUCTION_TIME = YEAR;
    uint256 constant RATE_REDUCTION_COEFFICIENT = 1189207115002721024; // 2 ** (1/4) * 1e18
    uint256 constant RATE_DENOMINATOR = 10**18;
    uint256 constant INFLATION_DELAY = 86400;

    // Supply variables
    int128 public mining_epoch;
    uint256 public start_epoch_time;
    uint256 public rate;

    uint256 start_epoch_supply;

    /// @notice Contract constructor
    /// @param _name Token full name
    /// @param _symbol Token symbol
    /// @param _decimals Number of decimals for token
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) {
        uint256 init_supply = INITIAL_SUPPLY * 10**_decimals;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balanceOf[msg.sender] = init_supply;
        total_supply = init_supply;
        admin = msg.sender;
        emit Transfer(address(0), msg.sender, init_supply);

        start_epoch_time =
            block.timestamp +
            INFLATION_DELAY -
            RATE_REDUCTION_TIME;
        mining_epoch = -1;
        rate = 0;
        start_epoch_supply = init_supply;
    }

    /// @dev Update mining rate and supply at the start of the epoch
    ///      Any modifying mining call must also call this
    function _update_mining_parameters() internal {
        uint256 _start_epoch_supply = start_epoch_supply;
        uint256 _rate = rate;

        _start_epoch_supply += RATE_REDUCTION_TIME;
        mining_epoch += 1;

        if (_rate == 0) _rate = INITIAL_RATE;
        else {
            _start_epoch_supply += _rate * RATE_REDUCTION_TIME;
            start_epoch_supply = _start_epoch_supply;
            _rate = (_rate * RATE_DENOMINATOR) / RATE_REDUCTION_COEFFICIENT;
        }

        rate = _rate;

        emit UpdateMiningParameters(block.timestamp, _rate, start_epoch_supply);
    }

    /// @notice Update mining rate and supply at the start of the epoch
    /// @dev Callable by any address, but only once per epoch
    ///      Total supply becomes slightly larger if this function is called late
    function update_mining_parameters() external {
        require(block.timestamp >= start_epoch_time + RATE_REDUCTION_TIME); // dev: too soon!
        _update_mining_parameters();
    }

    /// @notice Get timestamp of the current mining epoch start
    ///         while simultaneously updating mining parameters
    /// @return Timestamp of the epoch
    function start_epoch_time_write() external returns (uint256) {
        uint256 _start_epoch_time = start_epoch_time;
        if (block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME) {
            _update_mining_parameters();
            return start_epoch_time;
        } else return _start_epoch_time;
    }

    /// @notice Get timestamp of the next mining epoch start
    ///         while simultaneously updating mining parameters
    /// @return Timestamp of the next epoch
    function future_epoch_time_write() external returns (uint256) {
        uint256 _start_epoch_time = start_epoch_time;
        if (block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME) {
            _update_mining_parameters();
            return start_epoch_time + RATE_REDUCTION_TIME;
        } else return _start_epoch_time + RATE_REDUCTION_TIME;
    }

    function _available_supply() internal view returns (uint256) {
        return start_epoch_supply + (block.timestamp - start_epoch_time) * rate;
    }

    /// @notice Current number of tokens in existence (claimed or unclaimed)
    function available_supply() external view returns (uint256) {
        return _available_supply();
    }

    /// @notice How much supply is mintable from start timestamp till end timestamp
    /// @param start Start of the time interval (timestamp)
    /// @param end End of the time interval (timestamp)
    /// @return Tokens mintable from `start` till `end`
    function mintable_in_timeframe(uint256 start, uint256 end)
        external
        view
        returns (uint256)
    {
        require(start <= end); // dev: start > end
        uint256 to_mint = 0;
        uint256 current_epoch_time = start_epoch_time;
        uint256 current_rate = rate;

        // Special case if end is in future (not yet minted) epoch
        if (end > current_epoch_time + RATE_REDUCTION_TIME) {
            current_epoch_time += RATE_REDUCTION_TIME;
            current_rate =
                (current_rate * RATE_DENOMINATOR) /
                RATE_REDUCTION_COEFFICIENT;
        }
        require(end <= current_epoch_time + RATE_REDUCTION_TIME); // dev: too far in future

        for (uint256 i = 0; i < 999; i++) {
            // will not work in 1000 years. Darn!
            if (end >= current_epoch_time) {
                uint256 current_end = end;
                if (current_end > current_epoch_time + RATE_REDUCTION_TIME)
                    current_end = current_epoch_time + RATE_REDUCTION_TIME;

                uint256 current_start = start;
                if (current_start >= current_epoch_time + RATE_REDUCTION_TIME)
                    break;
                // We should never get here but what if...
                else if (current_start < current_epoch_time)
                    current_start = current_epoch_time;

                to_mint += current_rate * (current_end - current_start);

                if (start >= current_epoch_time) break;
            }

            current_epoch_time -= RATE_REDUCTION_TIME;
            current_rate =
                (current_rate * RATE_REDUCTION_COEFFICIENT) /
                RATE_DENOMINATOR; // double-division with rounding made rate a bit less => good
            require(current_rate <= INITIAL_RATE); // This should never happen
        }
        return to_mint;
    }

    /// @notice Set the minter address
    /// @dev Only callable once, when minter has not yet been set
    /// @param _minter Address of the minter
    function set_minter(address _minter) external {
        require(msg.sender == admin); // dev: admin only
        require(minter == address(0)); // dev: can set the minter only once, at creation
        minter = _minter;
        emit SetMinter(_minter);
    }

    /// @notice Set the new admin.
    /// @dev After all is set up, admin only can change the token name
    /// @param _admin New admin address
    function set_admin(address _admin) external {
        require(msg.sender == admin); // dev: admin only
        admin = _admin;
        emit SetAdmin(_admin);
    }

    /// @notice Total number of tokens in existence.
    function totalSupply() external view override returns (uint256) {
        return total_supply;
    }

    /// @notice Check the amount of tokens that an owner allowed to a spender
    /// @param _owner The address which owns the funds
    /// @param _spender The address which will spend the funds
    /// @return uint256 specifying the amount of tokens still available for the spender
    function allowance(address _owner, address _spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances[_owner][_spender];
    }

    /// @notice Transfer `_value` tokens from `msg.sender` to `_to`
    /// @param _to The address to transfer to
    /// @param _value The amount to be transferred
    /// @return bool success
    function transfer(address _to, uint256 _value)
        external
        override
        returns (bool)
    {
        require(_to != address(0)); // dev: transfers to 0x0 are not allowed
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    ///  @notice Transfer `_value` tokens from `_from` to `_to`
    ///  @param _from address The address which you want to send tokens from
    ///  @param _to address The address which you want to transfer to
    ///  @param _value uint256 the amount of tokens to be transferred
    ///  @return bool success
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool) {
        require(_to != address(0)); // dev: transfers to 0x0 are not allowed
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Approve `_spender` to transfer `_value` tokens on behalf of `msg.sender`
    /// @dev Approval may only be from zero -> nonzero or from nonzero -> zero in order
    ///     to mitigate the potential race condition described here:
    ///     https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    /// @param _spender The address which will spend the funds
    /// @param _value The amount of tokens to be spent
    /// @return bool success
    function approve(address _spender, uint256 _value)
        external
        override
        returns (bool)
    {
        require(_value == 0 || allowances[msg.sender][_spender] == 0);
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice Mint `_value` tokens and assign them to `_to`
    /// @dev Emits a Transfer event originating from 0x00
    /// @param _to The account that will receive the created tokens
    /// @param _value The amount that will be created
    /// @return bool success
    function mint(address _to, uint256 _value) external returns (bool) {
        require(msg.sender == minter); // dev: minter only
        require(_to != address(0)); // dev: zero address

        if (block.timestamp >= start_epoch_time + RATE_REDUCTION_TIME)
            _update_mining_parameters();

        uint256 _total_supply = total_supply + _value;
        require(_total_supply <= _available_supply()); // dev: exceeds allowable mint amount
        total_supply = _total_supply;

        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);

        return true;
    }

    /// @notice Burn `_value` tokens belonging to `msg.sender`
    /// @dev Emits a Transfer event with a destination of 0x00
    /// @param _value The amount that will be burned
    /// @return bool success
    function burn(uint256 _value) external returns (bool) {
        balanceOf[msg.sender] -= _value;
        total_supply -= _value;

        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    /// @notice Change the token name and symbol to `_name` and `_symbol`
    /// @dev Only callable by the admin account
    /// @param _name New token name
    /// @param _symbol New token symbol
    function set_name(string calldata _name, string calldata _symbol) external {
        require(msg.sender == admin, "Only admin is allowed to change name");
        name = _name;
        symbol = _symbol;
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

