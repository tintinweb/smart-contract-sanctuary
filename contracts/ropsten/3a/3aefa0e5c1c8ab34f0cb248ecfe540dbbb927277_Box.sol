// contracts/access-control/Auth.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auth {
    address private _administrator;

    constructor(address deployer) {
        // Make the deployer of the contract the administrator
        _administrator = deployer;
    }

    function isAdministrator(address user) public view returns (bool) {
        return user == _administrator;
    }
}

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Auth from the access-control subdirectory
import "./Auth.sol";

contract Box {
    uint256 private _value;
    uint256 public totalSupply;
    address public supplyer;
    Auth private _auth;

    event ValueChanged(uint256 value);

    constructor(uint256 _totalSupply, address _supplyer) {
        _auth = new Auth(msg.sender);
        totalSupply = _totalSupply;
        supplyer = _supplyer;
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