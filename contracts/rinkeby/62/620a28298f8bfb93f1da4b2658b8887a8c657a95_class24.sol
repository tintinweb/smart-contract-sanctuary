/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.4.24;
contract class24{
// 指定區塊的區塊哈希——由 blockhash(uint blockNumber-1) v
// block.coinbase (address): 挖出當前區塊的礦工地址 v
// block.difficulty (uint): 當前區塊難度 v
// block.gaslimit (uint): 當前區塊 gas 限額
// block.number (uint): 當前區塊號 v
// block.timestamp (uint): 目前區塊時間戳 v
// now (uint): 目前區塊時間戳（block.timestamp）v
// gasleft() returns (uint256)：剩餘的 gas
// msg.value (uint): 隨著交易發送的 wei 的數量 v
// tx.gasprice (uint): 交易的 gas 價格
// tx.origin (address): 交易發起者(說明：如果交易是由合約發起，那msg.sender是合約地址，tx.origin是真正的發起「人」) v
// msg.sender (address): 消息發送者 v
// msg.data (bytes): 完整的 calldata ;該次交易所帶入之參數
// msg.sig (bytes4): calldata 的前 4 字節（也就是函數標識符）
    bytes32 public a = blockhash(block.number);
    bytes32 public blockhash_ =blockhash(block.number-1);
    function get_time_now()public view returns(uint256,uint256){
        return (now,block.timestamp);
     } //計算出現在與西元1970年1月1日00:00:00 的時間差，通常會用秒做為計算單位。
    function get_block_info()public view returns(uint blockNumber,bytes32 blockHash,uint256  blockDifficulty){
        //只能拿到256個區塊內的hash
        return (block.number,
                blockhash(block.number-1),
                block.difficulty);
    }
    function get_tx_info()public view returns(address msgSender,address origin,uint value,address coinbase ){
        return (msg.sender,
                tx.origin,
                msg.value,
                block.coinbase);
    }

    //實作記錄送過來的ether
    
    event setMoney(string money ,string q);
    bytes public u;
    bytes32 public q;
    //可透過解碼將其轉回文字（utf08）
    function data(string a) public {
        emit setMoney(a,a);
        u = msg.data;
        q = msg.sig;
    }

}