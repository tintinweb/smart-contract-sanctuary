pragma solidity ^0.4.24;

contract test1 {
    uint256 public k;
    uint256 public j;
    uint256 public h;
    uint256 public i;

    constructor()
        public
    {
        k = 1;
        j = 1;
        h = 1;
        i = 1;
    }

    function  f1()
        public
    {
        k++;
        g1();
    }

    function g1() 
        public
    {
        j++;   
    }
}

contract test2 is test1 {

    function f1()
        public
    {
        super.f1();
        h++;
    }

    function g1() 
        public
    {
        super.g1();
        i++;
    }
}