// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";
import "./Hammies.sol";
import "./Fluff.sol";

contract Galaxy is Ownable, IERC721Receiver {
    using SafeMath for uint256;
    
    //Establish interface for Hammies
    Hammies hammies;
    
    //Establish interface for $Fluff
    Fluff fluff;

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event TokenClaimed(uint256 tokenId, uint256 earned, bool staked);
    
    //Maps tokenId to owner
    mapping(uint256 => address) public ownerById;
    /*GMaps Status to tokenId
      Status is as follows:
        0 - Unstaked
        1 - Adventurer
        2 - Pirate
        3 - Salvager
    */
    mapping(uint256 => uint256) public statusById;
    //Maps tokenId to time staked
    mapping(uint256 => uint256) public timeStaked;
    //Amount of $Fluff stolen by Pirate while staked
    mapping(uint256 => uint256) public fluffStolen;
    
    //Daily $Fluff earned by adventurers
    uint256 public adventuringFluffRate = 100 ether;
    //Total number of adventurers staked
    uint256 public totalAdventurersStaked = 0;
    //Percent of $Fluff earned by adventurers that is kept
    uint256 public adventurerShare = 50;
    
    //Percent of $Fluff earned by adventurers that is stolen by pirates
    uint256 public pirateShare = 50;
    //$Fluff pool to be distributed amongst pirates each day
    uint256 public piratePool = 0;
    //Total number of pirates staked
    uint256 public totalPiratesStaked = 0;
    //Wool earned per pirate (piratePool/totalPiratesStaked)
    uint256 public woolPerPirate = 0;
    //5% chance a pirate gets lost each day
    uint256 public chancePirateGetsLost = 5;
    //Number of pirates currently lost in space
    uint256 public numberOfPiratesLostInSpace = 0;
    
    //1 Percent chance a Salvager rescues a pirate, chance is per pirate lost
    uint256 public chanceSalvagerRescuesPirate = 1;
    //Total number of salvagers staked
    uint256 public totalSalvagersStaked = 0;
    
    //Stored tokenIds of all pirates staked
    uint256[] public piratesStaked;
    //Stored tokenIds of all salvages staked
    uint256[] public salvagersStaked;
    
    //1 day lock on staking
    uint256 public minStakeTime = 0 days;
    
    bool public staking = false;
    
    constructor(){}
    
    //-----------------------------------------------------------------------------//
    //------------------------------Staking----------------------------------------//
    //-----------------------------------------------------------------------------//
    
    /*sends any number of Hammies to the galaxy
        ids -> list of hammy ids to stake
        Status == 1 -> Adventurer
        Status == 2 -> Pirate
        Status == 3 -> Salvager
    */
    function sendManyToGalaxy(uint256[] calldata ids, uint256 status) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(hammies.ownerOf(ids[i]) == msg.sender, "Not your hammy");
            require(staking, "Staking is paused");

            statusById[ids[i]] = status;
            ownerById[ids[i]] = msg.sender;
            timeStaked[ids[i]] = block.timestamp;
            hammies.safeTransferFrom(msg.sender, address(this), ids[i]);

            if (status == 1)
                totalAdventurersStaked++;
            else if (status == 2){
                totalPiratesStaked++;
                piratesStaked.push(ids[i]);
            }
            else if (status == 3){
                totalSalvagersStaked++;
                salvagersStaked.push(ids[i]);
            }
        }
    }
    
    function unstakeManyHammies(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            _unstakeHammy(msg.sender, ids[i]);
        }
    }
    
    function _unstakeHammy(address owner, uint256 tokenId) internal {
        require(ownerById[tokenId] == owner, "Not your hammy");
        require(staking, "Staking is paused");
        require(block.timestamp - timeStaked[tokenId]>= minStakeTime, "1 day stake lock");
        
        if (statusById[tokenId] == 1){
            fluff.mint(owner, getPendingFluff(tokenId).mul(adventurerShare).div(100));
            //only if totalPiratesStaked>0
            distributeAmongstPirates(getPendingFluff(tokenId).mul(pirateShare).div(100));
            totalAdventurersStaked--;
        }
        else if (statusById[tokenId] == 2){
        //only if total Salvagers staked > 0
            uint256 roll = randomIntInRange(tokenId, 100);
            if(roll > 5){
                fluff.mint(owner, fluffStolen[tokenId]);
            } else{
                getNewOwnerForPirate(roll, tokenId);
            }
            for (uint256 i = 0; i < piratesStaked.length; i++){
                if (piratesStaked[i] == tokenId){
                    piratesStaked[i] = piratesStaked[piratesStaked.length-1];
                    piratesStaked.pop();
                }
            }
            totalPiratesStaked--;
        }
        else if (statusById[tokenId] == 3){
            for (uint256 i = 0; i < salvagersStaked.length; i++){
                if (salvagersStaked[i] == tokenId){
                    salvagersStaked[i] = salvagersStaked[salvagersStaked.length-1];
                    salvagersStaked.pop();
                }
            }
            totalSalvagersStaked--;
        }
        
        hammies.safeTransferFrom(address(this), ownerById[tokenId], tokenId);
        statusById[tokenId] = 0;

    }
    
    //Passive earning of $Fluff, 100 $Fluff per day
    function getPendingFluff(uint256 id) internal view returns(uint256) {
        return (block.timestamp - timeStaked[id]) * 100 ether / 1 days;
    }
    
    //Distribute stolen $Fluff accross all staked pirates
    function distributeAmongstPirates(uint256 amount) internal {
        for(uint256 i = 0; i < piratesStaked.length; i++){
            fluffStolen[piratesStaked[i]] += amount.div(totalPiratesStaked);
        }
    }
    
    //Returns a pseudo-random integer between 0 - max
    function randomIntInRange(uint256 seed, uint256 max) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
        ))) % max;
    }
    
    
    //Return new owner of lost pirate from current salvagers
    function getNewOwnerForPirate(uint256 seed, uint256 tokenId) internal{
        uint256 roll = randomIntInRange(seed, totalSalvagersStaked);
        ownerById[tokenId] = ownerById[roll];
        fluff.mint(ownerById[roll], fluffStolen[tokenId]);
    }
      
    //Set address for Hammies
    function setHammyAddress(address hammyAddr) external onlyOwner {
        hammies = Hammies(hammyAddr);
    }
    
    //Set address for $Fluff
    function setFluffAddress(address fluffAddr) external onlyOwner {
        fluff = Fluff(fluffAddr);
    }
    
    //Start/Stop staking
    function toggleStaking() public onlyOwner {
        staking = !staking;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      return IERC721Receiver.onERC721Received.selector;
    }
}