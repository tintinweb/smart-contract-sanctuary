/*Подключить к своему контракту библиотеку для работы с адресами:
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol.
 Разработать логику, которая используют следующиие функции из этой библиотеки:
 isContract(), sendValue()

 Суть изменений:
  модификатор для firstVersion(),только контракт ее может вызвать
  НОД чисел отправляется вызывающему функцию контракту с помощью sendValue()

*/
pragma solidity ^0.8.6;
import "./SafeMath.sol";
import "./Address.sol";


contract Euclidean {                        //представлены 2 версии алгоритма Евклида
    using SafeMath for uint256;
    uint256 public var1=10;           
    uint256 public var2=5;

/////9 задача    

    function charity() payable external{            //отправка денег на контракт         
        require(msg.value<=address(msg.sender).balance,"Insufficient balance");
    }


//в первом случае из конструктора доступ к firstVersion() не получит контракт
//во втором же случае получит
    modifier onlyForContracts(){
        require(Address.isContract(msg.sender)==true,"This function can be accessed only from existing contract");
        //require(msg.sender !=tx.origin);       // как аналог, tx.origin - всегда externally-owned account 
        _; 
    } 
    
    function firstVersion() public onlyForContracts returns (bool) { 
        uint256 v1=var1; uint256 v2=var2;
        bool flag;
        while (v1 != 0 && v2 != 0){
             if (v1 > v2){
                  (flag, v1)=mod(v1,v2);           //a = a % b
                  if (flag==false){
                     revert("Inappropriate numbers for this algorithm");
                 }
                  
             }
             else{
                 (flag,v2)=mod(v2,v1);                //b = b % a 
                 if (flag==false){
                     revert("Inappropriate numbers for this algorithm");
                 }
             }
        }
        (,uint256 v3)=add(v1,v2);            //добавила return в функцию библиотеки
        return (Address.sendValue(payable(msg.sender),v3));     //НОД двух чисел отправляется вызывающему функцию контракту
    }
    
/////конец 9 задачи на этом контракте. внизу пример контракта для вызова функции firstVersion() и получения денег

    function secondVersion() public view returns (bool success,uint256){ 
        uint256 v1=var1; uint256 v2=var2;
        bool flag;
        while (v1 != v2){
             if (v1 > v2){
                  (flag, v1)=sub(v1,v2);           //a = a - b
                  if (flag==false){
                     revert("Inappropriate numbers for this algorithm");
                 }
                  
             }
             else{
                 (flag,v2)=sub(v2,v1);                //b = b - a 
                 if (flag==false){
                     revert("Inappropriate numbers for this algorithm");
                 }
             }
        }
        return (true,v1);
   
    }
    

    function add(uint256 v1,uint256 v2) internal pure returns (bool success,uint256){  
        return v1.tryAdd(v2);
    }
    
    function mod(uint256 v1,uint256 v2) internal pure returns(bool success,uint256){
      return (v1.tryMod(v2));
    }

    function sub(uint256 v1,uint256 v2) internal pure returns(bool success,uint256){
      return (v1.trySub(v2));
    }


    function changeVars(uint256 _var1,uint256 _var2) public returns(string memory){   //изменяем переменные 
        var1=_var1;                
        var2=_var2;
        return "Vars have changed successfully";
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
}


//пример контракта вызывающего функцию firstVersion()

contract user{
    
    Euclidean con;
    bool public success;
    
    receive() external payable {               //fallback функция, без нее контракт не получит денег из первой фунции контракта
            
    }
    
    function go(address _con) public returns(bool){    //вызывает функцию firstVersion()
        con = Euclidean(_con);
        success = con.firstVersion();
        return success;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}