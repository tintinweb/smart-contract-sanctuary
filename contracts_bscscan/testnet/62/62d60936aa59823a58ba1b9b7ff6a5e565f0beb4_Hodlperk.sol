/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library Counters {
    struct Counter {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Hodlperk is Ownable {
    using Counters for Counters.Counter;
    struct Reward {
        string name;
        string code;
        string url;
        string external_url;
    }
    
    struct Perk {
        uint   perk_type;
        string name;
        string code;          //if the perk type is 1 we will store perk code here.
        string unique_url;    //if the perk type is 2 we will store perk's unique url here.
        string gift_card_url; //if the perk type is 3 we will store gift card'd url here.
    }

    Counters.Counter private _rewardIdCounter;
    Counters.Counter private _perkIdCounter;
    // variable that will contain the address of the contract deployer
    mapping(uint256 => Reward) public Rewards;
    mapping(uint256 => Perk)   public PerkList;
    mapping(address => bool)   public whitelistedAddresses;
    mapping(address => bool)   public blacklistAddresses;
    mapping(address => bool)   public modifierList;
    constructor()  {}

    modifier isBlacklisted(address _address) {
        require(blacklistAddresses[_address], "You are Blacklisted");
        _;
    }

    modifier canModify(address _address) {
        require(modifierList[_address] || whitelistedAddresses[_address], "You do not have privileges to modify");
        _;
    }

    modifier isModifier(address _address) {
        require(modifierList[_address], "You do not have privileges to modify");
        _;
    }

    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "You are not whitelisted");
        _;
    }
    function addPerks(uint perk_type, string memory name, string memory code,string memory unique_url,string memory gift_card_url) public isWhitelisted(msg.sender) returns (uint256)
    {
        bytes memory codeBytes = bytes(code);
        bytes memory uniqueUrlBytes = bytes(unique_url);
        bytes memory giftCardUrlBytes = bytes(gift_card_url); // Uses memory

        require (perk_type == 1 && codeBytes.length == 0, "Code is required");
        require (perk_type == 2 && uniqueUrlBytes.length == 0, "Unique URL is required");
        require (perk_type == 3 && giftCardUrlBytes.length == 0, "Gift Card URL is required");

        _perkIdCounter.increment();
        uint256 perkId = _perkIdCounter.current();

        Perk memory perk = Perk(perk_type,name,code, unique_url, gift_card_url);
        PerkList[perkId]=perk;
        return perkId;
    }
    function updatePerks(uint perkId ,uint perk_type, string memory name, string memory code,string memory unique_url,string memory gift_card_url) public canModify(msg.sender) returns (uint256)
    {
        bytes memory codeBytes = bytes(code);
        bytes memory uniqueUrlBytes = bytes(unique_url);
        bytes memory giftCardUrlBytes = bytes(gift_card_url); // Uses memory

        require (perk_type == 1 && codeBytes.length == 0, "Code is required");
        require (perk_type == 2 && uniqueUrlBytes.length == 0, "Unique URL is required");
        require (perk_type == 3 && giftCardUrlBytes.length == 0, "Gift Card URL is required");

        Perk memory perk = Perk(perk_type,name,code, unique_url, gift_card_url);
        PerkList[perkId]=perk;
        return perkId;
    }

    function removePerks(uint256 perk_id) public isWhitelisted(msg.sender){
        delete  PerkList[perk_id];
    }
    
    // only whitelisted users can add rewards
    function addRewards(string memory name,string memory image,string memory description,string memory url) public isWhitelisted(msg.sender) returns (uint256) {
        _rewardIdCounter.increment();
        uint256 rewardId = _rewardIdCounter.current();
        Reward memory reward=Reward(name,image,description,url);
        Rewards[rewardId]=reward;
        return rewardId;
    }

    function updateRewards(uint256 reward_id,string memory name,string memory image,string memory description,string memory url) public canModify(msg.sender) returns (uint256) {
        Reward memory tmp_reward=Reward(name,image,description,url);
        Rewards[reward_id]=tmp_reward;
        return reward_id;
    }

    function removeRewards(uint256 reward_id) public isWhitelisted(msg.sender){
        delete  Rewards[reward_id];
    }

    function addModifierListedUser(address _addressToModifierlist) public onlyOwner{
        modifierList[_addressToModifierlist] = true;
    }

    function removeModifierListedUser(address _addressToModifierlist) public onlyOwner{
        delete  modifierList[_addressToModifierlist];
    }
        
    function addUpdateWhiteListedUser(address _addressToWhitelist, bool status) public onlyOwner{
        whitelistedAddresses[_addressToWhitelist] = status;
    }

    function removeWhiteListedUser(address _addressToWhitelist) public onlyOwner{
        delete  whitelistedAddresses[_addressToWhitelist];
    }
    
    function addBlackListUser(address _addressToBlacklist, bool status) public onlyOwner{
        blacklistAddresses[_addressToBlacklist] = status;
    }

    function removeBlackListUser(address _addressToBlacklist) public onlyOwner{
        delete  blacklistAddresses[_addressToBlacklist];
    }
}