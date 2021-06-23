/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;
contract class44_game{
    event win(address);
    
    //隨機產生數字
    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ramdon) % 10;
    }
        
    //判斷玩家是否猜中數字，猜中則獲勝
    function play(uint n) public payable {
        require(msg.value == 0.1 ether);
        if(get_random() == n)
        {
            msg.sender.transfer(0.2 ether);emit win(msg.sender);
        }
        
    }
        
    //一開始佈署合約給的本金
    function () public payable{
        require(msg.value == 5 ether);
    }  
    constructor () public payable{
        require(msg.value == 5 ether); 
    }
}