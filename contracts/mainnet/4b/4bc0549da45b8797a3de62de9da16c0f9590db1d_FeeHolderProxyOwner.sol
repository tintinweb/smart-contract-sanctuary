/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

// File: contracts/loopring/iface/IFeeHolder.sol

/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.7;


/// @author Kongliang Zhong - <[email protected]>
/// @title IFeeHolder - A contract holding fees.
contract IFeeHolder {

    event TokenWithdrawn(
        address owner,
        address token,
        uint value
    );

    // A map of all fee balances; token --> owner --> balance
    mapping(address => mapping(address => uint)) public feeBalances;

    // A map of all the nonces for a withdrawTokenFor request
    mapping(address => uint) public nonces;

    /// @dev   Allows withdrawing the tokens to be burned by
    ///        authorized contracts.
    /// @param token The token to be used to burn buy and burn LRC
    /// @param value The amount of tokens to withdraw
    function withdrawBurned(
        address token,
        uint value
        )
        external
        returns (bool success);

    /// @dev   Allows withdrawing the fee payments funds
    ///        msg.sender is the recipient of the fee and the address
    ///        to which the tokens will be sent.
    /// @param token The token to withdraw
    /// @param value The amount of tokens to withdraw
    function withdrawToken(
        address token,
        uint value
        )
        external
        returns (bool success);

    /// @dev   Allows withdrawing the fee payments funds by providing a
    ///        a signature
    function withdrawTokenFor(
      address owner,
      address token,
      uint value,
      address recipient,
      uint feeValue,
      address feeRecipient,
      uint nonce,
      bytes calldata signature
      )
      external
      returns (bool success);

    function batchAddFeeBalances(
        bytes32[] calldata batch
        )
        external;
}

// File: contracts/loopring/lib/Ownable.sol

/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.7;


/// @title Ownable
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
        public
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0x0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: contracts/loopring/impl/FeeHolderProxyOwner.sol

/*
 * Copyright 2019 Dolomite
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.5.13;




contract FeeHolderProxyOwner is Ownable {

    using SafeERC20 for IERC20;

    event FeeHolderSet(address indexed newFeeHolder, address indexed oldFeeHolder);
    event TokenWithdrawn(address indexed token, address receiver, uint amount);

    IFeeHolder public feeHolder;

    constructor(
        address _feeHolder
    ) public {
        feeHolder = IFeeHolder(_feeHolder);
    }

    // ******************************
    // ***** Getters
    // ******************************

    function getBalancesByToken(
        address token
    ) public view returns (uint burnBalance, uint feeBalance) {
        burnBalance = feeHolder.feeBalances(token, address(feeHolder));
        feeBalance = feeHolder.feeBalances(token, address(this));
    }

    // ******************************
    // ***** Setters and Writers
    // ******************************

    function executeCode(
        string calldata signature,
        bytes calldata data
    )
    external
    payable
    onlyOwner
    returns (bytes memory) {
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = (address(feeHolder)).call.value(msg.value)(callData);
        require(success, "EXECUTION_REVERTED");

        return returnData;
    }

    function setFeeHolder(
        address _feeHolder
    )
    external
    onlyOwner {
        address oldFeeHolder = address(feeHolder);
        feeHolder = IFeeHolder(_feeHolder);
        emit FeeHolderSet(_feeHolder, oldFeeHolder);
    }

    function withdrawAllFeesByTokens(
        address[] calldata tokens,
        address receiver
    )
    external
    onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            _withdrawAllFeesByToken(tokens[i], receiver);
        }
    }

    function withdrawAllFeesByToken(
        address token,
        address receiver
    )
    external
    onlyOwner {
        _withdrawAllFeesByToken(token, receiver);
    }

    function _withdrawAllFeesByToken(
        address token,
        address receiver
    ) internal {
        (uint burnBalance, uint feeBalance) = getBalancesByToken(token);
        if (burnBalance > 0) {
            feeHolder.withdrawBurned(token, burnBalance);
        }
        if (feeBalance > 0) {
            feeHolder.withdrawToken(token, feeBalance);
        }

        uint balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(receiver, balance);
        }

        emit TokenWithdrawn(token, receiver, balance);
    }

}