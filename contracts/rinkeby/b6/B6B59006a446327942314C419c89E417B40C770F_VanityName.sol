/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/**
 * @title Store a fancy name
 * @author Jeff Prestes
 * @notice This contract is for example purposes
 * @dev This contract avoids front running attacks
 * */
contract VanityName {

    /// bytes32 was selected to save gas and make easier some operations such as length
    bytes32 public name;

    uint256 public stake;
    uint256 public oldStake;
    address payable public owner;
    address payable public oldOwner;

    /// timelock is calculated in blocks to avoid malicious time changing from Miner.
    uint256 public timelock;
    
    /// cooldownPeriodInBlocks is the period (in blocks) where the user needs to be commited with the name before change it
    uint256 constant public cooldownPeriodInBlocks = 3;

    /// Fee per character 
    uint256 constant public feePerCharacter = 1 gwei;

    /// maxBlocksLock is maximum blocks user can lock the name
    uint256 constant public maxBlocksLock = 10;

    /// commits store the commits send by the proto owners of the name
    mapping(address => mapping(bytes32 => uint)) public commits;
    
    error ErrInvalidNameLength(uint nameLength);
    error ErrBlockToLockHigherThanAllowed(uint blocksTolock, uint maxBlocksLock);
    error ErrPreviousNameNotExpiredYet();
    error ErrInsufficientStakeValueSent(uint valueSent, uint mininumStake);
    error ErrNotCommited();
    error ErrCooldownNotExpired(uint blockWhenCommitHasBeenMade);
    
    event NewNameSet(address indexed owner, uint block, string name);

    /**
    @notice Store the commitment of a user to store a name. This commitment avoids front running attacks
    @param _nameHash name hashed using keccak256 the user wants to store
    @return returns true to help DApp developers to control what was the result of the operation
     */
    function commit(bytes32 _nameHash) external returns (bool) {
        commits[msg.sender][_nameHash] = block.number;
        return true;
    }

    /**
    @notice Helper function to make easier to the user to know what is the hash of the name
    @param _name desired fancy plain name in bytes32 to record
    @return returns a keccak256 hash
     */
    function getHashedName(bytes32 _name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }

    /** 
    @notice Change the name and/or ownership of it
    @dev user must send a value in ether to stake in to be allowed to lock the name. 
    @param _name desired fancy plain name in bytes32 to record
    @param _blocksTolock number of blocks the user wants to lock the name. It should be less than maxBlocksLock
    @return returns true to help DApp developers to control what was the result of the operation
    */
    function changeName(bytes32 _name, uint256 _blocksTolock) payable external returns (bool) {
        /*
        Using require for old solidity versions
        
        require(_name.length > 0, "Name needs at least have one character");
        require(_blocksTolock < maxBlocksLock, "The number of blocks to lock is not valid. Higher value.");
        require(block.number - timelock > 0, "Previous lock time has not expired yet");
        require(msg.value>calcNewStake(_name), "To change the name you need to stake more value");
        require(commits[msg.sender][getHashedName(_name)]>0, "You have not previously commited to change the name");
        require(block.number - commits[msg.sender][getHashedName(_name)] > cooldownPeriodInBlocks, "Your cooldown period has not expired yet");
        */
        
        if (_name.length < 1) revert ErrInvalidNameLength(_name.length);
        if (_blocksTolock > maxBlocksLock) revert ErrBlockToLockHigherThanAllowed(_blocksTolock, maxBlocksLock);
        if (block.number - timelock < 1) revert ErrPreviousNameNotExpiredYet();
        if (msg.value<calcNewStake(_name)) revert ErrInsufficientStakeValueSent(msg.value, calcNewStake(_name));
        if (commits[msg.sender][getHashedName(_name)]<1) revert ErrNotCommited();
        if (block.number - commits[msg.sender][getHashedName(_name)] < cooldownPeriodInBlocks) {
            revert ErrCooldownNotExpired(commits[msg.sender][getHashedName(_name)]);
        }
        
        oldStake = stake;
        stake = msg.value;
        oldOwner = owner;
        owner = payable(msg.sender);
        name = _name;
        timelock = block.number+_blocksTolock;
        commits[msg.sender][getHashedName(_name)] = 0;
        
        emit NewNameSet(owner, block.number, bytes32ToString(name));
        
        return true;
    }

    /**
    @notice calculates what would be the next value to be staked
    @param _name desired fancy plain name in bytes32 to record
    */
    function calcNewStake(bytes32 _name) public view returns (uint256) {
        uint8 i = 0;
        while(i < 32 && _name[i] != 0) {
            i++;
        }
        return stake + (i*feePerCharacter);
    }

    /**
    @notice Returns all information to check if a user is elegible to change the name
    @param _name desired fancy plain name in bytes32 to record
    @return blocknumber
    @return previous commit made by the user to be elegible to change the name
    @return cool down period in blocks the user needs to wait to change the name
    @return if user can or cannot change the name
    */
    function isElegibleToChangeName(bytes32 _name) public view returns (uint, uint, uint, uint, bool, bool) {
        return (
            block.number,
            commits[msg.sender][getHashedName(_name)],
            cooldownPeriodInBlocks,
            timelock,
            block.number - commits[msg.sender][getHashedName(_name)] > cooldownPeriodInBlocks,
            block.number - timelock > 0
        );
    }
    
    /**
     * @notice returns in string format the actual vanity name
     * @return vanity name in string format
     */
    function getStringName() external view returns (string memory) {
        return bytes32ToString(name);
    }

    /**
    @notice allow last name owner to get back her stake
    @return returns true to help DApp developers to control what was the result of the operation
    */
    function withdrawStake() external returns (bool) {
        require(msg.sender == oldOwner);
        uint256 withdrawValue = oldStake;
        oldStake = 0;
        (bool success, ) = oldOwner.call{value: withdrawValue}("");
        require(success, "Withdraw fails");
        return success;
    }
    
    
    /**
     * @notice simple helper function to generate string from bytes32
     * @return name in string format
     * 
     */ 
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}