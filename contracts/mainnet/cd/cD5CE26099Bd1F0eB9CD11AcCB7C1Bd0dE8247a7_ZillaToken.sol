// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";


/**
    ▄▄███▄▄·███████╗██╗██╗     ██╗      █████╗
    ██╔════╝╚══███╔╝██║██║     ██║     ██╔══██╗
    ███████╗  ███╔╝ ██║██║     ██║     ███████║
    ╚════██║ ███╔╝  ██║██║     ██║     ██╔══██║
    ███████║███████╗██║███████╗███████╗██║  ██║
    ╚═▀▀▀══╝╚══════╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝

     Special thanks to the developer of the Banana contract (Owl of Moistness)
     which granted us the usage of their code.
*/

// Interface to the Zilla migration contract
interface IZilla {
    function zillaBalance(address _user) external view returns(uint256);
}

contract ZillaToken is ERC20, Ownable {

    uint256 constant public DAILY_RATE = 5 ether;
    uint256 constant public ARISE_ISSUANCE = 150 ether;
    uint256 constant public END_YIELD = 1955833200; // 24 december 2031, unix timestamp

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;
    mapping(address => bool) public grantedContracts;

    IZilla public zillaContract;

    event RewardPaid(address indexed user, uint256 reward);

    // Constructor expects the address of the zilla contract, where the function balanceOG is implemented
    constructor(address _zilla) ERC20("ZillaToken", "$ZILLA"){
        zillaContract = IZilla(_zilla);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Update the rewards for the given user when one or more Zillas arise
    function updateRewardOnArise(address _user, uint256 _amount) external {
        require(msg.sender == address(zillaContract), "Not the Zilla contract");

        // Check the timestamp of the block against the end yield date
        uint256 time = min(block.timestamp, END_YIELD);
        uint256 timerUser = lastUpdate[_user];

        // If one or more Zillas of the user were already minted, update the rewards to the new yield
        if (timerUser > 0) {
            rewards[_user] += getPendingRewards(_user,time) + (_amount * ARISE_ISSUANCE);
        }
        else {
            rewards[_user] += (_amount * ARISE_ISSUANCE);
        }
        // Update the mapping to the newest update
        lastUpdate[_user] = time;
    }

    // Called on transfers / update rewards in the Zilla contract, allowing the new owner to get $ZILLA tokens
    function updateReward(address _from, address _to) external {
        require(msg.sender == address(zillaContract), "Not the Zilla contract");

        uint256 time = min(block.timestamp, END_YIELD);
        uint256 timerFrom = lastUpdate[_from];
        if (timerFrom > 0) {
            rewards[_from] += getPendingRewards(_from, time);
        }
        if (timerFrom != END_YIELD) {
            lastUpdate[_from] = time;
        }
        if (_to != address(0)) {
            uint256 timerTo = lastUpdate[_to];
            if (timerTo > 0) {
                rewards[_to] += getPendingRewards(_from, time);
            }
            if (timerTo != END_YIELD) {
                lastUpdate[_to] = time;
            }
        }
    }

    // Mint $ZILLA tokens and send them to the user
    function getReward(address _to) external {
        require(msg.sender == address(zillaContract), "Not the Zilla contract");
        uint256 reward = rewards[_to];
        if (reward > 0) {
            rewards[_to] = 0;
            _mint(_to, reward);
            emit RewardPaid(_to, reward);
        }
    }

    // Burn a given amount of $ZILLA for utility
    function burn(address _from, uint256 _amount) external {
        require(grantedContracts[msg.sender] || msg.sender == address(zillaContract), "Contract is not granted to burn");
        _burn(_from, _amount);
    }

    // Returns the amount of claimable $ZILLA tokens for the user (existing + pending)
    function getTotalClaimable(address _user) external view returns(uint256) {
        uint256 time = min(block.timestamp, END_YIELD);
        return rewards[_user] + getPendingRewards(_user, time);
    }

    // Set contracts allowed to perform operations on the contract (for future utility)
    function setGrantedContracts(address _address, bool _isGranted) public onlyOwner {
        grantedContracts[_address] = _isGranted;
    }

    // Get the pending rewards for the given user
    // @dev make sure that lastUpdate[user] is greater than 0
    function getPendingRewards(address _user, uint256 timeStamp) internal view returns(uint256) {
        return zillaContract.zillaBalance(_user) * (DAILY_RATE * (timeStamp - lastUpdate[_user])) / 86400;  //86400 = 3600s * 24h = 1 day in seconds
    }
}