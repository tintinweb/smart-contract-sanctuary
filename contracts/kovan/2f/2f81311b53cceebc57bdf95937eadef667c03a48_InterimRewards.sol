/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// hevm: flattened sources of src/InterimRewards.sol
// SPDX-License-Identifier: MIT
pragma solidity =0.8.9 >=0.8.0 <0.9.0;

////// node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.0; */

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

////// src/Ownable.sol
/* pragma solidity 0.8.9; */

// Constructor is removed for upgradeability
abstract contract Ownable {
    event OwnerNominated(address newOwner);
    event OwnerChanged(address newOwner);

    address public owner;
    address public nominatedOwner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "not nominated");

        owner = nominatedOwner;
        nominatedOwner = address(0);

        emit OwnerChanged(owner);
    }
}

////// src/Whitelist.sol
/* pragma solidity 0.8.9; */

abstract contract Whitelist {
    event SetWhitelist(address indexed addr, bool approved);

    error WhitelistNoChange(address addr, bool approved);

    mapping(address => bool) public whitelist;

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "not whitelisted");
        _;
    }

    function _setWhitelist(address _addr, bool _approved) internal {
        if (whitelist[_addr] == _approved) {
            revert WhitelistNoChange(_addr, _approved);
        }

        whitelist[_addr] = _approved;

        emit SetWhitelist(_addr, _approved);
    }
}

////// src/InterimRewards.sol
/* pragma solidity 0.8.9; */

/* import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; */
/* import "./Ownable.sol"; */
/* import "./Whitelist.sol"; */

contract InterimRewards is Ownable, Whitelist {
    IERC20 public immutable vader;

    constructor(address _vader) {
        require(_vader != address(0), "vader = zero address");
        vader = IERC20(_vader);
        owner = msg.sender;
    }

    function setWhitelist(address _addr, bool _approved) external onlyOwner {
        _setWhitelist(_addr, _approved);
    }

    function transfer(address _to, uint _amount) external onlyWhitelist {
        vader.transfer(_to, _amount);
    }

    function sweep(IERC20 _token) external onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
}