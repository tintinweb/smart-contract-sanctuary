/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

pragma solidity ^0.4.26;

contract A { // This doesn't have to match the real contract name. Call it what you like.
   function sellEggs(){} // No implementation, just the function signature. This is just so Solidity can work out how to call it.
}

contract YourContract {
  function doYourThing() {
    A my_a = A(0xf30dC67B17Ec92542a1e6E5529F1f480B6991a09);
    my_a.sellEggs();
  }
}