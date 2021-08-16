/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address _tokenOwner) {
        _owner = _tokenOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Elgrand is Context, IBEP20, Ownable {
    address public liquidityBank;
    uint256  public dividendPerToken;
    uint256 private DENOMINATOR = 10_000;
    uint256 private LIQUIDITY_PERCENT = 1500;
    uint256 private ALL_HOLDER_PERCENT = 0;
    uint256 private BURN_PERCENT = 0;

    mapping(address => uint256) private _dividendCreditedTo;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    event SetLiquidityBank(address indexed previousAddress, address indexed newAddress);

    constructor () Ownable(0xCA23c3396A56d5F2bF6f566440e777049Dd8E2f8) {
        require(0xCA23c3396A56d5F2bF6f566440e777049Dd8E2f8 != address(0), "BEP20: transfer from the zero address");
        require(0xCA23c3396A56d5F2bF6f566440e777049Dd8E2f8 != address(0), "BEP20: transfer from the zero address");
        liquidityBank = 0xCA23c3396A56d5F2bF6f566440e777049Dd8E2f8;
        _totalSupply = 10000000 * 10 ** uint256(decimals());
        _name = "Elgrand";
        _symbol = "ELG";
        _balances[0xCA23c3396A56d5F2bF6f566440e777049Dd8E2f8] = _totalSupply;
        emit Transfer(address(0) , 0xCA23c3396A56d5F2bF6f566440e777049Dd8E2f8, _totalSupply);
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 3;
    }

    function getOwner() external virtual override view returns (address) {
        return owner();
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        require(_allowances[sender][_msgSender()] >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(_allowances[_msgSender()][spender] >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);

        return true;
    }

    function burn(uint256 amount) external onlyOwner returns (bool) {
        _burn(owner(), amount);
        return true;
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "BEP20: burn from the zero address");
        require(_balances[account] >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    function mint(uint256 amount) external onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        require(_balances[sender] >= amount && amount > 0, "BEP20: transfer amount exceeds balance");

        uint256 _liguidityAmount = amount * LIQUIDITY_PERCENT / DENOMINATOR;
        _balances[liquidityBank] += _liguidityAmount;
        emit Transfer(sender, liquidityBank, _liguidityAmount);

        uint256 _allHoldersAmount = amount * ALL_HOLDER_PERCENT / DENOMINATOR;
        _balances[address(this)] += _allHoldersAmount;
        emit Transfer(sender, address(this), _allHoldersAmount);

        uint256 _burnAmount = amount * BURN_PERCENT / DENOMINATOR;
        _burn(sender, _burnAmount);

        _balances[sender] -= amount - _burnAmount;

        uint256 _recipientAmount = amount - (_liguidityAmount + _allHoldersAmount + _burnAmount);
        _balances[recipient] += _recipientAmount;
        emit Transfer(sender, recipient, _recipientAmount);

        dividendPerToken += _allHoldersAmount;
        getReward(recipient);
        getReward(sender);
    }

    function getReward(address account) public {
        uint256 _dividend = viewReward(account);
        if (_dividend > 0) {
            _balances[account] += _dividend;
            _balances[address(this)] -= _dividend;
            emit Transfer(address(this), account, _dividend);
        }
        _dividendCreditedTo[account] = dividendPerToken;
    }

    function viewReward(address account) public view returns (uint256) {
        uint256 _dividendPerToken = dividendPerToken;
        if (_dividendPerToken > _dividendCreditedTo[account]) {
            uint256 _owed = _dividendPerToken - _dividendCreditedTo[account];
            return _balances[account] * _owed / _totalSupply;
        }
        return 0;
    }

    function checkRewardSender(address account) private {
        if (_dividendCreditedTo[account] == 0) {
            _dividendCreditedTo[account] = dividendPerToken;
        }
    }

    function viewDividendPerToken() public view returns (uint256) {
        return dividendPerToken;
    }

    function dividendCreditedTo(address account) external view returns (uint256) {
        return _dividendCreditedTo[account];
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function claimToken(IBEP20 token, address to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        bool sent = token.transfer(to, balance);
        require(sent, "Failed to send token");
    }

    function claimBNB(address payable to) external onlyOwner {
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "Failed to send BNB");
    }

    function setLiquidityBank(address newLiquidityBank) external onlyOwner {
        require(newLiquidityBank != address(0), "BEP20: set from the zero address");
        emit SetLiquidityBank(liquidityBank, newLiquidityBank);
        liquidityBank = newLiquidityBank;
    }
}