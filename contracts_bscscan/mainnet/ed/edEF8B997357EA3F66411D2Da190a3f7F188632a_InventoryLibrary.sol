// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface ILevelManager {
    struct Tier {
        string id;
        uint8 multiplier;
        uint256 lockingPeriod; // in seconds
        uint256 minAmount; // tier is applied when userAmount >= minAmount
        bool random;
        uint8 odds; // divider: 2 = 50%, 4 = 25%, 10 = 10%
        bool vip;
    }

    function isLocked(address account) external view returns (bool);

    function getTierById(string calldata id)
        external
        view
        returns (Tier memory);

    function getUserTier(address account) external view returns (Tier memory);

    function getUserUnlockTime(address account) external view returns (uint256);

    function getTierIds() external view returns (string[] memory);

    function lock(address account, uint256 idoStart) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "../structs.sol";

library InventoryLibrary {
    function getItemIds(Inventory storage self)
    public
    view
    returns (bytes32[] memory)
    {
        InventoryItem[] storage items = self.items;
        bytes32[] memory ids = new bytes32[](items.length);
        for (uint256 i; i < items.length; i++) {
            ids[i] = items[i].id;
        }
        return ids;
    }
    
    function getItem(Inventory storage self, bytes32 tokenId)
    public
    view
    returns (InventoryItem memory)
    {
        require(self.items.length > 0, "InventoryLibrary: Inventory is empty");
        // idx can be 0, when no tokenId found in the mapping
        InventoryItem storage item = self.items[self.index[tokenId]];
        // if ids do not match, tokenId wasn't found/out of bounds
        require(
            item.id == tokenId,
            "InventoryLibrary: Token not found for this ID"
        );
        
        return item;
    }
    
    function totalItemsAmount(Inventory storage self)
    public
    view
    returns (uint256)
    {
        uint256 total;
        for (uint256 i; i < self.items.length; i++) {
            total += self.items[i].supply;
        }
        return total;
    }
    
    function totalItemsSold(Inventory storage self)
    public
    view
    returns (uint256)
    {
        uint256 total;
        for (uint256 i; i < self.items.length; i++) {
            total += self.items[i].sold;
        }
        return total;
    }
    
    // In currency
    function totalPlannedRaise(Inventory storage self)
    public
    view
    returns (uint256)
    {
        uint256 total;
        for (uint256 i; i < self.items.length; i++) {
            InventoryItem memory item = self.items[i];
            total += item.price * item.supply;
        }
        return total;
    }
    
    function totalRaised(Inventory storage self) public view returns (uint256) {
        uint256 total;
        for (uint256 i; i < self.items.length; i++) {
            total += self.items[i].raised;
        }
        return total;
    }
    
    function getPurchaseValue(
        Inventory storage self,
        bytes32 id,
        uint256 amount
    ) public view returns (uint256) {
        InventoryItem memory item = getItem(self, id);
        
        return item.price * amount;
    }
    
    function createOrUpdateInventoryItem(
        Inventory storage self,
        bytes32 id,
        uint256 supply,
        uint256 price,
        uint256 limit
    ) external returns (InventoryItem memory) {
        InventoryItem memory item;
        
        uint256 lastIdx = self.items.length;
        if (lastIdx == 0) {
            item = InventoryItem(id, supply, price, limit, 0, 0);
            self.items.push(item);
            self.index[id] = lastIdx;
            
            return item;
        }
    
        item = self.items[self.index[id]];
        if (item.id == id) {
            item.supply = supply;
            item.price = price;
            item.limit = limit;
        } else {
            // Not found, defaulted to 0 idx
            item = InventoryItem(id, supply, price, limit, 0, 0);
            self.items.push(item);
            self.index[id] = lastIdx;
        }
        
        return item;
    }
    
    function deleteItem(Inventory storage self, bytes32 id)
    external
    returns (bool)
    {
        InventoryItem[] storage items = self.items;
        
        for (uint256 i = 0; i < items.length; i++) {
            if (items[i].id == id) {
                for (uint256 j = i; j < items.length - 1; j++) {
                    items[j] = items[j + 1];
                }
                items.pop();
                
                return true;
            }
        }
        
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "../levels/ILevelManager.sol";
    
    struct Inventory {
    mapping(bytes32 => uint256) index;
    InventoryItem[] items;
}

struct InventoryItem {
    bytes32 id;
    uint256 supply; // integer
    uint256 price; // in wei
    uint256 limit; // in wei
    uint256 sold; // integer
    uint256 raised; // in wei
}

struct LevelsState {
    ILevelManager levelManager;
    bool levelsEnabled; // true
    bool forceLevelsOpenAll;
    bool lockOnRegister; // true
    bool isVip;
    // Sum of weights (lottery losers are subtracted when picking winners) for base allocation calculation
    uint256 totalWeights;
    // Base allocation is 1x in CURRENCY (different to LaunchpadIDO)
    uint256 baseAllocation;
    // 0 - all levels, 6 - starting from "associate", etc
    uint256 minAllowedLevelMultiplier;
    // Min allocation in CURRENCY after registration closes. If 0, then ignored (different to LaunchpadIDO)
    // Needs to be limited to the lowest price in items, if it drops lower than the cheapest item, no purchase can be done
    uint256 minBaseAllocation;
    // Addresses per level
    mapping(string => address[]) levelAddresses;
    // Whether (and how many) winners were picked for a lottery level
    mapping(string => address[]) levelWinners;
    // Needed for user allocation calculation = baseAllocation * userWeight
    // If user lost lottery, his weight resets to 0 - means user can't participate in sale
    mapping(address => uint8) userWeight;
    mapping(address => string) userLevel;
}