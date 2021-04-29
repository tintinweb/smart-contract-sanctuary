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

    function redeemNft(
        address address1,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(isDropRecipient(address1, v, r, s));
        require(redemptions[address1] == false, "already redeemed");

        redemptions[address1] = true;
        IERC1155(nftAddress).safeTransferFrom(
            address(this),
            address1,
            nftTokenId,
            1,
            ""
        );
    }

    function hasReedeemed(address address1) public view returns (bool) {
        return redemptions[address1];
    }

    function hashedAddress(address address1) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(address1));
    }

    function generateAddressHash(address address1)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n64",
                    keccak256(abi.encodePacked(address1))
                )
            );
    }

    function isDropRecipient(
        address address1,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        address signedBy = ecrecover(generateAddressHash(address1), v, r, s);
        return signedBy == owner;
    }

    function emergencyExescute(
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}