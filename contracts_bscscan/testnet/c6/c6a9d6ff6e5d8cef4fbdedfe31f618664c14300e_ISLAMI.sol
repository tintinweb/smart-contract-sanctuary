/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// SPDX-License-Identifier: MIT


/**
 * 369
 * 
 * NO ONE WILL REAP EXCEPT WHAT THEY SOW" (AL-QURAN, 6:164)
 * 
 * Official Social Accounts for ISLAMICOIN
 * 
 * Website: https://islamicoin.finance
 * Email: [email protected]
 * Facebook: https://facebook.com/islamicoin
 * Twitter: https://twiter.com/islamicoin
 * Reddit: https://www.reddit.com/r/islamicoin
 * Youtube: https://www.youtube.com/channel/UCPdg9Cx2g9DyTR_xD5S_lXA
 * Discord: https://discord.gg/5Ya8gDwaUr
 * Telegram: https://t.me/islamicoin1
 * Instagram: https://www.instagram.com/islamicoin
 * LinkedIn: https://www.linkedin.com/company/islamicoin
 */
pragma solidity ^0.8.6;

// Start Of Interface

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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

/**
 * @dev Interface for the optional metadata functions from the BEP20 standard.
 *
 * _Available since v4.1._
 */
interface IBEP20Metadata is IBEP20 {
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
    
    /**
     * @dev Returns the decimals unit name of the token.
     */
    function DecimalUnitName() external view returns (string memory);
}

// Start of contracts

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
contract BEP20 is Context, IBEP20, IBEP20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping(address => bool) AirDropBlacklist;
        event Blacklist(address indexed blackListed, bool value);

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
    constructor(string memory name_, string memory symbol_, uint256 totalsupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalsupply_;
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
     * Ether and Wei. This is the value {BEP20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    /**
     * @dev ISLAMI decimal unit name (as Satoshi for Bitcoin)
     */
    function DecimalUnitName() public view virtual override returns (string memory){
        return "Halal";
    }
    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
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
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
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
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
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
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
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
     * problems described in {IBEP20-approve}.
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
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
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
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
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
    function _mint(address account, uint256 amount) internal {
        require(_totalSupply <= 30000000000000000000, "ISLAMICOIN Total Supply is 30 Billions Only");
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
    function _beforeTokenTransfer( address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
   
   
    
  // Blacklist AirDrop address after one transaction, no more airddrop can be called
  
  function _blackListAirdrop(address _address, bool _isBlackListed) internal returns (bool) {
	require(AirDropBlacklist[_address] != _isBlackListed);
	AirDropBlacklist[_address] = _isBlackListed;
	emit Blacklist(_address, _isBlackListed);
	return true;
  }
    
  
  
  
}

/**
 * Token constructor, AirDrop & crowdsale
 */
contract ISLAMI is BEP20, Ownable{
    
    
        
    
    uint256 internal aSBlock; 
    uint256 internal aEBlock; 
    uint256 internal aCap; 
    uint256 internal aTot; 
    uint256 internal aAmt; 
    uint256 internal sSBlock; 
    uint256 internal sEBlock; 
    uint256 internal sCap; 
    uint256 internal sTot; 
    uint256 internal sChunk; 
    uint256 internal sPrice;
    uint256 internal priceChange;
    uint256 internal Charity;
    uint256 internal FinalAmount;
   
    
    constructor() BEP20("ISALMICOIN", "ISLAMI", 0) {
        
        
        _mint(msg.sender,                                          7999999990 *10** decimals());    // ISLAMICOIN contract creator 
        _mint(address(this),                                       6000000000 *10** decimals());    // Contract Address for crowdsale feature
        _mint(address(0xD8A73Bfbd1444ce4796409c9b77800e6067b591a), 10         *10** decimals());    // Charity Address 2% add at each transfer detucted from contract until crowdsale is finished
        _mint(address(0x4c2bC6dA7B2B763F472C92DbCf4e9143D7dafe4F), 2000000000 *10** decimals());    // Binance Liquidity
        _mint(address(0x5ace0765b41035d5A426F7CF29EaDbF6300ca079), 2000000000 *10** decimals());    // PancakeSwap Liquidity
        _mint(address(0xd85f84f91c37297Cb686F3B3a78085EF41F3ec27), 2000000000 *10** decimals());    // Kucoin Liquidity
        _mint(address(0xa3F7084f5610A9324fE952f079da6dEb23BEAa4D), 2000000000 *10** decimals());    // ISALMI Games and apps
        _mint(address(0x76085CCC82BC4ca0B82adB4b9f5a7A26c93f40C0), 2000000000 *10** decimals());    // Video on Demand / Website 
        _mint(address(0x9eF571aD7708D78AC054c6413E767a23eEEEbe0D), 2000000000 *10** decimals());    // e-commerce website goods sale liquidity
        _mint(address(0x4d1a71F898DE61F9401B65daB99a4faFFbC15f51), 3000000000 *10** decimals());    // ISLAMICOIN Development Team / 90% will be locked for 1 year
        _mint(address(0x310e09640a1bcF7ED93937C239f576f8ceCA3Eb9), 1000000000 *10** decimals());    // AirDrop 
     
     // No access control mechanism (for minting/pausing) and hence no governance
     
        Charity = 5; // Devided by 2 in Transfer function to represent Zakkat persentage 2.5%
        priceChange = 5; // Devided by 2 in tokensale function 0.25% price increse after each transaction
        
        startSale(block.number, 999999999000, 0,3000000 *10** decimals(), 5000000000);
        startAirdrop(block.number,999999999000,300 *10** decimals(),3333333);
        
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    
    function DecimalUnitName() public view virtual override returns (string memory){
        return "Halal";
    }
    
    function WeAreCreators() public view virtual returns (string memory){
        return "ISLAMICOIN Team";
    }

    function AirDrop_Amount() public view virtual returns (uint256){
        return (aAmt / 1000000000);
    }
    function AirDrop_Cap() public view virtual returns (uint256){
        return aCap;
    }
    function Selling_Price_For_Each_BNB() public view virtual returns (uint256){
        return  (sPrice / 1000000000);
    }
    function recoverBEP20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        BEP20(tokenAddress).transfer(owner(), tokenAmount);
        
    }
    
    
    
    function getAirdrop(address ) public returns (bool success){
        require(aSBlock <= block.number && block.number <= aEBlock);
        require(aTot < aCap || aCap == 0);
        require(AirDropBlacklist[msg.sender] == false, "AirDrop can be claimed only once");
        aTot ++;
        
        _transfer(address(0x310e09640a1bcF7ED93937C239f576f8ceCA3Eb9), msg.sender, aAmt);
        super._blackListAirdrop(msg.sender, true);
        return true;
    
      }


  function tokenSale(address) public payable returns (bool success){
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(sTot < sCap || sCap == 0);
    
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice*_eth) / 1 ether;
    sTot ++;
    sPrice = sPrice - (sPrice*priceChange/2)/1000;
    
    _transfer(address(this), msg.sender, _tkns);
    
    return true;
  }

  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) internal onlyOwner {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }
  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) internal onlyOwner{
    sSBlock = _sSBlock;
    sEBlock = _sEBlock;
    sChunk = _sChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    sTot = 0;
  }
    
  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint givecharity = (amount*Charity/2)/100;
        uint transferAmount = amount ;
    
        FinalAmount = transferAmount - givecharity;
        
        if (sender == address(this) && address(this).balance != 0 ) {                // if sender is crowdsale Address and crowdsale not equal to zero
            super._transfer(sender,recipient, FinalAmount);
            super._transfer(sender,address(0xD8A73Bfbd1444ce4796409c9b77800e6067b591a),givecharity);
        } 
        else if (sender == address(0x3Bdb2fccf4257cd35584245E3bC0a1F97b0A5C4b)){      // Transfer tokens to old investors
            super._transfer(sender,recipient, FinalAmount);
        //    super._transfer(sender,address(0xD8A73Bfbd1444ce4796409c9b77800e6067b591a),givecharity);
        }
        else if(sender == address(0x310e09640a1bcF7ED93937C239f576f8ceCA3Eb9)){    // if sender is AirDrop Address
            super._transfer(sender,recipient, transferAmount);
            super._transfer(address(this),address(0xD8A73Bfbd1444ce4796409c9b77800e6067b591a),givecharity);
        }
        else {                                                                    // if crowdasle Address become empty 2.5% will be on the investor (Represent Zakkat)
            super._transfer(sender,recipient, FinalAmount);
            super._transfer(sender,address(0xD8A73Bfbd1444ce4796409c9b77800e6067b591a),givecharity);
        }
        
        
    }

    function clear(uint amount) public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(amount);
    }
   
}


/**
 * مَّثَلُ الَّذِينَ يُنفِقُونَ أَمْوَالَهُمْ فِي سَبِيلِ اللَّهِ كَمَثَلِ حَبَّةٍ أَنبَتَتْ سَبْعَ سَنَابِلَ فِي كُلِّ سُنبُلَةٍ مِّائَةُ حَبَّةٍ ۗ وَاللَّهُ يُضَاعِفُ لِمَن يَشَاءُ ۗ وَاللَّهُ وَاسِعٌ عَلِيمٌ (سورة البقرة الأية 261)
 * 
 * 369
 * Edited by: ISLAMICOIN Developers
 */