/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
// Part: PandaNFT

interface RiperNFT {
	function balanceOf(address _user) external view returns(uint256);
	function ownerOf(uint256 tokenId) external view returns (address owner);
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId                
    ) external;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @title Ownable
 * @dev Ownable has an owner address to simplify "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * Ownable
   * @dev Ownable constructor sets the `owner` of the contract to sender
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * ownerOnly
   * @dev Throws an error if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * transferOwnership
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), 'Pausable: paused');
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), 'Pausable: not paused');
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract RiperAuction is Ownable, Pausable {
    RiperNFT public  RiperNFTContract;
    uint256 public startTimeAuction;
    uint256 public endTimeAuction;
    uint256 public minAuctionAmount=0;    
    uint256[3] public nftTokenIds;
    mapping (uint256 => uint256) maxBids;
    mapping(uint256 => address) winners;    
    mapping(address => bool) endedAuctions;    

    struct Auction { // Struct        
        mapping (uint256 => uint256) info;
    }

    mapping(address => Auction) auctions;

    constructor() {                
        RiperNFTContract = RiperNFT(0x9447A30e610Ae865CA989886FE4df025BB5E11C8);
    }

    function getWinner(uint256 _tokenId) external view returns (address) {
        return winners[_tokenId];
    }

    function getAuctionPeriod() external view returns (uint256, uint256) {
        return (startTimeAuction, endTimeAuction);
    }

    function setAuctionPeriod(uint256 _startTimeAuction, uint256 _endTimeAuction) external onlyOwner {
        startTimeAuction = _startTimeAuction;
        endTimeAuction = _endTimeAuction;
    }

    function setAuctionMinAmount(uint256 _minAuctionAmount) external onlyOwner {
        minAuctionAmount = _minAuctionAmount;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw(uint256 tokenId) external onlyOwner {
        RiperNFTContract.transferFrom(address(this), msg.sender, tokenId);     
    }

    function startAuction(uint256 tokenId1, uint256 tokenId2, uint256 tokenId3) external onlyOwner {    
       require(startTimeAuction > 0, "AuctionTime need to be set up.");
       require(endTimeAuction > 0, "AuctionTime need to be set up.");
       uint256 tokenCount = RiperNFTContract.balanceOf(address(this));
       require(tokenCount == 3, "Contract is not ready for auction assets");       
       for (uint256 i=0; i < tokenCount; i++){
           uint256 tokenId = RiperNFTContract.tokenOfOwnerByIndex(address(this), i);
           bool token_existed = false; 
           for (uint256 j=0; j<3; j++){
               if (nftTokenIds[j] == tokenId){
                   token_existed = true;
               }
           }
           require(token_existed == true, "Asset is not exist on the contract");
       }    
       nftTokenIds[0] = tokenId1;
       nftTokenIds[1] = tokenId2;
       nftTokenIds[2] = tokenId3;       
       _unpause();
    }

    function endAuction(uint256 tokenId) external whenNotPaused {
        require(block.timestamp >= endTimeAuction, "Auction should be ended.");        
        require(endedAuctions[msg.sender] != true, "You already ended auction.");
        if (winners[tokenId] == msg.sender){
            RiperNFTContract.transferFrom(address(this), msg.sender, tokenId);                    
        } else {
            require(auctions[msg.sender].info[tokenId] > 0, "You are not bidder for this NFT");
            payable(msg.sender).transfer(auctions[msg.sender].info[tokenId]);            
        }
        endedAuctions[msg.sender] = true;    
    }

    function bidAuction(uint256 tokenId) external whenNotPaused payable {
        require(msg.value >= minAuctionAmount, "Auction Amount should be higher than min amount.");           
        require(block.timestamp >= startTimeAuction, "Auction should be started.");        
        require(block.timestamp <= endTimeAuction, "Auction should be started.");        
        require(msg.value > maxBids[tokenId], "Auction Amount should be higher than past bids.");
        auctions[msg.sender].info[tokenId] = auctions[msg.sender].info[tokenId] + msg.value;        
        maxBids[tokenId] = msg.value;
        winners[tokenId] = msg.sender;
    }   
}