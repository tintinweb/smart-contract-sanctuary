pragma solidity ^0.4.18;

 

/*

This is a token wallet contract

Store your tokens in this contract to give them super powers

Tokens can be spent from the contract with only an ecSignature from the owner - onchain approve is not needed


*/


library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}


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



contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;

}



contract Owned {

    address public owner;

    address public newOwner;


    event OwnershipTransferred(address indexed _from, address indexed _to);


    function Owned() public {

        owner = msg.sender;

    }


    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }


    function transferOwnership(address _newOwner) public onlyOwner {

        newOwner = _newOwner;

    }

    function acceptOwnership() public {

        require(msg.sender == newOwner);

        OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);

    }

}





contract LavaWallet is Owned {


  using SafeMath for uint;

  // balances[tokenContractAddress][EthereumAccountAddress] = 0
   mapping(address => mapping (address => uint256)) balances;

   //token => owner => spender : amount
   mapping(address => mapping (address => mapping (address => uint256))) allowed;

   mapping(address => uint256) depositedTokens;

   mapping(bytes32 => uint256) burnedSignatures;


  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);
  event Transfer(address indexed from, address indexed to,address token, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender,address token, uint tokens);

  function LavaWallet() public  {

  }


  //do not allow ether to enter
  function() public payable {
      revert();
  }


   //Remember you need pre-approval for this - nice with ApproveAndCall
  function depositTokens(address from, address token, uint256 tokens ) public returns (bool success)
  {
      //we already have approval so lets do a transferFrom - transfer the tokens into this contract
      ERC20Interface(token).transferFrom(from, this, tokens);
      balances[token][from] = balances[token][from].add(tokens);
      depositedTokens[token] = depositedTokens[token].add(tokens);

      Deposit(token, from, tokens, balances[token][from]);

      return true;
  }


  //No approve needed, only from msg.sender
  function withdrawTokens(address token, uint256 tokens) public {
    balances[token][msg.sender] = balances[token][msg.sender].sub(tokens);
    depositedTokens[token] = depositedTokens[token].sub(tokens);

    ERC20Interface(token).transfer(msg.sender, tokens);

    Withdraw(token, msg.sender, tokens, balances[token][msg.sender]);
  }

  //Requires approval so it can be public
  function withdrawTokensFrom( address from, address to,address token,  uint tokens) public returns (bool success) {
      balances[token][from] = balances[token][from].sub(tokens);
      depositedTokens[token] = depositedTokens[token].sub(tokens);
      allowed[token][from][to] = allowed[token][from][to].sub(tokens);

      ERC20Interface(token).transfer(to, tokens);

      Withdraw(token, from, tokens, balances[token][from]);
      return true;
  }


  function balanceOf(address token,address user) public constant returns (uint) {
       return balances[token][user];
   }



  //Can also be used to remove approval by using a &#39;tokens&#39; value of 0
  function approveTokens(address spender, address token, uint tokens) public returns (bool success) {
      allowed[token][msg.sender][spender] = tokens;
      Approval(msg.sender, token, spender, tokens);
      return true;
  }


  //No approve needed, only from msg.sender
   function transferTokens(address to, address token, uint tokens) public returns (bool success) {
        balances[token][msg.sender] = balances[token][msg.sender].sub(tokens);
        balances[token][to] = balances[token][to].add(tokens);
        Transfer(msg.sender, token, to, tokens);
        return true;
    }


    //Can be public because it requires approval
   function transferTokensFrom( address from, address to,address token,  uint tokens) public returns (bool success) {
       balances[token][from] = balances[token][from].sub(tokens);
       allowed[token][from][to] = allowed[token][from][to].sub(tokens);
       balances[token][to] = balances[token][to].add(tokens);
       Transfer(token, from, to, tokens);
       return true;
   }

   //Nonce is the same thing as a &#39;check number&#39;
   //EIP 712
   function getLavaTypedDataHash( address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                     uint256 expires, uint256 nonce) public constant returns (bytes32)
   {
        bytes32 hardcodedSchemaHash = 0x313236b6cd8d12125421e44528d8f5ba070a781aeac3e5ae45e314b818734ec3 ;

        bytes32 typedDataHash = sha3(
            hardcodedSchemaHash,
            sha3(from,to,this,token,tokens,relayerReward,expires,nonce)
          );

        return typedDataHash;
   }



   function approveTokensWithSignature(address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                     uint256 expires, uint256 nonce, bytes signature) public returns (bool success)
   {
       //bytes32 sigHash = sha3("\x19Ethereum Signed Message:\n32",this, from, to, token, tokens, relayerReward, expires, nonce);

       bytes32 sigHash = getLavaTypedDataHash(from,to,token,tokens,relayerReward,expires,nonce);

       address recoveredSignatureSigner = ECRecovery.recover(sigHash,signature);

       //make sure the signer is the depositor of the tokens
       if(from != recoveredSignatureSigner) revert();

       //make sure the signature has not expired
       if(block.number > expires) revert();

       uint burnedSignature = burnedSignatures[sigHash];
       burnedSignatures[sigHash] = 0x1; //spent
       if(burnedSignature != 0x0 ) revert();

       //approve the relayer reward
       allowed[token][from][msg.sender] = relayerReward;
       Approval(from, token, msg.sender, relayerReward);

       //transferRelayerReward
       if(!transferTokensFrom(from, msg.sender, token, relayerReward)) revert();

       //approve transfer of tokens
       allowed[token][from][to] = tokens;
       Approval(from, token, to, tokens);


       return true;
   }

   //The tokens are withdrawn from the lava wallet and transferred into the To account
  function withdrawTokensFromWithSignature(address from, address to,  address token, uint256 tokens,  uint256 relayerReward,
                                    uint256 expires, uint256 nonce, bytes signature) public returns (bool success)
  {
      //check to make sure that signature == ecrecover signature

      if(!approveTokensWithSignature(from,to,token,tokens,relayerReward,expires,nonce,signature)) revert();

      //it can be requested that fewer tokens be sent that were approved -- the whole approval will be invalidated though
      if(!withdrawTokensFrom( from, to, token, tokens)) revert();


      return true;

  }

   //the tokens remain in lava wallet
  function transferTokensFromWithSignature(address from, address to,  address token, uint256 tokens,  uint256 relayerReward,
                                    uint256 expires, uint256 nonce, bytes signature) public returns (bool success)
  {
      //check to make sure that signature == ecrecover signature

      if(!approveTokensWithSignature(from,to,token,tokens,relayerReward,expires,nonce,signature)) revert();

      //it can be requested that fewer tokens be sent that were approved -- the whole approval will be invalidated though
      if(!transferTokensFrom( from, to, token, tokens)) revert();


      return true;

  }


    function tokenAllowance(address token, address tokenOwner, address spender) public constant returns (uint remaining) {

        return allowed[token][tokenOwner][spender];

    }



     function burnSignature(address from, address to, address token, uint256 tokens, uint256 relayerReward, uint256 expires, uint256 nonce,  bytes signature) public returns (bool success)
     {

       bytes32 sigHash = getLavaTypedDataHash(from,to,token,tokens,relayerReward,expires,nonce);


         address recoveredSignatureSigner = ECRecovery.recover(sigHash,signature);

         //make sure the invalidator is the signer
         if(recoveredSignatureSigner != from) revert();


         //make sure this signature has never been used
         uint burnedSignature = burnedSignatures[sigHash];
         burnedSignatures[sigHash] = 0x2; //invalidated
         if(burnedSignature != 0x0 ) revert();

         return true;
     }


     //2 is burned
     //1 is redeemed
     function signatureBurnStatus(bytes32 digest) public view returns (uint)
     {
       return (burnedSignatures[digest]);
     }




       /*
         Receive approval to spend tokens and perform any action all in one transaction
       */
     function receiveApproval(address from, uint256 tokens, address token, bytes data) public returns (bool success) {


       return depositTokens(from, token, tokens );

     }

     /*
      Approve lava tokens for a smart contract and call the contracts receiveApproval method all in one fell swoop
      */
     function approveAndCall(address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                       uint256 expires, uint256 nonce, bytes signature,  bytes data) public returns (bool success) {

         if(!approveTokensWithSignature(from,to,token,tokens,relayerReward,expires,nonce,signature)) revert();

         ApproveAndCallFallBack(to).receiveApproval(from, tokens, token, data);

         return true;

     }



 // ------------------------------------------------------------------------

 // Owner can transfer out any accidentally sent ERC20 tokens
 // Owner CANNOT transfer out tokens which were purposefully deposited

 // ------------------------------------------------------------------------

 function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

    //find actual balance of the contract
     uint tokenBalance = ERC20Interface(tokenAddress).balanceOf(this);

     //find number of accidentally deposited tokens (actual - purposefully deposited)
     uint undepositedTokens = tokenBalance.sub(depositedTokens[tokenAddress]);

     //only allow withdrawing of accidentally deposited tokens
     assert(tokens <= undepositedTokens);

     ERC20Interface(tokenAddress).transfer(owner, tokens);

     return true;

 }




}