// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./IERC721.sol";



contract CoronavirusDisease is ERC1155Supply ,Ownable,Pausable{

    string private name_;
    string private symbol_;


    uint256 onceMintMax = 5;
    uint256 holderMintMax = 1;
    uint256 whitelistMintMax = 3;

    uint256 public basePrice = 4000000000000000;
    uint256 public price = 2000000000000000;

    uint256 public baseSupply = 5000;
    uint256 public supply = 2000;

   
    uint256 public holderPurchaseStart    = 1641811968;
    uint256 public whitelistPurchaseStart = 1641811968;
    uint256 public publicPurchaseStart    = 1641811968;

    uint256 public redeemFee = 0;//200 => 2%,500 => 5%

    address[] public holderNfts;



    bytes32 public merkleRoot;

    bool public isWithdraw = false;
    uint256 public lockBlock = 10;
    uint256 public lastTrueBlock = 0;

    mapping(address => uint256) public purchaseTxs;
    mapping(uint256 => NftConfig) public nfts;

    struct NftConfig{
      uint256 id;
      uint256 price;
      uint256 maxSupply;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;

        for(uint8 i = 0; i < 3; i++){
            nfts[i] = NftConfig({
              id: i,
              price: basePrice + (i*price),
              maxSupply: baseSupply - (i*supply)
            });
        }
    }

    event Purchased(uint256 indexed index, address indexed account, uint256 amount);

    event Redeem(uint256 indexed index, address indexed account, uint256 amount);


   
    function holderPurchase(uint256 _id,uint256 _amount) external payable whenNotPaused{
      require(block.timestamp >= holderPurchaseStart,"Not start");
      require(_isHolder(_msgSender()),"Need to hold the corresponding nft");
      require((purchaseTxs[_msgSender()] + _amount) <= holderMintMax, "Purchase quota has been used up");

      _purchase(_id,_amount);
    }

    function whitelistPurchase(uint256 _id,uint256 _amount,bytes32[] calldata merkleProof) external payable whenNotPaused{
      require(block.timestamp >= whitelistPurchaseStart,"Not start");
      require((purchaseTxs[_msgSender()] + _amount) <= whitelistMintMax, "Purchase quota has been used up");

      bytes32 node = keccak256(abi.encodePacked(_msgSender()));
      require(
          MerkleProof.verify(merkleProof, merkleRoot, node),
          "MerkleDistributor: Invalid proof."
      );
      _purchase(_id,_amount);
    }

    function publicPurchase(uint256 _id,uint256 _amount) external payable whenNotPaused{
      require(block.timestamp >= publicPurchaseStart,"Not start");
      require(_amount <= onceMintMax, "Buy too much");

      _purchase(_id,_amount);
    }

    function redeemYouEth(uint256 _id,uint256 _amount) external {
      _burn(_msgSender(), _id, _amount);
      NftConfig memory _nft = nfts[_id];

      uint256 fee = (_nft.price*_amount*redeemFee)/10000;
      uint256 returnValue = (_nft.price*_amount) - fee;

      payable(_msgSender()).transfer(returnValue);
      emit Redeem(_id, _msgSender(), _amount);
    }

    function _purchase(uint256 id,uint256 amount) internal {
      NftConfig memory _nft = nfts[id];
      require((totalSupply(id) + amount) <= _nft.maxSupply,"Sale out");
      require((_nft.price*amount) <= msg.value,"Not enough money");

      purchaseTxs[_msgSender()] += amount;
      _mint(_msgSender(), id, amount, "");
      emit Purchased(id, msg.sender, amount);
    }

    function isHolder(address _owner) external view returns(bool){
      return _isHolder(_owner);
    }

    function _isHolder(address owner) internal view returns(bool) {
      for(uint8 i = 0; i < holderNfts.length; i++ ){
        if(IERC721(holderNfts[i]).balanceOf(owner) > 0){
          return true;
        }
      }
      return false;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }   


    function uri(uint256 _id) public view override returns (string memory) {
      require(exists(_id), "URI: nonexistent token");

      return string(abi.encodePacked(super.uri(_id),"/", Strings.toString(_id)));
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
      merkleRoot = _merkleRoot;
    }

    function setMintMax(uint256 _onceMintMax,uint256 _holderMintMax,uint256 _whitelistMintMax) external onlyOwner {
      require(_onceMintMax > 0 && _holderMintMax > 0 && _whitelistMintMax > 0 ,"Parameter error");

      onceMintMax = _onceMintMax;
      holderMintMax = _holderMintMax;
      whitelistMintMax = _whitelistMintMax;
    }

    function setPurchaseStart(uint256 _holderPurchaseStart,uint256 _whitelistPurchaseStart,uint256 _publicPurchaseStart) external onlyOwner {
      require(_publicPurchaseStart > _whitelistPurchaseStart
              && _whitelistPurchaseStart > _holderPurchaseStart ,"Parameter error");

      holderPurchaseStart = _holderPurchaseStart;
      whitelistPurchaseStart = _whitelistPurchaseStart;
      publicPurchaseStart = _publicPurchaseStart;
    }

    function setPurchasePrice(uint256 _basePrice,uint256 _price) external onlyOwner {
      require(_basePrice >= 0 && _price >= 0 ,"Parameter error");
      basePrice = _basePrice;
      price = _price;
    }

    function setHolderNft(address _nft) external onlyOwner {
      require(_nft != address(0),"Parameter error");

      holderNfts.push(_nft);
    }

    function setRedeemFee(uint256 _fee) external onlyOwner {
      require(_fee <= 1000,"Parameter error");

      redeemFee = _fee;
    }

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }           

    function withdraw(uint256 _amount) external onlyOwner {
      require(isWithdraw && block.number <= (lastTrueBlock + lockBlock));
      payable(_msgSender()).transfer(_amount);
    }

    function openWithdraw() external onlyOwner {
      isWithdraw = true;
      lastTrueBlock = block.number;
    }


    
}