/**

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

// SPDX-License-Identifier: MIT

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */

// File contracts/Vfi.sol
pragma solidity 0.8.9;

/// @title the vfi token
/// Note initially forked from Uniswap and then upgraded to 0.8.9
contract Vfi {
    /// @notice EIP-20 token name for this token
    string public constant name = 'Vulture';

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = 'VFI';

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply = 300_000_000e18; // 300M VFI

    /// @notice Address which may mint new tokens
    address public minter;

    /// @notice The timestamp after which minting may occur
    uint256 public mintingAllowedAfter;

    /// @notice Minimum time between mints
    uint32 public constant minimumTimeBetweenMints = 1 days * 365;

    /// @notice Cap on the percentage of totalSupply that can be minted at each mint
    uint8 public constant mintCap = 2;

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public immutable DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public immutable PERMIT_TYPEHASH =
        keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when the minter address is changed
    event MinterChanged(address minter, address newMinter);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new Vfi token
     * @param account The initial account to grant all the tokens
     * @param minter_ The account with minting ability
     * @param mintingAllowedAfter_ The timestamp after which minting may occur
     */
    constructor(
        address account,
        address minter_,
        uint256 mintingAllowedAfter_
    ) {
        require(mintingAllowedAfter_ >= block.timestamp, 'Vfi::constructor: minting can only begin after deployment');

        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
        minter = minter_;
        emit MinterChanged(address(0), minter_);
        mintingAllowedAfter = mintingAllowedAfter_;
    }

    /**
     * @notice Change the minter address
     * @param minter_ The address of the new minter
     */
    function setMinter(address minter_) external {
        require(msg.sender == minter, 'Vfi::setMinter: only the minter can change the minter address');
        emit MinterChanged(minter, minter_);
        minter = minter_;
    }

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to be minted
     */
    function mint(address dst, uint256 rawAmount) external {
        require(msg.sender == minter, 'Vfi::mint: only the minter can mint');
        require(block.timestamp >= mintingAllowedAfter, 'Vfi::mint: minting not allowed yet');
        require(dst != address(0), 'Vfi::mint: cannot transfer to the zero address');

        // record the mint
        mintingAllowedAfter = block.timestamp + minimumTimeBetweenMints;

        // mint the amount
        uint96 amount = safe96(rawAmount, 'Vfi::mint: amount exceeds 96 bits');
        require(amount <= (totalSupply * mintCap)/(100), 'Vfi::mint: exceeded mint cap');
        totalSupply = safe96(totalSupply + amount, 'Vfi::mint: totalSupply exceeds 96 bits');

        // transfer the amount to the recipient
        balances[dst] = add96(balances[dst], amount, 'Vfi::mint: transfer amount overflows');
        emit Transfer(address(0), dst, amount);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint256) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, 'Vfi::approve: amount exceeds 96 bits');
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address owner,
        address spender,
        uint256 rawAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // VFI-01M fix
        require(v == 27 || v == 28, 'Vfi::permit: invalid range for v');
        require(
            uint256(s) < 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1,
            'Vfi::permit: invalid range for s'
        );

        uint96 amount;
        if (rawAmount == type(uint256).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, 'Vfi::permit: amount exceeds 96 bits');
        }

        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline)
        );
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'Vfi::permit: invalid signature');
        require(signatory == owner, 'Vfi::permit: unauthorized');
        require(block.timestamp <= deadline, 'Vfi::permit: signature expired');

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @dev This function is expected to ALWAYS return true, or else it should throw
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, 'Vfi::transfer: amount exceeds 96 bits');
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, 'Vfi::approve: amount exceeds 96 bits');

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(
                spenderAllowance,
                amount,
                'Vfi::transferFrom: transfer amount exceeds spender allowance'
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint96 amount
    ) internal {
        require(src != address(0), 'Vfi::_transferTokens: cannot transfer from the zero address');
        require(dst != address(0), 'Vfi::_transferTokens: cannot transfer to the zero address');

        balances[src] = sub96(balances[src], amount, 'Vfi::_transferTokens: transfer amount exceeds balance');
        balances[dst] = add96(balances[dst], amount, 'Vfi::_transferTokens: transfer amount overflows');
        emit Transfer(src, dst, amount);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}