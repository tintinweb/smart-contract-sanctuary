/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

//добавить функцию, которая бы в цикле изменяла содержимое 
//каждого элемента массива. (для числового типа шло бы увеличение значения числа на 1)
//Реализовать двумя типами циклов
// Придумать и описать свою реализацию для символьного типа
pragma solidity ^0.8.4;
contract Resume{
    
    address owner;
    resume[]  res;                      
   
    struct resume {
    uint256 id;
    string job;
    uint16 experience;
    uint256 time;     //связано с experience (его изменением)
    string hiredAs;             
    bool advancedEnglish;
    bool higherEdu;
    }
    
    constructor(){
        owner=msg.sender;
    }

    modifier onlyOwner(){ 
        require(msg.sender == owner);  
        _; 
    } 
////////////7 задача
    function a_updateResumeForMany() public onlyOwner{  //изменение элементов массива
        int256 n=int256(res.length)-1;                           //обновляется опыт на +j лет,если прошло от одного года
        while(n!=-1){                                                       // со времени внесения резюме в контракт 
            uint8 j=1;
            while(res[uint256(n)].time < block.timestamp  - j*365 days){
                res[uint256(n)].experience+=1;
                j++;
            }      
            res[uint256(n)].time=block.timestamp;   
            n-=1;           
        }
    }
    
//если есть в elements, то людей берут на должность job
    function b_hired(string memory job, uint16[] calldata elements) external onlyOwner{
        for(uint16 i=0;i<elements.length;i++){  //elements - массив индексов,ссылаются на массив резюме
            if (elements[i]<=res.length-1){
                res[elements[i]].hiredAs=job;    
            }
            else{
                revert('inappropriate index for resume');
            }
        }
    }

      function a_isHired(uint16 element) public view returns(string memory job){  //геттер
        if ((keccak256(abi.encodePacked((res[element].hiredAs))) == keccak256(abi.encodePacked((""))))){
            return ("none");
        }
        else {
            return (res[element].hiredAs);
        }
    }
////////////7 задача

    function addResume (uint256 id,string memory job, uint8 experience,bool advancedEnglish, bool higherEdu) public {
        require(advancedEnglish==true,"We aren't sure you're the right fit.");
        res.push(resume(id,job,experience,block.timestamp,"",advancedEnglish,higherEdu));
        }

    function changeResumeAll(uint16 element,string memory job, uint8 experience,bool advancedEnglish, bool higherEdu) onlyOwner external {
        if(advancedEnglish==false) resetResume(element);
        else res[element]=resume(res[element].id,job,experience,block.timestamp,"",advancedEnglish,higherEdu);
    }
    
    function updateResumeForOne(uint16 element, uint16 _experience) onlyOwner external {
        res[element].experience=_experience;
    }
         
    function output (uint16 element) public view returns(uint256 id,string memory job, uint16 experience, uint256 timeExp,bool advancedEnglish, bool higherEdu){
        if (element<0)revert("Elements are positive");
         return (res[element].id,res[element].job,res[element].experience,res[element].time,res[element].advancedEnglish,res[element].higherEdu);
     }          //для красивого вывода без кортежа;если такого элемента нет revert автоматом
                                                                 //выдает исключение

    function resetResume(uint16 element) onlyOwner public {
       delete  res[element];         
   }
                        
   function howMuchResume() public view returns(uint256 amount){
       return (res.length);             //длина массива
   }

}