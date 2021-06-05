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


// File contracts/levels/Spendthrift.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.17;


// Let me spend your coins
interface ERC20 {
    function balanceOf(address owner) external returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

contract Spendthrift is ILevelContract {
    string public name = "Spendthrift";
    uint256 public credits = 20e18;
    ICourseContract public course;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function gimmeYourCard(address token) public {
        ERC20 tokenContract = ERC20(token);

        // Check that initial balance is 0
        require(tokenContract.balanceOf(address(this)) == 0);

        // Transfer from msg.sender
        tokenContract.transferFrom(msg.sender, address(this), 10000e18);

        // Check that initial balance is 10000
        require(tokenContract.balanceOf(address(this)) == 10000e18);

        course.creditToken(msg.sender);
    }
}