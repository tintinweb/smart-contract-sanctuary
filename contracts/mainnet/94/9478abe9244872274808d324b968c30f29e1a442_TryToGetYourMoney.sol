pragma solidity ^0.6.0;

contract TryToGetYourMoney {
    mapping(bytes32 => uint) passwordHashToBalance;
    
    function lockEthersWithPassword(
        bytes32 passwordHash
    ) public payable {
        passwordHashToBalance[passwordHash] += msg.value;
    }
    
    function getHash(string memory raw) public view returns(bytes32) {
        return keccak256(abi.encodePacked(raw));
    }
    
    function unlockEthersWithPassword(
        string memory password
    ) public {
        bytes32 passwordHash = getHash(password);

        require(
            passwordHashToBalance[passwordHash] > 0,
            "No Ethers locked with specified password"
        );
        
        msg.sender.transfer(passwordHashToBalance[passwordHash]);

        passwordHashToBalance[passwordHash] = 0;
    }
}