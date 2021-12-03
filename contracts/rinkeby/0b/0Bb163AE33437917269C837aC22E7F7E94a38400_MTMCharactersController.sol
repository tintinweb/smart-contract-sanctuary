/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function transferFrom(address from_, address to_, uint256 tokenId_) external;
}

interface iCM {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function transferFrom(address from_, address to_, uint256 tokenId_) external;
    function contractAddressToTokenUploaded(address contractAddress_, uint256 tokenId_) external view returns (bool);
}

interface iMES {
    // View Functions
    function balanceOf(address address_) external view returns (uint256);
    function pendingRewards(address address_) external view returns (uint256); 
    function getStorageClaimableTokens(address address_) external view returns (uint256);
    function getPendingClaimableTokens(address address_) external view returns (uint256);
    function getTotalClaimableTokens(address address_) external view returns (uint256);
    // Administration
    function setYieldRate(address address_, uint256 yieldRate_) external;
    function addYieldRate(address address_, uint256 yieldRateAdd_) external;
    function subYieldRate(address address_, uint256 yieldRateSub_) external;
    // Updating
    function updateReward(address address_) external;
    // Credits System
    function deductCredits(address address_, uint256 amount_) external;
    function addCredits(address address_, uint256 amount_) external;
    // Burn
    function burn(address from, uint256 amount_) external;
}

interface iCS {
    struct Character {
        uint8  race_;
        uint8  renderType_;
        uint16 transponderId_;
        uint16 spaceCapsuleId_;
        uint8  augments_;
        uint16 basePoints_;
        uint16 totalEquipmentBonus_;
    }
    struct Stats {
        uint8 strength_; 
        uint8 agility_; 
        uint8 constitution_; 
        uint8 intelligence_; 
        uint8 spirit_; 
    }
    struct Equipment {
        uint8 weaponUpgrades_;
        uint8 chestUpgrades_;
        uint8 headUpgrades_;
        uint8 legsUpgrades_;
        uint8 vehicleUpgrades_;
        uint8 armsUpgrades_;
        uint8 artifactUpgrades_;
        uint8 ringUpgrades_;
    }

    // Create Character
    function createCharacter(uint tokenId_, Character memory Character_) external;
    // Characters
    function setName(uint256 tokenId_, string memory name_) external;
    function setBio(uint256 tokenId_, string memory bio_) external;
    function setRace(uint256 tokenId_, uint8 race_) external;
    function setRenderType(uint256 tokenId_, uint8 renderType_) external;
    function setTransponderId(uint256 tokenId_, uint16 transponderId_) external;
    function setSpaceCapsuleId(uint256 tokenId_, uint16 spaceCapsuleId_) external;
    function setAugments(uint256 tokenId_, uint8 augments_) external;
    function setBasePoints(uint256 tokenId_, uint16 basePoints_) external;
    function setBaseEquipmentBonus(uint256 tokenId_, uint16 baseEquipmentBonus_) external;
    function setTotalEquipmentBonus(uint256 tokenId_, uint16 totalEquipmentBonus) external;
    // Stats
    function setStrength(uint256 tokenId_, uint8 strength_) external;
    function setAgility(uint256 tokenId_, uint8 agility_) external;
    function setConstitution(uint256 tokenId_, uint8 constitution_) external;
    function setIntelligence(uint256 tokenId_, uint8 intelligence_) external;
    function setSpirit(uint256 tokenId_, uint8 spirit_) external;
    // Equipment
    function setWeaponUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setChestUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setHeadUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setLegsUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setVehicleUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setArmsUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setArtifactUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setRingUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    // Structs and Mappings
    function names(uint256 tokenId_) external view returns (string memory);
    function characters(uint256 tokenId_) external view returns (Character memory);
    function stats(uint256 tokenId_) external view returns (Stats memory);
    function equipments(uint256 tokenId_) external view returns (Equipment memory);
    function contractToRace(address contractAddress_) external view returns (uint8);
}

library Strings {
    function toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }
}

library MTMLib {
    // Static String Returns
    function getNameOfItem(uint8 item_) public pure returns (string memory) {
        if      (item_ == 1) { return "WEAPONS";   }
        else if (item_ == 2) { return "CHEST";     }
        else if (item_ == 3) { return "HEAD";      }
        else if (item_ == 4) { return "LEGS";      }
        else if (item_ == 5) { return "VEHICLE";   }
        else if (item_ == 6) { return "ARMS";      }
        else if (item_ == 7) { return "ARTIFACTS"; }
        else if (item_ == 8) { return "RINGS";     }
        else                 { revert("Invalid Equipment Upgrades Query!"); }
    }

    // Static Rarity Stuff
    function getItemRarity(uint16 spaceCapsuleId_, string memory keyPrefix_) public pure returns (uint8) {
        uint256 _rarity = uint256(keccak256(abi.encodePacked(keyPrefix_, Strings.toString(spaceCapsuleId_)))) % 21;
        return uint8(_rarity);
    }
    function queryEquipmentUpgradability(uint8 rarity_) public pure returns (uint8) {
        return rarity_ >= 19 ? rarity_ == 19 ? 4 : 4 : 4; 
    }
    function queryBaseEquipmentTier(uint8 rarity_) public pure returns (uint8) {
        return rarity_ >= 19 ? rarity_ == 19 ? 1 : 2 : 0;
    }

    // Character Modification Costs
    function queryAugmentCost(uint8 currentLevel_) public pure returns (uint256) {
        if      (currentLevel_ == 0) { return 0;         }
        else if (currentLevel_ == 1) { return 1 ether;   }
        else if (currentLevel_ == 2) { return 2 ether;   }
        else if (currentLevel_ == 3) { return 5 ether;   }
        else if (currentLevel_ == 4) { return 10 ether;  }
        else if (currentLevel_ == 5) { return 15 ether;  }
        else if (currentLevel_ == 6) { return 25 ether;  }
        else if (currentLevel_ == 7) { return 50 ether;  }
        else if (currentLevel_ == 8) { return 100 ether; }
        else if (currentLevel_ == 9) { return 250 ether; }
        else                         { revert("Invalid level!"); }
    }
    function queryBasePointsUpgradeCost(uint16 currentLevel_) public pure returns (uint256) {
        uint8 _tier = uint8(currentLevel_ / 5);
        if      (_tier == 0) { return 1 ether;   }
        else if (_tier == 1) { return 2 ether;   }
        else if (_tier == 2) { return 5 ether;   }
        else if (_tier == 3) { return 10 ether;  }
        else if (_tier == 4) { return 20 ether;  }
        else if (_tier == 5) { return 30 ether;  }
        else if (_tier == 6) { return 50 ether;  }
        else if (_tier == 7) { return 70 ether;  }
        else if (_tier == 8) { return 100 ether; }
        else if (_tier == 9) { return 150 ether; }
        else                 { revert("Invalid Level!"); }
    }
    function queryEquipmentUpgradeCost(uint8 currentLevel_) public pure returns (uint256) {
        if      (currentLevel_ == 0) { return 50 ether;   }
        else if (currentLevel_ == 1) { return 250 ether;  }
        else if (currentLevel_ == 2) { return 750 ether;  }
        else if (currentLevel_ == 3) { return 1500 ether; }
        else                         { revert("Invalid Level!"); }
    }

    // Yield Rate Constants
    function getBaseYieldRate(uint8 augments_) public pure returns (uint256) {
        if      (augments_ == 0 ) { return 0.1 ether; }
        else if (augments_ == 1 ) { return 1 ether;   }
        else if (augments_ == 2 ) { return 2 ether;   }
        else if (augments_ == 3 ) { return 3 ether;   }
        else if (augments_ == 4 ) { return 4 ether;   }
        else if (augments_ == 5 ) { return 5 ether;   }
        else if (augments_ == 6 ) { return 6 ether;   }
        else if (augments_ == 7 ) { return 7 ether;   }
        else if (augments_ == 8 ) { return 8 ether;   }
        else if (augments_ == 9 ) { return 9 ether;   }
        else if (augments_ == 10) { return 10 ether;  }
        else                      { return 0;         }
    }
    function queryEquipmentModulus(uint8 rarity_, uint8 upgrades_) public pure returns (uint8) {
        uint8 _baseTier = queryBaseEquipmentTier(rarity_);
        uint8 _currentTier = _baseTier + upgrades_;
        if      (_currentTier == 0) { return 0;  }
        else if (_currentTier == 1) { return 2;  }
        else if (_currentTier == 2) { return 5;  }
        else if (_currentTier == 3) { return 10; }
        else if (_currentTier == 4) { return 20; }
        else if (_currentTier == 5) { return 35; }
        else if (_currentTier == 6) { return 50; }
        else                        { revert("Invalid Level!"); }
    }
    function getStatMultiplier(uint16 basePoints_) public pure returns (uint256) {
        return uint256( (basePoints_ * 2) + 100 );
    }
    function getEquipmentMultiplier(uint16 totalEquipmentBonus_) public pure returns (uint256) {
        return uint256( totalEquipmentBonus_ + 100 );
    }

    // Base Yield Rate Caclulations
    function getItemBaseBonus(uint16 spaceCapsuleId_, string memory keyPrefix_) public pure returns (uint8) {
        return queryEquipmentModulus( getItemRarity(spaceCapsuleId_, keyPrefix_), 0 );
    }
    function getEquipmentBaseBonus(uint16 spaceCapsuleId_) public pure returns (uint16) {
        return uint16(
        getItemBaseBonus(spaceCapsuleId_, "WEAPONS") + 
        getItemBaseBonus(spaceCapsuleId_, "CHEST") +
        getItemBaseBonus(spaceCapsuleId_, "HEAD") +
        getItemBaseBonus(spaceCapsuleId_, "LEGS") +
        getItemBaseBonus(spaceCapsuleId_, "VEHICLE") +
        getItemBaseBonus(spaceCapsuleId_, "ARMS") + 
        getItemBaseBonus(spaceCapsuleId_, "ARTIFACTS") +
        getItemBaseBonus(spaceCapsuleId_, "RINGS")
        );
    }

    // Yield Rate Calculation
    function getCharacterYieldRate(uint8 augments_, uint16 basePoints_, uint16 totalEquipmentBonus_) public pure returns (uint256) {
        uint256 _baseYield = getBaseYieldRate(augments_);
        uint256 _statMultiplier = getStatMultiplier(basePoints_);
        uint256 _eqMultiplier = getEquipmentMultiplier(totalEquipmentBonus_);
        return _baseYield * (_statMultiplier * _eqMultiplier) / 10000;
    }
}

library MTMStrings {
    function onlyAllowedCharacters(string memory string_) public pure returns (bool) {
        bytes memory _strBytes = bytes(string_);
        for (uint i = 0; i < _strBytes.length; i++) {
            if (_strBytes[i] < 0x20 || _strBytes[i] > 0x7A || _strBytes[i] == 0x26 || _strBytes[i] == 0x22 || _strBytes[i] == 0x3C || _strBytes[i] == 0x3E) {
                return false;
            }     
        }
        return true;
    }
}

contract MTMCharactersController {
    // Access
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(msg.sender == owner, "You are not the owner!"); _; }
    function setNewOwner(address address_) external onlyOwner { owner = address_; }

    // Burn Target
    address internal constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    // Interfaces
    iCM public CM; iMES public MES; iCS public CS;
    IERC721 public SC; IERC721 public TP;
    function setContracts(address cm_, address mes_, address cs_, address sc_, address tp_) external onlyOwner {
        CM = iCM(cm_); MES = iMES(mes_); CS = iCS(cs_);
        SC = IERC721(sc_); TP = IERC721(tp_);
    }

    // Internal Write Functions
    function __MESPayment(address address_, uint256 amount_, bool useCredits_) internal {
        if (useCredits_) {
            require(amount_ <= MES.getTotalClaimableTokens(address_), "Not enough MES credits to do action!");
            if (amount_ >= MES.getStorageClaimableTokens(address_)) { MES.updateReward(address_); }
            MES.deductCredits(address_, amount_);
        } else {
            require(amount_ <= MES.balanceOf(address_), "Not enough MES to do action!");
            MES.burn(address_, amount_);
        }
    }
    function __updateReward(address address_) internal {
        MES.updateReward(address_);
    }
    function __addYieldRate(address address_, uint256 yieldRate_) internal {
        MES.addYieldRate(address_, yieldRate_);
    }

    // Internal Read Functions
    function __getCharacter(uint256 characterId_) internal view returns (iCS.Character memory) {
        return CS.characters(characterId_);
    }
    function __getEquipment(uint256 characterId_) internal view returns (iCS.Equipment memory) {
        return CS.equipments(characterId_);
    }
    function __getStats(uint256 characterId_) internal view returns (iCS.Stats memory) {
        return CS.stats(characterId_);
    }
    function __getAugments(uint256 characterId_) internal view returns (uint8) {
        return CS.characters(characterId_).augments_;
    }
    function __getBasePoints(uint256 characterId_) internal view returns (uint16) {
        return CS.characters(characterId_).basePoints_;
    }

    // Internal Equipment Administration
    function __getEquipmentUpgrades(iCS.Equipment memory Equipment_, uint8 item_) internal pure returns (uint8) {
        if      (item_ == 1) { return Equipment_.weaponUpgrades_;   }
        else if (item_ == 2) { return Equipment_.chestUpgrades_;    }
        else if (item_ == 3) { return Equipment_.headUpgrades_;     }
        else if (item_ == 4) { return Equipment_.legsUpgrades_;     }
        else if (item_ == 5) { return Equipment_.vehicleUpgrades_;  }
        else if (item_ == 6) { return Equipment_.armsUpgrades_;     }
        else if (item_ == 7) { return Equipment_.artifactUpgrades_; }
        else if (item_ == 8) { return Equipment_.ringUpgrades_;     }
        else                 { revert("Invalid Equipment Upgrades Query!"); }
    }
    function __setItemUpgrades(uint256 characterId_, uint8 newUpgrades_, uint8 item_) internal {
        if      (item_ == 1) { CS.setWeaponUpgrades(characterId_, newUpgrades_);   }
        else if (item_ == 2) { CS.setChestUpgrades(characterId_, newUpgrades_);    }
        else if (item_ == 3) { CS.setHeadUpgrades(characterId_, newUpgrades_);     }
        else if (item_ == 4) { CS.setLegsUpgrades(characterId_, newUpgrades_);     }
        else if (item_ == 5) { CS.setVehicleUpgrades(characterId_, newUpgrades_);  }
        else if (item_ == 6) { CS.setArmsUpgrades(characterId_, newUpgrades_);     }
        else if (item_ == 7) { CS.setArtifactUpgrades(characterId_, newUpgrades_); }
        else if (item_ == 8) { CS.setRingUpgrades(characterId_, newUpgrades_);     }
        else                 { revert("Invalid Equipment Set Upgrade Query!"); }
    }

    // Augment Character
    function augmentCharacter(uint256 characterId_, uint256[] memory charactersToBurn_, bool useCredits_) public {
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this character!");

        iCS.Character memory _Character = __getCharacter(characterId_);

        uint8 _augments = _Character.augments_;
        uint8 _numberOfAugments = uint8(charactersToBurn_.length);

        // Calculate the Augmentation Cost
        uint256 _totalAugmentCost;
        for (uint8 i = 0; i < _numberOfAugments; i++) {
            _totalAugmentCost += MTMLib.queryAugmentCost(_augments + i);
        }

        // Check $MES Requirements and Burn $MES!
        __MESPayment(msg.sender, _totalAugmentCost, useCredits_);

        // Check Character Requirements and Loop-Burn Characters!
        for (uint8 i = 0; i < _numberOfAugments; i++) {
            require(characterId_ != charactersToBurn_[i], "Cannot Burn Augmenting Character!");
            require(msg.sender == CM.ownerOf(charactersToBurn_[i]), "Unowned Character to Burn!");

            CM.transferFrom(msg.sender, burnAddress, charactersToBurn_[i]);
        }

        // Update Reward
        __updateReward(msg.sender);

        // Calculate Current Character Yield Rate before Augment
        uint256 _currentYieldRate = MTMLib.getCharacterYieldRate(_augments, _Character.basePoints_, _Character.totalEquipmentBonus_);

        // Set New Augment Level
        uint8 _newAugments = _augments + _numberOfAugments;
        CS.setAugments(characterId_, _newAugments);

        // Calculate New Character Yield Rate and Difference
        uint256 _newYieldRate = MTMLib.getCharacterYieldRate(_newAugments, _Character.basePoints_, _Character.totalEquipmentBonus_);
        uint256 _increasedYieldRate = _newYieldRate - _currentYieldRate;

        // Add Increased Yield Rate
        __addYieldRate(msg.sender, _increasedYieldRate);
    }
    function augmentCharacterWithMats(uint256 characterId_, uint256[] memory transponders_, uint256[] memory spaceCapsules_, bool useCredits_) public {
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this Character!");
        require(transponders_.length == spaceCapsules_.length, "Pair length mismatch!");

        iCS.Character memory _Character = __getCharacter(characterId_);

        uint8 _augments = __getAugments(characterId_);
        uint8 _numberOfAugments = uint8(transponders_.length);

        // Calculate the Augmentation Cost
        uint256 _totalAugmentCost;
        for (uint8 i = 0; i < _numberOfAugments; i++) {
            _totalAugmentCost += MTMLib.queryAugmentCost(_augments + i);
        }

        // Check $MES Requirements and Burn $MES!
        __MESPayment(msg.sender, _totalAugmentCost, useCredits_);

        // Check TP/SC Requirements and Loop-Burn TP/SC!
        for (uint8 i = 0; i < _numberOfAugments; i++) {
            require(msg.sender == TP.ownerOf(transponders_[i]) && msg.sender == SC.ownerOf(spaceCapsules_[i]), "Not owner of pair!");

            TP.transferFrom(msg.sender, burnAddress, transponders_[i]);
            SC.transferFrom(msg.sender, burnAddress, spaceCapsules_[i]);
        }

        // Update Reward
        __updateReward(msg.sender);

        // Calculate Current Character Yield Rate before Augment
        uint256 _currentYieldRate = MTMLib.getCharacterYieldRate(_augments, _Character.basePoints_, _Character.totalEquipmentBonus_);

        // Set New Augment Level
        uint8 _newAugments = _augments + _numberOfAugments;
        CS.setAugments(characterId_, _newAugments);

        // Calculate New Character Yield Rate and Difference
        uint256 _newYieldRate = MTMLib.getCharacterYieldRate(_newAugments, _Character.basePoints_, _Character.totalEquipmentBonus_);
        uint256 _increasedYieldRate = _newYieldRate - _currentYieldRate;

        // Add Increased Yield Rate
        __addYieldRate(msg.sender, _increasedYieldRate);
    }

    // Level Up Base Points
    function levelUp(uint256 characterId_, uint16 amount_, bool useCredits_) public {
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this Character!");

        iCS.Character memory _Character = __getCharacter(characterId_);

        uint16 _currentBasePoints = __getBasePoints(characterId_);

        // Calculate $MES Cost for Level Up
        uint256 _levelUpCost;
        for (uint16 i = 0; i < amount_; i++) {
            _levelUpCost += MTMLib.queryBasePointsUpgradeCost(_currentBasePoints + i);
        }

        // Check $MES Requires and Burn $MES!
        __MESPayment(msg.sender, _levelUpCost, useCredits_);

        // Update Reward
        __updateReward(msg.sender);

        // Calculate Current Character Yield Rate before Augment
        uint256 _currentYieldRate = MTMLib.getCharacterYieldRate(
            _Character.augments_, _currentBasePoints, _Character.totalEquipmentBonus_);

        // Set New Base Points
        uint16 _newBasePoints = _currentBasePoints + amount_;
        CS.setBasePoints(characterId_, _newBasePoints);

        // Calculate Yield Rate Benefits
        uint256 _newYieldRate = MTMLib.getCharacterYieldRate(
            _Character.augments_, _newBasePoints, _Character.totalEquipmentBonus_);
        uint256 _increasedYieldRate = _newYieldRate - _currentYieldRate;

        // Add Increased Yield Rate
        __addYieldRate(msg.sender, _increasedYieldRate);
    }
    function multiLevelUp(uint256[] memory characterIds_, uint16[] memory amounts_, bool useCredits_) public {
        // User must make sure they have enough $MES for the entire loop otherwise it will revert. Use with care.
        require(characterIds_.length == amounts_.length, "Mismatched length of arrays!");
        for (uint256 i = 0; i < characterIds_.length; i++) {
            levelUp(characterIds_[i], amounts_[i], useCredits_);
        }
    }

    // Equipment Upgrade
    function upgradeEquipment(uint256 characterId_, uint8 amount_, uint8 item_, bool useCredits_) public {
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this Character!");

        iCS.Character memory _Character = __getCharacter(characterId_);
        iCS.Equipment memory _Equipment = __getEquipment(characterId_);

        uint8 _rarity = MTMLib.getItemRarity(_Character.spaceCapsuleId_, MTMLib.getNameOfItem(item_));
        uint8 _currentUpgrades = __getEquipmentUpgrades(_Equipment, item_);

        require(_currentUpgrades + amount_ <= MTMLib.queryEquipmentUpgradability(_rarity), "Request to upgrade past upgradability!");

        // Calculate the Upgrade Cost
        uint256 _upgradeCost;
        for (uint8 i = 0; i < amount_; i++) {
            _upgradeCost += MTMLib.queryEquipmentUpgradeCost(_currentUpgrades + i);
        }

        // Check $MES Requires and Burn $MES!
        __MESPayment(msg.sender, _upgradeCost, useCredits_);

        // Update Reward
        __updateReward(msg.sender);

        // Calculate the Curent Yield Rate before Upgrading
        uint256 _currentYieldRate = MTMLib.getCharacterYieldRate(_Character.augments_, _Character.basePoints_, _Character.totalEquipmentBonus_);

        // Calculate and Set the New Item Level
        uint8 _newUpgrades = _currentUpgrades + amount_;
        __setItemUpgrades(characterId_, _newUpgrades, item_);

        // Calculate and Set the New Total Equipment Bonus of the Character
        uint16 _newTotalEquipmentBonus = _Character.totalEquipmentBonus_ + ( MTMLib.queryEquipmentModulus(_rarity, _newUpgrades) - MTMLib.queryEquipmentModulus(_rarity, _currentUpgrades) );
        CS.setTotalEquipmentBonus(characterId_, _newTotalEquipmentBonus);

        // Calculate the Yield Rate Difference
        uint256 _newYieldRate = MTMLib.getCharacterYieldRate(_Character.augments_, _Character.basePoints_, _newTotalEquipmentBonus);
        uint256 _increasedYieldRate = _newYieldRate - _currentYieldRate;

        // Adjust the Yield Rate accordingly
        __addYieldRate(msg.sender, _increasedYieldRate);
    }
    function multiUpgradeEquipment(uint256 characterId_, uint8[] memory amounts_, uint8[] memory items_, bool useCredits_) public {
        require(amounts_.length == items_.length, "Amounts and Items length mismatch!");
        for (uint256 i = 0; i < amounts_.length; i++) {
            upgradeEquipment(characterId_, amounts_[i], items_[i], useCredits_);
        }
    }

    // Role Play Stats
    function __getTotalStatsLeveled(iCS.Stats memory Stats_) internal pure returns (uint8) {
        return Stats_.strength_ + Stats_.agility_ + Stats_.constitution_ + Stats_.intelligence_ + Stats_.spirit_;
    }
    function __getCharacterLevel(iCS.Stats memory Stats_, uint8 attribute_) internal pure returns (uint8) {
        if      (attribute_ == 1) { return Stats_.strength_; }
        else if (attribute_ == 2) { return Stats_.agility_; }
        else if (attribute_ == 3) { return Stats_.constitution_; }
        else if (attribute_ == 4) { return Stats_.intelligence_; }
        else if (attribute_ == 5) { return Stats_.spirit_; }
        else                      { revert("Invalid attribute type!"); }
    }
    function __setCharacterLevel(uint256 characterId_, uint8 attribute_, uint8 level_) internal {
        if      (attribute_ == 1) { CS.setStrength(characterId_, level_); }
        else if (attribute_ == 2) { CS.setAgility(characterId_, level_); }
        else if (attribute_ == 3) { CS.setConstitution(characterId_, level_); }
        else if (attribute_ == 4) { CS.setIntelligence(characterId_, level_); }
        else if (attribute_ == 5) { CS.setSpirit(characterId_, level_); }
        else                      { revert("Invalid attribute type!"); }
    }
    function levelCharacterStat(uint256 characterId_, uint8 attribute_, uint8 amount_) public {
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this Character!");

        iCS.Character memory _Character = __getCharacter(characterId_);
        iCS.Stats memory _Stats = __getStats(characterId_);
        require(__getTotalStatsLeveled(_Stats) + amount_ <= _Character.basePoints_, "Request to upgrade stats above available base points!");

        // Get Current Level and New Level of Attribute
        uint8 _currentLevel = __getCharacterLevel(_Stats, attribute_);
        uint8 _newLevel = _currentLevel + amount_;

        // Set New Level for Attribute
        __setCharacterLevel(characterId_, attribute_, _newLevel);
    }
    function multiLevelCharacterStat(uint256 characterId_, uint8[] memory attributes_, uint8[] memory amounts_) public {
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this Character!");
        require(attributes_.length == amounts_.length, "Attributes and Amounts length mismatch!");
        
        // Load Character and Stats into local memory
        iCS.Character memory _Character = __getCharacter(characterId_);
        iCS.Stats memory _Stats = __getStats(characterId_);

        // Calculate total Amounts to add
        uint16 _amountToAdd;
        for (uint256 i = 0; i < amounts_.length; i++) {
            _amountToAdd += amounts_[i];
        }

        // Make sure stat upgrades are not above base points
        require(__getTotalStatsLeveled(_Stats) + _amountToAdd <= _Character.basePoints_, "Request to upgrade stats above available base points!");

        // Loop-Level each stat
        for (uint256 i = 0; i < amounts_.length; i++) {
            uint8 _currentLevel = __getCharacterLevel(_Stats, attributes_[i]);
            uint8 _newLevel = _currentLevel + amounts_[i];

            __setCharacterLevel(characterId_, attributes_[i], _newLevel);
        }
    }

    // General Cosmetics Variables
    uint256 nameChangeCost = 5 ether;
    uint256 bioChangeCost = 20 ether;
    uint256 rerollRaceCost = 10 ether;
    uint256 uploadRaceCost = 50 ether;
    uint256 renderTypeChangeCost = 10 ether;
    function __setCostmeticCost(uint8 type_, uint256 cost_) internal {
        if      (type_ == 1) { nameChangeCost = cost_; }
        else if (type_ == 2) { bioChangeCost = cost_; }
        else if (type_ == 3) { rerollRaceCost = cost_; }
        else if (type_ == 4) { uploadRaceCost = cost_; }
        else if (type_ == 5) { renderTypeChangeCost = cost_; }
        else                 { revert("Invalid Type!"); }
    }
    function setCosmeticCosts(uint8[] memory types_, uint256[] memory costs_) public onlyOwner {
        require(types_.length == costs_.length, "Array length mismatch!");
        for (uint256 i = 0; i < costs_.length; i++) {
            __setCostmeticCost(types_[i], costs_[i]);
        }
    }

    // Change Name
    function changeName(uint256 characterId_, string memory name_, bool useCredits_) public {
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this Character!");
        require(MTMStrings.onlyAllowedCharacters(name_), "Name contains unallowed characters!");
        require(20 >= bytes(name_).length, "Name can only contain 20 characters max!");
        __MESPayment(msg.sender, nameChangeCost, useCredits_);
        CS.setName(characterId_, name_);
    }

    // Change Bio
    function changeBio(uint256 characterId_, string memory bio_, bool useCredits_) public {
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this Character!");
        require(MTMStrings.onlyAllowedCharacters(bio_), "Bio contains unallowed characters!");
        // require(160 >= bytes(bio_).length, "Bio can only contain 160 characters max!");
        __MESPayment(msg.sender, bioChangeCost, useCredits_);
        CS.setBio(characterId_, bio_);
    }

    // Reroll Race
    bool public characterRerollable;
    function setCharacterRerollable(bool bool_) public onlyOwner { characterRerollable = bool_; }
    
    function rerollRace(uint256 characterId_, bool useCredits_) public {
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this Character!");
        __MESPayment(msg.sender, rerollRaceCost, useCredits_);
        uint8 _race = uint8( (uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, characterId_))) % 10) + 1 ); // RNG (1-10) 
        CS.setRace(characterId_, _race);
    }

    // Upload Race
    bool public characterUploadable;
    function setCharacterUploadable(bool bool_) public onlyOwner { characterUploadable = bool_; }
    mapping(address => mapping(uint256 => bool)) public contractAddressToTokenUploaded;
    
    function uploadRace(uint256 characterId_, address contractAddress_, uint256 uploadId_, bool useCredits_) public {
        require(characterUploadable, "Character type is not uploadable!");
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this Character!");
        require(!CM.contractAddressToTokenUploaded(contractAddress_, uploadId_), "This character has already been uploaded!"); // from CM
        require(contractAddressToTokenUploaded[contractAddress_][uploadId_], "This character has already been uploaded"); // from this contract

        __MESPayment(msg.sender, uploadRaceCost, useCredits_);

        contractAddressToTokenUploaded[contractAddress_][uploadId_] = true;

        uint8 _race = CS.contractToRace(contractAddress_);
        CS.setRace(characterId_, _race);
    }

    // Change Render Type
    bool public renderTypeChangable;
    function setRenderTypeChangable(bool bool_) public onlyOwner { renderTypeChangable = bool_; }
    
    function changeRenderType(uint256 characterId_, uint8 renderType_, bool useCredits_) public {
        require(renderTypeChangable, "Render type is not changable!");
        require(msg.sender == CM.ownerOf(characterId_), "You don't own this Character!");
         __MESPayment(msg.sender, uploadRaceCost, useCredits_);
        CS.setRenderType(characterId_, renderType_);
    }

    // Public View Functions (Mainly for Interfacing)
    function getCharacterYieldRate(uint256 characterId_) public view returns (uint256) {
        iCS.Character memory Character_ = __getCharacter(characterId_);
        return MTMLib.getCharacterYieldRate(Character_.augments_, Character_.basePoints_, Character_.totalEquipmentBonus_);
    }
    function queryCharacterYieldRate(uint8 augments_, uint16 basePoints_, uint16 totalEquipmentBonus_) public pure returns (uint256) {
        return MTMLib.getCharacterYieldRate(augments_, basePoints_, totalEquipmentBonus_);
    }
    function getItemRarity(uint16 spaceCapsuleId_, string memory keyPrefix_) public pure returns (uint8) {
        return MTMLib.getItemRarity(spaceCapsuleId_, keyPrefix_);
    }
    function queryBaseEquipmentTier(uint8 rarity_) public pure returns (uint8) {
        return MTMLib.queryBaseEquipmentTier(rarity_);
    }
    function getEquipmentBaseBonus(uint16 spaceCapsuleId_) public pure returns (uint16) {
        return MTMLib.getEquipmentBaseBonus(spaceCapsuleId_);
    }

    // Add GetCurrentItemLevel public view function
}