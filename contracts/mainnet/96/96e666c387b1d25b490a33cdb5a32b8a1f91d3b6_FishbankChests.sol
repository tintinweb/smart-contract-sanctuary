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