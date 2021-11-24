/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity ^0.4.20;
contract read {

string word;

constructor() public{
word = "Hello Word";
}

function changeWord (string _word) public payable returns(bool) {
word = _word;
return true;

}
function readWord () public view returns(string) {
return word;
}
}