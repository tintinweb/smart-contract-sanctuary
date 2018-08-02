pragma solidity ^0.4.24;

contract Random3{
    
    event onRandom(uint256 randomNumber);
    
    address private admin = msg.sender;
    uint256 public pool= 0;
    /**team 5% when someone win*/
    uint256 public com = 5;
    
    function put() public payable{
        pool=pool + msg.value;
    }
    
    /**_isOdd 1 is odd;0 is even*/
    function core(uint _isOdd) public payable{
        
        pool = pool + msg.value;
        uint random = uint256(keccak256(abi.encodePacked(block.timestamp)));
        emit onRandom(random);
        /**isOdd 1 is odd;0 is even*/
        uint isOdd;
        if (random % 2 == 0) {
            isOdd=0;
        } else {
            isOdd=1;
        }

        /**xor 1^1=0,0^0=0,1^0=1,0^1=1*/
        if(_isOdd ^ isOdd == 0){
            uint256 win=msg.value * 2;
            uint256 realWin = 0;
           if(pool > win){
               realWin = win;
           }else{
               realWin = pool ;
           }

            uint256 comPofit=realWin * com / 100;
            uint256 balance= realWin - comPofit;
            msg.sender.transfer(balance);
            admin.transfer(comPofit);
            pool = pool - realWin;
        } 
    }

}