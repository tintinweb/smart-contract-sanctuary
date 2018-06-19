pragma solidity^0.4.11;

// This is a hash bounty market which allows to set a bounty for a preimage of
//  a given hash (e.g. a password)

// Feel free to use the following code for any ethical purposes.

contract HashBounty {
    event HashSolved (
        address solver,
        string solution,
        bytes32 hash
    );
    
    struct Bounty {
        bytes32 hash;
        uint reward;
        bool isClaimed;
    }
    
    mapping (uint => Bounty) bounties;
    uint bountyIndex = 0;
    
    address owner;
    uint fees = 0;
    
    function HashBounty() {
        owner = msg.sender;
    }
    
    function setBounty(bytes32 hash) payable returns (uint) {
        uint reward;
        if (msg.value < 0.001 ether)
            throw;
        
        reward = msg.value - 0.001 ether;
        fees += 0.001 ether;
        
        bounties[bountyIndex++] = Bounty(hash, reward, false);
        
        return bountyIndex - 1;
    }
    
    function claimBounty(uint claimIndex, string solution) {
        bytes32 hash = sha256(solution);
        
        if (bounties[claimIndex].hash == hash) {
            HashSolved(msg.sender, solution, bounties[claimIndex].hash);
            bounties[claimIndex].isClaimed = true;
            msg.sender.transfer(bounties[claimIndex].reward);
        } else {
            throw;
        }
    }
    
    function addBountyReward(uint index) payable {
        if (!bounties[index].isClaimed && bounties[index].hash != 0x0) {
            bounties[index].reward += msg.value;
        } else {
            throw;
        }
    }
    
    function collectFees() {
        owner.transfer(fees);
        fees = 0;
    }
}