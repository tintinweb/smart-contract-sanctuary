pragma solidity 0.4.24;
contract Blueprint  {
    string exchange;
    string security;
    uint256 entry; 
    uint256 exit;
    uint256 expires;
    
    
    struct BlueprintInfo {
        string exchange;
        string security;
        uint256 entry; 
        uint256 exit;
        uint256 expires;
        address creator;
        uint256 createTime;
    }

    mapping(uint256 => BlueprintInfo) public _bluePrint;

    function createExchange(uint256 _id,string _exchange, string _security, uint256 _entry, uint256 _exit, uint256 _expires) public
          
    returns (bool)
   
    {
         BlueprintInfo memory info;
         info.exchange=_exchange;
         info.security=_security;
         info.entry=_entry;
         info.exit=_exit;
         info.expires=_expires;
         info.creator=msg.sender;
         info.createTime=block.timestamp;
         _bluePrint[_id] = info;
         return true;
         
    }
    
}