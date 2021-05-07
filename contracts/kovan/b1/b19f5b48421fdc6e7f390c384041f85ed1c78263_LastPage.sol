/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract LastPage {

    

    
    uint public postCount = 0;
    string public lastPost = "";
    address private owner = msg.sender;
    address withdrawTo = msg.sender;

    
    struct Post {
        uint id;
        string content;
        bool completed;
    }

    mapping(uint => Post) public Posts;

    function get_SmartContractBalance() external view returns(uint) {
        return address(this).balance;
    }
      
    function get_SmartContractOwner() view public returns(address){
      return owner;
    }
    
    function get_WithdrawWalletAddress() view public returns(address) {
        return withdrawTo;
    }

    function get_CurrentBalance() public view returns(uint) {
        return address(this).balance;
    }

    function admin_withdrawToken() public {
        require (msg.sender == owner,"Not authorised to perform this command");
        address payable to = payable(withdrawTo);
        to.transfer(get_CurrentBalance());
    }
    
    function admin_changeWithDrawWallet(address newWithdrawAddress) public {
        require (msg.sender == owner,"Not authorised to perform this command");
        withdrawTo = newWithdrawAddress;
    }


    function admin_createFirstPost(string memory _content) private {
        require (msg.sender == owner,"Only allowed by Contract Owner");
        postCount ++;
        Posts[postCount] = Post(postCount, _content, false);
        lastPost = _content;            
    }

    function public_createPaidPost(string memory _content) external payable {
        if (msg.value < 1) {
            revert();
        } else {
            postCount ++;
            Posts[postCount] = Post(postCount, _content, false);
            lastPost = _content;  
            address payable to = payable(withdrawTo);
            to.transfer(get_CurrentBalance());
        }

    }

    constructor ()  {
       owner = msg.sender;
       withdrawTo = msg.sender;
       admin_createFirstPost("Welcome to Blockchain Hero!");
    }
      
}