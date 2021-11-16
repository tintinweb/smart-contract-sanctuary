/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

pragma solidity ^0.8.0;
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

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

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

contract market is IERC721Receiver{
    using SafeMath for uint256;
    event PutHero(uint256 tokenId,uint256 price,address user);
    event TakeHero(uint256 tokenId,address user);
    event TransactionHero(address from,address to,uint256 price);
    
    event InquiryHero(uint256 tokenId,uint256 price,address user);
    event CancelInquiryHero(uint256 tokenId,uint256 buyPrice,address user);
    
    event PutEquipment(uint256 tokenId,uint256 price,address user);
    event TakeEquipment(uint256 tokenId,address user);
    event TransactionEquipment(address from,address to,uint256 price);
    
    event InquiryEquipment(uint256 tokenId,uint256 price,address user);
    event CancelInquiryEquipment(uint256 tokenId,uint256 buyPrice,address user);
    
    address public heroAddress;
    address public equipmentAddress;
    
    address public _wbnb = 0xAB58e408A73A2Ad27103df97c506EE90194086E9;
    
    struct HeroInfo {
        uint256 sellPrice;
        address owner;
        address offer;
        uint256 buyPrice;
    }
    mapping (uint256 => HeroInfo) public heroInfo;
    
    
    struct EquipmentInfo {
       uint256 sellPrice;
        address owner;
        address offer;
        uint256 buyPrice;
    }
    mapping (uint256 => EquipmentInfo) public equipmentInfo;
    
    constructor(address hero_address,address equipment_address) public {
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
        HeroInfo storage heroInfo = heroInfo[tokenId];
        heroInfo.owner = msg.sender;
        heroInfo.sellPrice = price;
        nft(heroAddress).safeTransferFrom(msg.sender,address(this),tokenId);
        emit PutHero(tokenId,price,msg.sender);
    }
    
    function takeHero(uint256 tokenId) public{
        HeroInfo storage heroInfo = heroInfo[tokenId];
        require(heroInfo.owner == msg.sender, "Token Insufficient");
        heroInfo.owner = address(0);
        heroInfo.sellPrice = 0;
        if(heroInfo.offer!=address(0) && heroInfo.buyPrice != 0){
            IERC20(_wbnb).transferFrom(address(this),heroInfo.offer,heroInfo.buyPrice);
        }
        heroInfo.offer = address(0);
        heroInfo.buyPrice = 0;
        nft(heroAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        emit TakeHero(tokenId,msg.sender);
    }
    
    function paymentHero(uint256 tokenId,uint256 price) public{
        HeroInfo storage heroInfo = heroInfo[tokenId];
        require(heroInfo.sellPrice == price,"Insufficient");
        address from = heroInfo.owner;
        IERC20(_wbnb).transferFrom(msg.sender,from,heroInfo.sellPrice);
        heroInfo.owner = address(0);
        heroInfo.sellPrice = 0;
        heroInfo.offer = address(0);
        heroInfo.buyPrice = 0;
        nft(heroAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        emit TransactionHero(from,msg.sender,heroInfo.sellPrice);
    }
    
    function inquiryHero(uint256 tokenId,uint256 price) public{
        HeroInfo storage heroInfo = heroInfo[tokenId];
        require(heroInfo.buyPrice < price, "Token Insufficient");
        IERC20(_wbnb).transferFrom(address(this),heroInfo.offer,heroInfo.buyPrice);
        
        heroInfo.offer = msg.sender;
        heroInfo.buyPrice = price;
        IERC20(_wbnb).transferFrom(msg.sender,address(this),price);
        emit InquiryHero(tokenId,price,msg.sender);
    }
    
    function cancelInquiryHero(uint256 tokenId) public{
        HeroInfo storage heroInfo = heroInfo[tokenId];
        require(heroInfo.offer == msg.sender, "Token Insufficient");
        uint256 buyPrice = heroInfo.buyPrice;
        heroInfo.offer = address(0);
        heroInfo.buyPrice = 0;
        IERC20(_wbnb).transferFrom(address(this),msg.sender,buyPrice);
        emit CancelInquiryHero(tokenId,buyPrice,msg.sender);
    }
    
    function sellHero(uint256 tokenId,uint256 price) public onlyUser(tokenId,heroAddress){
        HeroInfo storage heroInfo = heroInfo[tokenId];
        require(heroInfo.buyPrice == price,"Insufficient");
        address to = heroInfo.owner;
        IERC20(_wbnb).transferFrom(msg.sender,to,heroInfo.buyPrice);
        heroInfo.owner = address(0);
        heroInfo.sellPrice = 0;
        heroInfo.offer = address(0);
        heroInfo.buyPrice = 0;
        nft(heroAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        emit TransactionHero(msg.sender,to,heroInfo.sellPrice);
    }
    
    
    function putEquipment(uint256 tokenId,uint256 price) public onlyUser(tokenId,equipmentAddress){
        HeroInfo storage heroInfo = heroInfo[tokenId];
        heroInfo.owner = msg.sender;
        heroInfo.sellPrice = price;
        nft(equipmentAddress).safeTransferFrom(msg.sender,address(this),tokenId);
        emit PutEquipment(tokenId,price,msg.sender);
    }
    
    function takeEquipment(uint256 tokenId) public{
        HeroInfo storage heroInfo = heroInfo[tokenId];
        require(heroInfo.owner == msg.sender, "Token Insufficient");
        heroInfo.owner = address(0);
        heroInfo.sellPrice = 0;
        nft(equipmentAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        emit TakeEquipment(tokenId,msg.sender);
    }
    
    function paymentEquipment(uint256 tokenId) public{
        HeroInfo storage heroInfo = heroInfo[tokenId];
        address from = heroInfo.owner;
        IERC20(_wbnb).transferFrom(msg.sender,from,heroInfo.sellPrice);
        heroInfo.owner = address(0);
        heroInfo.sellPrice = 0;
        heroInfo.offer = address(0);
        heroInfo.buyPrice = 0;
        nft(equipmentAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        emit TransactionEquipment(from,msg.sender,heroInfo.sellPrice);
    }
    
    function inquiryEquipment(uint256 tokenId,uint256 price) public{
        HeroInfo storage heroInfo = heroInfo[tokenId];
        require(heroInfo.buyPrice < price, "Token Insufficient");
        IERC20(_wbnb).transferFrom(address(this),heroInfo.offer,heroInfo.buyPrice);
        
        heroInfo.offer = msg.sender;
        heroInfo.buyPrice = price;
        IERC20(_wbnb).transferFrom(msg.sender,address(this),price);
        emit InquiryEquipment(tokenId,price,msg.sender);
    }
    
    function cancelInquiryEquipment(uint256 tokenId) public{
        HeroInfo storage heroInfo = heroInfo[tokenId];
        require(heroInfo.offer == msg.sender, "Token Insufficient");
        uint256 buyPrice = heroInfo.buyPrice;
        heroInfo.offer = address(0);
        heroInfo.buyPrice = 0;
        IERC20(_wbnb).transferFrom(address(this),msg.sender,buyPrice);
        emit CancelInquiryEquipment(tokenId,buyPrice,msg.sender);
    }
    
    function sellEquipment(uint256 tokenId) public onlyUser(tokenId,equipmentAddress){
        HeroInfo storage heroInfo = heroInfo[tokenId];
        address to = heroInfo.owner;
        IERC20(_wbnb).transferFrom(msg.sender,to,heroInfo.sellPrice);
        heroInfo.owner = address(0);
        heroInfo.sellPrice = 0;
        heroInfo.offer = address(0);
        heroInfo.buyPrice = 0;
        nft(equipmentAddress).safeTransferFrom(address(this),msg.sender,tokenId);
        emit TransactionEquipment(msg.sender,to,heroInfo.sellPrice);
    }
   
}