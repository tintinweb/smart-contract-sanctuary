/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/interfaces/ISashoToken.sol

pragma solidity ^0.8.6;

interface ISashoToken is IERC20 {

    function mint(address account, uint256 rawAmount) external;

    function burn(uint256 tokenId) external;

    function delegate(address delegatee) external;

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}


// File contracts/MultisendSasho.sol


/// @title Sasho multisend contract.

pragma solidity ^0.8.6;

contract MultisendSasho {

  // The Sashos ERC20 token contract.
  ISashoToken public sashos;

  constructor(ISashoToken _sashos) {
    sashos = _sashos;
  }

  function multiSashoTransfer(
      address[] memory _addresses,
      uint[] memory _amounts
  ) public {
      for (uint i = 0; i < _addresses.length; i++) {
          _safeSashoTransfer(_addresses[i], _amounts[i]);
      }
  }

  /// @notice `_safeERC20Transfer` is used internally to
  ///  transfer a quantity of ERC20 tokens safely.
  function _safeSashoTransfer(address _to, uint _amount) internal {
      require(_to != address(0));
      require(sashos.transferFrom(msg.sender, _to, _amount));
  }

}