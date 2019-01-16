pragma solidity ^0.4.24;


pragma experimental ABIEncoderV2;

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


contract ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) internal  pure returns (address) {
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



/*

This is a token wallet contract

Store your tokens in this contract to give them super powers

Tokens can be spent from the contract with only an ecSignature from the owner - onchain approve is not needed


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
  function totalSupply() public constant returns (uint);
  function getMiningDifficulty() public constant returns (uint);
  function getMiningTarget() public constant returns (uint);
  function getMiningReward() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

}

contract MiningKingInterface {
    function getMiningKing() public returns (address);
    function transferKing(address newKing) public;
    function mint(uint256 nonce, bytes32 challenge_digest) returns (bool);

    event TransferKing(address from, address to);
}

contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;

}






contract LavaWallet is ECRecovery{

  using SafeMath for uint;

  // balances[tokenContractAddress][EthereumAccountAddress] = 0
   mapping(address => mapping (address => uint256)) balances;

   //token => owner => spender : amount
   mapping(address => mapping (address => mapping (address => uint256))) allowed;

   //mapping(address => uint256) depositedTokens;

   mapping(bytes32 => uint256) burnedSignatures;

   address relayKingContract;

  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);
  event Transfer(address indexed from, address indexed to,address token, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender,address token, uint tokens);



  struct EIP712Domain {
      string  name;
      address verifyingContract;
  }


  struct LavaPacket {
    bytes methodName;
    string relayMode; //only allow kings to relay the packet
    address from;
    address to;
    address wallet;  //this contract address
    address token;
    uint256 tokens;
    uint256 relayerReward;
    uint256 expires;
    uint256 nonce;
  }


  /*
      MUST update these if architecture changes !!
      MAKE SURE there are no spaces !
  */
  bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
      "EIP712Domain(string name,address verifyingContract)"
  );

  bytes32 constant LAVAPACKET_TYPEHASH = keccak256(
      "LavaPacket(bytes methodName,string relayMode,address from,address to,address wallet,address token,uint256 tokens,uint256 relayerReward,uint256 expires,uint256 nonce)"
  );



  function getDomainTypehash()   pure returns (bytes32) {
      return EIP712DOMAIN_TYPEHASH;
  }

    function getLavaPacketTypehash()   pure returns (bytes32) {
      return LAVAPACKET_TYPEHASH;
  }




  function getDomainHash(EIP712Domain eip712Domain)  pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            eip712Domain.verifyingContract
        ));
    }

    function getLavaPacketHash(LavaPacket packet)  pure returns (bytes32) {
        return keccak256(abi.encode(
            LAVAPACKET_TYPEHASH,
            keccak256(bytes(packet.methodName)),
            keccak256(bytes(packet.relayMode)),
            packet.from,
            packet.to,
            packet.wallet,
            packet.token,
            packet.tokens,
            packet.relayerReward,
            packet.expires,
            packet.nonce
        ));
    }



 bytes32 DOMAIN_SEPARATOR;

constructor(address relayKingContractAddress )  {
    relayKingContract = relayKingContractAddress;

    DOMAIN_SEPARATOR = getDomainHash(EIP712Domain({
           name: "Lava Wallet",
           verifyingContract: this
          // verifyingContract: 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC //comment this out
       }));
  }


  //do not allow ether to enter
  function() public payable {
      revert();
  }


   //Remember you need pre-approval for this - nice with ApproveAndCall
  function depositTokens(address from, address token, uint256 tokens ) public returns (bool success)
  {
      //we already have approval so lets do a transferFrom - transfer the tokens into this contract

      if(!ERC20Interface(token).transferFrom(from, this, tokens)) revert();


      balances[token][from] = balances[token][from].add(tokens);
  //    depositedTokens[token] = depositedTokens[token].add(tokens);

      emit Deposit(token, from, tokens, balances[token][from]);

      return true;
  }


  //No approve needed, only from msg.sender
  function withdrawTokens(address token, uint256 tokens) public returns (bool success){
    balances[token][msg.sender] = balances[token][msg.sender].sub(tokens);

    if(!ERC20Interface(token).transfer(msg.sender, tokens)) revert();


     emit Withdraw(token, msg.sender, tokens, balances[token][msg.sender]);
     return true;
  }

  //Requires approval so it can be public
  function withdrawTokensFrom( address from, address to,address token,  uint tokens) public returns (bool success) {
      balances[token][from] = balances[token][from].sub(tokens);
       allowed[token][from][to] = allowed[token][from][to].sub(tokens);

      if(!ERC20Interface(token).transfer(to, tokens)) revert();


      emit Withdraw(token, from, tokens, balances[token][from]);
      return true;
  }


  function balanceOf(address token,address user) public constant returns (uint) {
       return balances[token][user];
   }



   function allowance(address token, address tokenOwner, address spender) public constant returns (uint remaining) {

       return allowed[token][tokenOwner][spender];

   }




  //Can also be used to remove approval by using a &#39;tokens&#39; value of 0.  P.S. it makes no sense to do an ApproveTokensFrom
  function approveTokens(address spender, address token, uint tokens) public returns (bool success) {
      allowed[token][msg.sender][spender] = tokens;
      emit Approval(msg.sender, token, spender, tokens);
      return true;
  }

  ///transfer tokens within the lava balances
  //No approve needed, only from msg.sender
   function transferTokens(address to, address token, uint tokens) public returns (bool success) {
        balances[token][msg.sender] = balances[token][msg.sender].sub(tokens);
        balances[token][to] = balances[token][to].add(tokens);
        emit Transfer(msg.sender, token, to, tokens);
        return true;
    }


    ///transfer tokens within the lava balances
    //Can be public because it requires approval
   function transferTokensFrom( address from, address to,address token,  uint tokens) public returns (bool success) {
       balances[token][from] = balances[token][from].sub(tokens);
       allowed[token][from][to] = allowed[token][from][to].sub(tokens);
       balances[token][to] = balances[token][to].add(tokens);
       emit Transfer(token, from, to, tokens);
       return true;
   }



  // function getLavaPacket(address from,)

   //This replaces getLavaTypedDataHash .. how to handle methodName?

   function getLavaTypedDataHash(LavaPacket packet) public  constant returns (bytes32) {


          // Note: we need to use `encodePacked` here instead of `encode`.
          bytes32 digest = keccak256(abi.encodePacked(
              "\x19\x01",
              DOMAIN_SEPARATOR,
              getLavaPacketHash(packet)
          ));
          return digest;
      }



   //Nonce is the same thing as a &#39;check number&#39;
   //EIP 712
/*   function getLavaTypedDataHash(bytes methodName, LavaPacket packet ) public constant returns (bytes32)
   {


         bytes32 hardcodedSchemaHash = 0x8fd4f9177556bbc74d0710c8bdda543afd18cc84d92d64b5620d5f1881dceb37; //with methodName


        bytes32 typedDataHash = sha3(
            hardcodedSchemaHash,
            sha3(methodName,packet.from,packet.to,this,packet.token,packet.tokens,packet.relayerReward,packet.expires,packet.nonce)
          );

        return typedDataHash;
   }*/








   function _tokenApprovalWithSignature(  LavaPacket packet, bytes32 sigHash, bytes signature) internal returns (bool success)
   {

       address recoveredSignatureSigner = recover(sigHash,signature);

       //relaymode must be either Any or King
       require( bytesEqual(bytes(packet.relayMode) , &#39;any&#39;) || bytesEqual(bytes(packet.relayMode) , &#39;king&#39;)     );

       bool requireKingRelay = bytesEqual(bytes(packet.relayMode) , &#39;king&#39;);

       //make sure the signer is the depositor of the tokens
       require(packet.from == recoveredSignatureSigner);

       require(msg.sender == getRelayingKing() || !requireKingRelay);  // you must be the &#39;king of the hill&#39; to relay

       //make sure the signature has not expired
       require(block.number < packet.expires);

       uint burnedSignature = burnedSignatures[sigHash];
       burnedSignatures[sigHash] = 0x1; //spent
       require(burnedSignature == 0x0 );

       //approve the relayer reward
       allowed[packet.token][packet.from][msg.sender] = packet.relayerReward;
       emit Approval(packet.from, packet.token, msg.sender, packet.relayerReward);

       //transferRelayerReward
       require(transferTokensFrom(packet.from, msg.sender, packet.token, packet.relayerReward));

       //approve transfer of tokens
       allowed[packet.token][packet.from][packet.to] = packet.tokens;
      emit Approval(packet.from, packet.token, packet.to, packet.tokens);


       return true;
   }



   function approveTokensWithSignature(LavaPacket packet, bytes signature) public returns (bool success)
   {
       require(bytesEqual(&#39;approve&#39;,bytes(packet.methodName)));

       bytes32 sigHash = getLavaTypedDataHash(packet);

       require(_tokenApprovalWithSignature(packet,sigHash,signature));


       return true;
   }


   //the tokens remain in lava wallet
  function transferTokensWithSignature(LavaPacket packet, bytes signature) public returns (bool success)
  {

      require(bytesEqual(&#39;transfer&#39;,bytes(packet.methodName)));

      //check to make sure that signature == ecrecover signature
      bytes32 sigHash = getLavaTypedDataHash(packet);

      require(_tokenApprovalWithSignature(packet,sigHash,signature));

      //it can be requested that fewer tokens be sent that were approved -- the whole approval will be invalidated though
      require(transferTokensFrom( packet.from, packet.to, packet.token, packet.tokens));


      return true;

  }


  //the tokens remain in lava wallet
 function withdrawTokensWithSignature(LavaPacket packet, bytes signature) public returns (bool success)
 {
     require(bytesEqual(&#39;withdraw&#39;,bytes(packet.methodName)));

     //check to make sure that signature == ecrecover signature
     bytes32 sigHash = getLavaTypedDataHash(packet);

     require(_tokenApprovalWithSignature(packet,sigHash,signature));

     //it can be requested that fewer tokens be sent that were approved -- the whole approval will be invalidated though
     require(withdrawTokensFrom( packet.from, packet.to, packet.token, packet.tokens));


     return true;

 }





     function burnSignature( LavaPacket packet,  bytes signature) public returns (bool success)
     {


        bytes32 sigHash = getLavaTypedDataHash( packet);

         address recoveredSignatureSigner = recover(sigHash,signature);

         //make sure the invalidator is the signer
         if(recoveredSignatureSigner != packet.from) revert();

         //only the original packet owner can burn signature, not a relay
         if(packet.from != msg.sender) revert();

         //make sure this signature has never been used
         uint burnedSignature = burnedSignatures[sigHash];
         burnedSignatures[sigHash] = 0x2; //invalidated
         if(burnedSignature != 0x0 ) revert();

         return true;
     }


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
     function approveAndCall( LavaPacket packet, bytes signature ) public returns (bool success)   {

      // address from, address to, address token, uint256 tokens, uint256 relayerReward,  uint256 expires, uint256 nonce

        bytes32 sigHash = getLavaTypedDataHash( packet);



        require(_tokenApprovalWithSignature(packet,sigHash,signature));

        ApproveAndCallFallBack(packet.to).receiveApproval(packet.from, packet.tokens, packet.token, bytes(packet.methodName));

        return true;
     }

     function getRelayingKing() public returns (address)
     {
       return MiningKingInterface(relayKingContract).getMiningKing();
     }



     function bytesEqual(bytes b1,bytes b2) pure internal returns (bool)
        {
          if(b1.length != b2.length) return false;

          for (uint i=0; i<b1.length; i++) {
            if(b1[i] != b2[i]) return false;
          }

          return true;
        }


}