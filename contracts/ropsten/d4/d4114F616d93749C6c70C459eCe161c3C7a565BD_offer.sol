/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
//import "./tools.sol";
 library to{

function merge_string(bytes memory a,bytes memory b) public pure returns(string memory){
          uint len=(a.length)+(b.length);
        bytes memory merge = new bytes (len); 
        for (uint i=0;i < a.length;i++)
              merge[i]=a[i];
        for (uint i=0;i < b.length;i++)
               merge[i+a.length]=b[i];

 string memory _merge =string(merge);
     return(_merge);
}

function concatStrings(string memory a, string memory b) 
        internal pure returns(string memory) {
        bytes memory sa = bytes(a);
        bytes memory sb = bytes(b);
        uint len = sa.length + sb.length;
        bytes memory sc = new bytes(len);
        uint i;
        for (i=0; i < sa.length; i++)
            sc[i] = sa[i];
        for (i=0; i < sb.length; i++)
            sc[i+sa.length] = sb[i];
        return(string(sc));  
    } 


function concatStrings(string memory a, string memory b, string memory c) 
        internal pure returns(string memory) {
       return(concatStrings(concatStrings(a,b),c));
 }
 
function concatStrings(string memory a, string memory b, string memory c,string memory d) 
        internal pure returns(string memory) {
       return(concatStrings(concatStrings(a,b),concatStrings(c,d)));
 }

 /////////////////////////////////////////////////////////////////// functions add2str
 function add2str(address x) public pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
}

function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
}
/////////////////////////////////////////////////////////////////////////////

// function uint2str(uint a) internal pure returns(string memory) {
//         uint8 b;
//         string memory str = "";
//         byte c;
//         bytes memory d = new bytes(1);
//         do {
//             b = uint8(a % 10);
//             c = byte(b + 48);
//             d[0] = c; //2781 2781
//             str = concatStrings(string(d),str);
//             a /= 10;
//         } while (a > 0);
//         return(str);
//     }
function uint2str_v8( uint256 _i) internal pure returns (string memory str){
  if (_i == 0)
  {
    return "0";
  }
  uint256 j = _i;
  uint256 length;
  while (j != 0)
  {
    length++;
    j /= 10;
  }
  bytes memory bstr = new bytes(length);
  uint256 k = length;
  j = _i;
  while (j != 0)
  {
    bstr[--k] = bytes1(uint8(48 + j % 10));
    j /= 10;
  }
  str = string(bstr);
}
    // function stringToUint(string memory s) public  returns (uint result) {
    //     bytes memory b = bytes(s);
    //     uint i;
    //     result = 0;
    //     for (i = 0; i < b.length; i++) {
    //         uint c = uint(b[i]);
    //         if (c >= 48 && c <= 57) {
    //             result = result * 10 + (c - 48);
    //         }
    //     }
    // }


 function compare (string memory a , string memory b )internal pure returns(bool){
 if (bytes(a).length != bytes(b).length)
   return (false);
    for (uint i=0; i<bytes(a).length;i++){
        if (bytes(a)[i] != bytes (b)[i])    
          return (false); 
    }
    return(true);
 }
//raveshe do jaleb nis
function compare_2 (string memory a , string memory b )internal pure returns(bool){
    require(bytes(a).length == bytes(b).length);
    for (uint i=0; i<bytes(a).length;i++){
         require(bytes(a)[i] == bytes (b)[i]);
}
return(true);
}


// function greater_equality(uint a, uint b) public pure returns(string memory){
// if (a>=b)
// return (concatStrings(uint2str(a), ">" ,uint2str(b)));
// else
// return (concatStrings(uint2str(b), ">" ,uint2str(a)));
// }
 



 

// function sort(uint a, uint b,uint c) public pure returns(uint){
// return (sort(sort(a,b),c));

// }


 }

contract offer {
                                     // jori benevisim ke ba ye contract betavan haraji haye ziyadi ra bar gozar kard.
address owner; 
address payable top_pricer;
uint[] id_in;
uint top_price;
uint duration_time;   //mitavan zamanbandi ezafe krd
struct info {
    uint value;
    uint id; //mitavan id ra be sorate hash dar avard va az an estefade kard be onvane pass;
}
mapping(address=>info)public Recommender;


constructor (){
    owner=msg.sender;
    top_price=1 ether;
}

function _offer(uint _id )external payable returns  (string memory ){
require(_id != 0,"id khod ra vared konid(adade 0 ra vared nakonid)");
require(Recommender[msg.sender].value + msg.value > top_price ,"gheymate varede kam tar az hade aksare gheymat ast." );
if(Recommender[msg.sender].id==0){
   for(uint i=0;i<id_in.length;i++)
      require(_id!=id_in[i],"id entekhab shode tekrari ast,id jadid vared konid.");
Recommender[msg.sender].id=_id;
id_in.push(_id);}
if(Recommender[msg.sender].id==_id){
Recommender[msg.sender].value+=msg.value;
top_price=Recommender[msg.sender].value;
top_pricer=payable(msg.sender);
return "gheymate shoma sabt shod.dar meneuye information mitavanid akharin vaziyate afrdae barande ra bebinid.";
}
revert ("id khod ra sahih vared konid.");
}


function informatin()external view returns(string memory){
    string memory str;
str=to.concatStrings("ta in lahze balatarin ghemate pishnagad shode :",to.uint2str_v8(top_price),"|id pishnahad dahande:",to.uint2str_v8(Recommender[top_pricer].id));
return str;
}
function easy_calq4pay(uint offer_up)external view returns(uint){

}
function receiving_money(uint _id)external {
uint pay=Recommender[msg.sender].value;
require (pay>0);
require (Recommender[msg.sender].id==_id,"in id motaelegh be in address nist");
require (pay<top_price,"shoma ta in lahze barande shodid nemitavanid pol khod ra bardasht konid");
Recommender[msg.sender].value=0;
payable(msg.sender).transfer(pay);
}

function start_offer()public{

}

function end_offer()public{
    
}



}