// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./access-control/Auth.sol";

contract Box {

    uint256 private _value;
    Auth private _auth;

    event ValueChanged(uint256 value);

    constructor() public {
        _auth = new Auth(msg.sender);
    }

    function store(uint256 value) public{
      // Require that the caller is registered as an administrator in Auth
        require(_auth.isAdministrator(msg.sender), "Unauthorized");

       _value = value;
       emit ValueChanged(value);
    }

    function retrieve() public view returns (uint256) {
      return _value;
    }

}

// contracts/access-control/Auth.sol
// SPDX-License-Identifier: MIT


pragma solidity ^0.6.12;

contract Auth {
    address private _administrator;

    constructor(address deployer) public {
        // Make the deployer of the contract the administrator
        _administrator = deployer;
    }

    function isAdministrator(address user) public view returns (bool) {
        return user == _administrator;
    }
}

