//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ACPIOne.sol";
contract ACPIMaster {

    ACPIOne public acpiOne;
    event constructorBegin();
    event constructorEnd();
    event contractCreated(address newACPIOne);

    constructor() {
        emit constructorBegin();
        acpiOne = new ACPIOne(2022);
        emit constructorEnd();
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ACPIOne {
    uint256 public number;
    event APCIOneCreated(address newContract);

    address public owner;
    constructor(uint256 _number) {
        owner = msg.sender;
        number = _number;
        emit APCIOneCreated(address(this));
    }

}