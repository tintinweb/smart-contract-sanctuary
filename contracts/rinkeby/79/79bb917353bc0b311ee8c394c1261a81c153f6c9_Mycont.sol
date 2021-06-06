pragma solidity 0.5.1;
import "./projecttest.sol";

contract Mycont{
person[] public people;
parties_record[] public information;
//afterpurchace_record[] public human_1;

uint public peoplecount;

//uint public selltoken;
uint public buytoken;

//uint256 public number_of_item;
mapping(address=>uint) public number_of_item;
mapping(address=>uint) public bought_item;

mapping(address=>string) public  name_of_item;
address bazzarmaintainer;
address InpartyA;
address InpartyB;
address InpartyC;
address CpartyA;
address CpartyB;
address CpartyC;
address Currentcontractaddress;
//address payable wallet;
address public lastbuyer;
//uint selltoken;
constructor(address partyA,address partyB,address partyC) public {
    bazzarmaintainer=msg.sender;
    InpartyA=partyA;
    InpartyB=partyB;
    InpartyC=partyC;
 
    Currentcontractaddress=address(this);
}
struct person{
    string  first_name;
    string last_name;
    uint256 id;
}
struct parties_record {
    uint number_of_item_party_having;
    string  name_of_item_party_having;
}
struct transaction_record {
    uint numbers_of_items_exchange;
    string name_of_item_exchange;
}

mapping(uint => transaction_record[]) public transpartyA;
mapping(uint => transaction_record[]) public transpartyB;
mapping(uint => transaction_record[]) public transpartyC;

/*
struct afterpurchace_record{
    uint valu1;
    string valu2;
}
*/


function addperson(string memory _firstname,string memory _lastname,uint256 val,uint val1,string memory itemname) public {
    if (msg.sender == InpartyA) {
    
    people.push(person(_firstname,_lastname,val));
/*    struct data{
        uint value1;
        string value2;
    }*/
    number_of_item[InpartyA]=items.itemA(val1);
    //number2_of_item[InpartyA]=items.itemA(val1);
    name_of_item[InpartyA]=items.itemB(itemname);
    information.push(parties_record(number_of_item[InpartyA],name_of_item[InpartyA]));
    peoplecount++;
    }
    if(msg.sender==InpartyB){
    people.push(person(_firstname,_lastname,val));
/*    struct data{
        uint value1;
        string value2;
    }*/
    number_of_item[InpartyB]=items.itemA(val1);
    //number2_of_item[InpartyB]=items.itemA(val1);
    name_of_item[InpartyB]=items.itemB(itemname);
    information.push(parties_record(number_of_item[InpartyB],name_of_item[InpartyB]));
    peoplecount++; 
    }
    if(msg.sender==InpartyC){
           people.push(person(_firstname,_lastname,val));

    number_of_item[InpartyC]=items.itemA(val1);
    //number2_of_item[InpartyC]=items.itemA(val1);
    name_of_item[InpartyC]=items.itemB(itemname);
    information.push(parties_record(number_of_item[InpartyC],name_of_item[InpartyC]));
    peoplecount++;} 
    return;
    }
    
function buynsell(address payable _To,uint _transid,uint _ibuy,string memory _name) payable public {
    require(peoplecount>=2);
    
    
    if(msg.sender == InpartyA){
       if(_To==InpartyC && number_of_item[InpartyC] >= _ibuy){
       transpartyA[_transid].push(transaction_record(_ibuy,_name));
      _To.transfer(msg.value);
       number_of_item[_To] = number_of_item[_To] - _ibuy;
       bought_item[msg.sender]=bought_item[msg.sender] +_ibuy;
       buytoken+=_ibuy;
     }
       if(_To==InpartyB && number_of_item[InpartyB] > _ibuy){
         transpartyA[_transid].push(transaction_record(_ibuy,_name));
         _To.transfer(msg.value);
         number_of_item[_To] = number_of_item[_To] - _ibuy;
         bought_item[msg.sender]=bought_item[msg.sender] +_ibuy;
         buytoken+=_ibuy;
     }  
  
     }
     if(msg.sender == InpartyB){
       if(_To==InpartyC && number_of_item[InpartyC] > _ibuy){
         transpartyB[_transid].push(transaction_record(_ibuy,_name));
        _To.transfer(msg.value);
         number_of_item[_To] = number_of_item[_To] - _ibuy;
         bought_item[msg.sender]=bought_item[msg.sender] +_ibuy;
         buytoken+=_ibuy;
     }
       if(_To==InpartyA && number_of_item[InpartyA] > _ibuy){
         transpartyB[_transid].push(transaction_record(_ibuy,_name));
         _To.transfer(msg.value);
         number_of_item[_To] = number_of_item[_To] - _ibuy;
         bought_item[msg.sender]=bought_item[msg.sender] +_ibuy;
         buytoken+=_ibuy;
     }  
     }
     
     
    if(msg.sender == InpartyC){
      if(_To == InpartyB && number_of_item[InpartyB]>_ibuy){    
      transpartyC[_transid].push(transaction_record(_ibuy,_name));
     _To.transfer(msg.value);
    
     number_of_item[_To] = number_of_item[_To] - _ibuy;
     bought_item[msg.sender]=bought_item[msg.sender] +_ibuy;
     buytoken+=_ibuy;
     }
     if(_To==InpartyA && number_of_item[InpartyA] > _ibuy){
      transpartyC[_transid].push(transaction_record(_ibuy,_name));
      _To.transfer(msg.value);
    
      number_of_item[_To] = number_of_item[_To] - _ibuy;
      bought_item[msg.sender]=bought_item[msg.sender] +_ibuy;
      buytoken+=_ibuy;
     }
     }
}
}