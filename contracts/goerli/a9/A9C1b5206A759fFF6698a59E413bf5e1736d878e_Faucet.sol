// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

contract Faucet {
    IERC20 internal immutable _ierc20;
    uint256 internal immutable _period;
    uint256 internal immutable _amountLimit;

    mapping(address => uint256) public _lastTimestamps;

    constructor(
        IERC20 ierc20,
        uint256 period,
        uint256 amountLimit
    ) public {
        _ierc20 = ierc20;
        _period = period;
        _amountLimit = amountLimit;
    }

    event FSent(address _receiver, uint256 _amountSent);

    /// @notice send amount of IERC20 to a receiver.
    /// @param amount The value (allowance) of the ERC20 tokens that the nominated.
    /// spender will be allowed to spend.
    function send(uint256 amount) public {
        address _receiver = msg.sender;
        uint256 amountSent = amount;
        require(amount < _amountLimit, "Demand should not exceed limit");
        require(
            _lastTimestamps[_receiver] + _period < block.timestamp,
            "Demand not available now. You should wait after each Demand."
        );
        _lastTimestamps[_receiver] = block.timestamp;

        address contractAddress = address(this);
        if (_ierc20.balanceOf(contractAddress) < amount) {
            amountSent = _ierc20.balanceOf(contractAddress);
        }
        _ierc20.transferFrom(contractAddress, _receiver, amountSent);

        emit FSent(_receiver, amountSent);
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