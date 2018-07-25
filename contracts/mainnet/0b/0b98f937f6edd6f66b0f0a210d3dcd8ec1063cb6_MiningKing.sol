pragma solidity ^0.4.18;



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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

contract mintForwarderInterface
{
  function mintForwarder(uint256 nonce, bytes32 challenge_digest, address[] proxyMintArray) public returns (bool success);
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

  function getKing() view public returns (address king)
  {
    return miningKing;
  }

   function transferKing(address newKing) public   {

       require(msg.sender == miningKing);

       miningKing = newKing;

       emit TransferKing(msg.sender, newKing);

   }


/**
Set the king to the Ethereum Address which is encoded as 160 bits of the 256 bit mining nonce


**/

//proxyMintWithKing
   function mintForwarder(uint256 nonce, bytes32 challenge_digest, address[] proxyMintArray) public returns (bool)
   {

      require(proxyMintArray.length > 0);


      uint previousEpochCount = ERC918Interface(minedToken).epochCount();

      address proxyMinter = proxyMintArray[0];

      if(proxyMintArray.length == 1)
      {
        //Forward to the last proxyMint contract, typically a pool&#39;s owned  mint contract
        require(proxyMinterInterface(proxyMinter).proxyMint(nonce, challenge_digest));
      }else{
        //if array length is greater than 1, pop the proxyMinter from the front of the array and keep cascading down the chain...
        address[] memory remainingProxyMintArray = popFirstFromArray(proxyMintArray);

        require(mintForwarderInterface(proxyMinter).mintForwarder(nonce, challenge_digest,remainingProxyMintArray));
      }

     //make sure that the minedToken really was proxy minted through the proxyMint delegate call chain
      require( ERC918Interface(minedToken).epochCount() == previousEpochCount.add(1) );




      // UNIQUE CONTRACT ACTION SPACE 
      bytes memory nonceBytes = uintToBytesForAddress(nonce);

      address newKing = bytesToAddress(nonceBytes);
      
      miningKing = newKing;
      // --------

      return true;
   }


  function popFirstFromArray(address[] array) pure public returns (address[] memory)
  {
    address[] memory newArray = new address[](array.length-1);

    for (uint i=0; i < array.length-1; i++) {
      newArray[i] =  array[i+1]  ;
    }

    return newArray;
  }

 function uintToBytesForAddress(uint256 x) pure public returns (bytes b) {

      b = new bytes(20);
      for (uint i = 0; i < 20; i++) {
          b[i] = byte(uint8(x / (2**(8*(31 - i)))));
      }

      return b;
    }


 function bytesToAddress (bytes b) pure public returns (address) {
     uint result = 0;
     for (uint i = b.length-1; i+1 > 0; i--) {
       uint c = uint(b[i]);
       uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
       result += to_inc;
     }
     return address(result);
 }




}