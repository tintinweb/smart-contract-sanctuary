/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity ^0.8.3;

contract additions{                           //перевод из uint в строку - для getActiveDeposits
    
    function uintToStr(uint256 _i) internal pure returns (string memory str)
    {
      require(_i!=0,"A number should be positive");
      uint256 j = _i;
      uint256 length;
      while (j != 0)
      {
        length++;
        j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint256 k = length;
      j = _i;
      while (j != 0)
      {
        bstr[--k] = bytes1(uint8(48 + j % 10));
        j /= 10;
      }
      str = string(bstr);
      return str;
}
}

contract Deposits is additions{                  //наследование,чтобы использовалась функция с другого контракта
                                                             //для оптимизации
    address owner;
    constructor(){
      owner=msg.sender;
    }

    modifier onlyOwner(){                                    //модификатор доступа - возможность пользоваться депозитом 
            if (msg.sender != owner) {                                     //задает владелец контракта
            revert("You aren't allowed to access this function");
        }
           _; 
    } 
  
   modifier depTypes(uint8 typeofDeposit){                                     //ограничение по типу депозитов как в жизни
        require(typeofDeposit<11,"We dont have so many types of deposit"); 
           _; 
    } 
    mapping(address => bool[11]) public deposit;        //тип депозита как индекс bool массива,все ищется через адресс засчет mapping

    function AsetPermission(address client,uint8 typeofDeposit) external  depTypes(typeofDeposit) onlyOwner{
      deposit[client][typeofDeposit]=true;                                  //разрешает использование депозита bool типом 
    }

    function BsetDeny(address client,uint8 typeofDeposit) external  depTypes(typeofDeposit) onlyOwner{  
       require(deposit[client][typeofDeposit]==true,"All is up-to-date");
      deposit[client][typeofDeposit]=false;                                  //запрещает использование депозита => false
    }
    
    function bsetDenyAll(address client) external  onlyOwner{   //сведение к дефолту - нет разрешенных типов депозита
      delete deposit[client];
    }

    function AgetActiveDeposits(address client) public view returns(string memory) {      //вывод через строку всех типов депозита
        string memory str="Available types of deposit: ";                                                                //которые может использовать клиент
     for (uint i=1;i<11;i++){
         if(deposit[client][i]==true){
              str=string(abi.encodePacked(str," ",uintToStr(i)," "));
         }
     }
     return str;
}   
}