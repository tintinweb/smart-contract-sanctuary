// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./COWBOYS.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";


contract Corral is Ownable {    
    Cowboys public cowboys;
    bytes32 public merkleRoot;
    uint public MINIMUM_MINT_AMOUNT = 50000000000000000 wei;
    uint256 public MAX_PER_WALLET = 10;

    mapping(address => bool) private claimed;

    constructor(Cowboys cowboys_, bytes32 merkleRoot_) public {
        cowboys = cowboys_;
        merkleRoot = merkleRoot_;
    }

    function setNewRoot(bytes32 newMerkleRoot) public onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function changePrice(uint newPrice) public onlyOwner {
        MINIMUM_MINT_AMOUNT = newPrice;
    }

    function changeMax(uint newMax) public onlyOwner {
      MAX_PER_WALLET = newMax;
    }

    function transferFunds(address to) public onlyOwner() {
      address payable recipient = payable(to);
      recipient.transfer(address(this).balance);
    }

    function resetClaimed(address claimer, bool status) public onlyOwner() {
      claimed[claimer] = status;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) public payable {

        require(!claimed[msg.sender], 'CORRAL: Drop already claimed.');
        require(msg.sender == account, 'CORRAL: Must be attempting to claim your own airdrop');
        require(msg.value >= amount*MINIMUM_MINT_AMOUNT, 'CORRAL: Must send along number COWBOYS * MINIMUM_MINT_AMOUNT to claim ');
        require(amount <= MAX_PER_WALLET, 'COWBOYS: Must attempt to mint less than MAX_PER_WALLET');
        require(cowboys.PRESALE_LIVE(), 'COWBOYS: Presale must be live to claim!');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(account));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'CORRAL: Invalid proof. You are not on the whitelist.');

        // Mark it claimed and send the COWBOY.
        cowboys.mintCowboyPresale{value: msg.value}(msg.sender, amount);
        claimed[account] = true;


    }
}