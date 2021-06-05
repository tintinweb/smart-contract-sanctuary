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


// File contracts/levels/MoneyLaunderer.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;


interface IRecipient {
    function handlePayment() external payable returns (uint256);
}

// Launder the money to another smart contract that has to return a secret code
contract MoneyLaunderer is ILevelContract {
    string public name = "Money Launderer";
    uint256 public credits = 20e18;
    ICourseContract public course;
    mapping(address => bool) nullifier;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function launder(address recipient) public payable {
        require(!nullifier[recipient], "Launderer has been used before");
        require(msg.value >= 1e16, "Not enough ethers sent");
        IRecipient recipientContract = IRecipient(recipient);

        // Calling a method and sending ether is different for solidity 0.8
        // See https://solidity-by-example.org/sending-ether/
        uint256 secret = recipientContract.handlePayment.value(msg.value)();
        require(secret == 1337, "Launderer does not know scret");
        nullifier[recipient] = true;
        course.creditToken(msg.sender);
    }
}