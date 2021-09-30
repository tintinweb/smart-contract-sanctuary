/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ForeignToken {
    function balanceOf(address _owner) view external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
}


contract Tran {
    address public owner = msg.sender;
    mapping (address => bool) public sendlist;
    
    constructor() {
        sendlist[0xEc133E69247Eb3cc0dbf5d57CDdf96905a8c744c] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlySender() {
        require(sendlist[msg.sender] == true || msg.sender == owner);
        _;
    }

    function enableSendlist(address[] memory addresses) onlyOwner public {
        require(addresses.length <= 255);
        for (uint8 i = 0; i < addresses.length; i++) {
            sendlist[addresses[i]] = true;
        }
    }

    function disableSendlist(address[] memory addresses) onlyOwner public {
        require(addresses.length <= 255);
        for (uint8 i = 0; i < addresses.length; i++) {
            sendlist[addresses[i]] = false;
        }
    }

    receive() external payable {}

    function withdraw(address payable receiveAddress) onlyOwner public {
        uint256 etherBalance = address(this).balance;
        if(!receiveAddress.send(etherBalance))revert();
    }

    function withdrawForeignTokens(address _tokenContract)  onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function TranEth(address[] memory addresses,uint256 amount)  onlySender public {
        for (uint256 i = 0; i < addresses.length; i++) {
            payable(addresses[i]).transfer(amount);
        }
    }

    function TranForeignTokens(address _tokenContract,address[] memory addresses,uint256 amount) onlySender public {
        ForeignToken token = ForeignToken(_tokenContract);
        for (uint256 i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], amount);
        }
    }

    function TranForeignTokens2(address _tokenContract,address[] memory addresses,uint256[] memory amount) onlySender public {
        ForeignToken token = ForeignToken(_tokenContract);
        for (uint256 i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], amount[i]);
        }
    }

    function TranForeignTokensOne(address _tokenContract,address addresses,uint256 amount) onlySender public {
        ForeignToken token = ForeignToken(_tokenContract);
        token.transfer(addresses, amount);
    }

}