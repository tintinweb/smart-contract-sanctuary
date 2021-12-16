// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title IBZ721Market
 * IBZ721Market - Smart Contract for IbizaToken NFT Marketplace
 */
contract IBZ721Market is Ownable {
    IERC20 private ERC20;
    IERC721 private NFT;
    using SafeMath for uint256;
    uint256 default_percentage = 5; // Which means 20%: 100 / 20 = 5;
    bool private panic_withdraw_allowed = false;
    uint256 public _marketsCounter;
    mapping(uint256 => mapping(address => uint256)) private _vault;
    mapping(uint256 => mapping(uint256 => uint256)) private _prices;
    mapping(uint256 => address) private _markets;
    mapping(address => uint256) private _marketPercentages;
    mapping(uint256 => uint256) private _ibzCashback;
    // Auctions
    struct Offer {
        address from;
        uint256 offer;
        uint256 timestamp;
    }
    struct Auction {
        uint256 start;
        uint256 end;
        uint256 reserve;
        address from;
    }
    mapping(uint256 => mapping(uint256 => Auction)) private _auctions;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Offer))) private _offers;
    mapping(uint256 => mapping(uint256 => uint256)) private _offersCounter;

    /*
        This method will allow to buy an nft with IBZ
    */
    function buyNft(uint256 _token, uint256 _tokenId)
        public
    {
        require(_markets[_token] != address(0), "IBZNFT: This market is not active");
        uint256 price = _prices[_token][_tokenId];
        require(price > 0, "IBZNFT: This NFT is not for sale with selected token");
        uint256 balance = erc20Balance(_token, msg.sender);
        require(balance >= price, "IBZNFT: Don't have enough ERC20 tokens");
        uint256 allowance = erc20Allowance(_token, msg.sender);
        require(allowance >= price, "IBZNFT: Contract can't move ERC20 tokens");
        address owner = NFT.ownerOf(_tokenId);
        require(owner != msg.sender, "IBZNFT: Can't buy from yourself");
        // Transfer tokens
        erc20TransferFrom(_token, msg.sender, address(this), price);
        // Transfer NFT
        NFT.transferFrom(owner, msg.sender, _tokenId);
        // Check if there's a cashback
        if(_ibzCashback[_tokenId] > 0) {
            _vault[0][msg.sender] = _vault[0][msg.sender] + _ibzCashback[_tokenId];
            _ibzCashback[_tokenId] = 0;
        }
        // Giving fees and earnings
        uint256 percentage = returnMarketplacePercentage(owner);
        uint256 fee = price.div(percentage);
        _vault[_token][address(this)] = _vault[_token][address(this)] + fee;
        uint256 earn = price.sub(fee);
        _vault[_token][owner] = _vault[_token][owner] + earn;
        // Resetting prices
        resetAllPrices(_tokenId);
    }

    /*
        This method will get ERC20 balance
    */

    function erc20Balance(uint256 _token, address _address) public returns (uint256) {
        require(_markets[_token] != address(0), "IBZNFT: This market is not active");
        ERC20 = IERC20(_markets[_token]);
        uint256 balance = ERC20.balanceOf(_address);
        return balance;
    }

    /*
        This method will return ERC20 allowance
     */

    function erc20Allowance(uint256 _token, address _address) public returns (uint256) {
        require(_markets[_token] != address(0), "IBZNFT: This market is not active");
        ERC20 = IERC20(_markets[_token]);
        uint256 allowance = ERC20.allowance(_address, address(this));
        return allowance;
    }

    /*
        This method will start ERC20 transferfrom
     */

    function erc20TransferFrom(uint256 _token, address _from, address _to, uint256 _amount) public {
        require(_markets[_token] != address(0), "IBZNFT: This market is not active");
        ERC20 = IERC20(_markets[_token]);
        ERC20.transferFrom(_from, _to, _amount);
    }

    /*
        This method will start ERC20 transfer
     */

    function erc20Transfer(uint256 _token, address _to, uint256 _amount) public {
        require(_markets[_token] != address(0), "IBZNFT: This market is not active");
        ERC20 = IERC20(_markets[_token]);
        ERC20.transfer(_to, _amount);
    }

    /*
        This method will allow parties to withdraw all IBZ
     */

    function withdrawFromVault(uint256 _token) public {
        uint256 balance = _vault[_token][msg.sender];
        require(balance > 0, 'IBZNFT: Nothing to withdraw!');
        erc20Transfer(_token, msg.sender, balance);
        _vault[_token][msg.sender] = 0;
    }
    
    /*
        This method will allow owner to withdraw from contract
     */

    function ownerWithdraw(uint256 _token) public onlyOwner {
        uint256 balance = _vault[_token][address(this)];
        require(balance > 0, 'IBZNFT: Nothing to withdraw!');
        erc20Transfer(_token, msg.sender, balance);
        _vault[_token][address(this)] = 0;
    }

    function returnMarketplacePercentage(address _minter) public view returns (uint256) {
        if(_marketPercentages[_minter] == 0){
            return default_percentage;
        }else{
            return _marketPercentages[_minter];
        }
    }

    function getCashbackForToken(uint256 _tokenId) public view returns (uint256) {
        return _ibzCashback[_tokenId];
    }
     
    /*
        This method will fix prices
     */

    function fixPrice(uint256 _token, uint256 _tokenId, uint256 _price) public {
        address owner = NFT.ownerOf(_tokenId);
        require(msg.sender == owner, "IBZNFT: Only owner can fix price");
        _prices[_token][_tokenId] = _price;
        // Resetting auctions
        resetAllAuctions(_tokenId);
    }
    
    /*
        This method return public price
     */
    function returnPrice(uint256 _token, uint256 _tokenId) public view returns(uint256) {
       return _prices[_token][_tokenId];
    }

    /*
        This method will reset all fixed prices
     */
    function resetAllPrices(uint256 _tokenId) private {
        for (uint i = 0; i <= _marketsCounter; i++) {
            _prices[i][_tokenId] = 0;
        }
    }

    /*
        This method will fix reserve price (start an auction)
     */

    function startAuction(uint256 _token, uint256 _tokenId, uint256 _reserve_price, uint256 _start_auction, uint256 _end_auction) public {
        address owner = NFT.ownerOf(_tokenId);
        require(msg.sender == owner, "IBZNFT: Only owner can start auctions");
        require(_auctions[_token][_tokenId].start == 0, "IBZNFT: An auction exists yet for this token");
        require(_start_auction > block.timestamp, "IBZNFT: Auction can't start in the past");
        require(_start_auction < _end_auction, "IBZNFT: Auction can't end before the start");
        resetAllAuctions(_tokenId);
        resetAllPrices(_tokenId);
        // Setting auction
        _auctions[_token][_tokenId].reserve = _reserve_price;
        _auctions[_token][_tokenId].start = _start_auction;
        _auctions[_token][_tokenId].end = _end_auction;
        _auctions[_token][_tokenId].from = msg.sender;
    }

    /*
        This method will reset an auction
     */
    function resetAuction(uint256 _token, uint256 _tokenId) private {
        _auctions[_token][_tokenId].reserve = 0;
        _auctions[_token][_tokenId].start = 0;
        _auctions[_token][_tokenId].end = 0;
        _auctions[_token][_tokenId].from = address(0);
        // Removing all offers
        for (uint i = 0; i < _offersCounter[_token][_tokenId]; i++){
            _offers[_token][_tokenId][i].offer = 0;
            _offers[_token][_tokenId][i].from = address(0);
            _offers[_token][_tokenId][i].timestamp = 0;
        }
        _offersCounter[_token][_tokenId] = 0;
    }

    function resetAllAuctions(uint256 _tokenId) private {
        for (uint i = 0; i <= _marketsCounter; i++) {
            resetAuction(i, _tokenId);
        }
    }

    /*
        This method return the auction as an array
     */
    function returnAuction(uint256 _token, uint256 _tokenId) public view returns(uint256, uint256, uint256, address) {
        return (
            _auctions[_token][_tokenId].start,
            _auctions[_token][_tokenId].end,
            _auctions[_token][_tokenId].reserve,
            _auctions[_token][_tokenId].from
        );
    }

    /*
        This method will return if an auction is still valid
    */

    function isAuctionValid(uint256 _token, uint256 _tokenId) public view returns (bool){
        address owner = NFT.ownerOf(_tokenId);
        Auction memory auction = _auctions[_token][_tokenId];
        if(auction.from == owner) {
            return true;
        } else {
            return false;
        }
    }

    /*
        This method will allow to stop an auction
    */
    function removeAuction(uint256 _token, uint256 _tokenId)
        public
    {
        address owner = NFT.ownerOf(_tokenId);
        require(owner == msg.sender, "IBZNFT: Only owner can remove the auction");
        resetAuction(_token, _tokenId);
    }

    /*
        This method will allow to make an offer into an auction
    */
    function makeOffer(uint256 _token, uint256 _tokenId, uint256 _offer)
        public
    {
        require(isAuctionValid(_token, _tokenId), "IBZNFT: Auction no longer valid");
        require(_token <= 1, "IBZNFT: ERC20 token not recognized");
        uint256 price = _auctions[_token][_tokenId].reserve;
        require(price > 0, "IBZNFT: This NFT is not in auction");
        require(block.timestamp > _auctions[_token][_tokenId].start, "IBZNFT, Auction isn't started");
        require(block.timestamp < _auctions[_token][_tokenId].end, "IBZNFT, Auction is ended");
        Offer memory last = _offers[_token][_tokenId][_offersCounter[_token][_tokenId]];
        require(last.offer < _offer, "IBZNFT: Can't make an offer lower than last");
        require(_offer > price, "IBZNFT: Can't offer less than reserve price");
        uint256 allowance = erc20Allowance(_token, msg.sender);
        uint256 balance = erc20Balance(_token, msg.sender);
        require(balance >= _offer, "IBZNFT: Don't have enough ERC20 to make offer");
        require(allowance >= _offer, "IBZNFT: Contract can't move ERC20 tokens");
        address owner = NFT.ownerOf(_tokenId);
        require(owner != msg.sender, "IBZNFT: Can't make an offer to yourself");
        _offersCounter[_token][_tokenId]++;
        _offers[_token][_tokenId][_offersCounter[_token][_tokenId]].timestamp = block.timestamp;
        _offers[_token][_tokenId][_offersCounter[_token][_tokenId]].offer = _offer;
        _offers[_token][_tokenId][_offersCounter[_token][_tokenId]].from = msg.sender;
    }

    /*
        This method will reset an offer
     */
    function resetOffer(uint256 _token, uint256 _tokenId, uint256 _offer) private {
       _offers[_token][_tokenId][_offer].timestamp = 0;
       _offers[_token][_tokenId][_offer].offer = 0;
       _offers[_token][_tokenId][_offer].from = address(0);
    }

    /*
        This method will allow to remove an offer from auction
    */
    function removeOffer(uint256 _token, uint256 _tokenId, uint256 _offer)
        public
    {
        Offer memory offer = _offers[_token][_tokenId][_offer];
        require(offer.from == msg.sender, "IBZNFT: Only owner can change this offer");
        resetOffer(_token, _tokenId, _offer);
    }

    /*
        This method will return last WETH offer
    */
    function returnLastOffer(uint256 _token, uint256 _tokenId)
        public view returns (uint256)
    {
        return _offersCounter[_token][_tokenId];
    }

    /*
        This method will return last WETH offer
    */
    function returnOffer(uint256 _token, uint256 _tokenId, uint256 _offer)
        public view returns (address, uint256, uint256)
    {
        Offer memory offer = _offers[_token][_tokenId][_offer];
        return (offer.from, offer.offer, offer.timestamp);
    }

    /*
        Accept offer
    */
    function acceptOffer(uint256 _token, uint256 _tokenId, uint256 _offer)
        public
    {
        require(isAuctionValid(_token, _tokenId), "IBZNFT: Auction no longer valid");
        address owner = NFT.ownerOf(_tokenId);
        require(owner == msg.sender, "IBZNFT: Only owner can accept");
        Offer memory offer = _offers[_token][_tokenId][_offer];
        require(offer.offer > 0, "IBZNFT: This offer doesn't exists");
        uint256 allowance = erc20Allowance(_token, offer.from);
        require(allowance >= _offer, "IBZNFT: Contract can't move ERC20 tokens");
        // Transfer token
        erc20TransferFrom(_token, offer.from, address(this), offer.offer);
        // Transfer nft
        NFT.transferFrom(owner, offer.from, _tokenId);
        // Setting earnings for marketplace and owner
        uint256 percentage = returnMarketplacePercentage(owner);
        uint256 fee = offer.offer.div(percentage);
        _vault[_token][address(this)] = _vault[_token][address(this)] + fee;
        uint256 earn = offer.offer.sub(fee);
        _vault[_token][owner] = _vault[_token][owner] + earn;
        // Checking if there's a cashback
        if(_ibzCashback[_tokenId] > 0) {
            _vault[0][offer.from] = _vault[0][offer.from] + _ibzCashback[_tokenId];
            _ibzCashback[_tokenId] = 0;
        }
        // Finally reset auction
        resetAuction(_token, _tokenId);
    }

    /*
        This method return address's vault
     */
    function addressVault(uint256 _token, address _address) public view returns (uint256){
        return _vault[_token][_address];
    }
    
    /*
        Admin methods
     */

    function fixDefaultPercentage(uint256 _percentage) public onlyOwner {
        default_percentage = _percentage;
    }

    function setCashbackForToken(uint256 _tokenId, uint256 _amount) public onlyOwner {
        uint256 allowance = erc20Allowance(0, msg.sender);
        require(allowance >= _amount, "IBZNFT: Contract can't move IBZ tokens");
        erc20TransferFrom(0, msg.sender, address(this), _amount);
        _ibzCashback[_tokenId] = _amount;
    }

    function fixNftAddress(address _nft) public onlyOwner {
        NFT = IERC721(_nft);
    }

    function fixMarketAddress(uint256 _identifier, address _address) public onlyOwner {
        _markets[_identifier] = _address;
    }

    function fixMarketsCounter(uint256 _count) public onlyOwner {
        _marketsCounter = _count;
    }

    function fixPercentage(address _minter, uint256 _percentage) public onlyOwner {
        _marketPercentages[_minter] = _percentage;
    }

    function disablePanicWithdraw() public onlyOwner {
        panic_withdraw_allowed = false;
    }

    function panicWithdraw(uint256 _token, address _from, uint256 _amount) public onlyOwner {
        require(panic_withdraw_allowed, 'IBZNFT: Panic withdraw was disabled');
        uint256 balance = _vault[_token][_from];
        require(balance > 0, 'IBZNFT: Nothing to withdraw!');
        require(_amount <= balance, 'IBZNFT: Amount requested is more than balance');
        erc20Transfer(_token, msg.sender, _amount);
        _vault[_token][_from] = 0;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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