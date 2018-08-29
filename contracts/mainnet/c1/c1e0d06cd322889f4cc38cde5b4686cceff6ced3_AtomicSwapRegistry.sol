pragma solidity ^0.4.24;

contract AtomicSwapRegistry {

   struct AtomicSwap {
       bytes32 chain;
       bytes sender;
       bytes reciever;
       string amount;
       bytes tokenAddress;
       bytes hashedSecret;
       uint locktime;
       bytes refundAddress;
   }

   address owner;
   address oracle;
   mapping(bytes32 => AtomicSwap) public swaps;

   event ProofRequested(string txid, string chain, string btcContract);

   constructor() public {
       owner = msg.sender;
   }

   modifier onlyOwner {
       require(msg.sender == owner);
       _;
   }

   modifier onlyOracle {
       require(msg.sender == oracle);
       _;
   }

   // A function for emitting events so that the Lamden Oracle can provide and
   // register the proof for the atomic swap
   function getProof(string txid, string chain, string btcContract) public {
       emit ProofRequested(txid, chain, btcContract);
   }

   // Functions pertaining to the oracle which sends a tx with the verification
   // payload and stores it in this registry.
   function setOracle(address o) onlyOwner public {
       oracle = o;
   }

   // Oracle pushes the data onto the blockchain about the swap so that it is registered.
   // Anyone can read the mapping and get the verification if they know the txid
   function oraclize(
        bytes32 chain,
        bytes txid,
        bytes sender,
        bytes reciever,
        string amount,
        bytes tokenAddress,
        bytes hashedSecret,
        uint locktime,
        bytes refundAddress
    ) onlyOracle public {
       swaps[keccak256(txid)] = AtomicSwap(
        chain,
        sender,
        reciever,
        amount,
        tokenAddress,
        hashedSecret,
        locktime,
        refundAddress
       );
   }

}