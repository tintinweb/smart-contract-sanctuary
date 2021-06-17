/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.4.24;
contract class24{
    function get_time_now()public view returns(uint256,uint256){
        return (now,block.timestamp);
    }
    function get_block_info()public view returns(uint blockNumber,bytes32 blockHash,uint256  blockDifficulty){
        //只能拿到256個區塊內的hash
        return (block.number,
                blockhash(block.number-1),
                block.difficulty);
    }
    function get_tx_info()public view returns(address msgSender,address origin,uint value){
        return (msg.sender,
                tx.origin,
                msg.value);
    }
    
    event transfer(address indexed _from, uint amount);
    address who;
    uint value;
    address coinbase;
    uint currentTime;
    
    function buy() public payable{
        who = msg.sender;
        value = msg.value;
        coinbase = block.coinbase;
        currentTime = block.timestamp;
        
        emit transfer(who, value);
    }
}