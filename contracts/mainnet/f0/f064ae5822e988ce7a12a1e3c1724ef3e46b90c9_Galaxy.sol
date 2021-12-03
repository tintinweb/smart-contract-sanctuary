// ________  ________  ___       ________     ___    ___ ___    ___ 
//|\   ____\|\   __  \|\  \     |\   __  \   |\  \  /  /|\  \  /  /|
//\ \  \___|\ \  \|\  \ \  \    \ \  \|\  \  \ \  \/  / | \  \/  / /
// \ \  \  __\ \   __  \ \  \    \ \   __  \  \ \    / / \ \    / / 
//  \ \  \|\  \ \  \ \  \ \  \____\ \  \ \  \  /     \/   \/  /  /  
//   \ \_______\ \__\ \__\ \_______\ \__\ \__\/  /\   \ __/  / /    
//    \|_______|\|__|\|__|\|_______|\|__|\|__/__/ /\ __\\___/ /     
//                                           |__|/ \|__\|___|/      
                                                                  
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

    event HammieStolen(address previousOwner, address newOwner, uint256 tokenId);
    event HammieStaked(address owner, uint256 tokenId, uint256 status);
    event HammieClaimed(address owner, uint256 tokenId);
    
    /* Struct to track token info
    Status is as follows:
        0 - Unstaked
        1 - Adventurer
        2 - Pirate
        3 - Salvager
    */
    struct tokenInfo {
        uint256 tokenId;
        address owner;
        uint256 status;
        uint256 timeStaked;
    }
    
    // maps id to token info structure
    mapping(uint256 => tokenInfo) public galaxy;

    //Amount token id to amount stolen
    mapping(uint256 => uint256) public fluffStolen;
    
    //Daily $Fluff earned by adventurers
    uint256 public adventuringFluffRate = 100 ether;
    //Total number of adventurers staked
    uint256 public totalAdventurersStaked = 0;
    //Percent of $Fluff earned by adventurers that is kept
    uint256 public adventurerShare = 50;
    
    //Percent of $Fluff earned by adventurers that is stolen by pirates
    uint256 public pirateShare = 50;
    //5% chance a pirate gets lost each time it is unstaked
    uint256 public chancePirateGetsLost = 5;
    
    //Store tokenIds of all pirates staked
    uint256[] public piratesStaked;
    //Store Index of pirates staked
    mapping(uint256 => uint256) public pirateIndices;

    //Store tokenIds of all salvagers staked
    uint256[] public salvagersStaked;
    //Store Index of salvagers staked
    mapping(uint256 => uint256) public salvagerIndices;
    
    //1 day lock on staking
    uint256 public minStakeTime = 1 days;
    
    bool public staking = false;
    
    //Used to map address to claimable Hammies from original Galaxy Contract
    mapping (address => uint256) public claimableHammies;
    //Used to keep track of total Hammies supply
    uint256 public totalSupply = 4889;

    constructor(){}
    
    //Claim lost Hammies from Original Contract
    function claimLostHammiesAndStake(uint256 _count, bool stake, uint256 status) public {
        uint256 numReserved = claimableHammies[msg.sender];
        require(numReserved > 0, "You do not have any claimable Hammies");
        require(_count <= numReserved, "You do not have that many Claimable Hammies");
        claimableHammies[msg.sender] = numReserved - _count;

        for (uint256 i = 0; i < _count; i++) {
            uint256 tokenId = totalSupply + i;
            hammies.mintHammieForFluff();
            if(stake){
                galaxy[tokenId] = tokenInfo({
                    tokenId: tokenId,
                    owner: msg.sender,
                    status: status,
                    timeStaked: block.timestamp
                });
                if (status == 1)
                    totalAdventurersStaked++;
                else if (status == 2){
                    piratesStaked.push(tokenId);
                    pirateIndices[tokenId] = piratesStaked.length - 1;
                }
                else if (status == 3){
                    salvagersStaked.push(tokenId);
                    salvagerIndices[tokenId] = salvagersStaked.length - 1;

                }
            } else {
                hammies.safeTransferFrom(address(this), msg.sender, tokenId);
            }
        }
        uint256 fluffOwed = _count * 100 ether;
        fluff.mint(msg.sender, fluffOwed);
        totalSupply += _count;
    }
    
    //Edit Claimable Hammies per person
    function editHammiesClaimable(address[] calldata addresses, uint256[] calldata count) external onlyOwner {
        for(uint256 i; i < addresses.length; i++){
            claimableHammies[addresses[i]] = count[i];
        }
    }

    //Mint Hammies for Fluff
    function mintHammieForFluff(bool stake, uint256 status) public {
        require(staking, "Staking is paused");
        fluff.burn(msg.sender, getFluffCost(totalSupply));
        hammies.mintHammieForFluff();
        uint256 tokenId = totalSupply;
        totalSupply++;
        if(stake){
            galaxy[tokenId] = tokenInfo({
                tokenId: tokenId,
                owner: msg.sender,
                status: status,
                timeStaked: block.timestamp
            });
            if (status == 1)
                totalAdventurersStaked++;
            else if (status == 2){
                piratesStaked.push(tokenId);
                pirateIndices[tokenId] = piratesStaked.length - 1;
            }
            else if (status == 3){
                salvagersStaked.push(tokenId);
                salvagerIndices[tokenId] = salvagersStaked.length - 1;
            } 
        } else {
            hammies.safeTransferFrom(address(this), msg.sender, tokenId);
        }

    }
    
    function getFluffCost(uint256 supply) internal pure returns (uint256 cost){
        if (supply < 5888)
            return 100 ether;
        else if (supply < 6887)
            return 200 ether;
        else if (supply < 7887)
            return 400 ether;
        else if (supply < 8887)
            return 800 ether;
    }

    //-----------------------------------------------------------------------------//
    //------------------------------Staking----------------------------------------//
    //-----------------------------------------------------------------------------//
    
    /*sends any number of Hammies to the galaxy
        ids -> list of hammie ids to stake
        Status == 1 -> Adventurer
        Status == 2 -> Pirate
        Status == 3 -> Salvager
    */
    function sendManyToGalaxy(uint256[] calldata ids, uint256 status) external {
        for(uint256 i = 0; i < ids.length; i++){
            require(hammies.ownerOf(ids[i]) == msg.sender, "Not your Hammie");
            require(staking, "Staking is paused");

            galaxy[ids[i]] = tokenInfo({
                tokenId: ids[i],
                owner: msg.sender,
                status: status,
                timeStaked: block.timestamp
            });

            emit HammieStaked(msg.sender, ids[i], status);
            hammies.transferFrom(msg.sender, address(this), ids[i]);

            if (status == 1)
                totalAdventurersStaked++;
            else if (status == 2){
                piratesStaked.push(ids[i]);
                pirateIndices[ids[i]] = piratesStaked.length - 1;
            }
            else if (status == 3){
                salvagersStaked.push(ids[i]);
                salvagerIndices[ids[i]] = salvagersStaked.length - 1;

            }
        }
    }
    
    function unstakeManyHammies(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            tokenInfo memory token = galaxy[ids[i]];
            require(token.owner == msg.sender, "Not your Hammie");
            require(hammies.ownerOf(ids[i]) == address(this), "Hammie must be staked in order to claim");
            require(staking, "Staking is paused");
            require(block.timestamp - token.timeStaked >= minStakeTime, "1 day stake lock");

            _claim(msg.sender, ids[i]);

            if (token.status == 1){       
                totalAdventurersStaked--;
            }
            else if (token.status == 2){
                uint256 lastPirate = piratesStaked[piratesStaked.length - 1];
                piratesStaked[pirateIndices[ids[i]]] = lastPirate;
                pirateIndices[lastPirate] = pirateIndices[ids[i]];
                piratesStaked.pop();
            }
            else if (token.status == 3){
                uint256 lastSalvager = salvagersStaked[salvagersStaked.length - 1];
                salvagersStaked[salvagerIndices[ids[i]]] = lastSalvager;
                salvagerIndices[lastSalvager] = salvagerIndices[ids[i]];
                salvagersStaked.pop();
            } 

            emit HammieClaimed(address(this), ids[i]);

            //retrieve token info again to account for stolen Hammies
            tokenInfo memory newToken = galaxy[ids[i]];
            hammies.safeTransferFrom(address(this), newToken.owner, ids[i]);
            galaxy[ids[i]] = tokenInfo({
                tokenId: ids[i],
                owner: newToken.owner,
                status: 0,
                timeStaked: block.timestamp
            });
        }
    }

    function claimManyHammies(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++){
            tokenInfo memory token = galaxy[ids[i]];
            require(token.owner == msg.sender, "Not your hammie");
            require(hammies.ownerOf(ids[i]) == address(this), "Hammie must be staked in order to claim");
            require(staking, "Staking is paused");
            
            _claim(msg.sender, ids[i]);
            emit HammieClaimed(address(this), ids[i]);

            //retrieve token info again to account for stolen Hammies
            tokenInfo memory newToken = galaxy[ids[i]];
            galaxy[ids[i]] = tokenInfo({
                tokenId: ids[i],
                owner: newToken.owner,
                status: newToken.status,
                timeStaked: block.timestamp
            });
        }
    }
    
    function _claim(address owner, uint256 tokenId) internal {
        tokenInfo memory token = galaxy[tokenId];
        if (token.status == 1){
            if(piratesStaked.length > 0){
                uint256 fluffGathered = getPendingFluff(tokenId);
                fluff.mint(owner, fluffGathered.mul(adventurerShare).div(100));
                stealFluff(fluffGathered.mul(pirateShare).div(100));
            }
            else {
                fluff.mint(owner, getPendingFluff(tokenId));
            }            
        }
        else if (token.status == 2){
            uint256 roll = randomIntInRange(tokenId, 100);
            if(roll > chancePirateGetsLost || salvagersStaked.length == 0){
                fluff.mint(owner, fluffStolen[tokenId]);
                fluffStolen[tokenId ]= 0;
            } else{
                getNewOwnerForPirate(roll, tokenId);
            }
        }
    }
    
    //Public function to view pending $fluff earnings for Adventurers.
    function getFluffEarnings(uint256 id) public view returns(uint256) {
        return getPendingFluff(id);
    }

    //Passive earning of $Fluff, 100 $Fluff per day
    function getPendingFluff(uint256 id) internal view returns(uint256) {
        tokenInfo memory token = galaxy[id];
        return (block.timestamp - token.timeStaked) * 100 ether / 1 days;
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
    function stealFluff(uint256 amount) internal{
        uint256 roll = randomIntInRange(amount, piratesStaked.length);
        fluffStolen[piratesStaked[roll]] += amount;
    }

    //Return new owner of lost pirate from current salvagers
    function getNewOwnerForPirate(uint256 seed, uint256 tokenId) internal{
        tokenInfo memory pirate = galaxy[tokenId];
        uint256 roll = randomIntInRange(seed, salvagersStaked.length);
        tokenInfo memory salvager = galaxy[salvagersStaked[roll]];
        emit HammieStolen(pirate.owner, salvager.owner, tokenId);
        galaxy[tokenId] = tokenInfo({
                tokenId: tokenId,
                owner: salvager.owner,
                status: 2,
                timeStaked: block.timestamp
        });
        fluff.mint(salvager.owner, fluffStolen[tokenId]);
        fluffStolen[tokenId] = 0;
    }
      
    function getTotalSalvagersStaked() public view returns (uint256) {
        return salvagersStaked.length;
    }

    function getTotalPiratesStaked() public view returns (uint256) {
        return piratesStaked.length;
    }

    //Set address for Hammies
    function setHammieAddress(address hammieAddr) external onlyOwner {
        hammies = Hammies(hammieAddr);
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