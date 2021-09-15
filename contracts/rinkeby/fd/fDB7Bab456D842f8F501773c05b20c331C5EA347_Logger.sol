/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Logger {

    struct Log {
        address owner;
        uint identifier;
        address[] users;
        mapping (address => uint) deposit;   
        mapping (address => uint) metric;
    }

    Log[] public logs;

    address payable public admin;
    constructor() {
        // Save contract owner address during deployment
        admin = payable(msg.sender);
    }

    // define events
    event DepositEvent(address indexed sender, uint value, uint256 idx);
    event LogDeployed(address indexed owner, uint256 identifier, uint256 idx);
    event LogEvent(address indexed sender, uint256 identifier, uint value, uint256 idx);

    function hashSeriesNumber(uint256 nonce, uint256 number) public pure returns (uint) {
        // hash the value of a string and number 
        return uint256(keccak256(abi.encodePacked(number, nonce)));
    }

    function get_owner(uint idx) public view returns (address){
        // returns the address of the owner for certain id 
        return logs[idx].owner;
    }

    function is_owner(address addr, uint idx) public view returns (bool){
        // returns true/false of an address with idx
        if (addr == logs[idx].owner){
            return true;
        }
        else{
            return false;
        }
    }


    function get_idx_from_identifier(uint identifier) public view returns (uint){
        // get the id of a log given an identifier
        require(!identifier_is_unused(identifier), "ERROR: Identifier does not exist");
        for (uint256 idx = 0; idx < logs.length; idx++) {
            if (logs[idx].identifier == identifier){
                return idx;
            }
        }
        return 0;
    }

    function identifier_is_unused(uint identifier) public view returns (bool){
        // check if the identifier is already in use
        for (uint256 idx = 0; idx < logs.length; idx++) {
            if (logs[idx].identifier == identifier){
                return false;
            }
        }
        return true;
    }

    function get_number_of_logs() public view returns (uint){
        // returns the number of logs
        return logs.length;
    }

    function deploy_log(uint identifier) public payable{
        // deploys an auction
        require(identifier_is_unused(identifier), "ERROR: Identifier is already used");
        uint idx = logs.length;
        logs.push();
        Log storage new_log = logs[idx];
        // add data to blockchain
        new_log.owner = msg.sender;
        new_log.identifier = identifier;
        emit LogDeployed(msg.sender, idx, identifier);
    }


    function deposit_money(uint idx) public payable returns (uint){
        // Deposit money in order to be able to participate
        logs[idx].deposit[msg.sender] += msg.value;
        logs[idx].users.push(msg.sender);
        emit DepositEvent(msg.sender, msg.value, idx);
        return logs[idx].deposit[msg.sender];
    }

    function get_deposit_balance(uint idx) public view returns (uint){
        // gets the deposit balances of users
        return logs[idx].deposit[msg.sender];
    }

    function set_metric(uint idx, uint value) public {
        // sets the metric, requirements have to be fulfilled 
        require(msg.sender != logs[idx].owner, "ERROR: The owner can not log on his/her auction");
        require(logs[idx].deposit[msg.sender]>=0.1 ether, "ERROR: Deposit is not enough (at least 0.1 ETH)");
        require(value > logs[idx].metric[msg.sender], "ERROR: Value has to be higher than previous value");
        logs[idx].metric[msg.sender] = value;
     
        emit LogEvent(msg.sender, idx, block.number, value);
    }

    function get_metric(uint idx) public view returns (uint){
        // returns last/highest log of user
        return logs[idx].metric[msg.sender];
    }


    function refund_deposit(uint idx) public {
        // refund the deposit if logging is not active or if time is over
        require(logs[idx].deposit[msg.sender] > 0, "ERROR: The Sender does not have any deposit");
        payable(msg.sender).transfer(logs[idx].deposit[msg.sender]);
        logs[idx].deposit[msg.sender] = 0;
    }

    function kill() public {
        require(msg.sender == admin, "Only the contract owner can kill the contract, sorry.");
        selfdestruct(admin);
    }


}