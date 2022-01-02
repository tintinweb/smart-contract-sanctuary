//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ETHPool {

    mapping (address => uint) public stakersBalance;
    address[] public stakersList; 
    uint public totalStake;
    mapping (address => bool) public owners;

    constructor(address[] memory _owners) {
        for(uint i; i<_owners.length; i++) {
            owners[_owners[i]] = true;
        }
    }
    function addOwner(address newOwner) external onlyOwners {
        owners[newOwner] = true;
    }    

    function getStakersList() public view returns(address[] memory) {
        return stakersList;
    }
    function stake() external payable {
        if (stakersBalance[msg.sender] == 0) {
            stakersList.push(msg.sender);
        } 
        stakersBalance[msg.sender] += msg.value;
        totalStake +=msg.value;
    }

    function withdraw(uint amount) external {
        require(amount<= stakersBalance[msg.sender],'Amount is higher than balance');
        stakersBalance[msg.sender] -= amount;
        totalStake -= amount;
        if (stakersBalance[msg.sender]==0) {
            bool isFound;
            uint len = stakersList.length;
            for(uint i;i<len;i++) {
                if(isFound) {
                    stakersList[i-1] = stakersList[i];
                }
                if (stakersList[i]==msg.sender) {
                    isFound=true;
                }
            }
            if(isFound) {
                stakersList.pop();
            }
        }
        payable(msg.sender).transfer(amount);
    }

    function addReward() payable external onlyOwners {
        require(stakersList.length>0,'Must be at least one staker');
        for(uint i; i< stakersList.length;i++) {
            uint reward = stakersBalance[stakersList[i]]*msg.value/totalStake;
            stakersBalance[stakersList[i]] += reward;
        }
        totalStake += msg.value; 
    }

    modifier onlyOwners {
        require( owners[msg.sender],'Only owners can call this function');
        _;
    }
}