pragma solidity ^0.4.18;




/*
Contract for operating and maintaining an Inferno Sidechain

Only stores a simple merkle tree root hash on the Ethereum Mainnet

*/




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


contract EIP918Interface {
  function lastRewardTo() public returns (address);
  function epochCount() public returns (uint);

  function lastRewardAmount() public returns (uint);
  function lastRewardEthBlockNumber() public returns (uint);

  function totalSupply() public constant returns (uint);
  function getMiningDifficulty() public constant returns (uint);
  function getMiningTarget() public constant returns (uint);
  function getMiningReward() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

}



contract InfernoSidechain   {
    using SafeMath for uint;

    uint lastBlockMiningEpoch;
    bytes32 currentRootHash;


    address public miningContract;



   // 0xBTC is 0xb6ed7644c69416d67b522e20bc294a9a9b405b31;
  constructor(address mContract) public  {
    miningContract = mContract;
  }


  //do not allow ether to enter
  function() public payable {
      revert();
  }

  /*
  Based on Proof of Work, EIP 918 and Mining Contract

  This will typically return a smart contract but one which implements proper forwarding methods
  */
  function getMiningAuthority() public returns (address)
  {
    return EIP918Interface(miningContract).lastRewardTo();
  }

  function getMiningEpoch() public returns (uint)
  {
    return EIP918Interface(miningContract).epochCount();
  }

  /*
  In this case, the leaf we start with is the currentRootHash

  */
  function addNewBlock(
      bytes32[] proof,
      bytes32 root,
      bytes32 leaf
    )
      public 
      returns (bool)
    {
      require(msg.sender == getMiningAuthority());
      require(leaf == currentRootHash); //must build off of the previous block
      require(lastBlockMiningEpoch <  getMiningEpoch()); //one new sidechain block per Mining Round


      bytes32 computedHash = leaf;

      for (uint256 i = 0; i < proof.length; i++) {
        bytes32 proofElement = proof[i];

        if (computedHash < proofElement) {
          computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
        } else {
          computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
        }
      }


      currentRootHash = root; //update to the new overall chain state
      lastBlockMiningEpoch = getMiningEpoch();


      return computedHash == root;
    }


}