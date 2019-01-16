pragma solidity 0.4.25;
contract KryptoGifts {
    
    address admin;
    uint price = 10000000000000000;
    mapping(string => string) private msgs;
    


    constructor(uint8 _numProposals) public {
        admin = msg.sender;
    }
    
    function saveMsgByAdmin(string id,string msgTxt){
        require(msg.sender  == admin);
        msgs[id]=msgTxt;
        
    }
    
    function saveMsgByUser(string id,string msgTxt) payable external{
       
        require(msg.value >= price);
        msgs[id]=msgTxt;
        admin.transfer(this.balance);
    }
    
    function setMinBalance(uint256 bal){
         require(msg.sender  == admin);
         price = bal;
    }

    function getMsg(string id) public view returns (string msg) {
        return msgs[id];
    }
    
    function() payable { }
    
}