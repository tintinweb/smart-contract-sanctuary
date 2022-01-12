/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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


contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
    );
    
    constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
    return _owner;
    }
    
    modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
    }
    
    function isOwner() public view returns (bool) {
    return msg.sender == _owner;
    }
    
    function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
    require(
    newOwner != address(0), 
    "Ownable: new owner is the zero address"
    );
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
    }
}


interface stakePool{
    function totalTicket(address _address) external view returns(uint256);
}


contract mysterybox is Ownable{
    
    uint256 public mysteryboxCounter=0;
    uint256 public boxesCounter =0;
    uint256 public itemcounter =0;

     mapping(address => mapping(uint256 => uint256[])) private UsersBoxes;         
    //nested mapping from user address and mysterybox id which gives us boxes user has opened particular mysterybox

    struct MysteryBox {
        uint256 mysteryBoxId;           //particular mysterybox id
        string Name;
        uint256 itemCount;              //totalitems offered in mysterybox
        uint256[] itemArr;              //stores the value which represent item structure
        uint256 totalTreasureBoxes;     // how many boxes available
        uint256 claimTime;              //to set time for claimimg the treaurybox
        uint256 availableBoxes;         //to maintain count of how many boxes left in particular mysterybox
        uint256[] openBoxList;          //list of boxes user has opened
        uint256[] claimedBoxList;      //list of treasury boxes which user has get
        uint256 startTime;
        uint256 endTime;
    }

    struct Items{
        uint256 itemId;                 //unique id represent each item
        uint256 mysteryboxId;
        bool isERC20;                //itemtype is ERC20 or not
        bool isERC721;              //itemtype is ERC721 or not
        bool isAirdrop;
        string itemName;                //name of particular item
        uint256 itemAmountERC20;                 //actual ERC20 token offering in item
        uint256 itemValue;                 //item value which we get by offer particular item to user
        uint256 count;                  //total items available in pool
        IERC20 tokenAddERC20;
        IERC721 tokenAddERC721;
        uint256[] NFTIdarr;
        uint256 NFTIdclaimedcounter;
        address[] airDropUserArray;

    }

    struct Box{
        uint256 boxid;              //unique id for box 
        address userAddress;        //user address which shows the particular user who has opened that box
        uint256 mysteryBoxId;       //to map with particular mysterybox 
        uint256 offereditemId;                //item offered to that particular box
        string offereditemName;
        uint256 startTimestamp;     //timestamp when that particular box is allocated
        uint256 endTimestamp;       //timestamp when the duration of claiming this box is over
        bool isclaimed;             //to check that opened box is claimed by user or not
        bool boxDiscardedFrompool;
    }

    mapping (uint256 => Items) public ItemList;

    mapping (uint256 => MysteryBox) public mysteryBoxes;

    mapping (uint256 => Box) public boxes;

    address public holdWallet;
    
    function setHoldingadd(address _holdWallet) public onlyOwner{
        holdWallet = _holdWallet;
    }

    IERC20 public BAKED = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);

    address public stakePoolAddr;

    function setstakepool(address _stakepooladdr) public onlyOwner{
        stakePoolAddr= _stakepooladdr;
    }
    
    event createMysteryBox(string mysteryBoxName,
    uint256 mysteryBoxId,
    uint256 startTime,
    uint256 endTime);

    event setitem(uint256 mysteryboxId, uint256 itemId,string itemName);
    event openBox(uint256 mysteryboxId,uint256 boxid,address userAddress);
    event claimBox(uint256 mysteryboxId,uint256 boxid,address userAddress);

    function createmysterybox(string memory _mysteryBoxName,
    uint256 _boxclaimTime,
    uint256 _startTime,
    uint256 _endTime) 
    public onlyOwner returns(uint256)
    {
        mysteryboxCounter++;
        emit createMysteryBox(_mysteryBoxName,mysteryboxCounter,_startTime,_endTime);
        mysteryBoxes[mysteryboxCounter].mysteryBoxId = mysteryboxCounter;
        mysteryBoxes[mysteryboxCounter].Name = _mysteryBoxName;
        mysteryBoxes[mysteryboxCounter].claimTime = _boxclaimTime;
        mysteryBoxes[mysteryboxCounter].startTime = _startTime;
        mysteryBoxes[mysteryboxCounter].endTime = _endTime;
        return mysteryboxCounter;
    }

    function setItem(
        uint256 _mysteryid,
        string[] memory _itemName,
        bool[] memory _itemisERC20,
        bool[] memory _itemisERC721,
        bool[] memory _isAirdrop, 
        uint256[] memory _itemAmount,
        uint256[] memory _itemValue,
        uint256[] memory _itemCount,
        IERC20[] memory _tokenaddERC20,
        IERC721[] memory _tokenAddERC721,
        uint256[][] memory _NFTtokenArr)
     
     public onlyOwner {
        require(mysteryBoxes[_mysteryid].startTime>block.timestamp,"you can not enter value after start time");
        uint256 i;
        for(i=0;i<_itemName.length;i++){
            ItemList[itemcounter].mysteryboxId = _mysteryid;
            ItemList[itemcounter].itemId = itemcounter;
            ItemList[itemcounter].isERC20 = _itemisERC20[i];
            ItemList[itemcounter].isERC721 = _itemisERC721[i];
            ItemList[itemcounter].isAirdrop = _isAirdrop[i];
            ItemList[itemcounter].itemName = _itemName[i];
            ItemList[itemcounter].itemAmountERC20 = _itemAmount[i];
            ItemList[itemcounter].count = _itemCount[i];
            ItemList[itemcounter].itemValue = _itemValue[i];
            ItemList[itemcounter].tokenAddERC20 = _tokenaddERC20[i];
            ItemList[itemcounter].tokenAddERC721 = _tokenAddERC721[i];
            ItemList[itemcounter].NFTIdarr = _NFTtokenArr[i];
            emit setitem(_mysteryid,itemcounter,_itemName[i]);
            mysteryBoxes[_mysteryid].itemArr.push(itemcounter);
            mysteryBoxes[_mysteryid].itemCount += 1;
            mysteryBoxes[_mysteryid].totalTreasureBoxes =mysteryBoxes[_mysteryid].totalTreasureBoxes + _itemCount[i];
            mysteryBoxes[_mysteryid].availableBoxes =mysteryBoxes[_mysteryid].availableBoxes + _itemCount[i];
            itemcounter++;        
        }

    }
    
    function buyTreasurybox(uint256 _mysteryBoxId) public returns ( uint256) {    
        address _addr =msg.sender;
        require(mysteryBoxes[_mysteryBoxId].startTime<block.timestamp,"mysterybox is not started yet");
        require(mysteryBoxes[_mysteryBoxId].endTime>block.timestamp,"mysterybox is ended");
        require(totalticket(_addr) > (UsersBoxes[msg.sender][_mysteryBoxId]).length,"user is not having enough ticket");
        if(mysteryBoxes[_mysteryBoxId].availableBoxes==0 && 
        (mysteryBoxes[_mysteryBoxId].claimedBoxList.length != mysteryBoxes[_mysteryBoxId].totalTreasureBoxes))
        {
            isBoxClaimed(_mysteryBoxId);
        }       
        require( mysteryBoxes[_mysteryBoxId].availableBoxes > 0,"boxes not available");
        require(mysteryBoxes[_mysteryBoxId].claimedBoxList.length != mysteryBoxes[_mysteryBoxId].totalTreasureBoxes, "all boxes are claimed" );
        
        
        boxesCounter++;
        uint256 _item = randomItem(_mysteryBoxId);
        boxes[boxesCounter].boxid = boxesCounter;
        boxes[boxesCounter].mysteryBoxId = _mysteryBoxId;
        boxes[boxesCounter].offereditemId = _item;
        boxes[boxesCounter].offereditemName = ItemList[_item].itemName;
        boxes[boxesCounter].userAddress = msg.sender;
        boxes[boxesCounter].startTimestamp = block.timestamp;
        boxes[boxesCounter].endTimestamp = block.timestamp + mysteryBoxes[_mysteryBoxId].claimTime ;
        mysteryBoxes[_mysteryBoxId].openBoxList.push(boxesCounter);
        mysteryBoxes[_mysteryBoxId].availableBoxes =  mysteryBoxes[_mysteryBoxId].availableBoxes - 1;
        ItemList[_item].count = ItemList[_item].count - 1;
        UsersBoxes[msg.sender][_mysteryBoxId].push(boxesCounter);
        emit openBox(_mysteryBoxId,boxesCounter,msg.sender);
        return boxesCounter;
        
     }


    function claimTreasuryBox(uint256 _boxId) public{        
        require(boxes[_boxId].userAddress == msg.sender,"you are not owner of this box");
        require(boxes[_boxId].endTimestamp > block.timestamp,"claiming time is over");
        require(boxes[_boxId].isclaimed == false,"box is already claimed");
        uint256 _itemTemp = boxes[_boxId].offereditemId;
        uint256 counter;

        if(ItemList[_itemTemp].isAirdrop){
            
            ItemList[_itemTemp].airDropUserArray.push(msg.sender);
            boxes[_boxId].isclaimed = true;
            mysteryBoxes[boxes[_boxId].mysteryBoxId].claimedBoxList.push(_boxId);
        }
        else
        {
            if(ItemList[_itemTemp].itemValue == 0){
                
                if(ItemList[_itemTemp].isERC20 && ItemList[_itemTemp].isERC721){
                    IERC20(ItemList[_itemTemp].tokenAddERC20).transferFrom(holdWallet,msg.sender,(ItemList[_itemTemp].itemAmountERC20)* 1e18);
                    counter = ItemList[_itemTemp].NFTIdclaimedcounter;
                    IERC721(ItemList[_itemTemp].tokenAddERC721).safeTransferFrom(holdWallet,msg.sender,ItemList[_itemTemp].NFTIdarr[counter]);
                    ItemList[_itemTemp].NFTIdclaimedcounter = counter++;
                    boxes[_boxId].isclaimed = true;
                    mysteryBoxes[boxes[_boxId].mysteryBoxId].claimedBoxList.push(_boxId);
                }
                else{
                    if(ItemList[_itemTemp].isERC20){
                        IERC20(ItemList[_itemTemp].tokenAddERC20).transferFrom(holdWallet,msg.sender,(ItemList[_itemTemp].itemAmountERC20)* 1e18);
                        boxes[_boxId].isclaimed = true;
                        mysteryBoxes[boxes[_boxId].mysteryBoxId].claimedBoxList.push(_boxId);
                        
                    }
                    else{
                        counter = ItemList[_itemTemp].NFTIdclaimedcounter;
                        IERC721(ItemList[_itemTemp].tokenAddERC721).safeTransferFrom(holdWallet,msg.sender,ItemList[_itemTemp].NFTIdarr[counter]);
                        ItemList[_itemTemp].NFTIdclaimedcounter = counter++;
                        boxes[_boxId].isclaimed = true;
                        mysteryBoxes[boxes[_boxId].mysteryBoxId].claimedBoxList.push(_boxId);  
                    }
                }

            }
            else{

                if(ItemList[_itemTemp].isERC20 && ItemList[_itemTemp].isERC721){

                    IERC20(BAKED).transferFrom(msg.sender,holdWallet,(ItemList[_itemTemp].itemValue)* 1e18);
                    IERC20(ItemList[_itemTemp].tokenAddERC20).transferFrom(holdWallet,msg.sender,(ItemList[_itemTemp].itemAmountERC20)* 1e18);
                    counter = ItemList[_itemTemp].NFTIdclaimedcounter;
                    IERC721(ItemList[_itemTemp].tokenAddERC721).safeTransferFrom(holdWallet,msg.sender,ItemList[_itemTemp].NFTIdarr[counter]);
                    ItemList[_itemTemp].NFTIdclaimedcounter = counter++;
                    boxes[_boxId].isclaimed = true;
                    mysteryBoxes[boxes[_boxId].mysteryBoxId].claimedBoxList.push(_boxId);
                }
                else{
                    if(ItemList[_itemTemp].isERC20){

                        IERC20(BAKED).transferFrom(msg.sender,holdWallet,(ItemList[_itemTemp].itemValue)* 1e18);
                        IERC20(ItemList[_itemTemp].tokenAddERC20).transferFrom(holdWallet,msg.sender,(ItemList[_itemTemp].itemAmountERC20)* 1e18);
                        boxes[_boxId].isclaimed = true;
                        mysteryBoxes[boxes[_boxId].mysteryBoxId].claimedBoxList.push(_boxId);
                        
                    }
                    else{
                        IERC20(BAKED).transferFrom(msg.sender,holdWallet,(ItemList[_itemTemp].itemValue)* 1e18);
                        counter = ItemList[_itemTemp].NFTIdclaimedcounter;
                        IERC721(ItemList[_itemTemp].tokenAddERC721).safeTransferFrom(holdWallet,msg.sender,ItemList[_itemTemp].NFTIdarr[counter]);
                        ItemList[_itemTemp].NFTIdclaimedcounter = counter++;
                        boxes[_boxId].isclaimed = true;
                        mysteryBoxes[boxes[_boxId].mysteryBoxId].claimedBoxList.push(_boxId);  
                    }
                }

            }
        }

        emit claimBox(boxes[_boxId].mysteryBoxId,_boxId,msg.sender);
    }

    function isBoxClaimed(uint256 _mysteryBoxId) private{
        uint256 i;
        for(i=0;i<mysteryBoxes[_mysteryBoxId].openBoxList.length;i++){
            isBoxClaimed(mysteryBoxes[_mysteryBoxId].openBoxList[i]);
            uint256 _boxId =mysteryBoxes[_mysteryBoxId].openBoxList[i];
            if(boxes[_boxId].isclaimed==false && (boxes[_boxId].endTimestamp)>block.timestamp){
                mysteryBoxes[boxes[_boxId].mysteryBoxId].availableBoxes = mysteryBoxes[boxes[_boxId].mysteryBoxId].availableBoxes + 1;
                ItemList[boxes[_boxId].offereditemId].count = ItemList[boxes[_boxId].offereditemId].count + 1;
                boxes[_boxId].boxDiscardedFrompool = true; 
            }
        }    
    }

    function randomItem(uint256 _mysteryBoxId) private view returns(uint256){
        bool itemAvailable = false;
        uint256 randomNum;
        uint256 itemOffer;
        do{
            randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % mysteryBoxes[_mysteryBoxId].itemCount;
            itemOffer = mysteryBoxes[_mysteryBoxId].itemArr[randomNum];
            if( ItemList[itemOffer].count > 0)
            {
                itemAvailable = true;
                return itemOffer;
            }
        }while(itemAvailable == false);

    }

    function allItems(uint256 _mysteryid) public view returns (uint256[] memory){
            return mysteryBoxes[_mysteryid].itemArr;
    }

    function openBoxCount(uint256 _mysteryid) public view returns (uint256){
            return mysteryBoxes[_mysteryid].openBoxList.length;
    }

    function claimBoxCount(uint256 _mysteryid) public view returns (uint256){
            return mysteryBoxes[_mysteryid].claimedBoxList.length;
    }

    function airdropList(uint256 itemID) public onlyOwner view returns (address[] memory){
        require(ItemList[itemID].isAirdrop,"this item is not airdrop");
        return ItemList[itemID].airDropUserArray;
    }

    function totalticket(address _address) public view returns(uint256){
        return stakePool(stakePoolAddr).totalTicket(_address);
    }

    function UserTreasuryBoxes(address _address, uint256 _mystryId) public view returns(uint256[] memory){
        return UsersBoxes[_address][_mystryId];
    }
    
}