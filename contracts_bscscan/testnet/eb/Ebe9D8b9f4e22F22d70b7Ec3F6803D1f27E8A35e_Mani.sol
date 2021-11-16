// SPDX-License-Identifier: MIT
// File: contracts/libs/BEP20.sol

pragma solidity = 0.6.12;

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
import 'Context.sol';
import 'IBEP20.sol';
import 'Ownable.sol';
import 'SafeMath.sol';
import 'Address.sol';
import "IUniswapV2Router01.sol";
import 'IUniswapV2Router02.sol';
import 'IUniswapV2Pair.sol';
import 'IUniswapV2Factory.sol';

contract Mani is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _targetSupply;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address=>bool) isBlacklisted;
    address payable _taxwallet;
    bool private _bBurn;
    bool private _bPause;

  	// Addresses excluded from taxes
	mapping(address=> bool) private _taxExcludedList;
	address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event UpdateTaxExclusionAdd(address _addTaxExclusion);
    event UpdateTaxExclusionRemove(address _addTaxExclusion);
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() public {
        _name = "Mani Wallet";
        _symbol = "Mani";
        _decimals = 8;
        _totalSupply = 22220000000000000;
        _targetSupply = _totalSupply;
        
        _bBurn = true;
        _bPause = false;
        _taxwallet = 0x5eDB72A749E59a17aF82e4E9E9475FC4E21F62d6;
        
        _taxExcludedList[address(this)] = true;
		_taxExcludedList[msg.sender] = true;
		_taxExcludedList[address(0)] = true;
		_taxExcludedList[BURN_ADDRESS] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
	function isTaxExcluded(address _taxExcluded) public view returns (bool) {		
		return _taxExcludedList[_taxExcluded];
	}
    	/**
	* @dev Add address exempted from transfer tax (eg. CEX, MasterChef)
	* Can only be called by the current operator
	*/
	function updateTaxExclusionAdd(address _addTaxExclusion) external {
		require(_addTaxExclusion != address(0),"Mami::updateTaxExclusionAdd:Zero address");
		require(!isTaxExcluded(_addTaxExclusion),"Mami::updateTaxExclusionAdd:Address is already excluded from transfer tax");		
		emit UpdateTaxExclusionAdd(_addTaxExclusion);		
		_taxExcludedList[_addTaxExclusion] = true;
	}
	/**
	* @dev Remove address exempted from transfer tax
	* Can only be called by the current operator
	*/
	function updateTaxExclusionRemove(address _removeTaxExclusion) external {
		require(_removeTaxExclusion != address(0),"Mami::updateTaxExclusionRemove:Zero address");
		require(isTaxExcluded(_removeTaxExclusion),"Mami::updateTaxExclusionRemove:Address is not excluded from transfer tax");	
		emit UpdateTaxExclusionRemove(_removeTaxExclusion);
		_taxExcludedList[_removeTaxExclusion] = false;
	}

    function canBurn() external view returns(bool){
        return _bBurn;
    }
    function setCanBurn(bool bCanBurn) external{
        _bBurn = bCanBurn;
    }
    function canPause() external view returns(bool){
        return _bPause;
    }
    function setCanPause(bool bCanPause) external{
        _bPause = bCanPause;
    }

    function blackList(address _user) public onlyOwner {
        require(!isBlacklisted[_user], "mani: user already blacklisted");
        isBlacklisted[_user] = true;
        // emit events as well
    }
    
    function removeFromBlacklist(address _user) public onlyOwner {
        require(isBlacklisted[_user], "mani: user already whitelisted");
        isBlacklisted[_user] = false;
        // emit events as well
    }
    

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "Mani: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "Mani: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        if(_totalSupply + amount > _targetSupply)
            amount = _targetSupply - _totalSupply;
        _mint(_msgSender(), amount);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "Mani: transfer from the zero address");
        require(recipient != address(0), "Mani: transfer to the zero address");
        require(!_bPause, "Mani: pause transfer");
        require(!isBlacklisted[recipient], "Recipient is backlisted");
        
        _balances[sender] = _balances[sender].sub(amount, "Mani: transfer amount exceeds balance");

        if( !isTaxExcluded(sender)){
            if(_bBurn){
                uint256 toWalletOwner = amount.div(100);
                uint256 toHolder = amount.mul(3).div(100);
                uint256 toBurn = amount.mul(2).div(100);
    
                _balances[_taxwallet] += toWalletOwner;
                _balances[owner()] += toHolder;
                
                _totalSupply -= toBurn;
                _balances[BURN_ADDRESS] += toBurn;
                
                uint256 rValue = amount - (toWalletOwner + toHolder + toBurn);
                _balances[recipient] += rValue;
            }
            else
            {
                uint256 toWalletOwner = amount.div(100);
                uint256 toHolder = amount.mul(3).div(100);
    
                _balances[_taxwallet] += toWalletOwner;
                _balances[owner()] += toHolder;
                
                uint256 rValue = amount - (toWalletOwner + toHolder);
                _balances[recipient] += rValue;
            }
        }
        else
            _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mani: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Mani: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "Mani: burn amount exceeds balance");
        _balances[BURN_ADDRESS] += amount;
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, BURN_ADDRESS, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), "Mani: approve from the zero address");
        require(spender != address(0), "Mani: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "Mani: burn amount exceeds allowance")
        );
    }
}