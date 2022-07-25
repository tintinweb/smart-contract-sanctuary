/**
 *Submitted for verification at cronoscan.com on 2022-06-02
*/

// Reroll into Yandere, Himedere or fast Shundere

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None

pragma solidity 0.8.14;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function the100PromoteToManager(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }
    
    event OwnershipTransferred(address owner);
}

interface IShoujoStats {
    struct Shoujo {
        uint16 nameIndex;
        uint16 surnameIndex;
        uint8 rarity;
        uint8 personality;
        uint8 cuteness;
        uint8 lewd;
        uint8 intelligence;
        uint8 aggressiveness;
        uint8 talkative;
        uint8 depression;
        uint8 genki;
        uint8 raburabu; 
        uint8 boyish;
    }
    function tokenStatsByIndex(uint256 index) external view returns (Shoujo memory);
    function reroll(uint256 waifu, bool lock, bool rarity) external;
}

interface HibikiInterface {  
    function approveMax(address spender) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}
interface WaifuInterface{
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external  view returns (uint256);
    function balanceOf(address account) external returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;

}

interface WaifusOwnerInterface{
    function getAllIdsOwnedBy(address owner) external view returns(uint256[] memory);
}

contract WaifuReroller is Auth {

    HibikiInterface public hibiki = HibikiInterface(0x6B66fCB66Dba37F99876a15303b759c73fc54ed0);
    WaifuInterface public waifu = WaifuInterface(0x632e9915a9BEe6cD8bd9ad1fBDf5396048d4De56);
    
    address _shoujoStats = 0x7c4f9A98B295160B7cc9775aF6d15fCEd071366C;
    IShoujoStats ss = IShoujoStats(_shoujoStats);

    uint256 waifuID;
    bool showStatsInError = false;
    bool areWeDone = false;

    constructor() Auth(msg.sender) {
        hibiki.approveMax(0x7c4f9A98B295160B7cc9775aF6d15fCEd071366C);
    }

    function sendHibikiBack() external onlyOwner{
        hibiki.transfer(owner, hibiki.balanceOf(address(this)));
    }

    function sendOneBack(uint256 waifuIDsend) external onlyOwner{
        waifu.safeTransferFrom(address(this), owner, waifuIDsend);
    }

    function migrateToNewContract(address newContract) external onlyOwner{
        hibiki.transfer(newContract, hibiki.balanceOf(address(this)));
    }

    function sendWaifusToThisContract(uint256 waifuToSendID) external onlyOwner{
        waifu.transferFrom(msg.sender, address(this), waifuToSendID);
    }

    function migrateToNewContractWaifus(address newContract) external onlyOwner{
        waifu.transferFrom(address(this), newContract, waifuID);
        setup();
    }

    function setup() public {
        waifuID = waifu.tokenOfOwnerByIndex(address(this),0);
        areWeDone = false;
    }

    function doIWantToKnow(bool doI) external onlyOwner {
        showStatsInError = doI;
    }

    function reroll() external onlyOwner{
        if(areWeDone) return;

        IShoujoStats(_shoujoStats).reroll(waifuID,true,false);
        
        (uint256 _rarity, uint256 type_, uint256 _attack, uint256 _speed) = checkStats(waifuID);
        bool isLegend;
        
        if(type_ == 1 || type_ == 4) isLegend = true;
        
        if(!isLegend && type_ == 9 && _speed >= 80) isLegend = true;

        if(showStatsInError){
            string memory rarity = uint2str(_rarity);
            string memory _type = uint2str(type_);
            string memory attack = uint2str(_attack);
            string memory speed = uint2str(_speed);

            string memory stats = string(abi.encodePacked("rarity=", rarity,"-  ", "type=", _type,"-  ", "attack=", attack,"-  ","speed=", speed)); 
        
            require(isLegend, stats);
        } else {
            require(isLegend, "No Luck this time");
        }
        
        waifu.safeTransferFrom(address(this), owner, waifuID);
        
        areWeDone = waifu.balanceOf(address(this)) == 0;

        if(!areWeDone) setup();
    }

    function checkStats(uint256 waifuIDToCheck) public view returns (uint256,uint256,uint256,uint256) {
        IShoujoStats.Shoujo memory waifuToCheck = ss.tokenStatsByIndex(waifuIDToCheck);
        return (waifuToCheck.rarity, waifuToCheck.personality,waifuToCheck.genki + waifuToCheck.aggressiveness + waifuToCheck.boyish + 1, (waifuToCheck.aggressiveness + 1) * (waifuToCheck.genki + 1) + waifuToCheck.boyish);
    }

    function uint2str(uint256 _i) internal pure returns (string memory str)
    {
      if (_i == 0) return "0";
      uint256 j = _i;
      uint256 length;
      while (j != 0)
      {
        length++;
        j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint256 k = length;
      j = _i;
      while (j != 0)
      {
        bstr[--k] = bytes1(uint8(48 + j % 10));
        j /= 10;
      }
      str = string(bstr);
    }
}