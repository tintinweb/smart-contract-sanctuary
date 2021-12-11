// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


import "./ERC721OZ.sol";

/**
 * @title ERC721 Printable Token
 * @dev ERC721 Token that can be be printed before being sold and not incur high gas fees 
 */
 contract JetCoinNFT is ERC721 {
   
  //total number of series made 
  uint256 public totalSeries;
  // tracks the ids being used by series 
  uint256 public SeriesIDs;
  address payable public MintableAddress;
  mapping(uint256 => PreMint) public PreMintData;
  mapping(uint256 => bool) public PrintSeries;
  struct PreMint {
      uint256 amount_of_tokens_left;
      uint256 total_in_series;
      uint256 starting_id;
      uint256 price;
      address payable creator;
      string url;
      
    }  
  event SeriesMade(address indexed creator, uint256 indexed price, uint256 indexed amount_made);
  event SeriesPurchased(address indexed buyer, uint256 indexed token_id, uint256 indexed price); 
  event TransferPayment(address indexed to, uint256 indexed amount); 
  
  
   constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) public  ERC721(name, symbol, baseURI) {
        MintableAddress = msg.sender;
        SeriesIDs = 1;
    }
    
    function _fetchCurrentTokenID(uint256 _seriesID) internal view returns (uint256){
     uint256 tokenID = PreMintData[_seriesID].total_in_series.sub(PreMintData[_seriesID].amount_of_tokens_left);
     tokenID = tokenID.add(PreMintData[_seriesID].starting_id);
     return tokenID;
    }
    
    function _processTransfer(uint256 _seriesID) internal returns (bool){
    //calculate fees to be removed
     uint256 fee = (msg.value.mul(10)).div(100);
     uint256 creatorsPayment = msg.value.sub(fee);
     //transfer payment to creator's address
     PreMintData[_seriesID].creator.transfer(creatorsPayment);
    require(address(this).balance >= fee, "Not enough balance to send fee");
    MintableAddress.transfer(fee);
    emit TransferPayment( PreMintData[_seriesID].creator,  creatorsPayment);
    return true;
    }
   function _createPrintSeries(uint256 _totalAmount, uint256 _price, string memory _url) internal returns (bool){
        totalSeries = totalSeries.add(1);
     
        PrintSeries[totalSeries] = true;
           PreMint memory newSeries = PreMint({
               amount_of_tokens_left: _totalAmount,
               total_in_series: _totalAmount,
               starting_id: SeriesIDs,
               price:_price,
               creator: msg.sender,
               url: _url
        });       
        PreMintData[totalSeries] = newSeries;   
        SeriesIDs = SeriesIDs.add(_totalAmount);
                emit SeriesMade(msg.sender, _price, _totalAmount);
                return true;
 }
 
   
    function createPrintSeries(uint256 _amount, uint256 _price, string memory _url) public returns (bool){
        require(hasRole(MINTER, msg.sender), "Not authorized");
        return _createPrintSeries(_amount, _price, _url);
        
    }
    function mintSeries(uint256 _seriesID, address _to) public payable returns (bool){
     require(PrintSeries[_seriesID], "Not a valid series");
     require(PreMintData[_seriesID].amount_of_tokens_left >= 1, "Series is SOLD OUT!");
     require(msg.value >= PreMintData[_seriesID].price, "Invalid amount sent to purchase this NFT");
     //get total supply
     uint256 tokenID = _fetchCurrentTokenID(_seriesID);
     
     //change the amount of tokens left to be one less
     PreMintData[_seriesID].amount_of_tokens_left =  PreMintData[_seriesID].amount_of_tokens_left.sub(1);
     uint256 metadataID  = PreMintData[_seriesID].total_in_series.sub(PreMintData[_seriesID].amount_of_tokens_left);
     //check if tokens left are 0 if so, set to sold out
     if(PreMintData[_seriesID].amount_of_tokens_left == 0){
         PrintSeries[_seriesID] = false;
     }
     emit SeriesPurchased( msg.sender, tokenID, msg.value); 
     //mint tokens and send to buyer
    
     super._mintWithURI(_to,  string(abi.encodePacked(PreMintData[_seriesID].url, metadataID.toString())), tokenID);
     //calculate fees to be removed
    require(_processTransfer(_seriesID), "Transfer failed");
    return true;
 }
 
}