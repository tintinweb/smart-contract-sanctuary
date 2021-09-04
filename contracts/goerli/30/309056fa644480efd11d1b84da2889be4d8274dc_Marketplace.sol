// SPDX-License-Identifier: MIT

// This version supports ETH and ERC20
pragma solidity 0.8.0;
import "./SafeErc20.sol";

interface IERC721 {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _value, bytes calldata _data) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 {
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);

}

interface ISecondaryMarketFees {
  struct Fee {
    address recipient;
    uint256 value;
  }
  function getFeeRecipients(uint256 tokenId) external view returns(address[] memory);
  function getFeeBps(uint256 tokenId) external view returns(uint256[] memory);
}

contract Marketplace {

  using SafeERC20 for IERC20;
  bytes4 private constant INTERFACE_ID_FEES = 0xb7799584;
  address public beneficiary;
  address public orderSigner;
  address public owner;

  enum AssetType { ETH, ERC20, ERC721, ERC1155, ERC721Deprecated }
  enum OrderStatus { LISTED, COMPLETED, CANCELLED }

  struct Asset {
    address contractAddress;
    uint256 tokenId;
    AssetType assetType;
    uint256 value;
  }

  struct Order {
    address seller;
    Asset sellAsset;
    Asset buyAsset;
    uint256 salt;
  }

  struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  mapping(bytes32 => Order) orders;
  mapping(bytes32 => OrderStatus) public orderStatus;

  event Buy(
    address indexed sellContract, uint256 indexed sellTokenId, uint256 sellValue,
    address owner,
    address buyContract, uint256 buyTokenId, uint256 buyValue,
    address buyer,
    uint256 salt
  );

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner is allowed");
    _;
  }

  constructor(address _beneficiary, address _orderSigner) {
    beneficiary = _beneficiary;
    orderSigner = _orderSigner;
    owner = msg.sender;
  }

  function updateOrderSigner(address newOrderSigner) public onlyOwner {
    orderSigner =  newOrderSigner;
  }

  function updateBeneficiary(address newBeneficiary) public onlyOwner {
    beneficiary = newBeneficiary;
  }

   function exchange(
    Order calldata order,
    Signature calldata sellerSignature,
    Signature calldata buyerSignature,
    address buyer,
    uint256 sellerFee,
    uint256 buyerFee
  ) public payable {
    if(buyer == address(0)) buyer = msg.sender;

    validateSellerSignature(order, sellerFee, sellerSignature);
    validateBuyerSignature(order, buyer, buyerFee, buyerSignature);
    
    require(order.sellAsset.assetType == AssetType.ERC721 || order.sellAsset.assetType == AssetType.ERC1155  , "Only ERC721 are supported on seller side");
    require(order.buyAsset.assetType == AssetType.ETH || order.buyAsset.assetType == AssetType.ERC20, "Only Eth/ERC20 supported on buy side");
    require(order.buyAsset.tokenId == 0, "Buy token id must be UINT256_MAX");
    if(order.buyAsset.assetType == AssetType.ETH) {
      validateEthTransfer(order.buyAsset.value, buyerFee);
    }

    uint256 remainingAmount = transferFeeToBeneficiary(
      order.buyAsset, 
      buyer,
      order.buyAsset.value,
      sellerFee,
      buyerFee
    );

    transfer(order.sellAsset, order.seller, buyer, order.sellAsset.value);
    transferWithFee(order.buyAsset, buyer, order.seller, remainingAmount, order.sellAsset);
    emitBuy(order, buyer);
  }

  
  function transferFeeToBeneficiary(
    Asset memory asset, address from, uint256 amount, uint256 sellerFee, uint256 buyerFee
  ) internal returns(uint256) {
    uint256 sellerCommission = getPercentageCalc(amount, sellerFee);
    uint256 buyerCommission = getPercentageCalc(amount, buyerFee);
    require(sellerCommission <= amount, "Seller commission exceeds amount");
    uint256 totalCommission = sellerCommission + buyerCommission;
    if(totalCommission > 0) {
      transfer(asset, from, beneficiary, totalCommission);
    }
    return amount - sellerCommission;
  }

  function transferWithFee(
    Asset memory _primaryAsset,
    address from,
    address to,
    uint256 amount,
    Asset memory _secondaryAsset
  ) internal {
    uint256 remainingAmount = amount;
    if(supportsSecondaryFees(_secondaryAsset)) {
      ISecondaryMarketFees _secondaryMktContract = ISecondaryMarketFees(_secondaryAsset.contractAddress);
      address[] memory recipients = _secondaryMktContract.getFeeRecipients(_secondaryAsset.tokenId);
      uint[] memory fees = _secondaryMktContract.getFeeBps(_secondaryAsset.tokenId);
      require(fees.length == recipients.length, "Invalid fees arguments");
      for(uint256 i=0; i<fees.length; i++) {
        uint256 _fee = getPercentageCalc(_primaryAsset.value, fees[i]);
        remainingAmount = remainingAmount - _fee;
        transfer(_primaryAsset, from, recipients[i], _fee);
      }
    }
    transfer(_primaryAsset, from, to, remainingAmount);
  }

  function transfer(Asset memory _asset, address from, address to, uint256 value) internal {
    if(_asset.assetType == AssetType.ETH) {
      payable(to).transfer(value);
    } else if(_asset.assetType == AssetType.ERC20) {
      IERC20(_asset.contractAddress).safeTransferFrom(from, to, value);
    } else if(_asset.assetType == AssetType.ERC721) {
      require(value == 1, "value should be 1 for ERC-721");
      IERC721(_asset.contractAddress).safeTransferFrom(from, to, _asset.tokenId);
    } else if(_asset.assetType == AssetType.ERC1155) {
      IERC1155(_asset.contractAddress).safeTransferFrom(from, to, _asset.tokenId, value, "0x");
    } else {
      require(value == 1, "value should be 1 for ERC-721");
      IERC721(_asset.contractAddress).transferFrom(from, to, _asset.tokenId);
    }
  }

  function validateEthTransfer(uint amount, uint buyerFee) internal view {
    uint256 buyerCommission =  getPercentageCalc(amount, buyerFee);
    require(msg.value == amount + buyerCommission, "msg.value is incorrect");
  }

  function validateSellerSignature(Order calldata _order, uint256 sellerFee, Signature calldata _sig) public pure {
    bytes32 signature = getMessageForSeller(_order, sellerFee);
    require(getSigner(signature, _sig) == _order.seller, "Seller must sign order data");
  }

  function validateBuyerSignature(Order calldata order, address buyer, uint256 buyerFee,
    Signature calldata sig) public view {
    bytes32 message = getMessageForBuyer(order, buyer, buyerFee);
    require(getSigner(message, sig) == orderSigner, "Order signer must sign");
  }

  function getMessageForSeller(Order calldata order, uint256 sellerFee) public pure returns(bytes32) {
    return keccak256(abi.encode(order, sellerFee));
  }

  function getMessageForBuyer(Order calldata order, address buyer, uint256 buyerFee) public pure returns(bytes32) {
    return keccak256(abi.encode(order, buyer, buyerFee));
  }

  function getSigner(bytes32 message, Signature memory _sig) public pure returns (address){
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    return ecrecover(keccak256(abi.encodePacked(prefix, message)),_sig.v, _sig.r, _sig.s);
  }

  function emitBuy(Order calldata order, address buyer) internal {
    emit Buy(
      order.sellAsset.contractAddress,
      order.sellAsset.tokenId,
      order.sellAsset.value,
      order.seller,
      order.buyAsset.contractAddress,
      order.buyAsset.tokenId,
      order.buyAsset.value,
      buyer,
      order.salt
    );
  }

  function getPercentageCalc(uint256 totalValue, uint _percentage) internal pure returns(uint256) {
    return (totalValue * _percentage) / 1000 / 100;
  }
  
  function supportsSecondaryFees(Asset memory asset) internal view returns(bool) {
    return (
      (asset.assetType == AssetType.ERC1155 &&
      IERC1155(asset.contractAddress).supportsInterface(INTERFACE_ID_FEES)) ||
      ( isERC721(asset.assetType) &&
      IERC721(asset.contractAddress).supportsInterface(INTERFACE_ID_FEES))
    );
  }
  
  function isERC721(AssetType assetType) internal pure returns(bool){
    return assetType == AssetType.ERC721 || assetType == AssetType.ERC721Deprecated;
  }

}