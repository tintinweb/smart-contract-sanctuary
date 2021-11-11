/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.7;

interface ERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool) ;

    function balanceOf(address account) external view returns (uint256) ;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);

    
}

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant PORTAL_AAVEGOTCHIS_NUM = 10;

struct AavegotchiInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    uint256 status;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    int16[NUMERIC_TRAITS_NUM] modifiedNumericTraits;
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship; //The kinship value of this Aavegotchi. Default is 50.
    uint256 lastInteracted;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 toNextLevel;
    uint256 usedSkillPoints; //number of skill points used
    uint256 level; //the current aavegotchi level
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

struct PortalAavegotchiTraitsIO {
    uint256 randomNumber;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    address collateralType;
    uint256 minimumStake;
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name; //The name of the item
    string description;
    string author;
    // treated as int8s array
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] traitModifiers; //[WEARABLE ONLY] How much the wearable modifies each trait. Should not be more than +-5 total
    //[WEARABLE ONLY] The slots that this wearable can be added to.
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    // this is an array of uint indexes into the collateralTypes array
    uint8[] allowedCollaterals; //[WEARABLE ONLY] The collaterals this wearable can be equipped to. An empty array is "any"
    // SVG x,y,width,height
    Dimensions dimensions;
    uint256 ghstPrice; //How much GHST this item costs
    uint256 maxQuantity; //Total number that can be minted of this item.
    uint256 totalQuantity; //The total quantity of this item minted so far
    uint32 svgId; //The svgId of the item
    uint8 rarityScoreModifier; //Number from 1-50.
    // Each bit is a slot position. 1 is true, 0 is false
    bool canPurchaseWithGhst;
    uint16 minLevel; //The minimum Aavegotchi level required to use this item. Default is 1.
    bool canBeTransferred;
    uint8 category; // 0 is wearable, 1 is badge, 2 is consumable
    int16 kinshipBonus; //[CONSUMABLE ONLY] How much this consumable boosts (or reduces) kinship score
    uint32 experienceBonus; //[CONSUMABLE ONLY]
}

interface IERC721 /* is ERC165 */ {

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;
    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);
} 
 
interface Diamond{

    function openPortals(uint256[] calldata _tokenIds) external;
    
    function ownerOf(uint256 _tokenId) external view returns (address owner_);
    
    function getAavegotchi(uint256 _tokenId) external view returns (AavegotchiInfo memory aavegotchiInfo_);
    
    function portalAavegotchiTraits(uint256 _tokenId)
        external
        view
        returns (PortalAavegotchiTraitsIO[PORTAL_AAVEGOTCHIS_NUM] memory portalAavegotchiTraits_);
        
    function baseRarityScore(int16[NUMERIC_TRAITS_NUM] memory _numericTraits) external pure returns (uint256 rarityScore_);
}



contract PortalWars{
    address public gotchiAddress = 0x07543dB60F19b9B48A69a7435B5648b46d4Bb58E;
    
    enum State {Observer, Submitted, Committed, Opening, Winner, Loser}
    
    mapping (address => address) public opponents; //todo:change this to array of opponents?
    mapping (address => uint256) public deposits;
    mapping (address => State) public playerState;

    mapping (address => uint256) public maxNumOpponents;
    
    address[] public submittedPlayers;
    
    Diamond gotchiDiamond = Diamond(gotchiAddress);
    IERC721 aavegotchi = IERC721(gotchiAddress);

    ERC20 ghst = ERC20(0xeDaA788Ee96a0749a2De48738f5dF0AA88E99ab5);
    
    
    address public admin;
    
    constructor() {
        admin = msg.sender;
    }
    
    modifier onlyAdmin{
        require(msg.sender == admin);
        _;
    }
    
  
    
    function changeAdmin(address _admin) public onlyAdmin{
        admin = _admin;
    }
    
    function submitPortal(uint256 _portal/*, uint256 _maxNumOpponents*/) public{ //set 0 for unlimited?
        require(deposits[msg.sender] == 0, "You can only submit one portal at a time!");
        require((gotchiDiamond.getAavegotchi(_portal)).status == 0, "You can only submit closed portals");
        aavegotchi.safeTransferFrom(msg.sender,address(this),_portal,"");
        submittedPlayers.push(msg.sender);
        deposits[msg.sender] = _portal;
        playerState[msg.sender] = State.Submitted;
       // maxNumOpponents[msg.sender] = _maxNumOpponents;
    }
    
    function selectOpponent(address _opponent) public {
        
        //check that sender and opponent both submitted portals
        require(playerState[msg.sender] == State.Submitted, "You have not yet submitted a portal or already have an opponent!");
        require(playerState[_opponent] == State.Submitted, "Your opponent has not yet submitted a portal");
        
        //check that submitted portals are same hauntId
        require((gotchiDiamond.getAavegotchi(deposits[msg.sender])).hauntId == (gotchiDiamond.getAavegotchi(deposits[opponents[msg.sender]])).hauntId,"You and your opponent have different haunt portals!");
        
        //Commit the two players as each other's opponents
        opponents[msg.sender] = _opponent;
        opponents[_opponent] = msg.sender;
        playerState[msg.sender] = State.Committed;
        playerState[_opponent] = State.Committed;
    }
    
    //todo: selectOpponents

    function getOpponent() public view returns(address) {
        require(playerState[msg.sender] == State.Committed, "You are not yet in a matchup");
        return opponents[msg.sender];
    }
    
    //this function returns a sorted array of the BRS in a portal
    function getSortedBRS(PortalAavegotchiTraitsIO[PORTAL_AAVEGOTCHIS_NUM] memory portalAavegotchiTraits_) public view returns(uint256[PORTAL_AAVEGOTCHIS_NUM] memory _allBRS){
        
        uint256 BRS;
        //we get each BRS for each portal option
        for(uint i = 0; i < PORTAL_AAVEGOTCHIS_NUM; i++){
            BRS = gotchiDiamond.baseRarityScore(portalAavegotchiTraits_[i].numericTraits);
            _allBRS[i] = BRS;
        }
        
        //_allBRS is loaded up with all the BRS's, so now we sort
        _allBRS = sort(_allBRS);
    }

    
    function checkWinner() public returns(address _winner){
        
        //confirm that each portal is opened
        AavegotchiInfo memory firstPortal = gotchiDiamond.getAavegotchi(deposits[msg.sender]);
        require(firstPortal.status == 2, "one of the portals is not finished opening!");
        AavegotchiInfo memory secondPortal = gotchiDiamond.getAavegotchi(deposits[opponents[msg.sender]]);
        require(secondPortal.status == 2, "one of the portals is not finished opening!");
        
        //get a sorted array of BRS for each portal
        uint256[10] memory firstPortalBRS = getSortedBRS(gotchiDiamond.portalAavegotchiTraits(deposits[msg.sender]));
        uint256[10] memory secondPortalBRS = getSortedBRS(gotchiDiamond.portalAavegotchiTraits(deposits[opponents[msg.sender]]));

        //starting at the end of the ordered lists of BRS, go through and find the higher one
        for(uint i = 0; i<10; i++){
            if(firstPortalBRS[9-i] > secondPortalBRS[9-i]){
                playerState[msg.sender] = State.Winner;
                playerState[opponents[msg.sender]] = State.Loser;
                return msg.sender;
            }
            else if(firstPortalBRS[9-i] < secondPortalBRS[9-i]){
                playerState[msg.sender] = State.Loser;
                playerState[opponents[msg.sender]] = State.Winner;
                return opponents[msg.sender];
            }
        }
        
    }
    
    function sort(uint256[PORTAL_AAVEGOTCHIS_NUM] memory data) public pure returns(uint256[PORTAL_AAVEGOTCHIS_NUM] memory) {
       quickSort(data, int(0), int(data.length - 1));
       return data;
    }
    
    function quickSort(uint256[PORTAL_AAVEGOTCHIS_NUM] memory arr, int left, int right) internal pure{
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }
    
    function collectPrizes() public{
        
        //only a winner can call this
        require(playerState[msg.sender] == State.Winner, "Sorry you haven't won yet");
        
        //send the sender and opponent's portals to the sender
        aavegotchi.safeTransferFrom(address(this),msg.sender,deposits[msg.sender],"");        
        aavegotchi.safeTransferFrom(address(this),msg.sender,deposits[opponents[msg.sender]],"");        
        
        //re-set the player and opponent's states and other variables
        playerState[msg.sender] = State.Observer;
        playerState[opponents[msg.sender]] = State.Observer;
        deposits[msg.sender] = 0;
        deposits[opponents[msg.sender]] = 0;
        opponents[opponents[msg.sender]] = address(0);
        opponents[msg.sender] = address(0);

    }
    
    function openPortals() public{
        require(playerState[msg.sender] == State.Committed, "You are not in an active matchup");

        uint256[] memory portals = new uint256[](2);
        portals[0] = deposits[msg.sender];
        portals[1] = deposits[opponents[msg.sender]];
        gotchiDiamond.openPortals(portals);
    }


    function returnERC721(uint256 _tokenId) public onlyAdmin{
        
        aavegotchi.safeTransferFrom(address(this),msg.sender,_tokenId,"");        
    //todo: this should only allow admin to return to the owners
    }
    
    function returnERC721(address _returnee) public onlyAdmin{
        
        aavegotchi.safeTransferFrom(address(this),_returnee,deposits[_returnee],"");        
    }
    

    function returnGHST() public onlyAdmin{
        ghst.transfer(msg.sender, ghst.balanceOf(address(this)));
    }
    
   
    
    function onERC721Received(
        address, /* _operator */
        address, /*  _from */
        uint256, /*  _tokenId */
        bytes calldata /* _data */
    ) external pure  returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    
    
    
    
}