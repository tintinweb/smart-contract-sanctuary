/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// File contracts/ILevelContract.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;

interface ILevelContract {
    function name() external returns (string memory);

    function credits() external returns (uint256);
}


// File contracts/ICourseContract.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;

interface ICourseContract {
    function creditToken(address challenger) external;

    function addLevel(address levelContract) external;
}


// File contracts/levels/HeSaysSheSays.sol

// Call with previous address

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;


// Simply
contract HeSaysSheSays is ILevelContract {
    string public name = "He Says She Says";
    uint256 public credits = 10e18;
    ICourseContract public course;
    address lastUser;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
        lastUser = msg.sender;
    }

    function submit(address addr) public {
        require(addr == lastUser);
        lastUser = msg.sender;
        course.creditToken(msg.sender);
    }
}