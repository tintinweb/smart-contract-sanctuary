/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


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

interface IStepVesting {
    function started() external returns(uint256);
    function token() external returns(IERC20);
    function cliffDuration() external returns(uint256);
    function stepDuration() external returns(uint256);
    function cliffAmount() external returns(uint256);
    function stepAmount() external returns(uint256);
    function numOfSteps() external returns(uint256);
    function receiver() external returns(address);
}

contract VestingValidator {
    using Strings for uint256;

    IERC20 public constant TOKEN = IERC20(0x111111111117dC0aa78b770fA6A738034120C302);

    function check(
        IStepVesting[] memory contracts,
        address[] memory receivers,
        uint256[] memory amounts
    ) external {
        uint256 len = contracts.length;
        require(len == receivers.length, "Invalid receivers length");
        require(len == amounts.length, "Invalid amounts length");

        for (uint i = 0; i < len; i++) {
            IStepVesting vesting = contracts[i];
            require(
                vesting.token() == TOKEN,
                string(abi.encodePacked("Invalid token #", (i + 1).toString()))
            );
            require(
                vesting.receiver() == receivers[i],
                string(abi.encodePacked("Invalid receiver #", (i + 1).toString()))
            );
            require(
                vesting.started() == 1606824000, // 01 Dec 2020 12:00 UTC
                string(abi.encodePacked("Invalid start date #", (i + 1).toString()))
            );
            require(
                vesting.cliffDuration() == 31536000 + 15768000, // 365 days + 182.5 days
                string(abi.encodePacked("Invalid cliff duration #", (i + 1).toString()))
            );
            require(
                vesting.stepDuration() == 15768000, // 182.5 days
                string(abi.encodePacked("Invalid step duration #", (i + 1).toString()))
            );
            require(
                vesting.numOfSteps() == 2,
                string(abi.encodePacked("Invalid num of steps #", (i + 1).toString()))
            );
            require(
                vesting.cliffAmount() + vesting.stepAmount() * 2 == amounts[i],
                string(abi.encodePacked("Invalid amount #", (i + 1).toString()))
            );
            require(
                TOKEN.balanceOf(address(vesting)) == amounts[i],
                string(abi.encodePacked("Invalid balance #", (i + 1).toString()))
            );
        }
    }
}