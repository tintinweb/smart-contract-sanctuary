/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

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


// File contracts/levels/IRobot.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;


// Call with smart contract
contract IRobot is ILevelContract {
    string public name = "I Robot";
    uint256 public credits = 20e18;
    ICourseContract public course;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function ping(address challenger) public {
        require(isContract(msg.sender), "Caller must be a smart contract");
        course.creditToken(challenger);
    }

    function isContract(address _addr) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}