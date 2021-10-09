// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

contract Pets {
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

    // values between 0-10000; lower is bad as risk of death
    struct PetHealth {
        uint256 hunger; // low need to feed
        uint256 bordem; // low need to play
        uint256 energy; // low need to sleep
        bool alive;
    }

    struct Pet {
        uint256 id;
        uint256 age;
        PetStruct info;
        PetHealth health;
    }

    struct GameInfoStruct {
        address admin;
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
        uint256 accountUpdatedReward;
    }

    // private globals
    bool private initialized;
    uint256 private petId;
    GameInfoStruct private gameInfo;
    mapping(uint256 => PetStruct) pets;
    mapping(address => uint256[]) petIds;
    mapping(address => AccountStruct) accounts;
    mapping(address => bool) accountUpdated;
    address[] accountAddresses;

    function initalize(address tknAddress) public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        gameInfo = GameInfoStruct({
            admin: msg.sender,
            tokenAddress: tknAddress,
            creationFee: 100000000000000000, // 0.1 MATIC;
            feedBy: 28800, // ~8 hours on MATIC
            sleepBy: 43200, // ~ 12 hours on MATIC
            playBy: 172800, // ~ 48 hours on MATIC;
            sellPecentFee: 5,
            nonPetOwnerRewardMultipler: 2,
            feedReward: 5,
            sleepReward: 5,
            playReward: 5,
            buyReward: 200,
            sellReward: 150,
            createPetReward: 50,
            accountCreatedReward: 100,
            accountUpdatedReward: 1000
        });
        accountAddresses.push(msg.sender);
        accounts[msg.sender] = newAccount();
    }

    // *************************************************PAYABLE*************************************************
    function buyPet(uint256 id) public payable {
        require(pets[id].isForSale, "Pet is not for sale!");
        require(
            msg.value == pets[id].salePrice,
            "Must send the sale price for this pet!"
        );
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        address seller = pets[id].owner;
        // check and registerd account
        registerAccountIfNecessary();

        uint256 fee = (pets[id].salePrice / 100) * gameInfo.sellPecentFee;
        payable(gameInfo.admin).transfer(fee);
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
        accounts[msg.sender].maticOnPurchases =
            accounts[msg.sender].maticOnPurchases +
            msg.value;

        // clean up the pets ids
        accounts[msg.sender].myPetIds.push(id);
        for (uint256 i = 0; i < accounts[seller].myPetIds.length; i++) {
            if (accounts[seller].myPetIds[i] == id) {
                delete accounts[seller].myPetIds[i];
            }
        }

        // reward both parties
        rewardForSale(seller);
    }

    function createPet(bool _isPublic, string memory _name,string memory _image) public payable {
        require(msg.value == gameInfo.creationFee, "Must pay creation fee!");
        petId++;
        pets[petId] = newPetStruct(_isPublic, _name, _image);
        petIds[msg.sender].push(petId);
        payable(gameInfo.admin).transfer(msg.value);
    }

    // *************************************************PAYABLE*************************************************

    // *************************************************FREE*************************************************
    function accountRegistered() public view returns (bool) {
        return accounts[msg.sender].account != address(0);
    }

    function getAccount() public view returns (AccountStruct memory) {
        return accounts[msg.sender];
    }

    function getAccounts() public view onlyBy(gameInfo.admin) returns (AccountStruct[] memory)
    {
        AccountStruct[] memory _accounts = new AccountStruct[](
            accountAddresses.length
        );
        for (uint256 i = 0; i < accountAddresses.length; i++) {
            _accounts[i] = accounts[accountAddresses[i]];
        }
        return _accounts;
    }

    function getGameInfo() public view returns (GameInfoStruct memory) {
        return gameInfo;
    }

    function getAllPets() public view returns (Pet[] memory) {
        Pet[] memory _pets = new Pet[](petId);
        for (uint256 i = 1; i < petId + 1; i++) {
            PetHealth memory _health = getPetHealth(i);
            uint256 diedAtBlock;
            if (!_health.alive) {
                diedAtBlock = min(
                    pets[i].lastSleep + gameInfo.feedBy,
                    pets[i].lastPlay + gameInfo.playBy
                );
                diedAtBlock = min(
                    diedAtBlock,
                    pets[i].lastFeed + gameInfo.feedBy
                );
            }
            _pets[i - 1] = Pet({
                id: i,
                age: _health.alive
                    ? block.number - pets[i].born
                    : diedAtBlock - pets[i].born,
                info: pets[i],
                health: _health
            });
        }
        return _pets;
    }

    // *************************************************FREE*************************************************

    // *************************************************GAS PUBLIC*************************************************
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
        require(pets[id].isForSale == false,"Your pet is already set for sale!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        pets[id].isForSale = true;
        pets[id].salePrice = salePrice;
    }

    function revokeSale(uint256 id) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender, "Must be pet owner to revoke sale of this pet!");
        require(pets[id].isForSale == true,"Your pet is already not set for sale!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        pets[id].isForSale = false;
        pets[id].salePrice = 0;
    }

    function updateImage(uint256 id, string memory _image) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender,"Must be pet owner to update the photo!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        registerAccountIfNecessary();
        pets[id].image = _image;
    }

    function feed(uint256 id) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender || pets[id].isPublic,"Must be pet owner to feed this pet!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        registerAccountIfNecessary();
        pets[id].lastFeed = block.number;
        rewardForCare(id, gameInfo.feedReward);
    }

    function sleep(uint256 id) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender || pets[id].isPublic,"Must be pet owner to put this pet to sleep!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        registerAccountIfNecessary();
        pets[id].lastSleep = block.number;
        rewardForCare(id, gameInfo.sleepReward);
    }

    function play(uint256 id) public {
        require(id > 0, "Valid pet id required");
        require(id <= petId, "Valid pet id required");
        require(pets[id].owner == msg.sender || pets[id].isPublic,"Must be pet owner to play with this pet!");
        require(getPetHealth(id).alive, "Sorry this pet is not alive!");
        registerAccountIfNecessary();
        pets[id].lastPlay = block.number;
        rewardForCare(id, gameInfo.playReward);
    }

    function updateAccount(string memory name, string memory email) public {
        accounts[msg.sender].name = name;
        accounts[msg.sender].email = email;
        if (!accountUpdated[msg.sender]) {
            accountUpdated[msg.sender] = true;
            rewardTokens(msg.sender, gameInfo.accountUpdatedReward);
        }
    }
    // *************************************************GAS PUBLIC*************************************************
    
    // *************************************************GAS PUBLIC ADMIN ONLY*************************************************
        function createSomePets() public onlyBy(gameInfo.admin) {
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
        for (uint256 i = 1; i < 26; i++) {
            petId++;
            pets[petId] = newPetStruct(true, "", "");
            petIds[msg.sender].push(petId);
            pets[petId].name = names[petId - 1];
            if (petId > 9) {
                pets[petId].isForSale = true;
                pets[petId].salePrice = (gameInfo.creationFee * 333) / 100;
            }
            accounts[msg.sender].myPetIds.push(petId);
            accounts[msg.sender].petsCreated++;
            rewardTokens(msg.sender, gameInfo.createPetReward);
        }
    }

    function sendTokensToAdmin() public onlyBy(gameInfo.admin) {
        IERC20 tokenContract = IERC20(gameInfo.tokenAddress);
        tokenContract.transfer(gameInfo.admin, tokenContract.balanceOf(address(this)));
    }

    function updateGameInfo(GameInfoStruct memory info) public onlyBy(gameInfo.admin)
    {
        gameInfo = info;
    }

    function careForAllMyPets() public onlyBy(gameInfo.admin) {
        for (uint256 i = 0; i < petIds[gameInfo.admin].length; i++) {
            uint256 id = petIds[gameInfo.admin][i];
            if (getPetHealth(id).alive) {
                pets[id].lastFeed = block.number;
                rewardForCare(id, gameInfo.feedReward);
                pets[id].lastSleep = block.number;
                rewardForCare(id, gameInfo.sleepReward);
                pets[id].lastPlay = block.number;
                rewardForCare(id, gameInfo.playReward);
            }
        }
    }

    function careForAllPets() public onlyBy(gameInfo.admin) {
        for (uint256 i = 1; i < petId + 1; i++) {
            if (getPetHealth(i).alive) {
                pets[i].lastFeed = block.number;
                rewardForCare(i, gameInfo.feedReward);
                pets[i].lastSleep = block.number;
                rewardForCare(i, gameInfo.sleepReward);
                pets[i].lastPlay = block.number;
                rewardForCare(i, gameInfo.playReward);
            }
        }
    }
    // *************************************************GAS PUBLIC ADMIN ONLY*************************************************


    // *************************************************GAS PRIVATE OR INTERNAL*************************************************
    function registerAccountIfNecessary() private {
        if (!accountRegistered()) {
            accountAddresses.push(msg.sender);
            accounts[msg.sender] = newAccount();
            IERC20 tokens = IERC20(gameInfo.tokenAddress);
            tokens.transfer(msg.sender, gameInfo.accountCreatedReward * 1e18);
        }
    }

    function rewardForSale(address seller) private {
        rewardTokens(msg.sender, gameInfo.buyReward);
        rewardTokens(seller, gameInfo.sleepReward);
    }

    function rewardForCare(uint256 id, uint256 baseReward) private {
        uint256 earn = pets[id].owner == msg.sender ? baseReward : baseReward * gameInfo.nonPetOwnerRewardMultipler;
        rewardTokens(msg.sender, earn);
    }

    function rewardTokens(address to, uint256 amount) private {
        accounts[msg.sender].tokensEarned = accounts[msg.sender].tokensEarned + amount;
        IERC20 tokenContract = IERC20(gameInfo.tokenAddress);
        tokenContract.transfer(to, amount * 1e18);
    }
    // *************************************************GAS PRIVATE OR INTERNAL*************************************************

    // *************************************************FREE PRIVATE OR INTERNAL*************************************************
    function getPetHealth(uint256 id) private view returns (PetHealth memory) {
        uint256 blocksSinceFeed = pets[id].lastFeed + gameInfo.feedBy < block.number ? 0 : block.number + 1 - pets[id].lastFeed;
        uint256 blocksSincePlay = pets[id].lastPlay + gameInfo.playBy < block.number ? 0 : block.number + 1 - pets[id].lastPlay;
        uint256 blocksSinceSleep = pets[id].lastSleep + gameInfo.sleepBy < block.number ? 0 : block.number + 1 - pets[id].lastSleep;
        bool _alive = blocksSinceFeed > 0 && blocksSincePlay > 0 && blocksSinceSleep > 0;

        PetHealth memory health = PetHealth({
            hunger: _alive ? ((gameInfo.feedBy - blocksSinceFeed) * 10000) / gameInfo.feedBy : 0,
            bordem: _alive ? ((gameInfo.playBy - blocksSincePlay) * 10000) /gameInfo.playBy : 0,
            energy: _alive ? ((gameInfo.sleepBy - blocksSinceSleep) * 10000) /gameInfo.sleepBy: 0,
            alive: _alive
        });

        return health;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function newAccount() private view returns (AccountStruct memory) {
        AccountStruct memory account = AccountStruct({
            account: msg.sender,
            isAdmin: gameInfo.admin == msg.sender,
            accountCreated: block.number,
            name: "",
            email: "",
            petsSold: 0,
            petsPurchased: 0,
            maticFromSales: 0,
            maticOnPurchases: 0,
            tokensEarned: 0,
            petsCreated: 0,
            myPetIds: new uint256[](0)
        });
        return account;
    }

    function newPetStruct(bool _isPublic, string memory _name, string memory _image) private view returns (PetStruct memory) {
        PetStruct memory pet = PetStruct({
            isPublic: _isPublic,
            isForSale: false,
            salePrice: 0,
            name: _name,
            owner: msg.sender,
            lastFeed: block.number,
            lastSleep: block.number,
            lastPlay: block.number,
            born: block.number,
            image: _image
        });
        return pet;
    }

    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }

    // *************************************************FREE PRIVATE OR INTERNAL*************************************************
}