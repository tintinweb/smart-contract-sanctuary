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


// File contracts/levels/MathOlympiad.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;


// (bool success,) = address(test).call(abi.encodeWithSignature("nonExistingFunction()"));

interface Contestant {
    function add(uint256 a, uint256 b) external pure returns (uint256);

    function sub(uint256 a, uint256 b) external pure returns (uint256);

    function div(uint256 a, uint256 b) external pure returns (uint256);

    function mul(uint256 a, uint256 b) external pure returns (uint256);
}

// Implement contract with add & sub & mul & div (safe math)
contract MathOlympiad is ILevelContract {
    string public name = "Math Olympiad";
    uint256 public credits = 20e18;
    ICourseContract public course;
    uint256 largestNumber =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    mapping(address => bool) nullifier;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function compete(address contestantAddr) public returns (bytes32) {
        require(!nullifier[contestantAddr]);
        Contestant contestant = Contestant(contestantAddr);

        // Test addition
        require(contestant.add(1337, 2) == 1339);
        (bool addFailure, ) =
            contestantAddr.call(
                abi.encodeWithSignature(
                    "add(uint256,uint256)",
                    largestNumber,
                    2
                )
            );
        require(!addFailure);

        // Test subtraction
        require(contestant.sub(1337, 2) == 1335);
        (bool subFailure, ) =
            contestantAddr.call(
                abi.encodeWithSignature(
                    "sub(uint256,uint256)",
                    1,
                    largestNumber
                )
            );
        require(!subFailure);

        // Test multiplication
        require(contestant.mul(1337, 2) == 2674);
        (bool mulFailure, ) =
            contestantAddr.call(
                abi.encodeWithSignature(
                    "mul(uint256,uint256)",
                    largestNumber,
                    largestNumber
                )
            );
        require(!mulFailure);

        // Test multiplication
        require(contestant.div(1338, 2) == 669);
        (bool divFailure, ) =
            contestantAddr.call(
                abi.encodeWithSignature(
                    "div(uint256,uint256)",
                    largestNumber,
                    0
                )
            );
        require(!divFailure);

        nullifier[contestantAddr] = true;
        course.creditToken(msg.sender);
    }
}