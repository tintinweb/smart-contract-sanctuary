/***
 *
 * 
 *  Project: XXX
 *  Website: XXX
 *  Contract: MOX shares
 *  
 *  Description: Received by investors and NFT holders
 * 
 */
 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IMOX.sol"; 
import "./IMOXbucks.sol"; 
 
/**
 * @dev Implementation of the {IERC20} interface. 
 *
 */
contract MOXshares is Context, IERC20Metadata, Ownable { 
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (uint256 => uint256) private _lastClaim;
  
    address private _owner;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _nftContractAddress;
    address private _tokenContractAddress;
    address private _additionalContract;

    uint256 public SHARES_PER_DAY = 1000000000000000000; //1 share per day
    uint public constant SECONDS_PER_DAY = 86400;

    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;
    //IMOXbucks private token;
    /**
     * @dev Sets the values for {name}, {symbol} and {owner}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialSupply_;
        _balances[msg.sender] = initialSupply_;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, initialSupply_);
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
     * overloaded;
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
     * @dev Show total supply to external contracts.
     */
    function getTotalSupply() external view returns (uint256) {
        return _totalSupply;
    } 

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev Get balance to external contracts.
     */
    function getBalanceOf(address account) external view returns (uint256) {
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

        //uint256 currentAllowance = _allowances[sender][_msgSender()];
        //require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        //_approve(sender, _msgSender(), currentAllowance - amount);
       
        if ((msg.sender != _nftContractAddress) && (msg.sender != _additionalContract)) {
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
       
        
        if((_balances[recipient]!=0) && (!IMOXbucks(_tokenContractAddress).isCurrentOwner(recipient)))
            IMOXbucks(_tokenContractAddress).includeCurrentOwner(recipient);
            
        if((_balances[sender]==0) && (IMOXbucks(_tokenContractAddress).isCurrentOwner(sender)))
            IMOXbucks(_tokenContractAddress).excludeCurrentOwner(sender); 
        
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
     * @dev Burns a quantity of tokens held by the caller.
     *
     * Emits an {Transfer} event to 0 address
     *
     */
    function burn(uint256 burnQuantity) public virtual override returns (bool) {
        _burn(msg.sender, burnQuantity);
        return true;
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
     * @dev Set NFT address
     */
    function setNFTContractAddress(address nftAddress) public onlyOwner{
        _nftContractAddress = nftAddress;
    }
    
    /**
     * @dev Set token address 
     */
    function setTokenContractAddress(address tokenAddress) public onlyOwner{
       _tokenContractAddress = tokenAddress;
    }
    
    
    /**
     * @dev Set additional contract address
     */
    function setAdditionalContractAddress (address contractAddress) public onlyOwner{
        _additionalContract = contractAddress;
    }
    
    /**
     * @dev Mints daily tokens assigned to a NFT array. Returns the minted quantity.
     */
    function claimTokens(uint256[] memory tokenIds) public returns (uint256) {
        uint256 totalClaimQty = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            // Sanity check for non-minted index
            require(tokenIds[i] < IMOX(_nftContractAddress).totalSupply(), "NFT has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token index");
            }

            uint256 tokenIndex = tokenIds[i];
            require(IMOX(_nftContractAddress).ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");
            require(!IMOX(_nftContractAddress).isRedeemed(tokenIndex),"This NFT was redeemed");

            uint256 claimQty = tokensToClaim(tokenIndex); 
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "Nothing to harvest");
        
        _mint(msg.sender, totalClaimQty); 
        return totalClaimQty;
    }
   
    /**
     * @dev Measures daily tokens assigned to a NFT, that are ready to be claimed.
     */
    function tokensToClaim(uint256 tokenIndex) internal view returns (uint256) {
        require(IMOX(_nftContractAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IMOX(_nftContractAddress).totalSupply(), "NFT has not been minted yet");
        uint256 lastClaimed;
        if (_lastClaim[tokenIndex]==0)
            lastClaimed = IMOX(_nftContractAddress).getBirthday(tokenIndex); 
        else
            lastClaimed = _lastClaim[tokenIndex];
        
        uint256 totalAccumulated = (block.timestamp).sub(lastClaimed).mul(SHARES_PER_DAY).div(SECONDS_PER_DAY);
        return totalAccumulated;
    }
    
    /**
     * @dev Measures daily tokens assigned to a NFT array that are ready to be harvested.
     */
    function tokensArrayToClaim(uint256[] memory tokenIds) public view returns (uint256) {
        uint256 totalSum;
        for (uint i = 0; i < tokenIds.length; i++)
           totalSum = totalSum.add(tokensToClaim(tokenIds[i]));
    
        return totalSum;
    }
    
    /**
     * @dev Modifies daily reward
     */
    function modifyDailyReward(uint _dailyReward) public onlyOwner {
        SHARES_PER_DAY = _dailyReward;
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