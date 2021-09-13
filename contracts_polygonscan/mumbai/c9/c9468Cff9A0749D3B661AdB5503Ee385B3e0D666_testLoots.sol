/**
 *Submitted for verification at polygonscan.com on 2021-09-12
*/

// Sources flattened with hardhat v2.6.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/ILootProject.sol


pragma solidity ^0.8.4;
interface LootProject {

    function getWeapon(uint256 tokenId) external view returns (string memory);

    function getChest(uint256 tokenId) external view returns (string memory);

    function getHead(uint256 tokenId) external view returns (string memory);

    function getWaist(uint256 tokenId) external view returns (string memory);

    function getFoot(uint256 tokenId) external view returns (string memory);

    function getHand(uint256 tokenId) external view returns (string memory);

    function getNeck(uint256 tokenId) external view returns (string memory);

    function getRing(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;

}


// File contracts/BattleLoot.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract testLoots is Ownable {
    
    LootProject public mmloot; // mapping mloot on polygon network

    IERC20 public rewardToken;

    uint256 public rewardAmountPerRound;

    uint256 public constant MAXROUND = 10;

    uint256 public totalWarriors;

    struct BattleByRanking {
        address acceptorAddress;
        uint256 challengerRanking;
        uint256 acceptorRanking;
        uint256 failNumber;
        bool result;
    }

    struct BattleByRarityIndex {
        address acceptorAddress;
        uint256 challengerPower;
        uint256 acceptorPower;
        uint256 failNumber;
        bool result;
    }

    struct Warriors {
        address warriorAddress;
        uint256[] originalTokenIds;
        uint256[] rarityRankings;
        uint256[] rarityIndexes;
    }

    mapping ( address => BattleByRanking ) public battleDetailsByRanking;

    mapping ( address => BattleByRarityIndex ) public battleDetailsByRarityIndex;

    // record candidate warriors.
    mapping ( uint256 => Warriors ) public candidateWarriors;

    // the number among warriors.
    mapping ( address => uint256 ) public warriorsIndex;

    // record account's claimable reward.
    mapping ( address => uint256 ) private claimableReward;

    constructor (
        address _mmlootaddress, 
        address rewardTokenAddress
        ) {
        mmloot = LootProject(_mmlootaddress);
        rewardToken = IERC20(rewardTokenAddress);
    }

    /** ========== public view functions ========== */

    function getPlayerStakedToken() public view returns (uint256[] memory) {
        return candidateWarriors[warriorsIndex[_msgSender()]].originalTokenIds;
    }

    function getClaimableReward(address account) public view returns (uint256 rewardAmount) {
        return claimableReward[account];
    }


    /** ========== external mutative functions ========== */

    function pvpBattleByRanking(uint256 tokenId) external {
        address challengerAddress = _msgSender();
        require(warriorsIndex[challengerAddress] != 0, "pvpBattleByRanking: please register your role at first");
        require(_checkTokenExisted(tokenId), "pvpBattleByRanking: please register tokenId first");
        
        // get warriors message 
        uint256 warriorIndex = warriorsIndex[challengerAddress];
        Warriors memory challenger = candidateWarriors[warriorIndex];

        // select a random candidate warriors by challenger's basic power.
        uint256 rand = uint256(keccak256(abi.encodePacked(toString(tokenId), toString(block.timestamp))));
        uint256 randomWarriorNumber = rand % totalWarriors;
        Warriors memory acceptor = candidateWarriors[randomWarriorNumber];

        // select random tokenId from accpetor.
        uint256 randomWarriorTokenId = acceptor.originalTokenIds[(rand % acceptor.originalTokenIds.length) - 1];
        
        // pvp battle
        (uint256 _warriorRanking, ) = _getRarityMessageByTokenId(challenger.warriorAddress ,tokenId);
        (uint256 _acceptorRanking, ) = _getRarityMessageByTokenId(acceptor.warriorAddress ,randomWarriorTokenId);

        battleDetailsByRanking[challengerAddress].acceptorAddress = acceptor.warriorAddress;
        battleDetailsByRanking[challengerAddress].challengerRanking = _warriorRanking;
        battleDetailsByRanking[challengerAddress].acceptorRanking = _acceptorRanking;

        if(_warriorRanking < _acceptorRanking) {
            battleDetailsByRanking[challengerAddress].result = true;
            
            _recordRewardAmount(challengerAddress);
        } else {
            
            battleDetailsByRanking[challengerAddress].result = false;
            battleDetailsByRanking[challengerAddress].failNumber++;

            if(battleDetailsByRanking[challengerAddress].failNumber == 5) {
                _recordRewardAmount(challengerAddress);
                battleDetailsByRanking[challengerAddress].failNumber = 0;
            }
        }
        
        emit pvpBattledByRanking(challengerAddress, acceptor.warriorAddress, battleDetailsByRanking[challengerAddress].result);
    }


    function pvpBattleByRarityIndex(uint256 tokenId) external {
        address challengerAddress = _msgSender();
        require(warriorsIndex[challengerAddress] != 0, "pvpBattleByRarityIndex: please register your role at first");
        require(_checkTokenExisted(tokenId), "pvpBattleByRarityIndex: please register tokenId first");


        // get warriors message
        uint256 warriorIndex = warriorsIndex[challengerAddress];
        Warriors memory challenger = candidateWarriors[warriorIndex];

        // select a random candidate warriors by challenger's basic power.
        uint256 rand = uint256(keccak256(abi.encodePacked(toString(tokenId), toString(block.timestamp))));
        uint256 randomWarriorNumber = rand % totalWarriors;
        Warriors memory acceptor = candidateWarriors[randomWarriorNumber];

        // select random tokenId from accpetor.
        uint256 randomWarriorTokenId = acceptor.originalTokenIds[(rand % acceptor.originalTokenIds.length) - 1];

        // pvp battle
        (, uint256 warriorRarityindex) = _getRarityMessageByTokenId(challenger.warriorAddress, tokenId);
        (,uint256 acceptorRarityindex) = _getRarityMessageByTokenId(acceptor.warriorAddress, randomWarriorTokenId);

        uint256 warriorPower = _calculateRandomScore(warriorRarityindex, tokenId);
        uint256 acceptorPower = _calculateRandomScore(acceptorRarityindex, randomWarriorTokenId);

        battleDetailsByRarityIndex[challengerAddress].acceptorAddress = acceptor.warriorAddress;
        battleDetailsByRarityIndex[challengerAddress].challengerPower = warriorPower;
        battleDetailsByRarityIndex[challengerAddress].acceptorPower = acceptorPower;

        if(warriorPower > acceptorPower) {
            battleDetailsByRarityIndex[challengerAddress].result = true;
            
            _recordRewardAmount(challengerAddress);
        } else {
            
            battleDetailsByRarityIndex[challengerAddress].result = false;
            battleDetailsByRarityIndex[challengerAddress].failNumber++;

            if(battleDetailsByRarityIndex[challengerAddress].failNumber == 5) {
                _recordRewardAmount(challengerAddress);
                battleDetailsByRarityIndex[challengerAddress].failNumber = 0;
            }
        }
        
        emit pvpBattledByRarityIndex(challengerAddress, acceptor.warriorAddress, battleDetailsByRarityIndex[challengerAddress].result);

    }


    function registerRole(
        uint256 tokenId, 
        uint256 _rartiyRanking, 
        uint256 _rarityIndex
        ) external {

        // transfer your fight token
        require(mmloot.ownerOf(tokenId) == _msgSender(), "createRole: you do not own the nft");
        mmloot.transferFrom(_msgSender(), address(this), tokenId);

        uint256 warriorId;

        if(warriorsIndex[_msgSender()] == 0) {
            warriorId = totalWarriors + 1;
            totalWarriors++;
            warriorsIndex[_msgSender()] = warriorId;
        } else { warriorId = warriorsIndex[_msgSender()]; }
        
        candidateWarriors[warriorId].originalTokenIds.push(tokenId);
        candidateWarriors[warriorId].rarityRankings.push(_rartiyRanking);
        candidateWarriors[warriorId].warriorAddress = _msgSender();
        candidateWarriors[warriorId].rarityIndexes.push(_rarityIndex);

        emit roleRegistered(_msgSender(), tokenId, _rartiyRanking, _rarityIndex);
    }

    function quitFromGame(uint256 tokenId) external {        

        // delete player tokenId
        require(_checkTokenExisted(tokenId), "quitFromGame: Sorry, you're not a candidate warrior.");
        require(_deleteTokenIdRecords(tokenId), "quitFromGame: fail to delete tokenId records");

        // check player records and delete player records if no tokenId exists.
        if(candidateWarriors[warriorsIndex[_msgSender()]].originalTokenIds.length == 0) {
            delete warriorsIndex[_msgSender()];
            totalWarriors--;
        }

        // return player's token
        mmloot.transferFrom(address(this), _msgSender(), tokenId);

        emit roleQuit(tokenId, _msgSender());
    }


    // users claim their reward

    function claim() external {
        require(claimableReward[_msgSender()] >= rewardToken.balanceOf(address(this)), "claim: no enough token to claim");

        rewardToken.transfer(_msgSender(), claimableReward[_msgSender()]);

        emit rewardTokenClaimed(_msgSender(), claimableReward[_msgSender()]);
    }


    /** ========== exteranl mutative onlyOwner functions ========== */

    function updateRewardToken(address newRewardToken) external onlyOwner {
        rewardToken = IERC20(newRewardToken);

        emit rewardTokenUpdated(newRewardToken);
    }

    function refundRewardToken(address receiver) external onlyOwner {
        uint256 totalAmount = rewardToken.balanceOf(address(this));
        rewardToken.transfer(receiver, totalAmount);

        emit rewardTokenRefund(receiver, totalAmount);
    }

    function updateMMLoot(address newMMLoot) external onlyOwner {
        mmloot = LootProject(newMMLoot);
    }

    /** ========== internal view functions ========== */

    // calculate random score basing on user's rarityscore of the nft
    function _calculateRandomScore(uint256 _rarityScore, uint256 tokenId) internal view returns (uint256 randomScore) {
        uint256 rand = uint256(keccak256(abi.encodePacked(toString(tokenId), toString(_rarityScore), toString(block.timestamp))));
        (uint256 minScore, uint256 maxScore) = _getScoreRange(_rarityScore);
        uint256 levelRange = maxScore - minScore;
        
        return randomScore = (rand % levelRange) + minScore;
    }

    function _getScoreRange(uint256 _rarityScore) internal pure returns (uint256 minScore, uint256 maxScore) {
        require(_rarityScore != 0, "rarity score of loot must not be null");
        
        if(_rarityScore > 1500000 && _rarityScore <= 2000000) {
            return _calculateRange(_rarityScore, 5);
        } else if(_rarityScore > 2000000 && _rarityScore <= 2500000) {
            return _calculateRange(_rarityScore, 10);
        } else if(_rarityScore > 2500000 && _rarityScore <= 3000000) {
            return _calculateRange(_rarityScore, 15);
        } else if(_rarityScore > 3000000 && _rarityScore <= 3500000) {
            return _calculateRange(_rarityScore, 20);
        } else if(_rarityScore > 3500000 && _rarityScore <= 4100000) {
            return _calculateRange(_rarityScore, 25);
        }
    }

    function _calculateRange(uint256 _rarityScore, uint256 ratio) internal pure returns (uint256, uint256) {
        uint256 minScore = _rarityScore - _rarityScore * ratio / 100;
        uint256 maxScore = _rarityScore + _rarityScore * ratio / 100;
        return (minScore, maxScore);
    }

    function _checkTokenExisted(uint256 tokenId) internal view returns (bool deleted) {
        uint256[] memory tokenIds = candidateWarriors[warriorsIndex[_msgSender()]].originalTokenIds;
        for(uint256 i = 0; i < tokenIds.length; i++ ){
            if(tokenId == tokenIds[i]) {
                deleted = true;
            }

            deleted = false;
        }
    }

    function _getRarityMessageByTokenId(address account, uint256 tokenId) internal view returns (uint256 ranking, uint256 index) {
        uint256[] memory tokenIds = candidateWarriors[warriorsIndex[account]].originalTokenIds;
        uint256[] memory rankings = candidateWarriors[warriorsIndex[account]].rarityRankings;
        uint256[] memory rarityindexes = candidateWarriors[warriorsIndex[account]].rarityIndexes;

        require(tokenIds.length == rankings.length && rankings.length == rarityindexes.length, "not match");

        for(uint256 i = 0; i < tokenIds.length; i++ ) {
            if(tokenId == tokenIds[i]) {
                ranking = rankings[i];
                index = rarityindexes[i];
            }
        }
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /** ========== internal mutative functions ========== */

    function _deleteTokenIdRecords(uint256 tokenId) internal returns (bool deleted) {
        Warriors storage warriro = candidateWarriors[warriorsIndex[_msgSender()]];
        uint256[] memory tokenIds = warriro.originalTokenIds;

        for(uint256 i = 0; i < tokenIds.length; i++ ) {
            if(tokenId == tokenIds[i]) {
                delete warriro.originalTokenIds[i];
                delete warriro.rarityRankings[i];
                delete warriro.rarityIndexes[i];

                deleted = true;
            }

            deleted = false;
        }
    }

    function _recordRewardAmount(address account) internal {
        claimableReward[account] += rewardAmountPerRound;

        emit recordedReward(account, claimableReward[account]);
    }


    /** ========== event ========== */

    event roleRegistered(address indexed role, uint256 indexed tokenId, uint256 rarityRanking, uint256 rarityIndex);

    event pvpBattledByRanking(address indexed warriorAddress, address acceptorAddress, bool result);

    event pvpBattledByRarityIndex(address indexed warriorAddress, address acceptorAddress, bool result);

    event roleQuit(uint256 indexed tokenId, address playerAddress);

    event rewardTokenUpdated(address indexed newRewardToken);

    event rewardTokenRefund(address indexed receiver, uint256 totalAmount);

    event recordedReward(address indexed receiver, uint256 totalAmount);

    event rewardTokenClaimed(address indexed receiver, uint256 claimedToken);
}