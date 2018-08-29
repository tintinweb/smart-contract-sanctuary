pragma solidity ^0.4.23;

// With love from Evgeny!
contract HardcodedMarriage {

  string public partner_1_name;
  string public partner_2_name;

  constructor() public {
    partner_1_name = &#39;Lev&#39;;
    partner_2_name = &#39;Polina&#39;;
  }

  function getDeclaration() pure public returns (string) {
      return &#39;Lev & Polina got married on 14th of July! ♡♡♡&#39;;
  }
}