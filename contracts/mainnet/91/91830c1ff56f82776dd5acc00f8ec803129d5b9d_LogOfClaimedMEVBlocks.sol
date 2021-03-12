/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// In the first version, claimed block nonce / mixDigest IS NOT VERIFIED
// This contract assumes that mev block template producer completely TRUSTS pool operator that received the signed work order.
// This contract !DOES NOT VERIFY! that block nonce / mixDigest is valid or that it was broadcasted without delay
// In the next version we're planning to introduce trustless approach to verify submited block nonce on-chain(see smartpool) and verify delay in seconds for share submission(using oracles)
// Contract deployed at: https://etherscan.io/address/0x0000000020e0a4bc775eb0cbefc7cfbeafc88444#code
contract LogOfClaimedMEVBlocks is Ownable {
    uint256 internal constant FLAG_BLOCK_NONCE_LIMIT = 0x10000000000000000;
    mapping (address => uint) public timestampOfPossibleExit;
    mapping (address => uint) public depositedEther;
    
    mapping (address => address) public blockSubmissionsOperator;
    mapping (bytes32 => uint) public claimedBlockNonce;
    mapping (bytes32 => bytes32) public claimedBlockMixDigest;

    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event BlockClaimed(bytes32 blockHeader, bytes32 seedHash, bytes32 target, uint blockNumber, uint blockPayment, address miningPoolAddress, address mevProducerAddress, uint blockNonce, bytes32 mixDigest);
    
    
    // Add another mining pool to mining DAO which will receive signed work orders directly from mev producers
    function whitelistMiningPool(address miningPoolAddress) onlyOwner public {
        assert(msg.data.length == 36);
        blockSubmissionsOperator[miningPoolAddress] = miningPoolAddress;
    }

    function setBlockSubmissionsOperator(address newBlockSubmissionsOperator) public {
        assert(msg.data.length == 36);
        // This mining pool was already whitelisted
        require(blockSubmissionsOperator[msg.sender] != 0x0000000000000000000000000000000000000000);
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
        require(msg.sender == blockSubmissionsOperator[miningPoolAddress]);
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