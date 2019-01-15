pragma solidity ^0.5.2;
// This is basically a shared account in which any transactions done must be signed by multiple parties. Hence, multi-signature wallet.
contract SimpleMultiSigWallet {
    struct Proposal {
        uint256 amount;
        address payable to;
        uint8 votes;
        bytes data;
        mapping (address => bool) voted;
    }
    
    mapping (bytes32 => Proposal) internal proposals;
    mapping (address => uint8) public voteCount;
    
    uint8 constant public maximumVotes = 2; 
    constructor() public{
        voteCount[0x8c070C3c66F62E34bAe561951450f15f3256f67c] = 1; // ARitz Cracker
        voteCount[0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C] = 1; // Sumpunk
    }
    
    function proposeTransaction(address payable to, uint256 amount, bytes memory data) public{
        require(voteCount[msg.sender] != 0, "You cannot vote");
        bytes32 hash = keccak256(abi.encodePacked(to, amount, data));
        require(!proposals[hash].voted[msg.sender], "Already voted");
        if (proposals[hash].votes == 0){
            proposals[hash].amount = amount;
            proposals[hash].to = to;
            proposals[hash].data = data;
            proposals[hash].votes = voteCount[msg.sender];
            proposals[hash].voted[msg.sender] = true;
        }else{
            proposals[hash].votes += voteCount[msg.sender];
            proposals[hash].voted[msg.sender] = true;
            if (proposals[hash].votes >= maximumVotes){
                if (proposals[hash].data.length == 0){
                    proposals[hash].to.transfer(proposals[hash].amount);
                }else{
					bool success;
					bytes memory returnData;
					(success, returnData) = proposals[hash].to.call.value(proposals[hash].amount)(proposals[hash].data);
					require(success);
                }
                delete proposals[hash];
            }
        }
    }
    
    // Yes we will take your free ERC223 tokens, thank you very much
    function tokenFallback(address from, uint value, bytes memory data) public{
        
    }
    
    function() external payable{
        // Accept free ETH
    }
}