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

    event HammyStolen(address previousOwner, address newOwner, uint256 tokenId);
    event HammyStaked(address owner, uint256 tokenId, uint256 status);
    event HammyClaimed(address owner, uint256 tokenId);
    
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
    //5% chance a pirate gets lost each day
    uint256 public chancePirateGetsLost = 100;
    
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
            emit HammyStaked(msg.sender, ids[i], status);
            hammies.transferFrom(msg.sender, address(this), ids[i]);

            if (status == 1)
                totalAdventurersStaked++;
            else if (status == 2){
                piratesStaked.push(ids[i]);
            }
            else if (status == 3){
                salvagersStaked.push(ids[i]);
            }
        }
    }
    
    function unstakeManyHammies(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(ownerById[ids[i]] == msg.sender, "Not your hammy");
            require(staking, "Staking is paused");
            require(block.timestamp - timeStaked[ids[i]]>= minStakeTime, "1 day stake lock");
            _claim(msg.sender, ids[i]);
            emit HammyClaimed(address(this), ids[i]);
            hammies.safeTransferFrom(address(this), ownerById[ids[i]], ids[i]);
            statusById[ids[i]] = 0;
        }
    }

    function claimManyHammies(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(ownerById[ids[i]] == msg.sender, "Not your hammy");
            require(staking, "Staking is paused");
            require(block.timestamp - timeStaked[ids[i]]>= minStakeTime, "1 day stake lock");
            _claim(msg.sender, ids[i]);
            emit HammyClaimed(address(this), ids[i]);
        }
    }
    
    function _claim(address owner, uint256 tokenId) internal {
        if (statusById[tokenId] == 1){
            if(piratesStaked.length > 0){
                fluff.mint(owner, getPendingFluff(tokenId).mul(adventurerShare).div(100));
                distributeAmongstPirates(getPendingFluff(tokenId).mul(pirateShare).div(100));
            }
            else {
                fluff.mint(owner, getPendingFluff(tokenId));
            }            
            totalAdventurersStaked--;
        }
        else if (statusById[tokenId] == 2){
            uint256 roll = randomIntInRange(tokenId, 100);
            if(roll > chancePirateGetsLost || salvagersStaked.length == 0){
                fluff.mint(owner, fluffStolen[tokenId]);
                fluffStolen[tokenId] = 0;
            } else{
                getNewOwnerForPirate(roll, tokenId);
            }
            for (uint256 i = 0; i < piratesStaked.length; i++){
                if (piratesStaked[i] == tokenId){
                    piratesStaked[i] = piratesStaked[piratesStaked.length-1];
                    piratesStaked.pop();
                }
            }
            
        }
        else if (statusById[tokenId] == 3){
            for (uint256 i = 0; i < salvagersStaked.length; i++){
                if (salvagersStaked[i] == tokenId){
                    salvagersStaked[i] = salvagersStaked[salvagersStaked.length-1];
                    salvagersStaked.pop();
                }
            } 
        }
        timeStaked[tokenId] = block.timestamp;
    }
    
    //Passive earning of $Fluff, 100 $Fluff per day
    function getPendingFluff(uint256 id) internal view returns(uint256) {
        return (block.timestamp - timeStaked[id]) * 100 ether / 1 days;
    }
    
    //Distribute stolen $Fluff accross all staked pirates
    function distributeAmongstPirates(uint256 amount) internal {
        for(uint256 i = 0; i < piratesStaked.length; i++){
            fluffStolen[piratesStaked[i]] += amount.div(piratesStaked.length);
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
        uint256 roll = randomIntInRange(seed, salvagersStaked.length);
        emit HammyStolen(ownerById[tokenId], ownerById[salvagersStaked[roll]], tokenId);
        ownerById[tokenId] = ownerById[salvagersStaked[roll]];
        fluff.mint(ownerById[tokenId], fluffStolen[tokenId]);
        fluffStolen[tokenId] = 0;
    }
      
    function getTotalSalvagersStaked() public view returns (uint256) {
        return salvagersStaked.length;
    }

    function getTotalPiratesStaked() public view returns (uint256) {
        return piratesStaked.length;
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