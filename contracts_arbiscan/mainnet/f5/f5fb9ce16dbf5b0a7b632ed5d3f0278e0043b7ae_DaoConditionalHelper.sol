/**
 *Submitted for verification at arbiscan.io on 2022-01-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// Based on https://github.com/HausDAO/MinionSummoner/blob/main/MinionFactory.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

// import "hardhat/console.sol";

interface IERC20 { // brief interface for moloch erc20 token txs
    function balanceOf(address who) external view returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC1271 {
    function isValidSignature(bytes32 _messageHash, bytes memory _signature)
        external
        view
        returns (bytes4 magicValue);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC1155Receiver {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

interface IMOLOCH { // brief interface for moloch dao v2


    function depositToken() external view returns (address);
    
    function tokenWhitelist(address token) external view returns (bool);

    function totalShares() external view returns (uint256);
    
    function getProposalFlags(uint256 proposalId) external view returns (bool[6] memory);

    function getUserTokenBalance(address user, address token) external view returns (uint256);
    
    function members(address user) external view returns (address, uint256, uint256, bool, uint256, uint256);
    
    function memberAddressByDelegateKey(address user) external view returns (address);

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

    struct Proposal {
        address applicant; // the applicant who wishes to become a member - this key will be used for withdrawals (doubles as guild kick target for gkick proposals)
        address proposer; // the account that submitted the proposal (can be non-member)
        address sponsor; // the member that sponsored the proposal (moving it into the queue)
        uint256 sharesRequested; // the # of shares the applicant is requesting
        uint256 lootRequested; // the amount of loot the applicant is requesting
        uint256 tributeOffered; // amount of tokens offered as tribute
        address tributeToken; // tribute token contract reference
        uint256 paymentRequested; // amount of tokens requested as payment
        address paymentToken; // payment token contract reference
        uint256 startingPeriod; // the period in which voting can start for this proposal
        uint256 yesVotes; // the total number of YES votes for this proposal
        uint256 noVotes; // the total number of NO votes for this proposal
        bool[6] flags; // [sponsored, processed, didPass, cancelled, whitelist, guildkick]
        string details; // proposal details - could be IPFS hash, plaintext, or JSON
        uint256 maxTotalSharesAndLootAtYesVote; // the maximum # of total shares encountered at a yes vote on this proposal
    }
    function proposals(uint256 proposalId) external returns (address, address, address, uint256, uint256, uint256, address, uint256, address, uint256, uint256, uint256);
}

contract DaoConditionalHelper {

    function isDaoMember(address user, address dao) public view {
        // member only check should check if member or delegate
        IMOLOCH moloch = IMOLOCH(dao);
        address memberAddress = moloch.memberAddressByDelegateKey(user);
        (, uint shares,,,,) = moloch.members(memberAddress);
        require(shares > 0, "Is Not Dao Member");
    }

    function isNotDaoMember(address user, address dao) public view {
        // member only check should check if member or delegate
        IMOLOCH moloch = IMOLOCH(dao);
        address memberAddress = moloch.memberAddressByDelegateKey(user);
        (, uint shares,,,,) = moloch.members(memberAddress);
        require(shares == 0, "Is Not Dao Member");
    }

    function isAfter(uint256 timestamp) public view {
        require(timestamp < block.timestamp, "timestamp not meet");
    }

}