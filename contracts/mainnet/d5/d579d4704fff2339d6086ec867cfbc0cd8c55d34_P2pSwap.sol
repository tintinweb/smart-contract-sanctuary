/**
 *Submitted for verification at Etherscan.io on 2020-08-09
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: contracts/P2pSwap.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;


/**
 * @title P2pSwap
 * @dev Basic peer to per swap. Alice exchanging X tok1 with Y tok2 with Bob
 **/
contract P2pSwap {
    struct Swap {
        address aliceAddress;
        address token1;
        uint256 value1;
        address token2;
        uint256 value2;
        uint8 executed; // 0 - pending, 1 - executed, 2 - cancelled
    }

    mapping(uint256 => Swap) swaps;

    function getSwap(uint256 _id)
    public view returns (address, address, uint256, address, uint256, uint8) {
        Swap memory swap = swaps[_id];
        return (
            swap.aliceAddress,
            swap.token1,
            swap.value1,
            swap.token2,
            swap.value2,
            swap.executed
        );
    }

    function registerSwap(
        uint256 _id,
        address _aliceAddress,
        address _token1,
        uint256 _value1,
        address _token2,
        uint256 _value2)
    public returns (bool) {
        require(_id != 0);
        require(_aliceAddress != address(0));
        require(_token1 != address(0));
        require(_value1 != 0);
        require(_token2 != address(0));
        require(_value2 != 0);
        Swap storage swap = swaps[_id];
        require(swap.aliceAddress == address(0), "Swap already exists");
        swap.aliceAddress = _aliceAddress;
        swap.token1 = _token1;
        swap.value1 = _value1;
        swap.token2 = _token2;
        swap.value2 = _value2;
        return true;
    }

    function cancelSwap(uint256 _id) public returns (bool) {
        Swap storage swap = swaps[_id];
        require(swap.executed == 0, "Swap not available");
        swap.executed = 2;
    }

    function executeSwap(uint256 _id, address _bob)
    public returns (bool) {
        require(_bob != address(0));
        Swap storage swap = swaps[_id];
        require(swap.aliceAddress != address(0), "Swap does not exists");
        require(swap.executed == 2, "Swap not available");
        IERC20 Token1 = IERC20(swap.token1);
        IERC20 Token2 = IERC20(swap.token2);
        // Swap. Make sure to set the allowances in advance
        Token1.transferFrom(swap.aliceAddress, _bob, swap.value1);
        Token2.transferFrom(_bob, swap.aliceAddress, swap.value2);
        swap.executed = 1;
        return true;
    }
}