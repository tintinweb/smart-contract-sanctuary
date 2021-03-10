/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity ^0.4.23 ;

contract authentication{
    
    struct HV{
        bytes32 hashvalue;
    }
    mapping(uint =>HV) Hv;
    uint[] Hvlist;
    function getHvcount() internal returns(uint len){
        return Hvlist.length;
    }
    function newHv(bytes32 hv) internal returns(uint number){
        uint len = getHvcount();
        len++;
        Hv[len].hashvalue = hv;
        return Hvlist.push(len)-1;
        
    }
    function checkHv(bytes32 value) internal returns(bool flag){
        uint length = getHvcount();
        for(uint i = 0;i<=length;i++){
            if(Hv[i].hashvalue == value)
            return flag = true;
        }
    }
    
    struct tempadd{
        address Adda;
        address Addb;
    }
    mapping(uint=>tempadd) templist;
    uint[] Templist;
    function getTempcount() internal returns(uint len){
        return Templist.length;
    }    
    function newTemp(address a,address b) internal returns(uint number){
        uint len = getTempcount();
        len++;
        templist[len].Adda = a;
        templist[len].Addb = b;
        return Templist.push(len)-1;
    } 
    function findTemp(address b)
    internal
    returns(address flag){
        uint length = getTempcount();
        for(uint i = 0;i<=length;i++){
            if(templist[i].Addb == b)
            return flag = templist[i].Adda;
        }
    }
    
    function checktime(uint timestamp)  //==1,成功
    internal     
    returns(uint f){
        uint k = 0;
        if(now<=timestamp+300000){
            k=1;
        }
        f=k;
        return f;
    }
    
    function initialization() public{
        bytes32 a = 0x0000000000000000000000000000000000000000000000000000000000000001;
        address b = 0xc0b588DD21ce9b9B7eD30F2d7C7D697E9a9FFb17;
        bytes32 c = sha256(abi.encodePacked(a,b));
        newHv(c);
        a = 0x0000000000000000000000000000000000000000000000000000000000000002;
        b = 0x5e686c76F88B396842c27F891645Fa67715eb39f;
        c = sha256(abi.encodePacked(a,b));
        newHv(c);
    }
    function gettime() public returns(uint f){
        f = now;
        return f;
        
    }
    function getnum() returns(bytes32 a,bytes32 b){
        address num = 0x5e686c76F88B396842c27F891645Fa67715eb39f;
        bytes32 num1 = 0x0000000000000000000000000000000000000000000000000000000000000001;
        bytes32 num2 = 0x0000000000000000000000000000000000000000000000000000000000000002;
        a = sha256(abi.encodePacked(num1,num));
        b = sha256(abi.encodePacked(num,num2));
    }
    event feedback1(string aa,address aim,address caller,bytes32 a,uint Ftimestamp,bytes32 Fhashvalue);
    event showvalue(bytes32 a);
    
    function step1and2(bytes32 a,address addb,uint timestamp,bytes32 Hashv)
    public
    returns(uint flag)
    {
        address tempadd = msg.sender;
        bytes32 comparevalue;
        bytes32 UAV;
        bytes32 sendvalue;
        if(checktime(timestamp)!=1)// check timestamp
            return flag = 2;
        //comparevalue = sha256(abi.encodePacked(a,addb,timestamp));
        comparevalue = sha256(abi.encodePacked(a,addb));
        if(comparevalue!=Hashv){  //check hashvalue
            emit showvalue(comparevalue);
            return flag = 1;
        }
        UAV = sha256(abi.encodePacked(a,tempadd));
        if(checkHv(UAV) == true)
        {
            newTemp(tempadd,addb);
            sendvalue = sha256(abi.encodePacked(tempadd,a,now));
            emit feedback1("step 1&2 success,and returns ",addb,tempadd,a,now,sendvalue);
            return flag = 0;
        }
    }
    event show12(bytes32 a);
     event feedback2(string aa,address aim ,uint time,uint flag);
     function step3and4(bytes32 b,uint timestamp,bytes32 Hashv)
     public
     returns(uint flag){
        address tempadd = msg.sender;
        address sendto;
        bytes32 comparevalue;
        bytes32 UAV;
        bytes32 sendvalue;
        sendto = findTemp(tempadd);
        if(checktime(timestamp)!=1)// check timestamp
            return flag = 2;
        //comparevalue = sha256(abi.encodePacked(tempadd,b,timestamp));
        comparevalue = sha256(abi.encodePacked(tempadd,b));
        emit show12(comparevalue);
        if(comparevalue!=Hashv){  //check hashvalue
                emit feedback2("faild",sendto,now,1);
                return flag = 1;
        }       
        UAV = sha256(abi.encodePacked(b,tempadd));
        if(checkHv(UAV) == true)
        {
            emit feedback2("step 3&4 success,and returns ",sendto,now,0);
            return flag = 0;
        }
     }
}