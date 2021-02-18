/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

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

pragma solidity ^0.8.0;


interface ILiquidERC20 is IERC20 {
    
    // Price Query Functions
    function getEthToTokenInputPrice(uint256 ethSold) external view returns(uint256 tokensBought);
    function getEthToTokenOutputPrice(uint256 tokensBought) external view returns (uint256 ethSold);
    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256 ethBought);
    function getTokenToEthOutputPrice(uint256 ethBought) external view returns (uint256 tokensSold);

    // Liquidity Pool
    function poolTotalSupply() external view returns (uint256);
    function poolTokenReserves() external view returns (uint256);
    function poolBalanceOf(address account) external view returns (uint256);
    function poolTransfer(address recipient, uint256 amount) external returns (bool);
    function addLiquidity(uint256 minLiquidity, uint256 maxTokens, uint256 deadline)
        external payable returns (uint256 liquidityCreated);
    function removeLiquidity(uint256 amount, uint256 minEth, uint256 minTokens, uint256 deadline)
        external returns (uint256 ethAmount, uint256 tokenAmount);

    // Buy Tokens
    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline)
        external payable returns (uint256 tokensBought);
    function ethToTokenTransferInput(uint256 minTokens, uint256 deadline, address recipient)
        external payable returns (uint256 tokensBought);
    function ethToTokenSwapOutput(uint256 tokensBought, uint256 deadline)
        external payable returns (uint256 ethSold);
    function ethToTokenTransferOutput(uint256 tokensBought, uint256 deadline, address recipient)
        external payable returns (uint256 ethSold);

    // Sell Tokens
    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline)
        external returns (uint256 ethBought);
    function tokenToEthTransferInput(uint256 tokensSold, uint256 minEth, uint256 deadline, address payable recipient)
        external returns (uint256 ethBought);
    function tokenToEthSwapOutput(uint256 ethBought, uint256 maxTokens, uint256 deadline)
        external returns (uint256 tokensSold);
    function tokenToEthTransferOutput(uint256 ethBought, uint256 maxTokens, uint256 deadline, address payable recipient)
        external returns (uint256 tokensSold);

    // Events
    event AddLiquidity(
        address indexed provider,
        uint256 indexed eth_amount,
        uint256 indexed token_amount
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256 indexed eth_amount,
        uint256 indexed token_amount
    );
    event TransferLiquidity(
        address indexed from,
        address indexed to,
        uint256 value
    );
}

interface ILGT is ILiquidERC20 {

    // Minting Tokens
    function mint(uint256 amount) external;
    function mintFor(uint256 amount, address recipient) external;
    function mintToLiquidity(uint256 maxTokens, uint256 minLiquidity, uint256 deadline, address recipient)
        external payable returns (uint256 tokenAmount, uint256 ethAmount, uint256 liquidityCreated);
    function mintToSell(uint256 amount, uint256 minEth, uint256 deadline)
        external returns (uint256 ethBought);
    function mintToSellTo(uint256 amount, uint256 minEth, uint256 deadline, address payable recipient)
        external returns (uint256 ethBought);

    // Freeing Tokens
    function free(uint256 amount) external returns (bool success);
    function freeFrom(uint256 amount, address owner) external returns (bool success);

    // Buying and Freeing Tokens.
    // It is always recommended to check the price for the amount of tokens you intend to buy
    // and then send the exact amount of ether.

    // Will refund excess ether and returns 0 instead of reverting on most errors.
    function buyAndFree(uint256 amount, uint256 deadline, address payable refundTo)
        external payable returns (uint256 ethSold);

    // Spends all ether (no refunds) to buy and free as many tokens as possible.
    function buyMaxAndFree(uint256 deadline)
        external payable returns (uint256 tokensBought);



    // Optimized Functions
    // !!! USE AT YOUR OWN RISK !!!
    // These functions are gas optimized and intended for experienced users.
    // The function names are constructed to have 3 or 4 leading zero bytes
    // in the function selector.
    // Additionally, all checks have been omitted and need to be done before
    // sending the call if desired.
    // There are also no return values to further save gas.
    // !!! USE AT YOUR OWN RISK !!!
    function mintToSell9630191(uint256 amount) external;
    function mintToSellTo25630722(uint256 amount, address payable recipient) external;
    function buyAndFree22457070633(uint256 amount) external payable;

}

pragma solidity ^0.8.0;

/*import "../../utils/Context.sol";*/

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
contract ERC20 is /*Context*/ IERC20 {
    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) public _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
        _transfer(msg.sender, recipient, amount);
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
        _approve(msg.sender, spender, amount);
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

        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);

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
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
        require(_allowances[msg.sender][spender] >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);

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

        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] -= amount;
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

        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] -= amount;
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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

pragma solidity ^0.8.0;

interface IHGT {

    struct UserSetting
    {
        uint256 originAllowance;        // allowance when this account/contract is the tx.origin but NOT the msg.sender
        uint256 senderAllowance;        // allowance when this account/contract is the msg.sender
        uint256 LGTBurnablePrice;       // measured as absolute price - min gas price at which LGT's are burnable
        uint256 LGTRefillPrice;         // measured as absolute price - max gas price at which to buy LGT's
        uint256 maxMint;                // when minting LGT's, the maximum allowable amount to purchase
    }

    struct ContractSetting
    {
        // mapping(address => uint256) perUserAllowances;  // TODO: do we want to use this for now?
        uint256 globalUserAllowance;
        // uint256 allowanceRefillRate;    // how many LGTs allowances gain each day
        uint256 LGTbasisPrice;
        // uint256 LGTprofitabilityThreshold;
        uint256 LGTBurnablePrice;
        uint256 maxBurn;                     // when buying LGT's, the maximum allowable amount to purchase
    }


    function changeUserSettings(
        uint256 _originAllowance,
        uint256 _senderAllowance,
        uint256 _LGTBurnablePrice,
        uint256 _LGTRefillPrice,
        uint256 _maxMint
    )
    external;

    function getUserSettings(address _user) external view returns(UserSetting memory);

    function getContractSettings(address _contract) external view returns(ContractSetting memory);

    function initGasCount() external;

    function changeContractSettings(
        uint256 _globalUserAllowance,
        uint256 _LGTBurnablePrice,
        uint256 _maxBurn
    ) 
    external; 

    function applyGasSavings() external;

    function buy(uint256 minTokens, uint256 deadline) external payable;

    function buyTo(uint256 minTokens, uint256 deadline, address recipient) external payable;

    function mint(uint256 amount) external;

    function mintTo(uint256 amount, address recipient) external;

    function depositLGT(uint256 amount) external;

    function depositLGTto(uint256 amount, address recipient) external;

    function withdrawLGT(uint256 amount) external;

    function withdrawLGTTo(uint256 amount, address recipient) external;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//      HIDDEN GAS TOKEN
//
//      Hidden gas token is currently in development. This is considered an MVP (minimum viable product). As such, there 
//      are many improvements which can be made for further gas efficiency.
//      
//      Hidden gas token is built on top of Liquid Gas Token (https://github.com/matnad/liquid-gas-token).
//      Hidden gas tokens are ERC20 compliant and wrap liquid gas token. Kind of like Wrapped Ether. 
//      1 HGT = 1 LGT, and 1 HGT can be redeemed for 1 LGT at any time.
//      The hidden gas token contract controls the LGTs which underly HGTs so tokens can be burned by 
//      different calling accounts without the need for explicit "approve" calls.
//      In the future, Hidden Gas token may be a standalone token that re-uses LGT code, in order to save gas by avoiding
//      multiple external calls.
//
//      HOW TO USE
//      As a contract which seeks to provide users with gas savings, construct a modifier for all functions you seek to apply
//      gas savings to as follows:
//      
//          modifier usingHGT() 
//          {
//              HGT.initGasCount();
//              _;
//              HGT.applyGasSavings();
//          }
//
//      Also be sure to call "changeContractSettings()" below to set different parameters for using HGT through a contract. 
//      Be sure to call "changeContractSettings()" through the contract itself.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract HGT is ERC20, IHGT {

    uint256 AFTER_MINT_GAS = 50000; //set aside 50k gas for the operations performed after minting
    uint256 LGT_MINT_GAS = 41638; //approximate gas for minting LGTs
                                    //  this approximation comes from LGT benchmarks
                                    //  946314 gas to mint 25 tokens
                                    //  946314 * 1.1 = 1040946      // we add a 10% buffer for our approximation
                                    //  1040946 / 25 = 41638 gas per LGT
    uint256 LGT_BURN_GAS = 32152;   // approximate gas paid which justifies burning LGT's
                                    // for example, if an LGT saves 10k gas, and gas refund is capped at half, this would be 20k, so that for every 
                                    // 20k gas we pay, we burn 1 LGT
                                    // LGT benchmark: burn 1,000,000 gas, then free 25 tokens, gas paid is 598078
                                    // 1,000,000 - 598,078 = 401,992 gas 
                                    // 401,982 / 25 = 16,076 gas per token
                                    // since gas refunds are capped at half, we will assume 1 LGT per (16076 * 2) gas
    uint256 LOGIC_GAS = 50000;      // placeholder for now while we estimate these numbers better
                                    // TODO: consider that a gas refund cannot lower the gas cost below 21000

    address constant LGT_ADDRESS = 0x000000000000C1CB11D5c062901F32D06248CE48;
    
    mapping(address => UserSetting) userSettings;
    mapping(address => ContractSetting) contractSettings;
    mapping(bytes32 => uint256) initialGas;

    constructor() ERC20("Hidden Gas Token", "HGT") public { }

    function changeUserSettings(
        uint256 _originAllowance,
        uint256 _senderAllowance,
        uint256 _LGTBurnablePrice,
        uint256 _LGTRefillPrice,
        uint256 _maxMint
    )
    public override
    {
        userSettings[msg.sender].originAllowance = _originAllowance;
        userSettings[msg.sender].senderAllowance = _senderAllowance;
        userSettings[msg.sender].LGTBurnablePrice = _LGTBurnablePrice;
        userSettings[msg.sender].LGTRefillPrice = _LGTRefillPrice;
        userSettings[msg.sender].maxMint = _maxMint;
    }

    function getUserSettings(address _user) public override view returns(UserSetting memory)
    {
        return userSettings[_user];
    }

    function getContractSettings(address _contract) public override view returns(ContractSetting memory)
    {
        return contractSettings[_contract];
    }

    // @dev This function must be called so that we have a starting amount of gas for the call
    function initGasCount() public override
    {   
        initialGas[keccak256(abi.encode(msg.sender, block.number))] = gasleft();
    }

    function changeContractSettings(
        uint256 _globalUserAllowance,
        uint256 _LGTBurnablePrice,
        uint256 _maxBurn
    ) public override
    {
        contractSettings[msg.sender].globalUserAllowance = _globalUserAllowance;
        contractSettings[msg.sender].LGTBurnablePrice = _LGTBurnablePrice;
        contractSettings[msg.sender].maxBurn = _maxBurn;
    }

    function applyGasSavings() public override
    {
        //lookup tx.origin 
        address origin = tx.origin;

        // call _applyGasSavings
        _applyGasSavings(msg.sender, origin);
    }

    function _applyGasSavings(address _contract, address _user) internal
    {
        // call burn if profitable
        bool didBurn = _burnIfProfitable(_contract, _user);

        // if no burning occurred, call mint if profitable
        if(!didBurn)
        {
            _mintIfProfitable(_user);
        }
    }

    // uses ether to buy LGT, then give it to msg.sender
    function buy(uint256 minTokens, uint256 deadline) public override payable
    {
        // buy LGTs in the LGT contract
        uint256 tokensBought = ILGT(LGT_ADDRESS).ethToTokenSwapInput(minTokens, deadline);

        // increase msg.sender's internal balance
        _balances[msg.sender] += tokensBought;
    }

    // uses ether to buy LGT, then give it to some user
    function buyTo(uint256 minTokens, uint256 deadline, address recipient) public override payable
    {
        // buy LGTs in the LGT contract
        uint256 tokensBought = ILGT(LGT_ADDRESS).ethToTokenSwapInput(minTokens, deadline);

        // increase recipients's internal balance
        _balances[recipient] += tokensBought;
    }

    // uses gas to mint LGT, then give it to msg.sender
    function mint(uint256 amount) public override 
    {
        // mint tokens
        ILGT(LGT_ADDRESS).mint(amount);

        // increase user's balance
        _balances[msg.sender] += amount;
    }

    // uses gas to mint LGT, then give it to some user
    function mintTo(uint256 amount, address recipient) public override
    {
        // mint tokens
        ILGT(LGT_ADDRESS).mint(amount);

        // increase recipient's balance
        _balances[recipient] += amount;
    }

    // allows user to deposit LGT tokens. Requires allowance of this contract    
    function depositLGT(uint256 amount) public override
    {
        // transfer balances into this contract
        ILGT(LGT_ADDRESS).transferFrom(msg.sender, address(this), amount);

        // update user balance
        _balances[msg.sender] += amount;
    }

    // allows users to deposit LGT tokens to another account. Requires alloance of this contract
    function depositLGTto(uint256 amount, address recipient) public override
    {
        // transfer balances into this contract
        ILGT(LGT_ADDRESS).transferFrom(msg.sender, address(this), amount);

        // update user balance
        _balances[recipient] += amount;
    }

    // allows user to withdraw LGT
    function withdrawLGT(uint256 amount) public override
    {
        // decrease user's balance (will revert on overflow (thanks pragma ^0.8.0))
        _balances[msg.sender] -= amount;

        // transfer LGT's out
        ILGT(LGT_ADDRESS).transfer(msg.sender, amount);
    }

    // allows user to withdraw LGT to another address
    function withdrawLGTTo(uint256 amount, address recipient) public override
    {
        // decrease user's balance (will revert on overflow (thanks pragma ^0.8.0))
        _balances[msg.sender] -= amount;

        // transfer LGT's to recipient
        ILGT(LGT_ADDRESS).transfer(recipient, amount);
    }

    /* Internal Functions */
    // @param _LGTToBurn The max number of LGT's to be burned to get the best gas reward
    // @return True if tokens were burned
    function _burnIfProfitable(address _contract, address _user) internal returns(bool didBurn)
    {
        // initialized as false
        bool didBurn;

        // determine estimate of LGTs to burn
        uint256 LGTToBurn = _calculateLGTsToBurn();

        // if contract can burn tokens (has allowance and balance)
        if(contractSettings[_contract].globalUserAllowance > 0 && _balances[_contract] > 0)
        {
            // if it's profitable in the contract's eyes
            if(tx.gasprice > contractSettings[_contract].LGTBurnablePrice)
            {
                // get min of (LGTToBurn, globalUserAllowance, contract balance)
                uint256 contractLGTsBurned = min(LGTToBurn, contractSettings[_contract].globalUserAllowance, _balances[_contract]);

                // burn LGT (up to LGTToBurn), then decrement balances, LGTToBurn, and global allowance
                ILGT(LGT_ADDRESS).free(contractLGTsBurned);
                _balances[_contract] -= contractLGTsBurned;
                LGTToBurn -= contractLGTsBurned;
                contractSettings[_contract].globalUserAllowance -= contractLGTsBurned;

                // set didBurn to true
                didBurn = true;
            }
        }
        // if LGTToBurn > 0, try to burn some "origin" gas tokens
        if(LGTToBurn > 0)   
        {
            // if user can burn tokens (has allowance and balance)
            if(userSettings[_user].originAllowance > 0 && _balances[_user] > 0)
            {
                // if it's profitable
                if(tx.gasprice > userSettings[_user].LGTBurnablePrice)
                {
                    // find min of LGTToBurn, origin allowance, origin balance
                    uint256 originLGTsBurned = min(LGTToBurn, userSettings[_user].originAllowance, _balances[_user]);

                    // burn them, then decrement balances, LGTToBurn and allowance
                    ILGT(LGT_ADDRESS).free(originLGTsBurned);
                    _balances[_user] -= originLGTsBurned;
                    LGTToBurn -= originLGTsBurned;
                    userSettings[_user].originAllowance -= originLGTsBurned;

                    // set didBurn to true
                    didBurn = true;                    
                }
            }
        }
        // return didBurn
        return didBurn;
    }

    // @dev Returns the maximum number of LGTs that this call should burn to get the biggest usable gas reward
    function _calculateLGTsToBurn() internal returns(uint256 numLGTsToBurn)
    {
        // determine gas used
        // gasUsed = gasStart - gasLeft
        uint256 gasUsed = initialGas[keccak256(abi.encode(msg.sender, block.number))] - gasleft();  //this subtraction will not overflow because solidity 0.8

        // add in constant gas for all operations including this one and after
        gasUsed += LOGIC_GAS;
            // LOGIC_GAS =
            //          HGT initial call overhead +
            //          estimate for gas needed to burn tokens (we only care about the case where we are burning tokens, otherwise this is irrelevant and this function should not even be accessed)      

        // use LGT formula to find LGT's to burn
        // LGTs = gasUsed / B
        uint256 LGTsToBurn = gasUsed / LGT_BURN_GAS;        

        // reset initialGas to zero, giving a gas refund
        initialGas[keccak256(abi.encode(msg.sender, block.number))] = 0; 
    }

    // @dev this should be called after _burnIfProfitable, and ONLY if _burnIfProfitable returns false
    //      we should never allow both burning and minting in the same TX
    function _mintIfProfitable(address _user) internal
    {
        // if user has maxMint > 0 AND gasprice is low enough
        if(userSettings[_user].maxMint > 0 && userSettings[_user].LGTRefillPrice >= tx.gasprice)
        {
            // using gasLeft, determine max num of LGTs which can be minted
            uint256 maxLGTsWithGas = (gasleft() - AFTER_MINT_GAS) / LGT_MINT_GAS;

            // determine min(maxLGTsWithGas, maxMint), set LGTsBeingMinted to this
            uint256 LGTsBeingMinted;
            
            if(maxLGTsWithGas < userSettings[_user].maxMint)
            {
                LGTsBeingMinted = maxLGTsWithGas;
            }
            else
            {
                LGTsBeingMinted = userSettings[_user].maxMint;
            }
            
            // get gas pre-mint
            uint256 gasPreMint = gasleft();

            // mint 
            ILGT(LGT_ADDRESS).mint(LGTsBeingMinted);

            // update user balance
            _balances[_user] += LGTsBeingMinted;
        }           
    }


    function min(uint256 a, uint256 b, uint256 c) internal returns (uint256 minimum)
    {
        if(a < b)
        {   // min can't be b
            if(a < c)
            {   // min must be a
                return a;
            }
            else return c;
        }
        else
        {   // min can't be a (if b == a, min can be b)
            if(b < c)
            {
                return b;
            }
            else return c;
        }
    }

}