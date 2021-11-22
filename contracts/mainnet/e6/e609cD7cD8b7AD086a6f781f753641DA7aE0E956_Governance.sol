// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title Manages address permissions to act on Macabris contracts
 */
contract Governance {

    enum Actions { Vote, Configure, SetOwnerAddress, TriggerOwnerWithdraw, ManageDeaths, StopPayouts, Bootstrap }

    // Stores permissions of an address
    struct Permissions {
        bool canVote;
        bool canConfigure;
        bool canSetOwnerAddress;
        bool canTriggerOwnerWithdraw;
        bool canManageDeaths;
        bool canStopPayouts;

        // Special permission that can't be voted in and only the deploying address receives
        bool canBootstrap;
    }

    // A call for vote to change address permissions
    struct CallForVote {

        // Address that will be assigned the permissions if the vote passes
        address subject;

        // Permissions to be assigned if the vote passes
        Permissions permissions;

        // Total number of votes for and against the permission change
        uint128 yeas;
        uint128 nays;
    }

    // A vote in a call for vote
    struct Vote {
        uint64 callForVoteIndex;
        bool yeaOrNay;
    }

    // Permissions of addresses
    mapping(address => Permissions) private permissions;

    // List of calls for a vote: callForVoteIndex => CallForVote, callForVoteIndex starts from 1
    mapping(uint => CallForVote) private callsForVote;

    // Last registered call for vote of every address: address => callForVoteIndex
    mapping(address => uint64) private lastRegisteredCallForVote;

    // Votes of every address: address => Vote
    mapping(address => Vote) private votes;

    uint64 public resolvedCallsForVote;
    uint64 public totalCallsForVote;
    uint64 public totalVoters;

    /**
     * @dev Emitted when a new call for vote is registered
     * @param callForVoteIndex Index of the call for vote (1-based)
     * @param subject Subject address to change permissions to if vote passes
     * @param canVote Allow subject address to vote
     * @param canConfigure Allow subject address to configure prices, fees and base URI
     * @param canSetOwnerAddress Allows subject to change owner withdraw address
     * @param canTriggerOwnerWithdraw Allow subject address to trigger withdraw from owner's balance
     * @param canManageDeaths Allow subject to set tokens as dead or alive
     * @param canStopPayouts Allow subject to stop the bank payout schedule early
     */
    event CallForVoteRegistered(
        uint64 indexed callForVoteIndex,
        address indexed caller,
        address indexed subject,
        bool canVote,
        bool canConfigure,
        bool canSetOwnerAddress,
        bool canTriggerOwnerWithdraw,
        bool canManageDeaths,
        bool canStopPayouts
    );

    /**
     * @dev Emitted when a call for vote is resolved
     * @param callForVoteIndex Index of the call for vote (1-based)
     * @param yeas Total yeas for the call after the vote
     * @param nays Total nays for the call after the vote
     */
    event CallForVoteResolved(
        uint64 indexed callForVoteIndex,
        uint128 yeas,
        uint128 nays
    );

    /**
     * @dev Emitted when a vote is casted
     * @param callForVoteIndex Index of the call for vote (1-based)
     * @param voter Voter address
     * @param yeaOrNay Vote, true if yea, false if nay
     * @param totalVoters Total addresses with vote permission at the time of event
     * @param yeas Total yeas for the call after the vote
     * @param nays Total nays for the call after the vote
     */
    event VoteCasted(
        uint64 indexed callForVoteIndex,
        address indexed voter,
        bool yeaOrNay,
        uint64 totalVoters,
        uint128 yeas,
        uint128 nays
    );

    /**
     * @dev Inits the contract and gives the deployer address all permissions
     */
    constructor() {
        _setPermissions(msg.sender, Permissions({
            canVote: true,
            canConfigure: true,
            canSetOwnerAddress: true,
            canTriggerOwnerWithdraw: true,
            canManageDeaths: true,
            canStopPayouts: true,
            canBootstrap: true
        }));
    }

    /**
     * @dev Checks if the given address has permission to perform given action
     * @param subject Address to check
     * @param action Action to check permissions against
     * @return True if given address has permission to perform given action
     */
    function hasPermission(address subject, Actions action) public view returns (bool) {
        if (action == Actions.ManageDeaths) {
            return permissions[subject].canManageDeaths;
        }

        if (action == Actions.Vote) {
            return permissions[subject].canVote;
        }

        if (action == Actions.SetOwnerAddress) {
            return permissions[subject].canSetOwnerAddress;
        }

        if (action == Actions.TriggerOwnerWithdraw) {
            return permissions[subject].canTriggerOwnerWithdraw;
        }

        if (action == Actions.Configure) {
            return permissions[subject].canConfigure;
        }

        if (action == Actions.StopPayouts) {
            return permissions[subject].canStopPayouts;
        }

        if (action == Actions.Bootstrap) {
            return permissions[subject].canBootstrap;
        }

        return false;
    }

    /**
     * Sets permissions for a given address
     * @param subject Subject address to set permissions to
     * @param _permissions Permissions
     */
    function _setPermissions(address subject, Permissions memory _permissions) private {

        // Tracks count of total voting addresses to be able to calculate majority
        if (permissions[subject].canVote != _permissions.canVote) {
            if (_permissions.canVote) {
                totalVoters += 1;
            } else {
                totalVoters -= 1;

                // Cleaning up voting-related state for the address
                delete votes[subject];
                delete lastRegisteredCallForVote[subject];
            }
        }

        permissions[subject] = _permissions;
    }

    /**
     * @dev Registers a new call for vote to change address permissions
     * @param subject Subject address to change permissions to if vote passes
     * @param canVote Allow subject address to vote
     * @param canConfigure Allow subject address to configure prices, fees and base URI
     * @param canSetOwnerAddress Allows subject to change owner withdraw address
     * @param canTriggerOwnerWithdraw Allow subject address to trigger withdraw from owner's balance
     * @param canManageDeaths Allow subject to set tokens as dead or alive
     * @param canStopPayouts Allow subject to stop the bank payout schedule early
     *
     * Requirements:
     * - the caller must have the vote permission
     * - the caller shouldn't have any unresolved calls for vote
     */
    function callForVote(
        address subject,
        bool canVote,
        bool canConfigure,
        bool canSetOwnerAddress,
        bool canTriggerOwnerWithdraw,
        bool canManageDeaths,
        bool canStopPayouts
    ) external {
        require(
            hasPermission(msg.sender, Actions.Vote),
            "Only addresses with vote permission can register a call for vote"
        );

        // If the sender has previously created a call for vote that hasn't been resolved yet,
        // a second call for vote can't be registered. Prevents a denial of service attack, where
        // a minority of voters could flood the call for vote queue.
        require(
            lastRegisteredCallForVote[msg.sender] <= resolvedCallsForVote,
            "Only one active call for vote per address is allowed"
        );

        totalCallsForVote++;

        lastRegisteredCallForVote[msg.sender] = totalCallsForVote;

        callsForVote[totalCallsForVote] = CallForVote({
            subject: subject,
            permissions: Permissions({
                canVote: canVote,
                canConfigure: canConfigure,
                canSetOwnerAddress: canSetOwnerAddress,
                canTriggerOwnerWithdraw: canTriggerOwnerWithdraw,
                canManageDeaths: canManageDeaths,
                canStopPayouts: canStopPayouts,
                canBootstrap: false
            }),
            yeas: 0,
            nays: 0
        });

        emit CallForVoteRegistered(
            totalCallsForVote,
            msg.sender,
            subject,
            canVote,
            canConfigure,
            canSetOwnerAddress,
            canTriggerOwnerWithdraw,
            canManageDeaths,
            canStopPayouts
        );
    }

    /**
     * @dev Registers a vote
     * @param callForVoteIndex Call for vote index
     * @param yeaOrNay True to vote yea, false to vote nay
     *
     * Requirements:
     * - unresolved call for vote must exist
     * - call for vote index must match the current active call for vote
     * - the caller must have the vote permission
     */
    function vote(uint64 callForVoteIndex, bool yeaOrNay) external {
        require(hasUnresolvedCallForVote(), "No unresolved call for vote exists");
        require(
            callForVoteIndex == _getCurrenCallForVoteIndex(),
            "Call for vote does not exist or is not active"
        );
        require(
            hasPermission(msg.sender, Actions.Vote),
            "Sender address does not have vote permission"
        );

        uint128 yeas = callsForVote[callForVoteIndex].yeas;
        uint128 nays = callsForVote[callForVoteIndex].nays;

        // If the voter has already voted in this call for vote, undo the last vote
        if (votes[msg.sender].callForVoteIndex == callForVoteIndex) {
            if (votes[msg.sender].yeaOrNay) {
                yeas -= 1;
            } else {
                nays -= 1;
            }
        }

        if (yeaOrNay) {
            yeas += 1;
        } else {
            nays += 1;
        }

        emit VoteCasted(callForVoteIndex, msg.sender, yeaOrNay, totalVoters, yeas, nays);

        if (yeas == (totalVoters / 2 + 1) || nays == (totalVoters - totalVoters / 2)) {

            if (yeas > nays) {
                _setPermissions(
                    callsForVote[callForVoteIndex].subject,
                    callsForVote[callForVoteIndex].permissions
                );
            }

            resolvedCallsForVote += 1;

            // Cleaning up what we can
            delete callsForVote[callForVoteIndex];
            delete votes[msg.sender];

            emit CallForVoteResolved(callForVoteIndex, yeas, nays);

            return;
        }

        votes[msg.sender] = Vote({
            callForVoteIndex: callForVoteIndex,
            yeaOrNay: yeaOrNay
        });

        callsForVote[callForVoteIndex].yeas = yeas;
        callsForVote[callForVoteIndex].nays = nays;
    }

    /**
     * @dev Returns information about the current unresolved call for vote
     * @return callForVoteIndex Call for vote index (1-based)
     * @return yeas Total yea votes
     * @return nays Total nay votes
     *
     * Requirements:
     * - Unresolved call for vote must exist
     */
    function getCurrentCallForVote() public view returns (
        uint64 callForVoteIndex,
        uint128 yeas,
        uint128 nays
    ) {
        require(hasUnresolvedCallForVote(), "No unresolved call for vote exists");
        uint64 index = _getCurrenCallForVoteIndex();
        return (index, callsForVote[index].yeas, callsForVote[index].nays);
    }

    /**
     * @dev Checks if there is an unresolved call for vote
     * @return True if an unresolved call for vote exists
     */
    function hasUnresolvedCallForVote() public view returns (bool) {
        return totalCallsForVote > resolvedCallsForVote;
    }

    /**
     * @dev Returns current call for vote index
     * @return Call for vote index (1-based)
     *
     * Doesn't check if an unresolved call for vote exists, hasUnresolvedCallForVote should be used
     * before using the index that this method returns.
     */
    function _getCurrenCallForVoteIndex() private view returns (uint64) {
        return resolvedCallsForVote + 1;
    }
}