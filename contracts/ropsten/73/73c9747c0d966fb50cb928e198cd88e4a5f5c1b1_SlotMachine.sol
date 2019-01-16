pragma solidity ^0.4.4;

contract SlotMachine {

    address public slotMachineFunds;

    uint256 public coinPrice = 0.01 ether;

    address owner;
    uint256 ownnerBalance=0;

    event Rolled(address sender, uint rand1, uint rand2, uint rand3);

    mapping (address => uint) pendingWithdrawals;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function SlotMachine() {
        owner = msg.sender;
    }

    //the user plays one roll of the machine putting in money for the win
    function oneRoll() payable {
        require(msg.value >= coinPrice);

        uint rand1 = randomGen(msg.value);
        uint rand2 = randomGen(msg.value + 10);
        uint rand3 = randomGen(msg.value + 20);
        ownnerBalance=msg.value*5/100;
        uint result = calculatePrize(msg.value*95/100,rand1, rand2, rand3);

        Rolled(msg.sender, rand1, rand2, rand3);

        pendingWithdrawals[msg.sender] += result;

    }

    function contractBalance() constant returns(uint) {
        return this.balance;
    }

    function calculatePrize(uint value,uint rand1, uint rand2, uint rand3) constant returns(uint) {
        if(rand1 == 5 && rand2 == 5 && rand3 == 5) {
            return value * 30;
        } else if (rand1 == 6 && rand2 == 6 && rand3 == 6) {
            return value * 10;
        } else if (rand1 == 4 && rand2 == 4 && rand3 == 4) {
            return value * 8;
        } else if (rand1 == 3 && rand2 == 3 && rand3 == 3) {
            return value * 6;
        } else if (rand1 == 2 && rand2 == 2 && rand3 == 2) {
            return value * 4;
        } else if (rand1 == 1 && rand2 == 1 && rand3 == 1) {
            return value * 3;
        } else if ((rand1 == rand2) || (rand1 == rand3) || (rand2 == rand3)) {
            return value*150/100;
        } else {
            return 0;
        }
    }

    function withdraw() {
        uint amount = pendingWithdrawals[msg.sender];

        pendingWithdrawals[msg.sender] = 0;

        msg.sender.transfer(amount);
    }

    function balanceOf(address user) constant returns(uint) {
        return pendingWithdrawals[user];
    }

    function setCoinPrice(uint _coinPrice) onlyOwner {
        coinPrice = _coinPrice;
    }

    function() onlyOwner payable {
    }

    function cashout(uint _amount) onlyOwner {
        msg.sender.transfer(_amount);
    }

    function randomGen(uint seed) private constant returns (uint randomNumber) {
        return (uint(sha3(block.blockhash(block.number-1), seed )) % 6) + 1;
    }

}