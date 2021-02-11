/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

/*
  Copyright 2019,2020 StarkWare Industries Ltd.
  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  https://www.starkware.co/open-source-license/
  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/

pragma solidity ^0.6.2;


interface IFactRegistry {
    /*
      Returns true if the given fact was previously registered in the contract.
    */
    function isValid(bytes32 fact)
        external view
        returns(bool);
}

/*
  Extends the IFactRegistry interface with a query method that indicates
  whether the fact registry has successfully registered any fact or is still empty of such facts.
*/
interface IQueryableFactRegistry is IFactRegistry {

    /*
      Returns true if at least one fact has been registered.
    */
    function hasRegisteredFact()
        external view
        returns(bool);

}


contract FactRegistry is IQueryableFactRegistry {
    // Mapping: fact hash -> true.
    mapping (bytes32 => bool) private verifiedFact;

    // Indicates whether the Fact Registry has at least one fact registered.
    bool anyFactRegistered;

    /*
      Checks if a fact has been verified.
    */
    function isValid(bytes32 fact)
        external view override
        returns(bool)
    {
        return _factCheck(fact);
    }


    /*
      This is an internal method to check if the fact is already registered.
      In current implementation of FactRegistry it's identical to isValid().
      But the check is against the local fact registrey,
      So for a derived referral fact registry, it's not the same.
    */
    function _factCheck(bytes32 fact)
        internal view
        returns(bool)
    {
        return verifiedFact[fact];
    }

    function registerFact(
        bytes32 factHash
        )
        internal
    {
        // This function stores the fact hash in the mapping.
        verifiedFact[factHash] = true;

        // Mark first time off.
        if (!anyFactRegistered) {
            anyFactRegistered = true;
        }
    }

    /*
      Indicates whether at least one fact was registered.
    */
    function hasRegisteredFact()
        external view override
        returns(bool)
    {
        return anyFactRegistered;
    }

}

interface Identity {

    /*
      Allows a caller, typically another contract,
      to ensure that the provided address is of the expected type and version.
    */
    function identify()
        external view
        returns(string memory);
}

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

contract TransferRegistry is FactRegistry, Identity {

    event LogRegisteredTransfer(
        address recipient,
        address token,
        uint256 amount,
        uint256 salt
    );

    function identify()
        external view override
        returns(string memory)
    {
        return "StarkWare_TransferRegistry_2020_1";
    }

    /*
      Safe wrapper around ERC20/ERC721 calls.
      This is required because many deployed ERC20 contracts don't return a value.
      See https://github.com/ethereum/solidity/issues/4116.
    */
    function safeTokenContractCall(address tokenAddress, bytes memory callData) internal {
        // solium-disable-next-line security/no-low-level-calls
        // NOLINTNEXTLINE: low-level-calls.
        (bool success, bytes memory returndata) = address(tokenAddress).call(callData);
        require(success, string(returndata));

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "TOKEN_OPERATION_FAILED");
        }
    }

    /*
      The actual transfer is extracted to a function, so that we can easily mock the contract.
    */
    function performEthTransfer(address payable recipient, uint256 value)
        internal {
        recipient.transfer(value);
    }

    /*
      The actual transfer is extracted to a function, so that we can easily mock the contract.
    */
    function performErc20Transfer(address recipient, address erc20, uint256 amount)
        internal {
        safeTokenContractCall(
            erc20,
            abi.encodeWithSelector(IERC20(0).transferFrom.selector, msg.sender, recipient, amount)
        );
    }

    /*
      Passes on the transaction ETH value onto the recipient address,
      and register the associated fact.
      Reverts if the fact has already been registered.
    */
    function transfer(address payable recipient, uint256 salt) // NOLINT: erc20-interface.
        payable
        external {
        bytes32 transferFact = keccak256(
            abi.encodePacked(recipient, msg.value, address(0x0), salt));
        require(!_factCheck(transferFact), "TRANSFER_ALREADY_REGISTERED");
        registerFact(transferFact);
        emit LogRegisteredTransfer(recipient, address(0x0), msg.value, salt);
        performEthTransfer(recipient, msg.value);
    }

    /*
      Transfer the specified amount of erc20 tokens from msg.sender balance to the recipient's
      balance.
      Pre-conditions to successful transfer are that the msg.sender has sufficient balance,
      and the the approval (for the transfer) was granted to this contract.
      A fact with the transfer details is registered upon success.
      Reverts if the fact has already been registered.
    */
    function transferERC20(address recipient, address erc20, uint256 amount, uint256 salt)
        external {
        bytes32 transferFact = keccak256(
            abi.encodePacked(recipient, amount, erc20, salt));
        require(!_factCheck(transferFact), "TRANSFER_ALREADY_REGISTERED");
        registerFact(transferFact);
        emit LogRegisteredTransfer(recipient, erc20, amount, salt);
        performErc20Transfer(recipient, erc20, amount);
    }

}