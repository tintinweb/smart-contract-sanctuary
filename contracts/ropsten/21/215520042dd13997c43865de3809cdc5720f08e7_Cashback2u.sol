pragma solidity ^0.4.23;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
}

contract Cashback2u is owned {

    struct User {
        string name;
        address wallet;
        uint256 cashbackAmount1;
        uint256 cashbackTime1;
        bool cashbackPaid1;
        uint256 cashbackAmount2;
        uint256 cashbackTime2;
        bool cashbackPaid2;
        uint256 cashbackAmount3;
        uint256 cashbackTime3;
        bool cashbackPaid3;
    }

    uint public balance;
    mapping(address => User) public userDetails;

    // &quot;Anurag Makol&quot;,&quot;0x14723a09acff6d2a60dcdf7aa4aff308fddc160c&quot;,[&quot;0xDE0B6B3A7640000&quot;,&quot;0x1BC16D674EC80000&quot;,&quot;0x29A2241AF62C0000&quot;],[1529476151,1529478151,1529496151]
    function addCashback(string name,address wallet,uint256[] cashbackAmount,uint256[] cashbackTime) public onlyOwner returns (bool success) {
        userDetails[wallet].name = name;
        userDetails[wallet].wallet = wallet;
        userDetails[wallet].cashbackAmount1 = cashbackAmount[0];
        userDetails[wallet].cashbackTime1 = cashbackTime[0];
        userDetails[wallet].cashbackPaid1 = false;
        userDetails[wallet].cashbackAmount2 = cashbackAmount[1];
        userDetails[wallet].cashbackTime2 = cashbackTime[1];
        userDetails[wallet].cashbackPaid2 = false;
        userDetails[wallet].cashbackAmount3 = cashbackAmount[2];
        userDetails[wallet].cashbackTime3 = cashbackTime[2];
        userDetails[wallet].cashbackPaid3 = false;

        return true;
    }

    // &quot;0x14723a09acff6d2a60dcdf7aa4aff308fddc160c&quot;
    function receiveCashback(address wallet) public returns (bool success) {
        if(userDetails[wallet].cashbackTime1 < now && userDetails[wallet].cashbackPaid1 == false) {
            wallet.transfer(userDetails[wallet].cashbackAmount1);
            userDetails[wallet].cashbackPaid1 = true;
        } else if (userDetails[wallet].cashbackTime2 < now && userDetails[wallet].cashbackPaid2 == false) {
            wallet.transfer(userDetails[wallet].cashbackAmount2);
            userDetails[wallet].cashbackPaid2 = true;
        } else if(userDetails[wallet].cashbackTime3 < now && userDetails[wallet].cashbackPaid3 == false) {
            wallet.transfer(userDetails[wallet].cashbackAmount3);
            userDetails[wallet].cashbackPaid3 = true;
        } else {
            revert();
        }

        balance = address(this).balance;
        return true;
    }

    function () payable public {
        balance = address(this).balance;
    }

}