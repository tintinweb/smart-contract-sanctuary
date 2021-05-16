/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity ^0.6.0;

contract findEvil {
    mapping(bytes32 => uint) passwordHashToBalance;

    function lockEthers(bytes32 passwordHash) public payable {
        passwordHashToBalance[passwordHash] += msg.value;
    }

    function getHash(string memory raw) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(raw));
    }

    function unlockEthers(string memory password) public {
        bytes32 passwordHash = getHash(password);

        require(
            passwordHashToBalance[passwordHash] > 0,
            "No Ethers locked with this password"
        );

        msg.sender.transfer(passwordHashToBalance[passwordHash]);

        passwordHashToBalance[passwordHash] = 0;
    }
}