// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libraries/UniERC20.sol";

import "./ClipperPool.sol";
import "./ClipperExchangeInterface.sol";

/*  Deposit contract for locked-up deposits into the vault
    This contract is created by the Pool contract
        
    The interaction is as follows:
    * User transfers tokens to the vault.
    * They register the deposit.
    * They are granted claim to some (unminted) pool tokens, which are reflected in the fullyDilutedSupply of the pool.
    * Once their lockup time passes, they can unlock their deposit, which mints the pool tokens.
*/
contract ClipperDeposit is ReentrancyGuard {
    using UniERC20 for ERC20;
    ClipperPool theExchange;

    constructor() {
        theExchange = ClipperPool(payable(msg.sender));
    }

    struct Deposit {
        uint lockedUntil;
        uint256 poolTokenAmount;
    }

    event Deposited(
        address indexed account,
        uint256 amount
    );

    mapping(address => Deposit) public deposits;

    function hasDeposit(address theAddress) internal view returns (bool) {
        return deposits[theAddress].lockedUntil > 0;
    }

    function canUnlockDeposit(address theAddress) public view returns (bool) {
        Deposit storage myDeposit = deposits[theAddress];
        return hasDeposit(theAddress) && (myDeposit.poolTokenAmount > 0) && (myDeposit.lockedUntil <= block.timestamp);
    }

    function unlockVestedDeposit() public nonReentrant returns (uint256 numTokens) {
        require(canUnlockDeposit(msg.sender), "Deposit cannot be unlocked");
        numTokens = deposits[msg.sender].poolTokenAmount;
        delete deposits[msg.sender];
        theExchange.recordUnlockedDeposit(msg.sender, numTokens);
    }

    /*
        Main deposit contract.

        Uses the deposit / sync / update modality for call simplicity.

        To use:
        Deposit tokens with the pool contract first, then call to record deposit.

        # uint nDays
        + nDays is the minimum contract time that someone is buying into the pool for.
        + After nDays, Clipper will return equitable amount of Clipper pool tokens, along 
          with some yield as reward for buying into the pool.
        + For the special case of nDays = 0, it becomes a simple swap of some ERC20 coins
          for Clipper coins.

        # external
        Publicly accessible and callable to anyone on the blockchain.

        # nonReentrant
        The property means the function cannot recursively call itself.
        It is common best practice to mark nonReentrant every function with side
        effects.
        A simple example is a withdraw function, which should not call withdraw
        again to avoid double spend.

        # uint256 newTokensToMint
        These are the Clipper tokens that is the reward for depositing ERC20 tokens
        into the pool.
    */
    function deposit(uint nDays) external nonReentrant returns(uint256 newTokensToMint) {
        // Check for sanity and depositability
        require((nDays < 2000) && ClipperExchangeInterface(theExchange.exchangeInterfaceContract()).approvalContract().approveDeposit(msg.sender, nDays), "Clipper: Deposit rejected");
        uint256 beforeDepositInvariant = theExchange.exchangeInterfaceContract().invariant();
        uint256 initialFullyDilutedSupply = theExchange.fullyDilutedSupply();

        // 'syncAll' forces the vault to recheck its balances
        // This will cause the invariant to change if a deposit has been made. 
        theExchange.syncAll();

        uint256 afterDepositInvariant = theExchange.exchangeInterfaceContract().invariant();

        // new_inv = (1+\gamma)*old_inv
        // new_tokens = \gamma * old_supply
        // SOLVING:
        // \gamma = new_inv/old_inv - 1
        // new_tokens = (new_inv/old_inv - 1)*old_supply
        // new_tokens = (new_inv*old_supply)/old_inv - old_supply
        newTokensToMint = (afterDepositInvariant*initialFullyDilutedSupply)/beforeDepositInvariant - initialFullyDilutedSupply;

        require(newTokensToMint > 0, "Deposit not large enough");

        theExchange.recordDeposit(newTokensToMint);

        if(nDays == 0 && !hasDeposit(msg.sender)){
            // Immediate unlock
            theExchange.recordUnlockedDeposit(msg.sender, newTokensToMint);
        } else {
            // Add on to existing deposit, if it exists
            Deposit storage curDeposit = deposits[msg.sender];
            uint lockDepositUntil = block.timestamp + (nDays*86400);
            Deposit memory myDeposit = Deposit({
                                            lockedUntil: curDeposit.lockedUntil > lockDepositUntil ? curDeposit.lockedUntil : lockDepositUntil,
                                            poolTokenAmount: newTokensToMint+curDeposit.poolTokenAmount
                                        });
            deposits[msg.sender] = myDeposit;
        }
        emit Deposited(msg.sender, newTokensToMint);        
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

    constructor () {
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Unified library for interacting with native ETH and ERC20
// Design inspiration from Mooniswap
library UniERC20 {
    using SafeERC20 for ERC20;

    function isETH(ERC20 token) internal pure returns (bool) {
        return (address(token) == address(0));
    }

    function uniCheckAllowance(ERC20 token, uint256 amount, address owner, address spender) internal view returns (bool) {
        if(isETH(token)){
            return msg.value==amount;
        } else {
            return token.allowance(owner, spender) >= amount;
        }
    }

    function uniBalanceOf(ERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance-msg.value;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(ERC20 token, address to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                (bool success, ) = payable(to).call{value: amount}("");
                require(success, "Transfer failed.");
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniTransferFromSender(ERC20 token, uint256 amount, address sendTo) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value == amount, "Incorrect value");
                payable(sendTo).transfer(msg.value);
            } else {
                token.safeTransferFrom(msg.sender, sendTo, amount);
            }
        }
    }
}

// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "./libraries/UniERC20.sol";
import "./libraries/Sqrt.sol";
import "./libraries/SafeAggregatorInterface.sol";

import "./ClipperExchangeInterface.sol";
import "./ClipperEscapeContract.sol";
import "./ClipperDeposit.sol";

/*
    ClipperPool is the central "vault" contract of the Clipper exchange.
    
    Its job is to hold and track the pool assets, and is the referenceable ERC20
    pool token address as well.

    It is the "center" of the set of contracts, and its owner has owner-level controls
    of the exchange interface and deposit contracts.

    To perform swaps, we use the "deposit / swap / sync" modality of Uniswapv2 and Matcha.
    The idea is that a swapper inititally places their liquidity into our pool to initiate a swap.
    We will then check current balances against last known good values, then perform the swap.
    Following the swap, we then sync so that last known good values match balances.

    Our numeraire asset in the pool is ETH.
*/

contract ClipperPool is ERC20, ReentrancyGuard, Ownable {
    using Sqrt for uint256;
    using UniERC20 for ERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeAggregatorInterface for AggregatorV3Interface;

    address constant CLIPPER_ETH_SIGIL = address(0);

    // fullyDilutedSupply tracks the *actual* size of our pool, including locked-up deposits
    // fullyDilutedSupply >= ERC20 totalSupply
    uint256 public fullyDilutedSupply;

    // These contracts are created by the constructor
    // depositContract handles token deposit, locking, and transfer to the pool
    address public depositContract;
    // escapeContract is where the escaped tokens go
    address public escapeContract;

    address public triage;
    
    // Passed to the constructor
    ClipperExchangeInterface public exchangeInterfaceContract;

    uint constant FIVE_DAYS_IN_SECONDS = 432000;
    uint256 constant MAXIMUM_MINT_IN_FIVE_DAYS_BASIS_POINTS = 500;
    uint lastMint;

    // Asset represents an ERC20 token in our pool (not ETH)
    struct Asset {
        AggregatorV3Interface oracle; // Chainlink oracle interface
        uint256 marketShare; // Where 100 in market share is equal to ETH in pool weight. Higher numbers = Less of a share.
        uint256 marketShareDecimalsAdjusted;
        uint256 lastBalance; // last recorded balance (for deposit / swap / sync modality)
        uint removalTime; // time at which we can remove this asset (0 by default, meaning can't remove it)
    }

    mapping(ERC20 => Asset) assets;
    
    EnumerableSet.AddressSet private assetSet;

    // corresponds to "lastBalance", but for ETH
    // Note the other fields in Asset are not necessary:
    // marketShare is always 1e18*100 (if not otherwise set)
    // ETH is not removable, and there is no nextAsset
    uint256 lastETHBalance;
    AggregatorV3Interface public ethOracle;
    uint256 private ethMarketShareDecimalsAdjusted;

    uint256 constant DEFAULT_DECIMALS = 18;
    uint256 constant ETH_MARKET_WEIGHT = 100;
    uint256 constant WEI_PER_ETH = 1e18;
    uint256 constant ETH_WEIGHT_DECIMALS_ADJUSTED = 1e20;
    
    event UnlockedDeposit(
        address indexed account,
        uint256 amount
    );

    event TokenRemovalActivated(
        address token,
        uint timestamp
    );

    event TokenModified(
        address token,
        uint256 marketShare,
        address oracle
    );

    event ContractModified(
        address newContract,
        bytes contractType
    );

    modifier triageOrOwnerOnly() {
        require(msg.sender==this.owner() || msg.sender==triage, "Clipper: Only owner or triage");
        _;
    }

    modifier depositContractOnly() {
        require(msg.sender==depositContract, "Clipper: Deposit contract only");
        _;
    }

    modifier exchangeContractOnly() {
        require(msg.sender==address(exchangeInterfaceContract), "Clipper: Exchange contract only");
        _;
    }

    modifier depositOrExchangeContractOnly() {
        require(msg.sender==address(exchangeInterfaceContract) || msg.sender==depositContract, "Clipper: Deposit or Exchange Only");
        _;
    }

    /*
        Constructor must take ETH (to start the pool).
        Exchange Interface must already be created.
    */ 
    constructor(ClipperExchangeInterface initialExchangeInterface) payable ERC20("Clipper Pool Token", "CLPRPL") {
        require(msg.value > 0, "Clipper: Must deposit ETH");
        
        _mint(msg.sender, msg.value*10);
        lastETHBalance = msg.value;
        fullyDilutedSupply = totalSupply();
        
        exchangeInterfaceContract = initialExchangeInterface;

        // Create the deposit and escape contracts
        // Can't do this for the exchangeInterfaceContract because it's too large
        depositContract = address(new ClipperDeposit());
        escapeContract = address(new ClipperEscapeContract());
    }

    // We want to be able to receive ETH, either from deposit or swap
    // Note that we don't update lastETHBalance here (b/c that would invalidate swap)
    receive() external payable {
    }

    /* TOKEN AND ASSET FUNCTIONS */
    function nTokens() public view returns (uint) {
        return assetSet.length();
    }

    function tokenAt(uint i) public view returns (address) {
        return assetSet.at(i);
    } 


    function isToken(ERC20 token) public view returns (bool) {
        return assetSet.contains(address(token));
    }

    function isTradable(ERC20 token) public view returns (bool) {
        return token.isETH() || isToken(token);
    }

    function lastBalance(ERC20 token) public view returns (uint256) {
        return token.isETH() ? lastETHBalance : assets[token].lastBalance;
    }

    // marketShare is an inverse weighting for the market maker's desired portfolio:
    // 100 = ETH weight.
    // 200 = half the weight of ETH
    // 50 = twice the weight of ETH
    function upsertAsset(ERC20 token, AggregatorV3Interface oracle, uint256 rawMarketShare) external onlyOwner {
        require(rawMarketShare > 0, "Clipper: Market share must be positive");
        // Oracle returns a response that is in base oracle.decimals()
        // corresponding to one "unit" of input, in base token.decimals()

        // We want to return an adjustment figure with DEFAULT_DECIMALS

        // When both of these are 18 (DEFAULT_DECIMALS), we let the marketShare go straight through
        // We need to adjust the oracle's response so that it corresponds to 

        uint256 sumDecimals = token.decimals()+oracle.decimals();
        uint256 marketShareDecimalsAdjusted = rawMarketShare*WEI_PER_ETH;
        if(sumDecimals < 2*DEFAULT_DECIMALS){
            // Make it larger
            marketShareDecimalsAdjusted = marketShareDecimalsAdjusted*(10**(2*DEFAULT_DECIMALS-sumDecimals));
        } else if(sumDecimals > 2*DEFAULT_DECIMALS){
            // Make it smaller
            marketShareDecimalsAdjusted = marketShareDecimalsAdjusted/(10**(sumDecimals-2*DEFAULT_DECIMALS));
        }

        assetSet.add(address(token));
        assets[token] = Asset(oracle, rawMarketShare, marketShareDecimalsAdjusted, token.balanceOf(address(this)), 0);
        
        emit TokenModified(address(token), rawMarketShare, address(oracle));  
    }

    function getOracle(ERC20 token) public view returns (AggregatorV3Interface) {
        if(token.isETH()){
            return ethOracle;
        } else{
            return assets[token].oracle;
        }
    }

    function getMarketShare(ERC20 token) public view returns (uint256) {
        if(token.isETH()){
            return ETH_MARKET_WEIGHT;
        } else {
            return assets[token].marketShare;
        }
    }

    /*
        Only tokens that are not traded can be escaped.
        This means Token Removal is a serious issue for security.

        We emit an event prior to removing the token, and mandate a five-day cool off.
        This allows pool holders to potentially withdraw. 
    */
    function activateRemoval(ERC20 token) external onlyOwner {
        require(isToken(token), "Clipper: Asset not present");
        assets[token].removalTime = block.timestamp + FIVE_DAYS_IN_SECONDS;
        emit TokenRemovalActivated(address(token), assets[token].removalTime);
    }

    function clearRemoval(ERC20 token) external triageOrOwnerOnly {
        require(isToken(token), "Clipper: Asset not present");
        delete assets[token].removalTime;
    }

    function removeToken(ERC20 token) external onlyOwner {
        require(isToken(token), "Clipper: Asset not present");
        require(assets[token].removalTime > 0 && (assets[token].removalTime < block.timestamp), "Not ready");
        assetSet.remove(address(token));
        delete assets[token];
    }

    // Can escape ETH only if all the tokens have been removed
    // i.e., just ETH left in the assetSet
    function escape(ERC20 token) external onlyOwner {
        require(!isTradable(token) || (assetSet.length()==0 && address(token)==CLIPPER_ETH_SIGIL), "Can only escape nontradable");
        // No need to _sync here since it's not tradable
        token.uniTransfer(escapeContract, token.uniBalanceOf(address(this)));
    }

    function modifyExchangeInterfaceContract(address newContract) external onlyOwner {
        exchangeInterfaceContract = ClipperExchangeInterface(newContract);
        emit ContractModified(newContract, "exchangeInterfaceContract modified");
    }

    function modifyDepositContract(address newContract) external onlyOwner {
        depositContract = newContract;
        emit ContractModified(newContract, "depositContract modified");
    }

    function modifyTriage(address newTriageAddress) external onlyOwner {
        triage = newTriageAddress;
        emit ContractModified(newTriageAddress, "triage address modified");
    }

    function modifyEthOracle(AggregatorV3Interface newOracle) external onlyOwner {
        if(address(newOracle)==address(0)){
            delete ethOracle;
            ethMarketShareDecimalsAdjusted=ETH_WEIGHT_DECIMALS_ADJUSTED;
        } else {
            uint256 sumDecimals = DEFAULT_DECIMALS+newOracle.decimals();
            ethMarketShareDecimalsAdjusted = ETH_WEIGHT_DECIMALS_ADJUSTED;
            if(sumDecimals < 2*DEFAULT_DECIMALS){
                // Make it larger
                ethMarketShareDecimalsAdjusted = ethMarketShareDecimalsAdjusted*(10**(2*DEFAULT_DECIMALS-sumDecimals));
            } else if(sumDecimals > 2*DEFAULT_DECIMALS){
                // Make it smaller
                ethMarketShareDecimalsAdjusted = ethMarketShareDecimalsAdjusted/(10**(sumDecimals-2*DEFAULT_DECIMALS));
            }
            ethOracle = newOracle;
        }
        emit TokenModified(CLIPPER_ETH_SIGIL, ETH_MARKET_WEIGHT, address(newOracle));
    }

    // We allow minting, but:
    // (1) need to keep track of the fullyDilutedSupply
    // (2) only limited minting is allowed (5% every 5 days)
    function mint(address to, uint256 amount) external onlyOwner {
        require(block.timestamp > lastMint+FIVE_DAYS_IN_SECONDS, "Clipper: Pool token can mint once in 5 days");
        // amount+fullyDilutedSupply <= 1.05*fullyDilutedSupply 
        // amount <= 0.05*fullyDilutedSupply
        require(amount < (MAXIMUM_MINT_IN_FIVE_DAYS_BASIS_POINTS*fullyDilutedSupply)/1e4, "Clipper: Mint amount exceeded");
        _mint(to, amount);
        fullyDilutedSupply = fullyDilutedSupply+amount;
        lastMint = block.timestamp;
    }

    // Optimized function for exchange - avoids two external calls to the below function
    function balancesAndMultipliers(ERC20 inputToken, ERC20 outputToken) external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        require(isTradable(inputToken) && isTradable(outputToken), "Clipper: Untradable asset(s)");
        (uint256 x, uint256 M, uint256 marketWeightX) = findBalanceAndMultiplier(inputToken);
        (uint256 y, uint256 N, uint256 marketWeightY) = findBalanceAndMultiplier(outputToken);

        return (x,y,M,N,marketWeightX,marketWeightY);
    }

    // Returns the last balance and oracle multiplier for ETH or ERC20
    function findBalanceAndMultiplier(ERC20 token) public view returns(uint256 balance, uint256 M, uint256 marketWeight){
        if(token.isETH()){
            balance = lastETHBalance;
            marketWeight = ETH_MARKET_WEIGHT;
            // If ethOracle is unset our numeraire is ETH
            if(address(ethOracle)==address(0)){
                M = WEI_PER_ETH;
            } else {
                uint256 weiPerInput = ethOracle.safeUnsignedLatest();
                M = (ethMarketShareDecimalsAdjusted*weiPerInput)/ETH_WEIGHT_DECIMALS_ADJUSTED;
            }
        } else {
            Asset memory the_asset = assets[token];
            uint256 weiPerInput = the_asset.oracle.safeUnsignedLatest();
            marketWeight = the_asset.marketShare;
            // "marketShareDecimalsAdjusted" is the market share times 10**(18-token.decimals())
            uint256 marketWeightDecimals = the_asset.marketShareDecimalsAdjusted;
            balance = the_asset.lastBalance;
            // divide by the market base weight of 100*1e18 
            M = (marketWeightDecimals*weiPerInput)/ETH_WEIGHT_DECIMALS_ADJUSTED;
        }
    }

    function _sync(ERC20 token) internal {
        if(token.isETH()){
            lastETHBalance = address(this).balance;
        } else {
            assets[token].lastBalance = token.balanceOf(address(this));
        }
    }

    /* DEPOSIT CONTRACT ONLY FUNCTIONS */
    function recordDeposit(uint256 amount) external depositContractOnly {
        fullyDilutedSupply = fullyDilutedSupply+amount;
    }

    function recordUnlockedDeposit(address depositor, uint256 amount) external depositContractOnly {
        // Don't need to modify fullyDilutedSupply, since that was done above
        _mint(depositor, amount);
        emit UnlockedDeposit(depositor, amount);
    }

    /* EXCHANGE CONTRACT OR DEPOSIT CONTRACT ONLY FUNCTIONS */
    function syncAll() external depositOrExchangeContractOnly {
        _sync(ERC20(CLIPPER_ETH_SIGIL));
        uint i;
        while(i < assetSet.length()) {
            _sync(ERC20(assetSet.at(i)));
            i++;
        }
    }

    function sync(ERC20 token) external depositOrExchangeContractOnly {
        _sync(token);
    }

    /* EXCHANGE CONTRACT ONLY FUNCTIONS */
    // transferAsset() and syncAndTransfer() are the two ways tokens leave the pool without escape.
    // Since they transfer tokens, they are both marked as nonReentrant
    function transferAsset(ERC20 token, address recipient, uint256 amount) external nonReentrant exchangeContractOnly {
        token.uniTransfer(recipient, amount);
        // We never want to transfer an asset without sync'ing
        _sync(token);
    }

    function syncAndTransfer(ERC20 inputToken, ERC20 outputToken, address recipient, uint256 amount) external nonReentrant exchangeContractOnly {
        _sync(inputToken);
        outputToken.uniTransfer(recipient, amount);
        _sync(outputToken);
    }

    // This is activated when burning pool tokens for a single asset
    function swapBurn(address burner, uint256 amount) external exchangeContractOnly {
        // Reverts if not enough tokens
        _burn(burner, amount);
        fullyDilutedSupply = fullyDilutedSupply-amount;
    }

    /* Matcha PLP API */
    function getSellQuote(address inputToken, address outputToken, uint256 sellAmount) external view returns (uint256 outputTokenAmount){
        outputTokenAmount=exchangeInterfaceContract.getSellQuote(inputToken, outputToken, sellAmount);
    }
    function sellTokenForToken(address inputToken, address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount) {
        boughtAmount = exchangeInterfaceContract.sellTokenForToken(inputToken, outputToken, recipient, minBuyAmount, auxiliaryData);
    }

    function sellEthForToken(address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external payable returns (uint256 boughtAmount){
        boughtAmount=exchangeInterfaceContract.sellEthForToken(outputToken, recipient, minBuyAmount, auxiliaryData);
    }
    function sellTokenForEth(address inputToken, address payable recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount){
        boughtAmount=exchangeInterfaceContract.sellTokenForEth(inputToken, recipient, minBuyAmount, auxiliaryData);
    }
}

// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "./libraries/UniERC20.sol";
import "./libraries/Sqrt.sol";
import "./libraries/ApprovalInterface.sol";
import "./libraries/SafeAggregatorInterface.sol";


import "./ClipperPool.sol";

/*
    This exchange interface implements the Matcha PLP API

    Also controls swapFee and approvalContract (to minimize gas)

    It must be created before the Pool contract
    because it gets passed to the Pool contract constructor.

    Then setPoolAddress should be called to link this contract and destroy ownership.
*/
contract ClipperExchangeInterface is ReentrancyGuard, Ownable {
    using Sqrt for uint256;
    using UniERC20 for ERC20;
    using SafeAggregatorInterface for AggregatorV3Interface;

    ClipperPool public theExchange;
    ApprovalInterface public approvalContract;

    uint256 public swapFee;
    uint256 constant MAXIMUM_SWAP_FEE = 500;
    uint256 constant ONE_IN_DEFAULT_DECIMALS_DIVIDED_BY_ONE_HUNDRED_SQUARED = 1e14;
    uint256 constant ONE_IN_TEN_DECIMALS = 1e10;
    uint256 constant ONE_HUNDRED_PERCENT_IN_BPS = 1e4;
    uint256 constant ONE_BASIS_POINT_IN_TEN_DECIMALS = 1e6;

    address constant MATCHA_ETH_SIGIL = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant CLIPPER_ETH_SIGIL = address(0);
    address immutable myAddress;

    event Swapped(
        address inAsset,
        address outAsset,
        address recipient,
        uint256 inAmount,
        uint256 outAmount,
        bytes auxiliaryData
    );

    event SwapFeeModified(
        uint256 swapFee
    );

    modifier poolOwnerOnly() {
        require(msg.sender == theExchange.owner(), "Clipper: Only owner");
        _;
    }


    constructor(ApprovalInterface initialApprovalContract, uint256 initialSwapFee) {
        require(initialSwapFee < MAXIMUM_SWAP_FEE, "Clipper: Maximum swap fee exceeded");
        approvalContract = initialApprovalContract;
        swapFee = initialSwapFee;
        myAddress = address(this);
    }

    // This function should be called immediately after the pool is initialzied
    // It can only be called once because of renouncing ownership
    function setPoolAddress(address payable poolAddress) external onlyOwner {
        theExchange = ClipperPool(poolAddress);
        renounceOwnership();
    }

    function modifyApprovalContract(ApprovalInterface newApprovalContract) external poolOwnerOnly {
        approvalContract = newApprovalContract;
    }

    function modifySwapFee(uint256 newSwapFee) external poolOwnerOnly {
        require(newSwapFee < MAXIMUM_SWAP_FEE, "Clipper: Maximum swap fee exceeded");
        swapFee = newSwapFee;
        emit SwapFeeModified(newSwapFee);
    }

    // Used for deposits and withdrawals, but not swaps
    function invariant() public view returns (uint256) {
        (uint256 balance, uint256 M, uint256 marketWeight) = theExchange.findBalanceAndMultiplier(ERC20(CLIPPER_ETH_SIGIL));
        uint256 cumulant = (M*balance).sqrt()/marketWeight;
        uint i;
        uint n = theExchange.nTokens();
        while(i < n){
            ERC20 the_token = ERC20(theExchange.tokenAt(i));
            (balance, M, marketWeight) = theExchange.findBalanceAndMultiplier(the_token);
            cumulant = cumulant + (M*balance).sqrt()/marketWeight;
            i++;
        }
        // Divide to put everything on a 1e18 track...
        return (cumulant*cumulant)/ONE_IN_DEFAULT_DECIMALS_DIVIDED_BY_ONE_HUNDRED_SQUARED;
    }

    // Closed-form invariant swap expression
    // solves: (sqrt(Mx)/X + sqrt(Ny)/Y) == (sqrt(M(x+a)/X) + sqrt(N(y-b))/Y) for b
    function invariantSwap(uint256 x, uint256 y, uint256 M, uint256 N, uint256 a, uint256 marketWeightX, uint256 marketWeightY) internal pure returns(uint256) {
        uint256 Ma = M*a;
        uint256 Mx = M*x;
        uint256 rMax = (Ma+Mx).sqrt();
        // Since rMax >= rMx, we can start with a great guess
        uint256 rMx = Mx.sqrt(rMax+1);
        uint256 rNy = (N*y).sqrt();
        uint256 X2 = marketWeightX*marketWeightX;
        uint256 XY = marketWeightX*marketWeightY;
        uint256 Y2 = marketWeightY*marketWeightY;

        // multiply by X*Y to get: 
        if(rMax*marketWeightY >= (rNy*marketWeightX+rMx*marketWeightY)) {
            return y;
        } else {
            return (2*((XY*rNy*(rMax-rMx)) + Y2*(rMx*rMax-Mx)) - Y2*Ma)/(N*X2);
        }
    }

    // For gas savings, we query the existing balance of the input token exactly once, which is why this function needs to return
    // both output AND input
    function calculateSwapAmount(ERC20 inputToken, ERC20 outputToken, uint256 totalInputToken) public view returns(uint256 outputAmount, uint256 inputAmount) {
        // balancesAndMultipliers checks for tradability
        (uint256 x, uint256 y, uint256 M, uint256 N, uint256 weightX, uint256 weightY) = theExchange.balancesAndMultipliers(inputToken, outputToken);
        inputAmount = totalInputToken-x;
        uint256 b = invariantSwap(x, y, M, N, inputAmount, weightX, weightY);
        // trader gets back b-swapFee*b/10000 (swapFee is in basis points)
        outputAmount = b-((b*swapFee)/10000);
    }

    // Swaps between input and output, where ERC20 can be ERC20 or pure ETH
    // emits a Swapped event
    function unifiedSwap(ERC20 _input, ERC20 _output, address recipient, uint256 totalInputToken, uint256 minBuyAmount, bytes calldata auxiliaryData) internal returns (uint256 boughtAmount) {
        require(address(this)==myAddress && approvalContract.approveSwap(recipient), "Clipper: Recipient not approved");
        uint256 inputTokenAmount;
        (boughtAmount, inputTokenAmount) = calculateSwapAmount(_input, _output, totalInputToken);
        require(boughtAmount >= minBuyAmount, "Clipper: Not enough output");
        
        theExchange.syncAndTransfer(_input, _output, recipient, boughtAmount);
        
        emit Swapped(address(_input), address(_output), recipient, inputTokenAmount, boughtAmount, auxiliaryData);
    }

    /* These next four functions are the Matcha PLP API */
    
    // Returns how much of the 'outputToken' would be returned if 'sellAmount'
    // of 'inputToken' was sold.
    function getSellQuote(address inputToken, address outputToken, uint256 sellAmount) external view returns (uint256 outputTokenAmount){
        ERC20 _input = ERC20(inputToken==MATCHA_ETH_SIGIL ? CLIPPER_ETH_SIGIL : inputToken);
        ERC20 _output = ERC20(outputToken==MATCHA_ETH_SIGIL ? CLIPPER_ETH_SIGIL : outputToken);
        (outputTokenAmount, ) = calculateSwapAmount(_input, _output, sellAmount+theExchange.lastBalance(_input));
    }

    function sellTokenForToken(address inputToken, address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount) {
        ERC20 _input = ERC20(inputToken);
        ERC20 _output = ERC20(outputToken);
        
        uint256 inputTokenAmount = _input.balanceOf(address(theExchange));
        boughtAmount = unifiedSwap(_input, _output, recipient, inputTokenAmount, minBuyAmount, auxiliaryData);
    }

    // Matcha allows for either ETH pre-deposit, or msg.value transfer. We support both.
    function sellEthForToken(address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external payable returns (uint256 boughtAmount){
        ERC20 _input = ERC20(CLIPPER_ETH_SIGIL);
        ERC20 _output = ERC20(outputToken);
        // Will no-op if msg.value == 0
        _input.uniTransferFromSender(msg.value, address(theExchange));
        uint256 inputETHAmount = address(theExchange).balance;
        boughtAmount = unifiedSwap(_input, _output, recipient, inputETHAmount, minBuyAmount, auxiliaryData);
    }

    function sellTokenForEth(address inputToken, address payable recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount){
        ERC20 _input = ERC20(inputToken);
        uint256 inputTokenAmount = _input.balanceOf(address(theExchange));
        boughtAmount = unifiedSwap(_input, ERC20(CLIPPER_ETH_SIGIL), recipient, inputTokenAmount, minBuyAmount, auxiliaryData);
    }


    // Allows a trader to convert their Pool token into a single pool asset
    // This is essentially a swap between the pool token and something else
    // Note that it is the responsibility of the trader to tender an offer that does not decrease the invariant
    function withdrawInto(uint256 amount, ERC20 outputToken, uint256 outputTokenAmount) external nonReentrant {
        require(theExchange.isTradable(outputToken) && outputTokenAmount > 0, "Clipper: Unsupported withdrawal");
        // Have to sync before calculating the invariant
        // Otherwise, we may run into issues if someone erroneously transferred this outputToken to us
        // Immediately before the withdraw call.
        theExchange.sync(outputToken);
        uint256 initialFullyDilutedSupply = theExchange.fullyDilutedSupply();
        uint256 beforeWithdrawalInvariant = invariant();

        // This will fail if the sender doesn't have enough
        theExchange.swapBurn(msg.sender, amount);
        
        // This will fail if we don't have enough
        // Also syncs automatically
        theExchange.transferAsset(outputToken, msg.sender, outputTokenAmount);
        // so the invariant will have changed....
        uint256 afterWithdrawalInvariant = invariant();

        // TOKEN FRACTION BURNED:
        // amount / initialFullyDilutedSupply
        // INVARIANT FRACTION BURNED:
        // (before-after) / before
        // TOKEN_FRACTION_BURNED >= INVARIANT_FRACTION_BURNED + FEE
        // where fee is swapFee basis points of TOKEN_FRACTION_BURNED

        uint256 tokenFractionBurned = (ONE_IN_TEN_DECIMALS*amount)/initialFullyDilutedSupply;
        uint256 invariantFractionBurned = (ONE_IN_TEN_DECIMALS*(beforeWithdrawalInvariant-afterWithdrawalInvariant))/beforeWithdrawalInvariant;
        uint256 feeFraction = (tokenFractionBurned*swapFee*ONE_BASIS_POINT_IN_TEN_DECIMALS)/ONE_IN_TEN_DECIMALS;
        require(tokenFractionBurned >= (invariantFractionBurned+feeFraction), "Too much taken");
        // This is essentially a swap between the pool token into the output token
        emit Swapped(address(theExchange), address(outputToken), msg.sender, amount, outputTokenAmount, "");
    }

    // myFraction is a ten-decimal fraction
    // theFee is in Basis Points
    function _withdraw(uint256 myFraction, uint256 theFee) internal {
        ERC20 the_token;
        uint256 toTransfer;
        uint256 fee;

        uint i;
        uint n = theExchange.nTokens();
        while(i < n) {
            the_token = ERC20(theExchange.tokenAt(i));
            toTransfer = (myFraction*the_token.uniBalanceOf(address(theExchange))) / ONE_IN_TEN_DECIMALS;
            fee = (toTransfer*theFee)/ONE_HUNDRED_PERCENT_IN_BPS;
            // syncs done automatically on transfer
            theExchange.transferAsset(the_token, msg.sender, toTransfer-fee);
            i++;
        }
        the_token = ERC20(CLIPPER_ETH_SIGIL);
        toTransfer = (myFraction*the_token.uniBalanceOf(address(theExchange))) / ONE_IN_TEN_DECIMALS;
        fee = (toTransfer*theFee)/ONE_HUNDRED_PERCENT_IN_BPS;
        // syncs done automatically on transfer
        theExchange.transferAsset(the_token, msg.sender, toTransfer-fee);
    }

    // Can pull out all assets without fees if you are the exclusive of tokens
    function withdrawAll() external nonReentrant {
        // This will fail if the sender doesn't own the entire pool
        theExchange.swapBurn(msg.sender, theExchange.fullyDilutedSupply());
        // ONE_IN_TEN_DECIMALS = 100% of the pool's assets, no fees
        _withdraw(ONE_IN_TEN_DECIMALS, 0);
    }

    // Proportional withdrawal into ALL contracts
    function withdraw(uint256 amount) external nonReentrant {
        // Multiply by 1e10 for decimals, then divide before transfer
        uint256 myFraction = (amount*ONE_IN_TEN_DECIMALS)/theExchange.fullyDilutedSupply();
        require(myFraction > 1, "Clipper: Not enough to withdraw");

        // This will fail if the sender doesn't have enough
        theExchange.swapBurn(msg.sender, amount);
        _withdraw(myFraction, swapFee);
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

import "../IERC20.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

// Optimized sqrt library originally based on code from Uniswap v2
library Sqrt {
    // y is the number to sqrt
    // x MUST BE > int(sqrt(y)). This is NOT CHECKED.
    function sqrt(uint256 y, uint256 x) internal pure returns (uint256) {
        unchecked {
            uint256 z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) >> 1;
            }
            return z;
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256) {
        unchecked {
            uint256 x = y / 6e17;
            if(y <= 37e34){
                x = y/2 +1;
            }
            return sqrt(y,x); 
        }
    }
}

// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library SafeAggregatorInterface {
    using SafeCast for int256;

    uint256 constant ONE_DAY_IN_SECONDS = 86400;

    function safeUnsignedLatest(AggregatorV3Interface oracle) internal view returns (uint256) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = oracle.latestRoundData();
        require((roundId==answeredInRound) && (updatedAt+ONE_DAY_IN_SECONDS > block.timestamp), "Oracle out of date");
        return answer.toUint256();
    }
}

// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "./libraries/UniERC20.sol";

import "./ClipperPool.sol";

// Simple escape contract. Only the owner of Clipper can transmit out.
contract ClipperEscapeContract {
    using UniERC20 for ERC20;

    ClipperPool theExchange;

    constructor() {
        theExchange = ClipperPool(payable(msg.sender));
    }

    // Need to be able to receive escaped ETH
    receive() external payable {
    }

    function transfer(ERC20 token, address to, uint256 amount) external {
        require(msg.sender == theExchange.owner(), "Only Clipper Owner");
        token.uniTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Interface used for checking swaps and deposits
interface ApprovalInterface {
    function approveSwap(address recipient) external view returns (bool);
    function approveDeposit(address depositor, uint nDays) external view returns (bool);
}

