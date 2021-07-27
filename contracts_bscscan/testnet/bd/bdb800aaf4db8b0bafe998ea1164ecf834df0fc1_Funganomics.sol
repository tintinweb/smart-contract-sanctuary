/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// File: node_modules\openzeppelin-solidity\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

// File: openzeppelin-solidity\contracts\access\Ownable.sol





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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\IERC20.sol





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

// File: openzeppelin-solidity\contracts\token\ERC20\ERC20.sol







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
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 internal _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


contract Funganomics is ERC20("Funganomics", "FUNG", 18), Ownable {
    
/*
*------------------------------------------------------------
* Initializing the unlocked wallets.
* _____________________________________________________________
*/
    
    /*
    * Creating the Structure for UnlockedType.
    *------------------------------------------------------------
    */
    struct UnlockedType {
        address address_unlocked;
        uint8 percent_unlocked;
    }
    
        /*
        * Assigning the values for public sale.
        *------------------------------------------------------------
        */
        UnlockedType public public_sale = UnlockedType(
                0xCCF86383BCAc8444f265e1F06905aE49cBB8bE2B, // Address for minting the public sale fund.
                40 // percent of the total supply will mint to the public sale fund address.
            );
    
        /*
        * Assigning the values for Liquidity & Exchanges.
        *------------------------------------------------------------
        */
        UnlockedType public liquidity_and_exchanges = UnlockedType(
                0xCCF86383BCAc8444f265e1F06905aE49cBB8bE2B, // Address for minting the liquidity and exchanges fund.
                5 // percent of the total supply will mint to the liquidity and exchange fund address.
            );
        
        
    /*
    * Creating the Structure for presale.
    *------------------------------------------------------------
    */
    struct PresaleUnlockedType {
        address presale_wallet;
        address funding_address;
        uint8 percent_unlocked;
        uint8 percent_on_purchase;
        uint256 token_rate;
        uint256 max_buy_limit;
        uint256 token_sold;
        bool is_started;
    }
    
    mapping(address => uint256) public presale_purchased_per_user;  // It have the amount data for each user purchased in presale.
    mapping(address => uint256) public presale_received_per_user; // It have the amount data for each user recieved the tokens.
    mapping(address => uint256) public amount_spend_per_user; // It have the amount of data for each user have spend in wei in presale.
        /*
        * Assigning values to the presale.
        *------------------------------------------------------------
        */
        PresaleUnlockedType public presale = PresaleUnlockedType(
                0xCCF86383BCAc8444f265e1F06905aE49cBB8bE2B, // Presale wallet where the Token will mint.
                0xCCF86383BCAc8444f265e1F06905aE49cBB8bE2B, // Presale wallet where the fund will go on each buy.
                20, // percent of total supply of the token goes for the presale. Unlocked.
                25, // percent of amount the buy will get on the purchase instantly.
                100000000000, // number of tokens with decimals offer in 1 ETH.
                100000000000000000,  // maximum amount in wei per user can spend in the presale.  
                0, // Amount of token sold initialize to zero.
                false
            );
        
/*
*------------------------------------------------------------
* Initializing the unlocked wallets.
* _____________________________________________________________
*/
uint256 private month = 2628000;

    /*
    * Creating the Structure for locked type.
    *------------------------------------------------------------
    */
    struct LockedType {
        address[] address_locked;
        uint8 percent_locked;
        uint256 locked_timestamp;
    }
    
        /*
        * Assigning values to the Team.
        *------------------------------------------------------------
        */
        LockedType public team_locked = LockedType(
                new address[](2), // The length should be change according to the number of team member.
                9, // percent of total supply will mint to the team locked address.
                block.timestamp + (24*month)  // timestamp of the team locked
            );
            
        /*
        * Assigning values to the marketing and partnership.
        *------------------------------------------------------------
        */
        LockedType public  makt_and_pship_locked = LockedType(
                new address[](1), // The length should be change according to the number of marketing and partnership.
                11, // percent of total supply will mint to the marketing and partnership locked address.
                block.timestamp + (12*month)  // timestamp of the marketing and partnership locked
            );
        
        /*
        * Assigning values to the company reserve locked.
        *------------------------------------------------------------
        */
        LockedType public company_reserve_locked = LockedType(
                new address[](1), // The length should be change according to the number of company_reserve.
                5, // percent of total supply will mint to the company reserve locked address.
                block.timestamp + (12*month)  // timestamp of the company reserve locked
            );
        
        
        /*
        * Assigning values to the staking locked.
        *------------------------------------------------------------
        */
        LockedType public staking_locked = LockedType(
                new address[](1), // The length should be change according to the number of staking member.
                10, // percent of total supply will mint to the staking locked address.
                block.timestamp + (6*month)  // timestamp of the staking locked
            );
            
    
    address[] private blacklist;
    
    constructor(){
        /*
        * Assigning addresses to the locked wallets.
        *------------------------------------------------------------
        */
        team_locked.address_locked = [
                0xCCF86383BCAc8444f265e1F06905aE49cBB8bE2B,
                0xCCF86383BCAc8444f265e1F06905aE49cBB8bE2B
            ];
        
        makt_and_pship_locked.address_locked = [
                0xCCF86383BCAc8444f265e1F06905aE49cBB8bE2B
            ];
        
        company_reserve_locked.address_locked = [
                0xCCF86383BCAc8444f265e1F06905aE49cBB8bE2B
            ];
        
        staking_locked.address_locked = [
                0xCCF86383BCAc8444f265e1F06905aE49cBB8bE2B
            ];
        
        uint256 supply = 1000000000*(10**_decimals);
        
        /*
        * minting fund to unlocked addresses.
        *------------------------------------------------------------
        */
        _mint(presale.presale_wallet, (presale.percent_unlocked*supply)/100);
        _mint(public_sale.address_unlocked, (public_sale.percent_unlocked*supply)/100);
        _mint(liquidity_and_exchanges.address_unlocked, (liquidity_and_exchanges.percent_unlocked*supply)/100);
        
        
        /*
        * minting fund to locked addresses.
        *------------------------------------------------------------
        */
            
            // Minting to the locked wallets.
            for(uint i=0; i < team_locked.address_locked.length; i++){
                _mint(team_locked.address_locked[i], (team_locked.percent_locked*supply)/(100*team_locked.address_locked.length));
            }
            
            for(uint i=0; i < makt_and_pship_locked.address_locked.length; i++){
                _mint(makt_and_pship_locked.address_locked[i], (makt_and_pship_locked.percent_locked*supply)/(100*makt_and_pship_locked.address_locked.length));
            }
            
            for(uint i=0; i < company_reserve_locked.address_locked.length; i++){
                _mint(company_reserve_locked.address_locked[i], (company_reserve_locked.percent_locked*supply)/(100*company_reserve_locked.address_locked.length));
            }
            
            for(uint i=0; i < staking_locked.address_locked.length; i++){
                _mint(staking_locked.address_locked[i], (staking_locked.percent_locked*supply)/(100*staking_locked.address_locked.length));
            }
        
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(filter_blacklist(msg.sender)==false, "Transfer: Address Blacklisted.");
        /*
        * validating the locked addresses.
        *------------------------------------------------------------
        */
            for(uint i=0; i < team_locked.address_locked.length; i++){
                if(sender == team_locked.address_locked[i]){
                    require(team_locked.locked_timestamp < block.timestamp, "Time Remaining for the locked address");
                }
            }
            
            for(uint i=0; i < makt_and_pship_locked.address_locked.length; i++){
                if(sender == makt_and_pship_locked.address_locked[i]){
                    require(makt_and_pship_locked.locked_timestamp < block.timestamp, "Time Remaining for the locked address");
                }
            }
            
            for(uint i=0; i < company_reserve_locked.address_locked.length; i++){
                if(sender == company_reserve_locked.address_locked[i]){
                    require(company_reserve_locked.locked_timestamp < block.timestamp, "Time Remaining for the locked address");
                }
            }
            
            for(uint i=0; i < staking_locked.address_locked.length; i++){
                if(sender == staking_locked.address_locked[i]){
                    require(staking_locked.locked_timestamp < block.timestamp, "Time Remaining for the locked address");
                }
            }
        

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount); 
    }
    
    function buyToken() public payable{
        require(msg.sender!=address(0), "Presale: buyer cannot be address zero.");
        require(msg.value > 0, "Presale: value can't be zero");
        require(buy_allowance_left_by_user(msg.sender)>0, "Presale: Allowance per buyer Exceed.");
        require(filter_blacklist(msg.sender)==false, "Presale: Address Blacklisted.");
        
        uint256 total_transfer_amount = predict_token_value(msg.value);
        presale.token_sold += total_transfer_amount;
        uint256 transfer_amount = (total_transfer_amount*presale.percent_on_purchase)/100;
        
        amount_spend_per_user[msg.sender] += msg.value;
        presale_purchased_per_user[msg.sender] += total_transfer_amount;
        presale_received_per_user[msg.sender] += transfer_amount;
        
        payable(presale.funding_address).transfer(msg.value); // fund is going to the presale funding address.
        _transfer(presale.presale_wallet, msg.sender, transfer_amount); // tokens are transfer as per the calculated value with the bnb, token rate and the percent of distribution in advance.
    }
    
    function predict_token_value(uint256 amount_in_wei) public view returns(uint256) {
        return (amount_in_wei*presale.token_rate)/(10**18);
    }
    
    function changeTokenRate(uint256 tokens_with_decimals_per_eth) public onlyOwner {
        presale.token_rate = tokens_with_decimals_per_eth;
    }
    
    function startPresale() public onlyOwner {
        presale.is_started = true;
    }
    
    function endPresale() public onlyOwner {
        presale.is_started = false;
    }
    
    function change_max_buy_limit(uint256 new_buy_limit_in_eth) public onlyOwner {
        presale.max_buy_limit = new_buy_limit_in_eth;
    }
    
    function add_to_blacklist(address[] memory address_array) public onlyOwner {
        for(uint i = 0; i < address_array.length; i ++ ){
            blacklist.push(address_array[i]);
        }
    }
    
    function get_blacklist() public view returns(address[] memory) {
        return blacklist;
    }
    
    function filter_blacklist(address _address) private view returns(bool) {
        bool is_exist = false;
        for(uint i = 0; i < blacklist.length; i++){
            if(blacklist[i]==_address){
                is_exist = true;
            }
        }
        return is_exist;
    }
    
    function buy_allowance_left_by_user(address _address) public view returns(uint256) {
        return presale.max_buy_limit - amount_spend_per_user[_address];
    }
    
    function Airdrop_for_presale(address[] memory address_array, uint256[] memory amount_array) public onlyOwner {
        // Please make sure that the two parameter are array.
        // Please make sure that the amount of tokens should be multiplied by the decimals.
        
        for(uint i = 0; i < address_array.length; i++){
            _transfer(msg.sender, address_array[i], amount_array[i]);
            presale_received_per_user[address_array[i]] += amount_array[i];
        }
    }
    
    function Airdrop(address[] memory address_array, uint256[] memory amount_array) public {
        for(uint i =0; i< address_array.length; i++){
            _transfer(msg.sender, address_array[i], amount_array[i]);
        }
    }
}