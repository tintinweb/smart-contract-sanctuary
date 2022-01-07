// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Registry
/// @author M
/// @notice Creates a registry of name to owner
contract Registry {
    event Claim(string indexed _name, address indexed owner);
    event Release(string indexed _name, address indexed owner);

    mapping(string => address) public nameToOwner;

    /// @notice Claim any name if not already claimed
    /// @param _name The name the user wants to claim
    function claim(string memory _name) public {
        require(nameToOwner[_name] == address(0), "name already claimed");
        nameToOwner[_name] = msg.sender;

        emit Claim(_name, msg.sender);
    }

    /// @notice Release a claimed name
    /// @param _name The name the user wants to release
    function release(string memory _name) public {
        require(nameToOwner[_name] == msg.sender, "not owner");
        nameToOwner[_name] = address(0);

        emit Release(_name, msg.sender);
    }
}