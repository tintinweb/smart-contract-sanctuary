/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.8.0;




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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: peeny/peeny.sol


pragma solidity ^0.8.2;



contract Peeny is ERC20, Ownable {
    uint256 private constant MILLION = 1000000;
    uint256 private constant NUMBER_OF_COINS_MINTED = 100 * MILLION;
    
    // How many Peeny have been claimed through contribute()
    uint256 public peenyReserved = 0;
    // How many Peeny have been given out through issue()
    uint256 public peenyDistributed = 0;
    uint256 private numberOfContributions = 1;

    // Each contribution must be at least minimumContributionWei or it will fail.
    uint256 private minimumContributionWei = 100000000000000;
    
    // How much WEI has been received by the ICO.
    uint256 public contributionsReceived = 0;
    
    bool private icoOpen = true;
    
    // When <i> million Peeny have been sold, exchangeRate[i] contains the price
    // in Wei of one MicroPeeny (10^12) until the next million Peeny is sold,
    // after which exchangeRate[i+1] will be used for the next million Peeny.
    uint256[90] exchangeRates = [300, 360, 432, 518, 622, 746, 895, 1074, 1289, 1547, 1857, 2229, 2674, 3209, 3851, 4622, 5546, 6655, 7986, 9584, 11501, 13801, 16561, 19874, 23849, 28618, 34342, 41211, 49453, 59344, 71212, 85455, 102546, 123055, 147667, 177200, 212640, 255168, 306202, 367442, 440931, 529117, 634941, 761929, 914315, 1097178, 1316614, 1579937, 1895924, 2275109, 2730131, 3276157, 3931389, 4717667, 5661200, 6793440, 8152128, 9782554, 11739065, 14086878, 16904254, 20285105, 24342126, 29210551, 35052661, 42063194, 50475832, 60570999, 72685199, 87222239, 104666687, 125600024, 150720029, 180864035, 217036842, 260444210, 312533052, 375039663, 450047596, 540057115, 648068538, 777682246, 933218695, 1119862434, 1343834921, 1612601905, 1935122287, 2322146744, 2786576093, 3343891312];

    struct Funder {
        uint256 donation;
        uint256 numberOfCoins;
        // Add date
    }
    
    event LogUint256(uint256 val, string message);
    event Issue(Funder funder);
    
    mapping(address => Funder) public contributions;
    
    // List of contributors who have contributed and need to be issued Peeny.
    address[] contributors;
    constructor() ERC20("Peeny", "PP") {
        _mint(msg.sender, NUMBER_OF_COINS_MINTED * 10 ** decimals());
    }
    
    // Suport the Peeny ICO! Thank you for your support of the Dick Chainy foundation.
    // If you've altready contributed, you can't contribute again until your coins have
    // been distributed.
    function contribute() public payable {
        require(icoOpen, "The Peeny ICO has now ended.");
        require(msg.value >= minimumContributionWei, "Minimum contribution must be at least getMinimumContribution(). ");
        Funder storage funder = contributions[address(msg.sender)];
        require(funder.numberOfCoins == 0 && funder.donation == 0, "You have already contributed a donation and will be receiving your Peeny shortly. Please wait until you receive your Peeny before making another contribution. Thanks for supporting the Dick Chainy Foundation!");
        funder.donation = msg.value;
        contributionsReceived += funder.donation;
        funder.numberOfCoins = donationInWeiToPeeny(msg.value);

        contributors.push(msg.sender);
        
        peenyReserved += funder.numberOfCoins;
        numberOfContributions++;
    }
    
    // When donating Wei, the user will receive Peeny according to the exchange rate.
    // The current exchange rate is stored in the public variable weiToMicroPeeny, but
    // every 1 million Peeny that are sold will decrease the amount of MicroPeeny granted
    // for the same amount of Wei.
    // Note that contribute will add the user's contribution to a the contributions mapping,
    // but coins are not guaranteed based on the response of this function. They will be
    // granted in order based on when Funders were added to the contributions mapping, so
    // this function will be an upper bound on the amount of Peeny granted. The amount of
    // Peeny can be less if another contribution is made in the same block which causes the
    // number of coins granted to go beyond the next million Peeny because the exchange rate
    // will change due to the other contribution.
    function _donationInWeiToPeeny(uint256 donation, uint256 inPeenyDistributed) view public returns (uint256) {
        // This can be peenyReserved (from contribute) or peenyDistributed (from issue).
        uint256 tempPeenyDistributed = inPeenyDistributed;

        uint256 estimatedPeeny = 0;
        
        uint256 numLoops = 0;
        while (donation > 0 && tempPeenyDistributed <= NUMBER_OF_COINS_MINTED * 10**decimals() * 9 / 10) {
            // Integer 0-90, how many millions of peeny have been sold
            uint256 currentMillionPeeny = tempPeenyDistributed / MILLION / 10 ** decimals();
            assert(currentMillionPeeny <= 89);
            uint256 nextMillionPeeny = currentMillionPeeny + 1;
            uint256 tempExchangeRate = exchangeRates[currentMillionPeeny];
            
            // peeny = wei * wei / micropeeny * peeny / micropeeny
            uint256 peenyAtCurrentExchangeRate = donation * 10**12  / tempExchangeRate;

            // If we don't go over to the next million)
            if (peenyAtCurrentExchangeRate + tempPeenyDistributed <= nextMillionPeeny * MILLION * 10 ** decimals()) {
                tempPeenyDistributed += peenyAtCurrentExchangeRate;
                estimatedPeeny += peenyAtCurrentExchangeRate;
                donation -= donation;
            } else {
                estimatedPeeny += nextMillionPeeny * MILLION * 10 ** decimals() - tempPeenyDistributed;
                donation -= (nextMillionPeeny * MILLION * 10 ** decimals() - tempPeenyDistributed) * tempExchangeRate / 10**12;
                tempPeenyDistributed = nextMillionPeeny * MILLION * 10 ** decimals();
            }
            
            // tempExchangeRate = (tempExchangeRate * 120 / 100);
            numLoops++;
        }
        return estimatedPeeny;
    }
    
    function donationInWeiToPeeny(uint256 donation) view public returns (uint256) {
        return _donationInWeiToPeeny(donation, peenyReserved);
    }
    
    function issue() onlyOwner public payable {
        address funderAddress = contributors[contributors.length- 1];
        Funder memory funder = contributions[funderAddress];
        
        transfer(funderAddress, funder.numberOfCoins);
        peenyDistributed += funder.numberOfCoins;
        
        emit Issue(funder);
        contributors.pop();
        delete contributions[funderAddress];
    }
    
    function withdrawPartialFunds(uint256 balance) onlyOwner public {
        require(address(this).balance > 0, "withdrawFunds(): Cannot withdraw when balance is zero.");
        payable(owner()).transfer(balance);
    }
    
    function withdrawFunds() onlyOwner public {
        require(address(this).balance > 0, "withdrawFunds(): Cannot withdraw when balance is zero.");

        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
    
    // Just in case someone tries to be mean.
    function setMinContributionWei(uint256 minContribution) onlyOwner public {
        minimumContributionWei = minContribution;
    }
    
    function closeIco() onlyOwner public {
        icoOpen = false;
    }
    
    function reopenIco() onlyOwner public {
        icoOpen = true;
    }
    
    // The minimum amount of value allowed in a contribute() call.
    function getMinimumContribution() public view returns (uint256) {
        return minimumContributionWei;
    }
}