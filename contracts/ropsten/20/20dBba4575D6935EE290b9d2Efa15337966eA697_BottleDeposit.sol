// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// Simple bottle deposit contract
contract BottleDeposit {
    
    struct Bottle {
        string name;
        uint volume;
        uint price;
        uint deposit;
        bool depositPaid;
    }
    
    // Currently available bottles
    Bottle[] public shop;
    
    // Who payed deposit for which bottle
    mapping (uint => address) public depositsPaid;
    
    // Pull payments mapping
    mapping (address => uint) public withdrawals;
    
    modifier checkBottle(uint _id, bool depositPaid) {
        require(_id <= shop.length - 1, "Incorrect Id!");
        
        string memory message;
        if (depositPaid) {
            message = "No deposit for this bottle paid!";
        }else {
            message = "Deposit already paid!";
        }
        
        require(shop[_id].depositPaid == depositPaid, message);
        _;
    }
    
    // Adds three default bottles to the store
    constructor () {                                                            
        shop.push(Bottle("Glenmorangie", 70, 1 ether, 0.1 ether, false));
        shop.push(Bottle("Beluga", 70, 0.5 ether, 0.1 ether, false));
        shop.push(Bottle("Jack Daniels", 70, 0.5 ether, 0.1 ether, false));
    }
    
    function payDeposit(uint _id) external payable checkBottle(_id, false) {
        require(msg.value == shop[_id].deposit, "Incorrect deposit sent!");
        shop[_id].depositPaid = true;
        depositsPaid[_id] = msg.sender;
    }
    
    function returnBottle(uint _id) external checkBottle(_id, true) {
        // original buyer
        if (msg.sender == depositsPaid[_id]) {
            withdrawals[msg.sender] += shop[_id].deposit;
        } else {
            withdrawals[msg.sender] += shop[_id].deposit / 2;
            withdrawals[depositsPaid[_id]] += shop[_id].deposit / 2;
        }
        
        // Cleanup
        depositsPaid[_id] = address(0);
        shop[_id].depositPaid = false;
        
    }
    
    // Basic pull payment function for withdrawals
    function withdraw() public {
        
        uint amount = withdrawals[msg.sender];
        
        require(amount > 0, "No withdrawals available!");
        require(address(this).balance >= amount, "Not enough tokens on contract");
        
        withdrawals[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");                  // solhint-disable-line
        require(success, "Transfer of deposit failed!");
        
    }

}