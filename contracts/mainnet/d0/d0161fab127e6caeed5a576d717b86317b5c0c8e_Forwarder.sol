// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.1;


import "./interfaces/IERC20.sol";

contract Forwarder {

    // Address to which any funds sent to this contract will be forwarded
    address public parentAddress;
    // to -> to which funds are forwarded
    event ForwarderDeposited(address from, address indexed to, uint value);

    event TokensFlushed(
        address tokenContractAddress, // The contract address of the token
        address to, // the contract - multisig - to which erc20 tokens were forwarded
        uint value // Amount of token sent
    );

    constructor (address multisigWallet) {
        parentAddress = multisigWallet;
    }


    function forwardERC20(address tokenAddress) public returns (bool){
        IERC20 token = IERC20(tokenAddress);
        uint value = token.balanceOf(address (this));
        if (value > 0 ) {
            if (token.transfer(parentAddress, value)) {
                emit TokensFlushed(tokenAddress, parentAddress, value);
                return true;
            }
        }
        return false;
    }


    function forward() payable public {

        (bool success, ) = parentAddress.call{value: address(this).balance}("");
        require(success, 'Deposit failed');
        emit ForwarderDeposited(msg.sender, parentAddress, msg.value);
    }

    receive () payable external {
        forward();
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.1;

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}