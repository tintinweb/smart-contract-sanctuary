// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


import "./ERC721Batch.sol";
/**
 * @title ERC721 Printable Token
 * @dev ERC721 Token that can be be printed before being sold and not incur high gas fees 
 */
 contract ERC721Printable is ERC721 {
  uint256 public totalSeries;
  address payable public MintableAddress;
  mapping(uint256 => PreMint) public PreMintData;
  mapping(uint256 => bool) public PrintSeries;
  struct PreMint {
      uint256 amount_of_tokens_left;
      uint256 price;
      address payable creator;
      uint256 royaltyAmount;
      string url;
      
    }  
  event SeriesMade(address indexed creator, uint256 indexed price, uint256 indexed amount_made);
  event SeriesPurchased(address indexed buyer, uint256 indexed token_id, uint256 indexed price); 

  
  
   constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address _royaltyReceiver,
        uint256 batch_amount
    ) public  ERC721(name, symbol, baseURI, _royaltyReceiver, batch_amount) {
        MintableAddress = msg.sender;
    }
    
   function _createPrintSeries(uint256 _totalAmount, uint256 _price, string memory _url, uint256 _royaltyAmount) internal returns (bool){
        totalSeries = totalSeries.add(1);
          PrintSeries[totalSeries] = true;
          PreMintData[totalSeries] = PreMint({
              amount_of_tokens_left: _totalAmount,
              price: _price,
              url: _url,
              royaltyAmount: _royaltyAmount,
              creator: msg.sender
          });
         
                
                emit SeriesMade(msg.sender, _price, _totalAmount);
                return true;
 }
 
    function createPrintSeries(uint256 _amount, uint256 _price, string memory _url, uint256 _royaltyAmount) public onlyOwner returns (bool){
        return _createPrintSeries(_amount, _price, _url,  _royaltyAmount);
        
    }
    function mintSeries(uint256 _seriesID, address _to) public payable returns (bool){
     require(PrintSeries[_seriesID], "Not a valid series");
     require(PreMintData[_seriesID].amount_of_tokens_left >= 1, "Series is SOLD OUT!");
     require(msg.value >= PreMintData[_seriesID].price, "Invalid amount sent to purchase this NFT");
     PreMintData[_seriesID].amount_of_tokens_left =  PreMintData[_seriesID].amount_of_tokens_left.sub(1);
     if(PreMintData[_seriesID].amount_of_tokens_left == 0){
         PrintSeries[_seriesID] = false;
     }
     emit SeriesPurchased( msg.sender, super.totalSupply().add(1), msg.value); 
     super._mintWithURI(_to, PreMintData[_seriesID].url, PreMintData[_seriesID].royaltyAmount);
     uint256 fee = (msg.value.mul(10)).div(100);
     PreMintData[_seriesID].creator.transfer(msg.value.sub(fee));
    require(address(this).balance >= fee, "Not enough balance to send fee");
    MintableAddress.transfer(fee);
    return true;
 }
 
}