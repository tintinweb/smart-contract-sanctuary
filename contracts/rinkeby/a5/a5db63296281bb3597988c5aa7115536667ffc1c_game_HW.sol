/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.24;

contract game_HW{
    address owner;
    event win(address);
    
    //取得隨機變數
    function get_random() public view returns(uint){
        bytes32 random = keccak256(abi.encodePacked(now, blockhash(block.number-1)));
        return uint(random) % 1000;
    }
    
    function play() public payable{
        require(msg.value == 0.1 ether);
        if(get_random()>=500){
            msg.sender.transfer(0.2 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable{
        require(msg.value == 5 ether);
    }
    
    constructor () public payable{
        owner = 0xbF788b242FdcCeb19c47703dd4A346971807B315;
        require(msg.value == 5 ether);
    }
    
    //自毀合約
    function killcontract() public{
        require(msg.sender == owner);                                   //只有誰才可以呼叫此功能
        selfdestruct(0xA145eF81196526f12bfF3dAd1A19077e0F9aD5ba);       //餘額要轉給誰
    }
    
    //查詢合約餘額
    function qyerybalance() public view returns(uint){
        return address(this).balance;
    }
}