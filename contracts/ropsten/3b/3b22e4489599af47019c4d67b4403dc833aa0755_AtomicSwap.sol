pragma solidity ^0.4.24;

contract AtomicSwap {
    struct Swap {
        bytes32 hash;
        uint    valueInWei;
        address recipient;
        bool    done;
    }
    
    Swap[] private swaps;
    
    function getDeal(uint index) public view returns(bytes32 hash, uint valueInWei, address recipient, bool done) {
        hash       = swaps[index].hash;
        valueInWei = swaps[index].valueInWei;
        recipient  = swaps[index].recipient;
        done       = swaps[index].done;
    }
    
    function startDeal(bytes32 hash, address recipient) payable public returns (uint) {
        require(msg.value == 0.16 ether);
        swaps.push(Swap(hash,msg.value,recipient,false));
        return swaps.length - 1;
    }
    
    function executeDeal(uint index, string secret) public {
        Swap memory swap = swaps[index];
        require(!swap.done);
        require(keccak256(abi.encodePacked(secret)) == swap.hash);
        swaps[index].done = true;
        
        swap.recipient.transfer(swap.valueInWei);
    }
    
    function calcHash(string s) pure public returns(bytes32) {
        return keccak256(abi.encodePacked(s));
    }
}