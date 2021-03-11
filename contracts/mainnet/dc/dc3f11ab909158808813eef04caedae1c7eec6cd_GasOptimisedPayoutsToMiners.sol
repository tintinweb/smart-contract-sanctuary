/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity >=0.7.0 <0.8.0;

// In the first version, claimed block nonce / mixDigest IS NOT VERIFIED
// This contract assumes that mev block template producer completely TRUSTS pool operator that received the signed work order.
// This contract !DOES NOT VERIFY! that block nonce / mixDigest is valid or that it was broadcasted without delay
// In the next version we're planning to introduce trustless approach to verify submited block nonce on-chain(see smartpool) and verify delay in seconds for share submission(using oracles)
contract LogOfClaimedMEVBlocks {
    uint256 internal constant FLAG_BLOCK_NONCE_LIMIT = 0x10000000000000000;
    mapping (address => uint) public timestampOfPossibleExit;
    mapping (address => uint) public depositedEther;
    
    mapping (address => address) public blockSubmissionsOperator;
    mapping (bytes32 => uint) public claimedBlockNonce;
    mapping (bytes32 => bytes32) public claimedBlockMixDigest;
    
    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event BlockClaimed(bytes32 blockHeader, bytes32 seedHash, bytes32 target, uint blockNumber, uint blockPayment, address miningPoolAddress, address mevProducerAddress, uint blockNonce, bytes32 mixDigest);
    

    function setBlockClaimsOperator(address newBlockSubmissionsOperator) public {
        assert(msg.data.length == 36);
        blockSubmissionsOperator[msg.sender] = newBlockSubmissionsOperator;
    }

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
        // Deposit lockup period is over
        require(block.timestamp > timestampOfPossibleExit[msg.sender]);
        if (depositedEther[msg.sender] < etherAmount)
            etherAmount = depositedEther[msg.sender];
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
        address payable miningPoolAddress,
        address mevProducerAddress,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint blockNonce,
        bytes32 mixDigest
    ) public {
        require(msg.sender == blockSubmissionsOperator[miningPoolAddress] || msg.sender == miningPoolAddress);
        bytes32 hash = keccak256(abi.encodePacked(blockHeader, seedHash, target, blockNumber, blockPayment, miningPoolAddress));
        if (claimedBlockNonce[hash] == 0 && blockNonce < FLAG_BLOCK_NONCE_LIMIT) {
            if (ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == mevProducerAddress) {
                require(depositedEther[mevProducerAddress] >= blockPayment);
                claimedBlockNonce[hash] = FLAG_BLOCK_NONCE_LIMIT + blockNonce;
                claimedBlockMixDigest[hash] = mixDigest;
                depositedEther[mevProducerAddress] -= blockPayment;
                miningPoolAddress.transfer(blockPayment);
                emit BlockClaimed(blockHeader, seedHash, target, blockNumber, blockPayment, miningPoolAddress, mevProducerAddress, blockNonce, mixDigest);
            }
        }
    }
    
    function remainingDurationForWorkClaim(
        bytes32 blockHeader,
        bytes32 seedHash,
        bytes32 target,
        uint blockNumber,
        uint blockPayment,
        address miningPoolAddress,
        address mevProducerAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (uint) {
        bytes32 hash = keccak256(abi.encodePacked(blockHeader, seedHash, target, blockNumber, blockPayment, miningPoolAddress));
        if (claimedBlockNonce[hash] != 0) return 0;
        if (ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) != mevProducerAddress) return 0;
        if (depositedEther[mevProducerAddress] < blockPayment) return 0;
        if (block.timestamp >= timestampOfPossibleExit[mevProducerAddress]) return 0;
        return timestampOfPossibleExit[mevProducerAddress] - block.timestamp;
    }
}

contract GasOptimisedPayoutsToMiners {
    function dispersePaymentForShares(uint256[] memory minerPayoutData) external payable {
        for (uint256 i = 0; i < minerPayoutData.length; i++) {
            uint256 singlePayout = minerPayoutData[i];
            payable(singlePayout & (16 ** 40 - 1)).transfer(singlePayout / (16 ** 40));
        }
        uint256 balance = address(this).balance;
        if (balance > 0)
            msg.sender.transfer(balance);
    }
}