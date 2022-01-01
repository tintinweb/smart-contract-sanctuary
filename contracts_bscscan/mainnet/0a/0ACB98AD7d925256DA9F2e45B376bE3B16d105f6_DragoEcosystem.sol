// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IDragoKingdom.sol";
import "./IDragos.sol";
import "./IDrago.sol";

contract DragoEcosystem is
  Initializable,
  ERC1155Upgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  bool public EcosystemEnabled_;
  address payable public GnosisSafeVault;
  address public kingdomsContract;
  address public dragoNFTContract;
  uint256 public specialBlock;
  address public DragoAddress;


  // User address => KingdomType => IDs stacked
  mapping(address => mapping(uint256 => uint256[])) public addressToKingdomsType;
  // Kingdom Id => Owner Address
  mapping(uint256 => address) buildsAtAddress;
  // User address => DragoNFT Type => IDs stacked
  mapping(address => mapping(uint256 => uint256[])) public addressToDragosType;
  // DragoNFT Id => Owner Address
  mapping(uint256 => address) public dragosAtAddress;
  // kingdomType => BaseReward
  mapping(uint256 => uint256) public kingdomTypeBaseRewards;
  // kingdomType => BaseReward, it use the info that a Kingdom type only stack one type of drago
  mapping(uint256 => uint256) public dragoNFTTypeBaseRewards;
  // drago Id => tiemstamp when it start farming
  mapping(uint256 => uint256) public dragoNFTStartFarmingTimestamp;
  //Special Rewards Claim (NFTID - Amount)
  mapping(uint256 => uint256) public NftIDClaimed;
  //Special Reward Blocks
  uint256 public specialStartBlockTime;
  uint256 public specialEndBlockTime;
  uint256 public rewardFactor;
  event SpecialRewardClaimed(uint256 nftID, uint256 amount);
  struct Monster {
    uint256 typeNum;
    uint256 bait;
    uint256 reward;
    uint256 winningProb;
  }
  mapping(uint256 => Monster) public monsters_;
  mapping(uint256 => uint256) public winsByNftId;
  mapping(uint256 => uint256) public totalBattlesByNftId;
  event FightFinished(address player, uint256 figtherNftID, bool result, uint256 amount);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {
    __ERC1155_init("https://dragoland.io/NFT/dragoecosystem.json");
    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();
    EcosystemEnabled_ = true;
    GnosisSafeVault = payable(address(0x70D542e94a70081a15a555eCFA1Ba4BFB9217FBb)); //
    specialBlock = 15000001; // APPROX a month after launch. 
    DragoAddress = address(0x70D542e94a70081a15a555eCFA1Ba4BFB9217FBb);
    dragoNFTContract = address(0x1dCc869db68030cB56028FcCdfa21B04a487D50F);
    kingdomsContract = address(0x5CE083DD5e105db437A265a294F01488385518ed);
    specialStartBlockTime = 1631750400;
    specialEndBlockTime = 1632441600;
    rewardFactor = 3;
  }
  function setSpecialReward(uint256 startBlockTime, uint256 endBlockTime, uint256 rewFactor) public onlyOwner{
    specialStartBlockTime = startBlockTime;
    specialEndBlockTime = endBlockTime;
    rewardFactor = rewFactor;
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyOwner {
    _mint(account, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  // custom setters
  function setEcosystemEnabled(bool val) public onlyOwner {
    EcosystemEnabled_ = val;
  }

  function setGnosisSafeVault(address val) public onlyOwner {
    GnosisSafeVault = payable(address(val));
  }
  function setKingdomsContract(address val) public onlyOwner {
    kingdomsContract = val;
  }
  function setDragoNFTContract(address val) public onlyOwner {
    dragoNFTContract = val;
  }
  function setSpecialBlock(uint256 blockNumber) public onlyOwner {
    specialBlock = blockNumber;
  }
  function setDragoAddr(address val) public onlyOwner {
    DragoAddress = val;
  }
  function setKingdomsBaseRewards(uint256 firekingdomReward, uint256 waterkingdomReward, uint256 earthkingdomReward, uint256 energykingdomReward, uint256 darknesskingdomReward, uint256 lightkingdomReward) public onlyOwner {
    kingdomTypeBaseRewards[1] = firekingdomReward;
    kingdomTypeBaseRewards[2] = waterkingdomReward;
    kingdomTypeBaseRewards[3] = earthkingdomReward;
    kingdomTypeBaseRewards[4] = energykingdomReward;
    kingdomTypeBaseRewards[5] = darknesskingdomReward;
    kingdomTypeBaseRewards[6] = lightkingdomReward;
  }
  function setDragosBaseRewards(uint256 fireeggReward, uint256 watereggReward, uint256 eartheggReward, uint256 energyeggReward, uint256 darknesseggReward, uint256 lighteggReward) public onlyOwner {
    dragoNFTTypeBaseRewards[1] = fireeggReward;
    dragoNFTTypeBaseRewards[2] = watereggReward;
    dragoNFTTypeBaseRewards[3] = eartheggReward;
    dragoNFTTypeBaseRewards[4] = energyeggReward;
    dragoNFTTypeBaseRewards[5] = darknesseggReward;
    dragoNFTTypeBaseRewards[6] = lighteggReward;
  }
  
  // contract logic
  function stakeKingdom(uint256 kingdomNftID) public onlyOwner {
    address sender = address(msg.sender);
    IDragoKingdom dragoKingdom = IDragoKingdom(kingdomsContract);
    require(dragoKingdom.ownerOf(kingdomNftID) == sender, "You're not the owner of this Kingdom");
    require(buildsAtAddress[kingdomNftID] == address(0x000), "Kingdom already Stacked");
    // if there are Kingdoms with dragos of this kind at stack, make a claim without un-stacking
    uint256 genericType = dragoKingdom.getTypeIDByNftID(kingdomNftID);
    // TODO: Revisar creo que no debería hacer esto dado que cuando va haciendo el claim lo haría 2 veces
    // if (addressToKingdomsType[sender][genericType].length > 0 && addressToDragosType[sender][genericType].length > 0) {
    //   claimRewardsWithoutUnStack(genericType, sender);
    // }
    buildsAtAddress[kingdomNftID] = sender;
    addressToKingdomsType[sender][genericType].push(kingdomNftID);
    dragoKingdom.transferFrom(sender, address(this), kingdomNftID);
  }
  function stakeDrago(uint256 dragoNftId) public onlyOwner {
    address sender = address(msg.sender);
    IDragos dragosInstance = IDragos(dragoNFTContract);
    require(dragosInstance.ownerOf(dragoNftId) == sender, "You're not the owner of this Drago");
    require(dragosAtAddress[dragoNftId] == address(0x000), "DragoNFT already Stacked");
    uint256 genericType = dragosInstance.getTypeIdByNftId(dragoNftId);
    uint256 dragosByType = addressToDragosType[sender][genericType].length;
    uint256 maxSlots = addressToKingdomsType[sender][genericType].length * 3;
    uint256 freeSlots = maxSlots - dragosByType;
    require(freeSlots > 0, "Not free slots");

    addressToDragosType[sender][dragosInstance.getTypeIdByNftId(dragoNftId)].push(dragoNftId);
    dragosAtAddress[dragoNftId] = sender;
    dragosInstance.transferFrom(sender, address(this), dragoNftId);
    // claimRewards(); => Ya no se hace dado que solo se puede hacer cuando no generó nada
    dragoNFTStartFarmingTimestamp[dragoNftId] = block.timestamp;
  }
  function unStakeKingdom(uint256 genericType) public {
    address sender = address(msg.sender);
    require(addressToDragosType[sender][genericType].length == 0, "make claim instead");
    IDragoKingdom dragoKingdom = IDragoKingdom(kingdomsContract);
    require(addressToKingdomsType[sender][genericType].length > 0, "not stacked of this type");
    uint256 nftId = addressToKingdomsType[sender][genericType][addressToKingdomsType[sender][genericType].length - 1];
    require(buildsAtAddress[nftId] == sender, "not the stacker");
    // Como va a sacar un edificio tiene que haber al menos 3 slots libres
    uint256 dragosByType = addressToDragosType[sender][genericType].length;
    uint256 maxSlots = addressToKingdomsType[sender][genericType].length * 3;
    uint256 freeSlots = maxSlots - dragosByType;
    require(freeSlots >= 3, "still dragos on Kingdom");
    addressToKingdomsType[sender][genericType].pop();
    buildsAtAddress[nftId] = address(0x000);
    dragoKingdom.transferFrom(address(this), sender, nftId);
  }
  function unStakeDragos(uint256 genericType) public {
    address sender = address(msg.sender);
    require(addressToKingdomsType[sender][genericType].length == 0, "make claim instead");
    IDragos dragosInstance = IDragos(dragoNFTContract);
    require(addressToDragosType[sender][genericType].length > 0, "not dragos of this type");
    uint256 nftId = addressToDragosType[sender][genericType][addressToDragosType[sender][genericType].length];
    addressToDragosType[sender][genericType].pop();
    require(dragosAtAddress[nftId] == sender, "not the stacker");
    dragosAtAddress[nftId] = address(0x000); 
    dragosInstance.transferFrom(address(this), sender, nftId);
  }
  function adminUnStackDragoNFT(uint256 genericType, address owner, uint nftIdCheck) public onlyOwner {
    uint256 nftId = addressToDragosType[owner][genericType][addressToDragosType[owner][genericType].length - 1];
    require(nftId == nftIdCheck, "DragoNFT NFT Id not match");
    addressToDragosType[owner][genericType].pop();
    dragosAtAddress[nftId] = address(0x000); 
  }
  /*
    With each claim call it withdraw all the profits collected by the last drago of beeing stack and un-stack it.
    If that drago was the only one in a Kingdom, also claim and un-stack the gold collected by the Kingdom.
  */
  function claimRewards(uint256 genericType) public {
    address sender = address(msg.sender);
    require(addressToDragosType[sender][genericType].length > 0, "no dragos of this type");
    IDrago Drago = IDrago(DragoAddress);
    IDragos dragosInstance = IDragos(dragoNFTContract);
    uint256 totalDragosByType = addressToDragosType[sender][genericType].length;
    uint256 nftId = addressToDragosType[sender][genericType][totalDragosByType - 1];
    uint256 calculatedDelta = (block.timestamp - dragoNFTStartFarmingTimestamp[nftId]);
    uint256 totalRewards = calculatedDelta * dragoNFTTypeBaseRewards[genericType];


    dragosInstance.setDeltaStack(nftId, calculatedDelta);
    dragosInstance.transferFrom(address(this), sender, nftId);
    dragosAtAddress[nftId] = address(0x000);
    
    addressToDragosType[sender][genericType].pop();
    
    // adjust rewards
    if(calculatedDelta < 1296000) //Max 15 days
    {
      totalRewards = totalRewards / 86400;
    }
    else
    {
      totalRewards = 15 * dragoNFTTypeBaseRewards[genericType];
    }
    
    // transfer the rewards
    Drago.transfer(sender, totalRewards);
  }
  function claimRewardsWithoutUnStack(uint256 genericType, address sender) private {
    uint256 currentTimestamp = block.timestamp;
    require(addressToKingdomsType[sender][genericType].length > 0, "no Kingdoms of this type");
    require(addressToDragosType[sender][genericType].length > 0, "no dragos of this type");
    IDrago Drago = IDrago(DragoAddress);
    uint256 totalDragosByType = addressToDragosType[sender][genericType].length;
    // Add Drago profits
    uint256 totalRewards = 0;
    uint256 dragoDelta = currentTimestamp - dragoNFTStartFarmingTimestamp[addressToDragosType[sender][genericType][totalDragosByType - 1]];
    totalRewards += dragoDelta * dragoNFTTypeBaseRewards[genericType];
    // Add Kingdom profits
    if (((totalDragosByType - 1) % 3) == 0) {
      uint256 kingdomDelta = currentTimestamp - dragoNFTStartFarmingTimestamp[addressToDragosType[sender][genericType][totalDragosByType - 1]];
      totalRewards += kingdomDelta * kingdomTypeBaseRewards[genericType];
    }
    // adjust rewards
    totalRewards = totalRewards / 86400;
    // transfer the rewards
    Drago.transfer(sender, totalRewards);
  }
  function getStackedDragosIdsByType(address owner, uint256 genericType) public view returns(uint256[] memory) {
    return addressToDragosType[owner][genericType];
  }
  function getStackedBKingdomsIdsByType(address owner,uint256 genericType) public view returns(uint256[] memory) {
    return addressToKingdomsType[owner][genericType];
  }
  function currentFarmAccumulatorByDrago(uint256 dragonftid) public view returns(uint256) {
    address owner = dragosAtAddress[dragonftid];
    uint256 currentTimestamp = block.timestamp;
    IDragos dragosInstance = IDragos(dragoNFTContract);
    uint256 genericType = dragosInstance.getTypeIdByNftId(dragonftid);
    uint256 totalRewards = 0;
    if (addressToKingdomsType[owner][genericType].length <= 0) {
      totalRewards = 0;
    } else {
      uint256 dragoDelta = currentTimestamp - dragoNFTStartFarmingTimestamp[dragonftid];
      totalRewards += dragoDelta * dragoNFTTypeBaseRewards[genericType];
      // adjust rewards
      if (dragoDelta < 1296000) {
        totalRewards = totalRewards / 86400;
      } else {
        totalRewards = 15 * dragoNFTTypeBaseRewards[genericType];
      }
    }

    return totalRewards;
  }
  function getDragoAge(uint256 dragoNftId) internal view returns (uint256){
    IDragos dragoInstance = IDragos(dragoNFTContract);
    (
  	  uint256 idx,
	    uint256 id,
	    uint8 level,
	    uint256 age,
	    string memory edition,
	    uint256 bornAt,
	    bool onSale,
	    uint256 price
    ) = dragoInstance.dragos(dragoNftId - 1);
    return bornAt;
  }

  function claimSpecialRewards(uint256 dragoNftID) public returns (uint256){}
  function calculateSpecialRewards(uint256 dragoNftID) public view returns (uint256) {}

  //FIGHT Section
  function createMonster(uint256 typeNum,uint256 bait,uint256 reward,uint256 winningProv) public onlyOwner{
    Monster memory _toCreate = Monster(typeNum, bait, reward, winningProv);
    monsters_[typeNum] = _toCreate;
  }
  function fightAgainst(uint256 dragoNftID, uint256 monster) public returns (bool) {
    address sender = address(msg.sender);
    IDragos dragoInstance = IDragos(dragoNFTContract);
    bool isOwner = dragoInstance.ownerOf(dragoNftID) == sender;
    bool isWarrior = dragoInstance.getTypeIdByNftId(dragoNftID) == 6;
    require(isOwner, "This DRAGO doesn't belong to you");
    require(isWarrior, "Only Light Dragos can battle");
    IDrago aGoldInstance = IDrago(DragoAddress);
    require(aGoldInstance.balanceOf(sender) >= monsters_[monster].bait, "Insufficient Drago to fight");
    require(aGoldInstance.allowance(sender, address(this)) >= monsters_[monster].reward, "Insufficient allowance");

    bool won = fight(monsters_[monster].winningProb);
    if(won){
      aGoldInstance.transfer(sender, (monsters_[monster].reward));
      winsByNftId[dragoNftID] += 1;
      totalBattlesByNftId[dragoNftID] += 1;
      emit FightFinished(sender, dragoNftID, true, (monsters_[monster].reward));
      return true;
    }
    else
    {
      aGoldInstance.transferFrom(sender, address(this), monsters_[monster].bait);
      totalBattlesByNftId[dragoNftID] += 1;
      emit FightFinished(sender, dragoNftID, false, (monsters_[monster].bait));
      return false;
    }
  }
  function fight(uint percent) private view returns(bool) {
    uint256 spinResult = (block.gaslimit + block.timestamp) % 10; //Random 1 digit between 0-9
    uint256 adjPercent = (percent / 10) - 1;
    if (spinResult >= 0 && spinResult <= adjPercent) {
      return true;
    } 
    else 
    {
      return false;
    }
  }
}