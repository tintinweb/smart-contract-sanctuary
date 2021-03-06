/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract UniqlyPresaleA {
    string public name = "Uniqly Presale A";
    address constant public owner = 0xd035E08110B5303613bbFe25Bd668C5241144d35;

    uint256 constant private minInvestorCap = 0.3 ether;
    uint256 constant private maxInvestorCap = 1 ether;
    uint256 constant private presaleHardCap = 79 ether;
    mapping(address => uint256) private balances;

    bool private presaleEnded = false;
    
    // 7 April 2021 18:00:00
    uint256 constant public presaleDateExceeded = 1617818400;

    function send(address _user, uint256 _amount) private {
        bool _success = false;
       (_success,) = _user.call{value: _amount}('');

        require(_success, "Send failed");
    }

    function totalCollected() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }

    receive() external payable {
        require(!presaleEnded, "Presale is ended");
        require(block.timestamp < presaleDateExceeded, "Presale time passed");
        uint256 _amount = msg.value + balances[msg.sender];
        
        require(_amount >= minInvestorCap, "User not exceeded the min amount of transfer");
        require(_amount <= maxInvestorCap, "User exceeded the max amount of transfer");
        
        balances[msg.sender] = _amount;
        
        if (totalCollected() >= presaleHardCap) {
            presaleEnded = true;
            send(owner, address(this).balance);
        }
    }

    function withdrawByUser() external {
        require(!presaleEnded, "Presale is ended");
        require(block.timestamp > presaleDateExceeded, "Presale time not passed");
        
        uint256 _amount = balances[msg.sender];
        balances[msg.sender] = 0;
        send(msg.sender, _amount);
    }
}