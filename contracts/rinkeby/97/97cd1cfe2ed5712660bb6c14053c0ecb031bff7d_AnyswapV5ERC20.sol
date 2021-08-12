/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.6;


/// @dev Interface of the ERC20 standard as defined in the EIP.
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @dev library of SafeERC20
library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FAILED');
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FROM_FAILED');
    }
}

contract AnyswapV5ERC20 is IERC20 {
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8  public override decimals;

    address public underlying;

    /// @dev Records amount of AnyswapV5ERC20 token owned by account.
    mapping (address => uint256) public override balanceOf;
    uint256 private _totalSupply;
    
    /// @dev Records number of AnyswapV5ERC20 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping (address => mapping (address => uint256)) public override allowance;

    // init flag for setting immediate vault, needed for CREATE2 support
    bool public initialized;

    // flag to enable/disable swapout vs vault.burn so multiple events are triggered
    bool public vaultOnly;

    // configurable delay for timelock functions
    uint public constant delay = 2*24*3600;

    // set of minters, can be this bridge or other bridges
    mapping(address => bool) public isMinter;
    address[] public minters;

    // primary controller of the token contract
    address public vault;

    address public pendingMinter;
    uint public delayMinter;

    address public pendingVault;
    uint public delayVault;

    modifier onlyAuth() {
        require(isMinter[msg.sender], "AnyswapV5ERC20: FORBIDDEN");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "AnyswapV5ERC20: FORBIDDEN");
        _;
    }

    function owner() external view returns (address) {
        return vault;
    }

    function mpc() external view returns (address) {
        return vault;
    }

    function setVaultOnly(bool enabled) external onlyVault {
        vaultOnly = enabled;
    }

    function setVault(address _vault) external onlyVault {
        pendingVault = _vault;
        delayVault = block.timestamp + delay;
    }

    function applyVault() external {
        require(msg.sender == pendingVault);
        require(block.timestamp >= delayVault);
        emit LogChangeVault(vault, pendingVault, block.timestamp);
        vault = pendingVault;
        pendingVault = address(0);
    }

    function setMinter(address _auth) external onlyVault {
        pendingMinter = _auth;
        delayMinter = block.timestamp + delay;
    }

    function applyMinter() external {
        require(msg.sender == pendingMinter);
        require(block.timestamp >= delayMinter);
        emit LogAddAuth(pendingMinter, block.timestamp);
        isMinter[pendingMinter] = true;
        minters.push(pendingMinter);
        pendingMinter = address(0);
    }

    // No time delay revoke minter emergency function
    function revokeMinter(address _auth) external onlyVault {
        isMinter[_auth] = false;
        emit LogRevokeAuth(_auth, block.timestamp);
    }

    function getAllMintersLength() external view returns (uint) {
        return minters.length;
    }

    function getAllMinters() external view returns (address[] memory) {
        return minters;
    }

    function mint(address to, uint256 amount) external onlyAuth returns (bool) {
        require(to != address(0), "AnyswapV5ERC20: address(0x0)");
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external onlyAuth returns (bool) {
        require(from != address(0), "AnyswapV5ERC20: address(0x0)");
        _burn(from, amount);
        return true;
    }

    function Swapin(bytes32 txhash, address account, uint256 amount) public onlyAuth returns (bool) {
        require(!vaultOnly, "AnyswapV5ERC20: vaultOnly");
        _mint(account, amount);
        emit LogSwapin(txhash, account, amount);
        return true;
    }

    function Swapout(uint256 amount, address bindaddr) public returns (bool) {
        require(!vaultOnly, "AnyswapV5ERC20: vaultOnly");
        require(bindaddr != address(0), "AnyswapV5ERC20: address(0x0)");
        _burn(msg.sender, amount);
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }

    event LogChangeVault(address indexed oldVault, address indexed newVault, uint indexed effectiveTime);
    event LogSwapin(bytes32 indexed txhash, address indexed account, uint amount);
    event LogSwapout(address indexed account, address indexed bindaddr, uint amount);
    event LogAddAuth(address indexed auth, uint timestamp);
    event LogRevokeAuth(address indexed auth, uint timestamp);

    function init(string memory _name, string memory _symbol, uint8 _decimals, address _underlying) external {
        require(!initialized, "AnyswapV5ERC20: already initialized");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        underlying = _underlying;
        if (_underlying != address(0x0)) {
            require(_decimals == IERC20(_underlying).decimals());
        }

        // Use init to allow for CREATE2 accross all chains
        initialized = true;
    }

    function initVault(address _vault, bool _isV1) external {
        // Disable/Enable swapout for v1 tokens vs mint/burn for v3 tokens
        vaultOnly = !_isV1;

        vault = _vault;
        isMinter[_vault] = true;
        minters.push(_vault);
    }

    /// @dev Returns the total supply of AnyswapV5ERC20 token as the ETH held in this contract.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function deposit(uint amount) external returns (uint) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, msg.sender);
    }

    function deposit(uint amount, address to) external returns (uint) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, to);
    }

    function depositVault(uint amount, address to) external onlyVault returns (uint) {
        return _deposit(amount, to);
    }

    function _deposit(uint amount, address to) internal returns (uint) {
        require(underlying != address(0x0) && underlying != address(this));
        _mint(to, amount);
        return amount;
    }

    function withdraw(uint amount) external returns (uint) {
        return _withdraw(msg.sender, amount, msg.sender);
    }

    function withdraw(uint amount, address to) external returns (uint) {
        return _withdraw(msg.sender, amount, to);
    }

    function withdrawVault(address from, uint amount, address to) external onlyVault returns (uint) {
        return _withdraw(from, amount, to);
    }

    function _withdraw(address from, uint amount, address to) internal returns (uint) {
        require(underlying != address(0x0) && underlying != address(this));
        _burn(from, amount);
        IERC20(underlying).safeTransfer(to, amount);
        return amount;
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
        require(account != address(0), "AnyswapV5ERC20: mint to the zero address");

        uint256 newTotalSupply = _totalSupply + amount;
        require(newTotalSupply >= _totalSupply, "AnyswapV5ERC20: total supply overflow");

        _totalSupply = newTotalSupply;
        balanceOf[account] += amount;
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
        require(account != address(0), "AnyswapV5ERC20: burn from the zero address");
    
        uint256 balance = balanceOf[account];
        require(balance >= amount, "AnyswapV5ERC20: burn amount exceeds balance");

        balanceOf[account] = balance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's AnyswapV5ERC20 token.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    function approve(address spender, uint256 value) external override returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    /// @dev Moves `value` AnyswapV5ERC20 token from caller's account to account (`to`).
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent AnyswapV5ERC20 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` AnyswapV5ERC20 token.
    function transfer(address to, uint256 value) external override returns (bool) {
        require(to != address(0) || to != address(this));
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "AnyswapV5ERC20: transfer amount exceeds balance");

        balanceOf[msg.sender] = balance - value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        return true;
    }

    /// @dev Moves `value` AnyswapV5ERC20 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent AnyswapV5ERC20 token in favor of caller.
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - `from` account must have at least `value` balance of AnyswapV5ERC20 token.
    ///   - `from` account must have approved caller to spend at least `value` of AnyswapV5ERC20 token, unless `from` and caller are the same account.
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(to != address(0) || to != address(this));
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "AnyswapV5ERC20: request exceeds allowance");
                uint256 reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit Approval(from, msg.sender, reduced);
            }
        }

        uint256 balance = balanceOf[from];
        require(balance >= value, "AnyswapV5ERC20: transfer amount exceeds balance");

        balanceOf[from] = balance - value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);

        return true;
    }
}