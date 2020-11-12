// File: contracts/external/govblocks-protocol/interfaces/IGovernance.sol

/* Copyright (C) 2017 GovBlocks.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract IGovernance { 

    event Proposal(
        address indexed proposalOwner,
        uint256 indexed proposalId,
        uint256 dateAdd,
        string proposalTitle,
        string proposalSD,
        string proposalDescHash
    );

    event Solution(
        uint256 indexed proposalId,
        address indexed solutionOwner,
        uint256 indexed solutionId,
        string solutionDescHash,
        uint256 dateAdd
    );

    event Vote(
        address indexed from,
        uint256 indexed proposalId,
        uint256 indexed voteId,
        uint256 dateAdd,
        uint256 solutionChosen
    );

    event RewardClaimed(
        address indexed member,
        uint gbtReward
    );

    /// @dev VoteCast event is called whenever a vote is cast that can potentially close the proposal. 
    event VoteCast (uint256 proposalId);

    /// @dev ProposalAccepted event is called when a proposal is accepted so that a server can listen that can 
    ///      call any offchain actions
    event ProposalAccepted (uint256 proposalId);

    /// @dev CloseProposalOnTime event is called whenever a proposal is created or updated to close it on time.
    event CloseProposalOnTime (
        uint256 indexed proposalId,
        uint256 time
    );

    /// @dev ActionSuccess event is called whenever an onchain action is executed.
    event ActionSuccess (
        uint256 proposalId
    );

    /// @dev Creates a new proposal
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    function createProposal(
        string calldata _proposalTitle,
        string calldata _proposalSD,
        string calldata _proposalDescHash,
        uint _categoryId
    ) 
        external;

    /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
    function categorizeProposal(
        uint _proposalId, 
        uint _categoryId,
        uint _incentives
    ) 
        external;

    /// @dev Submit proposal with solution
    /// @param _proposalId Proposal id
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function submitProposalWithSolution(
        uint _proposalId, 
        string calldata _solutionHash, 
        bytes calldata _action
    ) 
        external;

    /// @dev Creates a new proposal with solution and votes for the solution
    /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
    /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
    /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
    function createProposalwithSolution(
        string calldata _proposalTitle, 
        string calldata _proposalSD, 
        string calldata _proposalDescHash,
        uint _categoryId, 
        string calldata _solutionHash, 
        bytes calldata _action
    ) 
        external;

    /// @dev Casts vote
    /// @param _proposalId Proposal id
    /// @param _solutionChosen solution chosen while voting. _solutionChosen[0] is the chosen solution
    function submitVote(uint _proposalId, uint _solutionChosen) external;

    function closeProposal(uint _proposalId) external;

    function claimReward(address _memberAddress, uint _maxRecords) external returns(uint pendingDAppReward); 

    function proposal(uint _proposalId)
        external
        view
        returns(
            uint proposalId,
            uint category,
            uint status,
            uint finalVerdict,
            uint totalReward
        );

    function canCloseProposal(uint _proposalId) public view returns(uint closeValue);

    function allowedToCatgorize() public view returns(uint roleId);

    /**
     * @dev Gets length of propsal
     * @return length of propsal
     */
    function getProposalLength() external view returns(uint);

}

// File: contracts/external/govblocks-protocol/interfaces/IProposalCategory.sol

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract IProposalCategory {

    event Category(
        uint indexed categoryId,
        string categoryName,
        string actionHash
    );

    mapping(uint256 => bytes) public categoryActionHashes;

    /**
    * @dev Adds new category
    * @param _name Category name
    * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    * @param _majorityVotePerc Majority Vote threshold for Each voting layer
    * @param _quorumPerc minimum threshold percentage required in voting to calculate result
    * @param _allowedToCreateProposal Member roles allowed to create the proposal
    * @param _closingTime Vote closing time for Each voting layer
    * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    * @param _contractAddress address of contract to call after proposal is accepted
    * @param _contractName name of contract to be called after proposal is accepted
    * @param _incentives rewards to distributed after proposal is accepted
    * @param _functionHash function signature to be executed
    */
    function newCategory(
        string calldata _name, 
        uint _memberRoleToVote,
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] calldata _allowedToCreateProposal,
        uint _closingTime,
        string calldata _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] calldata _incentives,
        string calldata _functionHash
    )
        external;

    /** @dev gets category details
    */
    function category(uint _categoryId)
        external
        view
        returns(
            uint categoryId,
            uint memberRoleToVote,
            uint majorityVotePerc,
            uint quorumPerc,
            uint[] memory allowedToCreateProposal,
            uint closingTime,
            uint minStake
        );
    
    /**@dev gets category action details
    */
    function categoryAction(uint _categoryId)
        external
        view
        returns(
            uint categoryId,
            address contractAddress,
            bytes2 contractName,
            uint defaultIncentive
        );
    
    /** @dev Gets Total number of categories added till now
    */
    function totalCategories() external view returns(uint numberOfCategories);

    /**
     * @dev Gets the category acion details of a category id
     * @param _categoryId is the category id in concern
     * @return the category id
     * @return the contract address
     * @return the contract name
     * @return the default incentive
     * @return action function hash
     */
    function categoryActionDetails(uint256 _categoryId)
        external
        view
        returns (
            uint256,
            address,
            bytes2,
            uint256,
            bytes memory
        );

    /**
    * @dev Updates category details
    * @param _categoryId Category id that needs to be updated
    * @param _name Category name
    * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
    * @param _allowedToCreateProposal Member roles allowed to create the proposal
    * @param _majorityVotePerc Majority Vote threshold for Each voting layer
    * @param _quorumPerc minimum threshold percentage required in voting to calculate result
    * @param _closingTime Vote closing time for Each voting layer
    * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
    * @param _contractAddress address of contract to call after proposal is accepted
    * @param _contractName name of contract to be called after proposal is accepted
    * @param _incentives rewards to distributed after proposal is accepted
    * @param _functionHash function signature to be executed
    */
    function editCategory(
        uint _categoryId, 
        string calldata _name, 
        uint _memberRoleToVote, 
        uint _majorityVotePerc, 
        uint _quorumPerc,
        uint[] calldata _allowedToCreateProposal,
        uint _closingTime,
        string calldata _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] calldata _incentives,
        string calldata _functionHash
    )
        external;

}

// File: contracts/external/govblocks-protocol/interfaces/IMemberRoles.sol

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;


contract IMemberRoles {

    event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);
    
    enum Role {UnAssigned, AdvisoryBoard, TokenHolder, DisputeResolution}

    function setInititorAddress(address _initiator) external;

    /// @dev Adds new member role
    /// @param _roleName New role name
    /// @param _roleDescription New description hash
    /// @param _authorized Authorized member against every role id
    function addRole(bytes32 _roleName, string memory _roleDescription, address _authorized) public;

    /// @dev Assign or Delete a member from specific role.
    /// @param _memberAddress Address of Member
    /// @param _roleId RoleId to update
    /// @param _active active is set to be True if we want to assign this role to member, False otherwise!
    function updateRole(address _memberAddress, uint _roleId, bool _active) public;

    /// @dev Change Member Address who holds the authority to Add/Delete any member from specific role.
    /// @param _roleId roleId to update its Authorized Address
    /// @param _authorized New authorized address against role id
    function changeAuthorized(uint _roleId, address _authorized) public;

    /// @dev Return number of member roles
    function totalRoles() public view returns(uint256);

    /// @dev Gets the member addresses assigned by a specific role
    /// @param _memberRoleId Member role id
    /// @return roleId Role id
    /// @return allMemberAddress Member addresses of specified role id
    function members(uint _memberRoleId) public view returns(uint, address[] memory allMemberAddress);

    /// @dev Gets all members' length
    /// @param _memberRoleId Member role id
    /// @return memberRoleData[_memberRoleId].memberAddress.length Member length
    function numberOfMembers(uint _memberRoleId) public view returns(uint);
    
    /// @dev Return member address who holds the right to add/remove any member from specific role.
    function authorized(uint _memberRoleId) public view returns(address);

    /// @dev Get All role ids array that has been assigned to a member so far.
    function roles(address _memberAddress) public view returns(uint[] memory assignedRoles);

    /// @dev Returns true if the given role id is assigned to a member.
    /// @param _memberAddress Address of member
    /// @param _roleId Checks member's authenticity with the roleId.
    /// i.e. Returns true if this roleId is assigned to member
    function checkRole(address _memberAddress, uint _roleId) public view returns(bool);   
}

// File: contracts/external/proxy/Proxy.sol

pragma solidity 0.5.7;


/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function () external payable {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
            }
    }

    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function implementation() public view returns (address);
}

// File: contracts/external/proxy/UpgradeabilityProxy.sol

pragma solidity 0.5.7;



/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param implementation representing the address of the upgraded implementation
    */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant IMPLEMENTATION_POSITION = keccak256("org.govblocks.proxy.implementation");

    /**
    * @dev Constructor function
    */
    constructor() public {}

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address impl) {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
            impl := sload(position)
        }
    }

    /**
    * @dev Sets the address of the current implementation
    * @param _newImplementation address representing the new implementation to be set
    */
    function _setImplementation(address _newImplementation) internal {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
        sstore(position, _newImplementation)
        }
    }

    /**
    * @dev Upgrades the implementation address
    * @param _newImplementation representing the address of the new implementation to be set
    */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}

// File: contracts/external/proxy/OwnedUpgradeabilityProxy.sol

pragma solidity 0.5.7;



/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    // Storage position of the owner of the contract
    bytes32 private constant PROXY_OWNER_POSITION = keccak256("org.govblocks.proxy.owner");

    /**
    * @dev the constructor sets the original owner of the contract to the sender account.
    */
    constructor(address _implementation) public {
        _setUpgradeabilityOwner(msg.sender);
        _upgradeTo(_implementation);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
    }

    /**
    * @dev Allows the proxy owner to upgrade the current version of the proxy.
    * @param _implementation representing the address of the new implementation to be set.
    */
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Sets the address of the owner
    */
    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}

// File: contracts/external/openzeppelin-solidity/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library SafeMath64 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint64 c = a - b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint64 a, uint64 b, string memory errorMessage) internal pure returns (uint64) {
        require(b <= a, errorMessage);
        uint64 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint64 a, uint64 b) internal pure returns (uint64) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint64 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint64 a, uint64 b) internal pure returns (uint64) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint64 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/interfaces/Iupgradable.sol

pragma solidity 0.5.7;

contract Iupgradable {

    /**
     * @dev change master address
     */
    function setMasterAddress() public;
}

// File: contracts/interfaces/IMarketRegistry.sol

pragma solidity 0.5.7;

contract IMarketRegistry {

    enum MarketType {
      HourlyMarket,
      DailyMarket,
      WeeklyMarket
    }
    address public owner;
    address public tokenController;
    address public marketUtility;
    bool public marketCreationPaused;

    mapping(address => bool) public isMarket;
    function() external payable{}

    function marketDisputeStatus(address _marketAddress) public view returns(uint _status);

    function burnDisputedProposalTokens(uint _proposaId) external;

    function isWhitelistedSponsor(address _address) public view returns(bool);

    function transferAssets(address _asset, address _to, uint _amount) external;

    /**
    * @dev Initialize the PlotX.
    * @param _marketConfig The address of market config.
    * @param _plotToken The address of PLOT token.
    */
    function initiate(address _defaultAddress, address _marketConfig, address _plotToken, address payable[] memory _configParams) public;

    /**
    * @dev Create proposal if user wants to raise the dispute.
    * @param proposalTitle The title of proposal created by user.
    * @param description The description of dispute.
    * @param solutionHash The ipfs solution hash.
    * @param actionHash The action hash for solution.
    * @param stakeForDispute The token staked to raise the diospute.
    * @param user The address who raises the dispute.
    */
    function createGovernanceProposal(string memory proposalTitle, string memory description, string memory solutionHash, bytes memory actionHash, uint256 stakeForDispute, address user, uint256 ethSentToPool, uint256 tokenSentToPool, uint256 proposedValue) public {
    }

    /**
    * @dev Emits the PlacePrediction event and sets user data.
    * @param _user The address who placed prediction.
    * @param _value The amount of ether user staked.
    * @param _predictionPoints The positions user will get.
    * @param _predictionAsset The prediction assets user will get.
    * @param _prediction The option range on which user placed prediction.
    * @param _leverage The leverage selected by user at the time of place prediction.
    */
    function setUserGlobalPredictionData(address _user,uint _value, uint _predictionPoints, address _predictionAsset, uint _prediction,uint _leverage) public{
    }

    /**
    * @dev Emits the claimed event.
    * @param _user The address who claim their reward.
    * @param _reward The reward which is claimed by user.
    * @param incentives The incentives of user.
    * @param incentiveToken The incentive tokens of user.
    */
    function callClaimedEvent(address _user , uint[] memory _reward, address[] memory predictionAssets, uint incentives, address incentiveToken) public {
    }

        /**
    * @dev Emits the MarketResult event.
    * @param _totalReward The amount of reward to be distribute.
    * @param _winningOption The winning option of the market.
    * @param _closeValue The closing value of the market currency.
    */
    function callMarketResultEvent(uint[] memory _totalReward, uint _winningOption, uint _closeValue, uint roundId) public {
    }
}

// File: contracts/interfaces/ITokenController.sol

pragma solidity 0.5.7;

contract ITokenController {
	address public token;
    address public bLOTToken;

    /**
    * @dev Swap BLOT token.
    * account.
    * @param amount The amount that will be swapped.
    */
    function swapBLOT(address _of, address _to, uint256 amount) public;

    function totalBalanceOf(address _of)
        public
        view
        returns (uint256 amount);

    function transferFrom(address _token, address _of, address _to, uint256 amount) public;

    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason at a specific time
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     * @param _time The timestamp to query the lock tokens for
     */
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 amount);

    /**
    * @dev burns an amount of the tokens of the message sender
    * account.
    * @param amount The amount that will be burnt.
    */
    function burnCommissionTokens(uint256 amount) external returns(bool);
 
    function initiateVesting(address _vesting) external;

    function lockForGovernanceVote(address _of, uint _days) public;

    function totalSupply() public view returns (uint256);

    function mint(address _member, uint _amount) public;

}

// File: contracts/interfaces/IToken.sol

pragma solidity 0.5.7;

contract IToken {

    function decimals() external view returns(uint8);

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() external view returns (uint256);

    /**
    * @dev Gets the balance of the specified address.
    * @param account The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address account) external view returns (uint256);

    /**
    * @dev Transfer token for a specified address
    * @param recipient The address to transfer to.
    * @param amount The amount to be transferred.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
    * @dev function that mints an amount of the token and assigns it to
    * an account.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function mint(address account, uint256 amount) external returns (bool);
    
     /**
    * @dev burns an amount of the tokens of the message sender
    * account.
    * @param amount The amount that will be burnt.
    */
    function burn(uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
    * @dev Transfer tokens from one address to another
    * @param sender address The address which you want to send tokens from
    * @param recipient address The address which you want to transfer to
    * @param amount uint256 the amount of tokens to be transferred
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

// File: contracts/interfaces/IMaster.sol

pragma solidity 0.5.7;

contract IMaster {
    function dAppToken() public view returns(address);
    function isInternal(address _address) public view returns(bool);
    function getLatestAddress(bytes2 _module) public view returns(address);
    function isAuthorizedToGovern(address _toCheck) public view returns(bool);
}

// File: contracts/interfaces/IMarket.sol

pragma solidity 0.5.7;

contract IMarket {

    enum PredictionStatus {
      Live,
      InSettlement,
      Cooling,
      InDispute,
      Settled
    }

    struct MarketData {
      uint64 startTime;
      uint64 predictionTime;
      uint64 neutralMinValue;
      uint64 neutralMaxValue;
    }

    struct MarketSettleData {
      uint64 WinningOption;
      uint64 settleTime;
    }

    MarketSettleData public marketSettleData;

    MarketData public marketData;

    function WinningOption() public view returns(uint256);

    function marketCurrency() public view returns(bytes32);

    function getMarketFeedData() public view returns(uint8, bytes32, address);

    function settleMarket() external;
    
    function getTotalStakedValueInPLOT() external view returns(uint256);

    /**
    * @dev Initialize the market.
    * @param _startTime The time at which market will create.
    * @param _predictionTime The time duration of market.
    * @param _minValue The minimum value of middle option range.
    * @param _maxValue The maximum value of middle option range.
    */
    function initiate(uint64 _startTime, uint64 _predictionTime, uint64 _minValue, uint64 _maxValue) public payable;

    /**
    * @dev Resolve the dispute if wrong value passed at the time of market result declaration.
    * @param accepted The flag defining that the dispute raised is accepted or not 
    * @param finalResult The final correct value of market currency.
    */
    function resolveDispute(bool accepted, uint256 finalResult) external payable;

    /**
    * @dev Gets the market data.
    * @return _marketCurrency bytes32 representing the currency or stock name of the market.
    * @return minvalue uint[] memory representing the minimum range of all the options of the market.
    * @return maxvalue uint[] memory representing the maximum range of all the options of the market.
    * @return _optionPrice uint[] memory representing the option price of each option ranges of the market.
    * @return _ethStaked uint[] memory representing the ether staked on each option ranges of the market.
    * @return _plotStaked uint[] memory representing the plot staked on each option ranges of the market.
    * @return _predictionType uint representing the type of market.
    * @return _expireTime uint representing the expire time of the market.
    * @return _predictionStatus uint representing the status of the market.
    */
    function getData() external view 
    	returns (
    		bytes32 _marketCurrency,uint[] memory minvalue,uint[] memory maxvalue,
        	uint[] memory _optionPrice, uint[] memory _ethStaked, uint[] memory _plotStaked,uint _predictionType,
        	uint _expireTime, uint _predictionStatus
        );

    // /**
    // * @dev Gets the pending return.
    // * @param _user The address to specify the return of.
    // * @return uint representing the pending return amount.
    // */
    // function getPendingReturn(address _user) external view returns(uint[] memory returnAmount, address[] memory _predictionAssets, uint[] memory incentive, address[] memory _incentiveTokens);

    /**
    * @dev Claim the return amount of the specified address.
    * @param _user The address to query the claim return amount of.
    * @return Flag, if 0:cannot claim, 1: Already Claimed, 2: Claimed
    */
    function claimReturn(address payable _user) public returns(uint256);

}

// File: contracts/Governance.sol

/* Copyright (C) 2020 PlotX.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity 0.5.7;












contract Governance is IGovernance, Iupgradable {
    using SafeMath for uint256;

    enum ProposalStatus {
        Draft,
        AwaitingSolution,
        VotingStarted,
        Accepted,
        Rejected,
        Denied
    }

    struct ProposalData {
        uint256 propStatus;
        uint256 finalVerdict;
        uint256 category;
        uint256 commonIncentive;
        uint256 dateUpd;
        uint256 totalVoteValue;
        address owner;
    }

    struct ProposalVote {
        address voter;
        uint256 proposalId;
        uint256 solutionChosen;
        uint256 voteValue;
        uint256 dateAdd;
    }
    struct VoteTally {
        mapping(uint256 => uint256) voteValue;
        mapping(uint=>uint) abVoteValue;
        uint256 voters;
    }

    ProposalVote[] internal allVotes;

    mapping(uint256 => ProposalData) internal allProposalData;
    mapping(uint256 => bytes[]) internal allProposalSolutions;
    mapping(address => uint256[]) internal allVotesByMember;
    mapping(uint256 => mapping(address => bool)) public rewardClaimed;
    mapping(address => mapping(uint256 => uint256)) public memberProposalVote;
    mapping(uint256 => VoteTally) public proposalVoteTally;
    mapping(address => uint256) public lastRewardClaimed;

    bytes32 constant swapABMemberHash = keccak256(abi.encodeWithSignature("swapABMember(address,address)"));
    bytes32 constant resolveDisputeHash = keccak256(abi.encodeWithSignature("resolveDispute(address,uint256)"));
    uint256 constant totalSupplyCapForDRQrm = 50;

    bool internal constructorCheck;
    uint256 public tokenHoldingTime;
    uint256 internal roleIdAllowedToCatgorize;
    uint256 internal maxVoteWeigthPer;
    uint256 internal advisoryBoardMajority;
    uint256 internal totalProposals;
    uint256 internal maxDraftTime;
    uint256 internal votePercRejectAction;
    uint256 internal actionRejectAuthRole;
    uint256 internal drQuorumMulitplier;

    IMaster public ms;
    IMemberRoles internal memberRole;
    IMarketRegistry internal marketRegistry;
    IProposalCategory internal proposalCategory;
    //Plot Token Instance
    IToken internal tokenInstance;
    ITokenController internal tokenController;

    mapping(uint256 => uint256) public proposalActionStatus;
    mapping(uint256 => uint256) internal proposalExecutionTime;
    mapping(uint256 => mapping(address => bool)) public isActionRejected;
    mapping(uint256 => uint256) internal actionRejectedCount;

    uint256 internal actionWaitingTime;

    enum ActionStatus {Pending, Accepted, Rejected, Executed, NoAction}

    /**
     * @dev Called whenever an action execution is failed.
     */
    event ActionFailed(uint256 proposalId);

    /**
     * @dev Called whenever an AB member rejects the action execution.
     */
    event ActionRejected(uint256 indexed proposalId, address rejectedBy);

    /**
     * @dev Checks if msg.sender is proposal owner
     */
    modifier onlyProposalOwner(uint256 _proposalId) {
        require(
            msg.sender == allProposalData[_proposalId].owner,
            "Not allowed"
        );
        _;
    }

    /**
     * @dev Checks if proposal is opened for voting
     */
    modifier voteNotStarted(uint256 _proposalId) {
        require(
            allProposalData[_proposalId].propStatus <
                uint256(ProposalStatus.VotingStarted)
        );
        _;
    }

    /**
     * @dev Checks if msg.sender is allowed to create proposal under given category
     */
    modifier isAllowed(uint256 _categoryId) {
        require(allowedToCreateProposal(_categoryId), "Not allowed");
        _;
    }

    /**
     * @dev Checks if msg.sender is allowed categorize proposal
     */
    modifier isAllowedToCategorize() {
        require(allowedToCategorize());
        _;
    }

    /**
     * @dev Event emitted whenever a proposal is categorized
     */
    event ProposalCategorized(
        uint256 indexed proposalId,
        address indexed categorizedBy,
        uint256 categoryId
    );

    /**
     * @dev Creates a new proposal
     * @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
     * @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
     */
    function createProposal(
        string calldata _proposalTitle,
        string calldata _proposalSD,
        string calldata _proposalDescHash,
        uint256 _categoryId
    ) external isAllowed(_categoryId) {
        require(
            memberRole.checkRole(
                msg.sender,
                uint256(IMemberRoles.Role.TokenHolder)
            ),
            "Not Member"
        );

        _createProposal(
            _proposalTitle,
            _proposalSD,
            _proposalDescHash,
            _categoryId
        );
    }

    /**
     * @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
     */
    function categorizeProposal(
        uint256 _proposalId,
        uint256 _categoryId,
        uint256 _incentive
    ) external voteNotStarted(_proposalId) isAllowedToCategorize {
        uint256 incentive = _incentive;
        bytes memory _functionHash = proposalCategory
            .categoryActionHashes(_categoryId);
        if(keccak256(_functionHash) == swapABMemberHash) {
            incentive = 0;
        }
        _categorizeProposal(_proposalId, _categoryId, incentive, _functionHash);
    }

    /**
     * @dev Submit proposal with solution
     * @param _proposalId Proposal id
     * @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
     */
    function submitProposalWithSolution(
        uint256 _proposalId,
        string calldata _solutionHash,
        bytes calldata _action
    ) external onlyProposalOwner(_proposalId) {
        require(
            allProposalData[_proposalId].propStatus ==
                uint256(ProposalStatus.AwaitingSolution)
        );

        _proposalSubmission(_proposalId, _solutionHash, _action);
    }

    /**
     * @dev Creates a new proposal with solution
     * @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
     * @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
     * @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
     */
    function createProposalwithSolution(
        string calldata _proposalTitle,
        string calldata _proposalSD,
        string calldata _proposalDescHash,
        uint256 _categoryId,
        string calldata _solutionHash,
        bytes calldata _action
    ) external isAllowed(_categoryId) {
        uint256 proposalId = totalProposals;

        _createProposal(
            _proposalTitle,
            _proposalSD,
            _proposalDescHash,
            _categoryId
        );

        require(_categoryId > 0);

        _proposalSubmission(proposalId, _solutionHash, _action);
    }

    /**
     * @dev Submit a vote on the proposal.
     * @param _proposalId to vote upon.
     * @param _solutionChosen is the chosen vote.
     */
    function submitVote(uint256 _proposalId, uint256 _solutionChosen) external {
        require(
            allProposalData[_proposalId].propStatus ==
                uint256(Governance.ProposalStatus.VotingStarted),
            "Not allowed"
        );

        require(_solutionChosen < allProposalSolutions[_proposalId].length);

        _submitVote(_proposalId, _solutionChosen);
    }

    /**
     * @dev Closes the proposal.
     * @param _proposalId of proposal to be closed.
     */
    function closeProposal(uint256 _proposalId) external {
        uint256 category = allProposalData[_proposalId].category;

        if (
            allProposalData[_proposalId].dateUpd.add(maxDraftTime) <= now &&
            allProposalData[_proposalId].propStatus <
            uint256(ProposalStatus.VotingStarted)
        ) {
            _updateProposalStatus(_proposalId, uint256(ProposalStatus.Denied));
            _transferPLOT(
                address(marketRegistry),
                allProposalData[_proposalId].commonIncentive
            );
        } else {
            require(canCloseProposal(_proposalId) == 1);
            _closeVote(_proposalId, category);
        }
    }

    /**
     * @dev Claims reward for member.
     * @param _memberAddress to claim reward of.
     * @param _maxRecords maximum number of records to claim reward for.
     _proposals list of proposals of which reward will be claimed.
     * @return amount of pending reward.
     */
    function claimReward(address _memberAddress, uint256 _maxRecords)
        external
        returns (uint256 pendingDAppReward)
    {
        uint256 voteId;
        uint256 proposalId;
        uint256 totalVotes = allVotesByMember[_memberAddress].length;
        uint256 lastClaimed = totalVotes;
        uint256 j;
        uint256 i;
        for (
            i = lastRewardClaimed[_memberAddress];
            i < totalVotes && j < _maxRecords;
            i++
        ) {
            voteId = allVotesByMember[_memberAddress][i];
            proposalId = allVotes[voteId].proposalId;
            if (
                proposalVoteTally[proposalId].voters > 0 && allProposalData[proposalId].propStatus >
                    uint256(ProposalStatus.VotingStarted)
            ) {                    
                if (!rewardClaimed[voteId][_memberAddress]) {
                    pendingDAppReward = pendingDAppReward.add(
                        allProposalData[proposalId].commonIncentive.div(
                            proposalVoteTally[proposalId].voters
                        )
                    );
                    rewardClaimed[voteId][_memberAddress] = true;
                    j++;
                }
            } else {
                if (lastClaimed == totalVotes) {
                    lastClaimed = i;
                }
            }
        }

        if (lastClaimed == totalVotes) {
            lastRewardClaimed[_memberAddress] = i;
        } else {
            lastRewardClaimed[_memberAddress] = lastClaimed;
        }

        if (j > 0) {
            _transferPLOT(
                _memberAddress,
                pendingDAppReward
            );
            emit RewardClaimed(_memberAddress, pendingDAppReward);
        }
    }

    /**
     * @dev Triggers action of accepted proposal after waiting time is finished
     */
    function triggerAction(uint256 _proposalId) external {
        require(
            proposalActionStatus[_proposalId] ==
                uint256(ActionStatus.Accepted) &&
                proposalExecutionTime[_proposalId] <= now,
            "Cannot trigger"
        );
        _triggerAction(_proposalId, allProposalData[_proposalId].category);
    }

    /**
     * @dev Provides option to Advisory board member to reject proposal action execution within actionWaitingTime, if found suspicious
     */
    function rejectAction(uint256 _proposalId) external {
        require(
            memberRole.checkRole(msg.sender, actionRejectAuthRole) &&
                proposalExecutionTime[_proposalId] > now
        );

        require(
            proposalActionStatus[_proposalId] == uint256(ActionStatus.Accepted)
        );

        require(!isActionRejected[_proposalId][msg.sender]);

        isActionRejected[_proposalId][msg.sender] = true;
        actionRejectedCount[_proposalId]++;
        emit ActionRejected(_proposalId, msg.sender);
        if (
            actionRejectedCount[_proposalId].mul(100).div(
                memberRole.numberOfMembers(actionRejectAuthRole)
            ) >= votePercRejectAction
        ) {
            proposalActionStatus[_proposalId] = uint256(ActionStatus.Rejected);
        }
    }

    /**
     * @dev Gets Uint Parameters of a code
     * @param code whose details we want
     * @return string value of the code
     * @return associated amount (time or perc or value) to the code
     */
    function getUintParameters(bytes8 code)
        external
        view
        returns (bytes8 codeVal, uint256 val)
    {
        codeVal = code;

        if (code == "GOVHOLD") { // Governance token holding time
            val = tokenHoldingTime / (1 days);
        } else if (code == "MAXDRFT") { // Maximum draft time for proposals
            val = maxDraftTime / (1 days);
        } else if (code == "ACWT") { //Action wait time
            val = actionWaitingTime / (1 hours);
        } else if (code == "REJAUTH") { // Authorized role to stop executing actions
            val = actionRejectAuthRole;
        } else if (code == "REJCOUNT") { // Majorty percentage for action rejection
            val = votePercRejectAction;
        } else if (code == "MAXVW") { // Max vote weight percentage
            val = maxVoteWeigthPer;
        } else if (code == "ABMAJ") { // Advisory board majority percentage
            val = advisoryBoardMajority;
        } else if (code == "DRQUMR") { // Dispute Resolution Quorum multiplier
            val = drQuorumMulitplier;
        }
    }

    /**
     * @dev Gets all details of a propsal
     * @param _proposalId whose details we want
     * @return proposalId
     * @return category
     * @return status
     * @return finalVerdict
     * @return totalReward
     */
    function proposal(uint256 _proposalId)
        external
        view
        returns (
            uint256 proposalId,
            uint256 category,
            uint256 status,
            uint256 finalVerdict,
            uint256 totalRewar
        )
    {
        return (
            _proposalId,
            allProposalData[_proposalId].category,
            allProposalData[_proposalId].propStatus,
            allProposalData[_proposalId].finalVerdict,
            allProposalData[_proposalId].commonIncentive
        );
    }

    /**
     * @dev Gets some details of a propsal
     * @param _proposalId whose details we want
     * @return proposalId
     * @return number of all proposal solutions
     * @return amount of votes
     */
    function proposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _proposalId,
            allProposalSolutions[_proposalId].length,
            proposalVoteTally[_proposalId].voters
        );
    }

    /**
     * @dev Gets solution action on a proposal
     * @param _proposalId whose details we want
     * @param _solution whose details we want
     * @return action of a solution on a proposal
     */
    function getSolutionAction(uint256 _proposalId, uint256 _solution)
        external
        view
        returns (uint256, bytes memory)
    {
        return (_solution, allProposalSolutions[_proposalId][_solution]);
    }

    /**
     * @dev Gets length of propsal
     * @return length of propsal
     */
    function getProposalLength() external view returns (uint256) {
        return totalProposals;
    }

    /**
     * @dev Gets pending rewards of a member
     * @param _memberAddress in concern
     * @return amount of pending reward
     */
    function getPendingReward(address _memberAddress)
        public
        view
        returns (uint256 pendingDAppReward)
    {
        uint256 proposalId;
        for (
            uint256 i = lastRewardClaimed[_memberAddress];
            i < allVotesByMember[_memberAddress].length;
            i++
        ) {
            if (
                !rewardClaimed[allVotesByMember[_memberAddress][i]][_memberAddress]
            ) {
                proposalId = allVotes[allVotesByMember[_memberAddress][i]]
                    .proposalId;
                if (
                    proposalVoteTally[proposalId].voters > 0 &&
                    allProposalData[proposalId].propStatus >
                    uint256(ProposalStatus.VotingStarted)
                ) {
                    pendingDAppReward = pendingDAppReward.add(
                        allProposalData[proposalId].commonIncentive.div(
                            proposalVoteTally[proposalId].voters
                        )
                    );
                }
            }
        }
    }

    /**
     * @dev Updates Uint Parameters of a code
     * @param code whose details we want to update
     * @param val value to set
     */
    function updateUintParameters(bytes8 code, uint256 val) public {
        require(ms.isAuthorizedToGovern(msg.sender));
        if (code == "GOVHOLD") {
            tokenHoldingTime = val * 1 days;
        } else if (code == "MAXDRFT") {
            maxDraftTime = val * 1 days;
        } else if (code == "ACWT") {
            actionWaitingTime = val * 1 hours;
        } else if (code == "REJAUTH") {
            actionRejectAuthRole = val;
        } else if (code == "REJCOUNT") {
            votePercRejectAction = val;
        } else if (code == "MAXVW") {
            maxVoteWeigthPer = val;
        } else if (code == "ABMAJ") {
            advisoryBoardMajority = val;
        } else if (code == "DRQUMR") {
            drQuorumMulitplier = val;
        } else {
            revert("Invalid code");
        }
    }

    /**
     * @dev Updates all dependency addresses to latest ones from Master
     */
    function setMasterAddress() public {
        OwnedUpgradeabilityProxy proxy =  OwnedUpgradeabilityProxy(address(uint160(address(this))));
        require(msg.sender == proxy.proxyOwner(),"Sender is not proxy owner.");

        require(!constructorCheck);
        _initiateGovernance();
        ms = IMaster(msg.sender);
        tokenInstance = IToken(ms.dAppToken());
        memberRole = IMemberRoles(ms.getLatestAddress("MR"));
        proposalCategory = IProposalCategory(ms.getLatestAddress("PC"));
        tokenController = ITokenController(ms.getLatestAddress("TC"));
        marketRegistry = IMarketRegistry(address(uint160(ms.getLatestAddress("PL"))));
    }

    /**
     * @dev Checks if msg.sender is allowed to create a proposal under given category
     */
    function allowedToCreateProposal(uint256 category)
        public
        view
        returns (bool check)
    {
        if (category == 0) return true;
        uint256[] memory mrAllowed;
        (, , , , mrAllowed, , ) = proposalCategory.category(category);
        for (uint256 i = 0; i < mrAllowed.length; i++) {
            if (
                mrAllowed[i] == 0 ||
                memberRole.checkRole(msg.sender, mrAllowed[i])
            ) return true;
        }
    }

    /**
     * @dev Checks if msg.sender is allowed to categorize proposals
     */
    function allowedToCategorize()
        public
        view
        returns (bool check)
    {
        return memberRole.checkRole(msg.sender, roleIdAllowedToCatgorize);
    }

    /**
     * @dev Checks If the proposal voting time is up and it's ready to close
     *      i.e. Closevalue is 1 if proposal is ready to be closed, 2 if already closed, 0 otherwise!
     * @param _proposalId Proposal id to which closing value is being checked
     */
    function canCloseProposal(uint256 _proposalId)
        public
        view
        returns (uint256)
    {
        uint256 dateUpdate;
        uint256 pStatus;
        uint256 _closingTime;
        uint256 _roleId;
        uint256 majority;
        pStatus = allProposalData[_proposalId].propStatus;
        dateUpdate = allProposalData[_proposalId].dateUpd;
        (, _roleId, majority, , , _closingTime, ) = proposalCategory.category(
            allProposalData[_proposalId].category
        );
        if (pStatus == uint256(ProposalStatus.VotingStarted)) {
            uint256 numberOfMembers = memberRole.numberOfMembers(_roleId);
            if (
                _roleId == uint256(IMemberRoles.Role.AdvisoryBoard)
            ) {
                if (
                    proposalVoteTally[_proposalId].voteValue[1].mul(100).div(
                        numberOfMembers
                    ) >=
                    majority ||
                    proposalVoteTally[_proposalId].voteValue[1].add(
                        proposalVoteTally[_proposalId].voteValue[0]
                    ) ==
                    numberOfMembers ||
                    dateUpdate.add(_closingTime) <= now
                ) {
                    return 1;
                }
            } else {
                if(_roleId == uint256(IMemberRoles.Role.TokenHolder) ||
                _roleId == uint256(IMemberRoles.Role.DisputeResolution)) {
                    if(dateUpdate.add(_closingTime) <= now)
                        return 1;
                } else if (
                    numberOfMembers <= proposalVoteTally[_proposalId].voters ||
                    dateUpdate.add(_closingTime) <= now
                ) return 1;
            }
        } else if (pStatus > uint256(ProposalStatus.VotingStarted)) {
            return 2;
        } else {
            return 0;
        }
    }

    /**
     * @dev Gets Id of member role allowed to categorize the proposal
     * @return roleId allowed to categorize the proposal
     */
    function allowedToCatgorize() public view returns (uint256 roleId) {
        return roleIdAllowedToCatgorize;
    }

    /**
     * @dev Gets vote tally data
     * @param _proposalId in concern
     * @param _solution of a proposal id
     * @return member vote value
     * @return advisory board vote value
     * @return amount of votes
     */
    function voteTallyData(uint256 _proposalId, uint256 _solution)
        public
        view
        returns (uint256, uint256, uint256)
    {
        return (
            proposalVoteTally[_proposalId].voteValue[_solution],
            proposalVoteTally[_proposalId].abVoteValue[_solution],
            proposalVoteTally[_proposalId].voters
        );
    }

    /**
     * @dev Internal call to create proposal
     * @param _proposalTitle of proposal
     * @param _proposalSD is short description of proposal
     * @param _proposalDescHash IPFS hash value of propsal
     * @param _categoryId of proposal
     */
    function _createProposal(
        string memory _proposalTitle,
        string memory _proposalSD,
        string memory _proposalDescHash,
        uint256 _categoryId
    ) internal {
        uint256 _proposalId = totalProposals;
        allProposalData[_proposalId].owner = msg.sender;
        allProposalData[_proposalId].dateUpd = now;
        allProposalSolutions[_proposalId].push("");
        totalProposals++;

        emit Proposal(
            msg.sender,
            _proposalId,
            now,
            _proposalTitle,
            _proposalSD,
            _proposalDescHash
        );

        if (_categoryId > 0) {
            (, , , uint defaultIncentive, bytes memory _functionHash) = proposalCategory
            .categoryActionDetails(_categoryId);
            require(allowedToCategorize() ||
                keccak256(_functionHash) ==
                 resolveDisputeHash ||
                keccak256(_functionHash) == swapABMemberHash
            );
            if(keccak256(_functionHash) == swapABMemberHash) {
                defaultIncentive = 0;
            }
            _categorizeProposal(_proposalId, _categoryId, defaultIncentive, _functionHash);
        }
    }

    /**
     * @dev Internal call to categorize a proposal
     * @param _proposalId of proposal
     * @param _categoryId of proposal
     * @param _incentive is commonIncentive
     */
    function _categorizeProposal(
        uint256 _proposalId,
        uint256 _categoryId,
        uint256 _incentive,
        bytes memory _functionHash
    ) internal {
        require(
            _categoryId > 0 && _categoryId < proposalCategory.totalCategories(),
            "Invalid category"
        );
        if(keccak256(_functionHash) == resolveDisputeHash) {
            require(msg.sender == address(marketRegistry));
        }
        allProposalData[_proposalId].category = _categoryId;
        allProposalData[_proposalId].commonIncentive = _incentive;
        allProposalData[_proposalId].propStatus = uint256(
            ProposalStatus.AwaitingSolution
        );

        if (_incentive > 0) {
            marketRegistry.transferAssets(
                address(tokenInstance),
                address(this),
                _incentive
            );
        }

        emit ProposalCategorized(_proposalId, msg.sender, _categoryId);
    }

    /**
     * @dev Internal call to add solution to a proposal
     * @param _proposalId in concern
     * @param _action on that solution
     * @param _solutionHash string value
     */
    function _addSolution(
        uint256 _proposalId,
        bytes memory _action,
        string memory _solutionHash
    ) internal {
        allProposalSolutions[_proposalId].push(_action);
        emit Solution(
            _proposalId,
            msg.sender,
            allProposalSolutions[_proposalId].length.sub(1),
            _solutionHash,
            now
        );
    }

    /**
     * @dev Internal call to add solution and open proposal for voting
     */
    function _proposalSubmission(
        uint256 _proposalId,
        string memory _solutionHash,
        bytes memory _action
    ) internal {
        uint256 _categoryId = allProposalData[_proposalId].category;
        if (proposalCategory.categoryActionHashes(_categoryId).length == 0) {
            require(keccak256(_action) == keccak256(""));
            proposalActionStatus[_proposalId] = uint256(ActionStatus.NoAction);
        }

        _addSolution(_proposalId, _action, _solutionHash);

        _updateProposalStatus(
            _proposalId,
            uint256(ProposalStatus.VotingStarted)
        );
        (, , , , , uint256 closingTime, ) = proposalCategory.category(
            _categoryId
        );
        emit CloseProposalOnTime(_proposalId, closingTime.add(now));
    }

    /**
     * @dev Internal call to submit vote
     * @param _proposalId of proposal in concern
     * @param _solution for that proposal
     */
    function _submitVote(uint256 _proposalId, uint256 _solution) internal {
        uint256 mrSequence;
        uint256 majority;
        uint256 closingTime;
        (, mrSequence, majority, , , closingTime, ) = proposalCategory.category(
            allProposalData[_proposalId].category
        );

        require(
            allProposalData[_proposalId].dateUpd.add(closingTime) > now,
            "Closed"
        );

        require(
            memberProposalVote[msg.sender][_proposalId] == 0,
            "Not allowed"
        );

        require(memberRole.checkRole(msg.sender, mrSequence), "Not Authorized");
        uint256 totalVotes = allVotes.length;

        allVotesByMember[msg.sender].push(totalVotes);
        memberProposalVote[msg.sender][_proposalId] = totalVotes;
        tokenController.lockForGovernanceVote(msg.sender, tokenHoldingTime);

        emit Vote(msg.sender, _proposalId, totalVotes, now, _solution);
        uint256 numberOfMembers = memberRole.numberOfMembers(mrSequence);
        _setVoteTally(_proposalId, _solution, mrSequence);

        if (
            numberOfMembers == proposalVoteTally[_proposalId].voters &&
            mrSequence != uint256(IMemberRoles.Role.TokenHolder)
        ) {
            emit VoteCast(_proposalId);
        }
    }

    function _setVoteTally(
        uint256 _proposalId,
        uint256 _solution,
        uint256 mrSequence
    ) internal {
        uint256 voters = 1;
        uint256 voteWeight;
        uint256 tokenBalance = tokenController.totalBalanceOf(msg.sender);
        uint totalSupply = tokenController.totalSupply();
        if (mrSequence != uint(IMemberRoles.Role.AdvisoryBoard) &&
        memberRole.checkRole(msg.sender, uint(IMemberRoles.Role.AdvisoryBoard))
        )
         {
            proposalVoteTally[_proposalId].abVoteValue[_solution]++;
        }
        if (
            mrSequence == uint256(IMemberRoles.Role.TokenHolder)
        ) {
            voteWeight = _minOf(tokenBalance, maxVoteWeigthPer.mul(totalSupply).div(100));
        } else if (
            mrSequence == uint256(IMemberRoles.Role.DisputeResolution)
        ) {
            voteWeight = tokenController.tokensLockedAtTime(msg.sender, "DR", now);
        } else {
            voteWeight = 1;
        }
        allVotes.push(
            ProposalVote(msg.sender, _proposalId, _solution, tokenBalance, now)
        );
        allProposalData[_proposalId]
            .totalVoteValue = allProposalData[_proposalId].totalVoteValue.add(
            voteWeight
        );
        proposalVoteTally[_proposalId]
            .voteValue[_solution] = proposalVoteTally[_proposalId]
            .voteValue[_solution]
            .add(voteWeight);
        proposalVoteTally[_proposalId].voters =
            proposalVoteTally[_proposalId].voters.add(voters);
    }

    /**
     * @dev Gets minimum of two numbers
     * @param a one of the two numbers
     * @param b one of the two numbers
     * @return minimum number out of the two
     */
    function _minOf(uint a, uint b) internal pure returns(uint res) {
        res = a;
        if (res > b)
            res = b;
    }

    /**
     * @dev Checks if the vote count against any solution passes the threshold value or not.
     */
    function _checkForThreshold(uint256 _proposalId, uint256 _category)
        internal
        view
        returns (bool check)
    {
        uint256 categoryQuorumPerc;
        uint256 roleAuthorized;
        (, roleAuthorized, , categoryQuorumPerc, , , ) = proposalCategory
            .category(_category);
        if (roleAuthorized == uint256(IMemberRoles.Role.TokenHolder)) {
            check =
                (allProposalData[_proposalId].totalVoteValue).mul(100).div(
                    tokenController.totalSupply()
                ) >=
                categoryQuorumPerc;
        } else if (roleAuthorized == uint256(IMemberRoles.Role.DisputeResolution)) {
            (address marketAddress, ) = abi.decode(allProposalSolutions[_proposalId][1], (address, uint256));
            uint256 totalStakeValueInPlot = IMarket(marketAddress).getTotalStakedValueInPLOT();
            if(allProposalData[_proposalId].totalVoteValue > 0) {
                check =
                    (allProposalData[_proposalId].totalVoteValue) >=
                    (_minOf(totalStakeValueInPlot.mul(drQuorumMulitplier), (tokenController.totalSupply()).mul(100).div(totalSupplyCapForDRQrm)));
            } else {
                check = false;
            }
        } else {
            check =
                (proposalVoteTally[_proposalId].voters).mul(100).div(
                    memberRole.numberOfMembers(roleAuthorized)
                ) >=
                categoryQuorumPerc;
        }
    }

    /**
     * @dev Called when vote majority is reached
     * @param _proposalId of proposal in concern
     * @param _status of proposal in concern
     * @param category of proposal in concern
     * @param max vote value of proposal in concern
     */
    function _callIfMajReached(
        uint256 _proposalId,
        uint256 _status,
        uint256 category,
        uint256 max,
        uint256 role
    ) internal {
        allProposalData[_proposalId].finalVerdict = max;
        _updateProposalStatus(_proposalId, _status);
        emit ProposalAccepted(_proposalId);
        if (
            proposalActionStatus[_proposalId] != uint256(ActionStatus.NoAction)
        ) {
            if (role == actionRejectAuthRole) {
                _triggerAction(_proposalId, category);
            } else {
                proposalActionStatus[_proposalId] = uint256(
                    ActionStatus.Accepted
                );
                bytes memory functionHash = proposalCategory.categoryActionHashes(category);
                if(keccak256(functionHash)
                    == swapABMemberHash ||
                    keccak256(functionHash)
                    == resolveDisputeHash 
                ) {
                    _triggerAction(_proposalId, category);
                } else {
                    proposalExecutionTime[_proposalId] = actionWaitingTime.add(now);
                }
            }
        }
    }

    /**
     * @dev Internal function to trigger action of accepted proposal
     */
    function _triggerAction(uint256 _proposalId, uint256 _categoryId) internal {
        proposalActionStatus[_proposalId] = uint256(ActionStatus.Executed);
        bytes2 contractName;
        address actionAddress;
        bytes memory _functionHash;
        (, actionAddress, contractName, , _functionHash) = proposalCategory
            .categoryActionDetails(_categoryId);
        if (contractName == "MS") {
            actionAddress = address(ms);
        } else if (contractName != "EX") {
            actionAddress = ms.getLatestAddress(contractName);
        }
        (bool actionStatus, ) = actionAddress.call(
            abi.encodePacked(
                _functionHash,
                allProposalSolutions[_proposalId][1]
            )
        );
        if (actionStatus) {
            emit ActionSuccess(_proposalId);
        } else {
            proposalActionStatus[_proposalId] = uint256(ActionStatus.Accepted);
            emit ActionFailed(_proposalId);
        }
    }

    /**
     * @dev Internal call to update proposal status
     * @param _proposalId of proposal in concern
     * @param _status of proposal to set
     */
    function _updateProposalStatus(uint256 _proposalId, uint256 _status)
        internal
    {
        if (
            _status == uint256(ProposalStatus.Rejected) ||
            _status == uint256(ProposalStatus.Denied)
        ) {
            proposalActionStatus[_proposalId] = uint256(ActionStatus.NoAction);
        }
        allProposalData[_proposalId].dateUpd = now;
        allProposalData[_proposalId].propStatus = _status;
    }

    /**
     * @dev Internal call to close member voting
     * @param _proposalId of proposal in concern
     * @param category of proposal in concern
     */
    function _closeVote(uint256 _proposalId, uint256 category) internal {
        uint256 majorityVote;
        uint256 mrSequence;
        (, mrSequence, majorityVote, , , , ) = proposalCategory.category(
            category
        );
        bytes memory _functionHash = proposalCategory.categoryActionHashes(category);
        if (_checkForThreshold(_proposalId, category)) {
            if (
                (
                    (
                        proposalVoteTally[_proposalId].voteValue[1]
                            .mul(100)
                    )
                        .div(allProposalData[_proposalId].totalVoteValue)
                ) >= majorityVote
            ) {
                _callIfMajReached(
                    _proposalId,
                    uint256(ProposalStatus.Accepted),
                    category,
                    1,
                    mrSequence
                );
            } else {
                _updateProposalStatus(
                    _proposalId,
                    uint256(ProposalStatus.Rejected)
                );
            }
        } else {
            if ((keccak256(_functionHash) != resolveDisputeHash) &&
             (mrSequence != uint(IMemberRoles.Role.AdvisoryBoard)) &&
             proposalVoteTally[_proposalId].abVoteValue[1].mul(100)
                .div(memberRole.numberOfMembers(uint(IMemberRoles.Role.AdvisoryBoard))) >= advisoryBoardMajority
            ) {
                _callIfMajReached(
                    _proposalId,
                    uint256(ProposalStatus.Accepted),
                    category,
                    1,
                    mrSequence
                );
            } else {
                _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
            }
        }
        if(allProposalData[_proposalId].propStatus > uint256(ProposalStatus.Accepted)) {
            if(keccak256(_functionHash) == resolveDisputeHash) {
                marketRegistry.burnDisputedProposalTokens(_proposalId);
            }
        }

        if (proposalVoteTally[_proposalId].voters == 0 && allProposalData[_proposalId].commonIncentive > 0) {
            _transferPLOT(
                address(marketRegistry),
                allProposalData[_proposalId].commonIncentive
            );
        }
    }

    function _transferPLOT(address _recipient, uint256 _amount) internal {
        if(_amount > 0) {
            tokenInstance.transfer(
                _recipient,
                _amount
            );
        }
    }

    /**
     * @dev to initiate the governance process
     */
    function _initiateGovernance() internal {
        allVotes.push(ProposalVote(address(0), 0, 0, 0, 0));
        totalProposals = 1;
        tokenHoldingTime = 1 * 3 days;
        constructorCheck = true;
        roleIdAllowedToCatgorize = uint256(IMemberRoles.Role.AdvisoryBoard);
        actionWaitingTime = 1 days;
        actionRejectAuthRole = uint256(IMemberRoles.Role.AdvisoryBoard);
        votePercRejectAction = 60;
        maxVoteWeigthPer = 5;
        advisoryBoardMajority = 60;
        drQuorumMulitplier = 5;
    }

}