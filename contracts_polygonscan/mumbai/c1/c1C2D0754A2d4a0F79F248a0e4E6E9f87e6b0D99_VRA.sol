/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @author BIZVERSE-LAB

/**
 * @dev IERC20 OpenZeppelin Implementation
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev IERC20Metadata OpenZeppelin Implementation
 */
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

/**
 * @dev Context OpenZeppelin Implementation
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
 * @dev Address library from OpenZeppelin Implementation
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Ownable OpenZeppelin Implementation
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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
 * @dev ERC20 OpenZeppelin Implementation
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

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

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/**
 * @dev Pausable OpenZeppelin Implementation
 */
abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/**
 * @dev ERC20Pausable OpenZeppelin Implementation
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

/**
  @dev  Contract module which allows children to implement a mechanism that can be triggered by an authorized account

        This module is used through inheritance. It will make available the modifier `inBlacklistStatus`, 
        which can be applied to function of contract.

 */
abstract contract Blacklistable is Context {
    /// @dev a private variable to check the address that is blacklist or not
    mapping(address => bool) private _blacklist;

    /// @dev Emitted when an account is added to blacklist
    event AddToBlacklist(address account);

    /// @dev Emitted when an account is removed from blacklist
    event RemoveFromBlacklist(address account);

    /** 
        @dev Modifier to make a function callable only when the address is 
        in blacklist or not. NOTE Set parameter `isBlacklisted` TRUE to check
        the address is in blacklist, FALSE to check the address is not in blacklist
        Requirements:
        - The address must be in the blacklist `isBlacklisted` status
    */
    modifier inBlacklistStatus(address account, bool isBlacklisted) {
        require(
            _blacklist[account] == isBlacklisted,
            "Blacklistable: Account not in expected status"
        );
        _;
    }

    /**
        @dev Set blacklist status for a given address.
     */
    function _setBlacklistStatus(address account, bool isBlacklisted)
        internal
        virtual
        inBlacklistStatus(account, !isBlacklisted)
    {
        _blacklist[account] = isBlacklisted;
        if (isBlacklisted) emit AddToBlacklist(account);
        else emit RemoveFromBlacklist(account);
    }

    /**
        @dev Returns true if the given account is blacklisted, and false otherwise
     */
    function isBlacklist(address account) public view virtual returns (bool) {
        return _blacklist[account];
    }
}

/**
 * @dev ERC20 token that can blacklist an evil address. NOTE The blacklisted
 * address is not allowed to transfer, to receive funds , to approve, to be spender
 */
abstract contract ERC20Blacklistable is Blacklistable, ERC20 {
    /**
     * @dev Hook called before transfering token, including minting and burning.
     *
     * Requirements:
     * - The sender, recipient, caller not in blacklist
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (!(isBlacklist(from) && to == address(0))) {
            require(
                !isBlacklist(from),
                "ERC20Blacklistable: Sender blacklisted"
            );
            require(
                !isBlacklist(to),
                "ERC20Blacklistable: Recipient blacklisted"
            );
            require(
                !isBlacklist(_msgSender()),
                "ERC20Blacklistable: Caller blacklisted"
            );
        }
    }

    /**
     * @dev ERC20 approve
     *
     * Requirements:
     * - The owner, spender not in blacklist
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        super._approve(owner, spender, amount);
        require(!isBlacklist(owner), "ERC20Blacklistable: Owner blacklisted");
        require(
            !isBlacklist(spender),
            "ERC20Blacklistable: Spender blacklisted"
        );
    }
}

/**
 * @dev ERC20 for general usecase in Bizverse World with pausable, blacklistable functions
 */
contract BizverseWorldERC20 is ERC20Pausable, ERC20Blacklistable, Ownable {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    /// @dev Only owner can mint
    function mint(address to, uint256 amount)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        _mint(to, amount);
        return true;
    }

    /// @dev Only owner can pause
    function pause() public virtual onlyOwner returns (bool) {
        _pause();
        return true;
    }

    /// @dev Only owner can unpause
    function unpause() public virtual onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    /// @dev Only owner can add address to blacklist
    function addToBlacklist(address account)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        _setBlacklistStatus(account, true);
        return true;
    }

    /// @dev Only owner can remove address from blacklist
    function removeFromBlacklist(address account)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        _setBlacklistStatus(account, false);
        return true;
    }

    /// @dev Only owner burn dead fund from blacklisted user
    function burnDead(address account)
        public
        virtual
        onlyOwner
        inBlacklistStatus(account, true)
        returns (bool)
    {
        uint256 evilBalance = balanceOf(account);
        _burn(account, evilBalance);
        return true;
    }

    /// @dev Overriding _beforeTokenTransfer hook from ERC20Pausable and ERC20Blacklistable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Pausable, ERC20Blacklistable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @dev Overriding _approve ERC20 and ERC20Blacklistable
    function _approve(
        address from,
        address spender,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Blacklistable) {
        super._approve(from, spender, amount);
    }
}

/**
 * @dev AllowanceWhitelistable let children contract to whitelist the address
 * that can be used in `approve` function. NOTE Used for whitelist only contracts, not EOA
 */
abstract contract AllowanceWhitelistable {
    using Address for address;

    /// @dev variable tracking whitelisted contract for approvals
    mapping(address => bool) private _whitelistApprovals;

    /// @dev Emitted when adding a contract to whitelist
    event AddContractToWhitelist(address target);

    /// @dev Emitted when removing a contract from whitelist
    event RemoveContractFromWhitelist(address target);

    /// @dev Modifier to check the address is in whitelist when `approve` is called.
    /// Requirements: The `target` address is CONTRACT IN WHITELIST
    modifier whenInWhitelist(address target) {
        if (target.isContract())
            require(
                _whitelistApprovals[target],
                "AllowanceWhitelistable: Contract must be in whitelist for approvals"
            );
        _;
    }

    /// @dev Modifier to check the address is NOT in whitelist when `approve` is called.
    /// Requirements: The `target` address is CONTRACT NOT IN WHITELIST
    modifier whenNotInWhitelist(address target) {
        if (target.isContract())
            require(
                !_whitelistApprovals[target],
                "AllowanceWhitelistable: Contract must not be in whitelist for approvals"
            );
        _;
    }

    /// @dev Modifier to check the address is a contract
    /// Requirements: The `target` address is CONTRACT.
    modifier onlyContract(address target) {
        require(
            target.isContract(),
            "AllowanceWhitelistable: Target is not a contract"
        );
        _;
    }

    /// @dev Returns false if address is a CONTRACT AND NOT IN WHITELIST, true otherwise.
    function isWhitelisted(address target) public view returns (bool) {
        if (target.isContract()) return _whitelistApprovals[target];
        else return true;
    }

    /// @dev Add a contract to whitelist
    function _addContractToWhitelist(address target)
        internal
        virtual
        onlyContract(target)
        whenNotInWhitelist(target)
    {
        _whitelistApprovals[target] = true;
    }

    /// @dev Remove a contract from whitelist
    function _removeContractFromWhitelist(address target)
        internal
        virtual
        onlyContract(target)
        whenInWhitelist(target)
    {
        _whitelistApprovals[target] = false;
    }
}

/**
 * @dev VRA Contract is an inheritance from BizverseWorldERC20 with additional AllowanceWhitelistable
 */
contract VRA is BizverseWorldERC20, AllowanceWhitelistable {
    constructor(uint256 initialSupply)
        BizverseWorldERC20("VIRTUAL REALITY ASSET", "VRA")
    {
        _mint(_msgSender(), initialSupply);
    }

    /// @dev Only approve when spender is in approval whitelist
    function approve(address spender, uint256 amount)
        public
        override
        whenInWhitelist(spender)
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @dev Owner can add contract to approval whitelist
    function addContractToWhitelist(address target)
        public
        onlyOwner
        returns (bool)
    {
        _addContractToWhitelist(target);
        return true;
    }

    /// @dev Owner can remove contract from approval whitelist
    function removeContractFromWhitelist(address target)
        public
        onlyOwner
        returns (bool)
    {
        _removeContractFromWhitelist(target);
        return true;
    }

    /// @dev ERC20 decimals
    function decimals() public pure override returns (uint8) {
        return 4;
    }
}