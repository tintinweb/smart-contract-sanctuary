/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

//young do Jang

pragma solidity 0.8.0;
contract Likelion_2{
    
    uint256 [] public a = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25];
    uint256 [] public goal;
    function problem() public returns(uint, uint){
    uint x = 0;
    uint ncount = 0;
    uint X;
    
    
    
    for(uint256 i= 0;  i< a.length ; i++){
       if(calculation(a[i])){
            X = a[i];
            x += X;   
            ncount += 1;
            goal.push(X);
        }
        
    }
      return (x,ncount);
    }
    
    
    function calculation(uint _number) public view returns(bool){
        
        if(_number&2 !=0 && _number&3 !=0 && _number&5 !=0 && _number&7 !=0 ){
           return true;
        }else{
            return false;
        }
    }
    
    function findorder(uint b) public view returns(uint){
        return goal[b-1];
    }
    
}