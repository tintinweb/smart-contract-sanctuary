pragma solidity ^0.7.0;

import "./IERC165.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ISFT.sol";
import "./IFaces.sol";
import "./Context.sol";
import "./Ownable.sol";

/**
 *
 * SFT Contract (The native token of SatoshiFaces)
 * @dev Extends standard ERC20 contract
 */
contract SFT is Context, Ownable, ISFT {
    using SafeMath for uint256;

    // Constants
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant SECONDS_IN_A_YEAR = SECONDS_IN_A_DAY * 365;
    
    uint256 public constant INITIAL_ALLOTMENT = 500 * (10 ** 18);

    // Public variables
    uint256 public constant EMISSION_START = 1617667200; // Tuesday, April 6, 2021 0:00:00 GMT
    uint256 public constant EMISSION_END = EMISSION_START + (SECONDS_IN_A_YEAR * 10); // 10 years
    
    // emission rate decreases with a reduction factor of 0.75 per year
    uint256 public constant EMISSION_PER_DAY_YEAR_0 = 5.00 * (10 ** 18);
    uint256 public constant EMISSION_PER_DAY_YEAR_1 = 3.75 * (10 ** 18);
    uint256 public constant EMISSION_PER_DAY_YEAR_2 = 2.81 * (10 ** 18);
    uint256 public constant EMISSION_PER_DAY_YEAR_3 = 2.11 * (10 ** 18);
    uint256 public constant EMISSION_PER_DAY_YEAR_4 = 1.58 * (10 ** 18);
    uint256 public constant EMISSION_PER_DAY_YEAR_5 = 1.19 * (10 ** 18);
    uint256 public constant EMISSION_PER_DAY_YEAR_6 = 0.89 * (10 ** 18);
    uint256 public constant EMISSION_PER_DAY_YEAR_7 = 0.67 * (10 ** 18);
    uint256 public constant EMISSION_PER_DAY_YEAR_8 = 0.50 * (10 ** 18);
    uint256 public constant EMISSION_PER_DAY_YEAR_9 = 0.36 * (10 ** 18);
    
    uint256[10] public EMISSION_PER_DAY_YEARS = [  EMISSION_PER_DAY_YEAR_0, 
                                                EMISSION_PER_DAY_YEAR_1, 
                                                EMISSION_PER_DAY_YEAR_2,
                                                EMISSION_PER_DAY_YEAR_3,
                                                EMISSION_PER_DAY_YEAR_4,
                                                EMISSION_PER_DAY_YEAR_5,
                                                EMISSION_PER_DAY_YEAR_6,
                                                EMISSION_PER_DAY_YEAR_7,
                                                EMISSION_PER_DAY_YEAR_8,
                                                EMISSION_PER_DAY_YEAR_9];

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping(uint256 => uint256) private _lastClaim;
    
    mapping(uint256 => uint256) private _claimedAmount;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _facesAddress;
    address private _addonsAddress;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () {
        _name = "SatoshiFinanceToken";
        _symbol = "SFT";
        _decimals = 18;
    }

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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev When accumulated SFTs have last been claimed for a SatoshiFaces index
     */
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(IFaces(_facesAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IFaces(_facesAddress).totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0 ? uint256(_lastClaim[tokenIndex]) : EMISSION_START;
        return lastClaimed;
    }
    
    /**
     * @dev Total accumulated SFT tokens for all existing SatoshiFace NFTs.
     */
    function totalAccumulatedSupply() public view override returns (uint256) {
        require(block.timestamp > EMISSION_START, "Emission has not started yet");
        require(IFaces(_facesAddress).ownerOf(0) != address(0), "Owner of NFT #0 cannot be 0 address");
        require(0 < IFaces(_facesAddress).totalSupply(), "No NFTs have been minted yet");
        
        uint256 nftSupply = IFaces(_facesAddress).totalSupply();
        return nftSupply.mul(totalAccumulated(0));
    }
    
    /**
     * @dev Accumulated SFT tokens for a SatoshiFaces token index.
     */
    function accumulated(uint256 tokenIndex) public view override returns (uint256) {
        require(block.timestamp > EMISSION_START, "Emission has not started yet");
        require(IFaces(_facesAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IFaces(_facesAddress).totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = lastClaim(tokenIndex);

        // sanity check if last claim was on or after emission end
        if (lastClaimed >= EMISSION_END) return 0;

        uint256 accumulatedQty = totalAccumulated(tokenIndex).sub(totalClaimed(tokenIndex));
        return accumulatedQty;
    }
    
    /**
     * @dev Lifetime Accumulated SFT tokens for a SatoshiFaces token index.
     */
    function totalAccumulated(uint256 tokenIndex) public view override returns (uint256) {
        require(block.timestamp > EMISSION_START, "Emission has not started yet");
        require(IFaces(_facesAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IFaces(_facesAddress).totalSupply(), "NFT at index has not been minted yet");
        
        uint256 nowTime = block.timestamp < EMISSION_END ? block.timestamp : EMISSION_END;
        uint256 elapsedTime = nowTime.sub(EMISSION_START);
        uint256 yearsElapsed = elapsedTime.div(SECONDS_IN_A_YEAR);
        uint256 totalAmountAccumulated = 0;
        uint256 timeAccountedFor = 0;
        
        // amount accumulated in each year
        for(uint year = 0; year < yearsElapsed; year++) {
            uint256 emissionPerDayForYear = EMISSION_PER_DAY_YEARS[year];
            uint256 yearAccumulated = emissionPerDayForYear.mul(365);
            totalAmountAccumulated = totalAmountAccumulated.add(yearAccumulated);
            timeAccountedFor = timeAccountedFor.add(SECONDS_IN_A_YEAR);
        }
        // amount accumulated since last full year
        if(elapsedTime > timeAccountedFor && yearsElapsed < 10) {
            uint256 remainingTime = elapsedTime.sub(timeAccountedFor);
            uint256 currentEmissionRate = EMISSION_PER_DAY_YEARS[yearsElapsed];
            uint256 remainingAccumulated = remainingTime.mul(currentEmissionRate).div(SECONDS_IN_A_DAY);
            totalAmountAccumulated = totalAmountAccumulated.add(remainingAccumulated);
        }
        // add initial allotment
        totalAmountAccumulated = totalAmountAccumulated.add(INITIAL_ALLOTMENT);
        
        return totalAmountAccumulated;
    }
    
    /**
     * @dev Lifetime SFT tokens claimed from a token index SatoshiFaces NFT
     */
    function totalClaimed(uint256 tokenIndex) public view override returns (uint256) {
        require(IFaces(_facesAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IFaces(_facesAddress).totalSupply(), "NFT at index has not been minted yet");
        
        uint256 claimed = uint256(_claimedAmount[tokenIndex]) >= 0 ? uint256(_claimedAmount[tokenIndex]) : 0;
        return claimed;
    }

    /**
     * @dev Set right after deployment and verified
     */
    function setFacesAddress(address facesAddress) onlyOwner public {
        require(_facesAddress == address(0), "Already set");
        _facesAddress = facesAddress;
    }
    
    /**
     * @dev To be set at a later date when the platform is developed
     */
    function setAddonsAddress(address addonsAddress) onlyOwner public {
        _addonsAddress = addonsAddress;
    }
    
    /**
     * @dev Claim mints SFTs and supports multiple SatoshiFaces token indices at once.
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        require(block.timestamp > EMISSION_START, "Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] < IFaces(_facesAddress).totalSupply(), "NFT at index has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIndices.length; j++) {
                require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
            }

            uint tokenIndex = tokenIndices[i];
            require(IFaces(_facesAddress).ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                _lastClaim[tokenIndex] = block.timestamp;
                uint256 alreadyClaimed = _claimedAmount[tokenIndex];
                _claimedAmount[tokenIndex] = alreadyClaimed.add(claimQty);
                totalClaimQty = totalClaimQty.add(claimQty);
            }
        }

        require(totalClaimQty != 0, "No accumulated SFT");
        _mint(msg.sender, totalClaimQty); 
        return totalClaimQty;
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
        // Approval check is skipped if the caller of transferFrom is the SatoshiFaces or SatoshiFaces Addons contract. For better UX.
        if (msg.sender == _facesAddress) {
            // caller of transferFrom is the SatoshiFaces contract
        }
        else if(_addonsAddress != address(0) && msg.sender == _addonsAddress) {
            // addons contract address is set and caller is from the SatoshiFaces Addons contract
        }
        else {
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    // ++
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
    // ++

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _setupDecimals(uint8 decimals_) internal {
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