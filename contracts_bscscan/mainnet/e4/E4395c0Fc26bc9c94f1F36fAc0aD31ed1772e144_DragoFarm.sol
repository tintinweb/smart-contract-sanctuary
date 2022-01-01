// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IDragoKingdom.sol";
import "./IDragos.sol";
import "./IDrago.sol";
import "./ILifeElixir.sol";

contract DragoFarm is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    //Contract Addresses
    bool public landEnabled;
    address public kingdomsContract;
    address public dragoNFTContract;
    address public DragoContract;
    address public LifeElixirContract;

    //Owner address => KingdomTypeNum => KingdomIDs stacked
    mapping(address => mapping(uint256 => uint256[]))
        public kingdomOwnerByTypeKingdoms;
    //KingdomID => Owner Address
    mapping(uint256 => address) public kingdomOwnerAddress;
    //KingdomID => Slot[] => DragoNFTID
    mapping(uint256 => uint256[3]) public kingdomSlotDrago;
    //KingdomID => Count(*) Dragoland_NFT
    mapping(uint256 => uint256) public kingdomDragoCounter;
    //KingdomTypeNum => BaseReward
    mapping(uint256 => uint256) public kingdomTypeBaseRewards;

    //Owner address => DragoTypeNum => IDs stacked
    mapping(address => mapping(uint256 => uint256[]))
        public dragosOwnerByTypeDragos;
    //DragoNFTID => Owner Address
    mapping(uint256 => address) public dragoNFTOwnerAddress;
    //DragoNFTID => KingdomID
    mapping(uint256 => uint256) public dragoKingdomMap;
    //DragoNFTID Farming init timestamp
    mapping(uint256 => uint256) public dragoFarmingInitTimestamp;
    //DragoNFTID Stack init timestamp
    mapping(uint256 => uint256) public dragoStakingInitTimestamp;
    //DragoTypeNum => BaseReward
    mapping(uint256 => uint256) public dragoNFTTypeBaseRewards;

    //Methods
    function initialize() public initializer {
        __ERC1155_init(
            "https://dragoland.io/NFT/dragoecosystem.json"
        );
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        landEnabled = false;

        //BSCTestValues
        DragoContract = address(0x70D542e94a70081a15a555eCFA1Ba4BFB9217FBb);
        dragoNFTContract = address(0x1dCc869db68030cB56028FcCdfa21B04a487D50F);
        kingdomsContract = address(0x5CE083DD5e105db437A265a294F01488385518ed);
        LifeElixirContract = address(0xB608C633C58457E5Ec5Cd007930c66FA2444A2c7);

        mint(_msgSender(), 0, 1, "");
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
        landEnabled = val;
    }

    function setKingdomsContract(address val) public onlyOwner {
        kingdomsContract = val;
    }

    function setDragoNFTContract(address val) public onlyOwner {
        dragoNFTContract = val;
    }

    function setLifeElixirAddr(address aval) public onlyOwner {
        LifeElixirContract = aval;
    }

    function setDragoAddr(address val) public onlyOwner {
        DragoContract = val;
    }

    function setDragosBaseRewards(
        uint256 fireeggReward,
        uint256 watereggReward,
        uint256 eartheggReward,
        uint256 energyeggReward,
        uint256 darknesseggReward,
        uint256 lighteggReward
    ) public onlyOwner {
    dragoNFTTypeBaseRewards[1] = fireeggReward;
    dragoNFTTypeBaseRewards[2] = watereggReward;
    dragoNFTTypeBaseRewards[3] = eartheggReward;
    dragoNFTTypeBaseRewards[4] = energyeggReward;
    dragoNFTTypeBaseRewards[5] = darknesseggReward;
    dragoNFTTypeBaseRewards[6] = lighteggReward;
    }

    //TEST settters
    function setTimeStamps(
        bool manualDays,
        uint256 dragoNftId,
        uint256 startFarmingAgo,
        uint256 startStakeAgo
    ) public onlyOwner {
        if (manualDays) {
            dragoFarmingInitTimestamp[dragoNftId] = (block.timestamp -
                (startFarmingAgo * 3600 * 24));
            dragoStakingInitTimestamp[dragoNftId] = (block.timestamp -
                (startStakeAgo * 3600 * 24));
        } else {
            dragoFarmingInitTimestamp[dragoNftId] = (block.timestamp -
                startFarmingAgo);
            dragoStakingInitTimestamp[dragoNftId] = (block.timestamp - startStakeAgo);
        }
    }

    function stakeKingdom(
        uint256 kingdomNftID
    ) public {
        address sender = address(msg.sender);
        IDragoKingdom dragoKingdom = IDragoKingdom(kingdomsContract);
        require(
            dragoKingdom.ownerOf(kingdomNftID) == sender,
            "Ownership failed"
        );
        require(
            kingdomOwnerAddress[kingdomNftID] == address(0x000),
            "Already stacked"
        );
        kingdomOwnerAddress[kingdomNftID] = sender;
        kingdomOwnerByTypeKingdoms[sender][dragoKingdom.getTypeIDByNftID(kingdomNftID)].push(kingdomNftID);
        dragoKingdom.transferFrom(sender, address(this), kingdomNftID);
    }

    //NEW: Only stake an dragonftid to a KingdomId in a SlotPosition (0 - 2)
    function stakeDrago(
        uint256 dragoNftId,
        uint256 kingdomId,
        uint256 slot
    ) public {
        address sender = address(msg.sender);
        IDragos dragosInstance = IDragos(dragoNFTContract);
        require(
            dragosInstance.ownerOf(dragoNftId) == sender,
            "You're not the owner of this drago"
        );
        require(
            dragosInstance.isDragoNFTOnSale(dragoNftId) == false,
            "DragoNFT is on sale"
        );
        require(
            dragoNFTOwnerAddress[dragoNftId] == address(0x000),
            "DragoNFT already Stacked"
        );
        IDragoKingdom aBuildInstance = IDragoKingdom(kingdomsContract);
        require(
            kingdomOwnerAddress[kingdomId] == sender,
            "Kingdom isn't staked"
        );
        require(kingdomDragoCounter[kingdomId] < 4, "Kingdom is full");
        require(
            dragosInstance.getTypeIdByNftId(dragoNftId) ==
                aBuildInstance.getTypeIDByNftID(kingdomId),
            "DragoNFT on kingdom error"
        );
        require(slot < 3, "Invalid slot");
        dragoNFTOwnerAddress[dragoNftId] = sender;
        kingdomDragoCounter[kingdomId]++;
        dragoKingdomMap[dragoNftId] = kingdomId;
        kingdomSlotDrago[kingdomId][slot] = dragoNftId;
        dragoFarmingInitTimestamp[dragoNftId] = block.timestamp;
        dragoStakingInitTimestamp[dragoNftId] = block.timestamp;
        dragosInstance.transferFrom(sender, address(this), dragoNftId);
    }

    //NEW: Only un-stake an dragonftid to a KingdomId in a SlotPosition (0 - 2) (Claim called)
    function unstackDrago(
        uint256 dragoNftId,
        uint256 kingdomNftId,
        uint256 slot
    ) public {
        claim(dragoNftId, kingdomNftId);
        address sender = address(msg.sender);
        IDragos dragosInstance = IDragos(dragoNFTContract);
        require(
            dragoNFTOwnerAddress[dragoNftId] == sender,
            "DRAGO not staked or owner failed"
        );
        require(
            dragoKingdomMap[dragoNftId] == kingdomNftId,
            "DRAGO on Kingdom error"
        );
        require(slot < 3, "Invalid slot");
        dragoNFTOwnerAddress[dragoNftId] = address(0x000);
        kingdomDragoCounter[kingdomNftId]--;
        dragoKingdomMap[dragoNftId] = 0;
        kingdomSlotDrago[kingdomNftId][slot] = 0;
        dragosInstance.setDeltaStack(
            dragoNftId,
            block.timestamp - dragoStakingInitTimestamp[dragoNftId]
        );
        dragoStakingInitTimestamp[dragoNftId] = 0;

        dragoFarmingInitTimestamp[dragoNftId] = 0;
        dragosInstance.transferFrom(address(this), sender, dragoNftId);
    }

    //NEW: Claim rewards from an dragonftid stack in a KingdomId
    function claim(uint256 dragoNftId, uint256 kingdomId)
        public
    {
        IDrago aGoldInstance = IDrago(DragoContract);

        require(dragoNFTOwnerAddress[dragoNftId] == _msgSender() || dragoNFTOwnerAddress[dragoNftId] == address(this), "DragoNFT owner failed");
        require(dragoKingdomMap[dragoNftId] == kingdomId, "DragoNFT isnt stacked");
        require(
            dragoFarmingInitTimestamp[dragoNftId] != 0,
            "Nothing to claim, timestamp 0"
        );
        uint256 rewards = currentFarmAccumulatorByDrago(dragoNftId);
        dragoFarmingInitTimestamp[dragoNftId] = block.timestamp;
        if (rewards > 0) {
            aGoldInstance.transfer(_msgSender(), rewards);
        }
    }
    //NEW: Claim all rewards from a KingdomId
    function claimKingdomRewards(
        uint256 kingdomId,
        uint256 dragonftid1,
        uint256 dragonftid2,
        uint256 dragonftid3
    ) public {
        require(dragonftid1 + dragonftid2 + dragonftid3 > 0, "Nothing to claim");
        if (dragonftid1 != 0) 
        {
            claim(dragonftid1, kingdomId);
        }
        if (dragonftid2 != 0)
        {
            claim(dragonftid2, kingdomId);
        }  
        if (dragonftid3 != 0)
        {
            claim(dragonftid3, kingdomId);
        }
    }

    function unStakeKingdom(
        uint256 kingdomNftId
    ) public {
        address sender = address(msg.sender);
        require(kingdomOwnerAddress[kingdomNftId] == sender, "Kingdom owner failed");
        require(kingdomDragoCounter[kingdomNftId] == 0, "Unstack Dragoland_NFT first");
        IDragoKingdom dragoKingdom = IDragoKingdom(kingdomsContract);
        kingdomOwnerAddress[kingdomNftId] = address(0x000);
        kingdomOwnerByTypeKingdoms[sender][dragoKingdom.getTypeIDByNftID(kingdomNftId)].pop();
        dragoKingdom.transferFrom(address(this), sender, kingdomNftId);
    }

    // function getStackedDragosIdsByType(
    //     address owner, uint256 genericType
    // ) public view returns (uint256[] memory)
    // {
    //     return dragosOwnerByTypeDragos[owner][genericType];
    // }

    function getStackedBKingdomsIdsByType(address owner, uint256 genericType)
        public
        view
        returns (uint256[] memory)
    {
        return kingdomOwnerByTypeKingdoms[owner][genericType];
    }

    function currentFarmAccumulatorByDrago(uint256 dragonftid)
        public
        view
        returns (uint256)
    {
        address owner = dragoNFTOwnerAddress[dragonftid];
        uint256 currentTimestamp = block.timestamp;
        IDragos dragosInstance = IDragos(dragoNFTContract);
        uint256 genericType = dragosInstance.getTypeIdByNftId(dragonftid);
        uint256 totalRewards = 0;
        if (kingdomOwnerByTypeKingdoms[owner][genericType].length <= 0) {
            totalRewards = 0;
        } else {
            uint256 changeRewardsDate = 1637067600;
            if (dragoFarmingInitTimestamp[dragonftid] < changeRewardsDate) {
              uint256 dragoOldDelta = changeRewardsDate -
                dragoFarmingInitTimestamp[dragonftid];
              uint256 dragoNewDelta = currentTimestamp -
                changeRewardsDate;
              totalRewards += (dragoNewDelta * dragoNFTTypeBaseRewards[genericType]) +
                (dragoOldDelta * dragoNFTTypeBaseRewards[genericType] * 2);
            } else {
              uint256 dragoDelta = currentTimestamp -
                dragoFarmingInitTimestamp[dragonftid];
              totalRewards += dragoDelta * dragoNFTTypeBaseRewards[genericType];
            }
        }
        // adjust rewards
        totalRewards = totalRewards / 86400;

        return totalRewards;
    }

    function evolve(
        uint256 nftID,
        string memory newURI
    ) public {
        ILifeElixir Dragoland_LifeElixir = ILifeElixir(LifeElixirContract);
        require(
            Dragoland_LifeElixir.balanceOf(address(msg.sender)) >= 1,
            "Dragoland_LifeElixir failed"
        );
        require(
            Dragoland_LifeElixir.allowance(address(msg.sender), address(this)) >= 1,
            "allowance failed"
        );
        IDragos dragoInstance = IDragos(dragoNFTContract);
        require(
            address(msg.sender) == dragoInstance.ownerOf(nftID),
            "ownership failed"
        );
        uint256 currLevel = dragoInstance.getLevel(nftID);
        require(
            currLevel != 0,
            "MysteryEgg can't use a Life Elixir, please evolve it first using Dragon Breath."
        );

        if (address(msg.sender) != this.owner()) {
            require(
                dragoInstance.deltaStack(nftID) >= 43200,
                "Please stake your Drago Egg for at least 12 hours first."
            );
        }

        if (currLevel == 1) {
            Dragoland_LifeElixir.transferFrom(
                address(msg.sender),
                address(LifeElixirContract),
                1
            );
            dragoInstance.setLevel(nftID, 2);
            dragoInstance.setDeltaStack(nftID, 0);
            dragoInstance.setURI(nftID,newURI);
        }
        if (currLevel == 2) {
            Dragoland_LifeElixir.transferFrom(
                address(msg.sender),
                address(LifeElixirContract),
                1
            );
            dragoInstance.setLevel(nftID, 3);
            dragoInstance.setDeltaStack(nftID, 0);
            dragoInstance.setURI(nftID,newURI);
        }
    }

    function adminUnstackDrago(
        uint256 dragoNftId,
        uint256 kingdomNftId,
        uint256 slot
    ) public onlyOwner {
        require(slot < 3, "Invalid slot");
        dragoNFTOwnerAddress[dragoNftId] = address(0x000);
        kingdomDragoCounter[kingdomNftId]--;
        dragoKingdomMap[dragoNftId] = 0;
        kingdomSlotDrago[kingdomNftId][slot] = 0;
        dragoStakingInitTimestamp[dragoNftId] = 0;
        dragoFarmingInitTimestamp[dragoNftId] = 0;
    }
}