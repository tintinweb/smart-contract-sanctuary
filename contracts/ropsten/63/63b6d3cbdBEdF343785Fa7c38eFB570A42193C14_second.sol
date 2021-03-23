/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity 0.6.0;

contract second{
    uint n = 0; //номер элемента который хочется изменить в массиве
    
    uint[3] mas3; //ограниченный массив
    uint[] mas; //не помню как называется но по моему неинициализированный
    function input_3(uint[3] memory data) public{ //тут пишем с ограничениями, меньше 3х файлов он видимо не примет
        for (uint i=0; i<data.length; i++){
             mas3[i]=data[i];
        }
    }
    
    function long_input(uint[] memory data) public{ //тут без ограничений
        for (uint i=0; i<data.length; i++){
             mas.push(data[i]);
        }
    }
    
    function showMAS_3() public view returns (uint[3] memory){ //выводим ограниченный
         return mas3;
    }   
    
    function showLongMAS() public view returns (uint[] memory){ //выводим неограниченный
         return mas;
    }
    
    function element(uint data) public{//меняем элемент который хотим изменить в массиве
        n = data;
    }
    
    function showElement() public view returns(uint){  //смотрим на этот элемент
        return n;
    }
    
    function change(uint data) public{ //пишем что хотим поставить вместо n-ого элемента
        mas[n] = data;
    }
    
}