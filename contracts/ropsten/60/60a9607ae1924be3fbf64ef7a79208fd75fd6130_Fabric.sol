/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

// Note that this is not the production code
pragma solidity 0.5.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract Wallet {
    address internal token = 0x377B46C556512a82Bb3fD2657Fe28193d3b28242;
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