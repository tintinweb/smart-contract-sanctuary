/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl{
    struct Checkbook{
        string name;
        address payable user_address;
        uint256 saving;
        uint256 timestamp;
        uint256 withdrawn;
    }
    address[] all_address;
    mapping(address=>string) address_name;
    mapping(string=>Checkbook) name_user;
    
    function AddUser(string memory User, address payable UserAddress) public {
        all_address.push(UserAddress);
        address_name[UserAddress] = User;
        name_user[User].name = User;
        name_user[User].user_address = UserAddress;
        name_user[User].saving = 0;
        name_user[User].withdrawn = 0;
    }

    function Deposit(string memory User, uint256 Amount) public {
        name_user[User].timestamp = block.timestamp;
        name_user[User].saving += Amount;
    }

    function TimeMachine(string memory User, bool GoForwardInTime) external returns(uint256) {
        if(GoForwardInTime){
            name_user[User].timestamp -= 53 weeks;
        }
        return name_user[User].timestamp;
    }
    
    function CheckBalance (address payable UserAddress) public view returns(uint256){
        Checkbook memory s = name_user[address_name[UserAddress]];
        return s.saving-s.withdrawn;
    }

    function CheckTimeElapsed (address payable UserAddress) public view returns(uint256){
        Checkbook memory s = name_user[address_name[UserAddress]];
        return block.timestamp-s.timestamp;
    }
    
    function MyBalance() external view returns(uint256) {
        Checkbook memory s = name_user[address_name[msg.sender]];
        return s.saving-s.withdrawn;
    }
    
    function Withdraw() external returns(uint256){
        address payable user = payable(msg.sender);
        require(CheckTimeElapsed(user)> 52 weeks);
        uint balance = CheckBalance(user);
        user.transfer(balance);
        string memory name = address_name[msg.sender];
        name_user[name].withdrawn += balance;
        return balance;
    }
    
    fallback() external payable {
    }
    
    receive() external payable {
    }

}