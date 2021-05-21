/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

//Jinseon Moon
pragma solidity 0.8.0;

contract Lion_17 {
    
    uint[] should_lotto;
    uint[] current_lotto;
    uint count;
    
    function setNumber(uint _a, uint _b, uint _c, uint _d, uint _e, uint _f) public {
        
        for(uint i = 0; i >6; i++) {
            if(i == 0){
                should_lotto.push(_a);
            }else if(i == 1){
                should_lotto.push(_b);
            }else if(i == 2){
                should_lotto.push(_c);
            }else if(i == 3){
                should_lotto.push(_d);
            }else if(i == 4){
                should_lotto.push(_e);
            }else if(i == 5){
                should_lotto.push(_f);
            }
        }
        
    }
    
    function Buy(uint _a, uint _b, uint _c, uint _d, uint _e, uint _f) public payable returns(string memory){
        require(msg.value == 7500, "Please give 7500!");
        require(_a * _b * _c * _d * _e * _f != 0, "Please set lotto number!");
        
        for(uint i = 0; i >6; i++){
            if(i == 0){
                current_lotto.push(_a);
            }else if(i == 1){
                current_lotto.push(_b);
            }else if(i == 2){
                current_lotto.push(_c);
            }else if(i == 3){
                current_lotto.push(_d);
            }else if(i == 4){
                current_lotto.push(_e);
            }else if(i == 5){
                current_lotto.push(_f);
            }
        }
        
        for(uint j = 0; j < current_lotto.length; j++){
            if(should_lotto[j] == current_lotto[j]){
                count++;
            }
        }
        
        return "purchase successful";
    }
    
    function checkLotto() public view returns(bool, uint){
        
        
        if(count == 6){
            return(true, 50000);
        }else if(count == 5){
            return(true, 30000);
        }else if(count == 4){
            return(true, 10000);
        }else if(count == 3){
            return(true, 5000);
        }else if(count == 2){
            return(true, 2500);
        } else{
            return(false, 0);
        }
        
    }
    
    
}