/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

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
        return msg.data;
    }
}

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

pragma solidity ^0.8.0;

abstract contract Sales is Ownable {
    struct SalesInfo{
        uint256 numberofToken;
        uint256 StartSaleTimestamp;
        uint256 EndSaleTimestamp;
        uint256 Raised;
        uint256 minSale;
        uint256 maxSale;
        uint256 Rate;
        uint256 maxSaleRate;
    }
    
    uint256 private releaseTimestamp;
    mapping(uint => SalesInfo) private SalesInfos;
    
    constructor() {
        releaseTimestamp = block.timestamp + 3650 days;
    }
    
    function buyTokens(uint index_, address Referrer_, address Beneficiary_) external virtual payable returns (bool) {}

    function setAngelSalesInfo(uint256 StartSaleTimestamp_) public virtual onlyOwner {
        _setSalesInfo(1, 30000000 * (uint256(10) ** 18), StartSaleTimestamp_, StartSaleTimestamp_ + 15 days, 0, 1.5 ether, 5 ether, 1000000, 1250000);
    }
    
    function setPrivate1SalesInfo(uint256 StartSaleTimestamp_) public virtual onlyOwner {
        _setSalesInfo(2, 30000000 * (uint256(10) ** 18), StartSaleTimestamp_, StartSaleTimestamp_ + 15 days, 0, 0.02 ether, 1 ether, 500000, 625000);
    }
    
    function setPrivate2SalesInfo(uint256 StartSaleTimestamp_) public virtual onlyOwner {
        _setSalesInfo(3, 30000000 * (uint256(10) ** 18), StartSaleTimestamp_, StartSaleTimestamp_ + 15 days, 0, 0.025 ether, 1 ether, 400000, 480000);
    }
    
    function setPrivate3SalesInfo(uint256 StartSaleTimestamp_) public virtual onlyOwner {
        _setSalesInfo(4, 30000000 * (uint256(10) ** 18), StartSaleTimestamp_, StartSaleTimestamp_ + 15 days, 0, 0.03 ether, 1 ether, 333333, 383333);
    }
    
    function setPrivate4SalesInfo(uint256 StartSaleTimestamp_) public virtual onlyOwner {
        _setSalesInfo(5, 30000000 * (uint256(10) ** 18), StartSaleTimestamp_, StartSaleTimestamp_ + 15 days, 0, 0.035 ether, 1 ether, 285714, 314285);
    }
    
    function setICOSalesInfo(uint256 StartSaleTimestamp_) public virtual onlyOwner {
        _setSalesInfo(6, 150000000 * (uint256(10) ** 18), StartSaleTimestamp_, StartSaleTimestamp_ + 30 days, 0, 0.05 ether, 1 ether, 200000, 210000);
    }
    
    function setPublicSalesInfo(uint256 StartSaleTimestamp_) public virtual onlyOwner {
        releaseTimestamp = StartSaleTimestamp_;
        _setSalesInfo(7, 300000000 * (uint256(10) ** 18), StartSaleTimestamp_, StartSaleTimestamp_ + 365 days, 0, 0.06 ether, 100 ether, 166666, 166666);
    }
    
    function setSalesInfo(uint index_, uint256 numberofToken_, uint256 StartSaleTimestamp_, uint256 EndSaleTimestamp_, uint256 Raised_, uint256 minSale_, uint256 maxSale_, uint256 Rate_, uint256 maxSaleRate_) public virtual onlyOwner {
        _setSalesInfo(index_, numberofToken_, StartSaleTimestamp_, EndSaleTimestamp_, Raised_, minSale_, maxSale_, Rate_, maxSaleRate_);
    }
    
    function _setSalesInfo(uint index_, uint256 numberofToken_, uint256 StartSaleTimestamp_, uint256 EndSaleTimestamp_, uint256 Raised_, uint256 minSale_, uint256 maxSale_, uint256 Rate_, uint256 maxSaleRate_) internal virtual {
        SalesInfos[index_].numberofToken = numberofToken_;
        SalesInfos[index_].StartSaleTimestamp = StartSaleTimestamp_;
        SalesInfos[index_].EndSaleTimestamp = EndSaleTimestamp_;
        SalesInfos[index_].Raised = Raised_;
        SalesInfos[index_].minSale = minSale_;
        SalesInfos[index_].maxSale = maxSale_;
        SalesInfos[index_].Rate = Rate_;
        SalesInfos[index_].maxSaleRate = maxSaleRate_;
    }
    
    function getSalesInfo(uint index) public view virtual returns (SalesInfo memory sale) {
        return SalesInfos[index];
    }
    
    
    function _setnumberofToken(uint index, uint256 numberofToken_) internal virtual {
        SalesInfos[index].numberofToken = numberofToken_;
    }
    
    function _setRaised(uint index, uint256 Raised_) internal virtual {
        SalesInfos[index].Raised = Raised_;
    }
    
    function _getnumberofToken(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].numberofToken;
    }
    
    function _getStartSaleTimestamp(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].StartSaleTimestamp;
    }
    
    function _getEndSaleTimestamp(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].EndSaleTimestamp;
    }
    
    function _getRaised(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].Raised;
    }
    
    function _getminSale(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].minSale;
    }
    
    function _getmaxSale(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].maxSale;
    }
    
    function _getRate(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].Rate;
    }
    
    function _getmaxSaleRate(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].maxSaleRate;
    }
    
    function _getReleaseTimestamp() internal view virtual returns (uint256) {
        return releaseTimestamp;
    }
    
    function getReleaseTimestamp() public view virtual returns (uint256) {
        return releaseTimestamp;
    }
}

pragma solidity ^0.8.0;

contract AMR is Context, IERC20, IERC20Metadata, Ownable, Sales {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    
    struct UserInfo {
        uint256 amount;
        uint256 raised;
    }
    
    mapping(address => mapping(uint => UserInfo)) private UserInfos;
    mapping(address => address) private UserReferrer;
    
    uint256[] private refIncomePercent;
    uint256 private TotalMintandSupply;
    
    constructor() {
        _name = "Alpha Machina";
        _symbol = "AMR";
        _totalSupply = 2460000000 * (uint256(10) ** 18);
        
        TotalMintandSupply = 3690000000 * (uint256(10) ** 18);
        
        refIncomePercent.push(10);
        refIncomePercent.push(6);
        refIncomePercent.push(5);
        refIncomePercent.push(4);
        refIncomePercent.push(3);
        refIncomePercent.push(2);

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    function burn(uint256 amount) public virtual onlyOwner {
        _burn(_msgSender(), amount);
    }
    
    function mint(uint256 amount) public virtual onlyOwner {
        require(TotalMintandSupply >= _totalSupply + amount, "AMR: all reserve token minted");
        _mint(_msgSender(), amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        if (from != owner())
            require(block.timestamp >= _getReleaseTimestamp(), "AMR: current time is before release time");
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    
    
    function transferAnyERC20Token(address tokenAddress, uint256 amount) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(_msgSender(), amount);
    }
    
    function transferAnyETH(uint256 amount) public onlyOwner {
        (bool sent, ) = _msgSender().call{value: amount}("");
        require(sent, "AMR: failed to send ether");
    }
    
    function buyTokens(uint index_, address Referrer_, address Beneficiary_) public virtual override payable returns (bool) {
        require(msg.value >= _getminSale(index_), "AMR: less than minimum sale");
        require(msg.value <= _getmaxSale(index_), "AMR: greater than maximum sale");
        require(block.timestamp >= _getStartSaleTimestamp(index_), "AMR: befor sale start time");
        require(block.timestamp <= _getEndSaleTimestamp(index_), "AMR: after sale end time");
        require(Referrer_ != Beneficiary_, "AMR: can't refer yourself");
        
        uint256 amountTokens = 0;
        
        if (msg.value == _getmaxSale(index_)) {
            amountTokens = msg.value * _getmaxSaleRate(index_);
        }
        else {
            amountTokens = msg.value * _getRate(index_);
        }
        
        require(amountTokens <= _getnumberofToken(index_), "AMR: not enough token");
        require(UserInfos[Beneficiary_][index_].raised + msg.value <= _getmaxSale(index_), "AMR: you bought your share");
        
        _setnumberofToken(index_, _getnumberofToken(index_) - amountTokens);
        _setRaised(index_, _getRaised(index_) + msg.value);

        UserReferrer[Beneficiary_] = Referrer_;
        
        UserInfos[Beneficiary_][index_].raised += msg.value;
        UserInfos[Beneficiary_][index_].amount += amountTokens;
        
        distributeReferralIncome(Beneficiary_, amountTokens, index_);

        _transfer(owner(), Beneficiary_, amountTokens);
        
        emit TokenBought(Beneficiary_, index_, amountTokens, Referrer_);
        return true;
    }
    
    function distributeReferralIncome(address _user, uint256 _amount, uint _phaseNo) internal returns (uint256) {
        uint256 sumDistributed = 0;
        address ref = UserReferrer[_user];
        
        for (uint256 i = 0; i < 6; i++) {
            if (ref == address(0)) {
                break;
            }
            
            uint256 income = _amount * refIncomePercent[i] / 100;
            
            UserInfos[ref][_phaseNo].amount += income;
            
            _transfer(owner(), ref, income);
            
            sumDistributed += income;
            emit ReferralIncomeDistributed(_user, int256(i+1), income, ref);
            
            ref = UserReferrer[ref];
        }
        
        return sumDistributed;
    }
    
    function getUserInfo(uint _phaseNo, address _user) public view returns (UserInfo memory user) {
        return UserInfos[_user][_phaseNo];
    }
    
    function getTotalMintandSupply() public view returns (uint256) {
        return TotalMintandSupply;
    }

    event TokenStaked(address Sender, uint phaseNo, uint256 amountTokens);
    event withdrawed(address Sender, uint phaseNo, uint256 amountTokens, uint256 reward);
    event ReferralIncomeDistributed(address sender, int256 level, uint256 income, address ref);
    event Distributed(uint256 RewardperShare, uint256 TotalShare);
    event TokenBought(address Sender, uint phaseNo, uint256 amountTokens, address Referrer);
}