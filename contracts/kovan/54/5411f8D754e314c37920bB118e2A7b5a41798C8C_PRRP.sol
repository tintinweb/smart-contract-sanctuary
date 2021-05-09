/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

contract PRRPERC20 is Context, IERC20{
    
    //// ERC20 from OpenZeppelin with small modifications in _transfer() and decimals() function ////
/*
The following functions are basically the OpenZeppelin ERC20 token functions.
They needed to be copied in the contract (instead of used out of an own contract) to make changes to the _transfer 
function possible. Except of the decimals and the _transfer function no changes where made.
*/
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    constructor() {
        _name = "PRRP/USDC_Intrinsic Project";
        _symbol = "PRRP";
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
/*
Like described before: The decimals where changed.
With 6 decimals they fit better to the decimals of USDC. More decimals would not be neccessary.
*/
    function decimals() public pure returns (uint8) {
        return 6;
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
/*
In the transfer function 3 changes where made to enable a hard coded transfer fee.
In contrast to many other functions with transfer fees, theese transfer fees work really deflationary 
as they reduce the amount of total supply but (and this is important) the intrinsic value is staying the same.
If this fee mechanism is combined with a token that has no "safe" intrinsic value it is not working directly deflationary.
It is only possible to work deflationary on the traded price which is highly vulnerable to panic sellers and price 
manipulations through big value holders. Therefore the deflationary effect is not secure.
But as this token has intrinsic value the deflationary effect is secured. Every hodler participates directly from 
the trading volume and with this mechanic the second functionality to increse the buyback price naturally is implemented.

It was thought about some kind of "protection against whales or pump/dump" logic with a maximum transfer amount. But it would be possible 
to bypass a mechanism like that with just multiple orders or multiple wallets. Therefore it would be unefficient.
Some kind of "protection" is achieved through the guaranteed buyback as a whale will never be able to dump under this price level.
Additionally: the closer the exchange price is to the buyback price the more interesting is this token for new investors.
*/
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[sender] = senderBalance - amount * 99 / 100;
        _burn(sender, amount / 100);

        _balances[recipient] += amount * 99 / 100;

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

// ERC20 Interface
/*  
    Interface for interacting with ERC20 token. In this case: USDC.
*/
interface ERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    
    function balanceOf(address) external view returns (uint256);
    
    function approve(address, uint256) external returns (bool);
}

/*
Interface for interacting with the AAVE lending platform.
*/
interface AAVE {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    
    function withdraw(address asset, uint256 amount, address to) external;
    
    function getLendingPool() external view returns (address);
}


// PRRP TOKEN CONTRACT
contract PRRP is Context, IERC20, Ownable, PRRPERC20 {
    
    
//// VARIABLES & EVENTS////
/*
Variables are packed in 32 byte (20 address and 12 uint96).
The token price should fit easily into 2^96 with 6 decimals, which would lead to a price of 79 trillion $ - very unlikly.
OBsub and OBadd could rise to the infinity with owner withdrawels or sold token 
- this is why the Ballance_OwnerBonus function is implemented and therefore theese numbers should also fit into uint96 easily.
*/
    uint96 public EXT_TokenPrice;
    address public EXT_PriceTicker;
    
    address public tokenContract;
    uint96 public OBsub;
    
    address public AtokenContract;
    address public addressProvider;
    uint96 public OBadd;
    
    
//// CONSTRUCTOR ////
/*
This constructor contains the ERC20 classical _name and _symbol because i needed to interweave
all the ERC20 functions, mappings and variables into this contract. It was the only solution where i could make
changes to the _transfer function (see below).
Additionally the token- and lending-contract is setted and not changeable forever.
*/
    constructor() {
        tokenContract = 0x13512979ADE267AB5100878E2e0f485B568328a4; //USDT
        addressProvider = 0x88757f2f99175387aB4C6a4b3067c77A695b0349; // addressProvider for lendingPool
        AtokenContract = 0xFF3c8bc103682FA918c954E84F5056aB4DD5189d; //aUSDT
    }
    
    
//// CORE ////
/*
One of the three core functions is to buy additionally minted tokens from the smart contract itself.
For this transaction the current internal selling price is calculated through the Get_CurrSellPrice 
function (see details on the function itself). Afterwards the buyer receives 99% of the minted tokens.
The gap 1% is not minted but instead reserved for the owner in the current security.
The checks-effects-interaction pattern is adhered to, because a reentry would not lead to any disadvanteges
for the contract or the token holders.
*/
    function BuyPRRP(uint256 _amountUSDC) public {
        // External Value interaction
        address _tokenContract = tokenContract;
        uint256 CurrSellPrice = Get_CurrSellPrice(_tokenContract);

        require(ERC20(_tokenContract).transferFrom(msg.sender,  address(this),  _amountUSDC), "Allowance not high enough.");

        // Internal Value interaction (Critical part)
        _mint(msg.sender, _amountUSDC * (10 ** 6) * 99 / CurrSellPrice / 100);
    }

/*
The selling function is the second core function which complements the whole intrinsic value construct.
Every owner of a token has at anytime the right to sell his tokens back to the smart contract.
The Buyback price is calculated through the Get_CurrBuybackPrice function (details on the function itself) 
and is basically the part of the current security in the contract which is represented by one token.
With selling to the contract the received tokens get burned and reduce the total supply. Through the first two 
core functions there is no maximum supply for this token which is not leading to inflation - 
the buying price will always be close to or higher than current external or internal (buyback price) prices 
and the payed amount of USDC is stored in the security which is guaranteeing the buyback.
Therefore any investments done in this token is backed by an intrinsic value of the token itself which is 
leading to an official, never declining minimum price.

The current security is stored frequently in a lending platform. Therefore a redeeming function is implemented 
which is executed if the current liquid part of the security is not enough to pay the sold tokens. If not 
exactly the missing amount is redeemed.

Additionally a variable (OBadd) is increased by an amount representing the 1% owner fee. This has to be implemented
to calculate always the correct 1% and the counterpart is OBsub which is increased if the owner pays out his 1%.
OBsub is basically the negative amount whereas OBsub is the positiv part for not redeemed funds or transaction fees.
*/
    function SellPRRP(uint256 _amountPRRP) public {
        // Internal Value interaction
        require(balanceOf(msg.sender) >= _amountPRRP, "Amount exceeds ballance!");
        
        address _tokenContract = tokenContract;
        AAVE _lendingPool = AAVE(Get_LendingPool());
        uint256 CurrBuybackPrice = Get_CurrBuybackPrice(_tokenContract);
        uint256 CurrUSDCBalance = ERC20(_tokenContract).balanceOf(address(this));
        uint256 _OwnerBonusLeft = OwnerBonusLeft(_tokenContract);
        
        if(_amountPRRP * CurrBuybackPrice / (10 ** 6) + _OwnerBonusLeft > CurrUSDCBalance) {
            _lendingPool.withdraw(_tokenContract, _amountPRRP * CurrBuybackPrice / (10 ** 6) + _OwnerBonusLeft - CurrUSDCBalance, address(this));
        }
        
        OBadd += uint96(_amountPRRP * CurrBuybackPrice / 99 / (10 ** 6));

        _burn(msg.sender, _amountPRRP);
        
        // External Value interaction (Critical part)
        require(ERC20(_tokenContract).approve(address(this), _amountPRRP * CurrBuybackPrice / (10 ** 6)), "Approval failed.");
        require(ERC20(_tokenContract).transferFrom(address(this), msg.sender, _amountPRRP * CurrBuybackPrice / (10 ** 6)), "Transfer failed.");
    }

/*
The third core function is the frequently called (by the owner) lending function which is storing 99% (security - OwnerBonusLeft) of the 
liquid part of the security in a lending platform to earn interest. The ownerbonus is also providing a puffer for truncating errors through divisions.
The functionality of lending provides a steadily increasing buyback price for all token holders. The intrinsic value of this token is 
therefore not only created by buying and transaction fees but also externally from interest rates on the current lending part of the current security.

The lending can be paused if the function is called with "false" for emergencies. Normally it is called with "true" to store the 
free liquid amount in the lending contract. If the owner does not claim his ownerBonus it could be possible (through interest) 
that the TargetLending is lower than the CurrentLending.
*/
    function Set_CurrentLending(bool enable) public onlyOwner{
        address _tokenContract = tokenContract;
        address _lendingPool = Get_LendingPool();
        uint256 TargetLending = Get_CurrentSecurity(_tokenContract) - OwnerBonusLeft(_tokenContract);
        uint256 CurrentLending = Get_CurrLending();
        
        if(enable == false) {
            AAVE(_lendingPool).withdraw(_tokenContract, CurrentLending, address(this));
        } else if(TargetLending > CurrentLending){
            require(ERC20(_tokenContract).approve(_lendingPool, TargetLending - CurrentLending), "Approval failed.");
            AAVE(_lendingPool).deposit(_tokenContract, TargetLending - CurrentLending, address(this), 0);
        } else if(CurrentLending > TargetLending){
            AAVE(_lendingPool).withdraw(_tokenContract, CurrentLending - TargetLending, address(this));
        }
    }
    
    
//// VIEWS ////
/*
The View_Values function is only to get all important information with one click without providing the contract address.
The contract address (USDC) was coded as a hard input to reduce gas costs by only calling the storage values once 
in every transaction and providing them for the cascaded functions.
*/
    function View_Values() external view returns (uint256 _CurrentSellPrice, uint256 _CurrentBuybackPrice, uint256 _CurrentSecurity, uint256 _CurrentLending, uint256 _OwnerBonusLeft){
        address _tokenContract = tokenContract;
        
        return (Get_CurrSellPrice(_tokenContract), Get_CurrBuybackPrice(_tokenContract), Get_CurrentSecurity(_tokenContract), Get_CurrLending(), OwnerBonusLeft(_tokenContract));
    }

/*
This function is basically combining the rest of the view functions, so i would recommend to start reading Get_Currentlending to 
Get_CurrentSellPrice.
Nevertheless the current selling price is the base for the contract to sell tokens - but not uncontrolled nor to controlled:
The selling price will always be at least 5% higher than the current buyback price to increase the average intrinsic value of all tokens circulating -
although the token is not for "mooning purposes" it is meant to be raising in value steadily (therefore 5% where setted and through the 
average mechanism it is getting harder and harder to dilute the buyback price with a high stored security).
Now to the part with "nor to controlled": If the external token price (means the trading price on exchanges, updated once per day) is higher than the current buyback 
price then the contract will sell for +5% to this price. With this mechanism the price is able to raise detached from the intrinsic value 
of the token itself - but the difference to other tokens for investment purposes the risk (= the fallback to the intrinsic value) is 
always transparent for everybody. Therefore the market should regulate itself with more and more investors that are not buying for this risk and the 
price declines - but at most: back to the current buyback price. Additionally the sold tokens for +5% of the exchange rate have a higher dilution power for the 
buyback price and reward hodlers.
*/
    function Get_CurrSellPrice(address _tokenContract) internal view returns (uint256){
        uint96 _EXT_TokenPrice = EXT_TokenPrice;
        uint256 _CurrBuybackPrice = Get_CurrBuybackPrice(_tokenContract);
        
        if (_EXT_TokenPrice > _CurrBuybackPrice) {
            return _EXT_TokenPrice * 105 / 100;
        } else {
            return _CurrBuybackPrice * 105 / 100;
        }
    }

/*
The current buyback price is the value of the current security divided by 101,01% of the total supply.
The 101,01% and OBsub and OBadd are a low gas cost way of providing the owner exactly 1% of value supplied 
or created to or from the security. External trading prices do not affect the owner Bonus directly.
Also the buyback price is not related to external trading prices. It is at every time the guaranteed buyback 
price for all circulating token.
*/
    function Get_CurrBuybackPrice(address _tokenContract) internal view returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        
        if(totalSupply_ > 0) {
            return  (Get_CurrentSecurity(_tokenContract) + OBsub - OBadd)
                    * (10 ** 6)
                    / (totalSupply_ * 100 / 99);
        } else {
            return 1000000;
        }
    }
    
/*
The current security is basically the heart of this intrinsic project because this (minus ownerBonus) is the intrinsic value 
of all circulating token.
The value is stored safely in the smart contract itself and everyone can watch the intrinsic value rise, 
because the buyback price is mathematically not possible to fall (except of truncation in the 0.00000X USD range).
*/
    function Get_CurrentSecurity(address _tokenContract) internal view returns (uint256) {
        return  ERC20(_tokenContract).balanceOf(address(this))
                    + Get_CurrLending();
    }

/*
Calculates the current USDC amount which is lended to the lending platform.
The stored exchange rate is precise enough, to get the exact lending amount.
*/
    function Get_CurrLending() internal view returns(uint256){
        return (ERC20(AtokenContract).balanceOf(address(this)));
    }
    
/*
The ownerBonusLeft is showing how much of the security the owner is able to redeem.
This does not make changes to the buyback price because of the OBadd and OBsub logic.
It will always be the predefined 1% of security increases (through buys from the contract, 
earned interest or transaction fees).
*/
    function OwnerBonusLeft(address _tokenContract) internal view returns(uint256){
        uint96 _OBsub = OBsub;
        uint96 _OBadd = OBadd;
        return (Get_CurrentSecurity(_tokenContract) + _OBsub - _OBadd) / 100 + _OBadd - _OBsub;
    }
    
    function Get_LendingPool() public view returns(address){
        return (AAVE(addressProvider).getLendingPool());
    }
    
    
//// OWNER & SUPPLIER SETTINGS
/*
This function can be called by the owner to redeem the ownerBonus.
The whole OwnerBonus functionality is implemented as an alternative for the normal "team or investor tokens" 
which are creating risks to possible selling pressure and therefore drawdowns of the token price.
The owner is only participating on the success of this token and does not represent any risk to the community.
*/
    function Get_OwnerBonus(uint256 _amountUSDC) external onlyOwner{
        address _tokenContract = tokenContract;
        
        require(OwnerBonusLeft(_tokenContract) >= _amountUSDC, "Exceeds OwnerBonus.");
        
        OBsub += uint96(_amountUSDC);
        
        ERC20(_tokenContract).approve(address(this), _amountUSDC);
        ERC20(_tokenContract).transferFrom(address(this), msg.sender, _amountUSDC);
    }

/*
This function is only ballancing out the OBadd and OBsub because they could theoretically rise to infinity which 
could lead to errors in some calculations.
*/
    function Ballance_OwnerBonus() external onlyOwner{
        if(OBsub < OBadd){
            OBadd -= OBsub;
        } else if(OBadd < OBsub) {
            OBsub -= OBadd;
        } else {
            OBsub = 0;
            OBadd = 0;
        }
    }
    
/*
Function for the oracle to daily set the price of this token from public exchanges (External price).
*/
    function Set_EXT_TokenPrice(uint96 TokenPrice) external {
        require(msg.sender == EXT_PriceTicker, "Your are not allowed!");
        EXT_TokenPrice = TokenPrice;
    }
    

//// MOSTLY UNUSED ////
/*
These functions should not be needed to use as this contract is not working with ETH.
Nevertheless, if someone is transferring ETH to this account we will see it as a "donation".
*/
    receive() external payable{
    }
    
    function WithDrawOwner(address payable _to) public onlyOwner{
        _to.transfer(address(this).balance);
    }
}