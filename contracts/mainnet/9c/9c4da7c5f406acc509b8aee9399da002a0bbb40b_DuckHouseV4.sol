//SPDX-License-Identifier: UNLICENSED

// okay#1746
// ▁ ▂ ▄ ▅ 𝔇𝔦𝔞𝔷𝔈𝔱𝔬 ▅ ▄ ▂ ▁#6666
/*          
                                            ██████████                                  
                                      ░░  ██░░░░░░░░░░██                                
                                        ██░░░░░░░░░░░░░░██                              
                                        ██░░░░░░░░████░░██████████                      
                            ██          ██░░░░░░░░████░░██▒▒▒▒▒▒██                      
                          ██░░██        ██░░░░░░░░░░░░░░██▒▒▒▒▒▒██                      
                          ██░░░░██      ██░░░░░░░░░░░░░░████████                        
                        ██░░░░░░░░██      ██░░░░░░░░░░░░██                              
                        ██░░░░░░░░████████████░░░░░░░░██                                
                        ██░░░░░░░░██░░░░░░░░░░░░░░░░░░░░██                              
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                              
                          ██░░░░░░░░░░░░░░░░░░░░░░░░░░██                                
                            ██████░░░░░░░░░░░░░░░░████                                  
                                  ████████████████                                      
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


import "./iquack.sol";
import "./iDuckGen2.sol";

contract DuckHouseV4 is Initializable, IERC721ReceiverUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    // Ref dopey duck contract
    IERC721Enumerable public dd;
    // Ref quack contract
    IQuack public quack;

    uint256 public minStakeTime;
    uint256 public stakeRewardDefault;
    uint256 public stakeRewardBoosted;

    mapping(uint256 => bool) tokenIsBoosted;

    struct StakeStatus {
        bool staked;
        uint88 since;
        address user;
    }

    mapping(uint256=>StakeStatus) public steak;

    uint256 public version;

    // V3 changes
    // support claim without unstake
    mapping(uint256=>uint256) public gen1TokenLastClaimedAt;        // time that a staked token last had its balance claimed at.  gen1 only.
    mapping(uint256=>uint256) public gen2TokenLastClaimedAt;        // time that a staked token last had its balance claimed at.  gen2 only.
    // lower gas for checking if an owner has a staked duck for hunter mint;
    mapping(address=>uint256) public stakedDuckCountByOwner;        // get the stakedDuckCount by owner (for easy ref for minting hunters)
    mapping(address=>uint256) public stakedGen2DuckCountByOwner;    // get the stakedDuckCount by owner (for easy ref for minting hunters)
    mapping(address=>uint256[]) private stakedGen2DuckIdsByOwner;

    iDD2 public dd2;
    mapping(uint256=>StakeStatus) private steak2;    // stake status for gen2 ducks
    uint256[] deathstamps;                          // timestamps for duck deaths - to calculate hunter reward bonuses
    mapping(address=>bool) admins;
    uint256 quackGenInterval;

    // Staking options ===
    function setMinimumStakeTime(uint256 minTime) public onlyOwner {
        minStakeTime = minTime;
    }

    function setStakeRewardDefault(uint256 defaultReward) public onlyOwner {
        stakeRewardDefault = defaultReward;
    }

    function setStakeRewardBoosted(uint256 boostedReward) public onlyOwner {
        stakeRewardBoosted = boostedReward;
    }

    function setQuackGenerationInterval(uint256 interval) public onlyOwner {
        quackGenInterval = interval;
    }
    // End staking options ===

    modifier onlyFromDD2() {
        require(_msgSender() == address(dd2) || _msgSender() == owner());
        _;
    }

    constructor(){}
    function initialize(address _dd, address _quack, uint256[] calldata boostedTokens) public initializer {
        // __ERC721Holder_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        dd = IERC721Enumerable(_dd);
        quack = IQuack(_quack);
        quack.initialize("Quack", "QUACK");
        
        minStakeTime = 2 days;
        stakeRewardDefault = 1 ether;
        stakeRewardBoosted = 4 ether;

        for (uint256 i = 0; i < boostedTokens.length; i++) {
            tokenIsBoosted[boostedTokens[i]] = true;
        }
    }

    function upgradeFromV1() public {
        require(version < 2, "this contract is already v2+");
        version = 2;
    }

    function upgradeFromV2(address _dd2) public {
        require(version < 3, "this contract is already v3+");
        version = 3;
        
        dd2 = iDD2(_dd2);
        quack.grantRole(0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6, _dd2);

        // Add all current staked duck owners to mapping
        for (uint256 i = 0; i < dd.totalSupply(); i++){
            if (steak[i].staked) {
                stakedDuckCountByOwner[steak[i].user]++;
            }
        }

        admins[owner()] = true;
        admins[address(dd2)] = true;
    }

    function upgradeFromV3(address admin) public {
        require(version < 4, "already upgraded");
        version = 4;
        quack.grantRole(0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6, admin);
        quackGenInterval = 1 days;
    }

    // Staking ====
    function stake(uint256[] calldata ids) whenNotPaused public {
        for (uint256 i=0; i < ids.length; i++) {
            _stake(ids[i]);
        }
    }

    function unstake(uint256[] calldata ids) whenNotPaused public{
        for (uint256 i=0; i < ids.length; i++) {
            _unstake(ids[i]);
        }
    }

    function _stake(uint256 id) private {
        StakeStatus memory stakeStatus = steak[id];
        require(stakeStatus.staked == false, "Duck already staked");
        dd.transferFrom(_msgSender(), address(this), id);

        steak[id] = StakeStatus({
            staked:true,
            user: _msgSender(),
            since: uint88(block.timestamp)
        });
        stakedDuckCountByOwner[_msgSender()]++;
    }

    // quackOwed for gen1 tokens
    function quackOwed(uint256 id) view public returns (uint256) {
        StakeStatus memory stakeStatus = steak[id];
        if (!stakeStatus.staked) {
            return 0;
        }
        uint256 lastClaimed;
        lastClaimed = stakeStatus.since;
        if (gen1TokenLastClaimedAt[id] > stakeStatus.since) {
            lastClaimed = gen1TokenLastClaimedAt[id];
        }
        uint256 diff = (block.timestamp - lastClaimed) / quackGenInterval;

        uint256 rate = stakeRewardDefault;
        if (tokenIsBoosted[id]) {
            rate = stakeRewardBoosted;
        }
        uint256 owed = diff * rate;
        return owed;
    }

    // quackOwed for gen2 tokens
    function quackOwedGen2(uint256 id) humansOnly view public returns (uint256) {
        StakeStatus memory stakeStatus = steak2[id];
        if (!stakeStatus.staked) {
            return 0;
        }
        uint256 lastClaimed;
        lastClaimed = stakeStatus.since;
        if (gen2TokenLastClaimedAt[id] > stakeStatus.since) {
            lastClaimed = gen2TokenLastClaimedAt[id];
        }

        uint256 owed;
        if (id > 2000) { // non hunter case;
            uint256 diff = (block.timestamp - lastClaimed) / quackGenInterval;
            owed = diff * 1 ether;
        } else { // hunter case
            uint256 dayDiff;

            // no ducks killed or last deathstamp is before this duck was staked/lastclaimed
            if (deathstamps.length == 0 || deathstamps[deathstamps.length-1] < lastClaimed) {
                (dayDiff, lastClaimed) = _calculateDayDiff(lastClaimed, block.timestamp);
                return dayDiff * 1 ether;
            }

            // normal case
            for (uint256 i = 0; i < deathstamps.length; i++) {
                if (deathstamps[i] > lastClaimed) {
                    // calculate how much would have been owed by then
                    (dayDiff, lastClaimed) = _calculateDayDiff(lastClaimed, deathstamps[i]);
                    owed += dayDiff * 1 ether;
                    
                    // apply bonus
                    owed = _applyBonusReward(owed);
                }
            }

        }
        return owed;
    }

    /*
    Calculate the difference in days between two timestamps, rounding down.
    Also calculate the timestamp of the actual reward time of the last day.
    */
    function _calculateDayDiff(uint256 timestamp1, uint256 timestamp2) view private returns (uint256 dayDiff, uint256 lastRewardTimestamp) {
        dayDiff = (timestamp2 - timestamp1) / quackGenInterval;
        lastRewardTimestamp = (60*60*24) * dayDiff + timestamp1;
        return (dayDiff, lastRewardTimestamp);
    }

    function _applyBonusReward(uint256 owed) pure private returns (uint256) {
        return owed + 0.25 ether;
    }

    // only claim for gen1
    function onlyClaimQuackForStakedDucks(uint256[] calldata ids) public {
        for (uint256 i = 0; i < ids.length; i++) {
            require(steak[ids[i]].user == _msgSender(), "Can't claim quack for duck you don't own");
            _claimQuack(ids[i]);
        }
    }

    // only claim for gen2
    function onlyClaimQuackForStakedGen2Ducks(uint256[] calldata ids) humansOnly public {
        require(!dd2.checkLockedAddress(_msgSender()), "Y?");
        for (uint256 i = 0; i < ids.length; i++) {
            require(steak2[ids[i]].user == _msgSender(), "Gen2: Can't claim quack for duck you don't own");
            _claimGen2Quack(ids[i]);
        }
    }

    function _claimQuack(uint256 id) nonReentrant private {
        uint256 owed = quackOwed(id);
        quack.mint(msg.sender, owed);
        // steak[id].since = uint88(block.timestamp);
        gen1TokenLastClaimedAt[id] = uint88(block.timestamp);
    }

    function _claimGen2Quack(uint256 id) nonReentrant private {
        uint256 owed = quackOwedGen2(id);
        quack.mint(msg.sender, owed);
        // steak[id].since = uint88(block.timestamp);
        gen2TokenLastClaimedAt[id] = uint88(block.timestamp);
    }

    function _unstake(uint256 id) private {
        StakeStatus memory stakeStatus = steak[id];
        require(stakeStatus.staked == true, "Duck not staked");
        require(stakeStatus.user == _msgSender(), "This ain't your duck");
        require(block.timestamp - stakeStatus.since > minStakeTime, "Min stake time not reached");
        dd.transferFrom(address(this), stakeStatus.user, id);

        _claimQuack(id);

        // set stake status 
        steak[id] = StakeStatus({
            staked: false,
            user: _msgSender(),
            since: uint88(block.timestamp)
        });
        stakedDuckCountByOwner[_msgSender()]--;
    }
    // End Staking ====

    // Staking for gen 2 ===
    function _setStakeForGen2Token(uint256 id, address originalOwner) public onlyFromDD2 {
        require(dd2.ownerOf(id) == address(this), "Not my token :/");
        stakedGen2DuckCountByOwner[originalOwner]++;
        stakedGen2DuckIdsByOwner[originalOwner].push(id);
        steak2[id] = StakeStatus({
            staked: true,
            user: originalOwner,
            since: uint88(block.timestamp)
        });
    }

    function stakeGen2(uint256[] calldata ids) humansOnly public {
        require(!dd2.checkLockedAddress(_msgSender()), "Y?");
        for (uint256 i = 0; i < ids.length; i++) {
            _stakeGen2(ids[i]);
            // dd2._duckHouseStakingCallback(ids[i], true);
        }
        dd2._duckHouseStakingCallback();
    }

    function _stakeGen2(uint256 id) private {
        StakeStatus memory stakeStatus = steak2[id];
        require(stakeStatus.staked == false, "Gen2: Duck already staked");
        require(dd2.ownerOf(id) == _msgSender(), "Gen2: Not your duck");
        dd2.transferFrom(_msgSender(), address(this), id);

        stakedGen2DuckCountByOwner[_msgSender()]++;
        stakedGen2DuckIdsByOwner[_msgSender()].push(id);
        steak2[id] = StakeStatus({
            staked:true,
            user: _msgSender(),
            since: uint88(block.timestamp)
        });
    }

    function unstakeGen2(uint256[] calldata ids) humansOnly public {
        require(!dd2.checkLockedAddress(_msgSender()), "Y?");
        for (uint256 i = 0; i < ids.length; i++) {
            _unstakeGen2(ids[i]);
            // dd2._duckHouseStakingCallback(ids[i], false);
        }
        dd2._duckHouseStakingCallback();
    }

    function _unstakeGen2(uint256 id) private {
        require(steak2[id].staked == true, "Gen2: Duck not staked");
        require(steak2[id].user == _msgSender(), "Gen2: This ain't your duck");
        require(block.timestamp - steak2[id].since > minStakeTime, "Gen2: Min stake time not reached");
        _claimGen2Quack(id);
        dd2.transferFrom(address(this), steak2[id].user, id);
        
        stakedGen2DuckCountByOwner[steak2[id].user]--;
        _removeIdFromGen2OwnerList(_msgSender(), id);
        steak2[id] = StakeStatus({
            staked: false,
            user: address(0),
            since: uint88(block.timestamp)
        });
    }

    function _removeIdFromGen2OwnerList(address _owner, uint256 tokenId) private {
        uint256 pos;
        bool found;
        for(uint256 i; i < stakedGen2DuckIdsByOwner[_owner].length; i++) {
            if (stakedGen2DuckIdsByOwner[_owner][i] == tokenId) {
                found = true;
                pos = i;
                break;
            }
        }
        if (found) {
            delete stakedGen2DuckIdsByOwner[_owner][pos];
            stakedGen2DuckIdsByOwner[_owner][pos] = stakedGen2DuckIdsByOwner[_owner][stakedGen2DuckIdsByOwner[_owner].length-1];
            stakedGen2DuckIdsByOwner[_owner].pop();
        }
    }
    // End Staking for gen 2 ===

    // Staked enumeration
    function getStakedDuckCountByOwner(address _owner) public view returns (uint256) {
        uint256 count = 0;
        StakeStatus memory stakeStatus;
        for (uint256 i = 1; i < dd.totalSupply(); i++) {
            stakeStatus = steak[i];
            if (stakeStatus.user == _owner && stakeStatus.staked == true) {
                count++;
            }
        }
        return count;
    }

    function getStakedDuckOfOwnerByIndex(address _owner, uint256 index) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < dd.totalSupply(); i++) {
            if (steak[i].user == _owner && steak[i].staked == true) {
                if (count == index) return i;
                count++;
            }
        }
        return 0;
    }

    function getGen2StakeStatus(uint256 id) view public humansOnly returns(StakeStatus memory) {
        return steak2[id];
    }
    
    function killCallback() public onlyFromDD2 {
        deathstamps.push(block.timestamp);
    }

    function getStakedGen2DuckIdsByOwner(address _owner) view public humansOnly returns(uint256[] memory){
        return stakedGen2DuckIdsByOwner[_owner];
    }
    // end staked enumeration

    // admin
    function togglePaused() onlyOwner public{
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
    // end admin

    modifier humansOnly() {
        uint256 size;
        address account = _msgSender();
        assembly {
            size := extcodesize(account)
        }
        require(admins[_msgSender()] || size == 0, "Humans only");
        _;
    }

  function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) pure external override returns (bytes4) {
        require(from == address(0), "Don't stake dux by sending them here");
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IQuack is IERC20Upgradeable {
    function burnFrom(address from, uint256 amount) external;
    function initialize(string memory, string memory) external;
    function mint(address, uint256) external;
    function grantRole(bytes32, address) external;
    // function balanceOf(address account) external;
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface iDD2 is IERC721Enumerable {
    function _duckHouseStakingCallback(uint256 id, bool staked) external;
    function _duckHouseStakingCallback() external;
    function checkLockedAddress(address) external returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
        return msg.data;
    }
    uint256[50] private __gap;
}