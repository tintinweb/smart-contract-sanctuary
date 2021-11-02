// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IERC721Burnable, IERC721} from "../../../external/interface/IERC721.sol";
import {Reentrancy} from "../../../lib/Reentrancy.sol";
import {ITreasuryConfig} from "../../../interface/ITreasuryConfig.sol";
import {IMirrorTreasury} from "../../../interface/IMirrorTreasury.sol";

/**
 * @title BurnERC721ToRedeemERC721
 * @author MirrorXYZ
 * Allows burning an "option" token in exchange for redeeming another transferrable
 * token.
 */
contract BurnERC721ToRedeemERC721 is Reentrancy {
    // ============ Constants ============

    uint256 constant REDEMPTION_PERIOD = 2 weeks;

    // ============ Immutable Storage ============

    // The recipient of the sales in ETH.
    address immutable fundingRecipient;
    // The ERC721 token that is being burned by the redeemer.
    address immutable burnToken;
    // The owner of the ERC721 token that is being redeemed.
    address immutable nftSender;
    // The price of the token being redeemed.
    uint256 immutable price;
    // The address of the Mirror treasury config, for getting the treasury address.
    address immutable treasuryConfig;
    // The address of the redeemable token.
    address immutable nft;
    // The token ID of the first token that's being redeemed.
    uint256 immutable startingId;
    // The total number of tokens that are being redeemed.
    uint256 immutable totalTokens;
    // The timestamp past which tokens cannot be redeemed.
    uint256 immutable endTime;

    // ============ Mutable Storage ============

    uint256 tokenCounter;

    // ============ Constructor ============

    constructor(
        address burnToken_,
        address nftSender_,
        address nft_,
        uint256 price_,
        address fundingRecipient_,
        address treasuryConfig_,
        uint256 startingId_,
        uint256 totalTokens_
    ) {
        burnToken = burnToken_;
        price = price_;
        treasuryConfig = treasuryConfig_;
        fundingRecipient = fundingRecipient_;
        nftSender = nftSender_;
        nft = nft_;
        startingId = startingId_;
        totalTokens = totalTokens_;

        endTime = block.timestamp + REDEMPTION_PERIOD;
    }

    // ============ Redeem Method ============

    /**
     * Allows the sender to burn some quantity of options in order
     * to redeem the same quantity of tokens, provided enough funds have
     * been transferred.
     */
    function redeem(uint256 burnableId) public payable nonReentrant {
        require(block.timestamp <= endTime, "Redemption period over");
        // Require that ETH has been sent.
        require(msg.value >= price, "Insufficient funds sent");
        // Burn the sender's ERC721 token.
        IERC721Burnable(burnToken).burn(burnableId);
        // Transfer the tokens to the user after burn.
        IERC721(nft).transferFrom(nftSender, msg.sender, tokenCounter);
        // Increment the token counter.
        tokenCounter += 1;
        // Check that we haven't gone over the number of total tokens.
        require(tokenCounter <= totalTokens);
    }

    // ============ Withdraw Methods ============

    /**
     * @notice Withdraws funds on the current proxy to the operator,
     * and transfer fee to treasury.
     */
    function withdraw() external nonReentrant {
        uint256 feePercentage = 250;

        uint256 fee = feeAmount(address(this).balance, feePercentage);

        IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury()).contribute{
            value: fee
        }(fee);

        // transfer the remaining available balance to the operator.
        _send(payable(fundingRecipient), address(this).balance);
    }

    function feeAmount(uint256 amount, uint256 fee)
        public
        pure
        returns (uint256)
    {
        return (amount * fee) / 10000;
    }

    // ============ Internal Methods ============

    function _send(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "recipient reverted");
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

interface IERC721Burnable is IERC721 {
    function burn(uint256 tokenId) external;
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

interface IERC721Royalties {
    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

contract Reentrancy {
    // ============ Constants ============

    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    // ============ Mutable Storage ============

    uint256 internal reentrancyStatus;

    // ============ Modifiers ============

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancyStatus != REENTRANCY_ENTERED, "Reentrant call");
        // Any calls to nonReentrant after this point will fail
        reentrancyStatus = REENTRANCY_ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip2200)
        reentrancyStatus = REENTRANCY_NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ITreasuryConfig {
    function treasury() external returns (address payable);

    function distributionModel() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorTreasury {
    function transferFunds(address payable to, uint256 value) external;

    function transferERC20(
        address token,
        address to,
        uint256 value
    ) external;

    function contributeWithTributary(address tributary) external payable;

    function contribute(uint256 amount) external payable;
}