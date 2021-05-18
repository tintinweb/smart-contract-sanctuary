/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function getFee(uint256 tokenId) external view returns(uint256);
    function getOwner(uint256 tokenId) external view returns(address);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function getFee(uint256 tokenId) external view returns(uint256);
    function getOwner(uint256 tokenId) external view returns(address);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract TransferProxy {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external  {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external  {
        token.safeTransferFrom(from, to, id, value, data);
    }
    
    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external  {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }   
}

contract Trade {
    using SafeMath for uint256;

    enum BuyingAssetType {ERC1155, ERC721}
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    uint8 private buyerFeePermille;
    uint8 private sellerFeePermille;
    TransferProxy public transferProxy;
    address public owner;
    uint256 royalty;
    uint256 assetValue;
    uint256 fee;
    address tokenCreator;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (uint8 _buyerFee, uint8 _sellerFee, TransferProxy _transferProxy) public {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        owner = msg.sender;
    }

    function buyerServiceFee() public view virtual returns (uint8) {
        return buyerFeePermille;
    }

    function sellerServiceFee() public view virtual returns (uint8) {
        return sellerFeePermille;
    }

    function setBuyerServiceFee(uint8 _buyerFee) public returns(bool) {
        buyerFeePermille = _buyerFee;
    }

    function setSellerServiceFee(uint8 _sellerFee) public returns(bool) {
        sellerFeePermille = _sellerFee;
    }

    function ownerTransfership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function tradeAsset(address paymentAssetAddress, address assetOwner, address buyer, uint paymentAmt, BuyingAssetType buyingAssetType, address buyingAssetAddress, uint tokenId, uint8 buyingAssetQty, bytes memory data) public returns(bool) {
        if (buyer == address(0x0)) {
            buyer = msg.sender;
        }
        uint256 buyerFee = paymentAmt.mul(buyerFeePermille).div(1000);
        uint256 sellerFee = paymentAmt.mul(sellerFeePermille).div(1000);
        uint256 assetFee = paymentAmt.sub((buyerFee).add(sellerFee));


        if(buyingAssetType == BuyingAssetType.ERC721) {

            fee = ((IERC721(buyingAssetAddress).getFee(tokenId)));
            tokenCreator = ((IERC721(buyingAssetAddress).getOwner(tokenId)));
            royalty = assetFee.mul(fee).div(100);
            assetValue = assetFee.sub(royalty);
            transferProxy.erc721safeTransferFrom(IERC721(buyingAssetAddress), assetOwner, buyer, tokenId);
            transferProxy.erc20safeTransferFrom(IERC20(paymentAssetAddress), buyer, owner, buyerFee);
            transferProxy.erc20safeTransferFrom(IERC20(paymentAssetAddress), buyer, owner, sellerFee);
            transferProxy.erc20safeTransferFrom(IERC20(paymentAssetAddress), buyer, tokenCreator, royalty);
            transferProxy.erc20safeTransferFrom(IERC20(paymentAssetAddress), buyer, assetOwner, assetValue);
        }
        
        if(buyingAssetType == BuyingAssetType.ERC1155)  {  

            fee = ((IERC1155(buyingAssetAddress).getFee(tokenId)));
            tokenCreator = ((IERC1155(buyingAssetAddress).getOwner(tokenId)));
            royalty = assetFee.mul(fee).div(100);
            assetValue = assetFee.sub(royalty);
            transferProxy.erc1155safeTransferFrom(IERC1155(buyingAssetAddress), assetOwner, buyer, tokenId, buyingAssetQty, data);
            transferProxy.erc20safeTransferFrom(IERC20(paymentAssetAddress), buyer, owner, buyerFee);
            transferProxy.erc20safeTransferFrom(IERC20(paymentAssetAddress), buyer, owner, sellerFee);
            transferProxy.erc20safeTransferFrom(IERC20(paymentAssetAddress), buyer, tokenCreator, royalty);
            transferProxy.erc20safeTransferFrom(IERC20(paymentAssetAddress), buyer, assetOwner, assetValue);
            
        }

        return true;
    }

}