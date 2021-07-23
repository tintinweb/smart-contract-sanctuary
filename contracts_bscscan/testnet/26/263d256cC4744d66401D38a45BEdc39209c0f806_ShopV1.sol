pragma solidity  ^0.8.6;
// SPDX-License-Identifier: Apache-2.0

import "./ERC721.sol";
import "./ERC721Holder.sol";


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

    contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address sender = msg.sender;
        _owner = sender;
        emit OwnershipTransferred(address(0), sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


/*
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}*/

contract ShopV1 is Ownable, IERC721Receiver { 

    using SafeMath for uint256;
    using Address for address;

    //array an bids?

    uint256 saleId = 0;

    struct Sale {
        uint256 id;
        uint256 start;
        uint256 end; //maximal 1 Woche nach Start
        uint256 startPrice;
       //uint256 currentPrice;
        //uint256 instaBuyPrice;
        uint256 idFromNft;
        ERC721 nft;
        address payable artist;
        bool created;
        //bool sold; --> wir brauchen ja wsl eine claim funktion falls das nft nicht verkauft wird ums wieder zum owner zu transferieren, und mit ner kombi aus dem bool und der endverkaufszeit könnten wir checken ob er wieder claimen kann @scharief 
    }
    
    uint256 fee = 4;
    mapping (address => Sale[]) private salesOfCustomer; //for bidders
    mapping (uint256 => Sale) private salesMap;
    mapping (address => ERC721) depositedNFT; //wahrscheinlich unnötig

    Sale[] private onGoingSale;
    Sale[] private expiredSale;

    event startedSale (uint256 _id, uint256 _start, uint256 _end, uint256 _startPrice, uint256 _idFromNft, ERC721 _nft, address _customer);
    event NFTsold (address _from, address to, ERC721 nft, uint256 NFT_ID, uint256 price);
    event NFTwasDeposited(address _from, address to);

    constructor (){

    }

    function startSale (uint256 _startPrice, uint256 _idFromNft, ERC721 _nft) public payable{
        
        require (salesOfCustomer[msg.sender].length < 3, "Customer has already 3 ongoing Sales");
        require (_nft.ownerOf(_idFromNft) == address(this), "you did not deposit your nft yet");
        saleId += 1;
        uint256 _start = block.timestamp;
        uint256 _end = _start.add(7 days);
        if (_end.add(7 days) > _start) _end = _start.add(7 days);
        Sale memory _sale = Sale({id:saleId, start:_start, end:_end, startPrice: _startPrice, idFromNft: _idFromNft, nft:_nft, artist: payable(msg.sender), created: true});
        salesMap[saleId] = _sale;
        salesOfCustomer[msg.sender].push(_sale);
        emit startedSale(_sale.id, _sale.start, _sale.end, _sale.startPrice, _sale.idFromNft, _sale.nft, _sale.artist);
    }

    

    
    /* function depositNFT (ERC721 _nft, uint256 _idFromNft) public {
        _nft.approve(address(this), _idFromNft);
        _nft.safeTransferFrom(msg.sender, address(this), _idFromNft);
        if (_nft.ownerOf(_idFromNft) == address(this))
            emit NFTwasDeposited(msg.sender, address(this));
        //depositedNFT[msg.sender].push(_nft);
    } */
    
   function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    )   override
        external
        returns(bytes4)
    {
       depositedNFT[from] = (ERC721(msg.sender));
       //startSale (0, tokenId, ERC721(msg.sender));
       return this.onERC721Received.selector;
    }
    

    function buy (uint256 idFromSale) public payable {
        
        
        Sale memory currentSale = salesMap[idFromSale];
        require (msg.value == currentSale.startPrice, "wrong money");
        //TODO check if NFT is still on contract and if the time is between start and endtime

        uint256 _price = msg.value;
       
        ERC721 erc721NFT = ERC721(currentSale.nft);
        require (currentSale.startPrice == _price, "NFT costs more/less");
        
        //uint256 oldBalance = address(this).balance;
        currentSale.artist.transfer(_price);
        //uint256 newBalance = address(this).balance;
        //uint256 checkSentBnB = newBalance.sub(oldBalance);
        
        //send NFT from contract to buyer
        erc721NFT.approve( msg.sender, currentSale.idFromNft);
        erc721NFT.transferFrom(address(this), msg.sender, currentSale.idFromNft);

        //takeFee and sent money to artist
        uint256 _fee = _price.mul(fee).div(100);
        currentSale.artist.transfer(_price.sub(_fee));


        emit NFTsold (currentSale.artist,  msg.sender, currentSale.nft, currentSale.idFromNft, currentSale.startPrice);
    }

      function claim(address payable _address) external onlyOwner{
        _address.transfer(address(this).balance);
    }
    
    function send(address receiver, ERC721 _nft, uint256 _nftID) external onlyOwner{
        
        _nft.safeTransferFrom(address(this), receiver, _nftID);
        
    }

    function claimNFT (uint256 saleID) public returns (bool) { //so stell ich ma die claimNFT funktion vor @scharief
        Sale memory _sale = salesMap[saleID];
       require (_sale.artist == msg.sender, "You are not the one who created the sale");
       //require (_sale.sold == false, "your nft was successfully sold");
       require (_sale.end <= block.timestamp, "you can claim back as soon as the sale is over and if your nft is not sold at the end");
       ERC721 erc721NFT = ERC721(_sale.nft);
      require (erc721NFT.ownerOf(_sale.idFromNft) == address(this), "nft is not on the contract");

        //erc721NFT.approve(msg.sender, _sale._idFromNft);
        erc721NFT.transferFrom(address(this), msg.sender, _sale.idFromNft);

        if (erc721NFT.ownerOf(_sale.idFromNft) == msg.sender) return true;
        else return false;

    }
    
    function setFee(uint256 _newFee) external onlyOwner{
        fee = _newFee;
    }
    
        // -------------------getter zum testen -----------------------------------------
    function getSaleStartTime (uint256 _saleID) public view returns (uint256){
        return salesMap[_saleID].start;
    }
    
    function getSaleEndTime (uint256 _saleID) public view returns (uint256){
        return salesMap[_saleID].end;
    }
    
    function getSalePrice (uint256 _saleID) public view returns (uint256){
        return salesMap[_saleID].startPrice;
    }
    
    function getSaleIDfromNFT(uint256 _saleID) public view returns (uint256){
        return salesMap[_saleID].idFromNft;
    }
    
    function getSaleArtist(uint256 _saleID) public view returns (address){
        return salesMap[_saleID].artist;
    }
    
     function getdepositedNFT () public view returns (ERC721){
        return depositedNFT[msg.sender];
    }
    
    //----------------------------------------------------------------------------------------

    //function setFee
    //function create Sell
    //function to get on_going_Bids
    //function to get expiredBids
}