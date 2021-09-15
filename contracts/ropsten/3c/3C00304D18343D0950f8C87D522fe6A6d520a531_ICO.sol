// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./CodeTest_1.sol";

contract ICO is Ownable  {

    using SafeMath for uint256;
    
    // The token we are selling
    CodeTest_1 private token;
   
    // the UNIX timestamp start date of the crowdsale
    uint256 private startsAt;
    
    // the UNIX timestamp end date of the crowdsale
    uint256 private endsAt;
    
    // the price of token
    uint256 private TokenPerBNB;
    
    uint256 private countWhitelistUser;
    
    //Pause the ICO
    bool private _pause_ico;
    
    // Has this crowdsale been finalized
    bool private finalized = false;
    
    // the number of tokens already sold through this contract
    uint256 private tokensSold = 0;
    
    // the number of ETH raised through this contract
    uint256 private weiRaised = 0;
    
    // How many distinct addresses have invested
    uint256 private investorCount = 0;
    
    // How much ETH each address has invested to this crowdsale
    uint256 private minPerAddress = 1;
    
    //NFT TokenId
    uint256 private token_id = 0;
    
    // NFT presale TokenId
    uint256 private token_id_presale = 0;
    
    mapping (address => uint256) private investedAmountOf;
  
    mapping (address => uint256) private listOfAdrress_presale;
    
    mapping (address => bool) private whitelistAddress;
       
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount);
    
    // Crowdsale Start time has been changed
    event StartsAtChanged(uint256 startsAt);
    
    // Crowdsale end time has been changed
    event EndsAtChanged(uint256 endsAt);
    
    // Calculated new price
    event RateChanged(uint256 oldValue, uint256 newValue);
    
    function initialize( address _token , uint256 startsTime , uint256 endsTime , uint256 rateOfNft) public {
        token = CodeTest_1(_token);
        emit StartsAtChanged(startsTime);
        emit EndsAtChanged(endsTime);
        emit RateChanged(TokenPerBNB, rateOfNft);
        startsAt = startsTime;
        endsAt = endsTime;
        TokenPerBNB = rateOfNft;
        _pause_ico = true;
    }
    
    function buyNFT() public payable {
        require(whitelistAddress[msg.sender], "Strings: This user is not whitelisted");
        require(listOfAdrress_presale[msg.sender] < 6, "Strings: You cant't mint");
        require(TokenPerBNB >= msg.value,"Strings: Please Check Price");
        require(_pause_ico, "Strings: pause");
        require(startsAt <= block.timestamp && endsAt > block.timestamp,"Strings: No presale");
        token.buy_nft(msg.sender);
        listOfAdrress_presale[msg.sender] += 1; 
        payable(owner()).transfer(address(this).balance);  // Transfer Fund to owner's address
    }
    
    function getTokenList(address owner_address) public view virtual returns(uint[] memory) {
        return  token.tokensOfOwner(owner_address);
    }
    
    function traitsOfId(uint256 tokenIdTraits) public view virtual returns(uint256 , uint256 ,uint256 ) {
        return  token.traitOfowner(tokenIdTraits);
    }
    
    function getTokenUri(uint256 tokenIdUri) public view virtual returns(string memory) {
        return  token.tokenURI(tokenIdUri);
    }
    
    function _mintNFT(string  memory metadata) private {
        require(!finalized, "Strings: finalized error");
        require(token_id < 222, "Strings: 222 nft is minted");
        token_id++;
        token.safemint(owner(), metadata);
    }
    
    function mintNFT(string memory _ipfs) onlyOwner public {
        _mintNFT(_ipfs);
    }
    
    function white_list(address[] memory whitelisted) onlyOwner public {
        for(uint256 i = 0 ; i < whitelisted.length ; i++)
        {
           countWhitelistUser++;
           whitelistAddress[whitelisted[i]] = true;
        }
    }
    
    function black_list(address whitelisted) onlyOwner public {
        countWhitelistUser--;
        whitelistAddress[whitelisted] = false;
    }
    
    function pause_ico() public onlyOwner {
        _pause_ico = false;
    }
    
    function unpause_ico() public onlyOwner {
        _pause_ico = true;
    }
    
    function finalize() public onlyOwner {
        // Finalized Pre crowdsele.
        finalized = true;
        uint256 tokensAmount = token.balanceOf(address(this));
        token.transferFrom(address(this),owner(), tokensAmount);
    }
    
    function getstartAt() public view virtual returns(uint256){
        return startsAt;
    }
    
    function getEndsAt() public view virtual returns(uint256){
        return endsAt;
    }
    
    function checkPause() public view virtual returns(bool){
        return _pause_ico;
    }
    function WhitelistUser() public view virtual returns(uint256){
        return countWhitelistUser;
    }
    
    function getTokenPrice() public view virtual returns (uint256){
        return TokenPerBNB;
    }
}