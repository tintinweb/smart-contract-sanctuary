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


// File contracts/levels/WishingWell.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;


// Send me some small amount of Ethers to complete the challenge
contract WishingWell is ILevelContract {
    string public name = "WishingWell";
    uint256 public credits = 10e18;
    ICourseContract public course;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function() external payable {
        require(msg.value >= 1e16);
        course.creditToken(msg.sender);
    }
}