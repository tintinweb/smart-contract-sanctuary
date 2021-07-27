/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

pragma solidity ^0.8.3;
//10% -кредит,непополняемый; 5%-вклад,пополняемый,неснимаемый,замораживается на установленное время
//начало 6 задачи с 38 строки
contract bank {
                                
    receive() external payable {               //fallback функция
            owner.transfer(msg.value);  
    }

    address payable owner;
    uint256 ownersFee;

   mapping (address=>investors) invest;                     //информация о вкладах:на сколько и сумма
   struct investors{                                             
    uint256 timestamp;
    uint256 outcome;  
    }
     
    event depositReceived(address indexed sender, uint256 sum);
    event depositReturned(address indexed sender, uint256 sum);

    event loanGot(address indexed creditor, uint256 sum);
    event loanPayed(address indexed creditor);

    constructor(){
        owner=payable(msg.sender);
    }

    modifier onlyOwner(){ 
        require(msg.sender == owner);  
        _; 
    } 

    modifier notSoLong(uint256 months){          //чтобы не могли взять кредит на очень долгий срок
        require(months<=60,"You can invest or take a credit only for 5 years for each deal.");               //maximum на пять лет кредит
        _; 
    } 
///////все что поменяла для решения 6 задачи, тк банк самое логичное переделать переменную "verified" в enum ///////
    enum creditorState{unverified,verified}     
             // "+" отмечаю что поменяла для решения 6-ой задачи
    
    mapping (address=>creditors) cred;                     //информация о кредиторах
    struct creditors{                                             
    uint256 time;
    uint256 creditSum;
    creditorState status;                            ///  "+" только проверенные пользователи могут взять кредит
    }

    modifier onlyVerified(address client,creditorState state){  
        require(state==creditorState.verified,"You are not allowed to take a loan"); ///"+" 
        _; 
    } 

    function AsetPermission(address creditor) external onlyOwner{   //добавить в проверенные пользователи кредитора
      cred[creditor].status=creditorState.verified;                    ///"+"                                
    }
    function deletePermission(address creditor) external onlyOwner{  
      cred[creditor].status=creditorState.unverified;                 ///"+"                  
    }
     function c2_repayCredit() public payable{                   //для выплаты кредита
        if(cred[msg.sender].creditSum==msg.value){
            cred[msg.sender].time=0;                 //если все выплатил -  обнуление информации о кредите
            emit loanPayed(msg.sender);
        }
        if(cred[msg.sender].time<block.timestamp &&cred[msg.sender].time!=0){   //если не уплатил в срок
            cred[msg.sender].status==creditorState.unverified;                  ///"+" 
        }
    cred[msg.sender].creditSum-=msg.value;
    }
function getInformationOfMyCredit() public view returns(uint sum,uint time,string memory userIs) {   //получение информации о кредите   
       string memory userIs;
       if(cred[msg.sender].status==creditorState.verified){             ///"+" 
           userIs="verified";
       }
       else{
           userIs="unverified";
       }
        return (cred[msg.sender].creditSum,cred[msg.sender].time,userIs);                                      
    }
///////////конец 6 задачи///////////
    function payFee(uint256 amount)  private returns(uint256 Fee) {     //вызывается из другой функции для перечисления налога
        ownersFee=amount/300;                                                   // владельцу контракта
        owner.transfer(ownersFee); 
        return(ownersFee);                         
    }
//////////////////////functions for investors//////////////////////

    function i_deposit(uint16 months) external payable notSoLong(months){                    //делаем вклад
        uint256 sum=msg.value;
        emit depositReceived(msg.sender, sum);
        uint256 fee=payFee(sum);                                        //платим налог от каждой транзакции
        if (invest[msg.sender].timestamp==0){                   
            invest[msg.sender].timestamp=block.timestamp+months*31 days;
        }
        else {                                                //если уже есть другой вклад то прибавляем к нему время
            invest[msg.sender].timestamp+=months*31 days;
        }
        invest[msg.sender].outcome+=sum;
        for(uint16 i=0;i<months;i++){                   //начисляем процент
            invest[msg.sender].outcome=invest[msg.sender].outcome*105/100;
        }
        invest[msg.sender].outcome-=fee;
    }

     function i_returnDeposit() public {                      //возврат вклада и обнуление информации о вкладе
        require(invest[msg.sender].timestamp<block.timestamp,"Wait for the expiration date of the deposit");
        address payable caller=payable(msg.sender);     
        assert((caller.send(invest[msg.sender].outcome)==true));            
        emit depositReturned(caller, invest[caller].outcome);
         invest[caller].outcome=0;
         invest[caller].timestamp=0;
    }
//////////////////////end for investors//////////////////////

////////////////////// functions for creditors//////////////////////
    
   function c1_takeCredit(uint256 amount,uint16 months) public notSoLong(months) onlyVerified(msg.sender,cred[msg.sender].status)  {
       require(amount<=1000 ether,"An amount for loan is too big");  // берем кредит с реальными ограничениями
        address payable caller=payable(msg.sender);                        //на не очень долгое время+не целое состояние
        require(cred[caller].time==0,"You cant take another loan");  //если уже есть кредит,то больше выдать не можем
            uint256 fee=payFee(amount);
            cred[caller].time=block.timestamp+months*31 days;
            cred[caller].creditSum=amount;
        for(uint16 i=0;i<months;i++){
            cred[msg.sender].creditSum=cred[msg.sender].creditSum*11/10;    //начисление процентов
        }
        cred[msg.sender].creditSum+=fee;
      assert((caller.send(cred[msg.sender].creditSum)==true)); 
        emit loanGot(msg.sender, cred[msg.sender].creditSum);
    }
    
 //////////////////////end for creditors//////////////////////   

 //////////////////////getters//////////////////////   
    function getInformationAsInvestor() public view returns(uint sum,uint time) {        //получение информации о вкладе
        return (invest[msg.sender].outcome,invest[msg.sender].timestamp);                                      
    }
    
    function getCOntractBalance() public view returns(uint balance) {            
        return address(this).balance;                                      
    }
}