pragma solidity ^0.4.23;


//1,45 left. -*-*-*-*- 45 55 programmer. -*-*-*-*-*-upper 35 right.
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Cryptoraces {


  using SafeMath for uint;
  uint256 maximumBalance;
  uint256 rewardnumber;
  address private manager;
  uint minimumBet;
  //address public listofwinners;
  //address public listoflosers;

  struct raceDetails {
      uint time;
      uint luckNumber;
      uint horseType;
  }

  mapping (address => raceDetails) members;

  address[] private listofUsers;


  constructor() public {
      manager = msg.sender;
  }


    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, block.timestamp, now));
    }



  function enter(uint256 leftorright) public payable {

      if(leftorright == 1) {
        maximumBalance = getMaximumBetRate();
        require(msg.value < maximumBalance && msg.value > .001 ether,"Your bet is too high!");

        rewardnumber = randomtests();
        if(rewardnumber < 45){
            msg.sender.transfer(msg.value.mul(2));
            members[msg.sender].time = now;
            members[msg.sender].luckNumber = rewardnumber;
            members[msg.sender].horseType = leftorright;
            listofUsers.push(msg.sender) -1;
        } else {

          members[msg.sender].time = now;
          members[msg.sender].luckNumber = rewardnumber;
          members[msg.sender].horseType = leftorright;
          listofUsers.push(msg.sender) -1;
        }
      } else {
        maximumBalance = getMaximumBetRate();
        require(msg.value < maximumBalance && msg.value > .001 ether,"Your bet is too high or low");

        rewardnumber = randomtests();
        if(rewardnumber > 55){
            msg.sender.transfer(msg.value.mul(2));

            members[msg.sender].time = now;
            members[msg.sender].horseType = leftorright;
            members[msg.sender].luckNumber = rewardnumber;
            listofUsers.push(msg.sender) -1;
        } else {

          members[msg.sender].time = now;
          members[msg.sender].horseType = leftorright;
          members[msg.sender].luckNumber = rewardnumber;
          listofUsers.push(msg.sender) -1;
        }
      }
    }

function getMaximumBetRate() public view returns(uint256){
    return address(this).balance.div(20);
  }


  function randomtests() private view returns(uint256){
    uint256 index = random() % 100;
    return index;
  }

  function getAccounts() view public returns(address[]) {
      return listofUsers;
  }

  function numberofGamePlay() view public returns (uint) {
      return listofUsers.length;
  }

  function uint2str(uint i) internal pure returns (string){
    if (i == 0) return "0";
    uint j = i;
    uint length;
    while (j != 0){
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (i != 0){
        bstr[k--] = byte(48 + i % 10);
        i /= 10;
    }
    return string(bstr);
}






  function getAccDetails(address _address) view public returns (string, string, string ,string) {


    if(members[_address].time == 0){
            return ("0", "0", "0", "You have never played this game before");
    } else {

      if(members[_address].horseType == 1) {

       if(rewardnumber < 45){
           return (uint2str(members[_address].time), uint2str(members[_address].luckNumber), uint2str(members[_address].horseType), "You Win because your number smaller than 45");

       } else {
           return (uint2str(members[_address].time), uint2str(members[_address].luckNumber),uint2str(members[_address].horseType), "youre lose  because your number bigger than 45");
       }
     } else {

       if(rewardnumber > 55){
           return (uint2str(members[_address].time), uint2str(members[_address].luckNumber),uint2str(members[_address].horseType), "You win, because your number bigger than 55");
       } else {
         return (uint2str(members[_address].time), uint2str(members[_address].luckNumber),uint2str(members[_address].horseType), "You lose because your number smaller than 55");
       }
     }


    }
  }





  function getEthBalance() public view returns(uint) {
    return address(this).balance;
 }


  function depositEther() public payable returns(uint256){
     require(msg.sender == manager,"only manager can reach  here");
    return address(this).balance;
  }

  function withDrawalether(uint amount) public payable returns(uint256){
      require(msg.sender == manager,"only manager can reach  here");
      manager.transfer(amount*1000000000000000); // 1 etherin 1000&#39; de birini g&#246;nderebilir.
      return address(this).balance;
  }

}