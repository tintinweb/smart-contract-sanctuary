pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

contract SuperChat {
    
    struct SuperChatObj {
        address sender;
        address receiver;
        uint amount;
        string message;
        string videoId;
    }

    event SuperChatEvent(address indexed sender, address indexed receiver, uint256 amount, string message);
    mapping(address => uint256[]) superchatPaidMapping;
    mapping(address => uint256[]) superchatReceivedMapping;

    SuperChatObj[] allSuperChats;

    function superChat(address receiver, uint amount, string memory message, string memory videoId) external payable {
        require(msg.value == amount, "Send correct amount of ether");
        payable(receiver).transfer(amount);
        SuperChatObj memory newSuperChat = SuperChatObj(msg.sender, receiver, amount, message, videoId);
        allSuperChats.push(newSuperChat);
        superchatReceivedMapping[receiver].push(allSuperChats.length - 1);
        superchatPaidMapping[msg.sender].push(allSuperChats.length - 1);
        emit SuperChatEvent(msg.sender, receiver, amount, message);
    }

    function superchatReceived() external view returns(uint256[] memory) {
        return superchatReceivedMapping[msg.sender];
    }

    function superChatPaid() external view returns(uint256[] memory) {
        return superchatPaidMapping[msg.sender];
    }

    function superchatFromIndex(uint256 index) external view returns(SuperChatObj memory) {
        return allSuperChats[index];
    }

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}