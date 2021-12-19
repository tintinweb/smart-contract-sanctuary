// SPDX-License-Identifier: None
// HungryBunz Foraging / $NOM Implementation V1
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Initializable.sol";

interface IHungryBunz {
    function applicationOwnerOf(uint256 tokenId) external view returns (address); //Used to verify ownership of game items.
    function ownerOf(uint256 tokenId) external view returns (address); //Used to verify ownership of game items.
    function burnConsumed(uint256) external; //Used to burn an item's NFT, once it has been consumed.
    function lockForStaking (uint16 tokenId) external; //Lock for staking
    function unlock (uint16 tokenId, uint248 newTime) external; //Unlock
    function serializeStats(uint16 tokenId) external view returns (bytes16); //Get serialized stats
    function serializeAtts(uint16 tokenId) external view returns (bytes16); //Get serialized stats
    function checkStake (uint16 tokenId) external view returns (address);
    function stakeStart (uint16 tokenId) external view returns(uint248);
    function updateStakeStart (uint16 tokenId, uint248 newTime) external;
}

contract NOM is Initializable, ERC20, Ownable {
    //******************************************************
    //CRITICAL STATE VARIABLES
    //****************************************************** 
    //Pausable library is simple enough to imitate in this contract
    bool public paused = false;

    address _mainContractAddress;
    address _gatewayContractAddress;
    IHungryBunz _HungryBunz;
    
    mapping(address => mapping(uint16 => uint256)) ownedStakes;
    mapping(uint16 => uint256) stakes;
    mapping(address => bool) approvedBurners;
    mapping(address => bool) approvedMinters;

    //Track balances not yet transferred to users.
    //Saves nominal gas vs incrementing supply and
    //emitting event on every claim.
    mapping(address => uint256) balances;
    
    uint256 _baseReward; //Base reward per block of time.
    uint256 _scavengingIncrement; //Seconds in a day.
    uint8 _maxScavengingPeriods; //Max length of time to scavenge.
    uint8 _foodComaPeriods; //Food coma duration in periods.
    
    struct st {
        uint8 rank; //1 = Whelp, 2 = Chunk, 3 = Hunk
        uint8 season; //Determines eligibility for season rewards
        uint16 thiccness; //Used to calculate score and determine eligibility to evolve
        uint16 criticalChance; //Determines likelihood of dropping critical $NOM
        uint16 criticalMult; //How much more $NOM the character drops on a critical day
        uint16 teamCritChance; //Nerfs this chunks critical chance, but boosts all others a player owns
        uint16 teamCritMult; //Nerfs this players critical chance, but boosts all others a player owns
    }
    
    constructor()
    {
        ownableInit();
    }

    function nomInit(address hbContractAddress) external initializer {
        //Require to prevent users from initializing
        //implementation contract
        require(owner() == address(0) || owner() == msg.sender,
            "No.");
        
        ownableInit();
        erc20init("Nom", "NOM");
        //Base reward per block of time. Expressed
        //in smaller units to accomodate basis point
        //calculations.
        _baseReward = 10 * (10 ** 14);
        _scavengingIncrement = 86400; //Seconds in a day.
        _maxScavengingPeriods = 12; //Max length of time to scavenge.
        _foodComaPeriods = 2; //Food coma duration in periods.
        
        _mainContractAddress = hbContractAddress;
        _HungryBunz = IHungryBunz(hbContractAddress);
        approvedBurners[hbContractAddress] = true;
        
        paused = true; //Start contract as paused
    }
    
    //******************************************************
    //ERC20 FUNCTIONALITY OVERRIDES
    //******************************************************
    function balanceOf(address account) public view override (ERC20) returns (uint256) {
        //_balances is actual supply, balances is hypothetical
        return ERC20.balanceOf(account) + balances[account];
    }

    //******************************************************
    //OWNER ONLY FUNCTIONS TO MANAGE ESSENTIAL FUNCTIONS
    //******************************************************
    function updateGatewayContract(address gatewayContractAddress) public onlyOwner {
        _gatewayContractAddress = gatewayContractAddress;
        approvedBurners[gatewayContractAddress] = true;
        approvedMinters[gatewayContractAddress] = true;
    }
    
    //Approve functions can be given a false status to revoke permissions.
    function approveBurner(address newConsumer, bool status) public onlyOwner {
        approvedBurners[newConsumer] = status;
    }

    function approveMinter(address newMinter, bool status) public onlyOwner {
        approvedMinters[newMinter] = status;
    }
    
    function updateAppPeriod(uint256 newDuration) public onlyOwner {
        _scavengingIncrement = newDuration;
    }
    
    function updateBaseReward(uint256 newBase) public onlyOwner {
        _baseReward = newBase;
    }
    
    function updateActivePeriods(uint8 newCount) public onlyOwner {
        _maxScavengingPeriods = newCount;
    }
    
    function updateRestPeriods(uint8 newCount) public onlyOwner {
        _foodComaPeriods = newCount;
    }

    //Cost of owner pausing when already paused is mild annoyance.
    //Removed extra requires
    function pause() onlyOwner public {
        paused = true;
    }

    //See above comment explaining bare bones implementation.
    function unpause() onlyOwner public {
        paused = false;
    }
    
    //******************************************************
    //CALCULATE REWARDS AND UPDATE BALANCES
    //******************************************************
    function _checkEligibility(uint16 tokenId) internal view returns(uint256) {
        //Check for paused state will return 0 eligible periods, thus allowing
        //users to unstake if rewards are paused.
        uint256 elapsedTime;
        uint256 stakeStart = _HungryBunz.stakeStart(tokenId);
        if (stakeStart != 0 && paused == false &&
            block.timestamp > stakeStart)
        {
            elapsedTime = block.timestamp - stakeStart;    
        } else {
            elapsedTime = 0;
        }
        
        uint256 elapsedPeriods = elapsedTime / _scavengingIncrement;
        return elapsedPeriods;
    }
    
    //Check if arbitrary uint16 falls within the bottom NNNN basis points of the range
    function _uint16HitMiss(uint16 basisPoints16, uint16 value) internal pure returns (bool) {
        uint256 max = 65535;
        uint256 basisPoints256 = uint256(basisPoints16);
        uint256 scaledThreshold = max * basisPoints256 / 10000;
        return (value <= scaledThreshold);
    }
    
    function _retrieveStruct(uint16 tokenId) internal view returns (st memory) {
        st memory output;
        bytes16 serialized = _HungryBunz.serializeStats(tokenId);
        output.rank = uint8(serialized[0]);
        output.season = uint8(serialized[1]);
        output.thiccness = uint16(bytes2(abi.encodePacked(serialized[2], serialized[3])));
        output.criticalChance = uint16(bytes2(abi.encodePacked(serialized[6], serialized[7])));
        output.criticalMult = uint16(bytes2(abi.encodePacked(serialized[8], serialized[9])));
        output.teamCritChance = uint16(bytes2(abi.encodePacked(serialized[12], serialized[13])));
        output.teamCritMult = uint16(bytes2(abi.encodePacked(serialized[14], serialized[15])));
                    
        return output;
    }
    
    /*
     Since visual attributes for tokens are, and will remain, fairly consistent over time,
     we use each tokens' visual properties as a seed for its team and individual critical
     stats. To ensure that all tokens have chance to hit criticals, we use the timestamp of
     the first block every other day as salt. This salt changes frequently enough to prevent
     any one NFT from becoming a guaranteed loser, but not so often that the expected value
     of waiting for the right salt to claim rewards becomes an effective strategy.
     
     A savvy user could identify the tokens which are due to pay out critical rewards in the
     near future and attempt to buy them off the secondary market. We expect that holders should
     price this factor into their listings, and that this strategy will enrichen mechanics and
     improve liquidity on the whole.
     */
    
    function _calculateRewards(uint16[] memory tokenIds) internal view returns (uint256) {
        //This function only called by internal _claim function
        st memory statSwap;
        
        bool teamCritHit;
        uint16 critSeed;
        uint256 teamCritMult = 10000; //100% as basis points for accuracy
        uint256 reward;
        uint256 eodStart = (block.timestamp - (block.timestamp % 172800)); //Every other day's start
        
        //Have to iterate through tokens twice to enumerate team crit chance and mult
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] != 0) {
                statSwap = _retrieveStruct(tokenIds[i]);
                
                //Calculate team critical hit. Upper bound of probability of hitting
                //team critical during any 2 day window is 34%, assuming 16 staked
                //tokens with 1/256 2.56% team critical multiplier.
                if (!teamCritHit) {
                    critSeed = uint16(bytes2(keccak256(abi.encodePacked(
                        _HungryBunz.serializeAtts(tokenIds[i]),
                        eodStart
                    ))));
                    teamCritHit = _uint16HitMiss(statSwap.teamCritChance, critSeed);
                }

                //Plus equals assignment forces incorrect order of operations. Use long form.
                teamCritMult = (teamCritMult * uint32(statSwap.teamCritMult)) / 10000;
            }
        }
        
        //Cap team critical mult at 8x for maximum daily nom of 26x
        if (teamCritMult > 80000) {
            teamCritMult = 80000;
        }
        
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] != 0) {
                statSwap = _retrieveStruct(tokenIds[i]);
                
                uint8 level = statSwap.rank;
                uint8 critHit;
                if (!teamCritHit) {
                    critSeed = uint16(bytes2(keccak256(abi.encodePacked(
                        _HungryBunz.serializeAtts(tokenIds[i]),
                        eodStart
                    ))));
                    
                    //Crit chance in excess of 10000 should not cause any grief,
                    //but overflow check inculded regardless.
                    uint16 critChance = (statSwap.criticalChance <= 10000) ? 
                        statSwap.criticalChance : 10000;
                    critHit = _uint16HitMiss(critChance, critSeed) ? 1 : 0;
                } else {
                    //Team crit chance will either be 0 (no team crit) or 10000 (team crit hit)
                    //If team crit chance isn't zero, then critHit must be 1.
                    critHit = 1;
                }

                uint8 eligiblePeriods = _checkEligibility(tokenIds[i]) > _maxScavengingPeriods ? 
                    _maxScavengingPeriods : uint8(_checkEligibility(tokenIds[i]));
                
                //Computing reward multiplier in basis points. Multiplying basis points for Critical and Team crit requires divide by 10k
                uint256 thisRewardMult = uint16((critHit * statSwap.criticalMult * teamCritMult) / 10000);
                thisRewardMult = thisRewardMult >= 10000 ? thisRewardMult : 10000;
                
                //Reward mult. Leave additional decimals.
                reward += eligiblePeriods * _baseReward * (level ** 2) * thisRewardMult;
            }
        }
        
        return reward;
    }
    
    //Internal function only called after input sanitization. Passes
    //sanitized array for reward assessments, and then sets user balance.
    //Timestamp is not updated in this function, since timestamp is stored
    //on main contract to reduce write operations, and main contract
    //exposes distinct functions for simple restake / claim, and unstake
    //operations.
    function _claim(uint16[] memory tokenIds, address targetAccount) internal returns (uint256) {
        uint256 rewards = _calculateRewards(tokenIds);
        balances[targetAccount] += rewards;
        
        return rewards;
    }
    
    //******************************************************
    //MAJOR HOOKS TO STAKE, CLAIM, AND UNSTAKE
    //******************************************************
    function stake(uint16[] memory tokenIds) public {
        //We don't sanitize this input, beyond owner check, since
        //consequence of staking twice is irrelevant and main
        //will revert when attempting to relock token. We use
        //the overriden ownerOf function to prevent staking while
        //token is on another layer.
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_HungryBunz.ownerOf(tokenIds[i]) == msg.sender) {
                //This function locks the token. Main contract will
                //not update timestamp if staking start is in the
                //future. Main contract reverts if token rank is
                //above max stakable rank.
                _HungryBunz.lockForStaking(tokenIds[i]);
            }
        }
    }

    //Function will not remove tokens which are owned and staked, but ineligible for claim.
    //Onus is on user to decide if they have a sufficient incentive to claim while token is
    //ineligible to claim nom
    function _sanitizeArray(uint16[] memory tokenIds, address account) internal view returns (uint16[] memory) {
        require(tokenIds.length < 17,
            "Cannot claim more than 16 at a time");
        
        uint16[] memory claimable = new uint16[](tokenIds.length);
        uint16 j = 0;
        uint16 validationSetLength;

        for (uint16 i = 0; i < tokenIds.length; i++) { //We assume no one will try to claim more than total supply....
            //If token is not current staked and owned by msg.sender, remove it from the claim array
            if (_HungryBunz.checkStake(tokenIds[i]) == account) {
                //Claimable can never contain more than i non zero values.
                //If invalid entries are deleted and claimable array is
                //shortened, then use claimable.length for later elements.
                validationSetLength = i < uint16(claimable.length) ? i : uint16(claimable.length);
                
                //Nested for loop for maximum of 128 iterations is favorable, gas-wise, to
                //other solutions which write to storage more frequently.
                for (uint16 k = 0; k < validationSetLength; k++) {
                    //User attempted to claim token more than once.
                    require(tokenIds[i] != claimable[k], "Shame!");
                }
                
                claimable[j] = tokenIds[i];
                j++;
            } else {
                //If stake not owned or staked, shorten claimable array by 1
                delete claimable[claimable.length - 1];
            }
        }

        return claimable;
    }
    
    //Restake and unstake functions share some redundant logic, but are left separate
    //to accomodate different calls to main contract.
    function restake(uint16[] memory tokenIds) public returns (uint256) { //Claim NOM
        //No advantage to running restake while claims are paused.
        require(paused == false, "Claims paused.");
        
        //Sanitize removes duplicates and tokens which are not owned by sender, or don't
        //exist on this layer.
        uint16[] memory claimable = _sanitizeArray(tokenIds, msg.sender);
        if (claimable.length > 0) {
            //We can claim safely before updating timers and completing
            //unlock procedure because simulated transfers eliminate
            //opportunities for reentrant attacks from receiver functions
            uint256 rewards = _claim(claimable, msg.sender);

            for (uint i = 0; i < claimable.length; i++) {
                if (claimable[i] != 0) {
                    if(_checkEligibility(claimable[i]) >= (_foodComaPeriods + _maxScavengingPeriods)) {
                        _HungryBunz.updateStakeStart(claimable[i], uint248(block.timestamp));
                    } else {
                        uint248 tokenStakeStart = uint248(block.timestamp) + 
                            uint248(_scavengingIncrement * (_foodComaPeriods));
                        _HungryBunz.updateStakeStart(claimable[i], tokenStakeStart);
                    }
                }
            }

            return rewards;
        } else {
            return 0;
        }
    }
    
    function unstake(uint16[] memory tokenIds, address targetAccount) external returns (uint256) { //Claim NOM and return NFTs
        address account = msg.sender == _mainContractAddress ? targetAccount : msg.sender;
        
        //Sanitize removes duplicates and tokens which are not owned by sender, or don't
        //exist on this layer.
        uint16[] memory claimable = _sanitizeArray(tokenIds, account);
        
        if(claimable.length > 0) {
            //We can claim safely before updating timers and completing
            //unlock procedure because simulated transfers eliminate
            //opportunities for reentrant attacks from receiver functions.
            //Reversion in unlock procedure will revert the entire tx.
            uint256 rewards = _claim(claimable, account);

            for (uint i = 0; i < claimable.length; i++) {
                if(claimable[i] != 0) {
                    if(_checkEligibility(claimable[i]) >= (_foodComaPeriods + _maxScavengingPeriods)) {
                        _HungryBunz.unlock(claimable[i], uint248(block.timestamp));
                    } else {
                        uint248 tokenStakeStart = uint248(block.timestamp) + 
                            uint248(_scavengingIncrement * (_foodComaPeriods));
                        _HungryBunz.unlock(claimable[i], tokenStakeStart);
                    }
                }
            }
            
            return rewards;
        } else {
            return 0;
        }
    }
    
    //******************************************************
    //VIEWS
    //******************************************************
    function getBunzStatus(uint16 tokenId) public view returns (bool) {
        //True if Bunz is resting, false if scavenging.
        return _HungryBunz.stakeStart(tokenId) > uint248(block.timestamp);
    }
    
    //View balance of tokens not yet withdrawn
    function viewBalance(address owner) external view returns (uint256) {
        return balances[owner];
    }
    
    //Check if claims are paused
    function claimStatus() external view returns (bool) {
        return paused;
    }
    
    //******************************************************
    //WITHDRAW FROM NON STANDARD BALANCE FOR TRADING
    //******************************************************
    function withdrawBalance() public {
        balances[msg.sender] = 0;
        _mint(msg.sender, balances[msg.sender]);
    }
    
    //******************************************************
    //BURN AND MINT FUNCTIONALITY FOR MAIN CONTRACT & BRIDGE
    //******************************************************
    function burn(address account, uint256 amount) public {
        require(approvedBurners[msg.sender] == true, 
            "Not Approved!");
        if(balances[account] >= amount) {
            balances[account] -= amount;
        } else {
            balances[account] = 0;
            _burn(account, (amount - balances[account]));
        }
    }
    
    //Mint function for other application contracts
    function applicationMint(address to, uint256 amount) public {
        require(approvedMinters[msg.sender] == true,
            "Not Approved!");
        _mint(to, amount);
    }
}