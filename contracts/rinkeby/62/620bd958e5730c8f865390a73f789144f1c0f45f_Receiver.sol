/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity ^0.8.0;

contract Receiver {

    event Single(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes data
    );
    
    event Batch(
        address operator,
        address from,
        uint256[] ids,
        uint256[] values,
        bytes data
    );

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        emit Single(operator, from, id, value, data);
        return this.onERC1155Received.selector;        
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        emit Batch(operator, from, ids, values, data);
        return this.onERC1155BatchReceived.selector;
    }
}