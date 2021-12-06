/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

pragma solidity ^0.8.0;


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
        return msg.data;
    }
}
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface nft{
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract market is IERC721Receiver,Ownable{
    using SafeMath for uint256;
    event PutHero(uint256 tokenId,uint256 price,address user);
    event TakeHero(uint256 tokenId,address user);
    event TransactionHero(uint256 tokenId,address from,address to,uint256 price);
    
    event InquiryHero(uint256 tokenId,uint256 price,address user);
    event CancelInquiryHero(uint256 tokenId,uint256 buyPrice,address user);
    
    event PutEquipment(uint256 tokenId,uint256 price,address user);
    event TakeEquipment(uint256 tokenId,address user);
    event TransactionEquipment(uint256 tokenId,address from,address to,uint256 price);
    
    event InquiryEquipment(uint256 tokenId,uint256 price,address user);
    event CancelInquiryEquipment(uint256 tokenId,uint256 buyPrice,address user);
    
    address public heroAddress;
    address public equipmentAddress;
    
    address public _token = 0xCDaFb1c685AC8f4c398F1Af3F5d53D77379DB268;
    uint256 public _fee = 250;
    uint256 public _time = 57600;
    
    struct HeroInfo {
        uint256 sellPrice;
        address owner;
        address offer;
        uint256 buyPrice;
        uint256 buyBlock;
    }
    mapping (uint256 => HeroInfo) public heroInfo;
    
    
    struct EquipmentInfo {
        uint256 sellPrice;
        address owner;
        address offer;
        uint256 buyPrice;
        uint256 buyBlock;
    }
    mapping (uint256 => EquipmentInfo) public equipmentInfo;
    
    constructor(address hero_address,address equipment_address) Ownable(){
        heroAddress = hero_address;
        equipmentAddress = equipment_address;
    }
    
    modifier onlyUser(uint256 tokenId ,address _contract){
        require(nft(_contract).ownerOf(tokenId) == msg.sender, "Token Invalid");
        _;
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    function putHero(uint256 tokenId,uint256 price) public onlyUser(tokenId,heroAddress){
        HeroInfo storage info = heroInfo[tokenId];
        info.owner = msg.sender;
        info.sellPrice = price;
        nft(heroAddress).safeTransferFrom(msg.sender,address(this),tokenId);
        emit PutHero(tokenId,price,msg.sender);
    }
    
    function takeHero(uint256 tokenId) public{
        HeroInfo storage info = heroInfo[tokenId];
        require(info.owner == msg.sender && info.sellPrice>0, "Token Insufficient");
        info.owner = address(0);
        info.sellPrice = 0;
        if(info.offer!=address(0) && info.buyPrice != 0){
            IERC20(_token).transfer(info.offer,info.buyPrice);
        }
        info.offer = address(0);
        info.buyPrice = 0;
        nft(heroAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        emit TakeHero(tokenId,msg.sender);
    }
    
    function paymentHero(uint256 tokenId,uint256 price) public{
        HeroInfo storage info = heroInfo[tokenId];
        require(info.sellPrice == price && info.owner != msg.sender && price >0,"Insufficient");
        address from = info.owner;
        if(info.offer!=address(0) && info.buyPrice != 0){
            IERC20(_token).transfer(info.offer,info.buyPrice);
        }
        uint256 fee =  info.sellPrice/10000*_fee;
        IERC20(_token).transferFrom(msg.sender,owner(),fee);
        IERC20(_token).transferFrom(msg.sender,from,info.sellPrice-fee);
        info.owner = address(0);
        info.sellPrice = 0;
        info.offer = address(0);
        info.buyPrice = 0;
        nft(heroAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        emit TransactionHero(tokenId,from,msg.sender,price);
    }
    
    function inquiryHero(uint256 tokenId,uint256 price) public{
        HeroInfo storage info = heroInfo[tokenId];
        require(info.buyPrice < price && info.owner != msg.sender && info.sellPrice>0, "Token Insufficient");
        if(info.offer!=address(0) && info.buyPrice != 0){
            IERC20(_token).transferFrom(address(this),info.offer,info.buyPrice);
        }
        info.offer = msg.sender;
        info.buyPrice = price;
        info.buyBlock = block.number + _time;
        IERC20(_token).transferFrom(msg.sender,address(this),price);
        emit InquiryHero(tokenId,price,msg.sender);
    }
    
    function cancelInquiryHero(uint256 tokenId) public{
        HeroInfo storage info = heroInfo[tokenId];
        require(info.offer == msg.sender && info.buyPrice>0, "Token Insufficient");
        require(info.buyBlock < block.number, "During the restricted period");
        uint256 buyPrice = info.buyPrice;
        info.offer = address(0);
        info.buyPrice = 0;
        IERC20(_token).transfer(msg.sender,buyPrice);
        emit CancelInquiryHero(tokenId,buyPrice,msg.sender);
    }
    
    function sellHero(uint256 tokenId,uint256 price) public{
        HeroInfo storage info = heroInfo[tokenId];
        require(info.buyPrice == price && info.owner == msg.sender && price >0,"Insufficient");
        address to = info.offer;
        uint256 fee =  info.buyPrice/10000*_fee;
        IERC20(_token).transfer(owner(),fee);
        IERC20(_token).transfer(info.owner,info.buyPrice-fee);
        info.owner = address(0);
        info.sellPrice = 0;
        info.offer = address(0);
        info.buyPrice = 0;
        nft(heroAddress).safeTransferFrom(address(this),to,tokenId);
        emit TransactionHero(tokenId,msg.sender,to,price);
    }
    
    
    function putEquipment(uint256 tokenId,uint256 price) public onlyUser(tokenId,equipmentAddress){
        EquipmentInfo storage info = equipmentInfo[tokenId];
        info.owner = msg.sender;
        info.sellPrice = price;
        nft(equipmentAddress).safeTransferFrom(msg.sender,address(this),tokenId);
        emit PutEquipment(tokenId,price,msg.sender);
    }
    
    function takeEquipment(uint256 tokenId) public{
        EquipmentInfo storage info = equipmentInfo[tokenId];
        require(info.owner == msg.sender && info.sellPrice>0, "Token Insufficient");
        info.owner = address(0);
        info.sellPrice = 0;
        if(info.offer!=address(0) && info.buyPrice != 0){
            IERC20(_token).transfer(info.offer,info.buyPrice);
        }
        info.offer = address(0);
        info.buyPrice = 0;
        nft(equipmentAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        emit TakeEquipment(tokenId,msg.sender);
    }
    
    function paymentEquipment(uint256 tokenId,uint256 price) public{
        EquipmentInfo storage info = equipmentInfo[tokenId];
        require(info.sellPrice == price && info.owner != msg.sender && price >0,"Insufficient");
        address from = info.owner;
        if(info.offer!=address(0) && info.buyPrice != 0){
            IERC20(_token).transfer(info.offer,info.buyPrice);
        }
        uint256 fee =  info.sellPrice/10000*_fee;
        IERC20(_token).transferFrom(msg.sender,owner(),fee);
        IERC20(_token).transferFrom(msg.sender,from,info.sellPrice-fee);
        info.owner = address(0);
        info.sellPrice = 0;
        info.offer = address(0);
        info.buyPrice = 0;
        nft(equipmentAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        emit TransactionEquipment(tokenId,from,msg.sender,price);
    }
    
    function inquiryEquipment(uint256 tokenId,uint256 price) public{
        EquipmentInfo storage info = equipmentInfo[tokenId];
        require(info.buyPrice < price && info.owner != msg.sender && info.sellPrice>0, "Token Insufficient");
        if(info.offer!=address(0) && info.buyPrice != 0){
            IERC20(_token).transferFrom(address(this),info.offer,info.buyPrice);
        }
        info.offer = msg.sender;
        info.buyPrice = price;
        info.buyBlock = block.number + _time;
        IERC20(_token).transferFrom(msg.sender,address(this),price);
        emit InquiryEquipment(tokenId,price,msg.sender);
    }
    
    function cancelInquiryEquipment(uint256 tokenId) public{
        EquipmentInfo storage info = equipmentInfo[tokenId];
        require(info.offer == msg.sender && info.buyPrice>0, "Token Insufficient");
        require(info.buyBlock < block.number, "During the restricted period");
        uint256 buyPrice = info.buyPrice;
        info.offer = address(0);
        info.buyPrice = 0;
        IERC20(_token).transfer(msg.sender,buyPrice);
        emit CancelInquiryEquipment(tokenId,buyPrice,msg.sender);
    }
    
    function sellEquipment(uint256 tokenId,uint256 price) public{
        EquipmentInfo storage info = equipmentInfo[tokenId];
        require(info.buyPrice == price && info.owner == msg.sender && price >0,"Insufficient");
        address to = info.offer;
        uint fee =  info.buyPrice/10000*_fee;
        IERC20(_token).transfer(owner(),fee);
        IERC20(_token).transfer(info.owner,info.buyPrice-fee);
        info.owner = address(0);
        info.sellPrice = 0;
        info.offer = address(0);
        info.buyPrice = 0;
        nft(equipmentAddress).safeTransferFrom(address(this),to,tokenId);
        emit TransactionEquipment(tokenId,msg.sender,to,price);
    }

    function payToken() public view returns(uint256,address){
        return(_fee,_token);
    }

    function setFeeAndToken(uint256 fee,address token) public onlyOwner{
        _fee = fee;
        _token = token;
    }

    function setTime(uint256 time) public onlyOwner{
        _time = time;
    }
}