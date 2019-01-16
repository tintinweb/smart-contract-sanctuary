pragma solidity ^0.4.0;

contract C {
    function () public {
        suicide(tx.origin);
    }
}

contract B {
   function () payable public {
       C c = new C();
       c.call();
   }
}