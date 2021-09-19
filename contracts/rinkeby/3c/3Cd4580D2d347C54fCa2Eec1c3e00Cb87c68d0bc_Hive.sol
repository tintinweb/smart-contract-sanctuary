/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// 
contract Hive {
    address[] internal _warrants;
    address[] internal _oracles;
    mapping(address => address) internal _metadata;
    address internal _hiveToken;

    event Register(address indexed warrant, address indexed metadata, address indexed sender);
    event Unregister(address indexed warrant, address indexed sender);

    constructor(address hiveToken)  {
        require(hiveToken != address(0), "Hive: The HiveToken address can't be empty.");
        _hiveToken = hiveToken;
    }

    function registerWarrant(address warrant, address metadata) external {
        uint256 balance = IERC20(_hiveToken).balanceOf(msg.sender);
        require(balance >= 10 * 10e18, "Hive: not enough HiveTokens to register a Warrant");
        require(warrant != address(0), "Hive: The Warrant address can't be empty.");
        uint32 index = 0;
        if (metadata != address(0)) {
            for (uint32 i; i < _oracles.length; i++) {
                if (_oracles[i] == metadata) {
                    index = i;
                    break;
                }
            }
        }
        require(metadata == address(0) || _oracles[index] == metadata, "Hive: The Oracle wasn't registered in the Hive.");
        _warrants.push(warrant);
        _metadata[warrant] = metadata;

        emit Register(warrant, metadata, msg.sender);
    }

    function unregisterWarrant(address warrant) external {
        uint256 balance = IERC20(_hiveToken).balanceOf(msg.sender);
        require(balance >= 10 * 10e18, "Hive: not enough HiveTokens to unregister a Warrant");
        uint32 index = 0;
        for (uint32 i; i < _warrants.length; i++) {
            if (_warrants[i] == warrant) {
                index = i;
                break;
            }
        }
        require(_warrants[index] == warrant, "Hive: The warrant wasn't registered in the Hive.");
        _warrants[index] = _warrants[_warrants.length - 1];
        _warrants.pop();
        //delete _warrants[_warrants.length - 1];
        delete _metadata[warrant];

        emit Unregister(warrant, msg.sender);
    }

    function getOracal(address warrant) external view returns (address) {
        return _metadata[warrant];
    }

    function registerOracle(address oracle) external {
        uint256 balance = IERC20(_hiveToken).balanceOf(msg.sender);
        require(balance >= 10 * 10e18, "Hive: not enough HiveTokens to register a Warrant");
        require(oracle != address(0), "Hive: The Oracle address can't be empty.");
        _oracles.push(oracle);
    }

    function unregisterOracle(address oracle) external {
        uint256 balance = IERC20(_hiveToken).balanceOf(msg.sender);
        require(balance >= 10 * 10e18, "Hive: not enough HiveTokens to unregister a Oracle");
        uint32 index = 0;
        for (uint32 i; i < _oracles.length; i++) {
            if (_oracles[i] == oracle) {
                index = i;
                break;
            }
        }
        require(_oracles[index] == oracle, "Hive: The Oracle wasn't registered in the Hive.");
        _oracles[index] = _oracles[_oracles.length - 1];
        _oracles.pop();
    }
}