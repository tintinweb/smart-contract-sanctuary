/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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

interface IERC1155 is IERC165 {
  
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
}

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

library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[1+i*2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes32  fullMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
         return ecrecover(fullMessage, v, r, s);
    }
}

interface IWAVAX{
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function withdraw(uint256 amount) external ;

}

contract OrderBook is Ownable {
	enum AssetType {
		ERC20,
		ERC721,
		ERC1155
	}

	struct Asset {
		address token;
		uint256 tokenId;
		AssetType assetType;
	}

	struct OrderKey {
		address payable owner;
		Asset sellAsset;
		Asset buyAsset;
	}

	struct Order {
		OrderKey key;
		uint256 selling;
		uint256 buying;
		uint256 sellerFee;
		uint256 salt;
		uint256 expiryTime; 
		uint256 orderType; 
	}

	struct Sig {
		uint8 v;
		bytes32 r;
		bytes32 s;
	}
}

contract OrderState is OrderBook {
	using BytesLibrary for bytes32;

	mapping(bytes32 => bool) public completed; 

	function getCompleted(OrderBook.Order calldata order)
		external
		view
		returns (bool)
	{
		return completed[getCompletedKey(order)];
	}

	function setCompleted(OrderBook.Order memory order, bool newCompleted)
		internal
	{
		completed[getCompletedKey(order)] = newCompleted;
	}

	function setCompletedBidOrder(
		OrderBook.Order memory order,
		bool newCompleted,
		address buyer,
		uint256 buyingAmount
	) internal {
		completed[
			getBidOrderCompletedKey(order, buyer, buyingAmount)
		] = newCompleted;
	}

	function getCompletedKey(OrderBook.Order memory order)
		public
		pure
		returns (bytes32)
	{
		return prepareOrderHash(order);
	}

	function getBidOrderCompletedKey(
		OrderBook.Order memory order,
		address buyer,
		uint256 buyingAmount
	) public pure returns (bytes32) {
		return prepareBidOrderHash(order, buyer, buyingAmount);
	}

	function validateOrderSignatureView(Order memory order, Sig memory sig)
		public
		view
		returns (address)
	{
		require(completed[getCompletedKey(order)] != true, "Signature exist");
		if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
			revert("Incorrect signature");
		} else {
			return prepareOrderHash(order).recover(sig.v, sig.r, sig.s);
		}
	}

	function validateBidOrderSignatureView(
		Order memory order,
		Sig memory sig,
		address bidder,
		uint256 buyingAmount
	) public view returns (address) {
		require(completed[getCompletedKey(order)] != true, "Signature exist");
		if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
			revert("Incorrect bid signature");
		} else {
			return
				prepareBidOrderHash(order, bidder, buyingAmount).recover(
					sig.v,
					sig.r,
					sig.s
				);
		}
	}

	function prepareOrderHash(OrderBook.Order memory order)
		public
		pure
		returns (bytes32)
	{
		return
			keccak256(
				abi.encodePacked(
					order.key.owner,
					abi.encodePacked(
						order.key.sellAsset.token,
						order.key.sellAsset.tokenId,
						order.key.sellAsset.assetType,
						order.key.buyAsset.token,
						order.key.buyAsset.tokenId,
						order.key.buyAsset.assetType
					),
					order.selling,
					order.buying,
					order.sellerFee,
					order.salt,
					order.expiryTime,
					order.orderType
				)
			);
	}

	function prepareBidOrderHash(
		OrderBook.Order memory order,
		address bidder,
		uint256 buyingAmount
	) public pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					bidder,
					abi.encodePacked(
						order.key.buyAsset.token,
						order.key.buyAsset.tokenId,
						order.key.buyAsset.assetType,
						order.key.sellAsset.token,
						order.key.sellAsset.tokenId,
						order.key.sellAsset.assetType
					),
					buyingAmount,
					order.selling,
					order.sellerFee,
					order.salt,
					order.expiryTime,
					order.orderType
				)
			);
	}

	function prepareBuyerFeeMessage(
		Order memory order,
		uint256 fee,
		address royaltyReceipt
	) public pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					abi.encodePacked(
						order.key.owner,
						abi.encodePacked(
							order.key.sellAsset.token,
							order.key.sellAsset.tokenId,
							order.key.buyAsset.token,
							order.key.buyAsset.tokenId
						),
						order.selling,
						order.buying,
						order.sellerFee,
						order.salt,
						order.expiryTime,
						order.orderType
					),
					fee,
					royaltyReceipt
				)
			);
	}
}

interface IIglooxStore {
	function mint(
		address from,
		address to,
		uint256 id,
		uint256 blockExpiry,
		uint8 v,
		bytes32 r,
		bytes32 s,
		uint256 supply,
		string memory uri
	) external returns (bool);
}

contract TransferSafe {
	struct mintParams {
		uint256 blockExpiry;
		uint8 v;
		bytes32 r;
		bytes32 s;
		string uri;
	}

	function erc721safeTransferFrom(
		IERC721 token,
		address from,
		address to,
		uint256 tokenId
	) internal {
		token.safeTransferFrom(from, to, tokenId);
	}

	function erc1155safeTransferFrom(
		IERC1155 token,
		address from,
		address to,
		uint256 id,
		uint256 value
	) internal {
		token.safeTransferFrom(from, to, id, value, "0x");
	}

	function erc1155safeMintTransferFrom(
		IIglooxStore token,
		address from,
		address to,
		uint256 id,
		uint256 value,
		uint256 blockExpiry,
		uint8 v,
		bytes32 r,
		bytes32 s,
		string memory uri
	) internal {
		require(
			token.mint(from, to, id, blockExpiry, v, r, s, value, uri),
			"TransferSafe:erc1155safeMintTransferFrom:: transaction Failed"
		);
	}
}

contract IglooxExchange is OrderState, TransferSafe {
	using SafeMath for uint256;

	address payable public beneficiaryAddress;
	address public buyerFeeSigner;
	uint256 public beneficiaryFee; //
	uint256 public royaltyFeeLimit = 50; // 5%
	uint256 public taxFee;
	IIglooxStore private _IglooxStore;
	address public WAVAX;
	address public staking;

	// auth token for exchange
	mapping(address => bool) public allowToken;

	event MatchOrder(
		address indexed sellToken,
		uint256 indexed sellTokenId,
		uint256 sellValue,
		address owner,
		address buyToken,
		uint256 buyTokenId,
		uint256 buyValue,
		address buyer,
		uint256 orderType
	);
	event Cancel(
		address indexed sellToken,
		uint256 indexed sellTokenId,
		address owner,
		address buyToken,
		uint256 buyTokenId
	);
	event Beneficiary(address newBeneficiary);
	event BuyerFeeSigner(address newBuyerFeeSigner);
	event BeneficiaryFee(uint256 newbeneficiaryfee);
	event RoyaltyFeeLimit(uint256 newRoyaltyFeeLimit);
	event AllowToken(address token, bool status);
	event SetMintableStore(address newMintableStore);

	constructor(
		address payable beneficiary,
		address buyerfeesigner,
		uint256 beneficiaryfee,
		address WAVAXAddr,
		address _staking
	) public {
		beneficiaryAddress = beneficiary;
		buyerFeeSigner = buyerfeesigner;
		beneficiaryFee = beneficiaryfee;
		WAVAX = WAVAXAddr;
		staking = _staking;
	}

	function buy(
		Order calldata order,
		Sig calldata sig,
		Sig calldata buyerFeeSig,
		uint256 royaltyFee,
		address payable royaltyReceipt,
		bool isStore,
		mintParams memory storeParams
	) external payable {
		require((block.timestamp <= order.expiryTime), "Signature expired");
		require(order.orderType == 1, "Invalid order type");
		require(order.key.owner != msg.sender, "Invalid owner");

		require(validateOrderSignatureView(order, sig) == order.key.owner,"Incorrect signature");
		require(validateBuyerFeeSigView(order, royaltyFee, royaltyReceipt, buyerFeeSig) == buyerFeeSigner,"Invalid buyerFee signature");

		transferSellFee(order, royaltyReceipt, royaltyFee, msg.sender);
		setCompleted(order, true);
		transferToken(order, msg.sender, isStore, storeParams);
		emitMatchOrder(order, msg.sender);
	}

	function makeOffer(
		Order calldata order,
		Sig calldata sig,
		Sig calldata buyerFeeSig,
		uint256 royaltyFee,
		address payable royaltyReceipt,
		bool isStore,
		mintParams memory storeParams
	) external {
		require((block.timestamp <= order.expiryTime), "Signature expired");
		require(order.orderType == 2, "Invalid order");
		require(order.key.owner != msg.sender, "Invalid owner");

		require(validateOrderSignatureView(order, sig) == order.key.owner,"Incorrect signature");
		require(validateBuyerFeeSigView(order, royaltyFee, royaltyReceipt, buyerFeeSig) == buyerFeeSigner,"Invalid buyerFee signature");

		transferBuyFee(order, royaltyReceipt, royaltyFee, msg.sender);
		setCompleted(order, true);
		transferToken(order, msg.sender, isStore, storeParams);
		emitMatchOrder(order, msg.sender);
	}

	function transferToken(
		Order calldata order,
		address buyer,
		bool isStore,
		mintParams memory storeParams
	) internal {
		if (
			order.key.sellAsset.assetType == AssetType.ERC721 ||
			order.key.buyAsset.assetType == AssetType.ERC721
		) {
			if (order.orderType == 1 || order.orderType == 3) {
				if (!isStore) {
					erc721safeTransferFrom(
						IERC721(order.key.sellAsset.token),
						order.key.owner,
						buyer,
						order.key.sellAsset.tokenId
					);
				} else {
					require(
						order.key.sellAsset.token == address(_IglooxStore),
						"invalid sell asset"
					);
					erc1155safeMintTransferFrom(
						IIglooxStore(order.key.sellAsset.token),
						order.key.owner,
						buyer,
						order.key.sellAsset.tokenId,
						1,
						storeParams.blockExpiry,
						storeParams.v,
						storeParams.r,
						storeParams.s,
						storeParams.uri
					);
				}
			} else if (order.orderType == 2) {
				if (!isStore) {
					erc721safeTransferFrom(
						IERC721(order.key.buyAsset.token),
						buyer,
						order.key.owner,
						order.key.buyAsset.tokenId
					);
				} else {
					require(
						order.key.buyAsset.token == address(_IglooxStore),
						"invalid buy asset"
					);
					erc1155safeMintTransferFrom(
						IIglooxStore(order.key.buyAsset.token),
						buyer,
						order.key.owner,
						order.key.buyAsset.tokenId,
						1,
						storeParams.blockExpiry,
						storeParams.v,
						storeParams.r,
						storeParams.s,
						storeParams.uri
					);
				}
			}
		} else if (
			order.key.sellAsset.assetType == AssetType.ERC1155 ||
			order.key.buyAsset.assetType == AssetType.ERC1155
		) {
			if (order.orderType == 1 || order.orderType == 3) {
				if (!isStore) {
					erc1155safeTransferFrom(
						IERC1155(order.key.sellAsset.token),
						order.key.owner,
						buyer,
						order.key.sellAsset.tokenId,
						order.selling
					);
				} else {
					require(
						order.key.sellAsset.token == address(_IglooxStore),
						"invalid sell asset"
					);
					erc1155safeMintTransferFrom(
						IIglooxStore(order.key.sellAsset.token),
						order.key.owner,
						buyer,
						order.key.sellAsset.tokenId,
						order.selling,
						storeParams.blockExpiry,
						storeParams.v,
						storeParams.r,
						storeParams.s,
						storeParams.uri
					);
				}
			} else if (order.orderType == 2) {
				if (!isStore) {
					erc1155safeTransferFrom(
						IERC1155(order.key.buyAsset.token),
						buyer,
						order.key.owner,
						order.key.buyAsset.tokenId,
						order.buying
					);
				} else {
					require(
						order.key.buyAsset.token == address(_IglooxStore),
						"invalid buy asset"
					);
					erc1155safeMintTransferFrom(
						IIglooxStore(order.key.buyAsset.token),
						buyer,
						order.key.owner,
						order.key.buyAsset.tokenId,
						order.buying,
						storeParams.blockExpiry,
						storeParams.v,
						storeParams.r,
						storeParams.s,
						storeParams.uri
					);
				}
			}
		} else {
			revert("invalid assest ");
		}
	}

	function acceptBid(
		Order calldata order,
		Sig calldata sig,
		Sig calldata buyerSig,
		Sig calldata buyerFeeSig,
		address buyer,
		uint256 buyingAmount,
		uint256 royaltyFee,
		address payable royaltyReceipt,
		bool isStore,
		mintParams memory storeParams
	) external {
		require((block.timestamp <= order.expiryTime), "Signature expired");
		require(buyingAmount >= order.buying, "BuyingAmount invalid");

		require(order.orderType == 3, "Invalid order");
		require(order.key.owner == msg.sender, "Not owner");

		require(validateOrderSignatureView(order, sig) == order.key.owner,"Incorrect signature");
		require(validateBidOrderSignatureView(order, buyerSig, buyer, buyingAmount) == buyer,"Invalid bidder signature");
		require(validateBuyerFeeSigView(order, royaltyFee, royaltyReceipt, buyerFeeSig) == buyerFeeSigner,"Invalid Buyer fee signature");

		setCompleted(order, true);
		setCompletedBidOrder(order, true, buyer, buyingAmount);

		transferBidFee(
			order.key.buyAsset.token,
			order.key.owner,
			buyingAmount,
			royaltyReceipt,
			royaltyFee,
			buyer
		);
		transferToken(order, buyer, isStore, storeParams);
		emitMatchOrder(order, buyer);
	}

	function transferSellFee(
		Order calldata order,
		address payable royaltyReceipt,
		uint256 royaltyFee,
		address buyer
	) internal {
		if (order.key.buyAsset.token == address(0x00)) {
			require(msg.value == order.buying, "msg.value is invalid");
			transferAVAXFee(
				order.buying,
				order.key.owner,
				royaltyFee,
				royaltyReceipt
			);
		} else if (order.key.buyAsset.token == WAVAX) {
			transferWAVAXFee(
				order.buying,
				order.key.owner,
				buyer,
				royaltyFee,
				royaltyReceipt
			);
		} else {
			transferErc20Fee(
				order.key.buyAsset.token,
				order.buying,
				order.key.owner,
				buyer,
				royaltyFee,
				royaltyReceipt
			);
		}
	}

	function transferBuyFee(
		Order calldata order,
		address payable royaltyReceipt,
		uint256 royaltyFee,
		address buyer
	) internal {
		if (order.key.sellAsset.token == WAVAX) {
			transferWAVAXFee(
				order.selling,
				buyer,
				order.key.owner,
				royaltyFee,
				royaltyReceipt
			);
		} else {
			transferErc20Fee(
				order.key.sellAsset.token,
				order.selling,
				buyer,
				order.key.owner,
				royaltyFee,
				royaltyReceipt
			);
		}
	}

	function transferBidFee(
		address assest,
		address payable seller,
		uint256 buyingAmount,
		address payable royaltyReceipt,
		uint256 royaltyFee,
		address buyer
	) internal {
		if (assest == WAVAX) {
			transferWAVAXFee(
				buyingAmount,
				seller,
				buyer,
				royaltyFee,
				royaltyReceipt
			);
		} else {
			transferErc20Fee(
				assest,
				buyingAmount,
				seller,
				buyer,
				royaltyFee,
				royaltyReceipt
			);
		}
	}

	function transferAVAXFee(
		uint256 amount,
		address payable _seller,
		uint256 royaltyFee,
		address payable royaltyReceipt
	) internal {
		(
			uint256 protocolfee,
			uint256 secoundaryFee,
			uint256 taxfee,
			uint256 remaining
		) = transferFeeView(amount, royaltyFee);
		if (protocolfee > 0) {
			(beneficiaryAddress).transfer(protocolfee);
		}
		if ((secoundaryFee > 0) && (royaltyReceipt != address(0x0))) {
			royaltyReceipt.transfer(secoundaryFee);
		}
		if (remaining > 0) {
			_seller.transfer(remaining);
		}
		if (taxfee > 0) {
			payable(staking).transfer(taxfee);
		}
	}

	function transferWAVAXFee(
		uint256 amount,
		address _seller,
		address buyer,
		uint256 royaltyFee,
		address royaltyReceipt
	) internal {
		(
			uint256 protocolfee,
			uint256 secoundaryFee,
			uint256 taxfee,
			uint256 remaining
		) = transferFeeView(amount, royaltyFee);
		if (protocolfee > 0) {
			require(
				IWAVAX(WAVAX).transferFrom(
					buyer,
					beneficiaryAddress,
					protocolfee
				),
				"Failed protocol fee transfer"
			);
		}
		if ((secoundaryFee > 0) && (royaltyReceipt != address(0x00))) {
			require(
				IWAVAX(WAVAX).transferFrom(buyer, royaltyReceipt, secoundaryFee),
				"Failed royalty fee transfer"
			);
		}
		if (remaining > 0) {
			require(
				IWAVAX(WAVAX).transferFrom(buyer, _seller, remaining),
				"Failed transfer"
			);
		}
		if(taxfee > 0) {

			uint256 initialBalance = address(this).balance;
			IWAVAX(WAVAX).withdraw(taxfee);
			uint256 currentBalance = address(this).balance.sub(initialBalance);
			require(
				payable(staking).send(currentBalance),
				"Failed tax fee transfer");
		}
	}

	function transferErc20Fee(
		address token,
		uint256 amount,
		address _seller,
		address buyer,
		uint256 royaltyFee,
		address royaltyReceipt
	) internal {
		require(allowToken[token], "Not authorized token");

		(
			uint256 protocolfee,
			uint256 secoundaryFee,
			uint256 taxfee,
			uint256 remaining
		) = transferFeeView(amount, royaltyFee);
		if (protocolfee > 0) {
			require(
				IERC20(token).transferFrom(
					buyer,
					beneficiaryAddress,
					protocolfee
				),
				"Failed protocol fee transfer"
			);
		}
		if ((secoundaryFee > 0) && (royaltyReceipt != address(0x00))) {
			require(
				IERC20(token).transferFrom(
					buyer,
					royaltyReceipt,
					secoundaryFee
				),
				"Failed royalty fee transfer"
			);
		}
		if (remaining > 0) {
			require(
				IERC20(token).transferFrom(buyer, _seller, remaining),
				"Failed transfer"
			);
		}
		if (taxfee > 0) {
			require(
				IERC20(staking).transferFrom(buyer, staking, taxfee),
				"Failed transfer transfer"
			);
		}
	}

	function transferFeeView(uint256 amount, uint256 royaltyPcent)
		public
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		uint256 protocolFee = (amount.mul(beneficiaryFee)).div(1000);
		uint256 secoundaryFee;
		if (royaltyPcent > royaltyFeeLimit) {
			secoundaryFee = (amount.mul(royaltyFeeLimit)).div(1000);
		} else {
			secoundaryFee = (amount.mul(royaltyPcent)).div(1000);
		}
		uint256 Fee = (amount.mul(taxFee).div(1000));
		uint256 remaining = amount.sub(protocolFee.add(secoundaryFee).add(Fee));
		

		return (protocolFee, secoundaryFee,Fee, remaining);
	}

	function emitMatchOrder(Order memory order, address buyer) internal {
		emit MatchOrder(
			order.key.sellAsset.token,
			order.key.sellAsset.tokenId,
			order.selling,
			order.key.owner,
			order.key.buyAsset.token,
			order.key.buyAsset.tokenId,
			order.buying,
			buyer,
			order.orderType
		);
	}

	function cancel(Order calldata order) external {
		require(order.key.owner == msg.sender, "Not an owner");
		setCompleted(order, true);
		emit Cancel(
			order.key.sellAsset.token,
			order.key.sellAsset.tokenId,
			msg.sender,
			order.key.buyAsset.token,
			order.key.buyAsset.tokenId
		);
	}

	function validateBuyerFeeSigView(
		Order memory order,
		uint256 buyerFee,
		address royaltyReceipt,
		Sig memory sig
	) public pure returns (address) {
		return
			prepareBuyerFeeMessage(order, buyerFee, royaltyReceipt).recover(
				sig.v,
				sig.r,
				sig.s
			);
	}

	function toAVAXSignedMessageHash(bytes32 hash, Sig memory sig)
		public
		pure
		returns (address signer)
	{
		signer = hash.recover(sig.v, sig.r, sig.s);
	}

	function setBeneficiary(address payable newBeneficiary) external onlyOwner {
		require(newBeneficiary != address(0x00), "Zero address");
		beneficiaryAddress = newBeneficiary;
		emit Beneficiary(newBeneficiary);
	}

	function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
		require(newBuyerFeeSigner != address(0x00), "Zero address");
		buyerFeeSigner = newBuyerFeeSigner;
		emit BuyerFeeSigner(newBuyerFeeSigner);
	}

	function setBeneficiaryFee(uint256 newbeneficiaryfee) external onlyOwner {
		beneficiaryFee = newbeneficiaryfee;
		emit BeneficiaryFee(newbeneficiaryfee);
	}

	function setRoyaltyFeeLimit(uint256 newRoyaltyFeeLimit) external onlyOwner {
		royaltyFeeLimit = newRoyaltyFeeLimit;
		emit RoyaltyFeeLimit(newRoyaltyFeeLimit);
	}

	function setTokenStatus(address token, bool status) external onlyOwner {
		require(token != address(0x00), "Zero address");
		allowToken[token] = status;
		emit AllowToken(token, status);
	}

	function setIglooxStore(address newIglooxStore) external onlyOwner {
		require(newIglooxStore != address(0x00), "Zero address");
		_IglooxStore = IIglooxStore(newIglooxStore);
		emit SetMintableStore(newIglooxStore);
	}

	function inCaseTokensGetStuck(address _token) external onlyOwner {
		if (_token != address(0x000)) {
			uint256 amount = IERC20(_token).balanceOf(address(this));
			IERC20(_token).transfer(msg.sender, amount);
		} else {
			(msg.sender).transfer(address(this).balance);
		}
	}

	function IglooxStore() external view returns (address) {
		return address(_IglooxStore);
	}
}