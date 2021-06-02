/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

/*
 * Qravity Key Shop contract
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Qravity QCO GmbH <qravity.com>
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.5;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/MultiOracleRequestI.sol

/*
Interface for requests to the multi-rate oracle (for EUR/ETH and ERC20)
Copy this to projects that need to access the oracle.
See rate-oracle project for implementation.
*/

interface MultiOracleRequestI {

    function EUR_WEI() external view returns(uint256); // number of wei per EUR

    function lastUpdate() external view returns(uint256); // timestamp of when the last update occurred

    function ETH_EUR() external view returns(uint256); // number of EUR per ETH (rounded down!)

    function ETH_EURCENT() external view returns(uint256); // number of EUR cent per ETH (rounded down!)

    function tokenSupported(address tokenAddress) external view returns(bool); // returns true for ERC20 tokens that are supported by this oracle

    function eurRate(address tokenAddress) external view returns(uint256); // number of token units per EUR

    event RateUpdated(address indexed tokenAddress, uint256 indexed rate); // rate update - using address(0) as tokenAddress for ETH updates

}

// File: contracts/QravityKeyShop.sol

/*
 * Qravity Key Shop
 */

contract QravityKeyShop {
    using SafeMath for uint256;

    address public payTokenControl;
    address public keyControl;
    address public tokenAssignmentControl;

    mapping(address => bool) public enabledPayTokens;
    uint256 public saleCancelDelay;
    bool internal _isOpen = true;

    MultiOracleRequestI internal oracle;

    uint256 public totalKeys;
    uint256 public keysSold; // Only needed for statistics and monitoring
    uint256 public encryptedKeysPublished; // Only needed for statistics and monitoring
    mapping(uint256 => bytes32) public keyHashes;
    mapping(uint256 => uint256) public priceEurCent;
    mapping(uint256 => address) public owners;
    mapping(uint256 => uint) public saleTimestamp;
    mapping(uint256 => uint256) public salePriceToken;
    mapping(uint256 => address) public salePayTokenAddress;
    mapping(uint256 => string) public encryptedKeys;

    event ShopOpened();
    event ShopClosed();
    event PayTokenEnabled(address indexed payTokenAddress);
    event PayTokenDisabled(address indexed payTokenAddress);
    event PriceChanged(uint256 indexed index, uint256 previousPriceEurCent, uint256 newPriceEurCent);
    event SaleCancelDelayChanged(uint256 previousSaleCancelDelay, uint256 newSaleCancelDelay);
    event OracleChanged(address indexed previousOracle, address indexed newOracle);
    event PayTokenControlTransferred(address indexed previousPayTokenControl, address indexed newPayTokenControl);
    event KeyControlTransferred(address indexed previousKeyControl, address indexed newKeyControl);
    event TokenAssignmentControlTransferred(address indexed previousTokenAssignmentControl, address indexed newTokenAssignmentControl);

    event KeyHashStored(uint256 indexed index, bytes32 indexed keyHash, uint256 priceEurCent);
    event KeySold(uint256 indexed index, address indexed owner, address payTokenAddress, uint256 priceToken, uint256 priceEurCent);
    event SaleCancelled(uint256 indexed index, address indexed operator);
    event EncryptedKeyStored(uint256 indexed index, string encryptedKey);

    constructor(uint256 _saleCancelDelay, MultiOracleRequestI _oracle, address _payTokenControl, address _keyControl, address _tokenAssignmentControl)
    {
        saleCancelDelay = _saleCancelDelay;
        oracle = _oracle;
        require(address(oracle) != address(0x0), "You need to provide an actual Oracle contract.");
        payTokenControl = _payTokenControl;
        require(payTokenControl != address(0), "payTokenControl cannot be the zero address.");
        keyControl = _keyControl;
        require(keyControl != address(0), "keyControl cannot be the zero address.");
        tokenAssignmentControl = _tokenAssignmentControl;
        require(tokenAssignmentControl != address(0), "tokenAssignmentControl cannot be the zero address.");
    }

    modifier onlyPayTokenControl() {
        require(msg.sender == payTokenControl, "payTokenControl key required for this function.");
        _;
    }

    modifier onlyKeyControl() {
        require(msg.sender == keyControl, "keyControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier requireExistingKey(uint256 keyIndex) {
        require(keyIndex < totalKeys, "Key doesn't exist.");
        _;
    }

    modifier requireOpen() {
        require(isOpen() == true, "This call only works when the shop is open.");
        _;
    }

    /*** Enable adjusting variables after deployment ***/

    function setSaleCancelDelay(uint256 _newSaleCancelDelay)
    public
    onlyPayTokenControl
    {
        emit SaleCancelDelayChanged(saleCancelDelay, _newSaleCancelDelay);
        saleCancelDelay = _newSaleCancelDelay;
    }

    function setOracle(MultiOracleRequestI _newOracle)
    public
    onlyPayTokenControl
    {
        require(address(_newOracle) != address(0x0), "You need to provide an actual Oracle contract.");
        emit OracleChanged(address(oracle), address(_newOracle));
        oracle = _newOracle;
    }

    function transferPayTokenControl(address _newPayTokenControl)
    public
    onlyPayTokenControl
    {
        require(_newPayTokenControl != address(0), "payTokenControl cannot be the zero address.");
        emit PayTokenControlTransferred(payTokenControl, _newPayTokenControl);
        payTokenControl = _newPayTokenControl;
    }

    function transferKeyControl(address _newKeyControl)
    public
    onlyKeyControl
    {
        require(_newKeyControl != address(0), "keyControl cannot be the zero address.");
        emit KeyControlTransferred(keyControl, _newKeyControl);
        keyControl = _newKeyControl;
    }

    function transferTokenAssignmentControl(address _newTokenAssignmentControl)
    public
    onlyTokenAssignmentControl
    {
        require(_newTokenAssignmentControl != address(0), "tokenAssignmentControl cannot be the zero address.");
        emit TokenAssignmentControlTransferred(tokenAssignmentControl, _newTokenAssignmentControl);
        tokenAssignmentControl = _newTokenAssignmentControl;
    }

    function openShop()
    public
    onlyKeyControl
    {
        _isOpen = true;
        emit ShopOpened();
    }

    function closeShop()
    public
    onlyKeyControl
    {
        _isOpen = false;
        emit ShopClosed();
    }

    // Return true if shop is currently open for purchases.
    // This can have additional conditions to just the variable, e.g. actually having items to sell.
    function isOpen()
    public view
    returns (bool)
    {
        return _isOpen;
    }

    /*** Manage payment tokens ***/

    function enablePaymentToken(address _tokenAddress)
    public
    onlyPayTokenControl
    {
        require(_tokenAddress != address(0), "token address cannot be the zero address.");
        require(enabledPayTokens[_tokenAddress] == false, "payment token is already enabled.");
        require(oracle.tokenSupported(_tokenAddress), "Oracle has to support this token.");
        // Instantiate the token and try to read an allowance.
        // As ERC20 doesn't include an ERC165 requirement, this serves as a poor man's replacement.
        // In fact, this will fail and revert on (most) contracts that are not actual ERC20 tokens.
        // Also, we are calling this in our payment process so better fail here than later.
        IERC20 payToken = IERC20(_tokenAddress);
        /*uint256 testAllowance =*/ payToken.allowance(msg.sender, address(this));
        enabledPayTokens[_tokenAddress] = true;
        emit PayTokenEnabled(_tokenAddress);
    }

    function disablePaymentToken(address _tokenAddress)
    public
    onlyPayTokenControl
    {
        require(enabledPayTokens[_tokenAddress] == true, "payment token needs to be enabled.");
        enabledPayTokens[_tokenAddress] = false;
        emit PayTokenDisabled(_tokenAddress);
    }

    /*** Actual shop for keys  ***/

    function addKeyHashes(bytes32[] memory _newHashes, uint256 _priceEurCent)
    public
    onlyKeyControl
    {
        require(_priceEurCent > 0, "A non-zero price needs to be set.");
        uint256 hashCount = _newHashes.length;
        for (uint8 i = 0; i < hashCount; i++) {
            keyHashes[totalKeys] = _newHashes[i];
            priceEurCent[totalKeys] = _priceEurCent;
            emit KeyHashStored(totalKeys, _newHashes[i], _priceEurCent);
            totalKeys = totalKeys.add(1);
        }
    }

    function setPrice(uint256 keyIndex, uint256 _newPriceEurCent)
    public
    onlyKeyControl
    requireExistingKey(keyIndex)
    {
        require(_newPriceEurCent > 0, "You need to provide a non-zero price.");
        require(owners[keyIndex] == address(0), "Key is already sold.");
        emit PriceChanged(keyIndex, priceEurCent[keyIndex], _newPriceEurCent);
        priceEurCent[keyIndex] = _newPriceEurCent;
    }

    // Calculate current key price in token units.
    // Note: Price in EUR cent is available from priceEurCent[keyIndex].
    function priceToken(uint256 keyIndex, address _payTokenAddress)
    public view
    requireExistingKey(keyIndex)
    returns (uint256)
    {
        require(enabledPayTokens[_payTokenAddress] == true, "payment token needs to be enabled.");
        return priceEurCent[keyIndex].mul(oracle.eurRate(_payTokenAddress)).div(100);
    }

    function buyKey(uint256 keyIndex, address _payTokenAddress)
    public
    requireOpen
    requireExistingKey(keyIndex)
    {
        require(owners[keyIndex] == address(0), "Key is already owned.");
        uint256 keyPriceToken = priceToken(keyIndex, _payTokenAddress);
        IERC20 payToken = IERC20(_payTokenAddress);
        uint256 testAllowance = payToken.allowance(msg.sender, address(this));
        require(testAllowance >= keyPriceToken, "Need enough allowance to buy this key.");
        // Actually transfer the needed amount of tokens.
        payToken.transferFrom(msg.sender, address(this), keyPriceToken);
        // Make all the settings for the key sale.
        owners[keyIndex] = msg.sender;
        saleTimestamp[keyIndex] = block.timestamp;
        salePriceToken[keyIndex] = keyPriceToken;
        salePayTokenAddress[keyIndex] = _payTokenAddress;
        emit KeySold(keyIndex, owners[keyIndex], _payTokenAddress, keyPriceToken, priceEurCent[keyIndex]);
        keysSold = keysSold.add(1);
    }

    function cancelSale(uint256 keyIndex)
    public
    requireExistingKey(keyIndex)
    {
        require(bytes(encryptedKeys[keyIndex]).length == 0, "Key has already been published.");
        require(msg.sender == keyControl || msg.sender == owners[keyIndex], "keyControl key or key owner required for this function.");
        require(msg.sender == keyControl || saleTimestamp[keyIndex] + saleCancelDelay < block.timestamp, "You cannot cancel the sale yet.");
        // Pay back salePriceToken[keyIndex] to owners[keyIndex].
        IERC20 payToken = IERC20(salePayTokenAddress[keyIndex]);
        payToken.transfer(owners[keyIndex], salePriceToken[keyIndex]);
        // Re-set all our variables to the key can be sold again.
        owners[keyIndex] = address(0);
        saleTimestamp[keyIndex] = 0;
        salePriceToken[keyIndex] = 0;
        salePayTokenAddress[keyIndex] = address(0);
        emit SaleCancelled(keyIndex, msg.sender);
        keysSold = keysSold.sub(1);
    }

    function publishEncryptedKey(uint256 keyIndex, string memory _encryptedKey)
    public
    onlyKeyControl
    requireExistingKey(keyIndex)
    {
        require(bytes(encryptedKeys[keyIndex]).length == 0, "Key has already been published.");
        require(owners[keyIndex] != address(0), "Key is not sold.");
        encryptedKeys[keyIndex] = _encryptedKey;
        emit EncryptedKeyStored(keyIndex, _encryptedKey);
        encryptedKeysPublished = encryptedKeysPublished.add(1);
    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(address _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        IERC20 erc20Token = IERC20(_foreignToken);
        erc20Token.transfer(_to, erc20Token.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}