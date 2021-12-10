// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/IRegistry.sol";

//TODO: maybe there should be an emergency escrow sweep and stale auction resolution
// for if an auction is won but the winner doesn't claim

interface IMusicNFT {
    function royaltyInfo(uint256 tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function supportsInterface(bytes4 interfaceID) external returns (bool);
}

contract Auction is IAuction, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // address alias for using ETH as a currency
    address constant ETH = address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa);

    Counters.Counter private _auctionId;
    IRegistry private Registry;

    mapping(uint256 => Auction) private auctions;
    mapping(uint256 => bool) private cancelled;
    mapping(uint256 => bool) private claimed;
    mapping(uint256 => address) private highestBid;
    mapping(uint256 => mapping(address => Bid)) private bids;
    // user => token => amount
    mapping(address => mapping(address => uint256)) private claimableFunds;
    // token => amount
    mapping(address => uint256) private escrow;
    // used for checking uniqueness on the UUIDs
    mapping(string => bool) private dbIds;

    constructor(address registry) {
        Registry = IRegistry(registry);
    }

    function getAuctionDetails(uint256 auctionId)
        external
        view
        returns (Auction memory)
    {
        require(
            auctionId <= _auctionId.current() && auctionId > 0,
            "auction does not exist"
        );
        return auctions[auctionId];
    }

    function getAuctionStatus(uint256 auctionId)
        public
        view
        override
        returns (string memory)
    {
        require(
            auctionId <= _auctionId.current() && auctionId > 0,
            "auction does not exist"
        );
        if (cancelled[auctionId] || !Registry.isPlatformContract(address(this)))
            return "CANCELLED";
        if (claimed[auctionId]) return "ENDED & CLAIMED";
        if (block.timestamp < auctions[auctionId].startTime) return "PENDING";
        if (
            block.timestamp >= auctions[auctionId].startTime &&
            block.timestamp < auctions[auctionId].endTime
        ) return "ACTIVE";
        if (block.timestamp > auctions[auctionId].endTime) return "ENDED";
        revert("error");
    }

    function getClaimableBalance(address account, address token)
        external
        view
        returns (uint256)
    {
        return claimableFunds[account][token];
    }

    function getBidDetails(uint256 auctionId, address bidder)
        external
        view
        returns (Bid memory)
    {
        return bids[auctionId][bidder];
    }

    function getHighestBidder(uint256 auctionId)
        external
        view
        returns (address)
    {
        return highestBid[auctionId];
    }

    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice,
        address currency,
        string memory dbId
    ) external nonReentrant returns (uint256) {
        IMusicNFT NftContract = IMusicNFT(nftContract);
        require(
            Registry.isPlatformContract(nftContract) == true,
            "NFT not in approved contract"
        );
        require(
            Registry.isPlatformContract(address(this)) == true,
            "This contract is deprecated"
        );
        require(
            Registry.isApprovedCurrency(currency) == true,
            "currency not supported"
        );
        require(
            NftContract.supportsInterface(0x2a55205a),
            "contract must support ERC2981"
        );
        require(
            NftContract.balanceOf(msg.sender, tokenId) > 0,
            "does not own NFT"
        );
        require(endTime > startTime, "error in start/end params");
        require(dbIds[dbId] == false, "auction:UUID already in use");
        dbIds[dbId] = true;

        _auctionId.increment();
        uint256 auctionId = _auctionId.current();

        auctions[auctionId] = Auction({
            id: auctionId,
            owner: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            startTime: startTime,
            endTime: endTime,
            reservePrice: reservePrice,
            currency: currency,
            dbId: dbId
        });

        NftContract.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");

        emit NewAuction(auctionId, auctions[auctionId]);

        return auctionId;
    }

    function bid(
        uint256 auctionId,
        uint256 amountFromBalance,
        uint256 externalFunds
    ) external payable nonReentrant returns (bool) {
        require(
            Registry.isPlatformContract(address(this)) == true,
            "This contract is deprecated"
        );
        require(
            keccak256(bytes(getAuctionStatus(auctionId))) ==
                keccak256(bytes("ACTIVE")),
            "auction is not active"
        );
        uint256 totalAmount = amountFromBalance +
            externalFunds +
            // this allows the top bidder to top off their bid
            bids[auctionId][msg.sender].amount;
        require(
            totalAmount > bids[auctionId][highestBid[auctionId]].amount,
            "bid not high enough"
        );
        require(
            totalAmount >= auctions[auctionId].reservePrice,
            "bid is lower than reserve price"
        );
        require(
            amountFromBalance <=
                claimableFunds[msg.sender][auctions[auctionId].currency],
            "not enough balance"
        );

        if (auctions[auctionId].currency != ETH) {
            IERC20 Token = IERC20(auctions[auctionId].currency);

            Token.safeTransferFrom(msg.sender, address(this), externalFunds);
        } else {
            require(msg.value == externalFunds, "mismatch of value and args");
            require(
                msg.value + amountFromBalance >
                    bids[auctionId][highestBid[auctionId]].amount,
                "insufficient ETH sent"
            );
        }

        // next highest bid can be made claimable now,
        // also helps for figuring out how much more net is in escrow
        address lastBidder = highestBid[auctionId];
        uint256 lastAmount = bids[auctionId][lastBidder].amount;
        escrow[auctions[auctionId].currency] += totalAmount - lastAmount;

        if (bids[auctionId][msg.sender].bidder == address(0)) {
            bids[auctionId][msg.sender].bidder = msg.sender;
        }

        if (lastBidder != msg.sender) {
            bids[auctionId][lastBidder].amount = 0;
            claimableFunds[lastBidder][
                auctions[auctionId].currency
            ] += lastAmount;
            emit BalanceUpdated(
                lastBidder,
                auctions[auctionId].currency,
                claimableFunds[lastBidder][auctions[auctionId].currency]
            );
        }
        bids[auctionId][msg.sender].amount = totalAmount;
        bids[auctionId][msg.sender].timestamp = block.timestamp;

        highestBid[auctionId] = msg.sender;

        emit BidPlaced(auctionId, totalAmount);

        return true;
    }

    function claimNft(uint256 auctionId, address recipient)
        external
        returns (bool)
    {
        require(
            msg.sender == highestBid[auctionId] ||
                msg.sender == auctions[auctionId].owner,
            "cannot claim nft"
        );
        bytes32 status = keccak256(bytes(getAuctionStatus(auctionId)));
        require(
            status == keccak256(bytes("CANCELLED")) ||
                status == keccak256(bytes("ENDED")),
            "nft not available for claiming"
        );
        IMusicNFT Nft = IMusicNFT(auctions[auctionId].nftContract);
        uint256 totalFundsToPay = msg.sender == auctions[auctionId].owner
            ? 0
            : bids[auctionId][highestBid[auctionId]].amount;
        if (msg.sender == highestBid[auctionId]) {
            require(
                block.timestamp > auctions[auctionId].endTime,
                "cannot claim from auction"
            );
            require(
                bids[auctionId][highestBid[auctionId]].amount >=
                    auctions[auctionId].reservePrice,
                "reserve price not met"
            );
        } else if (msg.sender == auctions[auctionId].owner) {
            require(
                cancelled[auctionId] ||
                    (bids[auctionId][highestBid[auctionId]].amount <
                        auctions[auctionId].reservePrice &&
                        block.timestamp > auctions[auctionId].endTime),
                "owner cannot reclaim nft"
            );
        }

        // accounting logic
        if (totalFundsToPay > 0) {
            escrow[auctions[auctionId].currency] -= totalFundsToPay;
            // if this is from successful auction
            (address artistAddress, uint256 royalties) = Nft.royaltyInfo(
                auctions[auctionId].tokenId,
                totalFundsToPay
            );

            // system fee
            (address systemWallet, uint256 fee) = Registry.feeInfo(
                totalFundsToPay
            );
            totalFundsToPay -= fee;
            claimableFunds[systemWallet][auctions[auctionId].currency] += fee;
            emit BalanceUpdated(
                systemWallet,
                auctions[auctionId].currency,
                claimableFunds[systemWallet][auctions[auctionId].currency]
            );

            // artist royalty if artist isn't the seller
            if (auctions[auctionId].owner != artistAddress) {
                totalFundsToPay -= royalties;
                claimableFunds[artistAddress][
                    auctions[auctionId].currency
                ] += royalties;
                emit BalanceUpdated(
                    artistAddress,
                    auctions[auctionId].currency,
                    claimableFunds[artistAddress][auctions[auctionId].currency]
                );
            }

            // seller gains
            claimableFunds[auctions[auctionId].owner][
                auctions[auctionId].currency
            ] += totalFundsToPay;
            emit BalanceUpdated(
                auctions[auctionId].owner,
                auctions[auctionId].currency,
                claimableFunds[auctions[auctionId].owner][
                    auctions[auctionId].currency
                ]
            );
        }

        Nft.safeTransferFrom(
            address(this),
            recipient,
            auctions[auctionId].tokenId,
            1,
            ""
        );
        claimed[auctionId] = true;

        emit ClaimNFT(
            auctions[auctionId].id,
            msg.sender,
            recipient,
            bids[auctionId][highestBid[auctionId]].amount
        );

        return true;
    }

    function claimFunds(address tokenContract) external {
        require(
            claimableFunds[msg.sender][tokenContract] > 0,
            "nothing to claim"
        );
        uint256 payout = claimableFunds[msg.sender][tokenContract];
        if (tokenContract != ETH) {
            IERC20 Token = IERC20(tokenContract);
            claimableFunds[msg.sender][tokenContract] = 0;
            Token.safeTransfer(msg.sender, payout);
        } else {
            claimableFunds[msg.sender][tokenContract] = 0;
            (bool success, ) = msg.sender.call{value: payout}("");
            require(success, "ETH payout failed");
        }
        emit BalanceUpdated(
            msg.sender,
            tokenContract,
            claimableFunds[msg.sender][tokenContract]
        );
    }

    function cancelAuction(uint256 auctionId) external {
        require(
            msg.sender == auctions[auctionId].owner || msg.sender == owner(),
            "only owner or sale creator"
        );
        cancelled[auctionId] = true;
        // current highest bid moves from escrow to being reclaimable
        address highestBidder = highestBid[auctionId];
        uint256 _highestBid = bids[auctionId][highestBidder].amount;

        escrow[auctions[auctionId].currency] -= _highestBid;
        claimableFunds[highestBidder][
            auctions[auctionId].currency
        ] += _highestBid;
        emit BalanceUpdated(
            highestBidder,
            auctions[auctionId].currency,
            claimableFunds[highestBidder][auctions[auctionId].currency]
        );
        emit AuctionCancelled(auctionId);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes memory data
    ) external pure returns (bytes4) {
        // 0xf23a6e61 = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
        return 0xf23a6e61;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity^0.8.10;

interface IAuction {
  struct Auction {
    uint256 id; // id of auction
    address owner; // address of NFT owner
    address nftContract;
    uint256 tokenId;
    uint256 startTime;
    uint256 endTime;
    uint256 reservePrice; // may need to be made private
    address currency; // use zero address or 0xeee for ETH
    string dbId; // used to sync database
  }

  struct Bid {
    uint256 auctionId;
    address bidder;
    uint256 amount;
    uint256 timestamp;
  }

  event NewAuction(uint256 indexed auctionId, Auction newAuction);
  event AuctionCancelled(uint256 indexed auctionId);
  event BidPlaced(uint256 auctionId, uint256 amount);
  event ClaimNFT(uint256 auctionId, address winner, address recipient, uint256 amount);
  event BalanceUpdated(
    address indexed accountOf, 
    address indexed tokenAddress, 
    uint256 indexed newBalance
  );

  function getAuctionDetails(uint256 auctionId) external view returns(Auction memory);
  function getAuctionStatus(uint256 auctionId) external view returns(string memory);
  function getClaimableBalance(address account, address token) external view returns(uint256);
  //note: the next function (getBidDetails) may be removed
  function getBidDetails(uint256 auctionId, address bidder) external view returns(Bid memory);
  function getHighestBidder(uint256 auctionId) external view returns(address);
  function createAuction(
    address nftContract,
    uint256 tokenId,
    uint256 startTime,
    uint256 endTime,
    uint256 reservePrice,
    address currency,
    string memory dbId
  ) external returns(uint256);
  function bid(uint256 auctionId, uint256 fromBalance, uint256 externalFunds) external payable returns(bool);
  function claimNft(uint256 auctionId, address recipient) external returns(bool);
  function claimFunds(address tokenContract) external;
  function cancelAuction(uint256 auctionId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRegistry {
  event SystemWalletUpdated(address newWallet);
  event FeeVariablesChanged(uint256 indexed newFee, uint256 indexed newScale);
  event ContractStatusChanged(address indexed changed, bool indexed status);
  event CurrencyStatusChanged(address indexed changed, bool indexed status);

  function feeInfo(uint256 _salePrice) external view returns(address, uint256);
  function isPlatformContract(address toCheck) external view returns(bool);
  function isApprovedCurrency(address tokenContract) external view returns(bool);
  function setSystemWallet(address newWallet) external;
  function setFeeVariables(uint256 newFee, uint256 newScale) external;
  function setContractStatus(address toChange, bool status) external;
  function setCurrencyStatus(address tokenContract, bool status) external;
  function approveAllCurrencies() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}