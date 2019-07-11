/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

pragma solidity ^0.5.10;

/// @title Interface for interacting with the MarbleCards Core contract created by the fine folks at Marble.Cards.
contract CardCore {
    function approve(address _approved, uint256 _tokenId) external payable;
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function getApproved(uint256 _tokenId) external view returns (address);
}






/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * @dev Moves `amount` tokens from the caller&#39;s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller&#39;s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender&#39;s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller&#39;s
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
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
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn&#39;t required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`&#39;s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller&#39;s allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7103141c121e3143">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="47262b223f223e072a2e3f253e332234692e28">[email&#160;protected]</a>>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() public {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}



/// @title Main contract for WrappedMarbleCards. Heavily inspired by the fine work of the WrappedKitties team
///  (https://wrappedkitties.com/) This contract converts MarbleCards between the ERC721 standard and the
///  ERC20 standard by locking marble.cards into the contract and minting 1:1 backed ERC20 tokens, that
///  can then be redeemed for marble cards when desired.
/// @notice When wrapping a marble card you get a generic WMC token. Since the WMC token is generic, it has no
///  no information about what marble card you submitted, so you will most likely not receive the same card
///  back when redeeming the token unless you specify that card&#39;s ID. The token only entitles you to receive
///  *a* marble card in return, not necessarily the *same* marblecard in return. A different user can submit
///  their own WMC tokens to the contract and withdraw the card that you originally deposited. WMC tokens have
///  no information about which card was originally deposited to mint WMC - this is due to the very nature of
///  the ERC20 standard being fungible, and the ERC721 standard being nonfungible.
contract WrappedMarbleCard is ERC20, Ownable, ReentrancyGuard {

    // OpenZeppelin&#39;s SafeMath library is used for all arithmetic operations to avoid overflows/underflows.
    using SafeMath for uint256;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /// @dev This event is fired when a user deposits marblecards into the contract in exchange
    ///  for an equal number of WMC ERC20 tokens.
    /// @param cardId  The card id of the marble card that was deposited into the contract.
    event DepositCardAndMintToken(
        uint256 cardId
    );

    /// @dev This event is fired when a user deposits WMC ERC20 tokens into the contract in exchange
    ///  for an equal number of locked marblecards.
    /// @param cardId  The marblecard id of the card that was withdrawn from the contract.
    event BurnTokenAndWithdrawCard(
        uint256 cardId
    );

    /* ******* */
    /* STORAGE */
    /* ******* */

    /// @dev An Array containing all of the marblecards that are locked in the contract, backing
    ///  WMC ERC20 tokens 1:1
    /// @notice Some of the cards in this array were indeed deposited to the contract, but they
    ///  are no longer held by the contract. This is because withdrawSpecificCard() allows a
    ///  user to withdraw a card "out of order". Since it would be prohibitively expensive to
    ///  shift the entire array once we&#39;ve withdrawn a single element, we instead maintain this
    ///  mapping to determine whether an element is still contained in the contract or not.
    uint256[] private depositedCardsArray;

    /// @dev Mapping to track whether a card is in the contract and it&#39;s place in the index
    mapping (uint256 => DepositedCard) private cardsInIndex;

    /// A data structure for tracking whether a card is in the contract and it&#39;s location in the array.
    struct DepositedCard {
        bool inContract;
        uint256 cardIndex;
    }

    /* ********* */
    /* CONSTANTS */
    /* ********* */

    /// @dev The metadata details about the "Wrapped MarbleCards" WMC ERC20 token.
    uint8 constant public decimals = 18;
    string constant public name = "Wrapped MarbleCards";
    string constant public symbol = "WMC";
    uint256 constant internal cardInWei = uint256(10)**decimals;

    /// @dev The address of official MarbleCards contract that stores the metadata about each card.
    /// @notice The owner is not capable of changing the address of the MarbleCards Core contract
    ///  once the contract has been deployed.
    /// Ropsten Testnet
    // address public cardCoreAddress = 0x5bb5Ce2EAa21375407F05FcA36b0b04F115efE7d;
    /// Mainnet
    address public cardCoreAddress = 0x1d963688FE2209A98dB35C67A041524822Cf04ff;
    CardCore cardCore;

    /* ********* */
    /* FUNCTIONS */
    /* ********* */


    /// @notice Allows a user to lock marblecards in the contract in exchange for an equal number
    ///  of WMC ERC20 tokens.
    /// @param _cardIds  The ids of the marblecards that will be locked into the contract.
    /// @notice The user must first call approve() in the MarbleCards Core contract on each card
    ///  that they wish to deposit before calling depositCardsAndMintTokens(). There is no danger
    ///  of this contract overreaching its approval, since the MarbleCards Core contract&#39;s approve()
    ///  function only approves this contract for a single marble card. Calling approve() allows this
    ///  contract to transfer the specified card in the depositCardsAndMintTokens() function.
    function depositCardsAndMintTokens(uint256[] calldata _cardIds) external nonReentrant {
        require(_cardIds.length > 0, &#39;you must submit an array with at least one element&#39;);
        for(uint i = 0; i < _cardIds.length; i++){
            uint256 cardToDeposit = _cardIds[i];
            require(msg.sender == cardCore.ownerOf(cardToDeposit), &#39;you do not own this card&#39;);
            require(cardCore.getApproved(cardToDeposit) == address(this), &#39;you must approve() this contract to give it permission to withdraw this card before you can deposit a card&#39;);
            cardCore.transferFrom(msg.sender, address(this), cardToDeposit);
            _pushCard(cardToDeposit);
            emit DepositCardAndMintToken(cardToDeposit);
        }
        _mint(msg.sender, (_cardIds.length).mul(cardInWei));
    }


    /// @notice Allows a user to burn WMC ERC20 tokens in exchange for an equal number of locked
    ///  marblecards.
    /// @param _cardIds  The IDs of the cards that the user wishes to withdraw. If the user submits 0
    ///  as the ID for any card, the contract uses the last card in the array for that card.
    /// @param _destinationAddresses  The addresses that the withdrawn cards will be sent to (this allows
    ///  anyone to "airdrop" cards to addresses that they do not own in a single transaction).
    function burnTokensAndWithdrawCards(uint256[] calldata _cardIds, address[] calldata _destinationAddresses) external nonReentrant {
        require(_cardIds.length == _destinationAddresses.length, &#39;you did not provide a destination address for each of the cards you wish to withdraw&#39;);
        require(_cardIds.length > 0, &#39;you must submit an array with at least one element&#39;);

        uint256 numTokensToBurn = _cardIds.length;
        require(balanceOf(msg.sender) >= numTokensToBurn.mul(cardInWei), &#39;you do not own enough tokens to withdraw this many ERC721 cards&#39;);
        _burn(msg.sender, numTokensToBurn.mul(cardInWei));

        for(uint i = 0; i < numTokensToBurn; i++){
            uint256 cardToWithdraw = _cardIds[i];
            if(cardToWithdraw == 0){
                cardToWithdraw = _popCard();
            } else {
                require(isCardInDeck(cardToWithdraw), &#39;this card is not in the deck&#39;);
                require(address(this) == cardCore.ownerOf(cardToWithdraw), &#39;the contract does not own this card&#39;);
                _removeFromDeck(cardToWithdraw);
            }
            cardCore.transferFrom(address(this), _destinationAddresses[i], cardToWithdraw);
            emit BurnTokenAndWithdrawCard(cardToWithdraw);
        }
    }

    /// @notice Adds a locked marblecard to the end of the array
    /// @param _cardId  The id of the marblecard that will be locked into the contract.
    function _pushCard(uint256 _cardId) internal {
        // push() returns the new array length, sub 1 to get the index
        uint256 index = depositedCardsArray.push(_cardId) - 1;
        DepositedCard memory _card = DepositedCard(true, index);
        cardsInIndex[_cardId] = _card;
    }

    /// @notice Removes an unlocked marblecard from the end of the array
    /// @return  The id of the marblecard that will be unlocked from the contract.
    function _popCard() internal returns(uint256) {
        require(depositedCardsArray.length > 0, &#39;there are no cards in the array&#39;);
        uint256 cardId = depositedCardsArray[depositedCardsArray.length - 1];
        _removeFromDeck(cardId);
        return cardId;
    }

    /// @notice The owner is not capable of changing the address of the MarbleCards Core
    ///  contract once the contract has been deployed.
    constructor() public {
        cardCore = CardCore(cardCoreAddress);
    }

    /// @dev We leave the fallback function payable in case the current State Rent proposals require
    ///  us to send funds to this contract to keep it alive on mainnet.
    function() external payable {}

    /// @dev If any eth is accidentally sent to this contract it can be withdrawn by the owner rather than letting
    ///   it get locked up forever. Don&#39;t send ETH to the contract, but if you do, the developer will consider it a tip.
    function extractAccidentalPayableEth() public onlyOwner returns (bool) {
        require(address(this).balance > 0);
        address(uint160(owner())).transfer(address(this).balance);
        return true;
    }

    /// @dev Gets the index of the card in the deck
    function _getCardIndex(uint256 _cardId) internal view returns (uint256) {
        require(isCardInDeck(_cardId));
        return cardsInIndex[_cardId].cardIndex;
    }

    /// @dev Will return true if the cardId is a card that is in the deck.
    function isCardInDeck(uint256 _cardId) public view returns (bool) {
        return cardsInIndex[_cardId].inContract;
    }

    /// @dev Remove a card by switching the place in the array
    function _removeFromDeck(uint256 _cardId) internal {
        // Get the index of the card passed above
        uint256 index = _getCardIndex(_cardId);
        // Get the last element of the existing array
        uint256 cardToMove = depositedCardsArray[depositedCardsArray.length - 1];
        // Move the card at the end of the array to the location
        //   of the card we want to void.
        depositedCardsArray[index] = cardToMove;
        // Move the card we are voiding to the end of the index
        cardsInIndex[cardToMove].cardIndex = index;
        // Trim the last card from the index
        delete cardsInIndex[_cardId];
        depositedCardsArray.length--;
    }

}