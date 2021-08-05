/**
 *Submitted for verification at Etherscan.io on 2020-12-19
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


interface IUniswapSync {
    function sync() external;
}

/**
 * @title UNBASE ERC20 token
 *      UNBASE is a normal ERC20 token, but its supply can be adjusted by splitting 
 *      tokens proportionally across all wallets (forked Base Protocol's logic), and 
 *      it reflects a transaction fee directly into all holder's wallet seemlessly 
 *      without any transfer (forked Reflect's logic).
 *
 *      UNBASE balances are internally represented with a hidden denomination, 'shares'.
 *      The circulating supply of 'shares' decrease over time due to the transaction fee.
 *      The UNBASE balance is then reflected from the share balance (using a conversion rate
 *      between 'shares' and 'UNBASE' taking into account the circulating supply). Exchanges' 
 *      wallets such as the Uniswap Pool are excluded from the circulating supply, therefore 
 *      only holders are earning from the transaction fee. 
 * 
 *      We also support splitting the currency in expansion by modifying the UNBASE total supply
 *      as well as the excluded wallets' balances, allowing the supply to contract and the price 
 *      to go up at each rebase event.
 */
contract UnbaseToken is ERC20, Ownable {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of shares that equals 1 UNBASE.
    //    The inverse rate must not be used--totalShares is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert shares to UNBASE instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Share balances converted into UnbaseToken are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x UnbaseToken to address 'B'. A's resulting external balance will
    //   be decreased by precisely x UnbaseToken, and B's external balance will be precisely
    //   increased by x UnbaseToken.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).
    using SafeMath for uint256;

    event LogRebase(uint256 indexed _epoch, uint256 totalSupply);
    event LogUserBanStatusUpdated(address user, bool banned);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_SUPPLY = 1 * 10**6 * 10**DECIMALS;
    uint256 private constant INITIAL_SHARES = (MAX_UINT256) - (MAX_UINT256 % INITIAL_SUPPLY);

    uint256 private _totalShares;
    uint256 private _totalSupply;
    address public _unbaseUniswapLPContract;

    uint256 private _epoch; 
    uint256 public _unbasePercent = 15;         // 15 = 15%. At each rebase event, _totalSupply is reduced by unbasePercent. Value can be modified by Owner.
    uint256 public _transferFee = 0;            // 3 = 3%. For each transfer, the tax (_transferFee * amount) is reflected seamlessly in all holders' balances. Value can be modified by Owner.
    uint256 private _unbaseFeeTotal;            
    
    mapping(address => uint256) private _shareBalances;
    mapping (address => uint256) private _unbaseBalances;    
    mapping(address => bool) public bannedUsers;
    mapping (address => mapping (address => uint256)) private _allowedUNBASE;       // This is denominated in UnbaseToken, because the shares-UNBASE conversion might change before it's fully paid.

    uint256 public antiBotTimer;
    bool public transfersPaused;
    bool public rebasesPaused;

    mapping(address => bool) public transferPauseExemptList;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;


    constructor() public ERC20("Unbase Protocol", "UNB") { 
        _totalShares = INITIAL_SHARES;
        _totalSupply = INITIAL_SUPPLY;
        _shareBalances[owner()] = _totalShares;

        // Ban the Kucoin hacker
        bannedUsers[0xeB31973E0FeBF3e3D7058234a5eBbAe1aB4B8c23] = true;

        emit Transfer(address(0x0), owner(), _totalSupply);
  }
  

        
    // After that limit are the functions from Base Protocol's contract,
    // modified to allow a seemless rebase of the supply once a day.
    // The transfer() and transferFrom() functions are not included as 
    // they derive mostly from Reflect's logic.

    function setAntiBotTimer()
        public
        onlyOwner
    {
        antiBotTimer = now;
    }

    function setTransfersPaused(bool _transfersPaused)
        public
        onlyOwner
    {
        transfersPaused = _transfersPaused;
    }

    function setTransferPauseExempt(address user, bool exempt)
        public
        onlyOwner
    {
        if (exempt) {
            transferPauseExemptList[user] = true;
        } else {
            delete transferPauseExemptList[user];
        }
    }

    function setRebasesPaused(bool _rebasesPaused)
        public
        onlyOwner
    {
        rebasesPaused = _rebasesPaused;
    }

    function setUnbasePercent(uint256 _newUnbasePercent)
        public
        onlyOwner
    {
        _unbasePercent = _newUnbasePercent;
    }
    
    function setTransferFee(uint256 _newTransferFee)
        public
        onlyOwner
    {
        _transferFee = _newTransferFee;
    }
    
    function setUnbaseUniswapLPContract(address _newUnbaseUniswapLPContract)
        public
        onlyOwner
    {
        _unbaseUniswapLPContract = _newUnbaseUniswapLPContract;
    }
    
    function rebase()
        public
        onlyOwner
        returns (uint256)
    {
        require(!rebasesPaused, "rebases paused");
        
        _totalSupply = _totalSupply.sub(_totalSupply.mul(_unbasePercent).div(100));
        _unbaseFeeTotal = _unbaseFeeTotal.sub(_unbaseFeeTotal.mul(_unbasePercent).div(100));
        // We also modify the UNBASE supply held in excluded accounts to correctly reflect the circulating supply after the rebase event //
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_unbaseBalances[_excluded[i]] > 0) {
                _unbaseBalances[_excluded[i]] = _unbaseBalances[_excluded[i]].sub(_unbaseBalances[_excluded[i]].mul(_unbasePercent).div(100));
            }
        }
        _epoch = _epoch.add(1);

        emit LogRebase(_epoch, _totalSupply);
        IUniswapSync(_unbaseUniswapLPContract).sync();
        return _totalSupply;
    }

    function getTotalShares()
        public
        view
        returns (uint256)
    {
        return _totalShares;
    }

    function sharesOf(address user)
        public
        view
        returns (uint256)
    {
        return _shareBalances[user];
    }

    function setUserBanStatus(address user, bool banned)
        public
        onlyOwner
    {
        if (banned) {
            bannedUsers[user] = true;
        } else {
            delete bannedUsers[user];
        }
        emit LogUserBanStatusUpdated(user, banned);
    }

    function totalSupply()
        public
        override
        view
        returns (uint256)
    {
        return _totalSupply;
    }
    
    function transfer(address recipient, uint256 amount) 
        public 
        override(ERC20) 
        validRecipient(recipient)
        returns (bool) 
    {
        require(bannedUsers[msg.sender] == false, "you are banned");
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");
        require(now.sub(antiBotTimer) >= 300 || amount <= 2000 * 10**DECIMALS, "Max buy 2000 UNB right after launch");
        
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner_, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowedUNBASE[owner_][spender];
    }

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        _allowedUNBASE[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) 
        public 
        override 
        validRecipient(recipient)
        returns (bool) 
    {
        require(bannedUsers[msg.sender] == false, "you are banned");
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");
        
        _transfer(sender, recipient, amount);
        approve(sender, _allowedUNBASE[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        _allowedUNBASE[msg.sender][spender] = _allowedUNBASE[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedUNBASE[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        uint256 oldValue = _allowedUNBASE[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedUNBASE[msg.sender][spender] = 0;
        } else {
            _allowedUNBASE[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedUNBASE[msg.sender][spender]);
        return true;
    }
    
        
    // After that limit are the functions implementing Reflect's logic to
    // distribute transaction fees to all holders seemlessly.
    // It includes the _transfer() and transferFrom() functions implementing 
    // both Base Protocol and Reflect's logic. 
    
    
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _unbaseBalances[account];
        return tokenFromReflection(_shareBalances[account]);
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _unbaseFeeTotal;
    }

    function reflect(uint256 unbaseAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 shareAmount,,,,) = _getValues(unbaseAmount);
        _shareBalances[sender] = _shareBalances[sender].sub(shareAmount);
        _totalShares = _totalShares.sub(shareAmount);
        _unbaseFeeTotal = _unbaseFeeTotal.add(unbaseAmount);
    }

    function reflectionFromToken(uint256 unbaseAmount, bool deductTransferFee) public view returns(uint256) {
        require(unbaseAmount <= _totalSupply, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 shareAmount,,,,) = _getValues(unbaseAmount);
            return shareAmount;
        } else {
            (,uint256 shareTransferAmount,,,) = _getValues(unbaseAmount);
            return shareTransferAmount;
        }
    }

    function tokenFromReflection(uint256 shareAmount) public view returns(uint256) {
        require(shareAmount <= _totalShares, "Amount must be less than _totalShares");
        uint256 currentRate = _getRateForReflection();
        return shareAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_shareBalances[account] > 0) {
            _unbaseBalances[account] = tokenFromReflection(_shareBalances[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _unbaseBalances[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 unbaseAmount) private {
        (uint256 shareAmount, uint256 shareTransferAmount, uint256 shareFee, uint256 unbaseTransferAmount, uint256 unbaseFee) = _getValues(unbaseAmount);
        _shareBalances[sender] = _shareBalances[sender].sub(shareAmount);
        _shareBalances[recipient] = _shareBalances[recipient].add(shareTransferAmount);       
        _reflectFee(shareFee, unbaseFee);
        emit Transfer(sender, recipient, unbaseTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 unbaseAmount) private {
        (uint256 shareAmount, uint256 shareTransferAmount, uint256 shareFee, uint256 unbaseTransferAmount, uint256 unbaseFee) = _getValues(unbaseAmount);
        _shareBalances[sender] = _shareBalances[sender].sub(shareAmount);
        _unbaseBalances[recipient] = _unbaseBalances[recipient].add(unbaseTransferAmount);
        _shareBalances[recipient] = _shareBalances[recipient].add(shareTransferAmount);           
        _reflectFee(shareFee, unbaseFee);
        emit Transfer(sender, recipient, unbaseTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 unbaseAmount) private {
        (uint256 shareAmount, uint256 shareTransferAmount, uint256 shareFee, uint256 unbaseTransferAmount, uint256 unbaseFee) = _getValues(unbaseAmount);
        _unbaseBalances[sender] = _unbaseBalances[sender].sub(unbaseAmount);
        _shareBalances[sender] = _shareBalances[sender].sub(shareAmount);
        _shareBalances[recipient] = _shareBalances[recipient].add(shareTransferAmount);   
        _reflectFee(shareFee, unbaseFee);
        emit Transfer(sender, recipient, unbaseTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 unbaseAmount) private {
        (uint256 shareAmount, uint256 shareTransferAmount, uint256 shareFee, uint256 unbaseTransferAmount, uint256 unbaseFee) = _getValues(unbaseAmount);
        _unbaseBalances[sender] = _unbaseBalances[sender].sub(unbaseAmount);
        _shareBalances[sender] = _shareBalances[sender].sub(shareAmount);
        _unbaseBalances[recipient] = _unbaseBalances[recipient].add(unbaseTransferAmount);
        _shareBalances[recipient] = _shareBalances[recipient].add(shareTransferAmount);        
        _reflectFee(shareFee, unbaseFee);
        emit Transfer(sender, recipient, unbaseTransferAmount);
    }

    function _reflectFee(uint256 shareFee, uint256 unbaseFee) private {
        _totalShares = _totalShares.sub(shareFee);
        _unbaseFeeTotal = _unbaseFeeTotal.add(unbaseFee);
    }

    function _getValues(uint256 unbaseAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 unbaseTransferAmount, uint256 unbaseFee) = _getTValues(unbaseAmount);
        uint256 currentRate =  _getRateForReflection();
        (uint256 shareAmount, uint256 shareTransferAmount, uint256 shareFee) = _getRValues(unbaseAmount, unbaseFee, currentRate);
        return (shareAmount, shareTransferAmount, shareFee, unbaseTransferAmount, unbaseFee);
    }

    function _getTValues(uint256 unbaseAmount) private view returns (uint256, uint256) {
        uint256 unbaseFee = unbaseAmount.div(100).mul(_transferFee);
        uint256 unbaseTransferAmount = unbaseAmount.sub(unbaseFee);
        return (unbaseTransferAmount, unbaseFee);
    }

    function _getRValues(uint256 unbaseAmount, uint256 unbaseFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 shareAmount = unbaseAmount.mul(currentRate);
        uint256 shareFee = unbaseFee.mul(currentRate);
        uint256 shareTransferAmount = shareAmount.sub(shareFee);
        return (shareAmount, shareTransferAmount, shareFee);
    }

    function _getRateForReflection() private view returns(uint256) {
        (uint256 shareSupply, uint256 unbaseSupply) = _getCurrentSupplyForReflection();
        return shareSupply.div(unbaseSupply);
    }

    function _getCurrentSupplyForReflection() private view returns(uint256, uint256) {
        uint256 shareSupply = _totalShares;
        uint256 unbaseSupply = _totalSupply;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_shareBalances[_excluded[i]] > shareSupply || _unbaseBalances[_excluded[i]] > unbaseSupply) return (_totalShares, _totalSupply);
            shareSupply = shareSupply.sub(_shareBalances[_excluded[i]]);
            unbaseSupply = unbaseSupply.sub(_unbaseBalances[_excluded[i]]);
        }
        if (shareSupply < _totalShares.div(_totalSupply)) return (_totalShares, _totalSupply);
        return (shareSupply, unbaseSupply);
    }
}