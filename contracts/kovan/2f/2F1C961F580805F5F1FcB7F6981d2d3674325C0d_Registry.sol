// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Name Registry
/// @author devtooligan.eth
/// @notice An excercise for the Yield mentorship program based on https://www.thehashmasks.com/names
contract Registry {
    /// @notice This is where registered names are stored
    /// @return The account address of the owner of a given name
    mapping(string => address) public claimedNames;

    /// @notice This event is emitted when a name is claimed
    /// @param _name The name being claimed
    /// @param _by The account address of the claimaint
    event NameClaimed(string _name, address _by);

    /// @notice This event is emitted when a name is released
    /// @param _name The name being released
    /// @param _by The account address of the former owner who initiated the release
    event NameReleased(string _name, address _by);

    /// @notice Use this function to claim an unclaimed name
    /// @dev Updates claimedNames with new owner
    /// @param _name The name being claimed
    function claimName(string memory _name) public {
        require(claimedNames[_name] == address(0), "Name already claimed");
        claimedNames[_name] = msg.sender;
        emit NameClaimed(_name, msg.sender);
    }

    /// @notice Registered name owners use this function to unclaim a name
    /// @dev Updates claimedNames with null address
    /// @param _name The name being claimed
    function releaseName(string memory _name) public {
        require(claimedNames[_name] == msg.sender, "Unauthorized");
        claimedNames[_name] = address(0);
        emit NameReleased(_name, msg.sender);
    }
}

