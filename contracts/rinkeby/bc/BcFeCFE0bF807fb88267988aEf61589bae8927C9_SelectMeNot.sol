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


// File contracts/levels/SelectMeNot.sol

// submit the selector for this function

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;


// Figure out the function selector to complete the challenge
contract SelectMeNot is ILevelContract {
    string public name = "Select Me Not";
    uint256 public credits = 10e18;
    ICourseContract public course;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function selectMeNot(bytes4 selector) public {
        require(selector == this.selectMeNot.selector);
        course.creditToken(msg.sender);
    }
}