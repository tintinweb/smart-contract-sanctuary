pragma solidity ^0.4.18;


 

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}


/*

This is a King Of The Hill contract which requires Proof of Work (hashpower) to set the king

This global non-owned contract proxy-mints 0xBTC through a personally-owned mintHelper contract (MintHelper.sol)

*/

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ERC918Interface {

  function epochCount() public constant returns (uint);

  function totalSupply() public constant returns (uint);
  function getMiningDifficulty() public constant returns (uint);
  function getMiningTarget() public constant returns (uint);
  function getMiningReward() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

}



contract proxyMinterInterface
{
  function proxyMint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);
}


contract MiningKing   {


  using SafeMath for uint;


   address public miningKing;

   address public minedToken;


   event TransferKing(address from, address to);

   // 0xBTC is 0xb6ed7644c69416d67b522e20bc294a9a9b405b31;
  constructor(address mintableToken) public  {
    minedToken = mintableToken;
  }


  //do not allow ether to enter
  function() public payable {
      revert();
  }

  function getKing() public returns (address king)
  {
    return miningKing;
  }

   function transferKing(address newKing) public   {

       require(msg.sender == miningKing);

       miningKing = newKing;

       TransferKing(msg.sender, newKing);

   }


/**
Set the king to the Ethereum Address which is encoded as 160 bits of the 256 bit mining nonce


**/

//proxyMintWithKing
   function mintForwarder(uint256 nonce, bytes32 challenge_digest, address proxyMinter) returns (bool)
   {

      bytes memory nonceBytes = uintToBytesForAddress(nonce);

      address newKing = bytesToAddress(nonceBytes);

      uint previousEpochCount = ERC918Interface(minedToken).epochCount();

      //Forward to another contract, typically a pool&#39;s owned  mint contract
      require(proxyMinterInterface(proxyMinter).proxyMint(nonce, challenge_digest));

     //make sure that the minedToken really was proxy minted through the proxyMint delegate call chain
      require(  ERC918Interface(minedToken).epochCount() == previousEpochCount.add(1) );

      miningKing = newKing;

      return true;
   }



 function uintToBytesForAddress(uint256 x) constant returns (bytes b) {

      b = new bytes(20);
      for (uint i = 0; i < 20; i++) {
          b[i] = byte(uint8(x / (2**(8*(31 - i)))));
      }

      return b;
    }


 function bytesToAddress (bytes b) constant returns (address) {
     uint result = 0;
     for (uint i = b.length-1; i+1 > 0; i--) {
       uint c = uint(b[i]);
       uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
       result += to_inc;
     }
     return address(result);
 }




}