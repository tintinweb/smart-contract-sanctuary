// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IMiner.sol";
import "./interfaces/IERC721Enumerable.sol";
import "./library/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

interface IMinerNFT is IERC721, IMiner{
}

interface ISpice {
    function mint(address to, uint256 amount) external;
}

interface IShieldNFT is IERC721Enumerable {
    function mintFromMiner(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function minerIdToLastTimestamp(uint256 tokenId) external view returns(uint256);
}

interface IStakeCard {
    function mintFromMiner(address to, uint256 minerId) external;
}

interface IBattlePVP {
    function deposit(address _owner, uint16 _tokenId) external;
    function withdraw(uint16 _tokenId) external;
}

contract Barn is IERC721Receiver, OwnableUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event MinerClaimed(address indexed owner, uint256 indexed tokenId, uint256 earned, uint256 tax, bool unstaked);
    event LooterClaimed(address indexed owner, uint256 indexed tokenId, uint256 earned, bool unstaked);

    IMinerNFT public miner;
    ISpice public spice;


    // maps tokenId to stake
    mapping(uint256 => Stake) public barn; 

    // maps level to all Looter stakes with that level
    mapping(uint256 => Stake[]) public pack;

    // tracks location of each Wolf in Pack
    mapping(uint256 => uint256) public packIndices; 

    // total level scores staked
    uint256 public totalLevelStaked; 

    // any rewards distributed when no looters are staked
    uint256 public unaccountedRewards; 

    // amount of $SPICE due for each level point staked
    uint256 public spicePerLevel;

    // miner earn $SPICE per day
    uint256[8] public DAILY_SPICE_EARN;
    
    // miners must have 2 days worth of $SPICE to unstake or else it's too cold
    uint256 public MINIMUM_TO_EXIT;

    // looters take a 20% tax on all $SPICE claimed
    uint256 public constant MINER_CLAIM_TAX_PERCENTAGE = 20;

    // there will only ever be (roughly) 0.4 billion $SPICE earned through staking
    uint256 public constant MAXIMUM_GLOBAL_SPICE = 400000000 ether;

    // amount of $SPICE earned so far
    uint256 public totalSpiceEarned;

    // number of Miner staked in the Barn for each level
    uint256[8] public totalMinerStakedOfEachLevel;

    // the last time $SPICE was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $SPICE
    bool public rescueEnabled;

    mapping(address=>uint16[]) public mapUserNfts;

    uint8 public maxPerAmount;

    IShieldNFT public shield;
    IStakeCard public stakeCard;

    uint256[5] public lootersBuf;

    IBattlePVP public battlePVP;

    function initialize(address _miner, address _spice) external initializer {
        require(_miner != address(0));
        require(_spice != address(0));

        __Ownable_init();
        __Pausable_init();

        miner = IMinerNFT(_miner);
        spice = ISpice(_spice);
        rescueEnabled = false;
        totalLevelStaked = 0;
        unaccountedRewards = 0;
        spicePerLevel = 0;
        maxPerAmount = 20;

        DAILY_SPICE_EARN = [300 ether, 600 ether, 1200 ether, 2400 ether, 4800 ether, 7500 ether, 15000 ether, 36000 ether];
        lootersBuf = [1,2,4,8,16];

        MINIMUM_TO_EXIT = 2 days;
    }

    function setMaxPerAmount(uint8 _maxPerAmount) external onlyOwner {
        require(_maxPerAmount != 0 && _maxPerAmount <= 100);
        maxPerAmount = _maxPerAmount;
    }

    function setShield(address _shield) external onlyOwner {
        require(_shield != address(0), "Invalid address");
        shield = IShieldNFT(_shield);
    }

    function setStakeCard(address _card) external onlyOwner {
        require(_card != address(0), "Invalid address");
        stakeCard = IStakeCard(_card);
    }

    function setDailySpiceEarn(uint256[8] memory _earn) external onlyOwner {
        for (uint256 i = 0; i < 8; ++i) {
            DAILY_SPICE_EARN[i] = _earn[i] * 1e18;
        }
    }

    function setLootersBuf(uint256[5] memory _buf) external onlyOwner {
        for (uint256 i = 0; i < 5; ++i) {
            lootersBuf[i] = _buf[i];
        }
    }

    function setRescueEnabled(bool _rescueEnabled) external onlyOwner {
        rescueEnabled = _rescueEnabled;
    }

    function setMINIMUMTOEXIT(uint256 _MinimumToExit) external onlyOwner {
        MINIMUM_TO_EXIT = _MinimumToExit;
    }

    function setBattlePVP(address _battle) external onlyOwner {
        battlePVP = IBattlePVP(_battle);
    }

    /** STAKING */

    /**
     * adds Miners and Looters to the Barn and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the Minters and Looters to stake
    */
    function addManyToBarnAndPack(address account, uint16[] calldata tokenIds) external {
        require(account == _msgSender() || _msgSender() == address(miner), "DONT GIVE YOUR TOKENS AWAY");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(miner)) { // dont do this step if its a mint + stake
                require(miner.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
                miner.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            //nftType 0: miner 1: looter
            if (nftType(tokenIds[i]) == 0) 
                _addMinerToBarn(account, tokenIds[i]);
            else 
                _addLooterToPack(account, tokenIds[i]);

            mapUserNfts[account].push(tokenIds[i]);
            _depoist(account, tokenIds[i]);
        }
    }

    /**
     * adds Miners and Looters to the Barn and Pack
     * @param tokenId the ID of the Minters and Looters to stake
    */
    function addToBarnAndPack(uint16 tokenId) external {
        require(tokenId > 0, "INVALID TOKEN ID");
        require(miner.ownerOf(tokenId) == _msgSender(), "AINT YO TOKEN");
        miner.transferFrom(_msgSender(), address(this), tokenId);

        address account = _msgSender();
        //nftType 0: miner 1: looter
        if (nftType(tokenId) == 0) 
            _addMinerToBarn(account, tokenId);
        else 
            _addLooterToPack(account, tokenId);

        mapUserNfts[account].push(tokenId);
        _depoist(account, tokenId);
    }

    /**
     * adds a single Miner to the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Miner to add to the Barn
    */
    function _addMinerToBarn(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        uint8 level = nftLevel(tokenId);
        require(level > 0, "Invalid level");
        barn[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        totalMinerStakedOfEachLevel[level - 1] += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single Looter to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Looter to add to the Pack
    */
    function _addLooterToPack(address account, uint256 tokenId) internal whenNotPaused {
        uint8 level = nftLevel(tokenId);
        require(level > 0, "Invalid level");
        totalLevelStaked = totalLevelStaked.add(lootersBuf[level-1]); // Portion of earnings ranges from 1 to 5
        packIndices[tokenId] = pack[level].length; // Store the location of the Looter in the Pack
        pack[level].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(spicePerLevel)
        })); // Add the looter to the Pack
        emit TokenStaked(account, tokenId, spicePerLevel);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $SPICE earnings and optionally unstake tokens from the Barn / Pack
     * to unstake a Miner it will require it has 2 days worth of $SPICE unclaimed
     * @param tokenId the ID of the token to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     * @param useShield whether or not to use shield
    */
    function claimFromBarnAndPack(uint16 tokenId, bool unstake, bool useShield) external whenNotPaused _updateEarnings {
        require(tx.origin == _msgSender(), "Not EOA");
        uint256 owed = 0;
        if (nftType(tokenId) == 0)
            owed += _claimMinerFromBarn(tokenId, unstake, useShield);
        else
            owed += _claimLooterFromPack(tokenId, unstake);

        if (unstake) {
            uint16[] memory userTokendIds = mapUserNfts[_msgSender()];
            for (uint j = 0; j < userTokendIds.length; ++j) {
                if (userTokendIds[j] == tokenId) {
                    uint16 lastId = userTokendIds[userTokendIds.length - 1];
                    mapUserNfts[_msgSender()][j] = lastId;
                    mapUserNfts[_msgSender()].pop();
                    break;
                }
            }

            if (mapUserNfts[_msgSender()].length == 0) {
                delete mapUserNfts[_msgSender()];
            }
            _withdraw(tokenId);
        }

        if (owed == 0) return;
        spice.mint(_msgSender(), owed);
    }

    /**
     * realize $SPICE earnings for a single Miners and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Looters
     * if unstaking, there is a 50% chance all $SPICE is stolen
     * @param tokenId the ID of the Miners to claim earnings from
     * @param unstake whether or not to unstake the Miners
     * @param useShield whether or not to use shield
     * @return owed - the amount of $SPICE earned
    */
    function _claimMinerFromBarn(uint256 tokenId, bool unstake, bool useShield) internal returns (uint256 owed) {
        require(miner.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
        if (useShield) {
            uint256 shieldId = shield.tokenOfOwnerByIndex(msg.sender, 0);
            require(shieldId > 0, "Invalid token Id");
            shield.safeTransferFrom(_msgSender(), address(this), shieldId, "");
            shield.burn(shieldId);
        }

        Stake memory stake = barn[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S SPICE");
        
        uint8 level = nftLevel(tokenId);
        require(level > 0, "Invalid level"); 

        if (totalSpiceEarned < MAXIMUM_GLOBAL_SPICE) {
            owed = (block.timestamp - stake.value) * DAILY_SPICE_EARN[level - 1] / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $SPICE production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * DAILY_SPICE_EARN[level - 1] / 1 days; // stop earning additional $SPICE if it's all been earned
        }
        uint256 tax = 0;
        if (unstake) {
            if (useShield == false) {
                if (random(tokenId) & 1 == 1) { // 50% chance of all $SPICE stolen
                    tax = owed;
                    _payLooterTax(tax);
                    owed = 0;
                }
            }
            delete barn[tokenId];
            totalMinerStakedOfEachLevel[level - 1] -= 1;
            miner.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Miner
        } else {
            if (useShield == false) {
                tax = owed * MINER_CLAIM_TAX_PERCENTAGE / 100;
                _payLooterTax(tax); // percentage tax to staked Looters
                owed -= tax; // remainder goes to Miner owner
            }
            
            barn[tokenId].value = uint80(block.timestamp); // reset stake value
        }
        emit MinerClaimed(stake.owner, tokenId, owed, tax, unstake);
    }

    /**
     * realize $SPICE earnings for a single Looter and optionally unstake it
     * Wolves earn $SPICE proportional to their Level rank
     * @param tokenId the ID of the Looter to claim earnings from
     * @param unstake whether or not to unstake the Looter
     * @return owed - the amount of $SPICE earned
    */
    function _claimLooterFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(miner.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
        uint8 level = nftLevel(tokenId);
        require(level > 0, "Invalid level"); 
        uint256 pos = packIndices[tokenId];
        Stake memory stake = pack[level][pos];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        uint256 buf = lootersBuf[level - 1];
        owed = (buf) * (spicePerLevel - stake.value); // Calculate portion of tokens based on Level
        if (unstake) {
            totalLevelStaked = totalLevelStaked.sub(lootersBuf[level-1]); // Remove Level from total staked
            Stake memory lastStake = pack[level][pack[level].length - 1];
            pack[level][pos] = lastStake; // Shuffle last Looter to current position
            packIndices[lastStake.tokenId] = pos;
            pack[level].pop(); // Remove duplicate
            delete packIndices[tokenId]; // Delete old mapping
            miner.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Looter
        } else {
            pack[level][pos].value = uint80(spicePerLevel);
        }
        emit LooterClaimed(stake.owner, tokenId, owed, unstake);
    }

    function rescue() external {
        require(tx.origin == _msgSender(), "Not EOA");
        require(rescueEnabled, "RESCUE DISABLED");

        uint16[] memory userTokenIds = mapUserNfts[_msgSender()];
        for (uint8 i = 0; i < userTokenIds.length; ++i) {
            uint256 tokenId = userTokenIds[i];
            miner.transferFrom(address(this), _msgSender(), tokenId);
        }

        delete mapUserNfts[_msgSender()];
    }

    /*function rescue(uint256[] calldata tokenIds) external {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint16[] memory userTokendIds = mapUserNfts[_msgSender()];
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (nftType(tokenId) == 0) {
                stake = barn[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                delete barn[tokenId];
                uint8 level = nftLevel(tokenId);
                require(level > 0, "Invalid level"); 
                totalMinerStakedOfEachLevel[level - 1] -= 1;
                miner.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Miner
                emit MinerClaimed(stake.owner, tokenId, 0, 0, true);
            } else {
                uint8 level = nftLevel(tokenId);
                require(level > 0, "Invalid level"); 
                uint256 pos = packIndices[tokenId];
                stake = pack[level][pos];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalLevelStaked = totalLevelStaked.sub(lootersBuf[level-1]); // Remove Level from total staked
                lastStake = pack[level][pack[level].length - 1];
                pack[level][pos] = lastStake; // Shuffle last Wolf to current position
                packIndices[lastStake.tokenId] = pos;
                pack[level].pop(); // Remove duplicate
                delete packIndices[tokenId]; // Delete old mapping
                miner.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Looter
                emit LooterClaimed(stake.owner, tokenId, 0, true);
            }

            for (uint j = 0; j < userTokendIds.length; ++j) {
                if (userTokendIds[j] == tokenId) {
                    uint16 lastId = userTokendIds[userTokendIds.length - 1];
                    mapUserNfts[_msgSender()][j] = lastId;
                    mapUserNfts[_msgSender()].pop();
                    break;
                }
            }
        }

        if (mapUserNfts[_msgSender()].length == 0) {
            delete mapUserNfts[_msgSender()];
        }
    }*/

    function drawShieldCard(uint256 _tokenId) external {
        require(tx.origin == _msgSender(), "Only EOA");
        require(barn[_tokenId].owner == _msgSender(), "No Auth");
        shield.mintFromMiner(_msgSender(), _tokenId);
    }

    /** ACCOUNTING */

    /** 
     * add $SPICE to claimable pot for the Pack
     * @param amount $SPICE to add to the pot
    */
    function _payLooterTax(uint256 amount) internal {
        if (totalLevelStaked == 0) { // if there's no staked looters
            unaccountedRewards += amount; // keep track of $SPICE due to looters
            return;
        }
        // makes sure to include any unaccounted $SPICE 
        spicePerLevel += (amount + unaccountedRewards) / totalLevelStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $SPICE earnings to ensure it stops once 0.4 billion is eclipsed
    */
    modifier _updateEarnings() {
        if (lastClaimTimestamp >= block.timestamp) {
            return;
        }

        if (totalSpiceEarned < MAXIMUM_GLOBAL_SPICE) {
            for (uint256 i = 0; i < 8; ++i) {
                uint256 stakedCount = totalMinerStakedOfEachLevel[i];
                if (stakedCount == 0) {
                    continue;
                }

                uint256 earned = (block.timestamp - lastClaimTimestamp) * stakedCount * DAILY_SPICE_EARN[i] / 1 days;
                totalSpiceEarned += earned;
            }
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /**
     * chooses a random Looter thief when a newly minted token is stolen
     * @param seed a random value to choose a Looter from
     * @return the owner of the randomly selected Looter thief
    */
    function randomLooterOwner(uint256 seed) external view returns (address) {
        if (totalLevelStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalLevelStaked; // choose a value from 0 to total level staked
        uint256 cumulative = 0;
        seed >>= 32;
        // loop through each bucket of Looters with the same level score
        for (uint i = 1; i <= 5; i++) {
            cumulative += pack[i].length * lootersBuf[i-1];
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Looter with that level score
            return pack[i][seed % pack[i].length].owner;
        }   
        return address(0x0);
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
    */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
        )));
    }

    /**
     * @param tokenId the ID of the token to check
     * @return nftType_
    */
    function nftType(uint256 tokenId) public view returns (uint8) {
        IMiner.MinerLooter memory nft = miner.getTokenTraits(tokenId);
        return nft.nftType;
    }

    /**
     * @param tokenId the ID of the token to check
     * @return level_
    */
    function nftLevel(uint256 tokenId) public view returns (uint8) {
        IMiner.MinerLooter memory nft = miner.getTokenTraits(tokenId);
        return nft.level;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        IMiner.MinerLooter memory nft = miner.getTokenTraits(tokenId);
        if (nft.nftType == 0) { // Miner
            Stake memory stake = barn[tokenId];
            return stake.owner;
        } else { // Looter
            Stake memory stake = pack[nft.level][packIndices[tokenId]];
            return stake.owner;
        }
    }

    function balanceOf(address _user) public view returns (uint256) {
        return mapUserNfts[_user].length;
    }

    struct NFT {
        uint256 tokenId;
        uint8 generation;
        uint8 nftType;
        uint8 gender;
        uint8 level;
        uint256 claimLastTimestamp;
        uint256 shieldLastTimestamp;
    }

    function getUserNFT(address _user, uint256 _index, uint8 _len) public view returns(NFT[] memory nfts, uint8 len) {
        require(_len <= maxPerAmount && _len != 0);
        nfts = new NFT[](_len);
        len = 0;

        uint256 bal = balanceOf(_user);
        if (bal == 0 || _index >= bal) {
            return (nfts, len);
        }

        uint16[] memory userTokenIds = mapUserNfts[_user];
        for (uint8 i = 0; i < _len; ++i) {
            uint256 tokenId = userTokenIds[_index];
            nfts[i].tokenId = tokenId;
            IMiner.MinerLooter memory nft = miner.getTokenTraits(tokenId);
            nfts[i].generation = nft.generation;
            nfts[i].nftType = nft.nftType;
            nfts[i].gender = nft.gender;
            nfts[i].level = nft.level;
            if (nft.nftType == 0) {
                nfts[i].claimLastTimestamp = barn[tokenId].value;
                nfts[i].shieldLastTimestamp = shield.minerIdToLastTimestamp(tokenId);
            }

            ++_index;
            ++len;
            if (_index >= bal) {
                return (nfts, len);
            }
        }
    }

    function _depoist(address _owner, uint16 _tokenId) internal {
        if (address(battlePVP) != address(0)) {
            battlePVP.deposit(_owner, _tokenId);   
        }
    }

    function _withdraw(uint16 _tokenId) internal {
        if (address(battlePVP) != address(0)) {
            battlePVP.withdraw(_tokenId);   
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IMiner {
  // struct to store each token's traits
  struct MinerLooter {
    uint8 generation;
    uint8 nftType;
    uint8 gender;
    uint8 level;
  }

  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (MinerLooter memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}