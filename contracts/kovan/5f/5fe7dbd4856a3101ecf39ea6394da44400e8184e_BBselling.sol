/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.7.6;

interface IBbond {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId, uint256 time);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
    function getUsedTokens(address owner, address operator) external view returns(uint256[] memory);

    function getSoldTokens(address owner) external view returns(uint256[] memory);

    function getAllTokens(address owner) external view returns(uint256[] memory);

}

interface IBUSD {

    function balanceOf(address _owner) view external  returns (uint256 balance);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);

}

interface IBTCB {

    function balanceOf(address _owner) view external  returns (uint256 balance);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);

}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract BBselling{
    
    IBbond public BbToken;
    IBUSD public BusdToken;
    IBTCB public BtcbToken;
    AggregatorV3Interface public priceFeedBusd;
    // AggregatorV3Interface public priceFeedBnb;
    
    address payable public owner;
    uint256 public precision = 10000;
    
    struct Sold{
        uint256[] soldTokenid;
    }
    
    mapping (address => Sold) soldTokens;
    mapping (uint256 => uint256) public tokenTime;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"Access denied.");
        _;
    }
    
    constructor(address payable _owner) public {
        owner = _owner;
        BusdToken = IBUSD(0x7438e4b25939457491852a903cF5A5b933b16d4D);
        BbToken = IBbond(0x425E2eEEaDa4e6aE093D02d826Baf47C818F4C99);
        BtcbToken = IBTCB(0x7438e4b25939457491852a903cF5A5b933b16d4D);
        priceFeedBusd = AggregatorV3Interface(0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf);
        // priceFeedBnb = AggregatorV3Interface(0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16);
    }
    
 
    function getLatestPriceBusd() public view returns (uint256) {
        (,int price,,,) = priceFeedBusd.latestRoundData();
        
        return uint256(price)/(1e11);
    }
    
    // function getLatestPriceBnb() public view returns (uint256) {
    //     (,int price,,,) = priceFeedBnb.latestRoundData();
    //     return uint256(price)/(1e8);
    // }
    
    // function sellBondBnb(uint256 amount) public returns(bool){
    //     require(amount > 0 , "Amount can not be zero.");
    //     require(BbToken.balanceOf(msg.sender) >= amount,"ERC721: User balance is insufficient.");
    //     uint256[] memory tokenIdList = BbToken.getAllTokens(msg.sender);
    //     Sold storage sold = soldTokens[msg.sender]; 
        

    //     for(uint8 i=0 ; i < amount ; i++){
    //         BbToken.safeTransferFrom(msg.sender, owner, tokenIdList[i], "");
    //         sold.soldTokenid.push(tokenIdList[i]);
    //         tokenTime[tokenIdList[i]] = block.timestamp;
    //     }
        
    //     uint256 priceBusd = getLatestPriceBusd();
    //     uint256 priceBnb = precision/(getLatestPriceBnb());
        
    //     require(address(this).balance >= amount*(priceBusd)*(priceBnb)/precision,"ERC721: contract balance is insufficient.");
    //     msg.sender.transfer((amount*(priceBusd)*(priceBnb)*(90))/(precision*(100)));
    //     return true;
    // }
    
    function sellBondBusd(uint256 amount) public returns(bool){
        require(amount > 0 , "Amount can not be zero.");
        require(BbToken.balanceOf(msg.sender) >= amount,"ERC721: User balance is insufficient.");
        uint256[] memory tokenIdList = BbToken.getAllTokens(msg.sender);
        Sold storage sold = soldTokens[msg.sender]; 
        

        for(uint8 i=0 ; i < amount ; i++){
            BbToken.safeTransferFrom(msg.sender, owner, tokenIdList[i], "");
            sold.soldTokenid.push(tokenIdList[i]);
            tokenTime[tokenIdList[i]] = block.timestamp;
        }
        
        uint256 price = getLatestPriceBusd();
        require(BusdToken.balanceOf(owner) >= amount*(price)*(1e18),"ERC721: contract balance is insufficient.");
        BusdToken.transferFrom(owner, msg.sender, amount*(price)*(1e18)*(90)/(100));
        return true;
    }
    
    function sellBondBTCB(uint256 amount) public returns(bool){
        require(amount > 0 , "Amount can not be zero.");
        require(BbToken.balanceOf(msg.sender) >= amount,"ERC721: User balance is insufficient.");
        uint256[] memory tokenIdList = BbToken.getAllTokens(msg.sender);
        Sold storage sold = soldTokens[msg.sender]; 
        

        for(uint8 i=0 ; i < amount ; i++){
            BbToken.safeTransferFrom(msg.sender, owner, tokenIdList[i], "");
            sold.soldTokenid.push(tokenIdList[i]);
            tokenTime[tokenIdList[i]] = block.timestamp;
        }
        
        require(BtcbToken.balanceOf(owner) >= amount/(1000),"ERC721: Not enough BTCB.");
        BtcbToken.transferFrom(owner, msg.sender, amount*(1e18)*(90)/(100000) );
        return true;
    }
    
    function getSoldBonds(address user) public view returns(uint256[] memory){
        return soldTokens[user].soldTokenid;
    }
    
    function changeOwner(address payable newOwner) external onlyOwner returns(bool){
        
        owner = newOwner;
        return true;
    }
    
    function setPrecision(uint256 value) external onlyOwner returns(bool){
        
        precision = value;
        return true;
    }
    
    function DrawFunds(uint256 value) external onlyOwner returns(bool){
        
        owner.transfer(value);
        return true;
    }
    
}