/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

pragma solidity >=0.7.0 <0.8.0;

// IN THE FIRST VERSION, CLAIMED BLOCK NONCE IS NOT VERIFIED
// THIS CONTRACT ASSUMES THAT MEV PRODUCER COMPLETELY TRUSTS POOL OPERATOR THAT:
// (1) PROVIDED NONCE IS VALID
// (2) PROVIDED NONCE WAS BROADCASTED WITHOUT DELAY TO MEV PRODUCER/MEMPOOL
// In the next version we're planning to introduce trustless approach to verify submited nonce onchain(see smartpool) and verify delay in seconds for share submission(with oracles)
contract LogOfClaimedMEVBlocks {
    mapping (address => uint) public timestampOfPossibleExit;
    mapping (address => uint) public depositedEther;
    mapping (bytes32 => uint) public claimedBlockNonce;
    mapping (bytes32 => uint) public claimedBlockCost;
    
    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event BlockClaimed(bytes32 blockHeader, bytes32 seedHash, bytes32 target, uint blockNumber, uint blockPayment, address poolOperator, uint blockNonce, address mevProducer);
    
    fallback () payable external {
        this.depositAndLock(msg.value, 24 * 60 * 60);
    }
    function depositAndLock(uint depositAmount, uint depositDuration) payable external {
        require(depositAmount == msg.value);
        // Enforcing min and max lockup durations
        require(depositDuration >= 24 * 60 * 60 && depositDuration < 365 * 24 * 60 * 60);
        timestampOfPossibleExit[msg.sender] = block.timestamp + depositDuration;
        if (msg.value > 0) {
            depositedEther[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdrawUpTo(uint etherAmount) external {
        // User previously deposited into contract
        require(depositedEther[msg.sender] > 0);
        // Full 1 day passed after last deposit
        require(block.timestamp > timestampOfPossibleExit[msg.sender]);
        if (depositedEther[msg.sender] < etherAmount)
            etherAmount = depositedEther[msg.sender];
        require(address(this).balance >= etherAmount);
        depositedEther[msg.sender] -= etherAmount;
        msg.sender.transfer(etherAmount);
        emit Withdraw(msg.sender, etherAmount);
    }

    function submitClaim(
        bytes32 blockHeader,
        bytes32 seedHash,
        bytes32 target,
        uint blockNumber,
        uint blockPayment,
        address poolOperator,
        uint blockNonce,
        address mevProducer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(msg.sender == poolOperator);
        bytes32 hash = sha256(abi.encode(blockHeader, seedHash, target, blockNumber, blockPayment, poolOperator));
        if (claimedBlockCost[hash] == 0) {
            if (ecrecover(keccak256(abi.encode("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == mevProducer) {
                require(depositedEther[mevProducer] >= blockPayment);
                claimedBlockCost[hash] = blockPayment;
                claimedBlockNonce[hash] = blockNonce;
                depositedEther[mevProducer] -= blockPayment;
                depositedEther[poolOperator] += blockPayment;
                emit BlockClaimed(blockHeader, seedHash, target, blockNumber, blockPayment, poolOperator, blockNonce, mevProducer);
            }
        }
    }
    
    function remainingDurationForWorkClaim(
        bytes32 blockHeader,
        bytes32 seedHash,
        bytes32 target,
        uint blockNumber,
        uint blockPayment,
        address poolOperator,
        address mevProducer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (uint) {
        bytes32 hash = sha256(abi.encode(blockHeader, seedHash, target, blockNumber, blockPayment, poolOperator));
        if (claimedBlockCost[hash] != 0) return 0;
        if (ecrecover(keccak256(abi.encode("\x19Ethereum Signed Message:\n32", hash)),v,r,s) != mevProducer) return 0;
        if (depositedEther[mevProducer] < blockPayment) return 0;
        if (block.timestamp >= timestampOfPossibleExit[mevProducer]) return 0;
        return timestampOfPossibleExit[mevProducer] - block.timestamp;
    }
}