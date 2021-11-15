pragma solidity ^0.8.6;

import {Address} from "./Address.sol";
import {SimpleMath} from "./math.sol";


contract Euclidean {                        //представлены 2 версии алгоритма Евклида
    using SimpleMath for uint256;
    uint256 public var1;           
    uint256 public var2;

    constructor(uint256 _var1, uint256 _var2) {
        var1 = _var1;
        var2 = _var2;
    } 

    //9 задача
    //в первом случае из конструктора доступ к firstVersion() не получит контракт
    //во втором же случае получит
    modifier onlyForContracts() {
        require(Address.isContract(msg.sender) == true,
        "This function can be accessed only from existing contract");
        //require(msg.sender !=tx.origin);       // как аналог, tx.origin - всегда externally-owned account 
        _; 
    } 
    
    function charity() payable external {            //отправка денег на контракт         
        require(msg.value <= address(msg.sender).balance, "Insufficient balance");
    }

    function firstVersion() public onlyForContracts returns (bool) { 
        uint256 v1 = var1; uint256 v2 = var2;
        bool flag;
        while (v1 != 0 && v2 != 0) {
             if (v1 > v2) {
                  (flag, v1) = v1.mod(v2);           //a = a % b
                  if (flag == false)
                     revert("Inappropriate numbers for this algorithm");
             } else {
                 (flag,v2) = v2.mod(v1);               //b = b % a 
                 if (flag == false)
                     revert("Inappropriate numbers for this algorithm");
             }
        }
        (,uint256 v3) = v1.add(v2);            //добавила return в функцию библиотеки
        return (Address.sendValue(payable(msg.sender),v3));     //НОД двух чисел отправляется вызывающему функцию контракту
    }
    
    //конец 9 задачи на этом контракте
    //внизу пример контракта для вызова функции firstVersion() и получения денег
    function secondVersion() public view returns (bool success, uint256) { 
        uint256 v1 = var1; uint256 v2 = var2;
        bool flag;
        while (v1 != v2) {
             if (v1 > v2) {
                  (flag, v1) = v1.sub(v2);           //a = a - b
                  if (flag == false)
                     revert("Inappropriate numbers for this algorithm");                 
             } else {
                 (flag,v2) = v2.sub(v1);                //b = b - a 
                 if (flag == false) 
                     revert("Inappropriate numbers for this algorithm");
             }
        }
        return (true,v1);
    }
    
    function changeVars(uint256 _var1, uint256 _var2) public returns(string memory) {   //изменяем переменные 
        var1 = _var1;                
        var2 = _var2;
        return "Vars have changed successfully";
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }   
}

//пример контракта вызывающего функцию firstVersion()
contract User {
    Euclidean con;
    bool public success;
    
    receive() external payable {    //fallback функция, без нее контракт не получит денег из первой фунции контракта     
    }
    
    function callFirstVersion(address _con) public returns(bool) {    //вызывает функцию firstVersion()
        con = Euclidean(_con);
        success = con.firstVersion();
        return success;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
}

pragma solidity ^0.8.0;

library SimpleMath {
    function add(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function mod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

}

pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal returns(bool) {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        return success;
    }
}

