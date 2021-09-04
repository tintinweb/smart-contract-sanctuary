/**
 *Submitted for verification at polygonscan.com on 2021-09-03
*/

// SPDX-License-Identifier: MIT




/**
 
 كَمَثَلِ حَبَّةٍ أَنبَتَتْ سَبْعَ سَنَابِلَ فِي كُلِّ سُنبُلَةٍ مِّائَةُ حَبَّةٍ ۗ وَاللَّهُ يُضَاعِفُ لِمَن يَشَاءُ (سورة البقرة الأية 261)
/**
 * 
 * 
 * Website: https://islamicoin.finance
 * 
 * Official Social Accounts for ISLAMICOIN
 * 
 * 
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
pragma solidity ^0.8.4;

// Start Of Interface

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IMatic {
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
interface IMaticMetadata is IMatic {
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

// Start of contracts


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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

abstract contract IslamiMatic is Ownable, IMatic, IMaticMetadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping(address => bool) AirDropBlacklist;
        event Blacklist(address indexed blackListed, bool value);

    uint256 private _totalSupply;
    uint256 private _finaltotalsupply;
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
        _finaltotalsupply = 300000000000000000;   // 30 Billion ISLAMI
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
        return 7;
    }
    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function maxSupply() public view returns (uint256){
        return _finaltotalsupply;
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Cannot transfer ISLAMI from zero address");
        require(recipient != address(0), "Cannot transfer ISLAMI to zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ISLAMI: transfer amount exceeds balance");
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
        require(_totalSupply <= _finaltotalsupply, "ISLAMICOIN Total Supply is 30 Billions Only");
        require(account != address(0), "ISLAMI: mint to the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ISLAMI: approve from the zero address");
        require(spender != address(0), "ISLAMI: approve to the zero address");

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
contract ISLAMICOIN is IslamiMatic {
    
    uint256 internal aSBlock;uint256 internal aEBlock;uint256 internal aCap;uint256 internal aTot;uint256 internal aAmt; 
    uint256 internal sSBlock;uint256 internal sEBlock;uint256 internal sCap;uint256 internal sTot;uint256 internal sChunk;
    uint256 internal sPrice;uint256 internal priceChange;uint256 internal Charity;uint256 internal FinalAmount; uint256 internal sPchange;
    
  
    uint256 internal sonbola = 10** decimals();
    uint256 internal qMint = 7776000;   // 90 Days
    uint256 internal tmint = 1725407999; // Tuesday, September 3, 2024 11:59:59 PM "Team Mint"
    uint256 internal mintTime = block.timestamp + qMint;
    uint256 internal mPrice;
    uint256 internal perMatic = mPrice * 1 ether;
    

    address AirDropAD = address(0xC07BA4A5074f2cDd5133AD4F5380731D10CFE3f1);   // AirDrop contract    
    address CharityAD = address(0xcEF7FEf9514AA1B127661D489B7742f2b166A4cd); // "Bayt Al-Mal / بيت المال" contract for charity
    address USDT = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F); // USDT contract address on ploygon blockchain
    
    constructor() IslamiMatic("ISALMICOIN", "ISLAMI", 0) {
        
        _mint(msg.sender,     7999999990 * sonbola);    // ISLAMICOIN contract creator 
        _mint(address(this),  6000000000 * sonbola);    // Contract Address for crowdsale featur
        _mint(AirDropAD,      1000000000 * sonbola);    // AirDrop 
        _mint(CharityAD,      10         * sonbola);    // Charity Address 2.5% add at each transfer detucted from contract
        
     // No access control mechanism (for minting/pausing) and hence no governance
        
        Charity = 5; // Devided by 2 in Transfer function to represent Zakkat persentage 2.5%
        priceChange = 5;
     
    }
    
    function maticpPrice (uint256 maticPricePerUSDT) public onlyOwner {
       mPrice = maticPricePerUSDT * sonbola; 
    }
    function viewPriceInUSDT () public view returns(uint256 Price_In_USD){
        return(mPrice);
    }
    
    function quarterMint()  public onlyOwner returns (bool success){
        require (block.timestamp >= mintTime, "Minting is not yet");
        _mint (address(this), 100000000 * sonbola);
        mintTime  = block.timestamp + qMint;
       return true;
    }
    function teamMint()  public onlyOwner returns (bool success){
        require (block.timestamp >= tmint, "Team Minting is not yet");
        _mint (msg.sender, 900000000 * sonbola);
       return true;
    }
    function getAirdrop(address Brother) public returns (bool success){
        require(block.number <= aEBlock, "Air Drop not started or ended");
        require(AirDropBlacklist[msg.sender] == false, "AirDrop can be claimed only once");
        aTot ++;
         if(msg.sender != Brother && balanceOf(Brother) != 0 && Brother != 0x0000000000000000000000000000000000000000){
          _transfer(AirDropAD, Brother, aAmt/2);
        }
        _transfer(AirDropAD, msg.sender, aAmt);
        super._blackListAirdrop(msg.sender, true);
        return true;
    
      }

  function tokenSale(address) public payable returns (bool success){
    require(balanceOf(address(msg.sender)) <= 20000000 * sonbola , "You reached your public sale limit");  
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(sTot < sCap || sCap == 0);
    
    uint256 _eth = msg.value;
    uint256 _tkns;
   
    require (_eth >= 1 ether && _eth <= 1000 ether, "Minimum 1 MATIC / Maximum 1000 MATIC");
    _tkns = (sPrice*_eth) / 1 ether;
    sTot ++;
    
    _transfer(address(this), msg.sender, _tkns); 
    sPrice = sPrice - (sPrice*priceChange/2)/sPchange;
    
    return true;
  }
  
  function payUSDT (address MATIC_USDT, uint256 usdt_Amt) public returns (bool success){
   
    if (MATIC_USDT == USDT) {
       uint256 _usdtprice = mPrice;
       uint256 _islami;
       _islami = _usdtprice * usdt_Amt;
       
       _transfer(address(this), msg.sender, _islami * sonbola);
      
    } 
    return true;
  }

  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }
  
  function startAirdrop( uint _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
    aEBlock = _aEBlock;aAmt = _aAmt * sonbola;aCap = _aCap;
  }
  function startSale(uint256 _sSBlock, uint256 _sEBlock,uint256 _sPrice, uint256 _sCap, uint256 _sPchange) public onlyOwner{
    sSBlock = _sSBlock;sEBlock = _sEBlock;sPrice =_sPrice * sonbola;sCap = _sCap; sPchange = _sPchange;
  }
  function end_Air_Drop () public onlyOwner{
          aEBlock = block.number;
  }
  function end_Sale () public onlyOwner{
          sEBlock = block.number;
  }
  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint givecharity = (amount*Charity/2)/100;
        uint transferAmount = amount ;
        
        if (sender == address(this) && balanceOf(address(this)) >= givecharity ) {                // if sender is crowdsale Address and crowdsale not empty
            super._transfer(sender,recipient, transferAmount);
            super._transfer(sender,CharityAD,givecharity);
            
        } 
        else if(sender == AirDropAD){    // if sender is AirDrop Address
            super._transfer(sender,recipient, transferAmount);
            super._transfer(address(this),CharityAD,givecharity);
        }
        else if(balanceOf(address(this)) >= givecharity) {        // if ISLAMICOIN contract is not empty (ISLAMI Tokens)                                 
            super._transfer(sender,recipient, transferAmount);
            super._transfer(address(this),CharityAD,givecharity);
        }
        else if(recipient == CharityAD) {        // When donations sent to Bayt Al-Mal                                
            super._transfer(sender,recipient, transferAmount);
        }
        else {                                                                   
            super._transfer(sender,recipient,transferAmount);
        }
    }
    function claimTokens() public onlyOwner {
           address payable _owner = payable(msg.sender);
           _owner.transfer(address(this).balance);
    }
    function Claim_ERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IslamiMatic(tokenAddress).transfer(owner(), tokenAmount);
    }
}


/**
 *  NO ONE WILL REAP EXCEPT WHAT THEY SOW" (AL-QURAN, 6:164)
 * 
 * 
 * Edited by: ISLAMICOIN Developers
 */