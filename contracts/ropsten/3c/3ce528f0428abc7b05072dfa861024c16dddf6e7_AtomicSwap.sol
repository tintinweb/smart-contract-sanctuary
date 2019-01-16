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

    function startDeal(bytes32 hash, address recipient) payable public {
        require(msg.value > 0);
        swaps.push(Swap(hash,msg.value,recipient,false));
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

    function getLatestIndex(address receiver) view public returns(int256) {
        for(uint i = swaps.length - 1; i >= 0; i--) {
            if (swaps[i].recipient == receiver) { return int256(i); }
        }
        return -1;
    }

    function getListIndices(address receiver) view public returns(uint[]) {
        uint count = 0;
        uint i = 0;
        for(i = 0; i < swaps.length; i++) {
            if (swaps[i].recipient == receiver) { count++; }
        }
        uint[] memory result = new uint[](count);
        count = 0;
        for(i = 0; i < swaps.length; i++) {
            if (swaps[i].recipient == receiver) {
                result[count++] = i;
            }
        }
        return result;
    }
}