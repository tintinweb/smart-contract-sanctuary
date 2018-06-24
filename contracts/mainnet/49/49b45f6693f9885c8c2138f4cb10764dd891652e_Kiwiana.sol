pragma solidity ^0.4.24;

contract Kiwiana {
    address public owner;
    mapping (address => uint) public payments;
    mapping (address => string) public allergies;
    address public chris = 0xC369B30c8eC960260631E20081A32e4c61E5Ea9d;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function () external payable {
        register(msg.sender);
    }

    function register(address _attendee) public payable returns(bool) {
        uint weiAmount = msg.value;
        if(weiAmount >= 100000000000000000) {
            payments[_attendee] = weiAmount;
            return true;
        }
        else {
            // you didn&#39;t pay enough, so we&#39;re just swallowing how much you spent
            return false;
        }
    }

    function isEatingAndDrinking(address __attendee) public view returns(bool) {
        if(payments[__attendee] >= 150000000000000000) {
            return true;
        }
        return false;
    }

    function isEating(address __attendee) public view returns(bool) {
        if(payments[__attendee] >= 100000000000000000) {
            return true;
        }
        return false;
    }

    function allergy(string _description) public payable returns(bool) {
        if(payments[msg.sender] >= 100000000000000000) {
            // you paid so we care about your allergies
            allergies[msg.sender] = _description;
            return true;
        }
        return false;
    }

    function giveMeBackMyMoney() public onlyOwner {
        //send all money to chris
        chris.transfer(address(this).balance);
    }
}