/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Macroon {
    /// REQUIRE SPENDER
    /* Methods:
    // Internal setThirdParty(ArrayList<addr> : 0x3242543520)
    // Internal setSecondParty(addr: 0x324235) || looks like not reqd
    // View fetchSpendable() -> uint256
    // View viewMerchants() -> ArrayList<addr>
    // Transact spend() -> bool success
    */

    //we deploy first and fund later.
    address private spender;
    uint256 private amount;
    uint256 public expiryDate; //it is in UTC
    address payable public deployer; //this is the address of the person who deployed the contract
    mapping(address => bool) private payableOrNot; //addresses vs money spent
    address[] public addressPayable; //addresses where we can pay
    string private remarks = "";
    bool public sendToOwnerOnExpire;

    struct funder {
        address whoFunded;
        uint256 amountFunded;
    }
    funder[] public funders;

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
        spender = _spender;
        deployer = payable(msg.sender);
        expiryDate = _expiryDate;
        amount = msg.value;
        funders.push(funder(msg.sender, msg.value));
        remarks = _remarks;
        sendToOwnerOnExpire = _sendToOwnerOnExpire;
        addThirdParty(addressParty3);
    }

    function getRemarks() public view returns (string memory) {
        require(
            msg.sender == deployer || msg.sender == spender,
            "Unauthorized to see remarks"
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
        require(!isExpired(), "Contract has expired");
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
        require(!isExpired(), "Contract has expired");
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
        require(!isExpired(), "Contract has expired");
        require(
            amountToPay <= address(this).balance && amountToPay > 0,
            "Invalid amount"
        );

        require(payableOrNot[_recipient] == true, "Cannot pay to this address");

        //amount to pay is in MATIC/ETH atm
        _recipient.transfer(amountToPay);
        success = true;
    }

    function expiredContractRefund() public returns (bool) {
        // require(msg.value == 0, "Cannot send money to this contract anymore"); ||auto refunded anyways
        require(isExpired(), "Contract has not expired");
        require(address(this).balance > 0, "No money left in contract");
        deployer.transfer(address(this).balance);
        amount = 0;
        return true;
    }
}