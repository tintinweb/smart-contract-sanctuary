pragma solidity ^0.4.13;

contract  ConstructorTest {
  uint a;
  uint b;
  function ConstructorTest (uint _a, uint _b) {
   a = _a;
   b = _b;
 }
  function addab  (  )  returns ( uint  ) {
    return a + b;
  }
  function helloworld  (  )  returns ( string ) {
    return &quot;hello world!&quot;;
  }
}