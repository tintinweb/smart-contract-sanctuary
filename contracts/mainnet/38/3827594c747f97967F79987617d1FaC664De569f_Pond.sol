// contracts/Pond.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IFrogGame {
    function transferFrom(address from, address to, uint tokenId) external;
}
interface ITadpole {
    function updateOriginActionBlockTime() external;
    function mintTo(address recepient, uint amount) external;
    function transfer(address to, uint amount) external;
} 

contract Pond is IERC721Receiver, ReentrancyGuard, Pausable {
    uint typeShift = 69000;

    bytes32 entropySauce;
    address constant nullAddress = address(0x0);

    uint constant public tadpolePerDay = 10000 ether;
    uint constant public tadpoleMax = 2000000000 ether;
    
    //tadpole claimed in total
    uint internal _tadpoleClaimed;
    //total rewards to be paid to every snake
    uint snakeReward;

    uint randomNounce=0;

    address public owner;
    IFrogGame internal frogGameContract;
    ITadpole internal tadpoleContract;

    uint[] internal snakesStaked;
    uint[] internal frogsStaked;

    uint internal _snakeTaxesCollected;
    uint internal _snakeTaxesPaid;

    bool public evacuationStarted;

    // map staked tokens IDs to staker address
    mapping(uint => address) stakedIdToStaker;
    // map staker address to staked ID's array
    mapping(address => uint[]) stakerToIds;
    // map staked tokens IDs to last reward claim time
    mapping(uint => uint) stakedIdToLastClaimTimestamp;
    // map staked tokens IDs to their positions in stakerToIds and snakesStaked or frogsStaked
    mapping(uint => uint[2]) stakedIdsToIndicies;
    // map every staked snake ID to reward claimed
    mapping(uint => uint) stakedSnakeToRewardPaid;
    // keep track of block where action was performed
    mapping(address => uint) callerToLastActionBlock;

    constructor() {
        owner=msg.sender;
    }

    //   _____ _        _    _             
    //  / ____| |      | |  (_)            
    // | (___ | |_ __ _| | ___ _ __   __ _ 
    //  \___ \| __/ _` | |/ / | '_ \ / _` |
    //  ____) | || (_| |   <| | | | | (_| |
    // |_____/ \__\__,_|_|\_\_|_| |_|\__, |
    //                                __/ |
    //                               |___/ 

    /// @dev Stake token
    function stakeToPond(uint[] calldata tokenIds) external noCheaters nonReentrant whenNotPaused {
        for (uint i=0;i<tokenIds.length;i++) {
            if (tokenIds[i]==0) { continue; }
            uint tokenId = tokenIds[i];

            stakedIdToStaker[tokenId] = msg.sender;
            stakedIdToLastClaimTimestamp[tokenId] = block.timestamp;
            
            uint stakerToIdsIndex = stakerToIds[msg.sender].length;
            stakerToIds[msg.sender].push(tokenId);

            uint stakedIndex;
            if (tokenId > typeShift)  {
                stakedSnakeToRewardPaid[tokenId]=snakeReward;
                stakedIndex=snakesStaked.length;
                snakesStaked.push(tokenId);
            } else {
                stakedIndex = frogsStaked.length;
                frogsStaked.push(tokenId);
            }
            stakedIdsToIndicies[tokenId]=[stakerToIdsIndex, stakedIndex];
            frogGameContract.transferFrom(msg.sender, address(this), tokenId);  
        }
    }

    /// @dev Claim reward by Id, unstake optionally 
    function _claimById(uint tokenId, bool unstake) internal {
        address staker = stakedIdToStaker[tokenId];
        require(staker!=nullAddress, "Token is not staked");
        require(staker==msg.sender, "You're not the staker");

        uint[2] memory indicies = stakedIdsToIndicies[tokenId];
        uint rewards;

        if (unstake) {
            // Remove staker address from the map
            stakedIdToStaker[tokenId] = nullAddress;
            // Replace the element we want to remove with the last element of array
            stakerToIds[msg.sender][indicies[0]] = stakerToIds[msg.sender][stakerToIds[msg.sender].length-1];
            // Update moved element with new index
            stakedIdsToIndicies[stakerToIds[msg.sender][stakerToIds[msg.sender].length-1]][0] = indicies[0];
            // Remove last element
            stakerToIds[msg.sender].pop();
        }

        if (tokenId > typeShift) {
            rewards=snakeReward-stakedSnakeToRewardPaid[tokenId];
            _snakeTaxesPaid+=rewards;
            stakedSnakeToRewardPaid[tokenId]=snakeReward;

            if (unstake) {
                stakedIdsToIndicies[snakesStaked[snakesStaked.length-1]][1]=indicies[1];
                snakesStaked[indicies[1]]=snakesStaked[snakesStaked.length-1];
                snakesStaked.pop();
            }
        } else {
            uint taxPercent = 20;
            uint tax;
            rewards = calculateRewardForFrogId(tokenId);
            _tadpoleClaimed += rewards;

            if (unstake) {
                //3 days requirement is active till there are $TOADPOLE left to mint
                if (_tadpoleClaimed < tadpoleMax) {
                    require(rewards >= 30000 ether, "3 days worth tadpole required to leave the Pond");
                }

                stakedIdsToIndicies[frogsStaked[frogsStaked.length-1]][1]=indicies[1];
                frogsStaked[indicies[1]]=frogsStaked[frogsStaked.length-1];
                frogsStaked.pop();

                uint stealRoll = _randomize(_rand(), "rewardStolen", (rewards + randomNounce++)) % 10000;
                // 50% chance to steal all tadpole accumulated by frog
                if (stealRoll < 5000) {
                    taxPercent = 100;
                } 
            }
            if (snakesStaked.length>0)
            {
                tax = rewards * taxPercent / 100;
                _snakeTaxesCollected+=tax;
                rewards = rewards - tax;
                snakeReward += tax / snakesStaked.length;
            }
        }
        stakedIdToLastClaimTimestamp[tokenId]=block.timestamp;

        if (rewards > 0) { tadpoleContract.transfer(msg.sender, rewards); }
        callerToLastActionBlock[tx.origin] = block.number;
        tadpoleContract.updateOriginActionBlockTime();
        if (unstake) {
            frogGameContract.transferFrom(address(this),msg.sender,tokenId);
        }
    }

    /// @dev Claim rewards by tokens IDs, unstake optionally
    function claimByIds(uint[] calldata tokenIds, bool unstake) external noCheaters nonReentrant whenNotPaused {
        uint length=tokenIds.length;
        for (uint i=length; i>0; i--) {
            _claimById(tokenIds[i-1], unstake);
        }
    }

    /// @dev Claim all rewards, unstake tokens optionally
    function claimAll(bool unstake) external noCheaters nonReentrant whenNotPaused {
        uint length=stakerToIds[msg.sender].length;
        for (uint i=length; i>0; i--) {
            _claimById(stakerToIds[msg.sender][i-1], unstake);
        }
    }

    // __      ___               
    // \ \    / (_)              
    //  \ \  / / _  _____      __
    //   \ \/ / | |/ _ \ \ /\ / /
    //    \  /  | |  __/\ V  V / 
    //     \/   |_|\___| \_/\_/  

    /// @dev Return the amount that can be claimed by specific token
    function claimableById(uint tokenId) public view noSameBlockAsAction returns (uint) {
        uint reward;
        if (stakedIdToStaker[tokenId]==nullAddress) {return 0;}
        if (tokenId>typeShift) { 
            reward=snakeReward-stakedSnakeToRewardPaid[tokenId];
        }
        else {
            uint pre_reward = (block.timestamp-stakedIdToLastClaimTimestamp[tokenId])*(tadpolePerDay/86400);
            reward = _tadpoleClaimed + pre_reward > tadpoleMax?tadpoleMax-_tadpoleClaimed:pre_reward;
        }
        return reward;
    }

    function evacuate(uint[] calldata tokenIds) external noCheaters nonReentrant {
        for (uint i=0;i<tokenIds.length;i++) {
            address staker = stakedIdToStaker[tokenIds[i]];
            require(evacuationStarted, "There was no evacuation signal");
            require(staker!=nullAddress, "Token is not staked");
            require(staker==msg.sender, "You're not the staker");

            uint tokenId=tokenIds[i];

            uint[2] memory indicies = stakedIdsToIndicies[tokenId];

            stakedIdToStaker[tokenId] = nullAddress;
            stakerToIds[msg.sender][indicies[0]]=stakerToIds[msg.sender][stakerToIds[msg.sender].length-1];
            stakedIdsToIndicies[stakerToIds[msg.sender][stakerToIds[msg.sender].length-1]][0]=indicies[0];
            stakerToIds[msg.sender].pop();

            if (tokenId>typeShift) {
                stakedIdsToIndicies[snakesStaked[snakesStaked.length-1]][1]=indicies[1];
                snakesStaked[indicies[1]]=snakesStaked[snakesStaked.length-1];
                snakesStaked.pop();
            } else {
                stakedIdsToIndicies[frogsStaked[frogsStaked.length-1]][1]=indicies[1];
                frogsStaked[indicies[1]]=frogsStaked[frogsStaked.length-1];
                frogsStaked.pop();
            }

            frogGameContract.transferFrom(address(this), msg.sender, tokenId);
        }
    }

    /// @dev total Snakes staked
    function snakesInPond() external view noSameBlockAsAction returns(uint) {
        return snakesStaked.length;
    }
    
    /// @dev total Frogs staked
    function frogsInPond() external view noSameBlockAsAction returns(uint) {
        return frogsStaked.length;
    }

    function snakeTaxesCollected() external view noSameBlockAsAction returns(uint) {
        return _snakeTaxesCollected;
    }

    function snakeTaxesPaid() external view noSameBlockAsAction returns(uint) {
        return _snakeTaxesPaid;
    }

    function tadpoleClaimed() external view noSameBlockAsAction returns(uint) {
        return _tadpoleClaimed;
    }

    function stakedByAddress(address _wallet)
        public
        view
        noSameBlockAsAction
        returns (uint256[] memory)
    {
        return stakerToIds[_wallet];
    }

    //   ____                           
    //  / __ \                          
    // | |  | |_      ___ __   ___ _ __ 
    // | |  | \ \ /\ / / '_ \ / _ \ '__|
    // | |__| |\ V  V /| | | |  __/ |   
    //  \____/  \_/\_/ |_| |_|\___|_|   
                                    

    function Pause() external onlyOwner {
        _pause();
    }

    function Unpause() external onlyOwner {
        _unpause();
    }

    function evacuationSwitch() external onlyOwner {
        evacuationStarted=!evacuationStarted;
    }

    /// @dev Set Tadpole contract address and init the interface
    function setTadpoleAddress(address _tadpoleAddress) external onlyOwner {
        tadpoleContract=ITadpole(_tadpoleAddress);
    }

    /// @dev Set FrogGame contract address and init the interface
    function setFrogGameAddress(address _frogGameAddress) external onlyOwner {
        frogGameContract=IFrogGame(_frogGameAddress);
    }
                         
    //  _    _ _   _ _ _ _         
    // | |  | | | (_) (_) |        
    // | |  | | |_ _| |_| |_ _   _ 
    // | |  | | __| | | | __| | | |
    // | |__| | |_| | | | |_| |_| |
    //  \____/ \__|_|_|_|\__|\__, |
    //                        __/ |
    //                       |___/ 

    /// @dev Create a bit more of randomness
    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    /// @dev Get random uint
    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, block.timestamp, entropySauce)));
    }

    /// @dev Utility function for FrogGame contract
    function getRandomSnakeOwner() external returns(address) {
        require(msg.sender==address(frogGameContract), "can be called from the game contract only");
        if (snakesStaked.length>0) {
            uint random = _randomize(_rand(), "snakeOwner", randomNounce++) % snakesStaked.length; 
            return stakedIdToStaker[snakesStaked[random]];
        } else return nullAddress;
    }

    /// @dev calculate reward for Frog based on timestamps and toadpole amount claimed
    function calculateRewardForFrogId(uint tokenId) internal view returns(uint) {
        uint reward = (block.timestamp-stakedIdToLastClaimTimestamp[tokenId])*(tadpolePerDay/86400);
        return ((_tadpoleClaimed + reward > tadpoleMax) ? (tadpoleMax - _tadpoleClaimed) : reward);
    }

    /// @dev Mint initial tadpole pool to the contract
    function mintTadpolePool() external onlyOwner() {
        tadpoleContract.mintTo(address(this), 2000000000 ether);
    }
    
    //  __  __           _ _  __ _               
    // |  \/  |         | (_)/ _(_)              
    // | \  / | ___   __| |_| |_ _  ___ _ __ ___ 
    // | |\/| |/ _ \ / _` | |  _| |/ _ \ '__/ __|
    // | |  | | (_) | (_| | | | | |  __/ |  \__ \
    // |_|  |_|\___/ \__,_|_|_| |_|\___|_|  |___/

    modifier noCheaters() {
        // WL for frogGameContract
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(msg.sender == tx.origin , "you're trying to cheat!");
        require(size == 0,                "you're trying to cheat!");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(msg.sender, block.coinbase));
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    /// @dev Don't allow view functions in same block as action that changed the state
    modifier noSameBlockAsAction() {
        require(callerToLastActionBlock[tx.origin] < block.number, "Please try again on next block");
        _;
    }
    
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Pond directly");
      return IERC721Receiver.onERC721Received.selector;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}