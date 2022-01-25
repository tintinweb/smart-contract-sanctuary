// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract CodeTest is Ownable{
    
    address payable public beneficiary;

    struct UserStruct {
        uint id;
        address payable referrerID;
        address[] referral;
        uint investment;
        uint downline;
    }

    uint public totalInvest = 0;
    uint public withdrawal = 0;

    uint[] public precent_of_reward = [10,5,5,5,5,5,5,5,5,5,5];

    mapping (address => UserStruct) public users;

    uint public currUserID = 0;

    event regEvent(address indexed _user, address indexed _referrer, uint _time);
    event investEvent(address indexed _user, uint _amount, uint _time);
    event getMoneyEvent(uint indexed _user, uint indexed _referral, uint _amount, uint _level, uint _time);
   
    constructor() {
        beneficiary = payable(msg.sender);

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            id: currUserID,
            referrerID: beneficiary,
            referral: new address[](0),
            investment: 99999999 ether,
            downline: 0
        });
        users[beneficiary] = userStruct;
    }

    // receive() external payable {
    //     if(users[msg.sender].id > 0){
    //         invest();
    //     } else {
    //         uint refId = 0;
    //         address referrer = bytesToAddress(msg.data);
    //         regUser(payable(referrer));
    //     }
    // }

    function regUser(address payable _referrerID) public payable {
        require(users[msg.sender].id == 0, "User exist");
        require(msg.value > 0, 'register with ETH');

        totalInvest += msg.value;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            id: currUserID,
            referrerID: _referrerID,
            referral: new address[](0),
            investment: msg.value,
            downline: 0
        });

        users[msg.sender] = userStruct;

        users[_referrerID].referral.push(msg.sender);

        emit regEvent(msg.sender, _referrerID, block.timestamp);
    }

    function invest() public payable {
        require(users[msg.sender].id > 0, 'User not exist');
        require(msg.value > 0, 'invest with ETH');

        totalInvest += msg.value;

        users[msg.sender].investment += msg.value;
        emit investEvent(msg.sender, msg.value, block.timestamp);
    }

    function viewUserGen(address _user, uint _gen) public view returns(uint) {
        uint gen = _gen;
        for (uint i = 0; i < users[_user].referral.length; i++) {
            uint temp = viewUserGen(users[_user].referral[i], (_gen + uint(1)));
            if(temp > gen){
                gen = temp;
            }
        }
        return gen;
    }

    function setUserGen(uint _user, address payable _add, uint _i) public returns(address) {
        address payable addr_2 = payable(address(uint160(_i)));
        address payable addr_1 = _add;
        for (uint i = _i; i < _user; i++) {
            UserStruct memory userStruct;
            currUserID++;
            if(i == _i){
                
            }else{
                addr_1 = addr_2;
            }
            addr_2 = payable(address(uint160(i)));
            // address payable addr_1 = _add;
            
            // address payable addr_2 = payable(address(uint160(block.timestamp + i + 101)));

            userStruct = UserStruct({
                id: currUserID,
                referrerID: addr_1,
                referral: new address[](0),
                investment: 100,
                downline: 0
            });
            users[addr_2] = userStruct;
            users[addr_1].referral.push(addr_2);
        }
        return addr_2;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function beneficiaryWithdrawal() public onlyOwner returns (bool) {
        withdrawal += address(this).balance;
        beneficiary.transfer(address(this).balance);
        return true;
    }

    function updateRewardPercent(uint[] memory _precent_of_reward) onlyOwner public returns (bool) {
        precent_of_reward = _precent_of_reward;
        return true;
    }
}