/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * See https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
 * @dev Interface of the ERC677 standard as defined in the EIP.
 * See https://github.com/ethereum/EIPs/issues/677.
 */
interface IERC677 {
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool);
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

interface ITransferReceiver {
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns (bool);
}

interface IApprovalReceiver {
    function onTokenApproval(address from, uint amount, bytes calldata data) external returns (bool);
}

/// @dev MERC20 is ERC20, ERC2612, ERC677 token
contract MERC20 is IERC20, IERC2612, IERC677 {
    string public name;
    string public symbol;
    uint8  public immutable override decimals;
    uint256 public override totalSupply;
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    /// @dev Records current ERC2612 nonce for account.
    /// This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} increases account's nonce by one.
    /// This prevents signature from being used multiple times.
    mapping (address => uint256) public override nonces;

    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant TRANSFER_TYPEHASH = keccak256(
        "Transfer(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public immutable override DOMAIN_SEPARATOR;
    uint256 public immutable deploymentChainId;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        _mint(msg.sender, _totalSupply);

        uint256 chainId;
        assembly {chainId := chainid()}
        DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId);
        deploymentChainId = chainId;
    }

    /// @dev Calculate the DOMAIN_SEPARATOR.
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)));
    }

    /// @dev Creates `amount` tokens and assigns them to account (`to`), increasing the total supply.
    /// Emits {Transfer} event with `from` set to the zero address.
    /// Requirements
    ///   - `to` account cannot be the zero address.
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "MERC20: mint to the zero address");

        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @dev Destroys `amount` tokens from account (`from`), reducing the total supply.
    /// Emits {Transfer} event with `to` set to the zero address.
    /// Requirements
    ///   - `from` account cannot be the zero address.
    ///   - `from` account must have at least `amount` tokens.
    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "MERC20: burn from the zero address");
        uint256 balance = balanceOf[from];
        require(balance >= amount, "MERC20: burn amount exceeds balance");

        balanceOf[from] = balance - amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    /// @dev Moves `value` token from account (`from`) to account (`to`)
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - `to` account cannot be the zero address or this contract address.
    ///   - `from` account must have at least `value` balance of token.
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0) && to != address(this), "MERC20: to address is not allowed");
        uint256 balance = balanceOf[from];
        require(balance >= value, "MERC20: transfer amount exceeds balance");

        balanceOf[from] = balance - value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    /// @dev Sets `value` as allowance of `spender` account over `owner` account's token.
    /// Emits {Approval} event.
    function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @dev Destroys `amount` tokens from `msg.sender`, reducing the total supply.
    /// Emits {Transfer} event with `to` set to the zero address.
    /// Returns boolean value indicating whether operation succeeded.
    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's token.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return IApprovalReceiver(spender).onTokenApproval(msg.sender, value, data);
    }

    /// @dev Moves `value` token from caller's account to account (`to`).
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` token.
    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /// @dev Moves `value` token from caller's account to account (`to`),
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
    }

    /// @dev Moves `value` token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - `from` account must have at least `value` balance of token.
    ///   - `from` account must have approved caller to spend at least `value` of token, unless `from` and caller are the same account.
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "MERC20: request exceeds allowance");
                _approve(from, msg.sender, allowed - value);
            }
        }

        _transfer(from, to, value);
        return true;
    }

    /// @dev Moves `value` token from account {`owner`} to account (`to`).
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - owner account must have at least `value` token.
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account.
    ///   - the signature must use `owner` account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner` account.
    function transferWithPermit(address owner, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool) {
        require(block.timestamp <= deadline, "MERC20: Expired permit");

        bytes32 hashStruct = keccak256(
            abi.encode(
                TRANSFER_TYPEHASH,
                owner,
                to,
                value,
                nonces[owner]++,
                deadline));

        require(verifyEIP712(owner, hashStruct, v, r, s), "MERC20: invalid permit");

        _transfer(owner, to, value);
        return true;
    }

    /// @dev Sets `value` as allowance of `spender` account over `owner` account's token, given `owner` account's signed approval.
    /// Emits {Approval} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner` account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// token implementation adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol.
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(block.timestamp <= deadline, "MERC20: Expired permit");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline));

        require(verifyEIP712(owner, hashStruct, v, r, s), "MERC20: invalid permit");

        _approve(owner, spender, value);
    }

    function verifyEIP712(address owner, bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashStruct));
        address signer = ecrecover(hash, v, r, s);
        return (signer == owner && signer != address(0));
    }
}