/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

pragma solidity >=0.7.0 <0.9.0;

contract Kudo
{mapping(address=>Kudos[]) allkudo;
 
 function givekudos(string memory Tech,address who,string memory review) public {
     Kudos memory kud=Kudos(Tech,msg.sender,review);
     allkudo[who].push(kud);

    }
 function getkudoslength(address who) public view returns(uint){
    return allkudo[who].length;
    }
  function getkudo(address who,uint idx) public view returns(string memory ,address,string memory)
  {  Kudos memory kud=allkudo[who][idx];
      return (kud.tech,kud.giver,kud.review);

  }


}

struct Kudos
{ string tech;
  address giver;
  string review;

}