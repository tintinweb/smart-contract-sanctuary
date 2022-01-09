/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Macroon {
    /* Methods:
    // Internal setThirdParty(ArrayList<addr> : 0x3242543520)
    // Internal setSecondParty(addr: 0x324235) || looks like not reqd
    // View fetchSpendable() -> uint256
    // View viewMerchants() -> ArrayList<addr>
    // Transact spend() -> bool success
    */

    //we deploy first and fund later.
    address private creator;
    address private spender;
    uint256 private amount;
    mapping(address => uint256) public spentByAddr;
    address[] public addressPayable;

    constructor(address _spender) {
        require(
            _spender != address(0),
            "Cannot throw ether to sink in this contract"
        );
        creator = msg.sender;
        spender = _spender;
        amount = 0;
    }

    function fund() public payable returns (bool success) {
        require(msg.value > 0, "Please pay some money...");
        amount += msg.value;
        success = true;
    }

    function spendable() public view returns (uint256) {
        return amount;
    }

    function addThirdParty(address[] memory addressParty3)
        public
        returns (bool success)
    {
        for (uint256 index = 0; index < addressParty3.length; index++) {
            if (spentByAddr[addressParty3[index]] != 1) {
                spentByAddr[addressParty3[index]] = 1;
                addressPayable.push(addressParty3[index]);
            } else {
                continue;
            }
        }
        success = true;
    }
}