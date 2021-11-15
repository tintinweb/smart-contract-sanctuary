// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interface/IERC20.sol";

import "./library/SafeERC20.sol";
import "./library/ReentrancyGuard.sol";

contract KsharkNFTMarket is IERC721Receiver, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // --- Data ---
  bool private initialized; // Flag of initialize data

  IERC20 public _dandy = IERC20(0x0);

  struct SalesObject {
    uint256 id;
    uint256 tokenId;
    uint256 price;
    uint8 status;
    address payable seller;
    address payable buyer;
    IERC721 nft;
  }

  // Total amount NFT sales
  uint256 public _salesAmount = 0;

  SalesObject[] _salesObjects;

  // List address is seller
  mapping(address => bool) public _seller;

  // List NFT support for sale
  mapping(address => bool) public _supportNft;

  // Start accept user sale nft
  bool public _isStartUserSales;

  // Check calc tips
  bool public _isCalcTipsFee = false;

  uint256 public _tipsFeeRate = 20; // 20$ each 1000$
  uint256 public _baseRate = 1000;
  address payable _tipsFeeWallet;

  event eveSales(
    uint256 indexed id,
    uint256 tokenId,
    address buyer,
    uint256 finalPrice,
    uint256 tipsFee
  );

  event eveNewSales(
    uint256 indexed id,
    uint256 tokenId,
    address seller,
    address nft,
    address buyer,
    uint256 price
  );

  event eveCancelSales(uint256 indexed id, uint256 tokenId);

  event eveNFTReceived(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  );

  address public _governance;

  event GovernanceTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  //
  mapping(uint256 => address) public _saleOnCurrency;
  mapping(address => bool) public _supportCurrency;

  event eveSupportCurrency(address currency, bool support);

  constructor() public {
    _governance = tx.origin;
  }

  // --- Init ---
  function initialize(address payable tipsFeeWallet) public {
    require(!initialized, "initialize: Already initialized!");
    _governance = msg.sender;
    _tipsFeeWallet = tipsFeeWallet;
    initReentrancyStatus();
    initialized = true;
  }

  // Check Governance
  modifier onlyGovernance() {
    require(msg.sender == _governance, "not governance");
    _;
  }

  function setGovernance(address governance) public onlyGovernance {
    require(governance != address(0), "new governance the zero address");
    emit GovernanceTransferred(_governance, governance);
    _governance = governance;
  }

  /**
   * check address
   */
  modifier validAddress(address addr) {
    require(addr != address(0x0));
    _;
  }

  modifier checkindex(uint256 index) {
    require(index <= _salesObjects.length, "overflow");
    _;
  }

  // Check NFT is not selling out
  modifier mustNotSellingOut(uint256 index) {
    require(index <= _salesObjects.length, "overflow");
    SalesObject storage obj = _salesObjects[index];
    require(obj.buyer == address(0x0) && obj.status == 0, "sry, selling out");
    _;
  }

  // Check seles is owner or governance
  modifier onlySalesOwner(uint256 index) {
    require(index <= _salesObjects.length, "overflow");
    SalesObject storage obj = _salesObjects[index];
    require(
      obj.seller == msg.sender || msg.sender == _governance,
      "author & governance"
    );
    _;
  }

  // Governance widthdraw token
  function seize(IERC20 asset)
    external
    onlyGovernance
    returns (uint256 balance)
  {
    balance = asset.balanceOf(address(this));
    asset.safeTransfer(_governance, balance);
  }

  function() external payable {
    revert();
  }

  // Set _isCalcTipsFee
  function setCalcTipsFee(bool _newCalcTipsFee) public onlyGovernance {
    _isCalcTipsFee = _newCalcTipsFee;
  }

  // Set array nft support
  function addSupportNft(address nft) public onlyGovernance validAddress(nft) {
    _supportNft[nft] = true;
  }

  // Remove array nft support
  function removeSupportNft(address nft)
    public
    onlyGovernance
    validAddress(nft)
  {
    _supportNft[nft] = false;
  }

  function addSeller(address seller)
    public
    onlyGovernance
    validAddress(seller)
  {
    _seller[seller] = true;
  }

  function removeSeller(address seller)
    public
    onlyGovernance
    validAddress(seller)
  {
    _seller[seller] = false;
  }

  function addSupportCurrency(address erc20) public onlyGovernance {
    require(_supportCurrency[erc20] == false, "the currency have support");
    _supportCurrency[erc20] = true;
    emit eveSupportCurrency(erc20, true);
  }

  function removeSupportCurrency(address erc20) public onlyGovernance {
    require(_supportCurrency[erc20], "the currency can not remove");
    _supportCurrency[erc20] = false;
    emit eveSupportCurrency(erc20, false);
  }

  // Set open for user sales
  function setIsStartUserSales(bool isStartUserSales) public onlyGovernance {
    _isStartUserSales = isStartUserSales;
  }

  function setTipsFeeWallet(address payable wallet) public onlyGovernance {
    _tipsFeeWallet = wallet;
  }

  function getSales(uint256 index)
    external
    view
    checkindex(index)
    returns (SalesObject memory)
  {
    return _salesObjects[index];
  }

  function setBaseRate(uint256 rate) external onlyGovernance {
    _baseRate = rate;
  }

  function setTipsFeeRate(uint256 rate) external onlyGovernance {
    _tipsFeeRate = rate;
  }

  function cancelSales(uint256 index)
    external
    checkindex(index)
    onlySalesOwner(index)
    mustNotSellingOut(index)
    nonReentrant
  {
    require(_isStartUserSales || _seller[msg.sender] == true, "cannot sales");
    SalesObject storage obj = _salesObjects[index];
    obj.status = 2;
    obj.nft.safeTransferFrom(address(this), obj.seller, obj.tokenId);

    emit eveCancelSales(index, obj.tokenId);
  }

  function startSales(
    uint256 tokenId,
    uint256 price,
    address nft,
    address currency
  ) external nonReentrant validAddress(nft) returns (uint256) {
    // Check tokenId
    require(tokenId != 0, "invalid token");

    // Check price
    require(price != 0, "invalid price");

    // Check User can seles, or sender is seller or nft is support for sale
    require(
      _isStartUserSales ||
        _seller[msg.sender] == true ||
        _supportNft[nft] == true,
      "cannot sales"
    );

    // Check currency is accept to sell with
    require(_supportCurrency[currency] == true, "not support currency");

    // send nft to contract
    IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);

    _salesAmount++;
    SalesObject memory obj;

    obj.id = _salesAmount;
    obj.tokenId = tokenId;
    obj.seller = msg.sender;
    obj.nft = IERC721(nft);
    obj.buyer = address(0x0);
    obj.price = price;
    obj.status = 0;

    _saleOnCurrency[obj.id] = currency;

    if (_salesObjects.length == 0) {
      SalesObject memory zeroObj;
      zeroObj.tokenId = 0;
      zeroObj.seller = address(0x0);
      zeroObj.nft = IERC721(0x0);
      zeroObj.buyer = address(0x0);
      zeroObj.price = 1;
      zeroObj.status = 2;
      _salesObjects.push(zeroObj);
    }

    _salesObjects.push(obj);

    emit eveNewSales(obj.id, tokenId, msg.sender, nft, address(0x0), price);
    return _salesAmount;
  }

  function buy(uint256 index) public nonReentrant mustNotSellingOut(index) {
    SalesObject storage obj = _salesObjects[index];
    require(_isStartUserSales || _seller[msg.sender] == true, "cannot sales");
    address currencyAddr = _saleOnCurrency[obj.id];

    uint256 price = obj.price;
    uint256 tipsFee = 0;
    uint256 purchase = 0;

    if (_isCalcTipsFee) {
      tipsFee = price.mul(_tipsFeeRate).div(_baseRate);
      purchase = price.sub(tipsFee);

      IERC20(currencyAddr).safeTransferFrom(
        msg.sender,
        _tipsFeeWallet,
        tipsFee
      );
    } else {
      purchase = price;
    }

    IERC20(currencyAddr).safeTransferFrom(msg.sender, obj.seller, purchase);

    obj.nft.safeTransferFrom(address(this), msg.sender, obj.tokenId);

    obj.buyer = msg.sender;

    obj.status = 1; // This NFT Sellout

    // fire event
    emit eveSales(index, obj.tokenId, msg.sender, price, tipsFee);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  ) public returns (bytes4) {
    //only receive the _nft staff
    if (address(this) != operator) {
      //invalid from nft
      return 0;
    }

    //success
    emit eveNFTReceived(operator, from, tokenId, data);
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}

pragma solidity ^0.5.5;

import "../interface/IERC20.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

contract ReentrancyGuard {
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

    constructor() internal {
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

    function initReentrancyStatus() internal {
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

    // add mint interface by dego
    function mint(address account, uint amount) external;
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

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.5.0;

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

