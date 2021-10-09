// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./TokenInterface.sol";
import "./VRFConsumerBase.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Base64Utils.sol";
import "./DateTime.sol";
contract Cryptogotchi_v3 is ERC721Enumerable, VRFConsumerBase, Ownable {
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
        uint256 dayPasses;
        uint256 prestige;
        uint256 rewards;
        uint256 tokensToRevive;
        uint256 packChoice;
        uint256 pet;
    }
    
    struct Pack {
        string[3] promo_metadata;
        string[27] batch_metadata;
        bool promoLive;
        bool batchLive;
    }
    
    function setLiveState(bool isPromo, bool position, uint256 _pack) public onlyOwner {
        Pack storage pack = packs[_pack];
        isPromo ? pack.promoLive = position : pack.batchLive = position;
    }
    
    mapping(uint256 => Device) internal unit;
    mapping(address=>bool) internal minters;
    mapping(uint256 => Pack) internal packs;
    
    enum DeviceState { Unsold, Egg, Alive, Dead }
    
    // address internal tokenAddress = 0xA8E9bcC828FADe96d757c8323846DAb9F8D987c8; // this is testnet QSM 0xA8E.7c8
    address internal tokenAddress = 0xA8E9bcC828FADe96d757c8323846DAb9F8D987c8;
    uint256 internal reward = 1 * 10**18;
    
    uint256[5] internal typeRarity = [40, 70, 85, 95, 100]; // [5thRarest, 4thRarest, 3rdRarest, 2ndRarest 1stRarest]
    uint256[5] internal petRarity = [5, 15, 30, 60, 100]; // [1stRarest, 2ndRarest, 3rdRarest, 4thRarest, 5thRarest]
    string[6] internal svgData;
    
    bool public mintEnabled;
    bool public hatchingEnabled;
    
    uint256 internal nftPrice = 3630 * 10**18;
    uint256 internal passPrice = 50 * 10**18;

    uint256 internal ONE_DAY = 86400;
    uint256 internal ONE_HOUR = 3600;
    uint256 internal MAX_TIME = 2**256 - 1;
    
    Counters.Counter private _tokenIds;
    
    event Minted(uint256 newTokenId, address owner, uint256 mintType);
    event Claim(address owner, uint256 tokenId, uint256 dayPasses, uint256 packChoice, uint256 petChoice);
    event InitialHatch(uint256 tokenId, uint256 createdAt, address tokenOwner, uint256 packChoice, uint256 pet, uint256 petType, uint256 petColor);
    event Hatched(uint256 tokenId, uint256 createdAt, address tokenOwner, uint256 packChoice, uint256 pet);
    event Feed(uint256 tokenId, uint256 feedLevel);
    event Play(uint256 tokenId, uint256 newGenerationTick, uint256 rewardAmount);
    event Prestige(uint256 newPrestige, uint256 tokenId);
    event PassPurchased(uint256 tokenId, uint256 passLength);
    event PassRedeemed(uint256 tokenId, uint256 redeemLength);
    event RewardDistributed(address owner, uint256 amount);
    event Revive(uint256 tokenId);
    
    // chainlink
    address public VRFCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;
    address public LinkToken = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 internal keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    uint256 internal vrfFee = 100000000000000000; // .01
    event RandomNumberRequest(bytes32 requestId, uint256 tokenId);
    mapping(bytes32 => uint256) internal requestToToken; // this was set to public

    constructor(
        // address _VRFCoordinator,
        // address _LinkToken,
        // bytes32 _keyhash
        // address _tokenAddress
        )
        // VRFConsumerBase(_VRFCoordinator,_LinkToken)
        VRFConsumerBase(VRFCoordinator,LinkToken)
        ERC721("Cryptogotchi Testnet", "PETv3") 
    {
        
        // VRFCoordinator = _VRFCoordinator;
        // LinkToken = _LinkToken;
        // keyHash = _keyhash;
        // vrfFee = 100000000000000000; 
        // tokenAddress = _tokenAddress;
    }
    
    modifier onlyMinter() {
        require(minters[msg.sender]);
        _;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _tokenIds.current().add(1050);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        Device memory device = unit[tokenId];
        Pack memory promo_pack = packs[device.pet];
        Pack memory group_pack = packs[device.packChoice];
        
        // uint256 fullCycles = uint256(block.timestamp.sub(device.createdAt)).div(ONE_DAY);
        // uint256 reward_ = ((device.generation.sub(1)).mul(reward)).mul(device.prestige.add(1)).add(reward);
        
        string memory output = string(abi.encodePacked(
            svgData[0], // id
            Utils.toString(tokenId), 
            svgData[1], //name
            device.name,
            svgData[2], // generation
            Utils.toString(device.generation),
            svgData[3], // prestige
            Utils.toString(device.prestige)
        ));
        
        output = string(abi.encodePacked(
            output,
            svgData[4], // day passes
            Utils.toString(device.dayPasses),
            svgData[5], // owner
            Utils.toAsciiString(ownerOf(tokenId))
        ));
        
        if (device.packChoice == 0 && device.pet > 0) {
            if (growthStage(tokenId) == DeviceState.Egg) {
                output = string(abi.encodePacked(output, promo_pack.promo_metadata[0]));
            } else if (growthStage(tokenId) == DeviceState.Alive) {
                output = string(abi.encodePacked(output, promo_pack.promo_metadata[2]));
            } else {
                output = string(abi.encodePacked(output, promo_pack.promo_metadata[1]));
            }
        } else {
            if (growthStage(tokenId) == DeviceState.Egg) {
                output = string(abi.encodePacked(output, group_pack.batch_metadata[0]));
            } else if (growthStage(tokenId) == DeviceState.Alive) {
                output = string(abi.encodePacked(output, group_pack.batch_metadata[device.pet]));
            } else {
                output = string(abi.encodePacked(output, group_pack.batch_metadata[1]));
            }
        }
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Crypogotchi Genesis Egg #', Utils.toString(tokenId), '", "description": "A Cryptogotchi is a living interactive NFT that yeilds Quantifiable Spacetime Meed (QSM) tokens as a reward when properly taken care of.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
       // find growth stage for feeding, dead or alive
    function growthStage(uint256 tokenId) public view returns (DeviceState) {
        Device memory device = unit[tokenId];
        
        if (device.createdAt == 0) return DeviceState.Unsold;
        if (device.createdAt == MAX_TIME) return DeviceState.Egg;
        
        uint256 elapsed = block.timestamp.sub(device.createdAt);
        uint256 fullCycles = uint256(elapsed).div(ONE_DAY);
        uint256 modulo = elapsed.mod(ONE_DAY);

        if (device.feedLevel > fullCycles) return DeviceState.Alive;

        if (device.feedLevel == fullCycles && modulo < ONE_HOUR.mul(device.generation))  {
            return DeviceState.Alive;
        }

        return DeviceState.Dead;
    }
    
    // @dev This sets SVG for either a single promo pet or a new pack batch of 25
    // both must include 1 egg SVG at 0 and 1 dead SVG at 1 for pack or promo
    // @param group Next pack, skip 0
    // @param item Spot in the pack (promo length = 3, batch length = 27 (0 = egg, 1 = dead, 3 = pet(s))
    /* @notice When setting a random pet, there are 2 rarity levels. First levels rarest is in position 5 
        and second levels rarest starts at 1. So, example: (level1 = less rare, rarest1 = more rare) 
          petRarity = [1stRarest, 2ndRarest, 3rdRarest, 4thRarest, 5thRarest]    
          typeRarity = [5thRarest, 4thRarest, 3rdRarest, 2ndRarest 1stRarest]   */
    // @param isBatch Either true for batch or false for promo
    function setPackItem(string memory SVG, uint256 group, uint256 item, bool isBatch) public onlyOwner {
        Pack storage pack = packs[group];
        isBatch ? pack.batch_metadata[item] = SVG : pack.promo_metadata[item] = SVG;
    }
    
    function setSvgData(string memory _data, uint256 position) public onlyOwner {
        svgData[position] = _data;
    }
    
     // true=mint false=hatch
    function enable(bool choice) public onlyOwner {
        choice ? mintEnabled = true : hatchingEnabled = true;
    }
    
    // change pass price
    // function setPassPrice(uint256 price) public onlyOwner {
    //     passPrice = price;
    // }
    
    // withdraw any matic
    function withdraw() public onlyOwner {
        // uint256 amount = TokenInterface(_tokenAddress).balanceOf(address(this));
        payable(msg.sender).transfer(address(this).balance);
        // TokenInterface(_tokenAddress).transferFrom(address(this), payable(msg.sender), amount);
    }
    
    // minter can batch mint, claim and add passes
    function changeMinter(address account, bool position) public onlyOwner {
        position ? minters[account] = true : minters[account] = false;
    }
    
     // add day passess to a device
    function addPasses(uint256 tokenId, uint256 amount) public onlyMinter {
        Device storage device = unit[tokenId];
        device.dayPasses = device.dayPasses.add(amount); 
    }
    
    /*
    mint/claim types:
    1,0 group loaded
    0,1 promo loaded
    */
     // batch minter with custom pass amount, pack and pet and day passes
    function batchMint(address[] memory recipients, uint256 _dayPasses, uint256 _packChoice, uint256 _petChoice) public onlyMinter {
        if (_packChoice == 0) require(_petChoice > 0);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _tokenIds.increment();
            uint256 id = _tokenIds.current().add(1050);
        
            
            unit[id] = Device({
                name: "",
                createdAt: MAX_TIME, 
                feedLevel: 0, 
                lastPlayTime: MAX_TIME,
                generation: 0,
                generationTicker: 0,
                dayPasses: _dayPasses,
                prestige: 0,
                rewards: 0,
                tokensToRevive: 0,
                packChoice: _packChoice,
                pet: _petChoice
            });
        
            _safeMint(recipients[i], id);
            
            emit Minted(id, msg.sender, 0);
        }
    }
    
    function claim(address recipient, uint256 tokenId, uint256 _dayPasses, uint256 _packChoice, uint256 _petChoice) public onlyMinter {
        require(hatchingEnabled, "!h");
        require(mintEnabled, "!m");
        uint256 id;
        if (_packChoice == 0 && _petChoice == 1 || _petChoice == 2 || _petChoice == 3) {
            id = tokenId;
        } else {
            _tokenIds.increment();
            id = _tokenIds.current().add(1050);
        }
        unit[id] = Device({
            name: "",
            createdAt: MAX_TIME, 
            feedLevel: 0, 
            lastPlayTime: MAX_TIME,
            generation: 0,
            generationTicker: 0,
            dayPasses: _dayPasses,
            prestige: 0,
            rewards: 0,
            tokensToRevive: 0,
            packChoice: _packChoice,
            pet: _petChoice
        });
    
        _safeMint(recipient, id);
        
        emit Claim(recipient, id, _dayPasses, _packChoice, _petChoice);
    }
    
    // function migrate() public {
        
    // }
    
    // mint nft with tokens
    function purchaseNFT(uint256 packNumber) public {
        Pack memory pack = packs[packNumber];
        require(mintEnabled, "!m");
        require(pack.batchLive, "!p");
        require(TokenInterface(tokenAddress).allowance(msg.sender, address(this)) >= nftPrice, "!a");
        require(TokenInterface(tokenAddress).balanceOf(msg.sender) >= nftPrice, "!b");
        
        TokenInterface(tokenAddress).burn(msg.sender, nftPrice);
        
        _tokenIds.increment();
        uint256 id = _tokenIds.current().add(1050); // 1000 eggs, 50 premints
        
        unit[id] = Device({
            name: "",
            createdAt: MAX_TIME, 
            feedLevel: 0, 
            lastPlayTime: MAX_TIME,
            generation: 0,
            generationTicker: 0,
            dayPasses: 0,
            prestige: 0,
            rewards: 0,
            tokensToRevive: 0,
            packChoice: packNumber,
            pet: 0
        });
        
        _safeMint(msg.sender, id);
        
        emit Minted(id, msg.sender, 2);
    }
    
    function setName(uint256 tokenId, string memory newName) public {
        bytes memory b = bytes(newName);
        require(b.length < 17, "!n");
        require(hatchingEnabled, "!h");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        
        Device storage device = unit[tokenId];
        
        device.name = newName;
    }
    
    // hatch device from egg
    function hatch(uint256 tokenId) public {
        require(hatchingEnabled, "!h");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        
        Device storage device = unit[tokenId];
        
        require(device.createdAt == MAX_TIME, "!e");

        if (device.pet > 0) {
            
            // stops reentrancy
            device.createdAt = block.timestamp;
            device.lastPlayTime = block.timestamp;
            device.generation = 1;
            
            emit Hatched(tokenId, block.timestamp, ownerOf(tokenId), device.packChoice, device.pet);
            return;
        }
        
         // stops reentrancy
        device.createdAt = block.timestamp;
        device.lastPlayTime = block.timestamp;
        
        getRandomColor(tokenId);
    }
    
    function getRandomColor(uint256 tokenId) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= vrfFee, "!L");
        
        requestId = requestRandomness(keyHash, vrfFee);
        // set uint256 tokenId in bytes32 mapping
        requestToToken[requestId] = tokenId;
        
        emit RandomNumberRequest(requestId, tokenId);
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // get uint256 tokenId from bytes32 mapping
        uint256 tokenId = requestToToken[requestId];
        
        Device storage device = unit[tokenId];
        uint256 petType = selectPet(randomness.mod(100).add(1), typeRarity); // 1-100
        uint256 randomness2 = uint256(keccak256(abi.encodePacked(randomness, ownerOf(tokenId))));  //2nd random number
        uint256 petColor = selectPet(randomness2.mod(100).add(1), petRarity); // 1-100
         
        device.pet = (petType.add(1)).mul(5) .sub(petColor).add(1);
        device.generation = 1;
      
        emit InitialHatch(tokenId, device.createdAt, ownerOf(tokenId), device.packChoice, device.pet, petType, petColor);
    }

     function selectPet(uint256 randomNumber, uint256[5] memory _data) internal pure returns (uint256 position) {
        for (uint256 i = 0; i < 5; i++) {
            if (randomNumber <= _data[i]) {
                return i;
            }
        }
    }
    
    // check if alive
    function alive(uint256 tokenId) public view returns (bool) {
        return growthStage(tokenId) != DeviceState.Dead;
    }

        // get all token id's by address
    function getOwnersTokenIds(address account) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(account);
        uint256[] memory tokenIds = new uint256[](balance);
        
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(account, i);
        }
        return tokenIds;
    }
    
    // feed 1, play 2, prestige 3, rewards 4
    function getTokensReadyToBatch(uint256 batchType, address account) internal view returns(uint256[] memory, bool hasBatch) {
        uint256[] memory ownersTokens = getOwnersTokenIds(account);
        uint256[] memory batchArray = new uint256[](ownersTokens.length);
        uint256 count = 0;
        for (uint256 i = 0; i < ownersTokens.length; i++) {
            Device memory device = unit[ownersTokens[i]];
            if (batchType == 1) { // feed
                if (uint256(block.timestamp.sub(device.createdAt)).div(ONE_DAY) == device.feedLevel && alive(ownersTokens[i])) {
                    batchArray[i] = ownersTokens[i];
                    count++;
                } else {
                    batchArray[i] = 0;
                }
            }
            if (batchType == 2) { // play
                if (device.feedLevel != uint256(block.timestamp.sub(device.createdAt)).div(ONE_DAY) && device.generation <= 10 && device.generation > 0 && block.timestamp.sub(device.lastPlayTime) > ONE_HOUR.add(device.prestige.mul(ONE_HOUR)) && alive(ownersTokens[i])) {
                    batchArray[i] = ownersTokens[i];
                    count++;
                } else {
                    batchArray[i] = 0;
                }
            }
            if (batchType == 3) { // prestige
                if (device.rewards == 0 && device.generation == 11 && device.feedLevel > uint256(block.timestamp.sub(device.createdAt)).div(ONE_DAY) && alive(ownersTokens[i])) {
                    batchArray[i] = ownersTokens[i];
                    count++;
                } else {
                    batchArray[i] = 0;
                }
            }
            if (batchType == 4) { // rewards
                if (device.rewards > 0) {
                    batchArray[i] = ownersTokens[i];
                    count++;
                } else {
                    batchArray[i] = 0;
                }
            }
        }
        if (count > 0) {
            return (batchArray, true);
            
        } else {
            return (batchArray, false);
        }
    }
    
    function returnReadyTokens(uint256 batchType, address account) public view returns(uint256[] memory, bool hasBatch) {
        return getTokensReadyToBatch(batchType, account);
    }
    
    // feed to keep alive
    function feed(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(alive(tokenId), "!x");
        
        Device storage device = unit[tokenId];
        
        uint256 elapsed = block.timestamp.sub(device.createdAt);
        uint256 fullCycles = uint256(elapsed).div(ONE_DAY);
        
        require(device.feedLevel == fullCycles, "!f");
        
        device.feedLevel = device.feedLevel.add(1);
        
        emit Feed(tokenId, device.feedLevel);
    }
    
    function batchFeed() public {
        (uint256[] memory batchArray, bool hasBatch) = returnReadyTokens(1, msg.sender);
        require(hasBatch, "nb");
        // uint256[] memory ownersTokens = returnReadyTokens(1);
        for (uint i = 0; i < batchArray.length; i++) {
            if (batchArray[i] != 0) {
               feed(batchArray[i]);
            }
        }
        return;
    }

    // play to earn tokens, increase generation
    function play(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(alive(tokenId), "!x");
        
        Device storage device = unit[tokenId];
        
        uint256 timeBetweenPlays = ONE_HOUR.add(device.prestige.mul(ONE_HOUR));
        uint256 elapsed = block.timestamp.sub(device.lastPlayTime);
        uint256 fullCycles = uint256(block.timestamp.sub(device.createdAt)).div(ONE_DAY);
        
        require(device.feedLevel != fullCycles, "!f");
        require(device.generation <= 10 && device.generation > 0, "!g");
        require(elapsed > timeBetweenPlays, "!t");
        
        //changing this first stops reentrancy
        device.lastPlayTime = block.timestamp;
        device.generationTicker = device.generationTicker.add(1);
        generationUp(tokenId);
    }

    function batchPlay() public {
        (uint256[] memory batchArray, bool hasBatch) = returnReadyTokens(2, msg.sender);
        require(hasBatch, "nb");
        for (uint i = 0; i < batchArray.length; i++) {
            if (batchArray[i] != 0) {
                play(batchArray[i]);
            }
        }
    }
    
    // increase generation to prestige
    function generationUp(uint256 tokenId) internal {
        Device storage device = unit[tokenId];
        
        uint256 amount = ((device.generation.sub(1)).mul(reward)).mul(device.prestige.add(1)).add(reward);
        
        // must have met required play amount
        if (device.generationTicker == device.generation) {
        // if (device.generationTicker == device.generation) {
            if (device.generation == 10) {
                //changing this first stops reentrancy
                device.generation = device.generation.add(1);
                device.tokensToRevive = device.tokensToRevive.add(amount);
                device.rewards = device.rewards.add(amount);
                // pendingRewards = pendingRewards.add(amount);
                
                emit Play(tokenId, device.generation, amount);
                return;
            } 
            if (device.generation < 10) {
                for (uint i = 0; i < 10; i++) {
                    if (device.generation.sub(1) == i) {
                        //changing this first stops reentrancy
                        device.generationTicker = 0;
                        device.tokensToRevive = device.tokensToRevive.add(amount);
                        device.rewards = device.rewards.add(amount);
                        // pendingRewards = pendingRewards.add(amount);
                        device.generation = device.generation.add(1);
                        
                        emit Play(tokenId, device.generation, amount);
                        return;
                    }
                }
            }
        }
        
        emit Play(tokenId, device.generation, 0);
    }
    
    // prestige to restart generation
    function prestige(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(alive(tokenId), "!a");
        
        Device storage device = unit[tokenId];
        
        uint256 elapsed = block.timestamp.sub(device.createdAt);
        uint256 fullCycles = uint256(elapsed).div(ONE_DAY);
        
        require(device.rewards == 0, "r0");
        require(device.generation == 11, "!11");
        require(device.feedLevel > fullCycles, "!f");
   
        // does this stop reentrancy?
        device.generation = 1;
        device.generationTicker = 0;
        device.lastPlayTime = block.timestamp;
        device.tokensToRevive = 0;
        device.dayPasses = device.dayPasses.add(device.prestige);
        device.prestige = device.prestige.add(1);
        
        emit Prestige(device.prestige, tokenId);
    }
    
    function batchPrestige() public {
        (uint256[] memory batchArray, bool hasBatch) = returnReadyTokens(3, msg.sender);
        require(hasBatch, "nb");
        for (uint i = 0; i < batchArray.length; i++) {
            if (batchArray[i] != 0) {
                prestige(batchArray[i]);
            }
        }
    }
    
    // withdraw pending rewards
    function getReward(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        
        Device storage device = unit[tokenId];
        
        require(device.rewards > 0, "!r");
     
        uint256 tempAmount;
        uint256 amount;
        //  ** MAYBE PROBLEM WITH RE-ENTRENY HERE***
        tempAmount = device.rewards;
        device.rewards = 0;
        amount = tempAmount;
        
        TokenInterface(tokenAddress).mint(msg.sender, amount);
        
        emit RewardDistributed(msg.sender, amount);
    }
    
    function batchGetReward() public {
        (uint256[] memory batchArray, bool hasBatch) = returnReadyTokens(4, msg.sender);
        require(hasBatch, "nb");
        for (uint i = 0; i < batchArray.length; i++) {
            if (batchArray[i] != 0) {
                getReward(batchArray[i]);
            }
        }
    }
    
    // purchase day pass
    function purchasePass(uint256 tokenId, uint256 amount) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(TokenInterface(tokenAddress).allowance(msg.sender, address(this)) >= amount.mul(passPrice), "!a");
        require(TokenInterface(tokenAddress).balanceOf(msg.sender) >= amount.mul(passPrice), "!b");
        require(amount > 0,"a0");
        
        uint256 calculatedPrice = passPrice.mul(amount);
        
        TokenInterface(tokenAddress).burn(msg.sender, calculatedPrice);
        
        Device storage device = unit[tokenId];
        
        device.dayPasses = device.dayPasses.add(amount);
        
        emit PassPurchased(tokenId, amount);
    }
    
    // redeem day pass
    function redeemPass(uint256 tokenId, uint256 amount) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(alive(tokenId), "!a");
        
        Device storage device = unit[tokenId];
        
        require(device.createdAt != MAX_TIME, "ie");
        require(amount <= device.dayPasses, "!d");
        require(amount > 0, "az");
        require(device.pet > 1, '!c');
        
        device.dayPasses = device.dayPasses.sub(amount);
        device.feedLevel = device.feedLevel.add(amount);
        
        emit PassRedeemed(tokenId, amount);
    }
    
    // revive device excluding prestige and color
    function revival(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!o");
        require(!alive(tokenId), "x!");
        
        Device storage device = unit[tokenId];
        
        require(TokenInterface(tokenAddress).allowance(msg.sender, address(this)) >= device.tokensToRevive, "!a");
        require(TokenInterface(tokenAddress).balanceOf(msg.sender) >= device.tokensToRevive, "!b");
        require(device.pet > 0, '!c'); // dead ipfs is now metatada[1] or 1
        // require devicestate = dead
        require(device.createdAt != MAX_TIME, "ie");
        require(device.rewards == 0, "r0");
        
        if (device.tokensToRevive != 0) TokenInterface(tokenAddress).burn(msg.sender, device.tokensToRevive);

        device.createdAt = MAX_TIME;
        device.lastPlayTime = MAX_TIME;
        device.feedLevel = 0;
        device.generation = 0;
        device.generationTicker = 0;
        device.tokensToRevive = 0;

        emit Revive(tokenId);
    }
    
    function Unit(uint256 tokenId) public view returns (
        string memory name_, uint256 createdAt_, uint256 feedLevel_, uint256 generation_,
        uint256 generationTicker_, uint256 lastPlayTime_, uint256 dayPasses_, uint256 prestige_,
        uint256 rewards_, uint256 tokensToRevive_, uint256 packChoice_, uint256 pet_) {
            
        Device memory device = unit[tokenId];
        
        return (
            device.name, device.createdAt, device.feedLevel, device.generation,
            device.generationTicker, device.lastPlayTime, device.dayPasses, device.prestige,
            device.rewards, device.tokensToRevive, device.packChoice, device.pet
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64Utils.sol";

library DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }
        
        function stringMonth(uint timestamp) public pure returns (string memory) {
            uint256 time = parseTimestamp(timestamp).month;
            if (time < 10) {
                return string(abi.encodePacked("0", Utils.toString(time)));
            }
            return Utils.toString(time);
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }
        
        function stringDay(uint timestamp) public pure returns (string memory) {
            uint256 time = parseTimestamp(timestamp).day;
            if (time < 10) {
                return string(abi.encodePacked("0", Utils.toString(time)));
            }
            return Utils.toString(time);
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }
        
        function stringHour(uint timestamp) public pure returns (string memory) {
            uint256 time = (timestamp / 60 / 60) % 24;
            if (time < 10) {
                return string(abi.encodePacked("0", Utils.toString(time)));
            }
            return Utils.toString(time);
        }
        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function stringMinute(uint timestamp) public pure returns (string memory) {
            uint256 time = (timestamp / 60) % 60;
            if (time < 10) {
                return string(abi.encodePacked("0", Utils.toString(time)));
            }
            return Utils.toString(time);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

library Utils {
    
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface TokenInterface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    
    // function getMonth(uint timestamp) external pure returns (uint8);
    // function getDay(uint timestamp) external pure returns (uint8);
    // function getYear(uint timestamp) external pure returns (uint8);
    // function getHour(uint timestamp) external pure returns (uint8);
    // function getMinute(uint timestamp) external pure returns (uint8);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/* ERROR MESSAGESS FROM REQUIREMENTS
        !a = not apporved
        !b = insufficiant erc20 token balance
        !d = amount greater than available days
        !e = not egg
        !h = hatching not enabled
        !L = not enough Link in contract
        !m = mint not enabled
        !n = name must be <= 16 characters
        !o = not the owner of nft
        !p = pack not enabled
        !r = rewards not greater than 0
        !t = still time between plays
        !x = not alive
        x! = alive
        !10 = not generation 10
        az = pass amount not greater than 0
        g1 = is generation 1
        ie - is egg
        mf = must feed before prestige
        mp = must prestige to continue
        NB = no pets to batch
        r0 = rewards greater than 0
    */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface LinkTokenInterface {
    function allowance(address owner, address spender ) external view returns ( uint256 remaining );
    function approve( address spender, uint256 value ) external returns ( bool success );
    function balanceOf( address owner ) external view returns ( uint256 balance );
    function decimals() external view returns ( uint8 decimalPlaces );
    function decreaseApproval( address spender, uint256 addedValue ) external returns ( bool success );
    function increaseApproval( address spender,uint256 subtractedValue) external;
    function name() external view returns (string memory tokenName );
    function symbol() external view returns ( string memory tokenSymbol );
    function totalSupply() external view returns ( uint256 totalTokensIssued );
    function transfer( address to, uint256 value ) external returns ( bool success );
    function transferAndCall( address to, uint256 value, bytes calldata data ) external returns ( bool success );
    function transferFrom( address from, address to, uint256 value ) external returns ( bool success );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}