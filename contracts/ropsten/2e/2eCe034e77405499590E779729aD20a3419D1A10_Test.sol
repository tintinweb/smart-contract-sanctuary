// SPDX-License-Identifier: MIT
// const address = '0xAfA472c69acB5EFC7339008F2569822f36af64cC';
// const Test = await ethers.getContractFactory("Test");
// const test = await new ethers.Contract(address, Test.interface, Test.provider);
// await test.blockNum();
pragma solidity ^0.7.4;

contract Test {

    string message;

    function blockNum( ) external view returns (uint) {
        return block.number;
    }

    function setMessage(string calldata _message) external {
        message = _message;
    }

    function getMessage() public view returns(string memory) {
        return message;
    }
    
}