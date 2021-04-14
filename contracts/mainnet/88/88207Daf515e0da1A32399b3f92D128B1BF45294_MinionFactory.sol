/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 { // brief interface for moloch erc20 token txs
    function balanceOf(address who) external view returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
}

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

contract Minion is IERC721Receiver {
    IMOLOCH public moloch;
    address public molochDepositToken;
    bool private initialized; // internally tracks deployment under eip-1167 proxy pattern
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
    event DoWithdraw(address token, uint256 amount);
    event CrossWithdraw(address target, address token, uint256 amount);
    event PulledFunds(address moloch, uint256 amount);
    event ActionCanceled(uint256 proposalId);
    
     modifier memberOnly() {
        require(isMember(msg.sender), "Minion::not member");
        _;
    }

    function init(address _moloch) external {
        require(!initialized, "initialized"); 
        moloch = IMOLOCH(_moloch);
        molochDepositToken = moloch.depositToken();
        initialized = true; 
    }

    function onERC721Received (address, address, uint256, bytes calldata) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 
    
    //  -- Withdraw Functions --

    function doWithdraw(address token, uint256 amount) external memberOnly {
        moloch.withdrawBalance(token, amount); // withdraw funds from parent moloch
        emit DoWithdraw(token, amount);
    }
    
    function crossWithdraw(address target, address token, uint256 amount, bool transfer) external memberOnly {
        // @Dev - Target needs to have a withdrawBalance functions
        IMOLOCH(target).withdrawBalance(token, amount); 
        
        // Transfers token into DAO. 
        if(transfer) {
            bool whitelisted = moloch.tokenWhitelist(token);
            require(whitelisted, "not a whitelisted token");
            require(IERC20(token).transfer(address(moloch), amount), "token transfer failed");
        }
        
        emit CrossWithdraw(target, token, amount);
    }
    
    //  -- Proposal Functions --
    
    function proposeAction(
        address actionTo,
        uint256 actionValue,
        bytes calldata actionData,
        string calldata details
    ) external memberOnly returns (uint256) {
        // No calls to zero address allows us to check that proxy submitted
        // the proposal without getting the proposal struct from parent moloch
        require(actionTo != address(0), "invalid actionTo");

        uint256 proposalId = moloch.submitProposal(
            address(this),
            0,
            0,
            0,
            molochDepositToken,
            0,
            molochDepositToken,
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

    function executeAction(uint256 proposalId) external returns (bytes memory) {
        Action memory action = actions[proposalId];
        bool[6] memory flags = moloch.getProposalFlags(proposalId);

        require(action.to != address(0), "invalid proposalId");
        require(!action.executed, "action executed");
        require(address(this).balance >= action.value, "insufficient eth");
        require(flags[2], "proposal not passed");

        // execute call
        actions[proposalId].executed = true;
        (bool success, bytes memory retData) = action.to.call{value: action.value}(action.data);
        require(success, "call failure");
        emit ExecuteAction(proposalId, msg.sender);
        return retData;
    }
    
    function cancelAction(uint256 _proposalId) external {
        Action memory action = actions[_proposalId];
        require(msg.sender == action.proposer, "not proposer");
        delete actions[_proposalId];
        emit ActionCanceled(_proposalId);
        moloch.cancelProposal(_proposalId);
    }
    
    //  -- Helper Functions --
    
    function isMember(address user) public view returns (bool) {
        
        (, uint shares,,,,) = moloch.members(user);
        return shares > 0;
    }

    receive() external payable {}
}

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
contract CloneFactory {
    function createClone(address payable target) internal returns (address payable result) { // eip-1167 proxy pattern adapted for payable minion
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

contract MinionFactory is CloneFactory {
    address payable immutable public template; // fixed template for minion using eip-1167 proxy pattern
    address[] public minionList; 
    mapping (address => AMinion) public minions;
    
    event SummonMinion(address indexed minion, address indexed moloch, string details, string minionType);
    
    struct AMinion {
        address moloch;
        string details; 
    }
    
    
    constructor(address payable _template) {
        template = _template;
    }
    
    function summonMinion(address moloch, string memory details) external returns (address) {
        Minion minion = Minion(createClone(template));
        
        minion.init(moloch);
        string memory minionType = "vanilla minion";
        
        minions[address(minion)] = AMinion(moloch, details);
        minionList.push(address(minion));
        emit SummonMinion(address(minion), moloch, details, minionType);
        
        return(address(minion));
        
    }
}