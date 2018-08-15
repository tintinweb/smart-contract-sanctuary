pragma solidity ^0.4.24;

contract lucky9io {
    bool private gameOn = true;
    address private owner = 0x5Bf066c70C2B5e02F1C6723E72e82478Fec41201;
    uint private entry_number = 0;
    uint private value = 0;

    modifier onlyOwner() {
     require(msg.sender == owner, "Sender not authorized.");
     _;
    }

    function stopGame() public onlyOwner {
      gameOn = false;
      owner.transfer(address(this).balance);
    }

    function () public payable{
        if(gameOn == false) {
            msg.sender.transfer(msg.value);
            return;
        }

        if(msg.value * 1000 < 9) {
            msg.sender.transfer(msg.value);
            return;
        }

        entry_number = entry_number + 1;
        value = address(this).balance;

        if(entry_number % 999 == 0) {
            msg.sender.transfer(value * 8 / 10);
            owner.transfer(value * 11 / 100);
            return;
        }

        if(entry_number % 99 == 0) {
            msg.sender.transfer(0.09 ether);
            owner.transfer(0.03 ether);
            return;
        }

        if(entry_number % 9 == 0) {
            msg.sender.transfer(0.03 ether);
            owner.transfer(0.01 ether);
            return;
        }
    }
}