/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface IERC20 { // brief interface for moloch erc20 token txs
    function balanceOf(address who) external view returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data
    )
        external 
        returns(bytes4);
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
    
    function totalShares() external view returns (uint256);
    
    function tokenWhitelist(address token) external view returns (bool);
    
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

    // function proposals(uint256 proposalId) external returns (Proposal memory);


    function withdrawBalance(address token, uint256 amount) external;
}

contract Minion is IERC721Receiver, IERC1155Receiver {
    using SafeMath for uint256;
    IMOLOCH public moloch;
    address public molochDepositToken;
    uint256 public minQuorum;
    bool private initialized; // internally tracks deployment under eip-1167 proxy pattern
    mapping(uint256 => Action) public actions; // proposalId => Action

    struct Action {
        uint256 value;
        address to;
        address proposer;
        bool executed;
        bytes data;
        address token;
        uint256 amount;
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

    function init(address _moloch, uint256 _minQuorum) external {
        require(!initialized, "initialized"); 
        moloch = IMOLOCH(_moloch);
        minQuorum = _minQuorum;
        molochDepositToken = moloch.depositToken();
        initialized = true;

    }

    function onERC721Received (address, address, uint256, bytes calldata) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
   

    //  -- Withdraw Functions --

    function doWithdraw(address token, uint256 amount) public memberOnly {
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
        string memory details,
        address withdrawToken,
        uint256 withdrawAmount
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
            withdrawAmount,
            withdrawToken,
            details
        );

        Action memory action = Action({
            value: actionValue,
            to: actionTo,
            proposer: msg.sender,
            executed: false,
            data: actionData,
            token: withdrawToken,
            amount: withdrawAmount
        });

        actions[proposalId] = action;

        emit ProposeAction(proposalId, msg.sender);
        return proposalId;
    }

    function executeAction(uint256 proposalId) external returns (bytes memory) {
        Action memory action = actions[proposalId];

        require(action.to != address(0), "invalid proposalId");
        require(!action.executed, "action executed");
        
        bool isPassed = hasQuorum(proposalId);

        require(isPassed, "proposal execution requirements not met");
        
        if(moloch.getUserTokenBalance(address(this), action.token) >= action.amount) {
            doWithdraw(action.token, action.amount);
        }
        
        require(address(this).balance >= action.value, "insufficient native token");
        

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
    
    function hasQuorum(uint256 _proposalId) internal returns (bool) {
        // something like this to check is some quorum is met
        // if met execution can proceed before proposal is processed

        uint256 padding = 100;
        uint256 totalShares = moloch.totalShares();
        bool[6] memory flags = moloch.getProposalFlags(_proposalId);


        // uint yesVotes = moloch.proposals(_proposalId).yesVotes;
        // uint noVotes = moloch.proposals(_proposalId).noVotes;
        (, , , , , , , , , , uint256 yesVotes, uint256 noVotes) = moloch.proposals(_proposalId);
        
        if (flags[2]) {
            return true;
        }

        if (minQuorum != 0) {
            uint256 quorum = yesVotes.mul(padding).div(totalShares);
            // if quorum is set it must be met and their can be no NO votes
            return quorum >= minQuorum && noVotes < 1;  
        }
        
        return false;

    }
    
    //  -- Helper Functions --
    
    function isMember(address user) public view returns (bool) {
        
        address memberAddress = moloch.memberAddressByDelegateKey(user);
        (, uint shares,,,,) = moloch.members(memberAddress);
        return shares > 0;
    }

    receive() external payable {}
    fallback() external payable {}
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
    
    event SummonMinion(address indexed minion, address indexed moloch, string details, string minionType, uint256 minQuorum);
    
    struct AMinion {
        address moloch;
        string details; 
    }
    
    
    constructor(address payable _template) {
        template = _template;
    }
    
    function summonMinion(address moloch, string memory details, uint256 minQuorum) external returns (address) {
        Minion minion = Minion(createClone(template));
        
        minion.init(moloch, minQuorum);
        string memory minionType = "nifty minion";
        
        minions[address(minion)] = AMinion(moloch, details);
        minionList.push(address(minion));
        emit SummonMinion(address(minion), moloch, details, minionType, minQuorum);
        
        return(address(minion));
        
    }
}