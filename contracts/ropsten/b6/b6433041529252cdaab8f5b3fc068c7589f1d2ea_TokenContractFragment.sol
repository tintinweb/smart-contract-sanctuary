pragma solidity ^0.5.1;




contract TokenContractFragment {
 
 
 uint public a;
 
        function setA(uint _a) public {
            
            require(_a > 10);
            a =_a;
        }
 
}