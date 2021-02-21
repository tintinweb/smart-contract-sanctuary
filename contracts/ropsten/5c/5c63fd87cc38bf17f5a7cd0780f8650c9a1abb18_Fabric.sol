/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

// Note that this is not the production code
pragma solidity 0.5.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

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
    function transfer(address recipient, uint256 amount) external;
}

contract Wallet {
    address internal token = 0xBd216833df5e86Dde28a12B4979bE6f620211449;
    address internal hotWallet = 0xd3Df7eDf5A6c698000cA15921E682e46d9895f26;

    constructor() public {
        // send all tokens from this contract to hotwallet
        IERC20(token).transfer(
            hotWallet,
            IERC20(token).balanceOf(address(this))
        );
        // selfdestruct to receive gas refund and reset nonce to 0
        selfdestruct(address(0x0));
    }
}

contract Fabric {
    function createContract(uint256 salt) public {
        // get wallet init_code
        bytes memory bytecode = type(Wallet).creationCode;
        assembly {
            let codeSize := mload(bytecode) // get size of init_bytecode
            let newAddr := create2(
                0, // 0 wei
                add(bytecode, 32), // the bytecode itself starts at the second slot. The first slot contains array length
                codeSize, // size of init_code
                salt // salt from function arguments
            )
        }
    }
}