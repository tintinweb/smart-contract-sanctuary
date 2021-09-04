/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity ^0.5.17;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract IERC721Receiver {
    
    //support onERC721Received  
    //equl 'bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))''
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes public receivedData;
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4){
        receivedData = data;
        
        return _ERC721_RECEIVED;
    }
}

contract IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract Context {

    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract HfAuction is Ownable ,IERC721Receiver  {

    //pay token
    IERC20    public hfdToken     = IERC20(0x6c098aBF90E7BEd28C14b06B6bc0401003064840);
    //rewardToken hft
    IERC20    public rewardToken  = IERC20(0x3c91B301f80cCB055e97d2405523C95e72892D30);
    
    IERC721   public erc721token;
    
    uint256   public productCnt;
    uint256   public farmerCnt;
    
    uint256   public rewardsLimit    = 100000;
    uint256   public rewardsUsed;
    uint256   public rewardsPerTrans = 1e18;
    uint256   public starttime;
    
    
    struct Product{
        address owner;
        uint256 tokenId;
        uint256 price;
        uint256 starttime;
        uint256 duration;
        bool    onSale;
    }
    
    struct Farmer{
        address farmer;
        address farmerAddr;
        uint256 price;
        uint256 starttime;
        uint256 duration;
        bool    onSale;
    }
    
    mapping(uint256=>Product) public products;
    mapping(uint256=>Farmer)  public farmers;
    
    //event nftOnListed(uint256 tokenId, uint256 price);
    event nftOnListed(uint256 index,address owner,uint256 tokenId,uint256 price,uint256 starttime,uint256 duration,bool onSale);
    event buyNFTed(uint256 index ,address newOwner,uint256 price,uint256 rewardsPerTrans);
    event offListed(uint256 index,bool onSale);

    constructor(address _erc721) public{
        erc721token = IERC721(_erc721);
        starttime   = block.timestamp;
        productCnt  = 0;
        farmerCnt   = 0;
    }
    
    modifier updateRewardsLimit(){
        //100000 per day
        if((block.timestamp - starttime) > 86400){
            rewardsUsed = 0;
            starttime    = block.timestamp;
        }
        _;
    }
    
    modifier checkOnSale(uint256 index) {
        if(products[index].onSale == true){
            if(block.timestamp > (products[index].starttime + products[index].duration) ){
                offList(index);
            }
        }
        _;
    }
    
    function setRewardsLimit(uint256 newLimit) onlyOwner public {
        rewardsLimit = newLimit;
    }
    
    
    function setRewardsPerTrans(uint256 newReward) onlyOwner public {
        rewardsPerTrans = newReward;
    }
    
    //function offList() public
    
    function nftOnList(uint256 tokenId, uint256 price ) public returns(uint256 ) {
        
        require(erc721token.ownerOf( tokenId ) == msg.sender );
        require(price > 0);
        
        Product memory newProduct;
        newProduct.owner     = msg.sender;
        newProduct.tokenId   = tokenId;
        newProduct.price     = price;
        newProduct.starttime = block.timestamp;
        newProduct.duration  = 604800;
        newProduct.onSale    = true;
        
        uint256 index = productCnt + 1;
        
        products[index]      = newProduct;
        
        productCnt = index;
        
        erc721token.safeTransferFrom(msg.sender,address(this),tokenId);
        
        emit nftOnListed(index,msg.sender,tokenId,price,newProduct.starttime,newProduct.duration,newProduct.onSale);
        
    }
    
    function getProductCnt() public view returns(uint256) {
        return productCnt;
    }
    
    
    function doCheck(uint256 index) public checkOnSale(index) returns(bool) {
        return products[index].onSale;
    }
    
    
    function getProductByIndex(uint256 index) public view returns(address,uint256,uint256,uint256,uint256,bool){
        return (products[index].owner,products[index].tokenId,products[index].price,products[index].starttime,products[index].duration,products[index].onSale);
    }
    
    function buyNFT(uint256 index ,uint256 amount) public checkOnSale(index) updateRewardsLimit {
        require( products[index].onSale == true );
        //require( products[index].owner  != msg.sender );
        require( products[index].price  == amount );
        
        //products[index].onSale = false;
        //products[index].owner  = msg.sender;
        
        //pay price
        hfdToken.transferFrom(msg.sender,products[index].owner,amount);
        
        //change owner
        erc721token.safeTransferFrom(address(this),msg.sender,products[index].tokenId);
        products[index].owner  = msg.sender;
        
        //hfdToken.Transfer();
        
        products[index].onSale == false;
        
        //pay rewards
        if( rewardsUsed < rewardsLimit ){
            rewardToken.transfer(msg.sender,rewardsPerTrans);
            rewardsUsed += 1;
        }
        
        emit buyNFTed(index ,msg.sender,amount,rewardsPerTrans);
        
    }
    
    function offList( uint256 index )  internal {
        
        require(products[index].owner  != address(0));
        require(products[index].onSale == true );
        
        if(block.timestamp > (products[index].starttime + products[index].duration)){
            products[index].onSale         =  false;
            erc721token.safeTransferFrom(address(this),products[index].owner,products[index].tokenId);
        }

        //erc721token.safeTransferFrom(address(this),products[index].owner,products[index].tokenId);
        
        emit offListed(index,products[index].onSale);
        
    }
    
    function offListEmergency( uint256 index ) public onlyOwner {
        
        require(products[index].owner  != address(0));
        require(products[index].onSale == true );
        
        //Emergency offline
        products[index].onSale         =  false;
        erc721token.safeTransferFrom(address(this),products[index].owner,products[index].tokenId);
        
        
        //erc721token.safeTransferFrom(address(this),products[index].owner,products[index].tokenId);
        
        emit offListed(index,products[index].onSale);
        
    }
    
    
}