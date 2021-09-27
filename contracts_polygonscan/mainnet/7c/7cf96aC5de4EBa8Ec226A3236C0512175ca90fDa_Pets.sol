// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

contract Pets {
    // private globals 
    // can be viewed using getGameInfo
    // can be set my contractOwner using updateGameInfo
    bool canCreteInitialPets;
    address contractOwner;
    address tokenAddress;
    uint256 petId;
    uint256 creationFee = 100000000000000000; // 0.1 MATIC;
    uint256 NOT_FEED_DEATH_BLOCKS = 28800; // ~8 hours on MATIC
    uint256 NOT_SLEEP_DEATH_BLOCKS = 43200; // ~ 12 hours on MATIC
    uint256 NOT_PLAY_DEATH_BLOCKS = 172800; // ~ 48 hours on MATIC;
    uint256 SELL_PET_FEE_PERCENTAGE = 5;
    uint256 NON_OWNER_REWARD_MULTIPLER = 2;
    uint256 FEED_REWARD = 5;
    uint256 SLEEP_REWARD = 5;
    uint256 PLAY_REWARD = 5;
    uint256 BUY_REWARD = 200;
    uint256 SELL_REWARD = 150;
    uint256 CREATE_PET_REWARD = 50;
    uint256 ACCOUNT_CREATED_REWARD = 100;
    uint256 ACCOUNT_UPDATED_REWARD = 1000;

    // storage model
    struct PetStruct {
        bool isPublic;
        bool isForSale;
        uint256 salePrice;
        address owner;
        string name;
        uint256 lastFeed;
        uint256 lastSleep;
        uint256 lastPlay;
        uint256 born;
        string image;
    }
    
    // storage model
    struct AccountStruct {
        address account;
        bool isAdmin;
        uint256 accountCreated;
        string name;
        string email;
        uint256 petsPurchased;
        uint256 petsSold;
        uint256 maticFromSales;
        uint256 maticOnPurchases;
        uint256 tokensEarned;
        uint256 petsCreated;
        uint256[] myPetIds;
    }
    
    // view model calculated at time of get request
    // values between 0-10000; lower is bad as risk of death
    struct PetHealth {
        uint256 hunger; // low need to feed
        uint256 bordem; // low need to play
        uint256 energy; // low need to sleep
        bool alive;
    }
    
    // view model
    struct Pet {
        uint256 id;
        uint256 age;
        PetStruct info;
        PetHealth health;
    }
    
    // view model
    struct GameInfoStruct {
        address administationAddress;
        address tokenAddress;
        uint256 creationFee;
        uint256 feedBy;
        uint256 sleepBy;
        uint256 playBy;
        uint256 sellPecentFee;
        uint256 nonPetOwnerRewardMultipler;
        uint256 feedReward;
        uint256 sleepReward;
        uint256 playReward;
        uint256 buyReward;
        uint256 sellReward;
        uint256 createPetReward;
        uint256 accountCreatedReward;
    }
    
    mapping (uint256 => PetStruct) pets;
    mapping (address => uint256[]) petIds;
    mapping (address => AccountStruct) accounts;
    mapping (address => bool) accountUpdated;
    
    constructor(address tknAddress)
    {
        contractOwner = msg.sender;
        tokenAddress = tknAddress;
        canCreteInitialPets = true;
    }
    
    // *************************************************PAYABLE*************************************************
    function buyPet(uint256 id) public payable {
        require(pets[id].isForSale, "Pet is not for sale!");
        require(msg.value == pets[id].salePrice, "Must send the sale price for this pet!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        address seller = pets[id].owner;
        // check and registerd account
        registerAccountIfNecessary();
        
        uint256 fee = (pets[id].salePrice / 100) * SELL_PET_FEE_PERCENTAGE;
        payable(contractOwner).transfer(fee);
        payable(pets[id].owner).transfer(msg.value - fee);
        
        // update account details for seller
        accounts[pets[id].owner].petsSold++;
        accounts[pets[id].owner].maticFromSales = accounts[pets[id].owner].maticFromSales + msg.value - fee;
        
        // transer pet to new owner
        pets[id].owner = msg.sender;
        pets[id].isForSale = false;
        pets[id].salePrice = 0;
        pets[id].lastFeed = block.number;
        pets[id].lastSleep = block.number;
        pets[id].lastPlay = block.number;
        
        // update account details for buyer
        accounts[msg.sender].petsPurchased++;
        accounts[msg.sender].maticOnPurchases = accounts[msg.sender].maticOnPurchases + msg.value;
        
        // clean up the pets ids
        accounts[msg.sender].myPetIds.push(id);
        for(uint256 i = 0; i < accounts[seller].myPetIds.length; i++) {
            if(accounts[seller].myPetIds[i] == id) {
                delete accounts[seller].myPetIds[i];
            }
        }
        
        // reward both parties
        rewardForSale(seller);
    }
    function createPet(bool _isPublic, string memory _name, string memory _image) public payable {
        require(msg.value == creationFee, "Must pay creation fee!");
        petId++;
        pets[petId] = newPetStruct(_isPublic, _name, _image);
        petIds[msg.sender].push(petId);
        payable(contractOwner).transfer(msg.value);
    }
    // *************************************************PAYABLE*************************************************
    
    
    
    // *************************************************FREE*************************************************
    function accountRegistered() public view returns(bool) {
        return accounts[msg.sender].account != address(0);
    }
    
    function getAccount() public view returns(AccountStruct memory) {
        return accounts[msg.sender];
    }
    
    function getAccount(address me) public view returns(AccountStruct memory) {
        return accounts[me];
    }
    
    function getGameInfo() public view returns(GameInfoStruct memory) {
        GameInfoStruct memory gameInfo = GameInfoStruct(
            {
                administationAddress: contractOwner,
                tokenAddress: tokenAddress,
                creationFee: creationFee,
                feedBy: NOT_FEED_DEATH_BLOCKS,
                sleepBy: NOT_SLEEP_DEATH_BLOCKS,
                playBy: NOT_PLAY_DEATH_BLOCKS,
                sellPecentFee: SELL_PET_FEE_PERCENTAGE,
                nonPetOwnerRewardMultipler: NON_OWNER_REWARD_MULTIPLER,
                feedReward: FEED_REWARD,
                sleepReward: SLEEP_REWARD,
                playReward: PLAY_REWARD,
                buyReward: BUY_REWARD,
                sellReward: SELL_REWARD,
                createPetReward: CREATE_PET_REWARD,
                accountCreatedReward: ACCOUNT_CREATED_REWARD
            }
        );
        return gameInfo;
    }
    function getAllPets() public view returns(Pet[] memory) {
        Pet[] memory _pets = new Pet[](petId);
        for (uint256 i = 1; i < petId + 1; i++) {
            PetHealth memory _health = getPetHealth(i);
            uint256 diedAtBlock;
            if(!_health.alive) {
                diedAtBlock = min(pets[i].lastSleep + NOT_FEED_DEATH_BLOCKS, pets[i].lastPlay + NOT_PLAY_DEATH_BLOCKS);
                diedAtBlock = min(diedAtBlock, pets[i].lastFeed + NOT_FEED_DEATH_BLOCKS);
            }
            _pets[i - 1] = Pet({
                id: i,
                age: _health.alive ? block.number - pets[i].born : diedAtBlock - pets[i].born,
                info: pets[i],
                health: _health
            });
        }
        return _pets;
    }
    // *************************************************FREE*************************************************
    
    
    // *************************************************GAS*************************************************
    function createInitalPets() public onlyBy(contractOwner) {
        require(canCreteInitialPets, "Can only create inital pets 1 time!");
        accounts[msg.sender] = newAccount();
        // why can't we initalize in one line WTF SOLIDITY
        string[] memory names = new string[](25);
        names[0] = "Floki";
        names[1] = "Floppy Ears"; 
        names[2] = "Tommy Tutle";
        names[3] = "Sassy Shiba";
        names[4] = "Jo Jo";
        names[5] = "Neo";
        names[6] = "Freddy";
        names[7] = "Oscar"; 
        names[8] = "Defido";
        names[9] = "Coco";
        names[10] = "Lucy"; 
        names[11] = "Gunner"; 
        names[12] = "Buddy"; 
        names[13] = "Rocky"; 
        names[14] = "Toby"; 
        names[15] = "Loki"; 
        names[16] = "King"; 
        names[17] = "Thor"; 
        names[18] = "Blue"; 
        names[19] = "Bandit"; 
        names[20] = "Bear"; 
        names[21] = "Max"; 
        names[22] = "Teddy"; 
        names[23] = "Milo"; 
        names[24] = "Hux";
        petId = 0;
        for(uint256 i = 1; i < 26; i++) {
            petId++;
            pets[petId] = newPetStruct(true, "", "");
            petIds[msg.sender].push(petId);  
            pets[petId].name = names[petId - 1];
            if(petId > 9) {
                pets[petId].isForSale = true;
                pets[petId].salePrice = (creationFee * 333) / 100 ;
            }
            accounts[msg.sender].myPetIds.push(petId);
            accounts[msg.sender].petsCreated++;
            rewardTokens(msg.sender, CREATE_PET_REWARD);
        }
        
        canCreteInitialPets = false;
    }
    
    
    function allowPublicCare(uint256 id) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender, "Must be pet owner to allow public care of this pet!");
        require(pets[id].isPublic == false, "Your pet is already set to public!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        pets[id].isPublic = true;
    }
    
    function revokePublicCare(uint256 id) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender, "Must be pet owner to allow public care of this pet!");
        require(pets[id].isPublic == true, "Your pet is already set to private!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        pets[id].isPublic = false;
    }
    
    function allowSale(uint256 id, uint256 salePrice) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender, "Must be pet owner to allow sale of this pet!");
        require(pets[id].isForSale == false, "Your pet is already set for sale!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        pets[id].isForSale = true;
        pets[id].salePrice = salePrice;
    }
    
    function revokeSale(uint256 id) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender, "Must be pet owner to revoke sale of this pet!");
        require(pets[id].isForSale == true, "Your pet is already not set for sale!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        pets[id].isForSale = false;
        pets[id].salePrice = 0;
    }
    
    function updateImage(uint256 id, string memory _image) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender, "Must be pet owner to update the photo!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        registerAccountIfNecessary();
        pets[id].image = _image;
    }
    
    function feed(uint256 id) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender || pets[id].isPublic, "Must be pet owner to feed this pet!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        registerAccountIfNecessary();
        pets[id].lastFeed = block.number;
        rewardForCare(id, FEED_REWARD);
    }
    
    function sleep(uint256 id) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender || pets[id].isPublic, "Must be pet owner to put this pet to sleep!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        registerAccountIfNecessary();
        pets[id].lastSleep = block.number;
        rewardForCare(id, SLEEP_REWARD);
    }
    
    function play(uint256 id) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender || pets[id].isPublic, "Must be pet owner to play with this pet!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        registerAccountIfNecessary();
        pets[id].lastPlay = block.number;
        rewardForCare(id, PLAY_REWARD);
    }
    
    function updateAccount(string memory name, string memory email) public {
        accounts[msg.sender].name = name;
        accounts[msg.sender].email = email;
        if(!accountUpdated[msg.sender]) {
            accountUpdated[msg.sender] = true;
            rewardTokens(msg.sender, ACCOUNT_UPDATED_REWARD);
        }
    }
    
    function updateGameInfo(GameInfoStruct memory info) public onlyBy(contractOwner) {
        // contractOwner = info.administationAddress;
        // tokenAddress = info.tokenAddress;
        creationFee = info.creationFee;
        NOT_FEED_DEATH_BLOCKS = info.feedBy;
        NOT_SLEEP_DEATH_BLOCKS = info.sleepBy;
        NOT_PLAY_DEATH_BLOCKS = info.playBy;
        SELL_PET_FEE_PERCENTAGE = info.sellPecentFee;
        NON_OWNER_REWARD_MULTIPLER = info.nonPetOwnerRewardMultipler;
        FEED_REWARD = info.feedReward;
        SLEEP_REWARD = info.sleepReward;
        PLAY_REWARD = info.playReward;
        BUY_REWARD = info.buyReward;
        SELL_REWARD = info.sellReward;
        CREATE_PET_REWARD = info.createPetReward;
        ACCOUNT_CREATED_REWARD = info.accountCreatedReward;
    }
    
    function careForAllMyPets() public onlyBy(contractOwner) {
        for(uint256 i = 0; i < petIds[contractOwner].length; i++) {
           uint256 id = petIds[contractOwner][i];
           if(getPetHealth(id).alive) {
                pets[id].lastFeed = block.number;
                rewardForCare(id, FEED_REWARD);
                pets[id].lastSleep = block.number;
                rewardForCare(id, SLEEP_REWARD);
                pets[id].lastPlay = block.number;
                rewardForCare(id, PLAY_REWARD);
           }
        }
    }
    
    function careForAllPets() public onlyBy(contractOwner) {
       for (uint256 i = 1; i < petId + 1; i++) {
           if(getPetHealth(i).alive) {
                pets[i].lastFeed = block.number;
                rewardForCare(i, FEED_REWARD);
                pets[i].lastSleep = block.number;
                rewardForCare(i, SLEEP_REWARD);
                pets[i].lastPlay = block.number;
                rewardForCare(i, PLAY_REWARD);
           }
        }
    }
    
    // allow sending all tokens back to contractOwner mainly used to avoid reminting during testing
    function recoverToken() public onlyBy(contractOwner) {
        IERC20 tokens = IERC20(tokenAddress);
        tokens.transfer(contractOwner, tokens.balanceOf(address(this)));
    }
    // *************************************************GAS*************************************************
    
    // *************************************************PRIVATE OR INTERNAL*************************************************
    function registerAccountIfNecessary() private {
        if(!accountRegistered()) {
            accounts[msg.sender] = newAccount();
            IERC20 tokens = IERC20(tokenAddress);
            tokens.transfer(msg.sender, ACCOUNT_CREATED_REWARD * 1e18);
        }
    }
    
    function rewardForSale(address seller) private {
        rewardTokens(msg.sender, BUY_REWARD);
        rewardTokens(seller, SELL_REWARD);
    }
    
    function rewardForCare(uint256 id, uint256 baseReward) private {
        uint256 earn = pets[id].owner == msg.sender ? baseReward : baseReward * NON_OWNER_REWARD_MULTIPLER;
        rewardTokens(msg.sender, earn);
    }
    
    function rewardTokens(address to, uint256 amount) private {
        accounts[msg.sender].tokensEarned = accounts[msg.sender].tokensEarned + amount;
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transfer(to, amount * 1e18);
    }
    
    function getPetHealth(uint256 id) private view returns(PetHealth memory) {
        uint256 blocksSinceFeed = pets[id].lastFeed + NOT_FEED_DEATH_BLOCKS < block.number ? 0 :  block.number - pets[id].lastFeed;
        uint256 blocksSincePlay = pets[id].lastPlay + NOT_PLAY_DEATH_BLOCKS < block.number ? 0 :  block.number - pets[id].lastPlay;
        uint256 blocksSinceSleep = pets[id].lastSleep + NOT_SLEEP_DEATH_BLOCKS < block.number ? 0 :  block.number - pets[id].lastSleep;
        bool _alive = blocksSinceFeed > 0 && blocksSincePlay > 0 && blocksSinceSleep > 0;
        
        PetHealth memory health = PetHealth(
            {
                hunger: _alive ? ((NOT_FEED_DEATH_BLOCKS - blocksSinceFeed) * 10000) / NOT_FEED_DEATH_BLOCKS : 0,
                bordem: _alive ? ((NOT_PLAY_DEATH_BLOCKS - blocksSincePlay) * 10000) / NOT_PLAY_DEATH_BLOCKS : 0,
                energy: _alive ? ((NOT_SLEEP_DEATH_BLOCKS - blocksSinceSleep) * 10000) / NOT_SLEEP_DEATH_BLOCKS : 0,
                alive: _alive
            }
        );
        
        return health;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function newAccount() private view returns (AccountStruct memory) {
        AccountStruct memory account = AccountStruct(
            {
                account: msg.sender,
                isAdmin: contractOwner == msg.sender,
                accountCreated: block.number,
                name: '',
                email: '',
                petsSold: 0,
                petsPurchased: 0,
                maticFromSales: 0,
                maticOnPurchases: 0,
                tokensEarned: 0,
                petsCreated: 0,
                myPetIds: new uint256[](0)
            }
        );
        return account;
    }
    
    function newPetStruct(bool _isPublic, string memory _name, string memory _image) private view returns (PetStruct memory) {
        PetStruct memory pet = PetStruct(
            {
                isPublic:_isPublic,
                isForSale: false,
                salePrice: 0,
                name: _name,
                owner: msg.sender,
                lastFeed: block.number,
                lastSleep: block.number,
                lastPlay: block.number,
                born: block.number,
                image: _image
            }
        );
        return pet;
    }
    
     modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }
    
    // *************************************************PRIVATE OR INTERNAL*************************************************
}