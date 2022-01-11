/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Macaroon {
    /* Methods:
    // read below
    */

    //we deploy first and fund later.
    address payable private spender; //second party
    uint256 private amount; //amount left in contract
    uint256 private expiryDate; //it is in UTC
    address payable public deployer; //this is the address of the person who deployed the contract
    mapping(address => bool) public payableOrNot; //checks if payable or not
    address[] private addressPayable; //addresses where we can pay
    string private remarks = ""; //remarks for contract
    bool public sendToOwnerOnExpire;

    struct funder {
        address whoFunded;
        uint256 amountFunded;
    }
    funder[] private funders;

    constructor(
        address _spender,
        uint256 _expiryDate,
        string memory _remarks,
        bool _sendToOwnerOnExpire,
        address[] memory addressParty3
    ) payable {
        //contract not funded yet. Call fund method in front OR
        //this contract can have += value
        require(_spender != address(0), "Can't send to sink");
        require(
            _expiryDate == 0 || _expiryDate > block.timestamp,
            "Invalid expiry date (use UNIX timestamp)"
        );
        // creator = msg.sender; // but here we are deploying the contract
        spender = payable(_spender);
        deployer = payable(msg.sender);
        expiryDate = _expiryDate;
        amount = msg.value;
        funders.push(funder(msg.sender, msg.value));
        remarks = _remarks;
        sendToOwnerOnExpire = _sendToOwnerOnExpire;
        addThirdParty(addressParty3);
    }

    function getExpiryOfContract() public view returns (uint256) {
        require(
            msg.sender == deployer || msg.sender == spender,
            "Unauthorized access"
        );
        return expiryDate;
    }

    function getAllPayable() public view returns (address[] memory) {
        require(
            msg.sender == deployer || msg.sender == spender,
            "Cannot all payable addresses"
        );
        return addressPayable;
    }

    function getRemarks() public view returns (string memory) {
        //allow everyone to see remarks (or completely remove funx)
        require(
            msg.sender == deployer || msg.sender == spender,
            "Cannot see remarks"
        );
        return remarks;
    }

    //create method fund and add address
    function isExpired() public view returns (bool) {
        if (expiryDate == 0) return false;
        if (block.timestamp > expiryDate) {
            return true;
        }
        return false;
    }

    function fund() public payable returns (bool success) {
        //anyone can fund the contract
        if (isExpired()) {
            expiredContractRefund();
            return false;
        }
        require(msg.value > 0, "Please pay some money...");
        funders.push(funder(msg.sender, msg.value));
        amount += msg.value;
        success = true;
    }

    function spendable() public view returns (uint256) {
        //returns amount that can be spent from the contract
        return amount;
    }

    function addThirdParty(address[] memory addressParty3)
        public
        returns (bool success)
    {
        require(msg.sender == deployer, "Unauthorized action for this user");
        if (isExpired()) {
            expiredContractRefund();
            return false;
        }
        // cannot add an address twice, obviously
        for (uint256 index = 0; index < addressParty3.length; index++) {
            if (payableOrNot[addressParty3[index]] == false) {
                payableOrNot[addressParty3[index]] = true;
                addressPayable.push(addressParty3[index]);
            } else {
                continue;
            }
        }
        success = true;
    }

    function payMoneyTo(address payable _recipient, uint256 amountToPay)
        public
        returns (bool success)
    {
        require(msg.sender == spender, "You cannot spend the money");
        if (isExpired()) {
            expiredContractRefund();
            return false;
        }
        require(
            amountToPay <= address(this).balance && amountToPay > 0,
            "Invalid amount"
        );

        require(payableOrNot[_recipient] == true, "Cannot pay to this address");

        //amount to pay is in MATIC/ETH atm
        _recipient.transfer(amountToPay);
        amount -= amountToPay;
        success = true;
    }

    function expiredContractRefund() public returns (bool) {
        // require(msg.value == 0, "Cannot send money to this contract anymore"); ||auto refunded anyways
        require(isExpired(), "Contract has not expired");
        require(
            address(this).balance > 0,
            "Reverting transactions, contract has expired"
        );
        if (sendToOwnerOnExpire) {
            deployer.transfer(address(this).balance);
        } else {
            spender.transfer(address(this).balance);
        }
        amount = 0;
        return true;
    }
}