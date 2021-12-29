/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract RedEnvelop {

    struct Status {
        bool initialized;
        bool claimed;
    }

    struct Envelope {
        uint256 balance;
        mapping(uint256 => Status) passwords;
        uint16 numParticipants;


    }
    mapping(uint64 => Envelope) public idToEnvelopes;

    function addEnvelope(uint64 envelopeID, uint16 numParticipants, uint64[] memory hashedPassword) payable public {
        require(idToEnvelopes[envelopeID].balance == 0, "balance not zero");
        require(msg.value > 0, "Trying to create zero balance envelope");
        Envelope storage envelope = idToEnvelopes[envelopeID];
        envelope.numParticipants = numParticipants;
        for (uint i=0; i < hashedPassword.length; i++) {
            Status storage envStatus = envelope.passwords[hashedPassword[i]];
            envStatus.initialized = true;
            envStatus.claimed = true;
        }
        envelope.balance = msg.value;
    }

    function hashPassword(string memory unhashedPassword) public pure returns(uint64) {
      uint64 MAX_INT = 2**64 - 1;
      uint256 password = uint256(keccak256(abi.encodePacked(unhashedPassword)));
      uint64 passInt64 = uint64(password % MAX_INT);
      return passInt64;
    }

    function openEnvelope(address payable receiver, uint64 envelopeID, string memory unhashedPassword) public {
        require(idToEnvelopes[envelopeID].balance > 0, "Envelope is empty");
        uint64 passInt64 = hashPassword(unhashedPassword);
        Envelope storage currentEnv = idToEnvelopes[envelopeID];
        Status storage passStatus = currentEnv.passwords[passInt64];
        require(passStatus.initialized, "Invalid password!");
        require(passStatus.claimed, "Password is already used");

        // claim the password
        currentEnv.passwords[passInt64].claimed = true;

        // currently withdrawl the full balance, turn this into something either true random or psuedorandom
        if (currentEnv.numParticipants == 1) {
            receiver.call{value: currentEnv.balance}("");
            currentEnv.balance = 0;
            return;
        }
        currentEnv.numParticipants--;
        
        // calculate the money open amount. We calculate a rand < 1k, then
        // max * rand1k / 1k
        // we generate a psuedorandom number. The cast here is basicalluy the same as mod
        // https://ethereum.stackexchange.com/questions/100029/how-is-uint8-calculated-from-a-uint256-conversion-in-solidity
        uint16 rand = uint16(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, receiver, envelopeID))));
        uint16 rand1K = rand % 1000;
        // We need to be careful with overflow here if the balance is huge. It needs to be 1k less than max.
        uint256 maxThisOpen = currentEnv.balance / 2;
        uint256 moneyThisOpen = maxThisOpen * rand1K / 1000;

        // once the withdrawal is made, mark that this password has been used
        receiver.call{value: moneyThisOpen}("");
        currentEnv.balance -= moneyThisOpen;
    }
}