pragma solidity ^0.4.23;
contract Fib {
  
    //function to calculate fibonacc recursive
    function fib(uint256 n) pure public returns(uint128){
        if (n==1){
            return 1;
        }
        if (n==0) {
            return 0;
        }
        return fib(n-1)+fib(n-2);
    }

    //iterative
    function fib1(uint256 n) pure public returns(uint256){
       if (n<=1) return n;
       uint256 pp=0;
       uint256 p=1;
       uint256 f=0;
       for (uint256 i=2;i<=n;i++){
           f=p+pp;
           pp=p;
           p=f;
       }
       return f;
    }    

}