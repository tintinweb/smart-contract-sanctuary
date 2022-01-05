// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Ezeki {

    string public nickname;
    string public avatarId;

    // function initialize(string memory _nickname, string memory _avatarId) public initializer {
    //     nickname = _nickname;
    //     avatarId = _avatarId;
    // }

    function sayHi() public pure returns (string memory) {
        return "Hello World";
    }

    function sum(int256 a, int256 b) public pure returns (int256) {
        return a + b;
    }
}