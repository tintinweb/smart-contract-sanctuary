/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity >=0.4.21 <0.6.0;
contract Words {
//誓言数据结构
struct Item {
string what;
address who;
uint when;
}
//记录所有的誓言数据
Item[ ] private allWords;
//将数据存储在区块链上
function save(string memory s, uint t) public {
allWords.push(Item ({
what: s,
who: msg.sender,
when: t
}));
}
//查询当前誓言的总条数
function getSize( ) public view returns (uint) {
return allWords.length;
}
//根据编号查询誓言的具体内容
function getRandom (uint random) public view returns (string memory, address, uint) {
if(allWords.length==0) {
return("", msg.sender, 0);
}else{
Item storage result = allWords [random];
return (result.what, result.who, result.when);
}
}
}