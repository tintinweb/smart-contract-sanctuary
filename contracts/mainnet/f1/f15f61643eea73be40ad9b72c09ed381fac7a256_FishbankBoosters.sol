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