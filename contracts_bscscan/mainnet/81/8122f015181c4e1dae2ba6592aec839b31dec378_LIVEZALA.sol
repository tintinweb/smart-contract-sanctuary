/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

/**
 * Created by nopantytonight, 21 May 2021.
 */

contract LIVEZALA {
    string public constant NAME = "LIVEZALA";

    string public constant SYMBOL = "LVZ";

    uint8 public constant DECIMALS = 18;

    uint256 public totalSupply = 777777777000000000000000000;

    // Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    // Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @notice Construct a new token
     */
    constructor() {
        balances[msg.sender] = uint96(totalSupply);
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /* @notice Token name */
    function name() public pure returns (string memory) {
        return NAME;
    }

    /* @notice Token symbol */
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    /* @notice Token decimals */
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    /* @notice domainSeparator */
    // solhint-disable func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(NAME)),
                    getChainId(),
                    address(this)
                )
            );
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
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
    function approve(address spender, uint256 rawAmount)
        external
        returns (bool)
    {
        _approve(msg.sender, spender, rawAmount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 rawAmount
    ) internal {
        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(
                rawAmount,
                "BuyRadicle::approve: amount exceeds 96 bits"
            );
        }

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
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        uint96 amount =
            safe96(rawAmount, "BuyRadicle::transfer: amount exceeds 96 bits");
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
        uint96 amount =
            safe96(rawAmount, "BuyRadicle::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance =
                sub96(
                    spenderAllowance,
                    amount,
                    "BuyRadicle::transferFrom: transfer amount exceeds spender allowance"
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
        require(
            src != address(0),
            "BuyRadicle::_transferTokens: cannot transfer from the zero address"
        );
        require(
            dst != address(0),
            "BuyRadicle::_transferTokens: cannot transfer to the zero address"
        );

        balances[src] = sub96(
            balances[src],
            amount,
            "BuyRadicle::_transferTokens: transfer amount exceeds balance"
        );
        balances[dst] = add96(
            balances[dst],
            amount,
            "BuyRadicle::_transferTokens: transfer amount overflows"
        );
        emit Transfer(src, dst, amount);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint96)
    {
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

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        // solhint-disable no-inline-assembly
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}