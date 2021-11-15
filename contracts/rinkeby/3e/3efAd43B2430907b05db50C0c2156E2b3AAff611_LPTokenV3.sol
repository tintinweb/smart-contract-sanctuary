// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Pool {
    function owner() external view returns (address);
}

contract LPTokenV3 is IERC20 {
    string public name;
    string public symbol;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;

    address public minter;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        minter = msg.sender;
        emit Transfer(address(0), msg.sender, 0);
    }

    /// @notice Get the number of decimals for this token
    /// @dev Implemented as a view method to reduce gas costs
    /// @return uint256 decimal places
    function decimals() external pure returns (uint256) {
        return 18;
    }

    /// @dev Transfer token for a specified address
    /// @param _to The address to transfer to.
    /// @param _value The amount to be transferred.
    function transfer(address _to, uint256 _value)
        external
        override
        returns (bool)
    {
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    ///  @dev Transfer tokens from one address to another.
    ///  @param _from address The address which you want to send tokens from
    ///  @param _to address The address which you want to transfer to
    ///  @param _value uint256 the amount of tokens to be transferred
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool) {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        uint256 _allowance = allowance[_from][msg.sender];
        if (_allowance != uint256(-1))
            allowance[_from][msg.sender] = _allowance - _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Approve the passed address to transfer the specified amount of
    ///         tokens on behalf of msg.sender
    /// @dev Beware that changing an allowance via this method brings the risk
    ///      that someone may use both the old and new allowance by unfortunate
    ///      transaction ordering. This may be mitigated with the use of
    ///      {increaseAllowance} and {decreaseAllowance}.
    ///      https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    /// @param _spender The address which will transfer the funds
    /// @param _value The amount of tokens that may be transferred
    /// @return bool success
    function approve(address _spender, uint256 _value)
        external
        override
        returns (bool)
    {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice Increase the allowance granted to `_spender` by the caller
    /// @dev This is alternative to {approve} that can be used as a mitigation for
    ///      the potential race condition
    /// @param _spender The address which will transfer the funds
    /// @param _added_value The amount of to increase the allowance
    /// @return bool success
    function increaseAllowance(address _spender, uint256 _added_value)
        external
        returns (bool)
    {
        uint256 _allowance = allowance[msg.sender][_spender] + _added_value;
        allowance[msg.sender][_spender] = _allowance;

        emit Approval(msg.sender, _spender, _allowance);
        return true;
    }

    /// @notice Decrease the allowance granted to `_spender` by the caller
    /// @dev This is alternative to {approve} that can be used as a mitigation for
    ///      the potential race condition
    /// @param _spender The address which will transfer the funds
    /// @param _subtracted_value The amount of to decrease the allowance
    /// @return bool success
    function decreaseAllowance(address _spender, uint256 _subtracted_value)
        external
        returns (bool)
    {
        uint256 _allowance =
            allowance[msg.sender][_spender] - _subtracted_value;
        allowance[msg.sender][_spender] = _allowance;

        emit Approval(msg.sender, _spender, _allowance);
        return true;
    }

    /// @dev Mint an amount of the token and assigns it to an account.
    ///      This encapsulates the modification of balances such that the
    ///      proper events are emitted.
    /// @param _to The account that will receive the created tokens.
    /// @param _value The amount that will be created.
    function mint(address _to, uint256 _value) external returns (bool) {
        require(msg.sender == minter);

        totalSupply += _value;
        balanceOf[_to] += _value;

        emit Transfer(address(0), _to, _value);
        return true;
    }

    /// @dev Burn an amount of the token from a given account.
    /// @param _to The account whose tokens will be burned.
    /// @param _value The amount that will be burned.
    function burnFrom(address _to, uint256 _value) external returns (bool) {
        require(msg.sender == minter);

        totalSupply -= _value;
        balanceOf[_to] -= _value;

        emit Transfer(_to, address(0), _value);
        return true;
    }

    function set_minter(address _minter) external {
        require(msg.sender == minter);
        minter = _minter;
    }

    function set_name(string memory _name, string memory _symbol) external {
        require(Pool(minter).owner() == msg.sender);
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

