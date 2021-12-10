/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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

contract RiperLottery is Ownable, Pausable {
    bytes32 internal keyHash;
    uint256 internal fee;
    RiperNFT public  RiperNFTContract;
    mapping(address => bool) public whiteList;
    mapping(uint256 => uint256) public tierPrices;
    mapping(uint256 => bool) public lotteryNFTRecords;
    mapping(uint256 => address) public lotteryWinnerRecords;
    mapping(uint256 => bool) public lotteryResultSelected;

    uint256 public maxNumber = 50;    

    event LotteryEvent(address indexed from, uint256 nft1, uint256 nft2, uint256 lotteryNumber, bool isWinner);

    constructor() {                
        RiperNFTContract = RiperNFT(0x9447A30e610Ae865CA989886FE4df025BB5E11C8);
    }
    
    function putFundForPrice() external payable {        
    }

    function withdrawFund() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMaxNumber(uint256 _maxNumber) external onlyOwner{
        maxNumber = _maxNumber;
    }

    function getMaxNumber() external view returns (uint256) {
        return maxNumber;
    }

    function isNFTAvailable(address _holder, uint256 _tokenId) external view returns(bool) {
        require(RiperNFTContract.ownerOf(_tokenId) == _holder, "Not Owned.");
        if (lotteryNFTRecords[_tokenId] == true) return false;
        else return true;
    }

    function isInWhiteList(address _addr) external view returns (bool){
        return whiteList[_addr];
    }

    function getTierPrice(uint256 _tier) external view returns (uint256){
        return tierPrices[_tier];
    }

    function nftBalanceOf() external view returns(uint256) {
        return RiperNFTContract.balanceOf(msg.sender);
    }

    function nftTokenOfOwnerByIndex(uint256 _index) external view returns(uint256) {
        return RiperNFTContract.tokenOfOwnerByIndex(msg.sender, _index);
    }

    function setTierPrice(uint256[] memory _tierList, uint256[] memory _priceList) external onlyOwner {
        for (uint256 i = 0; i < _tierList.length; i++) {
            tierPrices[_tierList[i]] = _priceList[i];
        } 
    }

    function setWhiteList(address[] memory _list) external onlyOwner {
        for (uint256 i = 0; i < _list.length; i++) whiteList[_list[i]] = true;
    }

    function removeWhiteList(address[] memory _list) external onlyOwner {
        for (uint256 i = 0; i < _list.length; i++) whiteList[_list[i]] = false;
    }

    function runLottery(uint256 nft1, uint256 nft2) external whenNotPaused returns (uint256, bool){
        require(RiperNFTContract.ownerOf(nft1) == msg.sender, "Not owner of nft1");
        require(RiperNFTContract.ownerOf(nft2) == msg.sender, "Not owner of nft2");
        require(lotteryNFTRecords[nft1] != true, "nft1 is already used on Lottery.");
        require(lotteryNFTRecords[nft2] != true, "nft2 is already used on Lottery.");        
        uint256 lotteryNum = random(nft1, nft2, msg.sender);                
        bool isWinner = false;
        if (lotteryResultSelected[lotteryNum] != true){            
            if (lotteryNum < 50) {
                require(tierPrices[lotteryNum] > 0, "tier price is not set");
                require(address(this).balance > tierPrices[lotteryNum], "balance is not ready now");
                payable(msg.sender).transfer(tierPrices[lotteryNum]);
                isWinner = true;
            }
        }
        lotteryNFTRecords[nft1] = true;
        lotteryNFTRecords[nft2] = true;
        lotteryResultSelected[lotteryNum] = true;
        lotteryWinnerRecords[lotteryNum] = msg.sender;
        emit LotteryEvent(msg.sender, nft1, nft2, lotteryNum, isWinner);
        return (lotteryNum, isWinner);          
    }

    function runLotteryWhiteList(uint256 nft1) external whenNotPaused returns (uint256, bool){
        require(whiteList[msg.sender] == true, "Not in whitelist.");
        require(RiperNFTContract.ownerOf(nft1) == msg.sender, "Not owner of nft1");
        require(lotteryNFTRecords[nft1] != true, "ntf1 is already used on Lottery.");        
        uint256 lotteryNum = random(nft1, 0, msg.sender);                
        bool isWinner = false;
        if (lotteryResultSelected[lotteryNum] != true){            
            if (lotteryNum < 50) {
                require(tierPrices[lotteryNum] > 0, "tier price is not set");
                require(address(this).balance > tierPrices[lotteryNum], "price is not ready now");
                payable(msg.sender).transfer(tierPrices[lotteryNum]);
                isWinner = true;
            }
        }
        lotteryNFTRecords[nft1] = true;        
        lotteryResultSelected[lotteryNum] = true;
        lotteryWinnerRecords[lotteryNum] = msg.sender;
        emit LotteryEvent(msg.sender, nft1, 0, lotteryNum, isWinner);
        return (lotteryNum, isWinner);          
    }

    function random(uint256 nft1, uint256 nft2, address _sender) internal view returns (uint256){
        uint256 num = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _sender, nft1, nft2)));
        return num % maxNumber;
    }
}