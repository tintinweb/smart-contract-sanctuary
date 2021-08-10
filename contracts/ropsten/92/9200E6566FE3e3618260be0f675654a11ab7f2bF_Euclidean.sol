/*Библиотеки. Подключить к своему контракту с арифметическими операциями 
(сложение и вычитание, также пусть тип будет uint256) библиотеку безопасной математики.
Разработать логику, которая используют арифметические операции с использованием этой библиотеки


Для демонстрации арифм операций в данной задаче реализовала 2 версии алгоритма Евклида
*/

pragma solidity ^0.8.6;
import "./SafeMath.sol";

contract Euclidean {
    using SafeMath for uint256;
    
    uint256 public var1=10;           
    uint256 public var2=5;
    
    
    
    function firstVersion() public view returns (bool success,uint256){ 
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
        return (add(v1,v2));
   
    }
    
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
    
}