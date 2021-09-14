/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity ^0.8.0;

contract osaisenBOX {

    address public owner;
    string[] negai;
    uint[] osaisen;
    address[] sanpaisha;
    uint public sanpaisuu;
    string public jinja_name;

    function omairi(string memory _negai) public payable {
        osaisen.push(msg.value);
        sanpaisha.push(msg.sender);
        negai.push(_negai);
        sanpaisuu = sanpaisuu + 1;
    }

    function checknegai(uint _num) public view returns(string memory){
        return negai[_num];
    }

    function checkOsaisen(uint _num) public view returns(uint){
        return osaisen[_num];
    }

    function checksanpaisha(uint _num) public view returns(address){
        return sanpaisha[_num];
    }

    function checkRecentNegai() public view returns(string memory){
        return negai[sanpaisuu-1];
    }

    function checkRecentOsaisen() public view returns(uint){
        return osaisen[sanpaisuu-1];
    }

    function checkRecentSanpaisha() public view returns(address){
        return sanpaisha[sanpaisuu-1];
    }

    function withdraw() public {
        require(msg.sender == owner);
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    constructor(string memory _jinjaname)  {
        jinja_name = _jinjaname;
        owner = msg.sender;
    } 
}