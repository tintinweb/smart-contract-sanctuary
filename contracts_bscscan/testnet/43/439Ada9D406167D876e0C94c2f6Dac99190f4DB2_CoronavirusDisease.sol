// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./IERC721.sol";

/**
  无聊猴，幻影熊持有者 最先mint,限制每个地址最多一个
  白名单，mint,限制每个地址最多两个
  公开发售，无限制
 */

contract CoronavirusDisease is ERC1155Supply ,Ownable,Pausable{

    string public name_;
    string public symbol_;


    uint8 onceMintMax = 5;
    uint8 holderMintMax = 1;
    uint8 whitelistMintMax = 3;

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

    function whitelistPurchase(uint256 _id,uint256 _amount,uint256 index,bytes32[] calldata merkleProof) external payable whenNotPaused{
      require(block.timestamp >= whitelistPurchaseStart,"Not start");
      require((purchaseTxs[_msgSender()] + _amount) <= whitelistMintMax, "Purchase quota has been used up");

      //检验白名单
      bytes32 node = keccak256(abi.encodePacked(index, msg.sender, uint256(2)));
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
      //先把nft销毁了，
      _burn(_msgSender(), _id, _amount);
      //返还eth
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


    
    /**
    * @notice returns the metadata uri for a given id
    *
    * @param _id the card id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
      require(exists(_id), "URI: nonexistent token");

      return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    /**
    * @notice edit the merkle root for early access sale
    *
    * @param _merkleRoot the new merkle root
    */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
      merkleRoot = _merkleRoot;
    }

    function setMintMax(uint8 _onceMintMax,uint8 _holderMintMax,uint8 _whitelistMintMax) external onlyOwner {
      require(_onceMintMax > 0 && _holderMintMax > 0 && _whitelistMintMax > 0 ,"Parameter error");

      onceMintMax = _onceMintMax;
      holderMintMax = _holderMintMax;
      whitelistMintMax = _whitelistMintMax;
    }

    function setPurchaseStart(uint8 _holderPurchaseStart,uint8 _whitelistPurchaseStart,uint8 _publicPurchaseStart) external onlyOwner {
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
    
}