/**
 *Submitted for verification at polygonscan.com on 2021-10-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

/// @notice Brief interface for Moloch DAO v2. 
interface IMolMinimal { 
    function getProposalFlags(uint256 proposalId) external view returns (bool[6] memory);
    
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

/// @notice Contract module that helps prevent reentrant calls to a function.
abstract contract ReentrancyGuard {
    uint256 status = 1;
    
    modifier nonReentrant() {
        require(status == 1, "REENTRANT"); 
        status = 2; 
        _;
        status = 1;
    }
}

/// @notice Low-level caller, ETH/NFT holder, separate bank for Moloch DAO v2 - based on Raid Guild `Minion`.
contract SuChef is ReentrancyGuard {
    address internal depositToken;
    IMolMinimal public mochiMol; // parent 

    mapping(uint256 => Action) public actions; // proposalId => Action

    struct Action {
        uint256 value;
        address to;
        address proposer;
        bool executed;
        bytes data;
    }

    event ProposeAction(uint256 proposalId, address proposer);
    event ExecuteAction(uint256 proposalId, address executor);

    function init(address _depositToken, IMolMinimal _mochiMol) external {
        require(address(mochiMol) == address(0), "INITIALIZED");
        depositToken = _depositToken;
        mochiMol = _mochiMol;
    }

    function doWithdraw(address token, uint256 amount) external nonReentrant {
        mochiMol.withdrawBalance(token, amount); // withdraw funds from parent
    }

    function proposeAction(
        address actionTo,
        uint256 actionValue,
        bytes calldata actionData,
        string calldata details
    ) external nonReentrant returns (uint256) {
        // No calls to zero address allows us to check that proxy submitted
        // the proposal without getting the proposal struct from parent
        require(actionTo != address(0), "INVALID_ACTION_TO");

        uint256 proposalId = mochiMol.submitProposal(
            address(this),
            0,
            0,
            0,
            depositToken,
            0,
            depositToken,
            details
        );

        Action memory action = Action({
            value: actionValue,
            to: actionTo,
            proposer: msg.sender,
            executed: false,
            data: actionData
        });

        actions[proposalId] = action;

        emit ProposeAction(proposalId, msg.sender);
        return proposalId;
    }

    function executeAction(uint256 proposalId) external nonReentrant returns (bytes memory) {
        Action memory action = actions[proposalId];
        bool[6] memory flags = mochiMol.getProposalFlags(proposalId);

        require(action.to != address(0), "INVALID_ID");
        require(!action.executed, "ACTION_EXECUTED");
        require(address(this).balance >= action.value, "INSUFF_ETH");
        require(flags[2], "PROPOSAL_NOT_PASSED");

        // execute call
        actions[proposalId].executed = true;
        (bool success, bytes memory retData) = action.to.call{value: action.value}(action.data);
        require(success, "CALL_FAILURE");
        emit ExecuteAction(proposalId, msg.sender);
        return retData;
    }
    
    /// @dev Returns confirmation for 'safe' ERC-721 (NFT) transfers.
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4 sig) {
        sig = 0x150b7a02; // 'onERC721Received(address,address,uint,bytes)'
    }
    
    /// @dev Returns confirmation for 'safe' ERC-1155 transfers.
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4 sig) {
        sig = 0xf23a6e61; // 'onERC1155Received(address,address,uint,uint,bytes)'
    }
    
    /// @dev Returns confirmation for 'safe' batch ERC-1155 transfers.
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4 sig) {
        sig = 0xbc197c81; // 'onERC1155BatchReceived(address,address,uint[],uint[],bytes)'
    }

    receive() external payable {}
}

/// @author Copyright (c) 2018 Murray Software, LLC,
/// License-Identifier: MIT.
contract CloneFactory {
    /// @notice EIP-1167 proxy pattern.
    function createClone(address payable target) internal returns (address payable result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

/// @notice Summoner for minion-like SuChef for MochiMol DAO.
contract SuChefSummoner is CloneFactory {
    address payable immutable public template; // fixed template for suChef using eip-1167 proxy pattern
    
    event SummonSuChef(address indexed suChef, IMolMinimal indexed mochiMol);
    
    constructor(address payable _template) public {
        template = _template;
    }
    
    function summonSuChef(address depositToken, IMolMinimal mochiMol) external returns (SuChef suChef) {
        suChef = SuChef(createClone(template));
        
        suChef.init(depositToken, mochiMol);
        
        emit SummonSuChef(address(suChef), mochiMol);
    }
}