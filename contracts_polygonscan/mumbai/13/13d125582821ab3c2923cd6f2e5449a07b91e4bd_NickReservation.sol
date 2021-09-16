/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NickReservation {
    struct Nick {
        address owner;
        bool approved;
    }
    mapping(string => Nick) public nickList;
    
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function storeName(string memory name) public payable {
        require(nickList[name].owner == address(0), "The name is already registered");
        require(msg.value == 0.01 ether, "Please send 0.01");
        address payable wallet = payable(address(this));
        bool sent = wallet.send(msg.value);
        require(sent, "Failed to send Ether");
        
        nickList[name] = Nick({
            owner: msg.sender,
            approved: false
        });
    }
    
    function deleteName(string memory name) external {
        require(nickList[name].owner == msg.sender);
        require(payable(msg.sender).send(0.009 ether));
        delete nickList[name];
    }
    
    function canUseName(string memory name) public view returns (bool) {
        return nickList[name].owner == msg.sender;
    }
}