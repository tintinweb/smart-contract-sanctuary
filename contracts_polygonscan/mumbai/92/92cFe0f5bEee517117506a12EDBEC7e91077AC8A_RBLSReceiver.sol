/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title ERC1363Receiver interface
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 *  from ERC1363 token contracts.
 */
interface IERC1363Receiver {
    /*
     * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
     * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
     */

    /**
     * @notice Handle the receipt of ERC1363 tokens
   * @dev Any ERC1363 smart contract calls this function on the recipient
   * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the token contract address is always the message sender.
   * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
   * @param from address The address which are token transferred from
   * @param value uint256 The amount of tokens transferred
   * @param data bytes Additional data with no specified format
   * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
   *  unless throwing
   */
    function onTransferReceived(address operator, address from, uint256 value, bytes memory data) external returns (bytes4);
}


contract RBLSReceiver is IERC1363Receiver {

    bytes4 retval = bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));

    event TokensReceived(
        address indexed operator,
        address indexed from,
        uint256 value,
        bytes data
    );

    function onTransferReceived(address operator, address from, uint256 value, bytes memory data) public virtual override returns (bytes4) {
        emit TokensReceived(operator, from, value, data);
        return retval;
    }

    function toBytes(uint256 x) external pure returns (bytes memory) {
        return abi.encode(x);
    }

    function toUint(bytes calldata depositData) external pure returns (uint256)  {
        return abi.decode(depositData, (uint256));
    }

    function test(uint256[] memory amounts, address[] memory addresses) external pure returns (uint256[] memory)  {
        return amounts;
    }

}