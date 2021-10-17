// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import { EtherOrcs } from "./EtherOrcs.sol";
import { ERC20 } from "./ERC20.sol";

contract Migrator {

    address implementation_;
    address public admin;
    EtherOrcs public  oldOrcs;
    EtherOrcs public  newOrcs;
    ERC20     public  zug;

    address  public burningAddress;
    uint256  public startingTime;

    mapping(uint256 => bool) public migrated;

    function initialize(address oldOrcs_,address newOrcs_, address zug_, address burningAddress_) public {
        require(msg.sender == admin);
        oldOrcs        = EtherOrcs(oldOrcs_);
        newOrcs        = EtherOrcs(newOrcs_);
        zug            = ERC20(zug_);
        burningAddress = burningAddress_;

        startingTime = block.timestamp;
    }
    
    function implementation() public view returns (address impl) {
        impl = implementation_;
    }

    function migrateMany(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            justMigrate(ids[index]);
        }
    }

    function migrateManyAndFarm(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            migrateAndFarm(ids[index]);
        }
    }

    function migrateManyAndTrain(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            migrateAndTrain(ids[index]);
        }
    }

    function migrateAndFarm(uint256 tokenId) public {
        _migrate(tokenId);
        //give retroactive time
        newOrcs.migrationAction(tokenId, msg.sender, EtherOrcs.Actions.FARMING);
    }

    function migrateAndTrain(uint256 tokenId) public {
        _migrate(tokenId);
        //give retroactive time
        newOrcs.migrationAction(tokenId, msg.sender, EtherOrcs.Actions.TRAINING);
    }

    function justMigrate(uint256 tokenId) public {
        _migrate(tokenId);
    }

    function _migrate(uint256 tokenId) internal {
        require(!migrated[tokenId], "already migrated");

        //Check what the orc is doing
        (address owner, uint88 timestamp, EtherOrcs.Actions action_) = oldOrcs.activities(tokenId);
        require(msg.sender == oldOrcs.ownerOf(tokenId) || (action_ == EtherOrcs.Actions.FARMING && owner == msg.sender), "not allowed");


        (uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level ,uint16 zugModifier , uint32 lvlProgress) = oldOrcs.orcs(tokenId);
        

        uint zugAmount;
        if (action_ == EtherOrcs.Actions.FARMING) {
            // We cant't transfer here, but it's safe there
            zugAmount = claimableZug(block.timestamp - timestamp, zugModifier);
        } else {
            // Transfer From to here
            oldOrcs.transferFrom(msg.sender, address(burningAddress), tokenId);
        }
        
        (helm, mainhand, offhand) = getEquipment(helm,mainhand,offhand);
        // Mint an excatly the the same orcs
        newOrcs.craft(msg.sender, tokenId,body,helm,mainhand,offhand,level,lvlProgress);

        migrated[tokenId] = true;

        if (block.timestamp - 25 hours < startingTime) zug.mint(owner,1 ether + zugAmount);
    } 
    
    function getEquipment(uint8 helm_, uint8 mainhand_, uint8 offhand_) internal returns (uint8 helm, uint8 mainhand, uint8 offhand) {
        uint maxTier = 6;
        helm     = _tier(helm_)     > maxTier ? helm_ - 4     : helm_;
        mainhand = _tier(mainhand_) > maxTier ? mainhand_ - 4 : mainhand_;
        offhand  = _tier(offhand_)  > maxTier ? offhand_ - 4  : offhand_;
    }

    function claimableZug(uint256 timeDiff, uint16 zugModifier) internal pure returns (uint256 zugAmount) {
        zugAmount = timeDiff * (4 + zugModifier) * 1 ether / 1 days;
    }

    function _tier(uint16 id) internal pure returns (uint16) {
        if (id == 0) return 0;
        return ((id - 1) / 4 );
    }
    

}