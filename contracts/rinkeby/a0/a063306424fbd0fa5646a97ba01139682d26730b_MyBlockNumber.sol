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


// File contracts/levels/MyBlockNumber.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;


// Guess(?) the block number and be rewarded
contract MyBlockNumber is ILevelContract {
    string public name = "My Block Number";
    uint256 public credits = 10e18;
    ICourseContract public course;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function submit(uint256 guess) public {
        require(block.number == guess);
        course.creditToken(msg.sender);
    }
}