/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.7.6;

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
// This contract assumes that MEV block template producer completely TRUSTS pool operator that received the signed work order.
// This contract !DOES NOT VERIFY! that block nonce / mixDigest is valid or that it was broadcasted without delay
// In the next version we're planning to introduce trustless approach to verify submited block nonce on-chain(see smartpool) and verify delay in seconds for share submission(using oracles)
contract LogOfClaimedMEVBlocks is Ownable {
    uint256 internal constant FLAG_BLOCK_NONCE_LIMIT = 0x10000000000000000;
    mapping (address => uint) public timestampOfPossibleExit;
    mapping (address => uint) public depositedEther;

    mapping (address => address) public blockSubmissionsOperator;
    mapping (bytes32 => uint) public claimedBlockNonce;

    event Deposit(address user, uint amount, uint updatedExitTime);
    event Withdraw(address user, uint amount);
    event BlockClaimed(bytes32 blockHeader, bytes32 seedHash, bytes32 target, uint blockNumber, uint blockPayment, address miningPoolAddress, address mevProducerAddress, uint blockNonce, bytes32 mixDigest);
    event PoolOperatorUpdate(address miningPoolAddress, address oldPoolOperator, address newPoolOperator);


    // Add another mining pool to mining DAO which will receive signed work orders directly from mev producers
    function whitelistMiningPool(address miningPoolAddress) onlyOwner external {
        assert(msg.data.length == 36);
        // Owner can't update submission operator for already active pool
        require(blockSubmissionsOperator[miningPoolAddress] == 0x0000000000000000000000000000000000000000);
        blockSubmissionsOperator[miningPoolAddress] = miningPoolAddress;
        emit PoolOperatorUpdate(miningPoolAddress, 0x0000000000000000000000000000000000000000, miningPoolAddress);
    }

    function setBlockSubmissionsOperator(address newBlockSubmissionsOperator) external {
        assert(msg.data.length == 36);
        address oldBlockSubmissionsOperator = blockSubmissionsOperator[msg.sender];
        // This mining pool was already whitelisted
        require(oldBlockSubmissionsOperator != 0x0000000000000000000000000000000000000000);
        blockSubmissionsOperator[msg.sender] = newBlockSubmissionsOperator;
        emit PoolOperatorUpdate(msg.sender, oldBlockSubmissionsOperator, newBlockSubmissionsOperator);
    }

    function depositAndLock(uint depositAmount, uint depositDuration) public payable {
        require(depositAmount == msg.value);
        // Enforcing min and max lockup durations
        require(depositDuration >= 24 * 60 * 60 && depositDuration <= 365 * 24 * 60 * 60);
        // You can always decrease you lockup time down to 1 day from the time of current block
        timestampOfPossibleExit[msg.sender] = block.timestamp + depositDuration;
        if (msg.value > 0) {
            depositedEther[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value, block.timestamp + depositDuration);
    }
    fallback () external payable {
        depositAndLock(msg.value, 24 * 60 * 60);
    }


    function withdrawEtherInternal(uint etherAmount) internal {
        require(depositedEther[msg.sender] > 0);
        // Deposit lockup period is over
        require(block.timestamp > timestampOfPossibleExit[msg.sender]);
        if (depositedEther[msg.sender] < etherAmount)
            etherAmount = depositedEther[msg.sender];
        depositedEther[msg.sender] -= etherAmount;
        payable(msg.sender).transfer(etherAmount);
        emit Withdraw(msg.sender, etherAmount);
    }
    function withdrawAll() external {
        withdrawEtherInternal((uint)(-1));
    }
    function withdraw(uint etherAmount) external {
        withdrawEtherInternal(etherAmount);
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
    ) external {
        require(msg.sender == blockSubmissionsOperator[miningPoolAddress]);
        bytes32 hash = keccak256(abi.encodePacked(blockHeader, seedHash, target, blockNumber, blockPayment, miningPoolAddress));
        if (claimedBlockNonce[hash] == 0 && blockNonce < FLAG_BLOCK_NONCE_LIMIT) {
            if (ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == mevProducerAddress) {
                require(depositedEther[mevProducerAddress] >= blockPayment);
                claimedBlockNonce[hash] = FLAG_BLOCK_NONCE_LIMIT + blockNonce;
                depositedEther[mevProducerAddress] -= blockPayment;
                miningPoolAddress.transfer(blockPayment);
                emit BlockClaimed(blockHeader, seedHash, target, blockNumber, blockPayment, miningPoolAddress, mevProducerAddress, blockNonce, mixDigest);
            }
        }
    }

    function checkValidityOfGetWork(
        bytes32 blockHeader,
        bytes32 seedHash,
        bytes32 target,
        uint blockNumber,
        uint blockPayment,
        address payable miningPoolAddress,
        address mevProducerAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool isWorkSignatureCorrect, uint remainingDuration) {
        bytes32 hash = keccak256(abi.encodePacked(blockHeader, seedHash, target, blockNumber, blockPayment, miningPoolAddress));
        if (claimedBlockNonce[hash] == 0) {
            if (ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == mevProducerAddress) {
                isWorkSignatureCorrect = true;
                if ((depositedEther[mevProducerAddress] >= blockPayment) && (timestampOfPossibleExit[mevProducerAddress] > block.timestamp)) {
                    remainingDuration = timestampOfPossibleExit[mevProducerAddress] - block.timestamp;
                }
            }
        }
    }
}