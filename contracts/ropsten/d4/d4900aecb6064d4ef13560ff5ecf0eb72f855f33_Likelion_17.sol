/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_17 {
    uint[] lotto = [1,3,5,7,9,11];
    mapping(uint => uint) user;
    uint[] money =[0,0,2500,5000,10000,30000,50000];
    uint index = 0;
    uint count;
    
    function Buy(uint _num) public {
        require(index<6);
        user[index] = _num;
        index++;
    }
    function Check() public returns(uint){
        for(uint i=0; i<lotto.length; i++){
            if(lotto[i]==user[i]){
                count++;
            }
        }
        return(count);
    }
    function Money() public view returns(uint){
        return (money[count]);
    }
    
}