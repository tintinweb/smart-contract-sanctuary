/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// Based on https://github.com/HausDAO/MinionSummoner/blob/main/MinionFactory.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 {
    // brief interface for moloch erc20 token txs
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC721 {
    // brief interface for minion erc721 token txs
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155 {
    // brief interface for minion erc1155 token txs
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    // TODO batch receive not implemented in tribute yet
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IMOLOCH {
    // brief interface for moloch dao v2

    function depositToken() external view returns (address);

    function tokenWhitelist(address token) external view returns (bool);

    function getProposalFlags(uint256 proposalId)
        external
        view
        returns (bool[6] memory);

    function members(address user)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        );

    function userTokenBalances(address user, address token)
        external
        view
        returns (uint256);

    function cancelProposal(uint256 proposalId) external;

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);

    function withdrawBalance(address token, uint256 amount) external;
}

contract NFTEscrowMinion is IERC721Receiver {
    mapping(address => mapping(uint256 => TributeEscrowAction)) public actions; // proposalId => Action

    enum TributeType {
        ERC20,
        ERC721,
        ERC1155
    }

    struct TributeEscrowAction {
        address tokenAddress;
        uint256 tokenId;
        address vaultAddress; // todo multiple vault destinations?
        address proposer;
        bool executed;
    }

    event ProposeAction(uint256 proposalId, address proposer, address moloch, address tokenAddress, uint256 tokenId, address destinationVault);
    event ExecuteAction(uint256 proposalId, address executor, address moloch);
    event ActionCanceled(uint256 proposalId, address moloch);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function doTransfers(
        TributeEscrowAction memory action,
        address from,
        address to
    ) internal {
        IERC721 erc721 = IERC721(action.tokenAddress);
        erc721.safeTransferFrom(from, to, action.tokenId);
    }

    function saveAction(
        address molochAddress,
        address tokenAddress,
        uint256 tokenId,
        // uint256[] calldata amounts,
        address vaultAddress,
        uint256 proposalId
    ) private returns (TributeEscrowAction memory) {
        TributeEscrowAction memory action = TributeEscrowAction({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            vaultAddress: vaultAddress,
            proposer: msg.sender,
            executed: false
        });

        actions[molochAddress][proposalId] = action;
        emit ProposeAction(proposalId, msg.sender, molochAddress, tokenAddress, tokenId, vaultAddress);
        return action;
    }

    //  -- Proposal Functions --
    /**
     * @notice Creates a proposal and moves NFT into escrow
     * @param molochAddress Address of DAO
     * @param vaultAddress Address of DAO's NFT vault
     * @param requestSharesLootFunds Amount of shares requested
     // add funding request token
     * @param details Info about proposal
     */
    // todo no re-entrency
    function proposeTribute(
        address molochAddress,
        // add array of erc1155, 721 or 20
        address tokenAddress,
        uint256 tokenId,
        address vaultAddress,
        uint256[3] calldata requestSharesLootFunds, // also request loot or treasury funds
        string calldata details
    ) external returns (uint256) {
        IMOLOCH thisMoloch = IMOLOCH(molochAddress);
        address thisMolochDepositToken = thisMoloch.depositToken();

        require(vaultAddress != address(0), "invalid vaultAddress");

        uint256 proposalId = thisMoloch.submitProposal(
            msg.sender,
            requestSharesLootFunds[0],
            requestSharesLootFunds[1],
            0,
            thisMolochDepositToken,
            requestSharesLootFunds[2],
            thisMolochDepositToken,
            details
        );

        TributeEscrowAction memory action = saveAction(
            molochAddress,
            tokenAddress,
            tokenId,
            vaultAddress,
            proposalId
        );

        doTransfers(action, msg.sender, address(this));

        return proposalId;
    }

    // todo no re-entrency
    function executeAction(uint256 proposalId, address molochAddress) external {
        IMOLOCH thisMoloch = IMOLOCH(molochAddress);

        TributeEscrowAction memory action = actions[molochAddress][proposalId];
        bool[6] memory flags = thisMoloch.getProposalFlags(proposalId);

        require(action.vaultAddress != address(0), "invalid proposalId");
        // TODO check for IERC721Receiver interface

        require(!action.executed, "action executed");

        require(flags[1], "proposal not processed");

        require(!flags[3], "proposal cancelled");

        address destination;
        // if passed, send NFT to vault
        if (flags[2]) {
            destination = action.vaultAddress;
        } else {
            destination = action.proposer;
        }

        doTransfers(action, address(this), destination);

        actions[molochAddress][proposalId].executed = true;

        emit ExecuteAction(proposalId, msg.sender, molochAddress);
    }

    // todo no re-entrency
    function cancelAction(uint256 _proposalId, address molochAddress) external {
        IMOLOCH thisMoloch = IMOLOCH(molochAddress);
        TributeEscrowAction memory action = actions[molochAddress][_proposalId];

        require(msg.sender == action.proposer, "not proposer");
        thisMoloch.cancelProposal(_proposalId);

        doTransfers(action, address(this), msg.sender);

        delete actions[molochAddress][_proposalId];

        emit ActionCanceled(_proposalId, molochAddress);
    }
}