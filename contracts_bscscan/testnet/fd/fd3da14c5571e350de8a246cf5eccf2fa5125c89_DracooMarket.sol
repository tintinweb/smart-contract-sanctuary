// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

library EnumerableSet {
    struct UintSet {
        uint256[] _values;
        mapping (uint256 => uint256) _indexes;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        if (contains(set, value)) {
            return false;
        }

        set._values.push(value);
        set._indexes[value] = set._values.length;
        return true;
    }


    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            uint256 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            set._values.pop();
            delete set._indexes[value];

            return true;
        } 
        else {
            return false;
        }
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        require(set._values.length < index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    function values(UintSet storage set) internal view returns (uint256[] memory _vals) {
        return set._values;
    }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract DracooMarket is Context, Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    struct NFTOffer {
        address nftAddress;
        address erc20Address;
        bool isForSale;
        uint256 index;  // tokenId
        address payable seller;
        uint256 price;
    }

    bool public isMarketPaused;
    uint256 public fee;

    // BNB
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // nftAddress is added to the market or not
    mapping(address => bool) private _nftAvailable;
    // erc20Address is available or not
    mapping(address => bool) private _erc20Available;
    // nftAddress => tokenId => is on sale or not
    mapping(address => mapping(uint256 => bool)) private _isNftOnSale;

    Counters.Counter private _transactionId;
    EnumerableSet.UintSet private _onSaleNftTransactionIds;
    // transactionId => NFTOffer
    mapping(uint256 => NFTOffer) private _nftOffer;


    event OfferNftForSale(uint256 indexed transactionId, address indexed nftAddress, uint256 indexed tokenId, address seller, address erc20Address, uint256 salePrice);
    event WithdrawNftSelling(uint256 indexed transactionId, address indexed nftAddress, uint256 indexed tokenId, address seller);
    event BuyNft(uint256 indexed transactionId, address indexed nftAddress, uint256 indexed tokenId, address seller, address buyer, address erc20Address, uint256 salePrice);
    event ChangeNftPrice(uint256 indexed transactionId, address indexed nftAddress, uint256 indexed tokenId, address seller, address erc20Address, uint256 oldPrice, uint256 newPrice);

    constructor () public {
        isMarketPaused = true;
        fee = 5;   // 5%, 0.05
        _erc20Available[ETH_ADDRESS] = true;
    }

    function pauseMarket(bool pause) public onlyOwner {
        isMarketPaused = pause;
    }

    function setFee(uint256 newFee) public onlyOwner {
        fee = newFee;
    }

    function setAvailableNft(address nftAddress, bool newState) public onlyOwner {
        _nftAvailable[nftAddress] = newState;
    }

    function setAvailableERC20(address erc20Address, bool newState) public onlyOwner {
        _erc20Available[erc20Address] = newState;
    }

    function withdrawBNB(address payable to) public onlyOwner {
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }

    function withdrawERC20(address erc20Address, address to) public onlyOwner {
        IERC20 erc20Token = IERC20(erc20Address);
        uint256 balance = erc20Token.balanceOf(address(this));
        erc20Token.safeTransfer(to, balance);
    }

    function checkNftAvailable(address nftAddress) public view returns (bool) {
        return _nftAvailable[nftAddress];
    }

    function checkERC20Support(address erc20Address) public view returns (bool) {
        return _erc20Available[erc20Address];
    }

    function checkIsNftOnSale(address nftAddress, uint256 tokenId) public view returns (bool) {
        require(_nftAvailable[nftAddress], "this Nft is not supported to sell here");
        return _isNftOnSale[nftAddress][tokenId];
    }

    function getOnSaleNftTransactionIds() external view returns (uint256[] memory) {
        return _onSaleNftTransactionIds.values();
    }

    function getOnSaleNftTransactionAmounts() external view returns (uint256) {
        return _onSaleNftTransactionIds.length();
    }

    function checkNftOffer(uint256 transactionId) external view returns (NFTOffer memory) {
        return _nftOffer[transactionId];
    }

    // owner MUST call Dracoo contract's "setApproveForAll" before use this method
    function offerNftForSale(address nftAddress, uint256 tokenId, address erc20Address, uint256 salePrice) public nonReentrant returns (uint256) {
        require(isMarketPaused == false, "market is paused now, try later");
        require(_nftAvailable[nftAddress], "this Nft is not supported to sell here");
        require(_erc20Available[erc20Address], "This Token is NOT supported");
        require(!_isNftOnSale[nftAddress][tokenId], "this nft's tokenId is already on sale now");
        require(salePrice > 0, "sale price must > 0");
        IERC721 nftObject = IERC721(nftAddress); 
        require(nftObject.getApproved(tokenId) == address(this) || nftObject.isApprovedForAll(_msgSender(), address(this)), "not approved");

        // start from #1
        _transactionId.increment();
        uint256 currentId = _transactionId.current();
        _nftOffer[currentId] = NFTOffer({
                                    nftAddress: nftAddress,
                                    erc20Address: erc20Address,
                                    isForSale: true,
                                    index: tokenId,
                                    seller: _msgSender(),
                                    price: salePrice});
        _onSaleNftTransactionIds.add(currentId);
        _isNftOnSale[nftAddress][tokenId] = true;

        nftObject.safeTransferFrom(_msgSender(), address(this), tokenId);

        emit OfferNftForSale(currentId, nftAddress, tokenId, _msgSender(), erc20Address, salePrice);
        return currentId;
    }

    function withdrawNftSelling(uint256 transactionId) public nonReentrant returns (uint256) {
        require(isMarketPaused == false, "market is paused now, try later");
        NFTOffer storage nftOffer = _nftOffer[transactionId];
        require(nftOffer.seller == _msgSender(), "you are not the owner of this NFT");
        require(nftOffer.isForSale, "this transactionId is not selling now");

        nftOffer.erc20Address = address(0);
        nftOffer.isForSale = false;
        nftOffer.price = 0;

        _onSaleNftTransactionIds.remove(transactionId);
        _isNftOnSale[nftOffer.nftAddress][nftOffer.index] = false;

        IERC721 nftObject = IERC721(nftOffer.nftAddress);
        nftObject.safeTransferFrom(address(this), _msgSender(), nftOffer.index);

        emit WithdrawNftSelling(transactionId, nftOffer.nftAddress, nftOffer.index, _msgSender());
        return transactionId;
    }

    function changeNftPrice(uint256 transactionId, uint256 newPrice) public nonReentrant returns (uint256) {
        require(isMarketPaused == false, "market is paused now, try later");
        NFTOffer storage nftOffer = _nftOffer[transactionId];
        require(nftOffer.seller == _msgSender(), "you are not the owner of this NFT");
        require(nftOffer.isForSale, "this transactionId is not selling now");

        uint256 oldPrice = nftOffer.price;
        nftOffer.price = newPrice;

        emit ChangeNftPrice(transactionId, nftOffer.nftAddress, nftOffer.index, nftOffer.seller, nftOffer.erc20Address, oldPrice, newPrice);
        return transactionId;
    }

    // if this transactionId is traded by ERC20 token, it must be approve to this contract
    function buyNft(uint256 transactionId) public payable nonReentrant returns (uint256){
        require(isMarketPaused == false, "market is paused now, try later");
        NFTOffer storage nftOffer = _nftOffer[transactionId];
        require(nftOffer.isForSale, "this transactionId is not selling now");
        address theSeller = nftOffer.seller;
        address erc20 = nftOffer.erc20Address;
        uint256 thePrice = nftOffer.price;
        require(_msgSender() != theSeller, "owner can not be the buyer");

        uint256 totalFee = thePrice.mul(fee).div(100);
        uint256 remaining = thePrice.sub(totalFee);

        if (erc20 == ETH_ADDRESS) {   // BNB payment
            require(msg.value >= thePrice, "not enough BNB balance to buy");
            payable(theSeller).transfer(remaining);
        } else {     // ERC20 token payment
            IERC20 erc20Token = IERC20(erc20);
            require(erc20Token.balanceOf(_msgSender()) >= thePrice, "not enough ERC20 token balance to buy");
            erc20Token.safeTransferFrom(_msgSender(), theSeller, remaining);
            erc20Token.safeTransferFrom(_msgSender(), address(this), totalFee);
        }

        nftOffer.isForSale = false;
        nftOffer.price = 0;
        nftOffer.seller = address(0);
        nftOffer.erc20Address = address(0);
        _onSaleNftTransactionIds.remove(transactionId);
        _isNftOnSale[nftOffer.nftAddress][nftOffer.index] = false;

        IERC721(nftOffer.nftAddress).safeTransferFrom(address(this), _msgSender(), nftOffer.index);

        emit BuyNft(transactionId, nftOffer.nftAddress, nftOffer.index, theSeller, _msgSender(), erc20, thePrice);
        return transactionId;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}