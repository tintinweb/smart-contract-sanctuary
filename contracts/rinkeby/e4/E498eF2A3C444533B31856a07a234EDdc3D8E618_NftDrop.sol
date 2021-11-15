// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract NftDrop {
    address public owner;
    address public nftAddress;
    uint256 public nftTokenId;
    mapping(address => bool) redemptions;
    bytes4 immutable onErc1155SuccessfulResult =
        bytes4(
            keccak256(
                "onERC1155Received(address,address,uint256,uint256,bytes)"
            )
        );

    modifier onlyOwner() {
        require(msg.sender == owner, "must be owner");
        _;
    }

    constructor(address _nftAddress, uint256 _nftTokenId) public {
        owner = msg.sender;
        nftAddress = _nftAddress;
        nftTokenId = _nftTokenId;
    }

    function getSigner(
        address aCustomAddress,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(aCustomAddress));
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return ecrecover(prefixedHash, v, r, s);
    }

    function emergencyExecute(
        address targetAddress,
        bytes memory targetCallData
    ) public onlyOwner returns (bool) {
        (bool success, ) = targetAddress.call(targetCallData);
        return success;
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return onErc1155SuccessfulResult;
    }
}

