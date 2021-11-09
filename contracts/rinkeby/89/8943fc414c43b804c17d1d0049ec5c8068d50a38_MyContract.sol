/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

pragma solidity ^0.8.9;


contract MyContract {

    address payable owner;
    uint256 jackpot;
    uint256 randNonce = 0;
    uint256 range = 100;
    uint256 ticketPrice = 1000000000000000000;

    modifier _ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        jackpot = random();
    }


    function buyTicket() public payable returns(uint256){
        if(msg.value >= ticketPrice) {
            uint256 genRand = random();
            if (genRand == jackpot) {
                address payable caller = payable(msg.sender);
                caller.transfer(address(this).balance / 2);
                owner.transfer(address(this).balance);
                jackpot = random();

            }
            return genRand;
        }
        revert();
    }

    function getBalance() public _ownerOnly view returns(uint256) {
        return address(this).balance;
    }

    function random() internal returns(uint256) {
        randNonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % (range + 1);
    }

    function setTicketPrice(uint256 newPrice) public _ownerOnly {
        ticketPrice = newPrice;
    }

    function getTicketPrice() public view returns(uint256) {
        return ticketPrice;
    }

    function setRange(uint256 newRange) public _ownerOnly {
        range = newRange;
        jackpot = random();
    }

    function getRange() public _ownerOnly view returns(uint256) {
        return range;
    }

    function getJackpot() public view returns(uint256) {
        return jackpot;
    }

}