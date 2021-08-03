/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Implementation of Vegion Token.
 * @author Vegion Team
 */
contract VegionToken is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _freezes;
    mapping(address => bool) private _addressExists;
    mapping(uint256 => address) private _addresses;
    uint256 private _addressCount = 0;
    address private _addressDev;
    address private _addressAd;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _totalBurn;
    uint256 private _burnStop;

    string private _name = "VegionToken";
    string private _symbol = "VT";

    mapping(address => bool) private _addressNoAirdrop;
    mapping(address => uint256) private _addressAirdrop;
    uint256 private _totalAirdrop = 0;
    uint256 private _totalVt = 0;

    uint256 private _adBatchEnd = 0;
    uint256 private _adBatchLast = 0;
    uint256 private _adBatchTotal = 0;
    uint256 private _adBatchVtTotal = 0;

    mapping(address => bool) private _admins;

    /**
     * @dev constructor
     */
    constructor(address addressDev, address addressAd) {
        require(addressDev != address(0), "constructor: dev address error");
        require(addressAd != address(0), "constructor: airdrop address error");
        require(
            addressDev != addressAd,
            "constructor: dev and airdrop not same"
        );
        _totalSupply = 100_000_000 * 10**decimals();
        _totalBurn = 0;
        _burnStop = 2_100_000 * 10**decimals();
        // owner
        _addressExists[_msgSender()] = true;
        _addresses[_addressCount++] = _msgSender();
        // dev
        if (!_addressExists[addressDev]) {
            _addressExists[addressDev] = true;
            _addresses[_addressCount++] = addressDev;
        }
        _addressDev = addressDev;
        // airdrop
        if (!_addressExists[addressAd]) {
            _addressExists[addressAd] = true;
            _addresses[_addressCount++] = addressAd;
        }
        _addressAd = addressAd;

        _admins[_msgSender()] = true;
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
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev totalBurn.
     */
    function totalBurn() public view virtual returns (uint256) {
        return _totalBurn;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transferBurn(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "transferFrom: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "decreaseAllowance: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev burn
     */
    function burn(uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev get address count
     */
    function addressCount() public view onlyAdmin returns (uint256) {
        return _addressCount;
    }

    /**
     * @dev check if address exist
     */
    function isAddressExist(address target)
        public
        view
        onlyAdmin
        returns (bool)
    {
        return _addressExists[target];
    }

    /**
     * @dev total airdrop vt
     */
    function totalAirdrop() public view onlyAdmin returns (uint256) {
        return _totalAirdrop;
    }

    /**
     * @dev total address vt
     */
    function totalVt() public view onlyAdmin returns (uint256) {
        return _totalVt;
    }

    /**
     * airdrop
     */
    function airdrop(address recipient, uint256 amount)
        public
        onlyAdmin
        returns (bool)
    {
        require(
            recipient != address(0),
            "airdrop: airdrop to the zero address"
        );

        // if recipient not exist
        if (!_addressExists[recipient]) {
            _addressExists[recipient] = true;
            _addresses[_addressCount++] = recipient;
        }
        _balances[recipient] += amount;
        _totalVt += amount;
        emit Transfer(address(0), recipient, amount);

        return true;
    }

    /**
     * airdrops
     */
    function airdrops(address[] memory recipients, uint256[] memory amounts)
        public
        onlyAdmin
        returns (bool)
    {
        require(
            recipients.length == amounts.length,
            "airdrops: length not equal"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] != address(0)) {
                airdrop(recipients[i], amounts[i]);
            }
        }
        return true;
    }

    /**
     * airdropAll
     */
    function airdropAll() public onlyAdmin returns (bool) {
        _airdrop(0, _addressCount, _totalAirdrop, _totalVt);
        _totalAirdrop = 0;
        return true;
    }

    /**
     * airdrop batch
     */
    function airdropBatch(uint256 count) public onlyAdmin returns (bool) {
        if (_adBatchTotal <= 0) {
            require(
                _totalAirdrop > 0,
                "airdropBatch: airdrop total should bigger than zero"
            );
            _adBatchTotal = _totalAirdrop;
            _adBatchVtTotal = _totalVt;
            _adBatchEnd = _addressCount;
            _adBatchLast = 0;

            _totalAirdrop = 0;
        }

        uint256 end = _adBatchLast + count >= _adBatchEnd
            ? _adBatchEnd
            : _adBatchLast + count;

        _airdrop(_adBatchLast, end, _adBatchTotal, _adBatchVtTotal);

        if (end >= _adBatchEnd) {
            _adBatchTotal = 0;
            _adBatchVtTotal = 0;
            _adBatchEnd = 0;
            _adBatchLast = 0;
        } else {
            _adBatchLast = end;
        }

        return true;
    }

    /**
     * address can get airdrop or not
     */
    function isAddressNoAirdrop(address target)
        public
        view
        onlyAdmin
        returns (bool)
    {
        return _addressNoAirdrop[target];
    }

    /**
     * address airdrop
     */
    function addressAirdrop() public view returns (uint256) {
        return _addressAirdrop[_msgSender()];
    }

    /**
     * receive airdrop
     */
    function receiveAirdrop() public returns (bool) {
        require(
            _addressAirdrop[_msgSender()] > 0,
            "receiveAirdrop: no wait receive airdrop vt"
        );
        uint256 waitReceive = _addressAirdrop[_msgSender()];
        require(
            _balances[_addressAd] >= waitReceive,
            "receiveAirdrop: not enough airdrop vt"
        );
        _balances[_msgSender()] += waitReceive;
        _addressAirdrop[_msgSender()] = 0;
        _balances[_addressAd] -= waitReceive;
        _totalVt += waitReceive;
        emit Transfer(_addressAd, _msgSender(), waitReceive);

        return true;
    }

    /**
     * setNoAirdrop for target address
     */
    function setNoAirdrop(address target, bool noAirdrop)
        public
        onlyAdmin
        returns (bool)
    {
        require(
            _addressNoAirdrop[target] != noAirdrop,
            "setNoAirdrop: same setting."
        );
        _addressNoAirdrop[target] = noAirdrop;
        return true;
    }

    /**
     * freeze
     */
    function freeze(address target, uint256 amount)
        public
        onlyAdmin
        returns (bool)
    {
        require(_balances[target] >= amount, "freeze: freeze amount error");

        _balances[target] -= amount;
        _freezes[target] += amount;
        _totalVt -= amount;
        emit Freeze(target, amount);
        return true;
    }

    /**
     * unfreeze
     */
    function unfreeze(address target, uint256 amount)
        public
        onlyAdmin
        returns (bool)
    {
        require(_freezes[target] >= amount, "unfreeze: unfreeze amount error");

        _balances[target] += amount;
        _freezes[target] -= amount;
        _totalVt += amount;
        emit Unfreeze(target, amount);
        return true;
    }

    /**
     * @dev See {IERC20-freezeOf}.
     */
    function freezeOf(address account) public view returns (uint256) {
        return _freezes[account];
    }

    /**
     * @dev get dev
     */
    function getAddressDev() public view onlyAdmin returns (address) {
        return _addressDev;
    }

    /**
     * @dev set new dev
     */
    function transferDev(address newDev) public onlyAdmin returns (bool) {
        require(newDev != address(0), "transferDev: new address zero");
        if (!_addressExists[newDev]) {
            _addressExists[newDev] = true;
            _addresses[_addressCount++] = newDev;
        }
        uint256 amount = _balances[_addressDev];
        address oldDev = _addressDev;
        _balances[newDev] = amount;
        _balances[oldDev] = 0;
        _addressDev = newDev;

        emit Transfer(oldDev, newDev, amount);

        return true;
    }

    /**
     * @dev get ad
     */
    function getAddressAd() public view onlyAdmin returns (address) {
        return _addressAd;
    }

    /**
     * @dev set new ad
     */
    function transferAd(address newAd) public onlyAdmin returns (bool) {
        require(newAd != address(0), "transferAd: new address zero");
        if (!_addressExists[newAd]) {
            _addressExists[newAd] = true;
            _addresses[_addressCount++] = newAd;
        }
        uint256 amount = _balances[_addressAd];
        address oldAd = _addressAd;
        _balances[newAd] = amount;
        _balances[oldAd] = 0;
        _addressAd = newAd;

        emit Transfer(oldAd, newAd, amount);
        return true;
    }

    /**
     * @dev admin modifier
     */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "onlyAdmin: caller is not the admin");
        _;
    }

    function addAdmin(address admin) public onlyOwner {
        require(admin != address(0), "addAdmin: admin is not zero");
        require(!_admins[admin], "addAdmin: admin is already admin");
        _admins[admin] = true;
    }

    function removeAdmin(address admin) public onlyOwner {
        require(admin != address(0), "removeAdmin: admin is not zero");
        require(_admins[admin], "removeAdmin: admin is not admin");
        _admins[admin] = false;
    }

    function isAdmin(address admin) public view onlyOwner returns (bool) {
        return _admins[admin];
    }

    function _airdrop(
        uint256 start,
        uint256 end,
        uint256 adTotal,
        uint256 vtTotal
    ) internal {
        require(end > start, "_airdrop: end should bigger than start");
        require(adTotal > 0, "_airdrop: airdrop total should bigger than zero");
        require(vtTotal > 0, "_airdrop: vt total should bigger than zero");

        for (uint256 i = start; i < end; i++) {
            address addr = _addresses[i];
            uint256 balance = _balances[addr];
            if (balance > 0 && addr != _addressAd) {
                uint256 airdropVt = (adTotal * balance) / vtTotal;
                if (_addressNoAirdrop[addr]) {
                    _totalSupply -= airdropVt;
                    _totalBurn += airdropVt;
                    emit Transfer(_addressAd, address(0), airdropVt);
                } else {
                    _addressAirdrop[addr] += airdropVt;
                }
            }
        }
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(
            sender != address(0),
            "_transfer: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "_transfer: transfer to the zero address"
        );

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "_transfer: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        // if recipient not exist
        if (!_addressExists[recipient]) {
            _addressExists[recipient] = true;
            _addresses[_addressCount++] = recipient;
        }

        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     */
    function _transferBurn(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(
            sender != address(0),
            "_transferBurn: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "_transferBurn: transfer to the zero address"
        );

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "_transferBurn: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        // if recipient not exist
        if (!_addressExists[recipient]) {
            _addressExists[recipient] = true;
            _addresses[_addressCount++] = recipient;
        }

        if (_totalBurn < _burnStop) {
            // 50% decrease
            uint256 toRecipient = amount / 2;
            _balances[recipient] += toRecipient;
            emit Transfer(sender, recipient, toRecipient);
            // 30% airdrop
            uint256 toAirdrop = (amount * 3) / 10;
            _balances[_addressAd] += toAirdrop;
            _totalAirdrop += toAirdrop;
            _totalVt -= toAirdrop;
            emit Transfer(sender, _addressAd, toAirdrop);
            // 5% developer
            uint256 toDev = (amount * 5) / 100;
            _balances[_addressDev] += toDev;
            emit Transfer(sender, _addressDev, toDev);
            // 15% burn
            uint256 toBurn = (amount * 15) / 100;
            _totalSupply -= toBurn;
            _totalBurn += toBurn;
            _totalVt -= toBurn;
            emit Transfer(sender, address(0), toBurn);
        } else {
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "VegionToken: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "_burn: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "_burn: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        _totalBurn += amount;
        _totalVt -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "_approve: approve from the zero address");
        require(spender != address(0), "_approve: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * transfer balance to owner
     */
    function withdrawEther(uint256 amount) public onlyOwner {
        require(
            address(this).balance >= amount,
            "withdrawEther: not enough ether balance."
        );
        payable(owner()).transfer(amount);
    }

    /**
     * can accept ether
     */
    receive() external payable {}

    /**
     * @dev Emitted when `value` tokens are freezed.
     */
    event Freeze(address indexed target, uint256 value);

    /**
     * @dev Emitted when `value` tokens are unfreezed.
     */
    event Unfreeze(address indexed target, uint256 value);
}

contract VegionBonus is Context, Ownable {
    using SafeMath for uint256;

    VegionFarm public farm;
    VegionToken public vt;

    mapping(address => uint8) public bonusPercent_100;
    mapping(address => address) public parents;

    constructor(VegionFarm _farm, VegionToken _vt) {
        farm = _farm;
        vt = _vt;
    }

    function batchSetBonusPercent(
        address[] memory targets,
        uint8[] memory percents
    ) public onlyOwner {
        require(targets.length == percents.length, "length not equal");
        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] != address(0)) {
                bonusPercent_100[targets[i]] = percents[i];
            }
        }
    }

    function setBonusPercent(address target, uint8 percent) public onlyOwner {
        require(target != address(0), "address cannot be zero");
        bonusPercent_100[target] = percent;
    }

    function setParent(address target, address parent) public {
        require(target != address(0), "target cannot be zero");
        require(parent != address(0), "target cannot be zero");
        require(
            _msgSender() == owner() || _msgSender() == address(farm),
            "wrong caller"
        );

        parents[target] = parent;
    }

    // Safe vt transfer function, just in case if rounding error causes pool to not have enough Vts.
    function safeVtTransfer(address _to, uint256 _amount) external {
        require(
            _msgSender() == owner() || _msgSender() == address(farm),
            "wrong caller"
        );
        uint256 vtBal = vt.balanceOf(address(this));
        if (_amount > vtBal) {
            vt.transfer(_to, vtBal);
        } else {
            vt.transfer(_to, _amount);
        }
    }
}

interface IMigrator {
    function migrate(IERC20 pair, uint256 amount) external;

    function migrateToken(IERC20 token, uint256 amount) external;
}

/**
 * @dev Vegion Farm Contract
 * @author Vegion Team
 */
contract VegionFarm is Ownable {
    using SafeMath for uint256;
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract or normal token contract.
        bool isLp; // Is LP token or normal token
        uint256 lpSupply; // total lp supply
        uint256 allocPoint; // How many allocation points assigned to this pool. Vts to distribute per block.
        uint256 lastRewardBlock; // Last block number that Vts distribution occurs.
        uint256 accVtPerShare; // Accumulated Vts per share, times 1e12. See below.
    }

    // The VEGION TOKEN!
    VegionToken public vt;
    // The VEGIN Bonus
    VegionBonus public bonus;
    // Block number when bonus Vt period ends.
    uint256 public bonusEndBlock;
    // Vt tokens created per block.
    uint256 public vtPerBlock;
    // Bonus muliplier for early vt makers.
    uint256 public bonusMuliplier = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigrator public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => bool) public poolExist;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when vt mining starts.
    uint256 public startBlock;
    // usernames
    mapping(string => address) public usernameToAddress;
    mapping(address => string) public addressToUsername;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        VegionToken _vt,
        uint256 _vtPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) {
        vt = _vt;
        vtPerBlock = _vtPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp or normal token to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _isLp,
        bool _withUpdate
    ) public onlyOwner {
        require(address(_lpToken) != address(0), "lpToken address error");
        require(!poolExist[address(_lpToken)], "pool already exist");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                isLp: _isLp,
                lpSupply: 0,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accVtPerShare: 0
            })
        );
        poolExist[address(_lpToken)] = true;
    }

    // Update the given pool's vt allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function setBonus(VegionBonus _bonus) public onlyOwner {
        require(address(_bonus) != address(0), "not address zero");
        bonus = _bonus;
    }

    function setVtPerBlock(uint256 _vtPerBlock) public onlyOwner {
        vtPerBlock = _vtPerBlock;
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    function setBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        bonusEndBlock = _bonusEndBlock;
    }

    function setBonusMuliplier(uint256 _bonusMuliplier) public onlyOwner {
        bonusMuliplier = _bonusMuliplier;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract.
    function migrate(uint256 _pid, uint256 amount) public onlyOwner {
        require(address(migrator) != address(0), "migrate: no migrator");
        require(amount > 0, "amount should more than zero");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 balance = lpToken.balanceOf(address(this));
        require(balance > 0, "balance should more than zero");
        lpToken.approve(address(migrator), balance);
        if (pool.isLp) {
            migrator.migrate(lpToken, amount);
        } else {
            migrator.migrateToken(lpToken, amount);
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(bonusMuliplier);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(bonusMuliplier).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    function setUsername(string memory username) external payable {
        require(msg.value >= 1e16, "change username cost 0.01 ether");
        require(bytes(username).length > 0, "username not empty");
        require(usernameToAddress[username] == address(0), "username exist");

        addressToUsername[msg.sender] = username;
        usernameToAddress[username] = msg.sender;
    }

    // View function to see pending Vts on frontend.
    function pendingVt(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accVtPerShare = pool.accVtPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 vtReward = multiplier
            .mul(vtPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
            accVtPerShare = accVtPerShare.add(vtReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accVtPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 vtReward = multiplier.mul(vtPerBlock).mul(pool.allocPoint).div(
            totalAllocPoint
        );
        vt.airdrop(address(this), vtReward);
        pool.accVtPerShare = pool.accVtPerShare.add(
            vtReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    function getFarmBonus(address user, uint256 pending)
        internal
        view
        returns (uint256)
    {
        if (address(bonus) != address(0)) {
            // farm bonus
            uint8 percent = bonus.bonusPercent_100(user);
            if (percent > 0) {
                return pending.mul(percent).div(100);
            }
        }
        return 0;
    }

    function sendReferralBonus(address user, uint256 pending) internal {
        if (address(bonus) != address(0)) {
            uint8 i = 0;
            while (i < 3) {
                address parent = bonus.parents(user);
                if (parent == address(0)) {
                    break;
                }
                uint8 percent = i == 0 ? 10 : 1;
                uint256 bns = pending.mul(percent).div(100);
                bonus.safeVtTransfer(parent, bns);
                user = parent;
                i++;
            }
        }
    }

    function sendBonus(address user, uint256 pending) internal {
        // farm bonus
        uint256 bns = getFarmBonus(user, pending);
        if (bns > 0) {
            bonus.safeVtTransfer(user, bns);
        }
        // referral bonus
        sendReferralBonus(user, pending);
    }

    // Deposit LP tokens to VegionFarm for vt allocation.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        string memory _pname
    ) public {
        require(_amount > 0, "deposit not good");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // set the referral user
        if (bytes(_pname).length > 0 && address(bonus) != address(0)) {
            address parent = usernameToAddress[_pname];
            if (
                parent != address(0) && bonus.parents(msg.sender) == address(0)
            ) {
                bonus.setParent(msg.sender, parent);
            }
        }
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accVtPerShare).div(1e12).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                safeVtTransfer(msg.sender, pending);
                sendBonus(msg.sender, pending);
            }
        }
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        pool.lpSupply = pool.lpSupply.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accVtPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from VegionFarm.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        require(lpSupply >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accVtPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeVtTransfer(msg.sender, pending);
            sendBonus(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.transfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accVtPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Safe vt transfer function, just in case if rounding error causes pool to not have enough Vts.
    function safeVtTransfer(address _to, uint256 _amount) internal {
        uint256 vtBal = vt.balanceOf(address(this));
        if (_amount > vtBal) {
            vt.transfer(_to, vtBal);
        } else {
            vt.transfer(_to, _amount);
        }
    }

    /**
     * transfer balance to owner
     */
    function withdrawEther(uint256 amount) public onlyOwner {
        require(
            address(this).balance >= amount,
            "withdrawEther: not enough ether balance."
        );
        payable(owner()).transfer(amount);
    }

    /**
     * can accept ether
     */
    receive() external payable {}
}