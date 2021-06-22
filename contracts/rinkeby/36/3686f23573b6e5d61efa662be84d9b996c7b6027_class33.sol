/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.4.24;
contract class33{
    //函數外面的參數，默認為storage
    uint x;
    uint y = 10;
    
    // storage:全域變數, 會改動鏈上資料, 所以gas費貴
    // memory: 區域變數，不會改動鏈上資料, 所以gas費便宜
    // 只有struct跟array要加上storage或memory判斷，其餘變數會自行判斷是區域還是全域變數
    struct fruit{
        uint id;
        string name;
    }
    
    fruit[12] public fruitarray;
    mapping(address => fruit) public fruitmapping;
    
    function myFruit(uint i, string n) public {
        fruit storage myfruit = fruitmapping[msg.sender];
        myfruit.id = i;
        myfruit.name = n;
    }
    function queryMyFruit() public view returns(uint, string){
        return (fruitmapping[msg.sender].id, fruitmapping[msg.sender].name);
    }
    
    function example1(uint i,string n)public{
        fruit storage fruit1 = fruitarray[0];
        fruit1.id = i;
        fruit1.name = n;
    }
    
    function example2(uint i,string n)public view{
        //不會改變鏈上資訊
        fruit memory fruit1 = fruitarray[0];
        fruit1.id = i;
        fruit1.name = n;
    }
}