// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IERC721} from "../../../external/interface/IERC721.sol";
import {IAllocatedEditionsLogic} from "./interface/IAllocatedEditionsLogic.sol";

/**
 * @title BurnAllocatedEditions
 * @author MirrorXYZ
 */
contract BurnAllocatedEditions {
    // ============ Storage for Setup ============

    /// @notice Edition Config
    address public editions;

    // ============ Constructor ============

    constructor(address editions_) {
        editions = editions_;
    }

    // ============ Edition Methods ============

    function batchBurn(uint256 fromTokenId, uint256 toTokenId) external {
        require(
            fromTokenId <= toTokenId,
            "fromTokenId should be less than or equal to toTokenId"
        );

        for (uint256 i = fromTokenId; i <= toTokenId; i++) {
            IERC721(editions).transferFrom(msg.sender, address(this), i);
            IAllocatedEditionsLogic(editions).burn(i);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Events {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IAllocatedEditionsLogicEvents {
    event EditionPurchased(
        uint256 indexed tokenId,
        uint256 amountPaid,
        address buyer,
        address receiver
    );

    event EditionCreatorChanged(
        address indexed previousCreator,
        address indexed newCreator
    );
}

interface IAllocatedEditionsLogic {
    function changeBaseURI(string memory baseURI_) external;

    function withdrawFunds() external;

    function burn(uint256 tokenId) external;
}

