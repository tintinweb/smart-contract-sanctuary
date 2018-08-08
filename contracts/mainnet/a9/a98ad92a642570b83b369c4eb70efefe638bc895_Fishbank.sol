pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}








contract Beneficiary is Ownable {

    address public beneficiary;

    function Beneficiary() public {
        beneficiary = msg.sender;
    }

    function setBeneficiary(address _beneficiary) onlyOwner public {
        beneficiary = _beneficiary;
    }


}



contract ChestsStore is Beneficiary {


    struct chestProduct {
        uint256 price; // Price in wei
        bool isLimited; // is limited sale chest
        uint32 limit; // Sell limit
        uint16 boosters; // count of boosters
        uint24 raiseChance;// in 1/10 of percent
        uint24 raiseStrength;// in 1/10 of percent for params or minutes for timebased boosters
        uint8 onlyBoosterType;//If set chest will produce only this type
        uint8 onlyBoosterStrength;
    }


    chestProduct[255] public chestProducts;
    FishbankChests chests;


    function ChestsStore(address _chests) public {
        chests = FishbankChests(_chests);
        //set chests to this address
    }

    function initChestsStore() public onlyOwner {
        // Create basic chests types
        setChestProduct(1, 0, 1, false, 0, 0, 0, 0, 0);
        setChestProduct(2, 15 finney, 3, false, 0, 0, 0, 0, 0);
        setChestProduct(3, 20 finney, 5, false, 0, 0, 0, 0, 0);
    }

    function setChestProduct(uint16 chestId, uint256 price, uint16 boosters, bool isLimited, uint32 limit, uint24 raiseChance, uint24 raiseStrength, uint8 onlyBoosterType, uint8 onlyBoosterStrength) onlyOwner public {
        chestProduct storage newProduct = chestProducts[chestId];
        newProduct.price = price;
        newProduct.boosters = boosters;
        newProduct.isLimited = isLimited;
        newProduct.limit = limit;
        newProduct.raiseChance = raiseChance;
        newProduct.raiseStrength = raiseStrength;
        newProduct.onlyBoosterType = onlyBoosterType;
        newProduct.onlyBoosterStrength = onlyBoosterStrength;
    }

    function setChestPrice(uint16 chestId, uint256 price) onlyOwner public {
        chestProducts[chestId].price = price;
    }

    function buyChest(uint16 _chestId) payable public {
        chestProduct memory tmpChestProduct = chestProducts[_chestId];

        require(tmpChestProduct.price > 0);
        // only chests with price
        require(msg.value >= tmpChestProduct.price);
        //check if enough ether is send
        require(!tmpChestProduct.isLimited || tmpChestProduct.limit > 0);
        //check limits if they exists

        chests.mintChest(msg.sender, tmpChestProduct.boosters, tmpChestProduct.raiseStrength, tmpChestProduct.raiseChance, tmpChestProduct.onlyBoosterType, tmpChestProduct.onlyBoosterStrength);

        if (msg.value > chestProducts[_chestId].price) {//send to much ether send some back
            msg.sender.transfer(msg.value - chestProducts[_chestId].price);
        }

        beneficiary.transfer(chestProducts[_chestId].price);
        //send paid eth to beneficiary

    }


}





contract FishbankBoosters is Ownable {

    struct Booster {
        address owner;
        uint32 duration;
        uint8 boosterType;
        uint24 raiseValue;
        uint8 strength;
        uint32 amount;
    }

    Booster[] public boosters;
    bool public implementsERC721 = true;
    string public name = "Fishbank Boosters";
    string public symbol = "FISHB";
    mapping(uint256 => address) public approved;
    mapping(address => uint256) public balances;
    address public fishbank;
    address public chests;
    address public auction;

    modifier onlyBoosterOwner(uint256 _tokenId) {
        require(boosters[_tokenId].owner == msg.sender);
        _;
    }

    modifier onlyChest() {
        require(chests == msg.sender);
        _;
    }

    function FishbankBoosters() public {
        //nothing yet
    }

    //mints the boosters can only be called by owner. could be a smart contract
    function mintBooster(address _owner, uint32 _duration, uint8 _type, uint8 _strength, uint32 _amount, uint24 _raiseValue) onlyChest public {
        boosters.length ++;

        Booster storage tempBooster = boosters[boosters.length - 1];

        tempBooster.owner = _owner;
        tempBooster.duration = _duration;
        tempBooster.boosterType = _type;
        tempBooster.strength = _strength;
        tempBooster.amount = _amount;
        tempBooster.raiseValue = _raiseValue;

        Transfer(address(0), _owner, boosters.length - 1);
    }

    function setFishbank(address _fishbank) onlyOwner public {
        fishbank = _fishbank;
    }

    function setChests(address _chests) onlyOwner public {
        if (chests != address(0)) {
            revert();
        }
        chests = _chests;
    }

    function setAuction(address _auction) onlyOwner public {
        auction = _auction;
    }

    function getBoosterType(uint256 _tokenId) view public returns (uint8 boosterType) {
        boosterType = boosters[_tokenId].boosterType;
    }

    function getBoosterAmount(uint256 _tokenId) view public returns (uint32 boosterAmount) {
        boosterAmount = boosters[_tokenId].amount;
    }

    function getBoosterDuration(uint256 _tokenId) view public returns (uint32) {
        if (boosters[_tokenId].boosterType == 4 || boosters[_tokenId].boosterType == 2) {
            return boosters[_tokenId].duration + boosters[_tokenId].raiseValue * 60;
        }
        return boosters[_tokenId].duration;
    }

    function getBoosterStrength(uint256 _tokenId) view public returns (uint8 strength) {
        strength = boosters[_tokenId].strength;
    }

    function getBoosterRaiseValue(uint256 _tokenId) view public returns (uint24 raiseValue) {
        raiseValue = boosters[_tokenId].raiseValue;
    }

    //ERC721 functionality
    //could split this to a different contract but doesn&#39;t make it easier to read
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function totalSupply() public view returns (uint256 total) {
        total = boosters.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        balance = balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner){
        owner = boosters[_tokenId].owner;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(boosters[_tokenId].owner == _from);
        //can only transfer if previous owner equals from
        boosters[_tokenId].owner = _to;
        approved[_tokenId] = address(0);
        //reset approved of fish on every transfer
        balances[_from] -= 1;
        //underflow can only happen on 0x
        balances[_to] += 1;
        //overflows only with very very large amounts of fish
        Transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public
    onlyBoosterOwner(_tokenId) //check if msg.sender is the owner of this fish
    returns (bool)
    {
        _transfer(msg.sender, _to, _tokenId);
        //after master modifier invoke internal transfer
        return true;
    }

    function approve(address _to, uint256 _tokenId) public
    onlyBoosterOwner(_tokenId)
    {
        approved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public returns (bool) {
        require(approved[_tokenId] == msg.sender || msg.sender == fishbank || msg.sender == auction);
        //require msg.sender to be approved for this token or to be the fishbank contract
        _transfer(_from, _to, _tokenId);
        //handles event, balances and approval reset
        return true;
    }


    function takeOwnership(uint256 _tokenId) public {
        require(approved[_tokenId] == msg.sender);
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }


}






contract FishbankChests is Ownable {

    struct Chest {
        address owner;
        uint16 boosters;
        uint16 chestType;
        uint24 raiseChance;//Increace chance to catch bigger chest (1 = 1:10000)
        uint8 onlySpecificType;
        uint8 onlySpecificStrength;
        uint24 raiseStrength;
    }

    Chest[] public chests;
    FishbankBoosters public boosterContract;
    mapping(uint256 => address) public approved;
    mapping(address => uint256) public balances;
    mapping(address => bool) public minters;

    modifier onlyChestOwner(uint256 _tokenId) {
        require(chests[_tokenId].owner == msg.sender);
        _;
    }

    modifier onlyMinters() {
        require(minters[msg.sender]);
        _;
    }

    function FishbankChests(address _boosterAddress) public {
        boosterContract = FishbankBoosters(_boosterAddress);
    }

    function addMinter(address _minter) onlyOwner public {
        minters[_minter] = true;
    }

    function removeMinter(address _minter) onlyOwner public {
        minters[_minter] = false;
    }

    //create a chest

    function mintChest(address _owner, uint16 _boosters, uint24 _raiseStrength, uint24 _raiseChance, uint8 _onlySpecificType, uint8 _onlySpecificStrength) onlyMinters public {

        chests.length++;
        chests[chests.length - 1].owner = _owner;
        chests[chests.length - 1].boosters = _boosters;
        chests[chests.length - 1].raiseStrength = _raiseStrength;
        chests[chests.length - 1].raiseChance = _raiseChance;
        chests[chests.length - 1].onlySpecificType = _onlySpecificType;
        chests[chests.length - 1].onlySpecificStrength = _onlySpecificStrength;
        Transfer(address(0), _owner, chests.length - 1);
    }

    function convertChest(uint256 _tokenId) onlyChestOwner(_tokenId) public {

        Chest memory chest = chests[_tokenId];
        uint16 numberOfBoosters = chest.boosters;

        if (chest.onlySpecificType != 0) {//Specific boosters
            if (chest.onlySpecificType == 1 || chest.onlySpecificType == 3) {
                boosterContract.mintBooster(msg.sender, 2 days, chest.onlySpecificType, chest.onlySpecificStrength, chest.boosters, chest.raiseStrength);
            } else if (chest.onlySpecificType == 5) {//Instant attack
                boosterContract.mintBooster(msg.sender, 0, 5, 1, chest.boosters, chest.raiseStrength);
            } else if (chest.onlySpecificType == 2) {//Freeze
                uint32 freezeTime = 7 days;
                if (chest.onlySpecificStrength == 2) {
                    freezeTime = 14 days;
                } else if (chest.onlySpecificStrength == 3) {
                    freezeTime = 30 days;
                }
                boosterContract.mintBooster(msg.sender, freezeTime, 5, chest.onlySpecificType, chest.boosters, chest.raiseStrength);
            } else if (chest.onlySpecificType == 4) {//Watch
                uint32 watchTime = 12 hours;
                if (chest.onlySpecificStrength == 2) {
                    watchTime = 48 hours;
                } else if (chest.onlySpecificStrength == 3) {
                    watchTime = 3 days;
                }
                boosterContract.mintBooster(msg.sender, watchTime, 4, chest.onlySpecificStrength, chest.boosters, chest.raiseStrength);
            }

        } else {//Regular chest

            for (uint8 i = 0; i < numberOfBoosters; i ++) {
                uint24 random = uint16(keccak256(block.coinbase, block.blockhash(block.number - 1), i, chests.length)) % 1000
                - chest.raiseChance;
                //get random 0 - 9999 minus raiseChance

                if (random > 850) {
                    boosterContract.mintBooster(msg.sender, 2 days, 1, 1, 1, chest.raiseStrength); //Small Agility Booster
                } else if (random > 700) {
                    boosterContract.mintBooster(msg.sender, 7 days, 2, 1, 1, chest.raiseStrength); //Small Freezer
                } else if (random > 550) {
                    boosterContract.mintBooster(msg.sender, 2 days, 3, 1, 1, chest.raiseStrength); //Small Power Booster
                } else if (random > 400) {
                    boosterContract.mintBooster(msg.sender, 12 hours, 4, 1, 1, chest.raiseStrength); //Tiny Watch
                } else if (random > 325) {
                    boosterContract.mintBooster(msg.sender, 48 hours, 4, 2, 1, chest.raiseStrength); //Small Watch
                } else if (random > 250) {
                    boosterContract.mintBooster(msg.sender, 2 days, 1, 2, 1, chest.raiseStrength); //Mid Agility Booster
                } else if (random > 175) {
                    boosterContract.mintBooster(msg.sender, 14 days, 2, 2, 1, chest.raiseStrength); //Mid Freezer
                } else if (random > 100) {
                    boosterContract.mintBooster(msg.sender, 2 days, 3, 2, 1, chest.raiseStrength); //Mid Power Booster
                } else if (random > 80) {
                    boosterContract.mintBooster(msg.sender, 2 days, 1, 3, 1, chest.raiseStrength); //Big Agility Booster
                } else if (random > 60) {
                    boosterContract.mintBooster(msg.sender, 30 days, 2, 3, 1, chest.raiseStrength); //Big Freezer
                } else if (random > 40) {
                    boosterContract.mintBooster(msg.sender, 2 days, 3, 3, 1, chest.raiseStrength); //Big Power Booster
                } else if (random > 20) {
                    boosterContract.mintBooster(msg.sender, 0, 5, 1, 1, 0); //Instant Attack
                } else {
                    boosterContract.mintBooster(msg.sender, 3 days, 4, 3, 1, 0); //Gold Watch
                }
            }
        }

        _transfer(msg.sender, address(0), _tokenId); //burn chest
    }

    //ERC721 functionality
    //could split this to a different contract but doesn&#39;t make it easier to read
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function totalSupply() public view returns (uint256 total) {
        total = chests.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        balance = balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner){
        owner = chests[_tokenId].owner;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(chests[_tokenId].owner == _from); //can only transfer if previous owner equals from
        chests[_tokenId].owner = _to;
        approved[_tokenId] = address(0); //reset approved of fish on every transfer
        balances[_from] -= 1; //underflow can only happen on 0x
        balances[_to] += 1; //overflows only with very very large amounts of fish
        Transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public
    onlyChestOwner(_tokenId) //check if msg.sender is the owner of this fish
    returns (bool)
    {
        _transfer(msg.sender, _to, _tokenId);
        //after master modifier invoke internal transfer
        return true;
    }

    function approve(address _to, uint256 _tokenId) public
    onlyChestOwner(_tokenId)
    {
        approved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public returns (bool) {
        require(approved[_tokenId] == msg.sender);
        //require msg.sender to be approved for this token
        _transfer(_from, _to, _tokenId);
        //handles event, balances and approval reset
        return true;
    }

}





contract FishbankUtils is Ownable {

    uint32[100] cooldowns = [
        720 minutes, 720 minutes, 720 minutes, 720 minutes, 720 minutes, //1-5
        660 minutes, 660 minutes, 660 minutes, 660 minutes, 660 minutes, //6-10
        600 minutes, 600 minutes, 600 minutes, 600 minutes, 600 minutes, //11-15
        540 minutes, 540 minutes, 540 minutes, 540 minutes, 540 minutes, //16-20
        480 minutes, 480 minutes, 480 minutes, 480 minutes, 480 minutes, //21-25
        420 minutes, 420 minutes, 420 minutes, 420 minutes, 420 minutes, //26-30
        360 minutes, 360 minutes, 360 minutes, 360 minutes, 360 minutes, //31-35
        300 minutes, 300 minutes, 300 minutes, 300 minutes, 300 minutes, //36-40
        240 minutes, 240 minutes, 240 minutes, 240 minutes, 240 minutes, //41-45
        180 minutes, 180 minutes, 180 minutes, 180 minutes, 180 minutes, //46-50
        120 minutes, 120 minutes, 120 minutes, 120 minutes, 120 minutes, //51-55
        90 minutes,  90 minutes,  90 minutes,  90 minutes,  90 minutes,  //56-60
        75 minutes,  75 minutes,  75 minutes,  75 minutes,  75 minutes,  //61-65
        60 minutes,  60 minutes,  60 minutes,  60 minutes,  60 minutes,  //66-70
        50 minutes,  50 minutes,  50 minutes,  50 minutes,  50 minutes,  //71-75
        40 minutes,  40 minutes,  40 minutes,  40 minutes,  40 minutes,  //76-80
        30 minutes,  30 minutes,  30 minutes,  30 minutes,  30 minutes,  //81-85
        20 minutes,  20 minutes,  20 minutes,  20 minutes,  20 minutes,  //86-90
        10 minutes,  10 minutes,  10 minutes,  10 minutes,  10 minutes,  //91-95
        5 minutes,   5 minutes,   5 minutes,   5 minutes,   5 minutes    //96-100
    ];


    function setCooldowns(uint32[100] _cooldowns) onlyOwner public {
        cooldowns = _cooldowns;
    }

    function getFishParams(uint256 hashSeed1, uint256 hashSeed2, uint256 fishesLength, address coinbase) external pure returns (uint32[4]) {

        bytes32[5] memory hashSeeds;
        hashSeeds[0] = keccak256(hashSeed1 ^ hashSeed2); //xor both seed from owner and user so no one can cheat
        hashSeeds[1] = keccak256(hashSeeds[0], fishesLength);
        hashSeeds[2] = keccak256(hashSeeds[1], coinbase);
        hashSeeds[3] = keccak256(hashSeeds[2], coinbase, fishesLength);
        hashSeeds[4] = keccak256(hashSeeds[1], hashSeeds[2], hashSeeds[0]);

        uint24[6] memory seeds = [
            uint24(uint(hashSeeds[3]) % 10e6 + 1), //whale chance
            uint24(uint(hashSeeds[0]) % 420 + 1), //power
            uint24(uint(hashSeeds[1]) % 420 + 1), //agility
            uint24(uint(hashSeeds[2]) % 150 + 1), //speed
            uint24(uint(hashSeeds[4]) % 16 + 1), //whale type
            uint24(uint(hashSeeds[4]) % 5000 + 1) //rarity
        ];

        uint32[4] memory fishParams;

        if (seeds[0] == 1000000) {//This is a whale 1:1 000 000 chance

            if (seeds[4] == 1) {//Orca
                fishParams = [140 + uint8(seeds[1] / 42), 140 + uint8(seeds[2] / 42), 75 + uint8(seeds[3] / 6), uint32(500000)];
                if(fishParams[0] == 140) {
                    fishParams[0]++;
                }
                if(fishParams[1] == 140) {
                    fishParams[1]++;
                }
                if(fishParams[2] == 75) {
                    fishParams[2]++;
                }
            } else if (seeds[4] < 4) {//Blue whale
                fishParams = [130 + uint8(seeds[1] / 42), 130 + uint8(seeds[2] / 42), 75 + uint8(seeds[3] / 6), uint32(500000)];
                if(fishParams[0] == 130) {
                    fishParams[0]++;
                }
                if(fishParams[1] == 130) {
                    fishParams[1]++;
                }
                if(fishParams[2] == 75) {
                    fishParams[2]++;
                }
            } else {//Cachalot
                fishParams = [115 + uint8(seeds[1] / 28), 115 + uint8(seeds[2] / 28), 75 + uint8(seeds[3] / 6), uint32(500000)];
                if(fishParams[0] == 115) {
                    fishParams[0]++;
                }
                if(fishParams[1] == 115) {
                    fishParams[1]++;
                }
                if(fishParams[2] == 75) {
                    fishParams[2]++;
                }
            }
        } else {
            if (seeds[5] == 5000) {//Legendary
                fishParams = [85 + uint8(seeds[1] / 14), 85 + uint8(seeds[2] / 14), uint8(50 + seeds[3] / 3), uint32(1000)];
                if(fishParams[0] == 85) {
                    fishParams[0]++;
                }
                if(fishParams[1] == 85) {
                    fishParams[1]++;
                }
            } else if (seeds[5] > 4899) {//Epic
                fishParams = [50 + uint8(seeds[1] / 12), 50 + uint8(seeds[2] / 12), uint8(25 + seeds[3] / 2), uint32(300)];
                if(fishParams[0] == 50) {
                    fishParams[0]++;
                }
                if(fishParams[1] == 50) {
                    fishParams[1]++;
                }

            } else if (seeds[5] > 4000) {//Rare
                fishParams = [20 + uint8(seeds[1] / 14), 20 + uint8(seeds[2] / 14), uint8(25 + seeds[3] / 3), uint32(100)];
                if(fishParams[0] == 20) {
                    fishParams[0]++;
                }
                if(fishParams[1] == 20) {
                    fishParams[1]++;
                }
            } else {//Common
                fishParams = [uint8(seeds[1] / 21), uint8(seeds[2] / 21), uint8(seeds[3] / 3), uint32(36)];
                if (fishParams[0] == 0) {
                    fishParams[0] = 1;
                }
                if (fishParams[1] == 0) {
                    fishParams[1] = 1;
                }
                if (fishParams[2] == 0) {
                    fishParams[2] = 1;
                }
            }
        }

        return fishParams;
    }

    function getCooldown(uint16 speed) external view returns (uint64){
        return uint64(now + cooldowns[speed - 1]);
    }

    //Ceiling function for fish generator
    function ceil(uint base, uint divider) internal pure returns (uint) {
        return base / divider + ((base % divider > 0) ? 1 : 0);
    }
}




/// @title Auction contract for any type of erc721 token
/// @author Fishbank

contract ERC721 {

    function implementsERC721() public pure returns (bool);

    function totalSupply() public view returns (uint256 total);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function ownerOf(uint256 _tokenId) public view returns (address owner);

    function approve(address _to, uint256 _tokenId) public;

    function transferFrom(address _from, address _to, uint256 _tokenId) public returns (bool);

    function transfer(address _to, uint256 _tokenId) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}


contract ERC721Auction is Beneficiary {

    struct Auction {
        address seller;
        uint256 tokenId;
        uint64 auctionBegin;
        uint64 auctionEnd;
        uint256 startPrice;
        uint256 endPrice;
    }

    uint32 public auctionDuration = 7 days;

    ERC721 public ERC721Contract;
    uint256 public fee = 45000; //in 1 10000th of a percent so 4.5% at the start
    uint256 constant FEE_DIVIDER = 1000000;
    mapping(uint256 => Auction) public auctions;

    event AuctionWon(uint256 indexed tokenId, address indexed winner, address indexed seller, uint256 price);

    event AuctionStarted(uint256 indexed tokenId, address indexed seller);

    event AuctionFinalized(uint256 indexed tokenId, address indexed seller);


    function startAuction(uint256 _tokenId, uint256 _startPrice, uint256 _endPrice) external {
        require(ERC721Contract.transferFrom(msg.sender, address(this), _tokenId));
        //Prices must be in range from 0.01 Eth and 10 000 Eth
        require(_startPrice <= 10000 ether && _endPrice <= 10000 ether);
        require(_startPrice >= (1 ether / 100) && _endPrice >= (1 ether / 100));

        Auction memory auction;

        auction.seller = msg.sender;
        auction.tokenId = _tokenId;
        auction.auctionBegin = uint64(now);
        auction.auctionEnd = uint64(now + auctionDuration);
        require(auction.auctionEnd > auction.auctionBegin);
        auction.startPrice = _startPrice;
        auction.endPrice = _endPrice;

        auctions[_tokenId] = auction;

        AuctionStarted(_tokenId, msg.sender);
    }


    function buyAuction(uint256 _tokenId) payable external {
        Auction storage auction = auctions[_tokenId];

        uint256 price = calculateBid(_tokenId);
        uint256 totalFee = price * fee / FEE_DIVIDER; //safe math needed?

        require(price <= msg.value); //revert if not enough ether send

        if (price != msg.value) {//send back to much eth
            msg.sender.transfer(msg.value - price);
        }

        beneficiary.transfer(totalFee);

        auction.seller.transfer(price - totalFee);

        if (!ERC721Contract.transfer(msg.sender, _tokenId)) {
            revert();
            //can&#39;t complete transfer if this fails
        }

        AuctionWon(_tokenId, msg.sender, auction.seller, price);

        delete auctions[_tokenId];
        //deletes auction
    }

    function saveToken(uint256 _tokenId) external {
        require(auctions[_tokenId].auctionEnd < now);
        //auction must have ended
        require(ERC721Contract.transfer(auctions[_tokenId].seller, _tokenId));
        //transfer fish back to seller

        AuctionFinalized(_tokenId, auctions[_tokenId].seller);

        delete auctions[_tokenId];
        //delete auction
    }

    function ERC721Auction(address _ERC721Contract) public {
        ERC721Contract = ERC721(_ERC721Contract);
    }

    function setFee(uint256 _fee) onlyOwner public {
        if (_fee > fee) {
            revert(); //fee can only be set to lower value to prevent attacks by owner
        }
        fee = _fee; // all is well set fee
    }

    function calculateBid(uint256 _tokenId) public view returns (uint256) {
        Auction storage auction = auctions[_tokenId];

        if (now >= auction.auctionEnd) {//if auction ended return auction end price
            return auction.endPrice;
        }
        //get hours passed
        uint256 hoursPassed = (now - auction.auctionBegin) / 1 hours;
        uint256 currentPrice;
        //get total hours
        uint16 totalHours = uint16(auctionDuration /1 hours) - 1;

        if (auction.endPrice > auction.startPrice) {
            currentPrice = auction.startPrice + (hoursPassed * (auction.endPrice - auction.startPrice))/ totalHours;
        } else if(auction.endPrice < auction.startPrice) {
            currentPrice = auction.startPrice - (hoursPassed * (auction.startPrice - auction.endPrice))/ totalHours;
        } else {//start and end are the same
            currentPrice = auction.endPrice;
        }

        return uint256(currentPrice);
        //return the price at this very moment
    }

    /// return token if case when need to redeploy auction contract
    function returnToken(uint256 _tokenId) onlyOwner public {
        require(ERC721Contract.transfer(auctions[_tokenId].seller, _tokenId));
        //transfer fish back to seller

        AuctionFinalized(_tokenId, auctions[_tokenId].seller);

        delete auctions[_tokenId];
    }
}


/// @title Core contract of fishbank
/// @author Fishbank

contract Fishbank is ChestsStore {

    struct Fish {
        address owner;
        uint8 activeBooster;
        uint64 boostedTill;
        uint8 boosterStrength;
        uint24 boosterRaiseValue;
        uint64 weight;
        uint16 power;
        uint16 agility;
        uint16 speed;
        bytes16 color;
        uint64 canFightAgain;
        uint64 canBeAttackedAgain;
    }

    struct FishingAttempt {
        address fisher;
        uint256 feePaid;
        address affiliate;
        uint256 seed;
        uint64 deadline;//till when does the contract owner have time to resolve;
    }

    modifier onlyFishOwner(uint256 _tokenId) {
        require(fishes[_tokenId].owner == msg.sender);
        _;
    }

    modifier onlyResolver() {
        require(msg.sender == resolver);
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    Fish[] public fishes;
    address public resolver;
    address public auction;
    address public minter;
    bool public implementsERC721 = true;
    string public name = "Fishbank";
    string public symbol = "FISH";
    bytes32[] public randomHashes;
    uint256 public hashesUsed;
    uint256 public aquariumCost = 1 ether / 100 * 3;//fee for fishing starts at 0.03 ether
    uint256 public resolveTime = 30 minutes;//how long does the contract owner have to resolve hashes
    uint16 public weightLostPartLimit = 5;
    FishbankBoosters public boosters;
    FishbankChests public chests;
    FishbankUtils private utils;


    mapping(bytes32 => FishingAttempt) public pendingFishing;//attempts that need solving;

    mapping(uint256 => address) public approved;
    mapping(address => uint256) public balances;
    mapping(address => bool) public affiliated;

    event AquariumFished(
        bytes32 hash,
        address fisher,
        uint256 feePaid
    ); //event broadcated when someone fishes in aqaurium

    event AquariumResolved(bytes32 hash, address fisher);

    event Attack(
        uint256 attacker,
        uint256 victim,
        uint256 winner,
        uint64 weight,
        uint256 ap, uint256 vp, uint256 random
    );

    event BoosterApplied(uint256 tokenId, uint256 boosterId);

    /// @notice Constructor of the contract. Sets resolver, beneficiary, boosters and chests
    /// @param _boosters the address of the boosters smart contract
    /// @param _chests the address of the chests smart contract

    function Fishbank(address _boosters, address _chests, address _utils) ChestsStore(_chests) public {

        resolver = msg.sender;
        beneficiary = msg.sender;
        boosters = FishbankBoosters(_boosters);
        chests = FishbankChests(_chests);
        utils = FishbankUtils(_utils);
    }

    /// @notice Mints fishes according to params can only be called by the owner
    /// @param _owner array of addresses the fishes should be owned by
    /// @param _weight array of weights for the fishes
    /// @param _power array of power levels for the fishes
    /// @param _agility array of agility levels for the fishes
    /// @param _speed array of speed levels for the fishes
    /// @param _color array of color params for the fishes

    function mintFish(address[] _owner, uint32[] _weight, uint8[] _power, uint8[] _agility, uint8[] _speed, bytes16[] _color) onlyMinter public {

        for (uint i = 0; i < _owner.length; i ++) {
            _mintFish(_owner[i], _weight[i], _power[i], _agility[i], _speed[i], _color[i]);
        }
    }

    /// @notice Internal method for minting a fish
    /// @param _owner address of owner for the fish
    /// @param _weight weight param for fish
    /// @param _power power param for fish
    /// @param _agility agility param for the fish
    /// @param _speed speed param for the fish
    /// @param _color color param for the fish

    function _mintFish(address _owner, uint32 _weight, uint8 _power, uint8 _agility, uint8 _speed, bytes16 _color) internal {

        fishes.length += 1;
        uint256 newFishId = fishes.length - 1;

        Fish storage newFish = fishes[newFishId];

        newFish.owner = _owner;
        newFish.weight = _weight;
        newFish.power = _power;
        newFish.agility = _agility;
        newFish.speed = _speed;
        newFish.color = _color;

        balances[_owner] ++;

        Transfer(address(0), _owner, newFishId);
    }

    function setWeightLostPartLimit(uint8 _weightPart) onlyOwner public {
        weightLostPartLimit = _weightPart;
    }

    /// @notice Sets the cost for fishing in the aquarium
    /// @param _fee new fee for fishing in wei
    function setAquariumCost(uint256 _fee) onlyOwner public {
        aquariumCost = _fee;
    }

    /// @notice Sets address that resolves hashes for fishing can only be called by the owner
    /// @param _resolver address of the resolver
    function setResolver(address _resolver) onlyOwner public {
        resolver = _resolver;
    }


    /// @notice Sets the address getting the proceedings from fishing in the aquarium
    /// @param _beneficiary address of the new beneficiary
    function setBeneficiary(address _beneficiary) onlyOwner public {
        beneficiary = _beneficiary;
    }

    function setAuction(address _auction) onlyOwner public {
        auction = _auction;
    }

    function setBoosters(address _boosters) onlyOwner public {
        boosters = FishbankBoosters(_boosters);
    }

    function setMinter(address _minter) onlyOwner public {
        minter = _minter;
    }

    function setUtils(address _utils) onlyOwner public {
        utils = FishbankUtils(_utils);
    }

    /// batch fishing from 1 to 10 times
    function batchFishAquarium(uint256[] _seeds, address _affiliate) payable public {
        require(_seeds.length > 0 && _seeds.length <= 10);
        require(msg.value >= aquariumCost * _seeds.length);
        //must send enough ether to cover costs
        require(randomHashes.length > hashesUsed + _seeds.length);
        //there needs to be a hash left

        if (msg.value > aquariumCost * _seeds.length) {
            msg.sender.transfer(msg.value - aquariumCost * _seeds.length);
            //send to much ether back
        }

        for (uint256 i = 0; i < _seeds.length; i ++) {
            _fishAquarium(_seeds[i]);
        }

        if(_affiliate != address(0)) {
            pendingFishing[randomHashes[hashesUsed - 1]].affiliate = _affiliate;
        }
    }

    function _fishAquarium(uint256 _seed) internal {
        //this loop prevents from using the same hash as another fishing attempt if the owner submits the same hash multiple times
        while (pendingFishing[randomHashes[hashesUsed]].fisher != address(0)) {
            hashesUsed++;
            //increase hashesUsed and try next one
        }

        FishingAttempt storage newAttempt = pendingFishing[randomHashes[hashesUsed]];

        newAttempt.fisher = msg.sender;
        newAttempt.feePaid = aquariumCost;
        //set the fee paid so it can be returned if the hash doesn&#39;t get resolved fast enough
        newAttempt.seed = _seed;
        //sets the seed that gets combined with the random seed of the owner
        newAttempt.deadline = uint64(now + resolveTime);
        //saves deadline after which the fisher can redeem his fishing fee

        hashesUsed++;
        //increase hashes used so it cannot be used again

        AquariumFished(randomHashes[hashesUsed - 1], msg.sender, aquariumCost);
        //broadcast event
    }

    /// @notice Call this to resolve hashes and generate fish/chests
    /// @param _seed seed that corresponds to the hash
    function _resolveAquarium(uint256 _seed) internal {
        bytes32 tempHash = keccak256(_seed);
        FishingAttempt storage tempAttempt = pendingFishing[tempHash];

        require(tempAttempt.fisher != address(0));
        //attempt must be set so we look if fisher is set

        if (tempAttempt.affiliate != address(0) && !affiliated[tempAttempt.fisher]) {//if affiliate is set
            chests.mintChest(tempAttempt.affiliate, 1, 0, 0, 0, 0);
            //Chest with one random booster
            affiliated[tempAttempt.fisher] = true;
        }

        uint32[4] memory fishParams = utils.getFishParams(_seed, tempAttempt.seed, fishes.length, block.coinbase);

        _mintFish(tempAttempt.fisher, fishParams[3], uint8(fishParams[0]), uint8(fishParams[1]), uint8(fishParams[2]), bytes16(keccak256(_seed ^ tempAttempt.seed)));

        beneficiary.transfer(tempAttempt.feePaid);
        AquariumResolved(tempHash, tempAttempt.fisher);
        //broadcast event

        delete pendingFishing[tempHash];
        //delete fishing attempt
    }

    /// @notice Batch resolve fishing attempts
    /// @param _seeds array of seeds that correspond to hashes that need resolving
    function batchResolveAquarium(uint256[] _seeds) onlyResolver public {
        for (uint256 i = 0; i < _seeds.length; i ++) {
            _resolveAquarium(_seeds[i]);
        }
    }


    /// @notice Adds an array of hashes to be used for resolving
    /// @param _hashes array of hashes to add
    function addHash(bytes32[] _hashes) onlyResolver public {
        for (uint i = 0; i < _hashes.length; i ++) {
            randomHashes.push(_hashes[i]);
        }
    }

    /// @notice Call this function to attack another fish
    /// @param _attacker ID of fish that is attacking
    /// @param _victim ID of fish to attack
    function attack(uint256 _attacker, uint256 _victim) onlyFishOwner(_attacker) public {

        Fish memory attacker = fishes[_attacker];
        Fish memory victim = fishes[_victim];

        //check if attacker is sleeping
        if (attacker.activeBooster == 2 && attacker.boostedTill > now) {//if your fish is sleeping auto awake it
            fishes[_attacker].activeBooster = 0;
            attacker.boostedTill = uint64(now);
            //set booster to invalid one so it has no effect
        }

        //check if victim has active sleeping booster
        require(!((victim.activeBooster == 2) && victim.boostedTill >= now));
        //cannot attack a sleeping fish
        require(now >= attacker.canFightAgain);
        //check if attacking fish is cooled down
        require(now >= victim.canBeAttackedAgain);
        //check if victim fish can be attacked again


        if (msg.sender == victim.owner) {
            uint64 weight = attacker.weight < victim.weight ? attacker.weight : victim.weight;
            fishes[_attacker].weight += weight;
            fishes[_victim].weight -= weight;
            fishes[_attacker].canFightAgain = uint64(utils.getCooldown(attacker.speed));

            if (fishes[_victim].weight == 0) {
                _transfer(msg.sender, address(0), _victim);
                balances[fishes[_victim].owner] --;
                //burn token
            } else {
                fishes[_victim].canBeAttackedAgain = uint64(now + 1 hours);
                //set victim cooldown 1 hour
            }

            Attack(_attacker, _victim, _attacker, weight, 0, 0, 0);
            return;
        }

        if (victim.weight < 2 || attacker.weight < 2) {
            revert();
            //revert if one of the fish is below fighting weight
        }

        uint256 AP = getFightingAmounts(attacker, true);
        // get attacker power
        uint256 VP = getFightingAmounts(victim, false);
        // get victim power

        bytes32 randomHash = keccak256(block.coinbase, block.blockhash(block.number - 1), fishes.length);

        uint256 max = AP > VP ? AP : VP;
        uint256 attackRange = max * 2;
        uint256 random = uint256(randomHash) % attackRange + 1;

        uint64 weightLost;

        if (random <= (max + AP - VP)) {
            weightLost = _handleWin(_attacker, _victim);
            Attack(_attacker, _victim, _attacker, weightLost, AP, VP, random);
        } else {
            weightLost = _handleWin(_victim, _attacker);
            Attack(_attacker, _victim, _victim, weightLost, AP, VP, random);
            //broadcast event
        }

        fishes[_attacker].canFightAgain = uint64(utils.getCooldown(attacker.speed));
        fishes[_victim].canBeAttackedAgain = uint64(now + 1 hours);
        //set victim cooldown 1 hour
    }

    /// @notice Handles lost gained weight after fight
    /// @param _winner the winner of the fight
    /// @param _loser the loser of the fight
    function _handleWin(uint256 _winner, uint256 _loser) internal returns (uint64) {
        Fish storage winner = fishes[_winner];
        Fish storage loser = fishes[_loser];

        uint64 fullWeightLost = loser.weight / sqrt(winner.weight);
        uint64 maxWeightLost = loser.weight / weightLostPartLimit;

        uint64 weightLost = maxWeightLost < fullWeightLost ? maxWeightLost : fullWeightLost;

        if (weightLost < 1) {
            weightLost = 1;
            // Minimum 1
        }

        winner.weight += weightLost;
        loser.weight -= weightLost;

        return weightLost;
    }

    /// @notice get attack and defence from fish
    /// @param _fish is Fish token
    /// @param _is_attacker true if fish is attacker otherwise false
    function getFightingAmounts(Fish _fish, bool _is_attacker) internal view returns (uint256){
        return (getFishPower(_fish) * (_is_attacker ? 60 : 40) + getFishAgility(_fish) * (_is_attacker ? 40 : 60)) * _fish.weight;
    }

    /// @notice Apply a booster to a fish
    /// @param _tokenId the fish the booster should be applied to
    /// @param _booster the Id of the booster the token should be applied to
    function applyBooster(uint256 _tokenId, uint256 _booster) onlyFishOwner(_tokenId) public {
        require(msg.sender == boosters.ownerOf(_booster));
        //only owner can do this
        require(boosters.getBoosterAmount(_booster) >= 1);
        Fish storage tempFish = fishes[_tokenId];
        uint8 boosterType = uint8(boosters.getBoosterType(_booster));

        if (boosterType == 1 || boosterType == 2 || boosterType == 3) {//if booster is attack or agility or sleep
            tempFish.boosterStrength = boosters.getBoosterStrength(_booster);
            tempFish.activeBooster = boosterType;
            tempFish.boostedTill = boosters.getBoosterDuration(_booster) * boosters.getBoosterAmount(_booster) + uint64(now);
            tempFish.boosterRaiseValue = boosters.getBoosterRaiseValue(_booster);
        }
        else if (boosterType == 4) {//watch booster
            require(tempFish.boostedTill > uint64(now));
            //revert on using watch on booster that has passed;
            tempFish.boosterStrength = boosters.getBoosterStrength(_booster);
            tempFish.boostedTill += boosters.getBoosterDuration(_booster) * boosters.getBoosterAmount(_booster);
            //add time to booster
        }
        else if (boosterType == 5) {//Instant attack
            require(boosters.getBoosterAmount(_booster) == 1);
            //Can apply only one instant attack booster
            tempFish.canFightAgain = 0;
        }

        require(boosters.transferFrom(msg.sender, address(0), _booster));
        //burn booster

        BoosterApplied(_tokenId, _booster);
    }

    /// @notice square root function used for weight gain/loss
    /// @param x uint64 to get square root from
    function sqrt(uint64 x) pure internal returns (uint64 y) {
        uint64 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    //utlitiy function for easy testing can be removed later
    function doKeccak256(uint256 _input) pure public returns (bytes32) {
        return keccak256(_input);
    }

    function getFishPower(Fish _fish) internal view returns (uint24 power) {
        power = _fish.power;
        if (_fish.activeBooster == 1 && _fish.boostedTill > now) {// check if booster active
            uint24 boosterPower = (10 * _fish.boosterStrength + _fish.boosterRaiseValue + 100) * power / 100 - power;
            if (boosterPower < 1 && _fish.boosterStrength == 1) {
                power += 1;
            } else if (boosterPower < 3 && _fish.boosterStrength == 2) {
                power += 3;
            } else if (boosterPower < 5 && _fish.boosterStrength == 3) {
                power += 5;
            } else {
                power = boosterPower + power;
            }
        }
    }

    function getFishAgility(Fish _fish) internal view returns (uint24 agility) {
        agility = _fish.agility;
        if (_fish.activeBooster == 3 && _fish.boostedTill > now) {// check if booster active
            uint24 boosterPower = (10 * _fish.boosterStrength + _fish.boosterRaiseValue + 100) * agility / 100 - agility;
            if (boosterPower < 1 && _fish.boosterStrength == 1) {
                agility += 1;
            } else if (boosterPower < 3 && _fish.boosterStrength == 2) {
                agility += 3;
            } else if (boosterPower < 5 && _fish.boosterStrength == 3) {
                agility += 5;
            } else {
                agility = boosterPower + agility;
            }
        }
    }


    //ERC721 functionality
    //could split this to a different contract but doesn&#39;t make it easier to read
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function totalSupply() public view returns (uint256 total) {
        total = fishes.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        balance = balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner){
        owner = fishes[_tokenId].owner;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(fishes[_tokenId].owner == _from);
        //can only transfer if previous owner equals from
        fishes[_tokenId].owner = _to;
        approved[_tokenId] = address(0);
        //reset approved of fish on every transfer
        balances[_from] -= 1;
        //underflow can only happen on 0x
        balances[_to] += 1;
        //overflows only with very very large amounts of fish
        Transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public
    onlyFishOwner(_tokenId) //check if msg.sender is the owner of this fish
    returns (bool)
    {
        _transfer(msg.sender, _to, _tokenId);
        //after master modifier invoke internal transfer
        return true;
    }

    function approve(address _to, uint256 _tokenId) public
    onlyFishOwner(_tokenId)
    {
        approved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public returns (bool) {
        require(approved[_tokenId] == msg.sender || msg.sender == auction);
        Fish storage fish = fishes[_tokenId];

        if (msg.sender == auction) {
            fish.activeBooster = 2;
            //Freeze for auction
            fish.boostedTill = uint64(now + 7 days);
            fish.boosterStrength = 1;
        }
        //require msg.sender to be approved for this token
        _transfer(_from, _to, _tokenId);
        //handles event, balances and approval reset
        return true;
    }

    function takeOwnership(uint256 _tokenId) public {
        require(approved[_tokenId] == msg.sender);
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

}