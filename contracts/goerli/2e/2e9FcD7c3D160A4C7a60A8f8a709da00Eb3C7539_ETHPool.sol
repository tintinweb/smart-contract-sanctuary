/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title Edge and Node Code Challenge - ETHPool
/// @author Tyler Goodman - github.com/technicallyty
/**
 * ASSUMPTIONS
 * - the reward period (or 'index') is automatically increased each time the team deposits.
 * - only ETH is accepted for this impl. no ERC-20's accepted.
 */
contract ETHPool {
    // ----------------- EVENTS -----------------
    /// @notice withdraw will fire when a user withdraws their funds
    event Withdraw(address, uint256);

    /// @notice Received will fire when ether is deposited to the contract
    event Received(address, uint256);
	// -----------------        -----------------

	/// @notice public tracker for the current period for deposits
    uint256 public currentDepositID;

    /// @notice the address which deposits the bonus rewards
    address public team;

    // mapping of deposit ID to pool
    mapping(uint256 => uint256) pool;

    // mapping from address to mapping of depositID to deposit.
    mapping(address => mapping(uint256 => uint256)) deposits;

    /// @notice mapping of an address to it's coressponding deposit IDs.
    mapping(address => uint256[]) public allUserDepositIDs;

	// mapping of address to a deposit ID's index in the allUserDepositID's list
    mapping(address => mapping(uint256 => uint256)) userDepositIDindex;

    constructor() {
        team = msg.sender;
    }

    /// @notice gets the total user deposits (not including team)
    function poolTotal(uint256 _depositID) external view returns (uint256) {
        return pool[_depositID];
    }

    /// @notice gets the teams total deposited bonus rewards for the ID
    function getTeamDeposit(uint256 _depositID)
        external
        view
        returns (uint256)
    {
        return deposits[team][_depositID];
    }

    /// @notice gets the deposit for a given user
    function getDeposit(address _user, uint256 _depositID)
        external
        view
        returns (uint256)
    {
        return deposits[_user][_depositID];
    }

    function getDepositIDs(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return allUserDepositIDs[_user];
    }

    // @notice withdraws the users deposit + their percentage of the total user deposits * the team's deposit.
    //          taking the extra rewards from the team pool.
    function withdrawRewards(address payable _to, uint256 _depositID)
        external
        returns (uint256)
    {
        // get the sum and subtract it from rewardsPool
        uint256 sum = deposits[msg.sender][_depositID];
        require(
            pool[_depositID] >= sum && sum != 0,
            "cannot withdraw 0 funds"
        );

        // get the bonus
        // property:  bonus => (sum / rewardsPool) * deposits[team];
        uint256 bonus = pool[_depositID]/sum;
        bonus = deposits[team][_depositID]/bonus;

        // remove the deposit from the rewards pool
        pool[_depositID] = pool[_depositID] - sum;

        // remove the bonus from the team rewards pool
        deposits[team][_depositID] = deposits[team][_depositID] - bonus;

        // add the bonus to the sum, remove the balance and transfer
        sum += bonus;
        deposits[msg.sender][_depositID] = 0;
        removeDepositFromArray(_depositID);
        _to.transfer(sum);

        emit Withdraw(_to, sum);
        return sum;
    }

    /// @notice gets the total amount of eth held in this contract
    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Private function to remove an entry from the deposit index tracking data structures.
     * This has O(1) time complexity, but alters the order of the userDepositIDindex array.
     * @param tokenId uint256 ID of the index to be removed from the deposit list
     */
    function removeDepositFromArray(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = allUserDepositIDs[msg.sender].length - 1;
        uint256 tokenIndex = userDepositIDindex[msg.sender][tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = allUserDepositIDs[msg.sender][lastTokenIndex];

        allUserDepositIDs[msg.sender][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        userDepositIDindex[msg.sender][lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete userDepositIDindex[msg.sender][tokenId];
        allUserDepositIDs[msg.sender].pop();
    }

    receive() external payable {
        if (msg.sender == team) {
            deposits[team][currentDepositID] = msg.value;
            currentDepositID++;
        } else {
            deposits[msg.sender][currentDepositID] = msg.value;
            pool[currentDepositID] += msg.value;
            allUserDepositIDs[msg.sender].push(currentDepositID);
            uint256 _id = allUserDepositIDs[msg.sender].length - 1;
            userDepositIDindex[msg.sender][currentDepositID] = _id;
        }
        emit Received(msg.sender, msg.value);
    }
}