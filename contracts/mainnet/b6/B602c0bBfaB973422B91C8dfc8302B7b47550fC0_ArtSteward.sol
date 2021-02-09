// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./interfaces/IERC721.sol";
import "./utils/SafeMath.sol";

// Fixed v1 update (January 2021 update):

// - Bumped to 0.7.x sol.
// - Changed 'now' to 'block.timestamp'.
// - Added in sections related to Restoration. 
// - > restore() function, 
// - > extracted buy() to enable once-off transfer
// - > extracted foreclosure + transferartwork to enable once-off transfer

// What changed for V2 (June 2020 update):
// - Medium Severity Fixes:
// - Added a check on buy to prevent front-running. Needs to give currentPrice when buying.
// - Removed ability for someone to block buying through revert on ETH send. Funds get sent to a pull location.
// - Added patron check on depositWei. Since anyone can send, it can be front-run, stealing a deposit by buying before deposit clears.
// - Other Minor Changes:
// - Added past foreclosureTime() if it happened in the past.
// - Moved patron modifier checks to AFTER patronage. Thus, not necessary to have steward state anymore.
// - Removed steward state. Only check on price now. If price = zero = foreclosed. 
// - Removed paid mapping. Wasn't used.
// - Moved constructor to a function in case this is used with upgradeable contracts.
// - Changed currentCollected into a view function rather than tracking variable. This fixed a bug where CC would keep growing in between ownerships.
// - Kept the numerator/denominator code (for reference), but removed to save gas costs for 100% patronage rate.

// - Changes for UI:
// - Need to have additional current price when buying.
// - foreclosureTime() will now backdate if past foreclose time.

contract ArtSteward {
    
    /*
    This smart contract collects patronage from current owner through a Harberger tax model and 
    takes stewardship of the artwork if the patron can't pay anymore.

    Harberger Tax (COST): 
    - Artwork is always on sale.
    - You have to have a price set.
    - Tax (Patronage) is paid to maintain ownership.
    - Steward maints control over ERC721.
    */
    using SafeMath for uint256;
    
    uint256 public price; //in wei
    IERC721 public art; // ERC721 NFT.
    
    uint256 public totalCollected; // all patronage ever collected

    /* In the event that a foreclosure happens AFTER it should have been foreclosed already,
    this variable is backdated to when it should've occurred. Thus: timeHeld is accurate to actual deposit. */
    uint256 public timeLastCollected; // timestamp when last collection occurred
    uint256 public deposit; // funds for paying patronage
    address payable public artist; // beneficiary
    uint256 public artistFund; // what artist has earned and can withdraw

    /*
    If for whatever reason the transfer fails when being sold,
    it's added to a pullFunds such that previous owner can withdraw it.
    */
    mapping (address => uint256) public pullFunds; // storage area in case a sale can't send the funds towards previous owner.
    mapping (address => bool) public patrons; // list of whom have owned it
    mapping (address => uint256) public timeHeld; // time held by particular patron

    uint256 public timeAcquired; // when it is newly bought/sold
    
    // percentage patronage rate. eg 5% or 100% 
    // granular to an additionial 10 zeroes.
    uint256 patronageNumerator; 
    uint256 patronageDenominator;

    // mainnet
    address public restorer; 
    uint256 public snapshotV1Price;
    address public snapshotV1Owner;

    bool public restored = false;

    IERC721 public oldV1; // for checking if allowed to transfer

    constructor(address payable _artist, address _artwork, 
        uint256 _snapshotV1Price, 
        address _snapshotV1Owner,
        address _oldV1Address) payable {

        patronageNumerator = 50000000000; // 5%
        patronageDenominator = 1000000000000;
        art = IERC721(_artwork);
        art.setup();
        artist = _artist;

        // Restoration-specific setup.
        oldV1 = IERC721(_oldV1Address);
        restorer = msg.sender; // this must be deployed by the Restoration contract.
        snapshotV1Price = _snapshotV1Price;
        snapshotV1Owner = _snapshotV1Owner;

        //sets up initial parameters for foreclosure
        _initForecloseIfNecessary();
    }

    function restore() public payable {
        require(restored == false, "RESTORE: Artwork already restored");
        require(msg.sender == restorer, "RESTORE: Can only be restored by restoration contract");

        // newPrice, oldPrice, owner
        _buy(snapshotV1Price, 0, snapshotV1Owner);
        restored = true;
    }

    event LogBuy(address indexed owner, uint256 indexed price);
    event LogPriceChange(uint256 indexed newPrice);
    event LogForeclosure(address indexed prevOwner);
    event LogCollection(uint256 indexed collected);
    
    modifier onlyPatron() {
        require(msg.sender == art.ownerOf(42), "Not patron");
        _;
    }

    modifier collectPatronage() {
       _collectPatronage(); 
       _;
    }

    /* public view functions */
    /* used internally in external actions */

    // how much is owed from last collection to block.timestamp.
    function patronageOwed() public view returns (uint256 patronageDue) {
        return price.mul(block.timestamp.sub(timeLastCollected)).mul(patronageNumerator).div(patronageDenominator).div(365 days);
        
        // use in 100% patronage rate
        //return price.mul(block.timestamp.sub(timeLastCollected)).div(365 days);
    }

    /* not used internally in external actions */
    function patronageOwedRange(uint256 _time) public view returns (uint256 patronageDue) {
        return price.mul(_time).mul(patronageNumerator).div(patronageDenominator).div(365 days);

        // used in 100% patronage rate
        // return price.mul(_time).div(365 days);
    }

    function currentCollected() public view returns (uint256 patronageDue) {
        if(timeLastCollected > timeAcquired) {
            return patronageOwedRange(timeLastCollected.sub(timeAcquired));
        } else { return 0; }
    }

    function patronageOwedWithTimestamp() public view returns (uint256 patronageDue, uint256 timestamp) {
        return (patronageOwed(), block.timestamp);
    }

    function foreclosed() public view returns (bool) {
        // returns whether it is in foreclosed state or not
        // depending on whether deposit covers patronage due
        // useful helper function when price should be zero, but contract doesn't reflect it yet.
        uint256 collection = patronageOwed();
        if(collection >= deposit) {
            return true;
        } else {
            return false;
        }
    }

    // same function as above, basically
    function depositAbleToWithdraw() public view returns (uint256) {
        uint256 collection = patronageOwed();
        if(collection >= deposit) {
            return 0;
        } else {
            return deposit.sub(collection);
        }
    }

    /*
    block.timestamp + deposit/patronage per second 
    block.timestamp + depositAbleToWithdraw/(price*nume/denom/365).
    */
    function foreclosureTime() public view returns (uint256) {
        // patronage per second
        uint256 pps = price.mul(patronageNumerator).div(patronageDenominator).div(365 days);
        uint256 daw = depositAbleToWithdraw();
        if(daw > 0) {
            return block.timestamp + depositAbleToWithdraw().div(pps);
        } else if (pps > 0) {
            // it is still active, but in foreclosure state
            // it is block.timestamp or was in the past
            uint256 collection = patronageOwed();
            return timeLastCollected.add((block.timestamp.sub(timeLastCollected)).mul(deposit).div(collection));
        } else {
            // not active and actively foreclosed (price is zero)
            return timeLastCollected; // it has been foreclosed or in foreclosure.
        }
    }

    /* actions */
    // determine patronage to pay
    function _collectPatronage() public {

        if (price != 0) { // price > 0 == active owned state
            uint256 collection = patronageOwed();
            
            if (collection >= deposit) { // foreclosure happened in the past

                // up to when was it actually paid for?
                // TLC + (time_elapsed)*deposit/collection
                timeLastCollected = timeLastCollected.add((block.timestamp.sub(timeLastCollected)).mul(deposit).div(collection));
                collection = deposit; // take what's left.
            } else { 
                timeLastCollected = block.timestamp; 
            } // normal collection

            deposit = deposit.sub(collection);
            totalCollected = totalCollected.add(collection);
            artistFund = artistFund.add(collection);
            emit LogCollection(collection);

            _forecloseIfNecessary();
        }

    }

    function buy(uint256 _newPrice, uint256 _currentPrice) public payable collectPatronage {
        _buy(_newPrice, _currentPrice, msg.sender);
    }

    // extracted out for initial setup
    function _buy(uint256 _newPrice, uint256 _currentPrice, address _newOwner) internal {
        /* 
            this is protection against a front-run attack.
            the person will only buy the artwork if it is what they agreed to.
            thus: someone can't buy it from under them and change the price, eating into their deposit.
        */
        require(price == _currentPrice, "Current Price incorrect");
        require(_newPrice > 0, "Price is zero");
        require(msg.value > price, "Not enough"); // >, coz need to have at least something for deposit

        address currentOwner = art.ownerOf(42);

        uint256 totalToPayBack = price.add(deposit);
        if(totalToPayBack > 0) { // this won't execute if steward owns it. price = 0. deposit = 0.
            // pay previous owner their price + deposit back.
            address payable payableCurrentOwner = address(uint160(currentOwner));
            bool transferSuccess = payableCurrentOwner.send(totalToPayBack);

            // if the send fails, keep the funds separate for the owner
            if(!transferSuccess) { pullFunds[currentOwner] = pullFunds[currentOwner].add(totalToPayBack); }
        }

        // new purchase
        timeLastCollected = block.timestamp;
        
        deposit = msg.value.sub(price);
        transferArtworkTo(currentOwner, _newOwner, _newPrice);
        emit LogBuy(_newOwner, _newPrice);
    }

    /* Only Patron Actions */
    function depositWei() public payable collectPatronage onlyPatron {
        deposit = deposit.add(msg.value);
    }

    function changePrice(uint256 _newPrice) public collectPatronage onlyPatron {
        require(_newPrice > 0, 'Price is zero'); 
        price = _newPrice;
        emit LogPriceChange(price);
    }
    
    function withdrawDeposit(uint256 _wei) public collectPatronage onlyPatron {
        _withdrawDeposit(_wei);
    }

    function exit() public collectPatronage onlyPatron {
        _withdrawDeposit(deposit);
    }

    /* Actions that don't affect state of the artwork */
    /* Artist Actions */
    function withdrawArtistFunds() public {
        require(msg.sender == artist, "Not artist");
        uint256 toSend = artistFund;
        artistFund = 0;
        artist.transfer(toSend);
    }

    /* Withdrawing Stuck Deposits */
    /* To reduce complexity, pull funds are entirely separate from current deposit */
    function withdrawPullFunds() public {
        require(pullFunds[msg.sender] > 0, "No pull funds available.");
        uint256 toSend = pullFunds[msg.sender];
        pullFunds[msg.sender] = 0;
        msg.sender.transfer(toSend);
    }

    /* internal */
    function _withdrawDeposit(uint256 _wei) internal {
        // note: can withdraw whole deposit, which puts it in immediate to be foreclosed state.
        require(deposit >= _wei, 'Withdrawing too much');

        deposit = deposit.sub(_wei);
        msg.sender.transfer(_wei); // msg.sender == patron

        _forecloseIfNecessary();
    }

    function _forecloseIfNecessary() internal {
        if(deposit == 0) {
            // become steward of artwork (aka foreclose)
            address currentOwner = art.ownerOf(42);
            transferArtworkTo(currentOwner, address(this), 0);
            emit LogForeclosure(currentOwner);
        }
    }

    // doesn't require v1 owner check to set up.
    function _initForecloseIfNecessary() internal {
        if(deposit == 0) {
            // become steward of artwork (aka foreclose)
            address currentOwner = art.ownerOf(42);
            _transferArtworkTo(currentOwner, address(this), 0);
            emit LogForeclosure(currentOwner);
        }

    }

    function transferArtworkTo(address _currentOwner, address _newOwner, uint256 _newPrice) internal {
        // a symbolic check to ensure that the old V1 is still blocked and owned by the Restorer
        // (the old V1 is thus a part of the new v1)
        // if this bond is broken, both artworks will seize
        require(oldV1.ownerOf(42) == restorer, "RESTORE: Old V1 is not owned by the Restorer");

        _transferArtworkTo(_currentOwner, _newOwner, _newPrice);
    }

    function _transferArtworkTo(address _currentOwner, address _newOwner, uint256 _newPrice) internal {
        // note: it would also tabulate time held in stewardship by smart contract
        timeHeld[_currentOwner] = timeHeld[_currentOwner].add((timeLastCollected.sub(timeAcquired)));
        
        art.transferFrom(_currentOwner, _newOwner, 42);

        price = _newPrice;
        timeAcquired = block.timestamp;
        patrons[_newOwner] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC165.sol";

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
    // event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    // event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    // function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    // function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    // function getApproved(uint256 tokenId) external view returns (address operator);

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
    // function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    // function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function setup() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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