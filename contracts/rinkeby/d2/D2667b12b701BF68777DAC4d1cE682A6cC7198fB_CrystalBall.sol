/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

//SPDX-License-Identifier: Unlicense

// File contracts/ILevelContract.sol

pragma solidity ^0.5.17;

interface ILevelContract {
    function name() external returns (string memory);

    function credits() external returns (uint256);
}


// File contracts/ICourseContract.sol

pragma solidity ^0.5.17;

interface ICourseContract {
    function creditToken(address challenger) external;

    function addLevel(address levelContract) external;
}


// File contracts/levels/CrystalBall.sol

// Guess the blockhash
pragma solidity ^0.5.17;


contract CrystalBall is ILevelContract {
    string public name = "Crystal Ball";
    uint256 public credits = 30e18;
    ICourseContract public course;
    mapping(address => bool) nullifier;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function gaze(bytes32 guess, address challenger)
        public
        allowedToCall(msg.sender)
    {
        require(blockhash(block.number) == guess, "Wrong guess");
        course.creditToken(challenger);
    }

    modifier allowedToCall(address caller) {
        require(
            !nullifier[caller],
            "Not allowed to call again with this caller"
        );
        nullifier[caller] = true;
        _;
    }
}