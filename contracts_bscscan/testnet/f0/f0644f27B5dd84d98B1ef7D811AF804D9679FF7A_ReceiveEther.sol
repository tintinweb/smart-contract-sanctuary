/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

// // SPDX-License-Identifier: MIT

// pragma solidity >=0.8.0;

// import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
// import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
// import '@openzeppelin/contracts/utils/math/SafeMath.sol';
// import "@openzeppelin/contracts/access/Ownable.sol";

// contract autoaaa is Ownable {
//     address public owner;
//     // mapping(bytes32 => address) public tokens;  
//     constructor() public {  
//         owner = msg.sender;  
//     }  

    
// }

pragma solidity ^0.8.10;

contract ReceiveEther {
    /*
    Which function is called, fallback() or receive()?

           send Ether
               |
         msg.data is empty?
              / \
            yes  no
            /     \
receive() exists?  fallback()
         /   \
        yes   no
        /      \
    receive()   fallback()
    */

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract SendEther {
    function sendViaTransfer(address payable _to) public payable {
        // This function is no longer recommended for sending Ether.
        _to.transfer(msg.value);
    }

    function sendViaSend(address payable _to) public payable {
        // Send returns a boolean value indicating success or failure.
        // This function is not recommended for sending Ether.
        bool sent = _to.send(msg.value);
        require(sent, "Failed to send Ether");
    }

    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}