/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File @openzeppelin/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File contracts/governance/TokensFarmCongressMembersRegistry.sol

pragma solidity 0.6.12;

/**
 * TokensFarmCongressMembersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 13.9.21.
 * Github: madjarevicn
 */

contract TokensFarmCongressMembersRegistry {
    using SafeMath for *;

    // The name of this contract
    string public constant name = "TokensFarmCongressMembersRegistry";

    // Event to fire every time someone is added or removed from members
    event MembershipChanged(address member, bool isMember);

    // _tokensFarmCongress congress pointer
    address public tokensFarmCongress;

    // The minimum number of voting members that must be in attendance
    uint256 minimalQuorum;

    // Mapping to check if the member is belonging to congress
    mapping (address => bool) isMemberInCongress;

    // Mapping address to member info
    mapping(address => Member) public address2Member;

    // Mapping to store all members addresses
    address[] public allMembers;

    // Info about member's of congress
    struct Member {
        // Name of member
        bytes32 name;
        // Member since what date
        uint memberSince;
    }

    // Modifiers
    modifier onlyTokensFarmCongress {
        require(msg.sender == tokensFarmCongress);
        _;
    }

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

    /**
     * @notice function is setting minimum quorum on new value
     *
     * @param newMinimumQuorum - new value of minimum quorum
     */
    function changeMinimumQuorum(
        uint newMinimumQuorum
    )
       external
       onlyTokensFarmCongress
    {
        require(
            newMinimumQuorum > 0,
            "Minimum quorum must be higher than 0"
        );

        minimalQuorum = newMinimumQuorum;
    }

    /**
     * @notice function is adding new member
     *
     * @param targetMember - ethereum address to be added
     * @param memberName - public name for that member
     */
    function addMember(
        address targetMember,
        bytes32 memberName
    )
        external
        onlyTokensFarmCongress
    {
        require(
            targetMember != address(0x0),
            "Target member can not be 0x0 address"
        );
        addMemberInternal(targetMember, memberName);
    }


    function addMemberInternal(
        address targetMember,
        bytes32 memberName
    )
        internal
    {
        //Require that this member is not already a member of congress
        require(!isMemberInCongress[targetMember], "Member already exists");
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
     * @notice remove membership from `targetMember`
     *
     * @param targetMember - ethereum address to be removed
     */
    function removeMember(
        address targetMember
    )
        external
        onlyTokensFarmCongress
    {
        require(isMemberInCongress[targetMember], "Member does not exits");

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
     * @notice function which will be exposed,
     * and congress will use it as "modifier"
     *
     * @param _address - is the address we're willing to check,
     * if it belongs to congress
     *
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

    /**
     * @notice getter for length for how many members are currently
     *
     * @return length of members
     */
    function getNumberOfMembers()
        external
        view
        returns (uint)
    {
        return allMembers.length;
    }

    /**
     * @notice function to get addresses of all members in congress
     *
     * @return array of addresses
     */
    function getAllMemberAddresses()
        external
        view
        returns (address[] memory)
    {
        return allMembers;
    }

    /**
     * @notice function to get member information
     *
     * @return address of member, members name and date when he became member
     */
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

    /**
     * @notice function to get minimal quorum
     *
     * @return minimal quorum
     */
    function getMinimalQuorum()
        external
        view
        returns (uint256)
    {
        return minimalQuorum;
    }
}