/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Guess3 {

    mapping(address => uint8) myNumber;
    event Guessing(string outcome);
    string outcome;
    uint256 amount;
    address payable admin;
    uint256 randNonce = 0;
    uint256 result;
    uint256 result2;
    uint256 result3;
    
    constructor(){
        admin = payable(msg.sender);
    }
    
    uint8 salt_;
    function salt(uint8 _salt) external onlyOwner{
        salt_ = _salt;
    }
    // Defining a function to generate a random number
    function randMod() internal {
        // increase nonce
        randNonce++;
        
        result = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, salt_, randNonce))) % 10;
        result2 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, salt_, randNonce+10))) % 10;
        result3 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, salt_, randNonce+100))) % 10;
    }
    
    function viewResult() public view returns(uint256 Result,uint256 Result2,uint256 Result3) {
        return (result,result2,result3);
    }
    
    modifier onlyOwner {
        require(msg.sender == admin, "onlyOwner" );
        _;
    }
    uint256 count0;
    uint256 count1;
    uint256 count2;
    uint256 count3;
    uint256 count4;
    uint256 count5;
    uint256 count6;
    uint256 count7;
    uint256 count8;
    uint256 count9;
    
    uint256[] public winner;
    
    function guessNumber(uint8 _number, uint8 _number2,uint8 _number3) public payable returns(uint256 Result)  {
        require(msg.value>0, " Nill");
        payable(address(this)).transfer(msg.value);
        randMod();
        
        if(_number == result || _number2 == result || _number3 == result){
            outcome = " Hooray!! You Won";
            //amount = msg.value + (address(this).balance-msg.value)*bonus/100;
            amount = msg.value*3;
            if(amount>address(this).balance) {
                payable(msg.sender).transfer(address(this).balance);
            } else {
            payable(msg.sender).transfer(amount);    
            }
            
         
        }else {
            outcome = "Ooops You Lost, better luck next time";
           
        }
        winner.push(result);
     
        if(result == 0){
            count0++;
        }
        if(result == 1){
            count1++;
        }
        if(result == 2){
            count2++;
        }
        if(result == 3){
            count3++;
        }
        if(result == 4){
            count4++;
        }
        if(result == 5){
            count5++;
        }
        if(result == 6){
            count6++;
        }
        if(result == 7){
            count7++;
        }
        if(result == 8){
            count8++;
        }
        if(result == 9){
            count9++;
        }
        
        emit Guessing(outcome);
        return(result);

    }
    function viewWinner()public view returns(uint256 Number0,uint256 Number1,uint256 Number2,uint256 Number3,uint256 Number4,uint256 Number5,uint256 Number6,uint256 Number7,uint256 Number8,uint256 Number9 ){
        return (count0,count1,count2,count3,count4,count5,count6,count7,count8,count9);
    }
    
    function sweep() public payable returns(uint256) {
        require(msg.value>0, " Nill");
        payable(address(this)).transfer(msg.value);
        randMod();
        if(result==result2 && result==result3) {
            outcome = " Hooray!! You Won Sweep Jackpot";
            amount = msg.value*50;
           if(amount>address(this).balance) {
                payable(msg.sender).transfer(address(this).balance);
            } else {
            payable(msg.sender).transfer(amount);    
            }
            
        }else {
            outcome = "Ooops You Lost, better luck next time";
          
        }
        emit Guessing(outcome);
        return(result);
    }
    
    function trail() public payable returns(uint256) {
        require(msg.value>0, " Nill");
        payable(address(this)).transfer(msg.value);
        randMod();
        if((result==(result2-1) && result==(result3-2))||(result==(result2+1) && result==(result3+2))) {
            outcome = " Hooray!! You Won";
            amount = msg.value*50;
           if(amount>address(this).balance) {
                payable(msg.sender).transfer(address(this).balance);
            } else {
            payable(msg.sender).transfer(amount);    
            }
        
        }else {
            outcome = "Ooops You Lost, better luck next time";
           
        }
        emit Guessing(outcome);
        return(result);
    }
    
    function lucky7() public payable returns(uint256) {
        require(msg.value>0, " Nill");
        payable(address(this)).transfer(msg.value);
        randMod();
        if(result==7 && result2==7 && result3==7) {
            outcome = " Hooray!! You Won SUPER7 Jackpot ";
            amount = msg.value*160;
            payable(msg.sender).transfer(amount);
        }
        if(result==0 && result2==0 && result3==0 ||
            result==5 && result2==5 && result3==5 ) {
            outcome = " Hooray!! You Won BAR Jackpot";
            amount = msg.value*25;
            payable(msg.sender).transfer(amount);
        }
        
        if(result==1 && result2==1 && result3==1 ||
            result==3 && result2==3 && result3==3||
            result==9 && result2==9 && result3==9 ) {
            outcome = " Hooray!! You Won Cherry Jackpot";
            amount = msg.value*8;
            payable(msg.sender).transfer(amount);
        }
        
        if(result==2 && result2==2 && result3==2 ||
            result==4 && result2==4 && result3==4 ||
            result==6 && result2==6 && result3==6 ||
            result==8 && result2==8 && result3==8) {
            outcome = " Hooray!! You Won WaterMelon Jackpot";
            amount = msg.value*4;
            payable(msg.sender).transfer(amount);
        }
        else {
            outcome = "Ooops You Lost, better luck next time";
            
        }
        emit Guessing(outcome);
        return(result);
           
    }
    
    function viewBalance() public view returns(uint Balance){
        return address(this).balance;
    }
    function withdrawl() public onlyOwner {
        payable(admin).transfer(address(this).balance);
    }
    
    fallback() external payable {
        
    }
    
    receive() external payable {
        
    }

}