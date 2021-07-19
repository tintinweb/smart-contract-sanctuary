/**
 *Submitted for verification at Etherscan.io on 2021-07-19
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