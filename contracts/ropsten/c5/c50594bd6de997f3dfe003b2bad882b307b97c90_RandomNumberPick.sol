pragma solidity ^0.4.24;
contract RandomNumberPick {

    event number(uint randomnumber);
    uint8 randomNum;
    mapping(address => uint) ifpaid;


    function () private payable { 
        ifpaid[msg.sender] += msg.value*1000000000000000000;
    } //fallback function

    function random() public {
        require(this.balance >= 4 ether);
        require (ifpaid[msg.sender] >=1000000000000000000);
    
      randomNum = uint8(uint256(keccak256(block.timestamp, block.number))%3);
      randomNum +=1;
      emit number(randomNum);

      if (randomNum == 1){
        msg.sender.transfer(2 ether);
        }
    ifpaid[msg.sender] -= 1000000000000000000;

    }    
    function returnrandom() public view returns(uint8 _rand){
        return randomNum;
    }
}