/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity ^0.4.23 ;

contract authentication{
    //-----------------------------定义TS------------------------------//
    //公钥PK_TS,服务器编号Id_TS
    struct TS_struct{      
        address PK_TS;
        uint ID_TS;
        
    }
    mapping(uint =>TS_struct) TS;
    uint[] TS_list;
    //-----------------------------定义TS------------------------------//    
    //-----------------------------对TS的操作--------------------------------------//
    //获取TS列表长度
    function getTScount() internal returns(uint len){
        return TS_list.length;
    }
    //生成新TS
    function newTS(address pk,uint id) internal returns(uint number){
        uint len = getTScount();
        len++;
        TS[len].PK_TS = pk;
        TS[len].ID_TS = id;
        return TS_list.push(len)-1;
        
    }
    //返回TS的公钥，失败返回2
    function getTS_PK(uint value) internal returns(address key){
        uint length = getTScount();
        for(uint i = 0;i<=length;i++){
            if(TS[i].ID_TS == value)
            return TS[i].PK_TS;
        return 0x2;
        }
    }
    //-----------------------------对TS的操作--------------------------------------//
    
    
    //-----------------------------定义Ticket------------------------------//
    //UAV编号ID_UAV,UAV信誉cerdit_UAV，时间戳Timestamp_UAV，票据状态 state；
    enum Ticket_state{born,checked,locked}
    struct Ticket_struct{      
        uint ID_UAV;
        uint cerdit_UAV;
        address Add_UAV;
        uint Timestamp_UAV;
        Ticket_state state;
    }
    mapping(uint =>Ticket_struct) Ticket;
    uint[] Ticket_list;
    //-----------------------------定义Ticket------------------------------//    
    //-----------------------------对Ticket的操作--------------------------------------//
    //获取Ticket列表长度
    function getTicketcount() internal returns(uint len){
        return Ticket_list.length;
    }
    //生成新Ticket
    function newTicket(uint id,uint cerdit,address ADD,uint T) internal returns(uint number){
        uint len = getTicketcount();
        len++;
        Ticket[len].ID_UAV = id;
        Ticket[len].cerdit_UAV = cerdit;
        Ticket[len].Add_UAV = ADD;
        Ticket[len].Timestamp_UAV = T;
        Ticket[len].state = Ticket_state.born;             //这里是枚举enum的使用方法
        return Ticket_list.push(len)-1;
        
    }
    //返回Ticket的公钥，失败返回3
    function getTicket_cerdit(uint value) internal returns(uint num){
        uint length = getTicketcount();
        for(uint i = 0;i<=length;i++){
            if(Ticket[i].ID_UAV == value)
            return Ticket[i].cerdit_UAV;
        return 0x3;
        }
    }
    //返回Ticket的add，失败返回0x3
    event show00(address);
    function getTicketAdd(uint id) internal returns(address add){
        uint length = getTicketcount();
        for(uint i = 0;i<=length;i++){
            if(Ticket[i].ID_UAV == id){
            emit show00(Ticket[i].Add_UAV);
            return Ticket[i].Add_UAV;
            }
        }
        return 0x03;
        
    }
    function checkTicketstate(uint id,Ticket_state a) internal returns(bool flag){
        uint i = 0;
        uint len = getTicketcount();
        for(i;i<len;i++){
          if(Ticket[i].ID_UAV == id&&Ticket[i].state == a)
          {
              return true;
          }
          
        }return false;
    }
    function changeCredit(uint id ,uint credit,uint T) internal returns(bool flag){
        uint i = 0;
        uint len = getTicketcount();
        for(i;i<len;i++){
          if(Ticket[i].ID_UAV == id)
          {
              Ticket[i].cerdit_UAV = credit;
              Ticket[i].Timestamp_UAV = T;
              return true;
          }
          return false;
        }
    }
    function changeState(uint id ,Ticket_state sta) internal returns(bool flag){
        uint i = 0;
        uint len = getTicketcount();
        for(i;i<len;i++){
          if(Ticket[i].ID_UAV == id)
          {
              Ticket[i].state = sta;
              return true;
          }
          
        }return false;
    }
    //-----------------------------对Ticket的操作--------------------------------------//
    
    
     //-----------------------------定义task------------------------------//
    //task编号ID_task,代理无人机TUAV_task，信誉要求 cerdit_req,任务信息 msg_task；

    struct task_struct{      
        uint ID_task;
        uint TUAV_task;
        uint cerdit_req;
        uint msg_task;
    }
    mapping(uint =>task_struct) task;
    uint[] task_list;
    //-----------------------------定义task------------------------------//    
    //-----------------------------对task的操作--------------------------------------//
    //获取task列表长度
    function gettaskcount() internal returns(uint len){
        return task_list.length;
    }
    //生成新task
    event showww(uint a,uint b);
    function newtask(uint id,uint tuav,uint req,uint msg) internal returns(uint number){
        uint len = gettaskcount();
        if(len <=0 )
        len = 0;
        len++;
        task[len].ID_task = id;
        task[len].TUAV_task = tuav;
        task[len].cerdit_req = req;
        task[len].msg_task = msg;
        emit showww(len,task[len].ID_task);
        return task_list.push(len)-1;
        
    }
    //返回task的id，失败返回4
    event show11(uint);
    function gettask_ID(uint tuav) internal returns(uint num){
        uint length = gettaskcount();
        for(uint i = 0;i<=length;i++){
            if(task[i].TUAV_task == tuav){
                emit show11(task[i].ID_task);
            return task[i].ID_task;
            }
        
        }return 0x4;
    }
    //返回task的id，失败返回4
    function gettask_cerdit(uint tuav) internal returns(uint num){
        uint length = gettaskcount();
        for(uint i = 0;i<=length;i++){
            if(task[i].TUAV_task == tuav)
            return task[i].cerdit_req;
       
        } return 0x4;
    }
    //-----------------------------对task的操作--------------------------------------//  
   
   //------------------------------检查时间戳---------------------------------------//
   modifier  checktime(uint timestamp)  {         
        require(
            (now-timestamp)<=10000
            );
        _;
    }
     //modifier的使用    再去看看event函数，最方便的debug方式
     modifier  hecktime(uint ti)  {        
        require((ti-10) <= 10);
        _;
    }

    //------------------------------检查时间戳---------------------------------------//

    //------------------------------------------------ 解签名 -------------------------------------------------------//   
    //我已经把解签名写好了，区块链解签名和传统的解签名方式、结果不一样。你们要去看一下，至少了解区块链解签名干了什么
    //判断解签名是否成功：：：：decode(hash,Sign)==msg.sender//
    function decode(bytes32 hash,bytes value) 
    internal
    returns (address){
      //这是一个已经签名的数据
      bytes memory signedString =value;
      //bytes32 hash = hex"f4128988cbe7df8315440adde412a8955f7f5ff9a5468a791433727f82717a6753bd71882079522207060b681fbd3f5623ee7ed66e33fc8e581f442acbcf6ab800";
      bytes32 r=bytesToBytes32(slice(signedString,0,32));
      bytes32 s=bytesToBytes32(slice(signedString,32,32));
      byte v = slice(signedString,64,1)[0];
      //bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      //hash = sha3(abi.encodePacked(prefix, hash));

      return ecrecoverDecode(hash,r,s,v);
      
  }
  
    //切片函数
    function slice(bytes memory data,uint start,uint len) 
    internal
    returns(bytes){
      bytes memory b=new bytes(len);
      for(uint i=0;i<len;i++){
          b[i]=data[i+start];
      }
      return b;
  }
    //使用ecrecover恢复出公钥，后对比
    function ecrecoverDecode(bytes32 hash,bytes32 r,bytes32 s, byte v1) 
    internal
    returns(address addr){
      uint8 v=uint8(v1)+27;
      addr=ecrecover(hash, v, r, s);
     //addr  = hex"4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45"
  }
    //bytes转换为bytes32
    function bytesToBytes32(bytes memory source) 
    internal
    returns(bytes32 result){
      assembly{
          result :=mload(add(source,32))
      }
  }
    //------------------------------------------------- 解签名 ----------------------------------------------------//
    
    
    //--------------------------------PPT12页--------------------------------//
    //差 初始化 是否使用 签名？
    
    // 基站发送信息给智能合约，合约修改ticket ；调用send函数向对应地址发送资金、信息（信息不发给uav而是return给TS也行）
    /*
    这里是只实现了一次修改一个无人机的信息
      TS的编号,id_ts      =    ida
      upload = {
      uav编号   id_uav
      uav信誉   uav_cerdit  }
      签名，Sign_sk     =      Sign_TS
      
      返回值bool
    */
    event showTS(address,uint);
    event showTicket(uint,uint,address,uint);
    function ini(){
        newTS(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,1);
        
        newTicket(1,100,0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,now);
        newTicket(2,100,0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,now);
        // uint id,uint cerdit,address ADD,uint T
        emit showTS(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,1);
        emit showTicket(1,100,0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,now);
        emit showTicket(2,100,0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,now);
    }


    function Upload_UAVmsg_by_TS(uint id_ts,uint id_uav,address uav_add,uint uav_cerdit,uint T/*bytes Sign_TS*/)
    payable
    checktime(T)
    returns(bool flag){
        bytes32 hash_temp ;
        Ticket_state state_temp = Ticket_state.locked;
        hash_temp = sha256(abi.encodePacked(id_ts,id_uav,uav_add,uav_cerdit,T));
        //if(decode(hash_temp,Sign_TS) != msg.sender) //////////////////////这个不要
        //return false;
        //if(checkTicketstate(id_uav,state_temp)){
            changeCredit(id_uav,uav_cerdit,T);
            return true;
        //}
        
    }
    
    //--------------------------------PPT12页--------------------------------//
    
     //--------------------------------PPT13页--------------------------------//
     //TS将任务信息上链
     /*
     b_task_id 任务的id，
     b_tuav_id TUAV的id，
     b_cerdit_req任务的信誉要求
     msg 杂七杂八的任务信息，随便写
     新建一个任务，返回值bool
     */
     
    function boardcast_task(uint b_task_id,uint b_tuav_id ,uint b_cerdit_req,uint b_msg,uint T) 
    returns(bool flag)
    {
       bytes32 hash_temp;
       hash_temp = sha256(abi.encodePacked(b_task_id,b_tuav_id,b_cerdit_req,b_msg,T));
        //if(decode(hash_temp,Sign) != msg.sender)
        //return false;
        newtask(b_task_id,b_tuav_id,b_cerdit_req,b_msg);
        return true;
    }
   //--------------------------------PPT13页--------------------------------//
   
   //--------------------------------PPT14页--------------------------------//
   /*
   第一步 UAV发送信息给合约，判断tuav_id对应任务是否存在，判断UAV信誉是否达标，合格收钱，更新票据
   */
   function uav_addingroup(uint id,uint tuav_id, bytes32 value)
   payable
   returns(bool flag)
   {
       bytes32 hash_temp;
       uint credit_temp;
       hash_temp = sha256(abi.encodePacked(id,tuav_id));
       if(hash_temp != value)
      { 
       return false;
      }

       if(getTicketAdd(id)!=msg.sender)
       {
       return false;
       }
      /* if(!checkTicketstate(id,Ticket_state.born))
       {emit show3(3);
       return false;
       }
       */
       if(gettask_ID(tuav_id) == 0x4)
       {
       return false;
       }
       if(getTicket_cerdit(tuav_id)>getTicket_cerdit(id))
       {
       return false;}
       changeState(id,Ticket_state.checked);
       return true;
        
   }
    /*
   第五步 TUAV发送信息给合约，检查uav票据状态，成功则更新票据为locked，表示锁定
   */
   function tuav_req(uint tuav_id ,uint id,bytes32 hash_value)
   returns(bool flag){
       bytes32 hash_temp;
       hash_temp = sha256(abi.encodePacked(tuav_id,id));
       if(hash_temp!=hash_value)
       return false;
       
       if(gettask_ID(tuav_id) == 0x4)
       return false;
       
       if(!checkTicketstate(id,Ticket_state.checked))
       return false;
       changeState(id,Ticket_state.locked);
       return true;
   }
   event showt(bytes32,uint);
   function showhashvv(uint a ,uint b)
   returns(bytes32 flag)
   {
       uint aa =now;
       flag = sha256(abi.encodePacked(a,b));
      emit showt(flag,now);
   }
   
   
   //-----------------------------------子链的---------------------------------//
       //-----------------------------定义------------------------------// 
       //执行结果 Result_task 结果 ；ID_task 任务编号
       
    struct task_result_struct{      
        uint Result_task;
        uint ID_task;
    }
    mapping(uint =>task_result_struct) task_res;
    uint[] task_res_list;
       //-----------------------------定义------------------------------//    
       //-----------------------------对task的操作--------------------------------------//
        //获取列表长
    function getTask_res_count() internal returns(uint len){
        return TS_list.length;
    }
        //生成
    function newTask_res(uint res,uint id) internal returns(uint number){
        uint len = getTask_res_count();
        len++;
        task_res[len].Result_task = res;
        task_res[len].ID_task = id;
        return TS_list.push(len)-1;
        
    }
    //-----------------------------对task的操作--------------------------------------//
    
   //1.通信，为了方便，没弄加解密，且仅记录通信内容//
   
   function commuincation_func(bytes32 msg,address id_a,address id_b,bytes32 hash_value)returns(bool flag){
       bytes32 test_hash = sha256(abi.encodePacked(msg,id_a,id_b));
       bytes32 hash;
       if(test_hash!=hash_value)
       return false;
       hash = sha256(abi.encodePacked(msg,id_a,id_b,hash_value));
       return id_b.call("Caculated hash by block : ", hash);
   }
   
   //2.上传结果，产生验证，会保存结果
      function result_func(uint t_id,bytes32 msg,address id_a,bytes32 hash_value)returns(bool flag){
       bytes32 test_hash = sha256(abi.encodePacked(msg,id_a));
       bytes32 hash;
       if(test_hash!=hash_value)
       return false;
       // function docheck()  returns(uint result)
       uint result;
       newTask_res(result,t_id) ;
       return true;
   }
}