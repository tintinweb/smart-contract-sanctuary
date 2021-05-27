/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.4.26;

//完成了从创建众筹时间、捐赠、提款的全部操作



contract zhongchou{
    
    
    struct funder{
        address funderaddress;  //捐赠者的地址  
        uint Tomoney;   //捐赠者捐赠的金额
    }
    
    struct needer{
        address Neederaddress;  //受益人的地址
        uint goal;  //受益人的目标值
        uint amount;    //当前的已经募集到了多少钱
        
        uint funderAcoount; //捐赠者的ID
        
        mapping(uint => funder) map;    //映射，将捐赠者的ID与捐赠者绑定再一起，从而能够得知，是谁给当前的受益人捐钱了
        
    }
    
    uint neederAmount;  //受益人的ID数
    mapping(uint => needer) needmap;    //通过mapping将受益人的ID与受益人绑定再一起，从而能够能很好管理受益人
    
    
    //实现一个众筹的事件
    function NewNeeder(address _Neederaddress,uint _goal){
       //将受益人ID与受益人绑定
        neederAmount++;
        needmap[neederAmount] = needer(_Neederaddress,_goal,0,0);
    }
    
    //@param _address	  捐赠者的地址
    //@param _neederAmount	受益人的ID
    function contribute(address _address, uint _neederAmount) payable{
      //通过ID获取到受益人对象
        needer storage _needer = needmap[_neederAmount];
       //聚集到的资金增加
        _needer.amount += msg.value;
        //捐赠人数增加
        _needer.funderAcoount++;
        //将受益人ID与受益人绑定
        _needer.map[_needer.funderAcoount] = funder(_address, msg.value);
    }
    
    
    //当募集到的资金满足条件，就会给受益人的地址转账
    //@param  _neederAmount	受益人的ID
    function ISconpelete(uint _neederAmount){
        needer storage _needer = needmap[_neederAmount];
        if(_needer.amount > _needer.goal){
            _needer.Neederaddress.transfer(_needer.amount);
        }
    }
    
    
}