/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

pragma solidity ^0.8.11;

// SPDX-License-Identifier: GPL-3.0-or-later

/*

Creator: John Rigler 

The purpose of Apollo is to simply record an indexed record
which points to a Bitcoin SV transaction in either production 
or testnet that contains an entire copy of the data which the 
NFT points to. A place is also given for name and IPFS address.

This smart contract simply allows for this record creation. It
also accepts current sent directly to its address and has a payout 
function which always goes to the contract creator.

Cut and paste into https://remix.ethereum.org to make your own
copy.



*/

contract ApolloTestnet {
    address public Owner;
    string public Address;

 constructor(
      string memory TargetAddress,
      string memory Chain,
      string memory Version


 ) {     
      Address = TargetAddress;
      Owner = msg.sender;
   }


    function record ( 
        // Name of File
       string memory Name,
        // Transaction to send
       string memory Txid,
       // Position of OP_RETURN payload in output
       string memory Vout,
       // IPFS version 0 address
       string memory Ipfs,
       // Payment amount
       uint256 Amount,
       // Sha1 hash of payload, helps avoid redundancy
       address payable Sha1
              ) public
   {

    address payable Hash = payable(Sha1);
    address payable Payment = payable(Owner);
    
/*

    By coding messages into a Base58 language format and converting it to hex,
    we are able to cram quite a bit of readable data into a collidable address.
    This allows us to create various native database indexing structures via
    the internal address space. Query these addresses with a block explorer to 
    find that a Web 3.0 Metaverse of sorts begins to form. 

    https://github.com/johnrigler/unspendable

    1AxMooNSHoTxPoDSzzzzzzzzzzzzT9opRN
    1BxPERMANENTxNFTxSToRAGEzzzzVZA3sq
    1CxAPoLLoxyxBSVzzzzzzzzzzzzzWcFQsk

    Trim out the middle, convert from base58

    AxMooNSHoTxPoDSzzzzzzzzzzzz   0x0c51be09739F41039AE07e0F0c086fC866e49ffF
    BxPERMANENTxNFTxSToRAGEzzzz   0x0d8EB187781debAb6e2da8B81376DF5ABc89fD7F   
    CxAPoLLoxyxBSVzzzzzzzzzzzzz   0x0eca4d264B467d9D7e6Ad22a9E8357B3cb175Fff   
*/

    address payable A = payable(0x0c51be09739F41039AE07e0F0c086fC866e49ffF);
    address payable B = payable(0x0d8EB187781debAb6e2da8B81376DF5ABc89fD7F);
    address payable C = payable(0x0eca4d264B467d9D7e6Ad22a9E8357B3cb175Fff);
    
    Hash.transfer(0);
    Payment.transfer(Amount);
    A.transfer(0);
    B.transfer(0);
    C.transfer(0);

    }

   function cashout (
      uint256 Amount ) public
{
    address payable Payment = payable(Owner);
       if(msg.sender == Owner)
            Payment.transfer(Amount);

}

    fallback () payable external {}
    receive () payable external {}

}