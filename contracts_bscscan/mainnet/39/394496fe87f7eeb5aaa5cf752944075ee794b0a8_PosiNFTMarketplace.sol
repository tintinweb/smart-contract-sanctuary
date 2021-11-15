pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./library/Auction.sol";

interface IUniswapV2Router01{
		function factory() external pure returns (address);
    function WETH() external pure returns (address);
		function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
			external
			payable
			returns (uint[] memory amounts);
}


contract PosiNFTMarketplace is Initializable, ReentrancyGuardUpgradeable {
		using Auction for Auction.Data;
		using AuctionGetter for Auction.Data;
		using SafeMath for uint256;
		IERC20 public posi;
    uint256 public auctionIndex;
		uint256 public minDuration;
		IUniswapV2Router01 swapRouter;
		mapping(uint256 => Auction.Data) public auctions;
		uint256 public marketIndex;
		struct MarketData {
			IERC721 nft;
			uint256 tokenId;
			uint256 price;
			bool isSold;
			address purchaser;
			address seller;
		}
		mapping(uint256 => MarketData) public markets;

		event AuctionListed(uint256 indexed id, address seller, address nft, uint256 tokenId);
		event Bid(uint256 indexed id, address bidder, uint256 price, uint256 profit);
		event NFTReceived(address operator, address from, uint256 tokenId, bytes data);
		event Collected(uint256 indexed id);
		event CollectedBackNFT(uint256 indexed id);
		event MarketListed(uint256 indexed id, address seller, address nft, uint256 tokenId, uint256 price);
		event MarketPurchased(uint256 indexed id, address purchaser);

		function initialize() public initializer {
			__ReentrancyGuard_init();
			swapRouter = IUniswapV2Router01(0x10ED43C718714eb63d5aA57B78B54704E256024E);
			posi = IERC20(0x5CA42204cDaa70d5c773946e69dE942b85CA6706);
			minDuration = 12 hours;
		}

    fallback() external {
        revert();
    }

		function getAuctionData(uint256 _id) public view returns (
			address seller,
			address lastBidder,
			address nft,
			uint256 tokenId,
			uint256 lastPrice,
			uint256 raisedAmount,
			uint256 startedAt,
			uint256 endingAt,
			uint256 status
		) {
			Auction.Data storage auctionData = auctions[_id];
			seller = auctionData.seller;
			lastBidder = auctionData.lastBidder;
			nft = address(auctionData.nft);
			tokenId = auctionData.tokenId;
			lastPrice = auctionData.lastPrice;
			raisedAmount = auctionData.raisedAmount;
			startedAt = auctionData.startedAt;
			endingAt = auctionData.getEndingAt();
			status = auctionData.getStatus();
		}

		// list on direct purchasing market
		function listMarket(address _nft, uint256 _tokenId, uint256 _price) external {
			require(_tokenId != 0, "invalid token");
			IERC721(_nft).safeTransferFrom(msg.sender, address(this), _tokenId);
			marketIndex++;
			markets[marketIndex] = MarketData({
				nft: IERC721(_nft),
				tokenId: _tokenId,
				price: _price,
				isSold: false,
				purchaser: address(0),
				seller: msg.sender
			});
			emit MarketListed(marketIndex, msg.sender, _nft, _tokenId, _price);
		}

		function purchaseByBNB(uint256 _id) external payable nonReentrant {
			MarketData storage marketData = markets[_id];
			require(!marketData.isSold, "Purchased");
			address[] memory paths = new address[](2);
			paths[0] = swapRouter.WETH();
			paths[1] = address(posi);
			uint[] memory amounts = swapRouter.swapETHForExactTokens{value: msg.value}(marketData.price.mul(1011).div(1000), paths, address(this), block.timestamp+15 minutes);
			_completePurchase(_id);

		}

		function purchase(uint256 _id) external {
			MarketData storage marketData = markets[_id];
			require(!marketData.isSold, "Purchased");
			// cover RFI fees
			posi.transferFrom(msg.sender, address(this), marketData.price.mul(1011).div(1000));
			_completePurchase(_id);
		}

		// auction listing
    function list(address _nft, uint256 _tokenId, uint256 _startingPrice, uint256 _duration) external {
			require(_tokenId != 0, "invalid token");
			require(_duration >= minDuration, "invalid duration");

			IERC721(_nft).safeTransferFrom(msg.sender, address(this), _tokenId);
			auctionIndex++;
			auctions[auctionIndex] = Auction.Data({
				seller: msg.sender,
				lastBidder: address(0),
				lastPrice: _startingPrice,
				nft: IERC721(_nft),
				tokenId: _tokenId,
				duration: _duration,
				startedAt: block.timestamp,
				isTaken: false,
				raisedAmount: 0
			});
			emit AuctionListed(auctionIndex, msg.sender, _nft, _tokenId);
    }

		function bidBNB(uint256 _id) external payable nonReentrant {
			Auction.Data storage auction = auctions[_id];
			require(auction.getStatus() == 1, "invalid status");
			(uint256 newAmount,uint256 increaseAmount,uint256 previousBidderReward,uint256 sellerAmount) = auction.getBidAmount();
			address[] memory paths = new address[](2);
			paths[0] = swapRouter.WETH();
			paths[1] = address(posi);
			uint[] memory amounts = swapRouter.swapETHForExactTokens{value: msg.value}(newAmount.mul(1011).div(1000), paths, address(this), block.timestamp+15 minutes);

			if(previousBidderReward > 0){
				posi.transfer(auction.lastBidder, auction.lastPrice.add(previousBidderReward));
			}
			auction.updateState(msg.sender, newAmount, sellerAmount);
			emit Bid(_id, msg.sender, newAmount, previousBidderReward);
		}

    function bid(uint256 _id) external {
			Auction.Data storage auction = auctions[_id];
			require(auction.getStatus() == 1, "invalid status");
			(uint256 newAmount,uint256 increaseAmount,uint256 previousBidderReward,uint256 sellerAmount) = auction.getBidAmount();
			// plus RFI fee
			posi.transferFrom(msg.sender, address(this), newAmount.mul(1011).div(1000));
			if(previousBidderReward > 0){
				posi.transfer(auction.lastBidder, auction.lastPrice.add(previousBidderReward));
			}
			auction.updateState(msg.sender, newAmount, sellerAmount);
			emit Bid(_id, msg.sender, newAmount, previousBidderReward);
    }

		function collect(uint256 _id) external {
			Auction.Data storage auction = auctions[_id];
			require(auction.getStatus() == 2, "invalid status");
			require(auction.lastBidder == msg.sender || auction.seller == msg.sender, "not authorized");
			require(!auction.isTaken, "alrady collected");
			// transfer NFT to lastBidder
			auction.nft.safeTransferFrom(address(this), auction.lastBidder, auction.tokenId);

			//send sold amount to seller
			posi.transfer(auction.seller, auction.raisedAmount);
			auction.isTaken = true;
			emit Collected(_id);
		}


		function getBackNFT(uint256 _id) external {
			Auction.Data storage auction = auctions[_id];
			require(auction.seller == msg.sender, "only seller");
			require(auction.getStatus() == 3, "invalid status");
			require(!auction.isTaken, "already taken");
			auction.nft.safeTransferFrom(address(this), auction.seller, auction.tokenId);
			auction.isTaken = true;
			emit  CollectedBackNFT(_id);
		}
		function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        //only receive the _nft staff
        if(address(this) != operator) {
            //invalid from nft
            return 0;
        }
        //success
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

		function _completePurchase(uint256 _id) private {
			MarketData storage marketData = markets[_id];
			marketData.nft.safeTransferFrom(address(this), msg.sender, marketData.tokenId);
			posi.transfer(marketData.seller, marketData.price);
			marketData.isSold = true;
			marketData.purchaser = msg.sender;
			emit MarketPurchased(_id, msg.sender);
		}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AuctionGetter {
	using SafeMath for uint256;
	function getEndingAt(Auction.Data storage _data) internal view returns(uint256) {
		return _data.startedAt.add(_data.duration);
	}

	function getStatus(Auction.Data storage _data) internal view returns(uint256) {
		/*
		* 1: RUNNING;
	  * 2: DEALED;
	  * 3: FAILED;
	  * 0: NOT RUNNING;
		*/
	  if(_data.startedAt == 0) return 0;
	  uint256 _endingAt = _data.startedAt.add(_data.duration);
		if( block.timestamp <= _endingAt){
			return 1;
		}else if(block.timestamp > _endingAt) {
			if(_data.lastBidder == address(0)){
				return 3;
			}else{
				return 2;
			}
		}
	}


}

library Auction {
	using SafeMath for uint256;
	using AuctionGetter for Data;
	enum Status { OPENING, ENDED }
	struct Data {
			// Current owner of NFT
			address seller;
			address lastBidder;
			IERC721 nft;
			uint256 tokenId;
			// Price (in wei) at beginning of auction
			uint256 lastPrice;
			// POSI amount raised
			uint256 raisedAmount;
			// Duration (in seconds) of auction
			uint256 duration;
			// Time when auction started
			// NOTE: 0 if this auction has been concluded
			uint256 startedAt;
			bool isTaken;
	}

	function updateState(Data storage _data, address _newBidder, uint256 _newPrice, uint256 _newRaisedAmount) internal {
		_data.lastBidder = _newBidder;
		_data.lastPrice = _newPrice;
		_data.raisedAmount = _newRaisedAmount;
		if(_data.getEndingAt().sub(block.timestamp) < 1 hours){
			_data.duration = _data.duration.add(10 minutes);
		}
	}

	function getBidAmount(Data storage _data) internal view returns(
		uint256 newPrice,
	 	uint256 increaseAmount, 
		uint256 previousBidderReward,
	 	uint256 sellerAmount
	) {
		// 10% increase
		if(_data.lastBidder == address(0)){
			newPrice = _data.lastPrice;
			sellerAmount = newPrice;
		}else{
			increaseAmount = _data.lastPrice.div(10);
			previousBidderReward = increaseAmount.mul(2).div(10);
			newPrice = _data.lastPrice.add(increaseAmount);
			sellerAmount = newPrice.sub(previousBidderReward);
		}
	}

	function validateBidding(Data storage _data) internal view {
		require(_data.getStatus() == 1, "auction is not opening");
	}


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

