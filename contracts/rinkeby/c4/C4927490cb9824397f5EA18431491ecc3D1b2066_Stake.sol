pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Token} from "./Token.sol";
import {TokenIdLib} from "../lib/TokenId.sol";

address constant ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
enum NFTStatus {Lockable, Locked, Unlockable, Unlocked}

contract Stake is Ownable {
    struct NFTLockDetails {
        uint256 power;
        uint256 lockPeriod;
    }

    // Power map for each series - { collectionId: { seriesId: power }}.
    mapping(IERC721 => mapping(uint256 => mapping(uint256 => NFTLockDetails)))
        public nftStakeDetails;

    // Record the owner of each token ID.
    mapping(IERC721 => mapping(address => uint256[])) public ownerNFTs;
    mapping(IERC721 => mapping(uint256 => address)) public nftOwner;
    mapping(IERC721 => mapping(uint256 => uint256)) public nftLockTimestamp;
    mapping(IERC721 => mapping(uint256 => uint256)) public nftTokensClaimed;

    Token public token;

    constructor(Token token_) Ownable() {
        token = token_;
    }

    // EVENTS //////////////////////////////////////////////////////////////////

    event NFTLocked(IERC721 indexed nft, uint256 indexed tokenId);
    event NFTRedeemed(
        IERC721 indexed nft,
        uint256 indexed tokenId,
        bytes32 formHash
    );
    event NFTUnlocked(IERC721 indexed nft, uint256 indexed tokenId);

    // PERMISSIONED METHODS ////////////////////////////////////////////////////

    function addNFTLockDetails(
        IERC721 nft,
        uint256 collectionId,
        uint256[] memory seriesIds,
        uint256[] memory powers,
        uint256[] memory lockPeriods
    ) public onlyOwner {
        for (uint256 i = 0; i < seriesIds.length; i++) {
            uint256 currentLockPeriod =
                nftStakeDetails[nft][collectionId][seriesIds[i]].lockPeriod;
            require(
                currentLockPeriod == 0 || lockPeriods[i] <= currentLockPeriod,
                "CANNOT_INCREASE_LOCK_PERIOD"
            );
            nftStakeDetails[nft][collectionId][seriesIds[i]] = NFTLockDetails({
                power: powers[i],
                lockPeriod: lockPeriods[i]
            });
        }
    }

    // USER METHODS ////////////////////////////////////////////////////////////

    function stakeNFTs(IERC721 nft, uint256[] memory tokenIds) public {
        // Optimize accessing power storage in loop.
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftStatus(nft, tokenId) == NFTStatus.Lockable);

            nftOwner[nft][tokenIds[i]] = msg.sender;
            nftLockTimestamp[nft][tokenIds[i]] = block.timestamp;

            ownerNFTs[nft][msg.sender].push(tokenId);
            nft.transferFrom(msg.sender, address(this), tokenId);

            emit NFTLocked(nft, tokenId);
        }
    }

    function claimableTokens(IERC721 nft, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 tokensClaimed = nftTokensClaimed[nft][tokenId];
        uint256 lockTimestamp = nftLockTimestamp[nft][tokenId];

        uint256 collectionId = TokenIdLib.extractCollectionId(tokenId);
        uint256 seriesId = TokenIdLib.extractSeriesId(tokenId);
        NFTLockDetails memory lockDetails =
            nftStakeDetails[nft][collectionId][seriesId];
        uint256 nftPower = lockDetails.power;
        uint256 lockPeriod = lockDetails.lockPeriod;

        uint256 lockProgress = block.timestamp - lockTimestamp;
        if (lockProgress > lockPeriod) {
            lockProgress = lockPeriod;
        }

        uint256 claimableProgress = (nftPower * lockProgress) / lockPeriod;

        if (tokensClaimed >= claimableProgress) {
            return 0;
        }

        uint256 claimable = claimableProgress - tokensClaimed;

        // Sanity check.
        require(
            claimable + tokensClaimed <= nftPower,
            "Stake: invalid claimable amount"
        );

        return claimable;
    }

    function claimTokens(IERC721 nft, uint256[] memory tokenIds) public {
        uint256 powerOwed = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 claimable = claimableTokens(nft, tokenId);

            if (claimable > 0) {
                powerOwed += claimable;
                nftTokensClaimed[nft][tokenId] += claimable;
            }
        }

        if (powerOwed > 0) {
            token.transfer(msg.sender, powerOwed);
        }
    }

    // The following is exposed as a backup. `claimAndUnstakeNFTs` should be
    // used instead.
    function _unstakeNFTs(IERC721 nft, uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftOwner[nft][tokenId] == msg.sender, "NOT_NFT_OWNER");
            require(
                nftStatus(nft, tokenId) == NFTStatus.Unlockable,
                "NOT_UNLOCKABLE"
            );

            nft.transferFrom(address(this), msg.sender, tokenId);

            emit NFTUnlocked(nft, tokenId);
        }
    }

    // Only callable by the owner of the NFTs.
    function claimAndUnstakeNFTs(IERC721 nft, uint256[] memory tokenIds)
        public
    {
        claimTokens(nft, tokenIds);
        _unstakeNFTs(nft, tokenIds);
    }

    function takePayment(address paymentToken, uint256 amount) internal {
        if (paymentToken == ETHEREUM) {
            require(msg.value >= amount, "INSUFFICIENT_ETH_AMOUNT");
            // Refund change.
            payable(msg.sender).transfer(msg.value - amount);
        } else {
            IERC20(paymentToken).transferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
    }

    function withdraw(address withdrawToken) public onlyOwner {
        if (withdrawToken == ETHEREUM) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(withdrawToken).transfer(
                msg.sender,
                IERC20(withdrawToken).balanceOf(address(this))
            );
        }
    }

    // USER METHODS - MULTIPLE NFT CONTRACTS ///////////////////////////////////

    function stakeMultipleNFTs(
        IERC721[] memory nftArray,
        uint256[][] memory tokenIdsArray
    ) public {
        require(nftArray.length == tokenIdsArray.length, "MISMATCHED_LENGTHS");
        for (uint256 i = 0; i < nftArray.length; i++) {
            stakeNFTs(nftArray[i], tokenIdsArray[i]);
        }
    }

    function claimForMultipleNFTs(
        IERC721[] memory nftArray,
        uint256[][] memory tokenIdsArray
    ) public {
        require(nftArray.length == tokenIdsArray.length, "MISMATCHED_LENGTHS");
        for (uint256 i = 0; i < nftArray.length; i++) {
            claimTokens(nftArray[i], tokenIdsArray[i]);
        }
    }

    function unstakeMultipleNFTs(
        IERC721[] memory nftArray,
        uint256[][] memory tokenIdsArray
    ) public {
        require(nftArray.length == tokenIdsArray.length, "MISMATCHED_LENGTHS");
        for (uint256 i = 0; i < nftArray.length; i++) {
            claimAndUnstakeNFTs(nftArray[i], tokenIdsArray[i]);
        }
    }

    // VIEW ////////////////////////////////////////////////////////////////////

    function getNFTStakeDetails(
        IERC721 nft,
        uint256 collectionId,
        uint256 seriesId
    ) public view returns (NFTLockDetails memory) {
        return nftStakeDetails[nft][collectionId][seriesId];
    }

    function nftStatus(IERC721 nft, uint256 tokenId)
        public
        view
        returns (NFTStatus)
    {
        // If there's no owner associated, it's never been locked.
        if (nftOwner[nft][tokenId] == address(0x0)) {
            return NFTStatus.Lockable;
        }

        // If this contract no longer holds the token, it has been unlocked.
        if (nft.ownerOf(tokenId) != address(this)) {
            return NFTStatus.Unlocked;
        }

        uint256 collectionId = TokenIdLib.extractCollectionId(tokenId);
        uint256 seriesId = TokenIdLib.extractSeriesId(tokenId);

        uint256 tokenLockTimestamp = nftLockTimestamp[nft][tokenId];
        uint256 tokenLockPeriod =
            nftStakeDetails[nft][collectionId][seriesId].lockPeriod;

        if (block.timestamp >= tokenLockTimestamp + tokenLockPeriod) {
            return NFTStatus.Unlockable;
        }

        return NFTStatus.Locked;
    }

    function getOwnerNFTs(IERC721 nft, address owner)
        public
        view
        returns (uint256[] memory)
    {
        return ownerNFTs[nft][owner];
    }

    // INTERNAL ////////////////////////////////////////////////////////////////
}

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is Ownable, ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) Ownable() ERC20(name, symbol) {
        _mint(msg.sender, totalSupply);
    }
}

pragma solidity ^0.8.0;

uint256 constant TOKEN_ID_LIMIT = 100000000;

library TokenIdLib {
    uint256 internal constant tokenIdLimit = TOKEN_ID_LIMIT;
    uint256 internal constant collectionIdMultiplier =
        tokenIdLimit * tokenIdLimit;
    uint256 internal constant seriesIdMultiplier = tokenIdLimit;

    // Combine the collection ID, series ID and the token's position into a
    // single token ID. For example, if the series ID is `0` and the token
    // position is `23`, generate `100000023`.
    function encodeTokenId(
        uint256 collectionId,
        uint256 seriesId,
        uint256 tokenPosition
    ) internal pure returns (uint256) {
        return
            (collectionId + 1) *
            collectionIdMultiplier +
            (seriesId + 1) *
            seriesIdMultiplier +
            tokenPosition +
            1;
    }

    function extractEdition(uint256 tokenId) internal pure returns (uint256) {
        return ((tokenId % seriesIdMultiplier)) - 1;
    }

    // Extract the series ID from the tokenId. For example, `100000010` returns
    // `0`.
    function extractSeriesId(uint256 tokenId) internal pure returns (uint256) {
        return ((tokenId % collectionIdMultiplier) / seriesIdMultiplier) - 1;
    }

    // Extract the series ID from the tokenId. For example, `100000010` returns
    // `0`.
    function extractCollectionId(uint256 tokenId)
        internal
        pure
        returns (uint256)
    {
        uint256 id = tokenId / collectionIdMultiplier;
        return id == 0 ? 0 : id - 1;
    }
}

contract TokenId {
    uint256 internal constant tokenIdLimit = TOKEN_ID_LIMIT;
    uint256 public constant collectionIdMultiplier =
        tokenIdLimit * tokenIdLimit;
    uint256 public constant seriesIdMultiplier = tokenIdLimit;

    // Combine the collection ID, series ID and the token's position into a
    // single token ID. For example, if the series ID is `0` and the token
    // position is `23`, generate `100000023`.
    function encodeTokenId(
        uint256 collectionId,
        uint256 seriesId,
        uint256 tokenPosition
    ) public pure returns (uint256) {
        return TokenIdLib.encodeTokenId(collectionId, seriesId, tokenPosition);
    }

    function extractEdition(uint256 tokenId) public pure returns (uint256) {
        return TokenIdLib.extractEdition(tokenId);
    }

    // Extract the series ID from the tokenId. For example, `100000010` returns
    // `0`.
    function extractSeriesId(uint256 tokenId) public pure returns (uint256) {
        return TokenIdLib.extractSeriesId(tokenId);
    }

    // Extract the series ID from the tokenId. For example, `100000010` returns
    // `0`.
    function extractCollectionId(uint256 tokenId)
        public
        pure
        returns (uint256)
    {
        return TokenIdLib.extractCollectionId(tokenId);
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}