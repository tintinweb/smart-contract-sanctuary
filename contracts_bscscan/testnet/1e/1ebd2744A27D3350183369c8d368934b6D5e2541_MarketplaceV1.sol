pragma solidity  ^0.8.6;
// SPDX-License-Identifier: Apache-2.0

import "./ERC721.sol";


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

contract MarketplaceV1 is Ownable, IERC721Receiver { 

    using SafeMath for uint256;
    using Address for address;


    uint256 saleCount = 0;
    uint256 maxRunningSales = 3;
    uint256 endTime = 7 days;
    
    uint8 status_openForSale = 1;
    uint8 status_sold = 2;
    uint8 status_closedbycustomer = 3;
    uint8 status_closedbyadmin = 4;

    struct Sale {
        uint256 id;
        uint256 start;
        //uint256 end; //maximal 1 Woche nach Start
        uint256 startPrice;
        uint256 idFromNft;
        ERC721 nft;
        address payable seller;
        //1 => openforsale; 2 => sold; 3 => closedbycustomer 4 => closedbyadmin
        uint8 status; //--> wir brauchen ja wsl eine claim funktion falls das nft nicht verkauft wird ums wieder zum owner zu transferieren, und mit ner kombi aus dem bool und der endverkaufszeit könnten wir checken ob er wieder claimen kann @scharief 
        bool active;
    }
    
    
    uint256 fee = 4;
    mapping (address => uint256[]) private salesOfCustomer; //for bidders
    mapping (uint256 => Sale) private salesMap;
    mapping (address => mapping (ERC721 => uint256[])) transferredNFTS;

    uint256[] private closedSaleIds;
    uint256[] private runningSaleIds;

    event startedSale (uint256 _id, uint256 _start, uint256 _startPrice, uint256 _idFromNft, ERC721 _nft, address _customer);
    event NFTsold (address _from, address to, ERC721 nft, uint256 NFT_ID, uint256 price);
    event NFTwasDeposited(address _from, address to);

    constructor (){

    }



    function startSale (uint256 _startPrice, uint256 _idFromNft, ERC721 _nft) public payable{
        
        require (!hasRunningSaleForNFT(msg.sender, _nft, _idFromNft), "Already a sale for this NFT");
        require (hasTransferredNFT(msg.sender, _nft, _idFromNft), "Did not deposit NFT");
        require (_nft.ownerOf(_idFromNft) == address(this), "NFT is not on contract");
        require (salesOfCustomer[msg.sender].length <= maxRunningSales, "Customer has already max number of running Sales");

        saleCount += 1;

        Sale memory _sale = Sale({
            id: saleCount, 
            start: block.timestamp, 
            startPrice: _startPrice, 
            idFromNft: _idFromNft, 
            nft:_nft, 
            seller: payable(msg.sender),
            status: status_openForSale,
            active: true
        });

        require(!salesMap[saleCount].active, "Error creating sale");

        salesMap[saleCount] = _sale;
        salesOfCustomer[msg.sender].push(_sale.id);
        runningSaleIds.push(_sale.id);
        emit startedSale(_sale.id, _sale.start,  _sale.startPrice, _sale.idFromNft, _sale.nft, _sale.seller);

    } 
    
    //checks if seller has an open sale for this NFT //does not check the NFT parameter
    function hasRunningSaleForNFT (address _seller, ERC721 _nft, uint256 _idFromNft) public view returns (bool) {
        bool hasSale = false;
         for (uint256 i = 0; i < salesOfCustomer[_seller].length; i++){
            Sale memory sale = salesMap[salesOfCustomer[_seller][i]];
            if (sale.active &&
                sale.nft == _nft &&
                sale.idFromNft == _idFromNft && sale.status != status_openForSale){
                hasSale = true;
                break;
            }
        }
        return hasSale;
    }

    //Checks if the NFT was sent by the seller to the contract
    function hasTransferredNFT (address seller, ERC721 _nft, uint256 _idFromNft) public view returns (bool) {
        
        bool hasTransferred = false;
        for (uint256 i = 0; i < transferredNFTS[seller][_nft].length; i++){
            
            if (transferredNFTS[seller][_nft][i] == _idFromNft) 
            {
                hasTransferred = true;
                break;
            }
        }
        return hasTransferred;
    }
    
    
   function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    )   override
        external
        returns(bytes4)
    {
        //TODO check out if we can revert the transfer here if he has already enough sales
       transferredNFTS[from][ERC721(msg.sender)].push(tokenId);
       return this.onERC721Received.selector;
    }
    

    function buy (uint256 idFromSale) public payable {
        
        Sale memory _sale = salesMap[idFromSale];

        require (_sale.active, "Invalid sale id");
        require (_sale.nft.ownerOf(_sale.idFromNft) == address(this), "NFT is not on contract");
        require (msg.value == _sale.startPrice, "Invalid input amount");
        //require (_sale.end >= block.timestamp, "Sale is over");
       
        ERC721 erc721NFT = _sale.nft;

        //send NFT from contract to buyer
        erc721NFT.safeTransferFrom(address(this), msg.sender, _sale.idFromNft);

        //takeFee and send money to seller
        uint256 _fee = msg.value.mul(fee).div(100);
        salesMap[idFromSale].seller.transfer(msg.value.sub(_fee));
        salesMap[idFromSale].status = status_sold;
        removeFromTransferredNFTS (_sale);
        moveFromRunningToClosed(_sale.id);
        
        emit NFTsold (_sale.seller,  msg.sender, _sale.nft, _sale.idFromNft, _sale.startPrice);
    }

    function _claim(address payable _address) external onlyOwner{
        _address.transfer(address(this).balance);
    }
    
    function sendNFTFromContract(address receiver, ERC721 _nft, uint256 _nftID) external onlyOwner{
        _nft.safeTransferFrom(address(this), receiver, _nftID);
    }
    
    function moveFromRunningToClosed (uint256 saleId) internal {
        bool foundSale = false;
        for (uint i = 0; i < runningSaleIds.length - 1; i++){
            if(salesMap[runningSaleIds[i]].id == saleId){
                foundSale = true;
            }

            if(foundSale){
                runningSaleIds[i] = runningSaleIds[i+1];
            }
        }
        
        if(foundSale){
            runningSaleIds.pop; //changed length-- to pop
            closedSaleIds.push(saleId);
        }
    }  
    
    function removeFromTransferredNFTS (Sale memory _sale) internal {
        
        uint256 _length = transferredNFTS[_sale.seller][_sale.nft].length;
        for (uint256 i = 0; i < _length; i++) {
            if (transferredNFTS[_sale.seller][_sale.nft][i] == _sale.idFromNft)
            {
                if(i != _length -1){
                    transferredNFTS[_sale.seller][_sale.nft][i] =  transferredNFTS[_sale.seller][_sale.nft][_length -1];
                }
                transferredNFTS[_sale.seller][_sale.nft].pop;
                break;
            }
        }
    }  

    function closeSale (uint256 saleID) public returns (bool) { 
        Sale memory _sale = salesMap[saleID];
        require (_sale.active, "Invalid sale");
        require (_sale.status == status_openForSale, "Invalid sale status");
        require (_sale.seller == msg.sender, "Not your sale");
        require (_sale.nft.ownerOf(_sale.idFromNft) == address(this), "NFT is not on contract");

        _sale.nft.safeTransferFrom(address(this), msg.sender, _sale.idFromNft);

        if (_sale.nft.ownerOf(_sale.idFromNft) == msg.sender) 
        {
            salesMap[saleID].status = status_closedbycustomer;
            removeFromTransferredNFTS(_sale);
            moveFromRunningToClosed(_sale.id);
            return true;
        }
         
        else return false;
    }
    

    function closeSaleAdmin (uint256 saleID) public onlyOwner returns (bool) { 
        Sale memory _sale = salesMap[saleID];
        require (_sale.active, "Has no sale for this NFT");
        require (_sale.nft.ownerOf(_sale.idFromNft) == address(this), "NFT is not on contract");

        _sale.nft.safeTransferFrom(address(this), _sale.seller, _sale.idFromNft);

        if (_sale.nft.ownerOf(_sale.idFromNft) == _sale.seller) 
        {
            salesMap[saleID].status = status_closedbyadmin;
            removeFromTransferredNFTS(_sale);
            moveFromRunningToClosed(_sale.id);
            return true;
        }
         
        else return false;
    }

    function moveFromRunningToClosedAdmin (uint256 saleID) external onlyOwner {
        Sale memory _sale = salesMap[saleID];
        moveFromRunningToClosed(_sale.id);
    } 
    
    function removeFromTransferredNFTSAdmin (uint256 saleID) external onlyOwner {
        Sale memory _sale = salesMap[saleID];
        removeFromTransferredNFTS(_sale);
    }  
    
   function setEndTime (uint256 _et) public onlyOwner{
       endTime = _et;
   }
    
    function setFee(uint256 _newFee) external onlyOwner{
        fee = _newFee;
    }
    
    //------------------- setter functions for a sale

    function setSaleID (uint256 _saleID, uint256 _newID) external onlyOwner returns (uint256){
        salesMap[_saleID].id = _newID;
        return salesMap[_saleID].id;
    }
    
    function setStartTime (uint256 _saleID, uint256 _newStartTime) external onlyOwner returns (uint256){
        salesMap[_saleID].start = _newStartTime;
        return salesMap[_saleID].start;
    }

    function setStartPrice (uint256 _saleID, uint256 _newStartPrice) external onlyOwner returns (uint256){
        salesMap[_saleID].startPrice = _newStartPrice;
        return salesMap[_saleID].startPrice;
    }

    function setIDfromNFT (uint256 _saleID, uint256 _newIDfromNFT) external onlyOwner returns (uint256){
        salesMap[_saleID].idFromNft = _newIDfromNFT;
        return salesMap[_saleID].idFromNft;
    }

    function setNFT (uint256 _saleID, ERC721 _newNFT) external onlyOwner returns (ERC721){
        salesMap[_saleID].nft = _newNFT;
        return salesMap[_saleID].nft;
    }

    function setSellerAddress (uint256 _saleID, address payable _newSeller) external onlyOwner returns (address){
        salesMap[_saleID].seller = _newSeller;
        return  salesMap[_saleID].seller;
    }

    function setStatus (uint256 _saleID, uint8 _newStatus) external onlyOwner returns (uint256){
        salesMap[_saleID].status = _newStatus;
        return salesMap[_saleID].status;
    }

    function setActive (uint256 _saleID, bool _newActive) external onlyOwner returns (bool){
        salesMap[_saleID].active = _newActive;
        return salesMap[_saleID].active;
    }



    // -------------------getter zum testen -----------------------------------------
    function getSaleStartTime (uint256 _saleID) public view returns (uint256){
        return salesMap[_saleID].start;
    }
    
    function getSalePrice (uint256 _saleID) public view returns (uint256){
        return salesMap[_saleID].startPrice;
    }
    
    function getIDfromNFT(uint256 _saleID) public view returns (uint256){
        return salesMap[_saleID].idFromNft;
    }
    
    function getSaleSeller(uint256 SaleID) public view returns (address){
        return salesMap[SaleID].seller;
    }
    
    function getSale(uint256 saleID) public view returns (uint256, uint256, uint256, uint256, address, address, uint8){
        Sale memory _sale = salesMap[saleID];
        return (_sale.id, _sale.start, _sale.startPrice, _sale.idFromNft, address(_sale.nft), _sale.seller, _sale.status);
    }
    
    function getSalesOfCustomer(address customer) public view returns (uint256[] memory){
        return salesOfCustomer[customer];
    }
    
    function getTransferredNFTs(address customer, ERC721 nft) public view returns (uint256[] memory){
        return transferredNFTS[customer][nft];
    }

    function getRunningSaleIds(address customer) public view returns (uint256[] memory){
        return runningSaleIds;
    }

    function getClosedSaleIds(address customer) public view returns (uint256[] memory){
        return closedSaleIds;
    }

    
}