/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity 0.8.3;

contract PIVTbank {
    //10% -кредит,непополняемый; 5%-вклад,пополняемый,неснимаемый,замораживается на установленное время
                                
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

    mapping (address=>creditors) cred;                     ////информация о кредиторах
    struct creditors{                                             
    uint256 time;
    uint256 creditSum;
    bool verifiedClient;                                  //только проверенные пользователи могут взять кредит
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
    modifier onlyVerified(address client){ 
        require(cred[client].verifiedClient == true,"You are not allowed to take a loan");  
        _; 
    } 
    modifier notSoLong(uint256 months){          //чтобы не могли взять кредит на очень долгий срок
        require(months<=60,"You can invest or take a credit only for 5 years for each deal.");               //maximum на пять лет кредит
        _; 
    } 
//////
    function AsetPermission(address creditor) public onlyOwner{   //добавить в проверенные пользователи кредитора
      cred[creditor].verifiedClient=true;                                 
    }
    function AdeletePermission(address creditor) public onlyOwner{  
      cred[creditor].verifiedClient=false;                                 
    }

    function payFee(uint256 amount)  private returns(uint256 Fee) {     //вызывается из другой функции для перечисления налога
        ownersFee=amount/300;                                                   // владельцу контракта
        owner.transfer(ownersFee); 
        return(ownersFee);                         
    }
//////////////////////for investors//////////////////////

    function Bdeposit(uint16 months) external payable notSoLong(months){                    //делаем вклад
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

     function BreturnDeposit() public {                      //возврат вклада и обнуление информации о вкладе
        require(invest[msg.sender].timestamp<block.timestamp,"Wait for the expiration date of the deposit");
        address payable caller=payable(msg.sender);     
        assert((caller.send(invest[msg.sender].outcome)==true));            
        emit depositReturned(caller, invest[caller].outcome);
         invest[caller].outcome=0;
         invest[caller].timestamp=0;
    }
//////////////////////end for investors//////////////////////

////////////////////// for creditors//////////////////////
    
   function CtakeCredit(uint256 amount,uint16 months) public notSoLong(months) onlyVerified(msg.sender)  {
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
    
    function CrepayCredit() public payable{                   //для выплаты кредита
        if(cred[msg.sender].creditSum==msg.value){
            cred[msg.sender].time=0;                 //если все выплатил -  обнуление информации о кредите
            emit loanPayed(msg.sender);
        }
        if(cred[msg.sender].time<block.timestamp &&cred[msg.sender].time!=0){   //если не уплатил в срок
            cred[msg.sender].verifiedClient=false;
        }
    cred[msg.sender].creditSum-=msg.value;
    }
 //////////////////////end for creditors//////////////////////   

 //////////////////////getters//////////////////////   
    function getInformationAsInvestor() public view returns(uint sum,uint time) {        //получение информации о вкладе
        return (invest[msg.sender].outcome,invest[msg.sender].timestamp);                                      
    }

    function getInformationOfMyCredit() public view returns(uint sum,uint time,bool trusted_User) {   //получение информации о кредите         
        return (cred[msg.sender].creditSum,cred[msg.sender].time,cred[msg.sender].verifiedClient);                                      
    }
    
    function getCOntractBalance() public view returns(uint balance) {            
        return address(this).balance;                                      
    }
}