/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.8.0;

interface IVRroom {
    function burnBatch(uint256[] memory _ids, uint256[] memory _amounts)
        external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(uint256 _id, uint256 _amount) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}


pragma solidity ^0.8.0;


contract Merge {
    uint256[] ids = new uint256[](52);
    uint256[] merge_amounts = new uint256[](52);
    IVRroom nftContractAddress;

    event Merged(address indexed _from);

    constructor(address _nftContractAddress) public{
        for (uint256 i = 0; i < 52; i++) {
            ids[i] = i;
            merge_amounts[i] = 1;
        }
        nftContractAddress = IVRroom(_nftContractAddress);
    }

    function merge() external {
        for (uint256 i = 0; i < 52; i++) {
            nftContractAddress.safeTransferFrom(
                msg.sender,
                address(this),
                ids[i],
                merge_amounts[i],
                ""
            );
        }

         for (uint256 i = 0; i < 52; i++) {
            nftContractAddress.burn(
                ids[i],
                merge_amounts[i]
            );
        }
        emit Merged(msg.sender);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }
}