pragma solidity 0.5.17;

import "./VELOTokenInterface.sol";
import "./VELODelegate.sol";

contract VELODelegator is VELOTokenInterface, VELODelegatorInterface {
    /**
     * @notice Construct a new VELO
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param initSupply_ Initial token amount
     * @param implementation_ The address of the implementation the contract delegates to
     * @param becomeImplementationData The encoded args for becomeImplementation
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initSupply_,
        address implementation_,
        bytes memory becomeImplementationData
    )
        public
    {


        // Creator of the contract is gov during initialization
        gov = msg.sender;

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(string,string,uint8,address,uint256)",
                name_,
                symbol_,
                decimals_,
                msg.sender,
                initSupply_
            )
        );

        // New implementations always get set via the settor (post-initialize)
        _setImplementation(implementation_, false, becomeImplementationData);

    }

    /**
     * @notice Called by the gov to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public {
        require(msg.sender == gov, "VELODelegator::_setImplementation: Caller must be gov");

        if (allowResign) {
            delegateToImplementation(abi.encodeWithSignature("_resignImplementation()"));
        }

        address oldImplementation = implementation;
        implementation = implementation_;

        delegateToImplementation(abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData));

        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(address to, uint256 mintAmount)
        external
        returns (bool)
    {
        to; mintAmount; // Shh
        delegateAndReturn();
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount)
        external
        returns (bool)
    {
        dst; amount; // Shh
        delegateAndReturn();
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    )
        external
        returns (bool)
    {
        src; dst; amount; // Shh
        delegateAndReturn();
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        spender; amount; // Shh
        delegateAndReturn();
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        external
        returns (bool)
    {
        spender; addedValue; // Shh
        delegateAndReturn();
    }

    function maxScalingFactor()
        external
        view
        returns (uint256)
    {
        delegateToViewAndReturn();
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        external
        returns (bool)
    {
        spender; subtractedValue; // Shh
        delegateAndReturn();
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256)
    {
        owner; spender; // Shh
        delegateToViewAndReturn();
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param delegator The address of the account which has designated a delegate
     * @return Address of delegatee
     */
    function delegates(
        address delegator
    )
        external
        view
        returns (address)
    {
        delegator; // Shh
        delegateToViewAndReturn();
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner)
        external
        view
        returns (uint256)
    {
        owner; // Shh
        delegateToViewAndReturn();
    }

    /**
     * @notice Currently unused. For future compatability
     * @param owner The address of the account to query
     * @return The number of underlying tokens owned by `owner`
     */
    function balanceOfUnderlying(address owner)
        external
        view
        returns (uint256)
    {
        owner; // Shh
        delegateToViewAndReturn();
    }

    /*** Gov Functions ***/

    /**
      * @notice Begins transfer of gov rights. The newPendingGov must call `_acceptGov` to finalize the transfer.
      * @dev Gov function to begin change of gov. The newPendingGov must call `_acceptGov` to finalize the transfer.
      * @param newPendingGov New pending gov.
      */
    function _setPendingGov(address newPendingGov)
        external
    {
        newPendingGov; // Shh
        delegateAndReturn();
    }

    function setRebaser(address rebaser_)
        external
    {
        rebaser_; // Shh
        delegateAndReturn();
    }

    function _setIncentivizer(address incentivizer_)
        external
    {
        incentivizer_; // Shh
        delegateAndReturn();
    }

    /**
      * @notice Accepts transfer of gov rights. msg.sender must be pendingGov
      * @dev Gov function for pending gov to accept role and update gov
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptGov()
        external
    {
        delegateAndReturn();
    }

    function setGov(address gov_) external {
        gov_;
        delegateAndReturn();
    }

    function rebase(uint256 scaling_modifier) external {
        delegateAndReturn();
    }

    function setFeeCharger(
        address feeCharger_
    ) external {
      feeCharger_;
      delegateAndReturn();
    }


    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        account; blockNumber;
        delegateToViewAndReturn();
    }

    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        delegatee; nonce; expiry; v; r; s;
        delegateAndReturn();
    }

    function delegate(address delegatee)
        external
    {
        delegatee;
        delegateAndReturn();
    }

    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        account;
        delegateToViewAndReturn();
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }

    function delegateToViewAndReturn() private view returns (bytes memory) {
        (bool success, ) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", msg.data));

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(add(free_mem_ptr, 0x40), returndatasize) }
        }
    }

    function delegateAndReturn() private returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    function () external payable {
        require(msg.value == 0,"VELODelegator:fallback: cannot send value to fallback");

        // delegate all other functions to current implementation
        delegateAndReturn();
    }
}
