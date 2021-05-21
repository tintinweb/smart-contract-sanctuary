/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity 0.8.0;


contract Likelion_17 {
    //YunJun Lee
    uint[] nums = [0, 0, 0, 0, 0 ,0 ];
    uint[] answer = [1, 2 , 3, 4, 5,6] ;
    uint count = 0;
    uint bal = 10000;
    
    function pay(uint _n1, uint _n2, uint _n3, uint _n4, uint _n5, uint _n6) public payable returns(uint, uint,uint,uint,uint,uint){
        uint randNonce = 0;
        for(uint i = 0 ;i<6; i+=1){
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) %10;
            answer[i] = random;
        }
        
        nums[0] = _n1;
        nums[1] = _n2;
        nums[2] = _n3;
        nums[3] = _n4;
        nums[4] = _n5;
        nums[5] = _n6;
        bal -= 7500;
        return (answer[0], answer[1],answer[2],answer[3],answer[4],answer[5]);
    }
    
    function check() public returns (uint){
        
        for(uint i =0;i<6;i+=1){
            if(nums[i] == answer[i])
                count+=1;
        }
        return count;
    }
    
    
    function getMoney() public returns (uint) {
        if(count==6){
            bal+=50000;
        }
        else if(count==5){
            bal+=30000;
        } else if(count==4){
            bal+=10000;
        }
        else if(count==3){
            bal+=5000;
        }else if(count==2){
            bal+=2500;
        }
        
        return bal;
        
    }
    
    
}