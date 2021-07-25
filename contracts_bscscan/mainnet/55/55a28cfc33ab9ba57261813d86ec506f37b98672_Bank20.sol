/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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



pragma solidity 0.6.12;

contract Bank20 {

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public CLAIM_TYPEHASH;
    bytes32 public PASSWORD_TYPEHASH;
    mapping(address => uint) public nonces;
    mapping(address => mapping(address => uint)) public tokenUserBalance;

    event  Deposit(address indexed token, address indexed user, uint value);
    event  Withdraw(address indexed token, address indexed from, address indexed to, uint value);
    event  Claim(address indexed token, address indexed from, address indexed to, uint value);
    event  Password(address indexed token, address indexed from, address indexed to, uint value);


    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes('Bank20')),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );

        CLAIM_TYPEHASH = keccak256('Claim(address token,address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
        PASSWORD_TYPEHASH = keccak256('Password(address token,address owner,string psw,uint256 value,uint256 nonce,uint256 deadline)');
    }

    function deposit(address token, uint value) public {
        IERC20(token).transferFrom(msg.sender, address(this), value);
        tokenUserBalance[token][msg.sender] = tokenUserBalance[token][msg.sender] + value;

        emit Deposit(token, msg.sender, value);
    }

    function withdraw(address token, address spender, uint value) public {
        require(tokenUserBalance[token][msg.sender] >= value, 'Bank20::withdraw: oh no');
        tokenUserBalance[token][msg.sender] = tokenUserBalance[token][msg.sender] - value;
        IERC20(token).transfer(spender, value);

        emit Withdraw(token, msg.sender, spender, value);
    }

    function claim(address token, address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Bank20::claim: expired deadline');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(CLAIM_TYPEHASH, token, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Bank20::claim: invalid signature');

        require(tokenUserBalance[token][owner] >= value, 'Bank20::claim: oh no');
        tokenUserBalance[token][owner] = tokenUserBalance[token][owner] - value;
        IERC20(token).transfer(spender, value);

        emit Claim(token, owner, spender, value);
    }

    function password(address token, address owner, string memory psw, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Bank20::password: expired deadline');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PASSWORD_TYPEHASH, token, owner, psw, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Bank20::password: invalid signature');

        require(tokenUserBalance[token][owner] >= value, 'Bank20::password: oh no');
        tokenUserBalance[token][owner] = tokenUserBalance[token][owner] - value;
        IERC20(token).transfer(msg.sender, value);

        emit Password(token, owner, msg.sender, value);
    }
}