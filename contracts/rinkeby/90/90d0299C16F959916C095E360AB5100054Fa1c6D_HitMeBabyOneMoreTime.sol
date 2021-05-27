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


// File contracts/levels/HitMeBabyOneMoreTime.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;


// Hit the contract. The challenge is completed when the counter is a multiple of 30
// What happens when everyone is hitting it at the same time?
contract HitMeBabyOneMoreTime is ILevelContract {
    string public name = "HitMeBabyOneMoreTime";
    uint256 public credits = 20e18;
    ICourseContract public course;
    uint256 public hits = 1;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function hit() public {
        hits += 1;
    }

    function submit(address challenger) public {
        require(hits % 30 == 0);
        hit();
        course.creditToken(challenger);
    }
}