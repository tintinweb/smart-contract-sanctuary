pragma solidity ^0.5.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

contract AOENetwork is IERC20 {
    uint256 private constant FLOAT_SCALAR = 2**64;
    uint256 private constant INITIAL_SUPPLY = 1e27; // 1B
    uint256 private constant BURN_RATE = 5; // 5% per tx
    uint256 private constant SUPPLY_FLOOR = 10; // 10% of 1B = 100M
    uint256 private constant MIN_FREEZE_AMOUNT = 1e20; // 100

    string public constant name = "AOE Network";
    string public constant symbol = "AOE";
    uint8 public constant decimals = 18;

    struct User {
        bool whitelisted;
        uint256 balance;
        uint256 frozen;
        mapping(address => uint256) allowance;
        int256 scaledPayout;
    }

    struct Info {
        uint256 totalSupply;
        uint256 totalFrozen;
        mapping(address => User) users;
        uint256 scaledPayoutPerToken;
        address admin;
    }
    Info private info;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 tokens
    );
    event Whitelist(address indexed user, bool status);
    event Freeze(address indexed owner, uint256 tokens);
    event Unfreeze(address indexed owner, uint256 tokens);
    event Collect(address indexed owner, uint256 tokens);
    event Burn(uint256 tokens);

    constructor() public {
        info.admin = msg.sender;
        info.totalSupply = INITIAL_SUPPLY;
        info.users[msg.sender].balance = INITIAL_SUPPLY;
        emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
        whitelist(msg.sender, true);
    }

    function freeze(uint256 _tokens) external {
        _freeze(_tokens);
    }

    function unfreeze(uint256 _tokens) external {
        _unfreeze(_tokens);
    }

    function collect() external returns (uint256) {
        uint256 _dividends = dividendsOf(msg.sender);
        require(_dividends >= 0);
        info.users[msg.sender].scaledPayout += int256(
            _dividends * FLOAT_SCALAR
        );
        info.users[msg.sender].balance += _dividends;
        emit Transfer(address(this), msg.sender, _dividends);
        emit Collect(msg.sender, _dividends);
        return _dividends;
    }

    function burn(uint256 _tokens) external {
        require(balanceOf(msg.sender) >= _tokens);
        info.users[msg.sender].balance -= _tokens;
        uint256 _burnedAmount = _tokens;
        if (info.totalFrozen > 0) {
            _burnedAmount /= 2;
            info.scaledPayoutPerToken +=
                (_burnedAmount * FLOAT_SCALAR) /
                info.totalFrozen;
            emit Transfer(msg.sender, address(this), _burnedAmount);
        }
        info.totalSupply -= _burnedAmount;
        emit Transfer(msg.sender, address(0x0), _burnedAmount);
        emit Burn(_burnedAmount);
    }

    function distribute(uint256 _tokens) external {
        require(info.totalFrozen > 0);
        require(balanceOf(msg.sender) >= _tokens);
        info.users[msg.sender].balance -= _tokens;
        info.scaledPayoutPerToken +=
            (_tokens * FLOAT_SCALAR) /
            info.totalFrozen;
        emit Transfer(msg.sender, address(this), _tokens);
    }

    function transfer(address _to, uint256 _tokens) external returns (bool) {
        _transfer(msg.sender, _to, _tokens);
        return true;
    }

    function approve(address _spender, uint256 _tokens)
        external
        returns (bool)
    {
        info.users[msg.sender].allowance[_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokens
    ) external returns (bool) {
        require(info.users[_from].allowance[msg.sender] >= _tokens);
        info.users[_from].allowance[msg.sender] -= _tokens;
        _transfer(_from, _to, _tokens);
        return true;
    }

    function whitelist(address _user, bool _status) public {
        require(msg.sender == info.admin);
        info.users[_user].whitelisted = _status;
        emit Whitelist(_user, _status);
    }

    function totalSupply() public view returns (uint256) {
        return info.totalSupply;
    }

    function totalFrozen() public view returns (uint256) {
        return info.totalFrozen;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return info.users[_user].balance - frozenOf(_user);
    }

    function frozenOf(address _user) public view returns (uint256) {
        return info.users[_user].frozen;
    }

    function dividendsOf(address _user) public view returns (uint256) {
        return
            uint256(
                int256(info.scaledPayoutPerToken * info.users[_user].frozen) -
                    info.users[_user].scaledPayout
            ) / FLOAT_SCALAR;
    }

    function allowance(address _user, address _spender)
        public
        view
        returns (uint256)
    {
        return info.users[_user].allowance[_spender];
    }

    function isWhitelisted(address _user) public view returns (bool) {
        return info.users[_user].whitelisted;
    }

    function allInfoFor(address _user)
        public
        view
        returns (
            uint256 totalTokenSupply,
            uint256 totalTokensFrozen,
            uint256 userBalance,
            uint256 userFrozen,
            uint256 userDividends
        )
    {
        return (
            totalSupply(),
            totalFrozen(),
            balanceOf(_user),
            frozenOf(_user),
            dividendsOf(_user)
        );
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokens
    ) internal returns (uint256) {
        require(balanceOf(_from) >= _tokens);
        info.users[_from].balance -= _tokens;
        uint256 _burnedAmount = (_tokens * BURN_RATE) / 100;
        if (
            totalSupply() - _burnedAmount <
            (INITIAL_SUPPLY * SUPPLY_FLOOR) / 100 ||
            isWhitelisted(_from)
        ) {
            _burnedAmount = 0;
        }
        uint256 _transferred = _tokens - _burnedAmount;
        info.users[_to].balance += _transferred;
        emit Transfer(_from, _to, _transferred);
        if (_burnedAmount > 0) {
            if (info.totalFrozen > 0) {
                _burnedAmount /= 2;
                info.scaledPayoutPerToken +=
                    (_burnedAmount * FLOAT_SCALAR) /
                    info.totalFrozen;
                emit Transfer(_from, address(this), _burnedAmount);
            }
            info.totalSupply -= _burnedAmount;
            emit Transfer(_from, address(0x0), _burnedAmount);
            emit Burn(_burnedAmount);
        }
        return _transferred;
    }

    function _freeze(uint256 _amount) internal {
        require(balanceOf(msg.sender) >= _amount);
        require(frozenOf(msg.sender) + _amount >= MIN_FREEZE_AMOUNT);
        info.totalFrozen += _amount;
        info.users[msg.sender].frozen += _amount;
        info.users[msg.sender].scaledPayout += int256(
            _amount * info.scaledPayoutPerToken
        );
        emit Transfer(msg.sender, address(this), _amount);
        emit Freeze(msg.sender, _amount);
    }

    function _unfreeze(uint256 _amount) internal {
        require(frozenOf(msg.sender) >= _amount);
        uint256 _burnedAmount = (_amount * BURN_RATE) / 100;
        info.scaledPayoutPerToken +=
            (_burnedAmount * FLOAT_SCALAR) /
            info.totalFrozen;
        info.totalFrozen -= _amount;
        info.users[msg.sender].balance -= _burnedAmount;
        info.users[msg.sender].frozen -= _amount;
        info.users[msg.sender].scaledPayout -= int256(
            _amount * info.scaledPayoutPerToken
        );
        emit Transfer(address(this), msg.sender, _amount - _burnedAmount);
        emit Unfreeze(msg.sender, _amount);
    }
}