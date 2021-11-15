// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

contract TransferTest {
    function balance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw1(address payable to) external {
        to.transfer(address(this).balance);
    }

    function withdraw2(address to) external {
        payable(to).transfer(address(this).balance);
    }

    receive() external payable
    {
    }
}

