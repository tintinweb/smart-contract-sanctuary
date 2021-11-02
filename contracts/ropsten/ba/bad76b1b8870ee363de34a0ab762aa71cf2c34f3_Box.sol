// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Auth from the access-control subdirectory
import "./Auth.sol";

contract Box {
    uint256 private _value;
    uint256 public totalSupply;
    Auth private _auth;

    event ValueChanged(uint256 value);

    constructor(uint256 _totalSupply) {
        _auth = new Auth(msg.sender);
        totalSupply = _totalSupply;
    }

    function store(uint256 value) public {
        // Require that the caller is registered as an administrator in Auth
        require(_auth.isAdministrator(msg.sender), "Unauthorized");

        _value = value;
        emit ValueChanged(value);
    }

    function retrieve() public view returns (uint256) {
        return _value;
    }
}