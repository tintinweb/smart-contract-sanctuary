/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// Based on https://github.com/HausDAO/MinionSummoner/blob/main/MinionFactory.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 { // brief interface for moloch erc20 token txs
    function balanceOf(address who) external view returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC721 { // brief interface for minion erc721 token txs
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// TODO add IERC1155Receiver
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IMOLOCH { // brief interface for moloch dao v2


    function depositToken() external view returns (address);
    
    function tokenWhitelist(address token) external view returns (bool);
    
    function getProposalFlags(uint256 proposalId) external view returns (bool[6] memory);
    
    function members(address user) external view returns (address, uint256, uint256, bool, uint256, uint256);
    
    function userTokenBalances(address user, address token) external view returns (uint256);
    
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

contract EscrowMinion is IERC721Receiver {
    mapping(address => mapping (uint256 => TributeEscrowAction)) public actions; // proposalId => Action

    struct TributeEscrowAction {
        address tokenAddress;
        uint256 tokenId;
        address vaultAddress;
        address proposer;
        address applicant;
        bool executed;
    }

    event ProposeAction(uint256 proposalId, address proposer, address moloch);
    event ExecuteAction(uint256 proposalId, address executor, address moloch);
    event ActionCanceled(uint256 proposalId, address moloch);
    
    function onERC721Received (address, address, uint256, bytes calldata) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 
    
    //  -- Proposal Functions --
   /**
     * @notice Creates a proposal and moves NFT into escrow
     * @param applicant Application address for the new shares
     * @param molochAddress Address of DAO
     * @param tokenAddress NFT contract address
     * @param tokenId NFT token id.
     * @param vaultAddress Address of DAO's NFT vault
     * @param requestAmount Amount of shares requested
     * @param details Info about proposal
     */
    function proposeTribute(
        address applicant,
        address molochAddress,
        address tokenAddress,
        uint256 tokenId,
        address vaultAddress,
        uint256 requestAmount,
        string calldata details
        ) external returns (uint256) {
          IMOLOCH thisMoloch = IMOLOCH(molochAddress);
          address thisMolochDepositToken = thisMoloch.depositToken();
          
          // Enforce applicant is message sender so proposal can't be front-run
          require(applicant == msg.sender, 'sender is not applicant');

          require(vaultAddress != address(0), "invalid vaultAddress");
          
          // TODO maybe do an interface check to see if vaultAddress is IERC721Receiver
          
          IERC721 erc721 = IERC721(tokenAddress);
          
          erc721.safeTransferFrom(applicant, address(this), tokenId);

          uint256 proposalId = thisMoloch.submitProposal(
              applicant,
              requestAmount,
              0,
              0,
              thisMolochDepositToken,
              0,
              thisMolochDepositToken,
              details
          );
          
          TributeEscrowAction memory action = TributeEscrowAction({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            vaultAddress: vaultAddress,
            proposer: msg.sender,
            applicant: applicant,
            executed: false
          });
          
          actions[molochAddress][proposalId] = action;
          
          emit ProposeAction(proposalId, msg.sender, molochAddress);
          return proposalId;
        }
    
    function executeAction(uint256 proposalId, address molochAddress) external {
        IMOLOCH thisMoloch = IMOLOCH(molochAddress);

        TributeEscrowAction memory action = actions[molochAddress][proposalId];
        bool[6] memory flags = thisMoloch.getProposalFlags(proposalId);

        require(action.vaultAddress != address(0), "invalid proposalId");
        // TODO check for IERC721Receiver interface

        require(!action.executed, "action executed");

        require(!flags[3], "proposal cancelled");

        // bool[6] memory flags; // [sponsored, processed, didPass, cancelled, whitelist, guildkick]

        // if canceled or failed, return NFT to applicant
        
        IERC721 erc721 = IERC721(action.tokenAddress);
        // if passed, send NFT to vault
        if(flags[2]) {
          erc721.safeTransferFrom(address(this), action.vaultAddress, action.tokenId);
        } else if (flags[1] && !flags[2]) {
          erc721.safeTransferFrom(address(this), action.applicant, action.tokenId);
        }

        actions[molochAddress][proposalId].executed = true;

        emit ExecuteAction(proposalId, msg.sender, molochAddress);
    }
    
    function cancelAction(uint256 _proposalId, address molochAddress) external {
        IMOLOCH thisMoloch = IMOLOCH(molochAddress);
        TributeEscrowAction memory action = actions[molochAddress][_proposalId];

        require(msg.sender == action.proposer, "not proposer");
        delete actions[molochAddress][_proposalId];

        //return the NFT
        IERC721 erc721 = IERC721(action.tokenAddress);
        erc721.safeTransferFrom(address(this), action.applicant, action.tokenId);

        emit ActionCanceled(_proposalId, molochAddress);
        thisMoloch.cancelProposal(_proposalId);
    }
    
}