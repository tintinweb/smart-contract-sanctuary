// SPDX-License-Identifier: MIT
// File contracts/SecurusDrop.sol

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./INFT.sol";
import "./IERC20.sol";
import "./IReferrals.sol";
import "./IWhitelist.sol";
import "./IBlacklist.sol";

/**
 * @dev Contract for new NFT drops. SecurusDrop must be authorized to mint new NFTs of the specified
 * NFT contract (_nftAddress). You also have to be carefull of IDs you set. Since this contract
 * assumes offchain reservation of IDs. Meaning when you add drops you need to consider if NFT ids
 * will be available when buying.
 */
contract SecurusDrop is Ownable {

  struct Drop {
    uint256 totalSupply;
    uint256 idCounter;
    uint256 startingId;
    uint256 startTime;
    address nftAddress;
    address paymentCoin;
    address receiverAddress;
    uint256 price;
    uint256 Storelevel;
  }

  struct RefLevel {
    uint256 level1;
    uint256 level2;
    uint256 level3;
    uint256 level4;
    uint256 level5;
    uint256 level6;
    uint256 level7;
  }
  /**
   * @dev Address that will receive tokens from bought NFTs.
   */
  address private _receiverAddress;

  /**
   * @dev Address that will mint NFTs.
   */
     INFT public SecurusNFT;

      // Referrals Interface
    IReferrals public referrals;
    IWhitelist public whitelist;
    IBlacklist public blacklist;
  /**
   * @dev List of drops.
   */
  Drop[] public drops;
  RefLevel[] public RefLevels;

 //Counter for NFT-IDs
 uint private nftId = 0;

  /**
   * @dev Implements ERC721 contract and sets default values. 
   */
  constructor(
  )

  {
  
  }

   //Add a new drop
  function addDrop(
    uint256 totalSupply,
    uint256 startingId,
    uint256 startTime,
    address nftAddress,
    address paymentCoin,
    address receiverAddress,
    uint256 price,
    uint256 Storelevel
  )
    external
    onlyOwner
  {
    Drop memory d = Drop(totalSupply, 0, startingId, startTime, nftAddress, paymentCoin,receiverAddress, price, Storelevel);
    drops.push(d);
  }

   //Add a new drop
  function addRefLevel(
    uint256 level1,
    uint256 level2,
    uint256 level3,
    uint256 level4,
    uint256 level5,
    uint256 level6,
    uint256 level7

   )
    external
    onlyOwner
  {
    RefLevel memory r = RefLevel(level1, level2, level3, level4, level5, level6, level7);
    RefLevels.push(r);
  }




  
    struct MemberStruct {
        bool isExist;
        uint256 id;
        address sponsor;
        uint256 referrerID;
        uint256 referredUsers;
    }
    mapping(address => MemberStruct) public members; // Membership structure
    mapping(uint256 => address) public membersList; // Member listing by id
    mapping(uint256 => mapping(uint256 => address)) public memberChild; // List of referrals by user
    uint256 public lastMember; // ID of the last registered member
    
  //UpdateDrop
    function UpdateTotalSupply(uint256 dropIndex, uint _totalSupply) public onlyOwner {
        drops[dropIndex].totalSupply = _totalSupply;
    }
     function UpdateStartingId(uint256 dropIndex, uint _startingId) public onlyOwner {
        drops[dropIndex].startingId = _startingId;
    }
     function UpdateStartTime(uint256 dropIndex, uint _startTime) public onlyOwner {
        drops[dropIndex].startTime = _startTime;
    }
     function UpdateNftAddress(uint256 dropIndex, address _nftAddress) public onlyOwner {
        drops[dropIndex].nftAddress = _nftAddress;
    }
     function UpdatePaymentCoin(uint256 dropIndex, address _paymentCoin) public onlyOwner {
        drops[dropIndex].paymentCoin = _paymentCoin;
    }
    function UpdateReceiverAddress(uint256 dropIndex, address _newReceiverAddress) public onlyOwner {
        drops[dropIndex].receiverAddress = _newReceiverAddress;
    }   
     function UpdatePrice(uint256 dropIndex, uint _price) public onlyOwner {
        drops[dropIndex].price = _price;
    }
  

    function UpdateReferralsContract(address _referralsContract) public onlyOwner {
        referrals = IReferrals(_referralsContract);
    }

    function UpdateWhitelistContract(address _whitelistContract) public onlyOwner {
        whitelist = IWhitelist(_whitelistContract);
    }

    function UpdateBlacklistContract(address _blacklistContract) public onlyOwner {
         blacklist = IBlacklist(_blacklistContract);
    }

  /**
   * @dev Removes and existing drop.
   * @param index Index of the drop we are removing.
   */
  function removeDrop(
    uint256 index
  )
    external
    onlyOwner
  {
    delete drops[index];
  }


//=================================================================================================================

     function UpdateNftID(uint _NftID) public onlyOwner {
        nftId = _NftID;
    }
 
 //Buy a NFT from Drop X
   function buy(uint256 dropIndex, address _sponsor) external {
       
    Drop memory d = drops[dropIndex];
    RefLevel memory r = RefLevels[dropIndex];

           require(whitelist.isWhitelisted(msg.sender) != false || whitelist.statusWhitelist() != true, "Not Whitelisted");
           require(blacklist.isBlacklisted(msg.sender) != true, "isBlacklisted");
            require(block.timestamp >= d.startTime, "Drop not yet available.");
            require(d.totalSupply > d.idCounter, "No more editions available.");
             nftId += 1;
            drops[dropIndex].idCounter++;
          
            IERC20 paymentCoins = IERC20 (address(d.paymentCoin));

        if(referrals.isMember(msg.sender) == false){
            if(referrals.isMember(_sponsor) == false){
                _sponsor = referrals.membersList(0);
            }
            referrals.addMember(msg.sender, _sponsor);
        }
         
        address _sponsor1 = referrals.getSponsor(msg.sender);
        paymentCoins.transferFrom(msg.sender, d.receiverAddress, d.price/100*d.Storelevel);
                 
        if (_sponsor1 != address(0x0) && r.level1 > 0) {
            paymentCoins.transferFrom(msg.sender, _sponsor1, d.price/100*r.level1);
            address _sponsor2 = referrals.getSponsor(_sponsor1);
              
        if (_sponsor2 != address(0x0) && r.level2 > 0) {
            paymentCoins.transferFrom(msg.sender, _sponsor2, d.price/100*r.level2);
            address  _sponsor3 = referrals.getSponsor(_sponsor2);
              
        if (_sponsor3 != address(0x0) && r.level3 > 0) {
            paymentCoins.transferFrom(msg.sender, _sponsor3, d.price/100*r.level3);
            address _sponsor4 = referrals.getSponsor(_sponsor3);
            
        if (_sponsor4 != address(0x0) && r.level4 > 0) {
            paymentCoins.transferFrom(msg.sender, _sponsor4, d.price/100*r.level4);
            address _sponsor5 = referrals.getSponsor(_sponsor4);

        if (_sponsor5 != address(0x0) && r.level5 > 0) {
            paymentCoins.transferFrom(msg.sender, _sponsor4, d.price/100*r.level5);
            address _sponsor6 = referrals.getSponsor(_sponsor5);

        if (_sponsor6 != address(0x0) && r.level6 > 0) {
            paymentCoins.transferFrom(msg.sender, _sponsor4, d.price/100*r.level6);
            address _sponsor7 = referrals.getSponsor(_sponsor6);

        if (_sponsor7 != address(0x0) && r.level7 > 0) {
            paymentCoins.transferFrom(msg.sender, _sponsor7, d.price/100*r.level7);
               
        }}}}}}}
        else {}
            
             SecurusNFT.mint(msg.sender, nftId); 
  }
   
   // Returns the address of the sponsor of an account
    function getSponsor(address account) public view returns (address) {
        return membersList[members[account].referrerID];
    }
    
     function isMember(address _user) public view returns (address) {
        return members[_user].sponsor;
    }    

 
  /**
   * @dev Returns the count of all existing Drops.
   * @return Total supply of NFTs.
   */
  function getDropCount()
    external
    view
    returns (uint256)
  {
    return drops.length;
  }
  
}