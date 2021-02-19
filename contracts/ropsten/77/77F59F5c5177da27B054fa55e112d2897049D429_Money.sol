/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

pragma solidity ^0.6.0;

contract Money {
    
address payable public seller; 
    
mapping (address=>Date) public date;
mapping (address=>uint256) public smth;

      constructor() public{                      
        seller = msg.sender; 
    } 
    
    struct Date{                                             
    uint256 time;
    uint256 sum;
    bool buyerOK;
    }
    
    
    modifier onlySeller(){ 
        require(msg.sender == seller); 
        _; 
    }
    
    
    function addUser(uint256 stamp, address buyer) onlySeller public {  // №1 добавление пользователя - только единожды за счет мэппинга smth
        if (smth[buyer]==0) {
        date[buyer]=Date(now+stamp*1 minutes, 0, false);
        smth[buyer]=1;
        }
    }
    
    function setOK(bool bOk) public {      // для соглашений:для изменения временной метки и функции payToSeller
          date[msg.sender].buyerOK=bOk;
    }
    
    function setSMTH(uint256 s) public {             //Доп: доступ к изменению штампа временного+безопасость активов покупателя
        smth[msg.sender]=s;
    }
    
    
    function ConfPay() public payable  {                        // №2 перевод на контракт+метка в мэппинг,обнуление согласия продавца
          require(
            msg.value < (msg.sender).balance,
            "Not enough Ether provided."
        );
        date[msg.sender].sum+=msg.value;
        date[msg.sender].buyerOK=false;
    }
    
    function changeStamp(uint256 stamp, address buyer) onlySeller public {    //изменение временного штампа - необходимо согласие 2 сторон 
        if ((smth[buyer]==stamp)&&((date[buyer].buyerOK)==true)&&(stamp!=1)){
            date[buyer].time+=stamp*1 minutes;
            smth[buyer]=1;
            date[buyer].buyerOK=false;
    }
    }
    
    
    function PayToSeller(uint256 amount,address buyer) public onlySeller  {      // №3 перевод продавцу
      require(
            (date[buyer].sum)>=amount,
            "Not enough Ether provided."
        );
          if (now>(date[buyer].time)){
              seller.transfer(amount);
              date[buyer].sum-=amount;
          }
          else if (((date[buyer].buyerOK)==true)&&(smth[buyer]==1)){
          seller.transfer(amount);
          date[buyer].sum-=amount;
      }
      else {
          revert("No permission or impossible amount.");
      }
   }
    function returnPay (uint256 amount, address payable buyer) public {               // Доп: возврат денег
       require(
            (date[buyer].sum)>=amount,
            "Not enough Ether provided."
        );
          if (msg.sender==seller){
              buyer.transfer(amount);
              date[buyer].sum-=amount;
        }
          else if (now>(( date[msg.sender].time)+30 days)){
              buyer.transfer(amount);
              date[msg.sender].sum-=amount;
          }
    }   
    
    function kill() onlySeller public {                                            // Доп: уничтожение контракта 
            if ((address(this).balance)==0){
                selfdestruct(seller);
            }
    }
}