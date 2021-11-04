// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "../interfaces/ICoreVoting.sol";
import "../interfaces/IVotingVault.sol";
import "../libraries/Authorizable.sol";

// This vault allows someone to gain one vote on the GSC and tracks that status through time
// it will be a voting vault of the gsc voting contract
// It is not going to be an upgradable proxy since only a few users use it and it doesn't have
// high migration overhead. It also won't have full historical tracking which will cause
// GSC votes to behave differently than others. Namely, anyone who is a member at any point
// in the voting period can vote.

contract GSCVault is Authorizable, IVotingVault {
    // Tracks which people are in the GSC, which vaults they use and when they became members
    mapping(address => Member) public members;
    // The core voting contract with approved voting vaults
    ICoreVoting public coreVoting;
    // The amount of votes needed to be on the GSC
    uint256 public votingPowerBound;
    // The duration during which a fresh gsc member cannot vote.
    uint256 public idleDuration = 4 days;

    // Event to help tracking members
    event MembershipProved(address indexed who, uint256 when);
    // Event to help tracking kicks
    event Kicked(address indexed who, uint256 when);

    struct Member {
        // vaults used by the member to gain membership
        address[] vaults;
        // timestamp when the member joined
        uint256 joined;
    }

    /// @notice constructs this contract and initial vars
    /// @param _coreVoting The core voting contract
    /// @param _votingPowerBound The first voting power bound
    /// @param _owner The owner of this contract, should be the timelock contract
    constructor(
        ICoreVoting _coreVoting,
        uint256 _votingPowerBound,
        address _owner
    ) {
        // Set the state variables
        coreVoting = _coreVoting;
        votingPowerBound = _votingPowerBound;
        // Set the owner
        setOwner(address(_owner));
    }

    /// @notice Called to prove membership in the GSC
    /// @param votingVaults The contracts this person has their voting power in
    /// @param extraData Extra data given to the vaults to help calculation
    function proveMembership(
        address[] calldata votingVaults,
        bytes[] calldata extraData
    ) external {
        // Check for call validity
        assert(votingVaults.length > 0);
        // We loop through the voting vaults to check they are authorized
        // We check all up front to prevent any reentrancy or weird side effects
        for (uint256 i = 0; i < votingVaults.length; i++) {
            // No repeated vaults in the list
            for (uint256 j = i + 1; j < votingVaults.length; j++) {
                require(votingVaults[i] != votingVaults[j], "duplicate vault");
            }
            // Call the mapping the core voting contract to check that
            // the provided address is in fact approved.
            // Note - Post Berlin hardfork this repeated access is quite cheap.
            bool vaultStatus = coreVoting.approvedVaults(votingVaults[i]);
            require(vaultStatus, "Voting vault not approved");
        }
        // Now we tally the caller's voting power
        uint256 totalVotes = 0;
        // Parse through the list of vaults
        for (uint256 i = 0; i < votingVaults.length; i++) {
            // Call the vault to check last block's voting power
            // Last block to ensure there's no flash loan or other
            // intra contract interaction
            uint256 votes =
                IVotingVault(votingVaults[i]).queryVotePower(
                    msg.sender,
                    block.number - 1,
                    extraData[i]
                );
            // Add up the votes
            totalVotes += votes;
        }
        // Require that the caller has proven that they have enough votes
        require(totalVotes >= votingPowerBound, "Not enough votes");
        // if the caller has already provedMembership, update their votingPower without
        // resetting their idle duration.
        if (members[msg.sender].joined != 0) {
            members[msg.sender].vaults = votingVaults;
        } else {
            members[msg.sender] = Member(votingVaults, block.timestamp);
        }
        // Emit the event tracking this
        emit MembershipProved(msg.sender, block.timestamp);
    }

    /// @notice Removes a GSC member who's registered vaults no longer contain enough votes
    /// @param who The address to challenge.
    /// @param extraData the extra data the vaults need to load the user's voting power
    /// @dev NOTE - Because the bytes extra data must be supplied by the kicker vaults must
    ///             revert if not provided correct extra data [ie merkle proof for total power]
    ///             or they cannot be relied upon to maintain status in the GSC.
    function kick(address who, bytes[] calldata extraData) external {
        // Load the vaults into memory
        address[] memory votingVaults = members[who].vaults;
        // We verify that they have lost sufficient voting power to be kicked
        uint256 totalVotes = 0;
        // Parse through the list of vaults
        for (uint256 i = 0; i < votingVaults.length; i++) {
            // If the vault is not approved we don't count its votes now
            if (coreVoting.approvedVaults(votingVaults[i])) {
                // Call the vault to check last block's voting power
                // Last block to ensure there's no flash loan or other
                // intra contract interaction
                uint256 votes =
                    IVotingVault(votingVaults[i]).queryVotePower(
                        who,
                        block.number - 1,
                        extraData[i]
                    );
                // Add up the votes
                totalVotes += votes;
            }
        }
        // Only proceed if the member is currently kick-able
        require(totalVotes < votingPowerBound, "Not kick-able");
        // Delete the member
        delete members[who];
        // Emit a challenge event
        emit Kicked(who, block.number);
    }

    /// @notice Queries voting power, GSC members get one vote and the owner gets 100k
    /// @param who Which address to query
    /// @return Returns the votes of the queried address
    /// @dev Because this function ignores the when variable it creates a unique voting system
    ///      and should not be plugged in with truly historic ones.
    function queryVotePower(
        address who,
        uint256,
        bytes calldata
    ) public view override returns (uint256) {
        // If the address queried is the owner they get a huge number of votes
        // This allows the primary governance timelock to take any action the GSC
        // can make or block any action the GSC can make. But takes as many votes as
        // a protocol upgrade.
        if (who == owner) {
            return 100000;
        }
        // If the who has been in the GSC longer than idleDuration
        // return 1 and otherwise return 0.
        if (
            members[who].joined > 0 &&
            (members[who].joined + idleDuration) <= block.timestamp
        ) {
            return 1;
        } else {
            return 0;
        }
    }

    /// @notice Queries user voting vaults used to gain membership.
    /// @param who Which address to query
    function getUserVaults(address who) public view returns (address[] memory) {
        return members[who].vaults;
    }

    /// Functions to allow gov to reset the state vars

    /// @notice Sets the core voting contract
    /// @param _newVoting The new core voting contract
    function setCoreVoting(ICoreVoting _newVoting) external onlyOwner() {
        coreVoting = _newVoting;
    }

    /// @notice Sets the vote power bound
    /// @param _newBound The new vote power bound
    function setVotePowerBound(uint256 _newBound) external onlyOwner() {
        votingPowerBound = _newBound;
    }

    /// @notice Sets the duration during which new gsc members remain unable to vote
    /// @param _idleDuration The duration in seconds.
    function setIdleDuration(uint256 _idleDuration) external onlyOwner() {
        idleDuration = _idleDuration;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

interface ICoreVoting {
    /// @notice A method auto generated from a public storage mapping, looks
    ///         up which vault addresses are approved by core voting
    /// @param vault the address to check if it is an approved vault
    /// @return true if approved false if not approved
    function approvedVaults(address vault) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

interface IVotingVault {
    /// @notice Attempts to load the voting power of a user
    /// @param user The address we want to load the voting power of
    /// @param blockNumber the block number we want the user's voting power at
    /// @param extraData Abi encoded optional extra data used by some vaults, such as merkle proofs
    /// @return the number of votes
    function queryVotePower(
        address user,
        uint256 blockNumber,
        bytes calldata extraData
    ) external returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0;

contract Authorizable {
    // This contract allows a flexible authorization scheme

    // The owner who can change authorization status
    address public owner;
    // A mapping from an address to its authorization status
    mapping(address => bool) public authorized;

    /// @dev We set the deployer to the owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev This modifier checks if the msg.sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Sender not Authorized");
        _;
    }

    /// @dev Returns true if an address is authorized
    /// @param who the address to check
    /// @return true if authorized false if not
    function isAuthorized(address who) public view returns (bool) {
        return authorized[who];
    }

    /// @dev Privileged function authorize an address
    /// @param who the address to authorize
    function authorize(address who) external onlyOwner() {
        _authorize(who);
    }

    /// @dev Privileged function to de authorize an address
    /// @param who The address to remove authorization from
    function deauthorize(address who) external onlyOwner() {
        authorized[who] = false;
    }

    /// @dev Function to change owner
    /// @param who The new owner address
    function setOwner(address who) public onlyOwner() {
        owner = who;
    }

    /// @dev Inheritable function which authorizes someone
    /// @param who the address to authorize
    function _authorize(address who) internal {
        authorized[who] = true;
    }
}