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
    mapping (uint256 => mapping (address => User)) public userDetails;
    
    event CashbackAdded(string name, address indexed wallet);
    event CashbackReceived(address indexed wallet,uint256 cashback);

    // "Anurag Makol","0x356233346361363663306461393137653830663639366161","0x14723a09acff6d2a60dcdf7aa4aff308fddc160c",["0xDE0B6B3A7640000","0x1BC16D674EC80000","0x29A2241AF62C0000"],[1529476151,1529478151,1529496151]
    function addCashback(string name,uint256 identifier,address wallet,uint256[] cashbackAmount,uint256[] cashbackTime) public onlyOwner returns (bool success) {
        userDetails[identifier][wallet].name = name;
        userDetails[identifier][wallet].wallet = wallet;
        userDetails[identifier][wallet].cashbackAmount1 = cashbackAmount[0];
        userDetails[identifier][wallet].cashbackTime1 = cashbackTime[0];
        userDetails[identifier][wallet].cashbackPaid1 = false;
        userDetails[identifier][wallet].cashbackAmount2 = cashbackAmount[1];
        userDetails[identifier][wallet].cashbackTime2 = cashbackTime[1];
        userDetails[identifier][wallet].cashbackPaid2 = false;
        userDetails[identifier][wallet].cashbackAmount3 = cashbackAmount[2];
        userDetails[identifier][wallet].cashbackTime3 = cashbackTime[2];
        userDetails[identifier][wallet].cashbackPaid3 = false;

        emit CashbackAdded(name, wallet);
        return true;
    }

    // "0x356233346361363663306461393137653830663639366161","0x14723a09acff6d2a60dcdf7aa4aff308fddc160c"
    function receiveCashback(uint256 identifier, address wallet) public returns (bool success) {
        if(userDetails[identifier][wallet].cashbackTime1 < now && userDetails[identifier][wallet].cashbackPaid1 == false) {
            wallet.transfer(userDetails[identifier][wallet].cashbackAmount1);
            userDetails[identifier][wallet].cashbackPaid1 = true;
            emit CashbackReceived(wallet, userDetails[identifier][wallet].cashbackAmount1);
        } else if (userDetails[identifier][wallet].cashbackTime2 < now && userDetails[identifier][wallet].cashbackPaid2 == false) {
            wallet.transfer(userDetails[identifier][wallet].cashbackAmount2);
            userDetails[identifier][wallet].cashbackPaid2 = true;
            emit CashbackReceived(wallet, userDetails[identifier][wallet].cashbackAmount2);
        } else if(userDetails[identifier][wallet].cashbackTime3 < now && userDetails[identifier][wallet].cashbackPaid3 == false) {
            wallet.transfer(userDetails[identifier][wallet].cashbackAmount3);
            userDetails[identifier][wallet].cashbackPaid3 = true;
            emit CashbackReceived(wallet, userDetails[identifier][wallet].cashbackAmount3);
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