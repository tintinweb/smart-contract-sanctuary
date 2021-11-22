//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "./SafeMath.sol";

/**
 * TokensFarmCongressMembersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 13.9.21.
 * Github: madjarevicn
 */
contract TokensFarmCongressMembersRegistry {

    using SafeMath for *;

    /// @notice The name of this contract
    string public constant name = "TokensFarmCongressMembersRegistry";

    /// @notice Event to fire every time someone is added or removed from members
    event MembershipChanged(address member, bool isMember);

    /// @notice _tokensFarmCongress congress pointer
    address public tokensFarmCongress;

    //The minimum number of voting members that must be in attendance
    uint256 minimalQuorum;

    // Mapping to check if the member is belonging to congress
    mapping (address => bool) isMemberInCongress;

    // Mapping address to member info
    mapping(address => Member) public address2Member;

    // Mapping to store all members addresses
    address[] public allMembers;


    struct Member {
        bytes32 name;
        uint memberSince;
    }

    modifier onlyTokensFarmCongress {
        require(msg.sender == tokensFarmCongress);
        _;
    }

    /**
     * @param initialCongressMembers is the array containing addresses of initial members
     */
    constructor(
        address[] memory initialCongressMembers,
        bytes32[] memory initialCongressMemberNames,
        address _tokensFarmCongress
    )
    public
    {
        uint length = initialCongressMembers.length;

        for(uint i=0; i<length; i++) {
            addMemberInternal(
                initialCongressMembers[i],
                initialCongressMemberNames[i]
            );
        }

        tokensFarmCongress = _tokensFarmCongress;
    }


    function changeMinimumQuorum(
        uint newMinimumQuorum
    )
    external
    onlyTokensFarmCongress
    {
        require(newMinimumQuorum > 0);
        minimalQuorum = newMinimumQuorum;
    }

    /**
     * Add member
     *
     * Make `targetMember` a member named `memberName`
     *
     * @param targetMember ethereum address to be added
     * @param memberName public name for that member
     */
    function addMember(
        address targetMember,
        bytes32 memberName
    )
    external
    onlyTokensFarmCongress
    {
        addMemberInternal(targetMember, memberName);
    }


    function addMemberInternal(
        address targetMember,
        bytes32 memberName
    )
    internal
    {
        //Require that this member is not already a member of congress
        require(isMemberInCongress[targetMember] == false);
        // Update basic member information
        address2Member[targetMember] = Member({
        memberSince: block.timestamp,
        name: memberName
        });
        // Add member to list of all members
        allMembers.push(targetMember);
        // Update minimum quorum
        minimalQuorum = allMembers.length.sub(1);
        // Mark that user is member in congress
        isMemberInCongress[targetMember] = true;
        // Fire an event
        emit MembershipChanged(targetMember, true);
    }

    /**
     * Remove member
     *
     * @notice Remove membership from `targetMember`
     *
     * @param targetMember ethereum address to be removed
     */
    function removeMember(
        address targetMember
    )
    external
    onlyTokensFarmCongress
    {
        require(isMemberInCongress[targetMember] == true);

        uint length = allMembers.length;

        uint i=0;

        // Find selected member
        while(allMembers[i] != targetMember) {
            if(i == length) {
                revert();
            }
            i++;
        }

        // Move the last member to this place
        allMembers[i] = allMembers[length-1];

        // Remove the last member
        allMembers.pop();

        //Remove him from state mapping
        isMemberInCongress[targetMember] = false;

        //Remove his state to empty member
        address2Member[targetMember] = Member({
        memberSince: block.timestamp,
        name: "0x0"
        });

        //Reduce 1 member from quorum
        minimalQuorum = minimalQuorum.sub(1);

        // Emit event that member is removed.
        emit MembershipChanged(targetMember, false);
    }

    /**
     * @notice Function which will be exposed and congress will use it as "modifier"
     * @param _address is the address we're willing to check if it belongs to congress
     * @return true/false depending if it is either a member or not
     */
    function isMember(
        address _address
    )
    external
    view
    returns (bool)
    {
        return isMemberInCongress[_address];
    }

    /// @notice Getter for length for how many members are currently
    /// @return length of members
    function getNumberOfMembers()
    external
    view
    returns (uint)
    {
        return allMembers.length;
    }

    /// @notice Function to get addresses of all members in congress
    /// @return array of addresses
    function getAllMemberAddresses()
    external
    view
    returns (address[] memory)
    {
        return allMembers;
    }

    /// Get member information
    function getMemberInfo(
        address _member
    )
    external
    view
    returns (address, bytes32, uint)
    {
        Member memory member = address2Member[_member];
        return (
        _member,
        member.name,
        member.memberSince
        );
    }

    function getMinimalQuorum()
    external
    view
    returns (uint256)
    {
        return minimalQuorum;
    }
}