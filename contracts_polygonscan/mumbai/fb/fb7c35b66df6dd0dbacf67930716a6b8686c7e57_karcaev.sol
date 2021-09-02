// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Data2.sol";
import "./TokenInterface.sol";
import "./VRFConsumerBase.sol";
import "./ERC721PresetMinterPauserAutoId.sol";
import "./SafeMath.sol";


contract karcaev is ERC721PresetMinterPauserAutoId, VRFConsumerBase, Data  {
    using SafeMath for uint256;
    using Strings for string;
    using Counters for Counters.Counter;

    struct Device {
        string name;
        uint256 createdAt;
        uint256 feedLevel;
        uint256 generation;
        uint256 generationTicker;
        uint256 lastPlayTime;
        uint256 availableFreeDays;
        uint256 prestige;
        uint256 rewards;
        uint256 revivals;
        uint256 tokensToRevive;
        uint256 frogColor;
    }
    
    mapping(uint256 => Device) public unit;
    
    enum DeviceGeneration {
        Unsold,Egg,
        Gen1,Gen2,Gen3,Gen4,Gen5,
        Gen6,Gen7,Gen8,Gen9,Gen10,
        Dead
    }
    
    bool internal mintEnabled;
    bool internal hatchingEnabled;
    
    uint256 internal paidRewards;
    uint256 internal pendingRewards;

    address public tokenAddress = 0x3a199fD90eAEB4631F01BE2E92F286aB2B4A69F9;
    
    uint256 internal reward = 1 * 10**18;
    uint256 internal passPrice = 100 * 10**18;
    uint256 internal nftPrice = 1570 * 10**18;

    uint256 internal ONE_DAY = 86400;
    uint256 internal ONE_HOUR = 60; //10min
    uint256 internal HALF_HOUR = 30; //5min
    uint256 internal MAX_TIMESTAMP = 2**256 - 1;
    
    Counters.Counter private _tokenIds;

    event Minted(uint256 NewTokenId, address owner, uint256 mintType);
    event InitialHatch(uint256 tokenId, uint256 createdAt, address tokenOwner, uint256 frogColor, uint256 randomness);
    event Hatched(uint256 tokenId, uint256 createdAt, address tokenOwner, uint256 frogColor);
    event Feed(uint256 tokenId, uint256 feedLevel);
    event Play(uint256 tokenId, uint256 newGenerationTick, uint256 rewardAmount);
    event Prestige(uint256 newPrestige, uint256 tokenId);
    // event GenerationUp(uint256 tokenId, uint256 newLevel, uint256 rewardAmount);
    event PassPurchased(uint256 tokenId, uint256 passLength);
    event PassRedeemed(uint256 tokenId, uint256 redeemLength);
    event DayPassAddedToDevice(uint256 tokenId, uint256 amount);
    event RewardDistributed(address owner, uint256 amount);
    event Revive(uint256 tokenId);
    // event Dead(uint256 tokenId);
    
    mapping(bytes32 => string) private nameIPFS;
    
    //chainlink
    // address public VRFCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;
    address public VRFCoordinator = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;
    // address public LinkToken = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address public LinkToken = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // bytes32 internal keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    bytes32 internal keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    // uint256 internal vrfFee = 100000000000000000;
    uint256 internal vrfFee = 100000000000000; // .0001
    event RequestedRandomness(bytes32 requestId, uint256 tokenId);
    mapping(bytes32 => uint256) public requestToToken;
    //

    constructor(
        // address _VRFCoordinator,
        // address _LinkToken,
        // bytes32 _keyhash,
        // address _tokenAddress
        )
        VRFConsumerBase(VRFCoordinator, LinkToken)
        ERC721PresetMinterPauserAutoId("Cjtac", "ahd", "ipfs://") 
    {
        // VRFCoordinator = _VRFCoordinator;
        // LinkToken = _LinkToken;
        // keyHash = _keyhash;
        // vrfFee = 100000000000000000; 
        // tokenAddress = _tokenAddress;
    }
    
    function set_IPFS_with_new_data() public onlyOwner {
        for (uint256 index = 0; index < nameList.length; index++) {
            nameIPFS[keccak256(abi.encode(nameList[index]))] = nameIPFSConstant[index];
        }
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        Device memory device = unit[tokenId];
        string memory name = device.name;
        string memory name_IPFS = nameIPFS[keccak256(abi.encode(name))];
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Egg) {
            return string(abi.encodePacked(_baseURI(), EGG_IPFS));
        }
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Gen1) {
            return string(abi.encodePacked(_baseURI(), name_IPFS ));
        }
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Gen2) {
            return string(abi.encodePacked(_baseURI(), name_IPFS));
        }
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Gen3) {
            return string(abi.encodePacked(_baseURI(), name_IPFS));
        }
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Gen4) {
            return string(abi.encodePacked(_baseURI(), name_IPFS));
        }
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Gen5) {
            return string(abi.encodePacked(_baseURI(), name_IPFS));
        }
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Gen6) {
            return string(abi.encodePacked(_baseURI(), name_IPFS));
        }
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Gen7) {
            return string(abi.encodePacked(_baseURI(), name_IPFS));
        }
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Gen8) {
            return string(abi.encodePacked(_baseURI(), name_IPFS));
        }
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Gen9) {
            return string(abi.encodePacked(_baseURI(), name_IPFS));
        }
        if (deviceGrowthStage(tokenId) == DeviceGeneration.Gen10) {
            return string(abi.encodePacked(_baseURI(), name_IPFS));
        }
        return string(abi.encodePacked(_baseURI(), DEAD_IPFS));
    }

    // true=mint false=hatch
    function enable(bool choice) public onlyOwner {
        choice ? mintEnabled = true : hatchingEnabled = true;
    }
    
     //add day passess to a device, onlyOwner
    function addPasses(uint256 tokenId, uint256 amount) public onlyOwner {
        Device storage device = unit[tokenId];
        
        device.availableFreeDays = device.availableFreeDays.add(amount); 
        
        emit DayPassAddedToDevice(tokenId, amount);
        return;
    }
    
    function setPassPrice(uint256 price) public onlyOwner {
        passPrice = price;
    }
    
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }
    
    // withdraw any matic
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // onlyowner batch minter
    function ownerMint(address[] memory recipients, uint256 _availableFreeDays, uint256 _frogColor) public onlyOwner {
        uint256 i = 0;
        while (i <= recipients.length.sub(1)) {
            uint256 id;
            if (!mintEnabled) {
                id = 0;
            } else {
                _tokenIds.increment();
                id = _tokenIds.current();
            }
        
            unit[id] = Device({
                name: egg, 
                createdAt: MAX_TIMESTAMP, 
                feedLevel: 1, 
                lastPlayTime: MAX_TIMESTAMP,
                generation: 0,
                generationTicker: 0,
                availableFreeDays: _availableFreeDays,
                prestige: 0,
                rewards: 0,
                revivals: 0,
                tokensToRevive: 0,
                frogColor: _frogColor
            });
        
            _safeMint(recipients[i], id);
            
            i++;
            
            emit Minted(id, msg.sender, 0);
        }
        return;
    }
    
    // mint nft with tokens
    function purchaseNFT() public {
        require(mintEnabled, "!m");
        require(TokenInterface(tokenAddress).allowance(msg.sender, address(this)) >= nftPrice, "!a");
        require(TokenInterface(tokenAddress).balanceOf(msg.sender) >= nftPrice, "!b");
        
        TokenInterface(tokenAddress).burn(msg.sender, nftPrice);
        
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        
        unit[id] = Device({
            name: egg, 
            createdAt: MAX_TIMESTAMP, 
            feedLevel: 1, 
            lastPlayTime: MAX_TIMESTAMP,
            generation: 0,
            generationTicker: 0,
            availableFreeDays: 0,
            prestige: 0,
            rewards: 0,
            revivals: 0,
            tokensToRevive: 0,
            frogColor: 0
        });
        
        _safeMint(msg.sender, id);
        
        emit Minted(id, msg.sender, 1);
        return;
    }
    
    // hatch device from egg
    function hatch(uint256 tokenId) public {
        require(hatchingEnabled, "!h");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        
        Device storage device = unit[tokenId];
        
        require(device.createdAt == MAX_TIMESTAMP, "!e");

        if (device.frogColor > 0) {
            
            // stops reentrancy
            device.createdAt = block.timestamp;
            device.lastPlayTime = block.timestamp;
            
            if (device.frogColor == 1) {
            device.name = nameList[0];
            }
            if (device.frogColor == 2) {
            device.name = nameList[10];
            }
            if (device.frogColor == 3) {
            device.name = nameList[20];
            }
            if (device.frogColor == 4) {
            device.name = nameList[30];
            }
            if (device.frogColor == 5) {
            device.name = nameList[40];
            }
            
            emit Hatched(tokenId, block.timestamp, ownerOf(tokenId), device.frogColor);
            return;
        }
        
         // stops reentrancy
        device.createdAt = block.timestamp;
        device.lastPlayTime = block.timestamp;
        
        getRandomColor(tokenId);
    }
    
    function getRandomColor(uint256 tokenId) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= vrfFee, "!L");
        
        // requestRandomness(keyHash, vrfFee);
        requestId = requestRandomness(keyHash, vrfFee);
        
        // set uint256 tokenId in bytes32 mapping
        requestToToken[requestId] = tokenId;
        
        emit RequestedRandomness(requestId, tokenId);
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // get uint256 tokenId from bytes32 mapping
        uint256 tokenId = requestToToken[requestId];
        
        Device storage device = unit[tokenId];
        
        uint256 color = randomness.mod(100).add(1);
        
        // 5%yellow,10%blue,15%orange,30%green,40%Purple
        if (color >= 1 && color <= 40) {
        device.name = nameList[0];
        device.frogColor = 1;
        }
        if (color >= 41 && color <= 70) {
        device.name = nameList[10];
        device.frogColor = 2;
        }
        if (color >= 71 && color <= 85) {
        device.name = nameList[20];
        device.frogColor = 3;
        }
        if (color >= 86 && color <= 95) {
        device.name = nameList[30];
        device.frogColor = 4;
        }
        if (color >= 96 && color <= 100) {
        device.name = nameList[40];
        device.frogColor = 5;
        }
        
        emit InitialHatch(tokenId, device.createdAt, ownerOf(tokenId), device.frogColor, randomness);
        return;
    }
    
    // check if alive
    function alive(uint256 tokenId) public view returns (bool) {
        return deviceGrowthStage(tokenId) != DeviceGeneration.Dead;
    }
    
    // find growth stage for feeding, dead or alive
    function deviceGrowthStage(uint256 tokenId) public view returns (DeviceGeneration) {
        Device memory device = unit[tokenId];
        
        if (device.createdAt == 0) return DeviceGeneration.Unsold;
        if (device.createdAt == MAX_TIMESTAMP) return DeviceGeneration.Egg;
        
        uint256 elapsed = block.timestamp.sub(device.createdAt);
        uint256 fullCycles = uint256(elapsed).div(ONE_DAY);
        uint256 modulo = elapsed.mod(ONE_DAY);

        if (device.feedLevel > fullCycles) {
            return findGeneration(device.generation);
        }

        if (device.feedLevel == fullCycles && modulo < ONE_HOUR.add((ONE_HOUR.mul(device.generation))))  {
            return findGeneration(device.generation);
        }

        return DeviceGeneration.Dead;
    }
    
    // find generation for tokenURI
    function findGeneration(uint256 _generationLevel) internal pure returns (DeviceGeneration generationLevel_){
        
        if (_generationLevel == 0 ) {
            return DeviceGeneration.Gen1;
        }
        if (_generationLevel == 1 ) {
            return DeviceGeneration.Gen2;
        }
        if (_generationLevel == 2 ) {
            return DeviceGeneration.Gen3;
        }
        if (_generationLevel == 3 ) {
            return DeviceGeneration.Gen4;
        }
        if (_generationLevel == 4 ) {
            return DeviceGeneration.Gen5;
        }
        if (_generationLevel == 5 ) {
            return DeviceGeneration.Gen6;
        }
        if (_generationLevel == 6 ) {
            return DeviceGeneration.Gen7;
        }
        if (_generationLevel == 7 ) {
            return DeviceGeneration.Gen8;
        }
        if (_generationLevel == 8 ) {
            return DeviceGeneration.Gen9;
        }
        if (_generationLevel >= 9 ) {
            return DeviceGeneration.Gen10;
        }
    }

    // feed to keep alive
    function feed(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(alive(tokenId), "!x");
        
        Device storage device = unit[tokenId];
        
        uint256 elapsed = block.timestamp - device.createdAt;
        uint256 fullCycles = uint256(elapsed).div(ONE_DAY);
        
        require(device.feedLevel == fullCycles, "!feed");
        
        device.feedLevel = device.feedLevel.add(1);
        
        emit Feed(tokenId, device.feedLevel);
        return;
    }

    // play to earn tokens, increase generation
    function play(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(alive(tokenId), "!x");
        
        Device storage device = unit[tokenId];
        
        uint256 timeBetweenPlays;
        
        if (device.prestige == 0) {
            timeBetweenPlays = ONE_HOUR;
        } 
        else if (device.prestige == 1) {
            timeBetweenPlays = ONE_HOUR.mul(2);
        }
        else if (device.prestige == 2) {
            timeBetweenPlays = ONE_HOUR.mul(3);
        }
        else {
            // ONE_HOUR is 30 seconds   
            timeBetweenPlays = ONE_HOUR.add((device.prestige.add(4)).mul(HALF_HOUR));
        }
        uint256 elapsed = block.timestamp.sub(device.lastPlayTime);
        
        require(elapsed > timeBetweenPlays, "!t");
        require(device.generation <= 9, "mp");
        
        //changing this first stops reentrancy
        device.lastPlayTime = block.timestamp;
        
        device.generationTicker = device.generationTicker.add(1);
        
        generationUp(tokenId);

    }

    // increase generation to prestige
    function generationUp(uint256 tokenId) internal {
        Device storage device = unit[tokenId];
        
        uint256 maxPlaysPerGen = device.prestige.add(1); // 2 for testing
        uint256 maxPrestigeForCalc = 16;
        uint256 amount;
        
        // must have met required play amount
        if (device.generationTicker == maxPlaysPerGen) {
        
            // if !prestige 16, calculate reward. Else on prestige 16+, rewards set to 1 indefinitely
            if (device.prestige < maxPrestigeForCalc) {
                amount = (device.generation.mul(reward)).mul((maxPrestigeForCalc.sub(device.prestige))).add(reward);
            } else {
                amount = reward;
            }
        
            if (device.generation == 9) {
                
                //changing this first stops reentrancy
                // add one to generation
                device.generation = device.generation.add(1);
                
                // add to local rewards counters
                device.tokensToRevive = device.tokensToRevive.add(amount);
                device.rewards = device.rewards.add(amount);
                
                // global pending rewards counter
                pendingRewards = pendingRewards.add(amount);
                
                return;
            } 
            if (device.generation < 9) {
                
                for (uint i = 0; i < 9; i++) {
                    
                    if (device.generation == i) {
                        
                        //changing this first stops reentrancy
                        // reset generation ticker
                        device.generationTicker = 0;
                        
                        // update name for tokenURI
                        if (device.frogColor == 1) {
                            device.name = nameList[i.add(1)];
                        }
                        if (device.frogColor == 2) {
                            device.name = nameList[(i.add(10)).add(1)];
                        }
                        if (device.frogColor == 3) {
                            device.name = nameList[(i.add(20)).add(1)];
                        }
                        if (device.frogColor == 4) {
                            device.name = nameList[(i.add(30)).add(1)];
                        }
                        if (device.frogColor == 5) {
                            device.name = nameList[(i.add(40)).add(1)];
                        }
                        
                        // add to local rewards counters
                        device.tokensToRevive = device.tokensToRevive.add(amount);
                        device.rewards = device.rewards.add(amount);
                        
                        // global pending rewards counter
                        pendingRewards = pendingRewards.add(amount);

                        // add one to generation
                        device.generation = device.generation.add(1);
                        
                        emit Play(tokenId, device.generation, amount);
                        return;
                    }
                }
            }
        }
        emit Play(tokenId, device.generation, 0);
        return;
    }
    
    // prestige to restart generation
    function prestige(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(alive(tokenId), "!a");
        
        Device storage device = unit[tokenId];
        
        uint256 elapsed = block.timestamp - device.createdAt;
        uint256 fullCycles = uint256(elapsed).div(ONE_DAY);
        // bytes32 hash = keccak256(bytes(device.name));
        // require(hash != keccak256(bytes(nameList[0])) ||
        //         hash != keccak256(bytes(nameList[10])) ||
        //         hash != keccak256(bytes(nameList[20])) ||
        //         hash != keccak256(bytes(nameList[30])) ||
        //         hash != keccak256(bytes(nameList[40])), "g1");
        require(device.rewards == 0, "r0");
        require(device.generation == 10, "!10");
        require(device.feedLevel > fullCycles, "mf");
   
        // does this stop reentrancy?
        device.generation = 0;
        device.tokensToRevive = 0;
        device.generationTicker = 0;
        device.prestige = device.prestige.add(1);
        device.availableFreeDays = device.availableFreeDays.add(1);
        
        // this was first to stop reentrancy, but i think changing generation does the same
        if (device.frogColor == 1) {
            device.name = nameList[0];
        }
        if (device.frogColor == 2) {
            device.name = nameList[10];
        }
        if (device.frogColor == 3) {
            device.name = nameList[20];
        }
        if (device.frogColor == 4) {
            device.name = nameList[30];
        }
        if (device.frogColor == 5) {
            device.name = nameList[40];
        }
        
        emit Prestige(device.prestige, tokenId);
        return;
    }
    
    // withdraw pending rewards from playing
    function getReward(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        
        Device storage device = unit[tokenId];
        
        require(device.rewards > 0, "!r");
     
        uint256 amount = device.rewards;
        //  ** MAYBE PROBLEM WITH RE-ENTRENY HERE                         ***
        device.rewards = 0;
        pendingRewards = pendingRewards.sub(amount);
        paidRewards = paidRewards.add(amount);
        
        TokenInterface(tokenAddress).mint(msg.sender, amount);
        
        emit RewardDistributed(msg.sender, amount);
        return;
    }
    
    // purchase day pass
    function purchasePass(uint256 tokenId, uint256 amount) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        // require(alive(tokenId), "!alive");
        
        require(TokenInterface(tokenAddress).allowance(msg.sender, address(this)) >= amount.mul(passPrice), "!a");
        require(TokenInterface(tokenAddress).balanceOf(msg.sender) >= amount.mul(passPrice), "!b");
        require(amount > 0,"!amount");
        
        uint256 calculatedPrice = passPrice.mul(amount);
        
        TokenInterface(tokenAddress).burn(msg.sender, calculatedPrice);
        
        Device storage device = unit[tokenId];
        
        device.availableFreeDays = device.availableFreeDays.add(amount);
        
        emit PassPurchased(tokenId, amount);
        return;
    }
    
    // redeem day pass
    function redeemPass(uint256 tokenId, uint256 amount) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(alive(tokenId), "!a");
        
        Device storage device = unit[tokenId];
        require(keccak256(bytes(device.name)) != keccak256(bytes(egg)), "ie");
        require(amount <= device.availableFreeDays, "!d");
        require(amount > 0, "az");
        
        device.availableFreeDays = device.availableFreeDays.sub(amount);
        device.feedLevel = device.feedLevel.add(amount);
        
        emit PassRedeemed(tokenId, amount);
        return;
    }
    
    //  // revive device excluding prestige and color
    function revival(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(!alive(tokenId), "x!");
        
        Device storage device = unit[tokenId];
        
        require(TokenInterface(tokenAddress).allowance(msg.sender, address(this)) >= device.tokensToRevive, "!a");
        require(TokenInterface(tokenAddress).balanceOf(msg.sender) >= device.tokensToRevive, "!b");
        
        require(device.createdAt != MAX_TIMESTAMP);
        require(device.rewards == 0, "r0");
        // require(keccak256(bytes(device.name)) != keccak256(bytes(egg)), "ie");
        
        TokenInterface(tokenAddress).burn(msg.sender, device.tokensToRevive);

        device.createdAt = MAX_TIMESTAMP;
        device.lastPlayTime = MAX_TIMESTAMP;
        device.name = egg;
        device.feedLevel = 1;
        device.generation = 0;
        device.generationTicker = 0;
        device.tokensToRevive = 0;
        device.revivals = device.revivals.add(1);

        emit Revive(tokenId);
        return;
    }

    // get internal data
    function internalData() public view returns(
        uint256 pendingRewards_, uint256 paidRewards_, 
        bool mintEnabled_, bool hatchingEnabled_ 
        ) {
            
        return (
            pendingRewards, paidRewards,
            mintEnabled, hatchingEnabled
        );
    }
    
    function getOwnersTokenIds(address account) public view returns (uint256[] memory) {
        uint256 currentBalance = balanceOf(account);
        uint256[] memory accountsTokens_ = new uint[](currentBalance);
        
        for(uint256 i = 0; i < currentBalance; i++) {
            accountsTokens_[i] = tokenOfOwnerByIndex(account, i);
        }
        return accountsTokens_;
    }
    
    
    function getTimeData(uint256 tokenId) public view returns (
        bool isItPlayTime_, uint256 secondsUntilNextPlay_, uint256 timeBetweenPlays_, uint256 playsPerGeneration_,
        bool isInFeedWindow_, uint256 secondsUntilNextFeed_, uint256 secondsLeftInFeedWindow_ 
        ) {
            
        Device memory device = unit[tokenId];
        
        uint256 elapsed;
        uint256 timeBetweenPlays;
        
        if (device.prestige == 0) {
            timeBetweenPlays = ONE_HOUR;
        } 
        else if (device.prestige == 1) {
            timeBetweenPlays = ONE_HOUR.mul(2);
        }
        else if (device.prestige == 2) {
            timeBetweenPlays = ONE_HOUR.mul(3);
        }
        else {
            // ONE_HOUR is 30 seconds   
            timeBetweenPlays = ONE_HOUR.add((device.prestige.add(4)).mul(HALF_HOUR));
        }
        
        if (device.createdAt != MAX_TIMESTAMP && alive(tokenId)) {
            
            uint256 feedElapsedTime = block.timestamp.sub(device.createdAt);
            uint256 fullCycles = uint256(feedElapsedTime).div(ONE_DAY);
            uint256 modulo = feedElapsedTime.mod(ONE_DAY);
            uint256 feedWindow = ONE_HOUR.add((ONE_HOUR.mul(device.generation)));
            
            // in a play
            if (block.timestamp.sub(device.lastPlayTime) > timeBetweenPlays) {
                elapsed = block.timestamp.sub(device.lastPlayTime);
                // not in a feed
                if (device.feedLevel > fullCycles) {
                    return (true, 0, timeBetweenPlays, device.prestige.add(1),  false, device.feedLevel.mul(ONE_DAY).sub(feedElapsedTime), feedWindow );
                }
                // in feeding window
                if (device.feedLevel == fullCycles && modulo < feedWindow)  {
                    return (true, 0, timeBetweenPlays, device.prestige.add(1), true, 0,  feedWindow.sub(modulo));
                }
            //not in a play
            } else {
                elapsed = block.timestamp.sub(device.lastPlayTime);
                // not in a feed
                if (device.feedLevel > fullCycles) {
                    return (false, timeBetweenPlays.sub(elapsed), timeBetweenPlays, device.prestige.add(1), false, device.feedLevel.mul(ONE_DAY).sub(feedElapsedTime), feedWindow);
                }
                // in feeding window
                if (device.feedLevel == fullCycles && modulo < feedWindow)  {
                    return (false, timeBetweenPlays.sub(elapsed), timeBetweenPlays, device.prestige.add(1), false, 0, feedWindow.sub(modulo));
                }
            }
        }
        return (false, 0, 0, 0, false, 0, 0);
    }
}