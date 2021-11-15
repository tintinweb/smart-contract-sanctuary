// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBackupableERC20.sol";

contract BackupableERC20 is IBackupableERC20 {
    // keccak256("Backup(address account,address backupAddress,uint256 value,uint256 deadline)")
    bytes32 public constant BACKUP_TYPEHASH =
        0x4310bae2d8c961b4f172b7233bb28f5e858776459ced2b09e2a6c2951c368ef4;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => address) private _backupAddresses;
    mapping(address => bool) private _blacklisted;

    uint256 public override totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    modifier notBlacklisted(address account) {
        require(!_blacklisted[account], "BackupableERC20: blacklisted");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _mint(msg.sender, totalSupply_);
    }

    function _mint(address account, uint256 amount) internal {
        require(
            account != address(0),
            "BackupableERC20: mint to the zero address"
        );

        _balances[account] += amount;
        totalSupply += amount;

        emit Transfer(address(0), account, amount);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "BackupableERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "BackupableERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setBackupAddress(address backup)
        external
        notBlacklisted(msg.sender)
        notBlacklisted(backup)
    {
        _backupAddresses[msg.sender] = backup;

        emit BackupAddressSet(msg.sender, backup);
    }

    function backupToken(
        address account,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external notBlacklisted(account) {
        require(
            deadline >= block.timestamp,
            "BackupableERC20: signature expired"
        );
        address _backupAddress = _backupAddresses[account];
        uint256 _currentBalance = _balances[account];

        require(
            _backupAddress != address(0),
            "BackupableERC20: backup address is not set"
        );
        require(
            !_blacklisted[_backupAddress],
            "BackupableERC20: backup address is black listed"
        );

        bytes memory data = abi.encode(
            BACKUP_TYPEHASH,
            account,
            _backupAddress,
            _currentBalance,
            deadline
        );

        require(
            _recover(_toEthSignedMessageHash(keccak256(data)), v, r, s) ==
                account,
            "BackupableERC20: invalid signature"
        );

        _emergencyTransfer(account, _backupAddress, _currentBalance);
        _makeBlackList(account);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal notBlacklisted(sender) notBlacklisted(recipient) {
        require(
            sender != address(0),
            "BackupableERC20: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "BackupableERC20: transfer to the zero address"
        );

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "BackupableERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal notBlacklisted(owner) notBlacklisted(spender) {
        require(
            owner != address(0),
            "BackupableERC20: approve from the zero address"
        );
        require(
            spender != address(0),
            "BackupableERC20: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _emergencyTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        _transfer(from, to, amount);

        emit EmergencyTransfer(from, to, amount);
    }

    function _makeBlackList(address account) internal {
        _blacklisted[account] = true;
        emit Blacklisted(account);
    }

    function _recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "BackupableERC20: invalid signature 's' value"
        );
        require(
            v == 27 || v == 28,
            "BackupableERC20: invalid signature 'v' value"
        );

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "BackupableERC20: invalid signature");

        return signer;
    }

    function _toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
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

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function backupAddress(address account)
        external
        view
        override
        returns (address)
    {
        return _backupAddresses[account];
    }

    function blacklisted(address account)
        external
        view
        override
        returns (bool)
    {
        return _blacklisted[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface of the IBackupableERC20.
 */
interface IBackupableERC20 is IERC20 {
    /**
     * @dev Returns backup address.
     */
    function backupAddress(address account) external view returns (address);

    /**
     * @dev Returns if black listed.
     */
    function blacklisted(address account) external view returns (bool);

    /**
     * @dev Emitted when `account` set `backupAddress` as backup address
     */
    event BackupAddressSet(
        address indexed account,
        address indexed backupAddress
    );

    /**
     * @dev Emitted when `account` is black listed
     */
    event Blacklisted(address indexed account);

    /**
     * @dev Emitted when `value` tokens are backed up from one account (`from`)
     */
    event EmergencyTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT

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

