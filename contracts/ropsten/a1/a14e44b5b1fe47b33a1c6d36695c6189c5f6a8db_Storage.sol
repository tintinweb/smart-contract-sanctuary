/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity ^0.4.24;  /* pragme 為版本的宣告 */
/* contract 為合約的宣告 */
contract Storage { 
    /* public 為訪問修飾詞, 添加在變數前面, 可讓變數具有公開的特性, 可以隨時查看 */
    address public owner;   /* address變數, 佔有20Bytes */
    uint  public storedData; /* unsigned integer, 無號整數, 默認為256bit, 大小可調整 e.g
     uint8, uint32, ….. uint256,  */
    /* constructor為構造函數, 只在合約發布時執行 */
    constructor() public {     
        owner = msg.sender;  /* msg.sender 是函數的呼叫者, 是一個address */
    }
    /* function 函數宣告 */
    function set(uint data) public {
        require(owner == msg.sender); /* 條件判斷, 若滿足條件則往下執行, 若不滿足則返回,     
          回復所有狀態*/
        storedData = data;
    }
}