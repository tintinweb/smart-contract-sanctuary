/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
contract arrays{
    
/*Массив - структура данных,которая присваивает каждому элементу (элементы одного типа) индекс
    (целочисленное число,начиная с нуля).
    Массивы бывают фиксированные,смешанные, динамические,разных размеров (одномерные, двумерные и тд),
    "storage" и "memory","calldata", массивы структур
*/
    
uint[] dynamic;                  
uint[5] fixeed;                
string[2][] public mixed=[["good"]];    //2-ограничение 2_го измерения   


/////////////сеттеры и создание разных массивов//////////                                                                                                                    ///

     function AinpDyn (uint[] calldata data) public{     //ввод динамического массива
        dynamic = data;
    }
    
     function AinpFix (uint[] calldata data) public{      //ввод фиксированного массива
            for (uint i=0; i<fixeed.length; i++){
                if (i==data.length){
                    break;
                }
            fixeed[i] = data[i];
        }
    }
    
    function AinpMix (string[] calldata data) public{     //ввод смешанного массива строк
               mixed.push(["contract", "working"]);     
               for(uint i=0;i<data.length-1;i++){          //нет ограничений для i тк смешанный тип
               mixed.push([data[i],data[i+1]]);
              }
    }
    
    function Ainput2D(uint[][] calldata data) public view returns(uint[][] memory)  {
        uint[][] memory arr = new uint[][](data.length);           //ввод двумерного массива из массива-аргумента 
        arr=data;
        return arr;
    }
    
       function addDyn(uint element) public {        //добавление элемента в конец (с фикс массивом не работает)
        dynamic.push(element);
    }
    
/////////////изменение и удаление/////////////    

    function changeDynFix(uint data,uint index,uint number) public{       //изменение элементов двух массивов
        if (number==0){                                            //динамического и фиксированного
            require(index<dynamic.length,        
            "Wrong index"                               
       );
            dynamic[index]= data;
        }
        else if (number==1){
            require(index<fixeed.length,        
            "Wrong index"                               
       );
            fixeed[index]= data;
        }
    }
    
    function change2D(string memory data,uint i,uint j) public{         //изменение двумерного массива строк
         require((j<2)&&(i<mixed.length),        
            "Wrong index"                               
       );
          mixed[i][j]=data;
    }    
    
    function edit2D(uint[][] calldata data) public view returns(uint[][] memory,uint sum)  {
        uint[][] memory arr = new uint[][](data.length);          //создание,обработка массива находящегося в памяти
        uint sum=0;                                                 //также сумма его элементов
        for (uint i=0; i < data.length; i++) {
            uint[] memory dim2 = new uint[](data.length);
            for(uint j = 0; j < data.length; j++){
                    dim2[j]=data[i][j]+j-i;
                    sum+=dim2[j];
                }
            arr[i] = dim2;            //[[2,23],[3,4]]
        }
        return (arr,sum);
    }
    
    function Aopredelitel2X2(int256[][] calldata data) public view returns(int opredelitel)  {
            int256[2][2] memory matrix;                                // считает определитель матрицы 2 на 2
    for (uint i = 0; i < matrix.length; i++){                       
        for (uint j = 0; j < matrix.length; j++){
            matrix[i][j]=data[i][j];
        }
    }
      int opredelitel=0;
       opredelitel=matrix[0][0]*matrix[1][1];
       opredelitel-=matrix[1][0]*matrix[0][1];
        return opredelitel;
    }
    
    function removeDynFix(uint index,uint number) public {              // удаляет элемент в динам. и фикс. массиве
        if (number==0){                                                   //не оставляя пустого места
        require(index<dynamic.length,                     
            "Wrong index"                               
       );

        for (uint i = index; i<dynamic.length-1; i++){
            dynamic[i] = dynamic[i+1];
        }
        dynamic.pop();                                //удаляет последний элемент массива - нуль
    }
    else if(number==1){
        require(index<fixeed.length,                    
            "Wrong index"                               
       );
        for (uint i = index; i<fixeed.length-1; i++){
            fixeed[i] = fixeed[i+1];
        }
        fixeed[fixeed.length-1]=0;     // т к фиксированные проинициализированны нулем изначально
    }
    }
 
 function removeMix(uint i,uint j) public {       //удаление элемента без перетасовки
             require((j<2)&&(i<mixed.length),                    
            "Wrong 2D index"                       
       );
       delete mixed[i][j];
 }
 
 function removeMix2() public {       //удаление элемента в конце
       mixed.pop();
 }
 
 function zdeleteMix() public {       //удаляет смешанный массив
       delete mixed;
 }
 
/////////////геттеры/////////////     
    function zgetDynam() public view returns (uint[] memory){
         return dynamic;
    } 
    
    function zgetFix() public view returns (uint[5] memory){
         return fixeed;
    }
     function zgetMix() public view returns (string[2][] memory){    //для вывода массива целиком 
         return mixed;
    }
    
    function zgetMixLen() public view returns (uint){    
         return mixed.length;
    }

}