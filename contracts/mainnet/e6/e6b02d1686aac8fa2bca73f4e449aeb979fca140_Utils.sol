/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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

// File contracts/interfaces/utils/IUtils.sol

pragma solidity ^0.8.0;

interface IUtils {
    function isContract(address addr) external view returns (bool);

    function isContracts(address[] calldata addrs) external view returns (bool[] memory);

    function getBalances(address token, address[] calldata addrs) external view returns (uint256[] memory);
}

// File contracts/utils/Utils.sol

pragma solidity ^0.8.0;

contract Utils is IUtils {
    function isContract(address addr) public view override returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function isContracts(address[] calldata addrs) external view override returns (bool[] memory) {
        bool[] memory results = new bool[](addrs.length);

        for (uint256 index = 0; index < addrs.length; index++) {
            results[index] = isContract(addrs[index]);
        }

        return results;
    }

    function getBalances(address token, address[] calldata addrs) external view override returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](addrs.length);

        for (uint256 index = 0; index < addrs.length; index++) {
            uint256 balance;
            if (token == address(0)) {
                balance = addrs[index].balance;
            } else {
                balance = IERC20(token).balanceOf(addrs[index]);
            }
            balances[index] = balance;
        }

        return balances;
    }
}