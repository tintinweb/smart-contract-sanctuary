// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

interface IERC721 {
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract NftMinter {
    address public admin;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(admin == msg.sender, 'caller is not admin');
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public payable onlyAdmin returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, 'Timelock::executeTransaction: Transaction execution reverted.');

        return returnData;
    }

    function batchTransferToken(
         address target, // target nft contract address
         uint256[] calldata tokenIds,
         address to
    ) public onlyAdmin {
        for (uint256 i; i < tokenIds.length; i++) {
             IERC721(target).safeTransferFrom(address(this), to, tokenIds[i]);
        }
    }

    // mint the tokens and ensure the desired token id is minted.
    function mintEnsureTokenId(
        address target, // target nft contract address
        uint256 value, // amount to pay in eth for each one
        uint256 amount, // how many tokens to mint
        string memory signature, // function call
        uint256 tokenId, // the tokenId we must receive
        bytes memory data
    ) public payable {
        bytes memory callData;
        require(msg.value >= value * amount, 'amount does not match');

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        for (uint256 i; i < amount; i++) {
            // solium-disable-next-line security/no-call-value
            (bool success, ) = target.call{value: value}(callData);
            require(success, 'mintEnsureTokenId: Transaction execution reverted.');
            // now check if we have received any tokens
        }

        // we don't know other tokens being minted, so we only transfer this token.
        IERC721(target).safeTransferFrom(address(this), msg.sender, tokenId);
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}