/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

pragma solidity 0.6.0;
contract second {
    
    uint8 public price1=200;          //переменные uint8 
    uint8 public price2=190;
    
    
    function add() public view returns (uint8){  //вычисление суммы в uint8 и вывод
        return(price1+price2);
    }
    
    
    function sub() public view returns(uint8){   //вычисление разности в uint8 и вывод
    if (int(price1)-int(price2)<0) {                       // выводим такой результат который удоволетворяет задаче арифм переполнения 
        return (price1-price2);
    }
    else{
        return (price2-price1);
    }
  }
  
  
  function changePrices(uint8 var1,uint8 var2) public returns(string memory){   //изменяем переменные 
   require( 
            ((int(var1)+int(var2)>255) && ((int(var2)-int(var1)<0) || (int(var1)-int(var2)<0))),          //для удовлетворения условиям задачи арифм переполнения -обертывание исключений
            "Неподходящие переменные для демонстрации арифметического переполнения в uint8."                               //чтобы не использовали газ
       );
            price1=var1;                //изменение переменных
            price2=var2;
        return "Цены успешно заменены";
        }
    
}