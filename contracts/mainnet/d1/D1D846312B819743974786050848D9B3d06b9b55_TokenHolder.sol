/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// File: solidity/contracts/utility/interfaces/IOwned.sol

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// File: solidity/contracts/utility/Owned.sol


pragma solidity 0.6.12;


/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
     * @dev triggered when the owner is updated
     *
     * @param _prevOwner previous owner
     * @param _newOwner  new owner
     */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     * the new owner still needs to accept the transfer
     * can only be called by the contract owner
     *
     * @param _newOwner    new contract owner
     */
    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity/contracts/utility/Utils.sol


pragma solidity 0.6.12;

/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address _address) {
        _validExternalAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address _address) internal view {
        require(_address != address(0) && _address != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }
}

// File: solidity/contracts/token/interfaces/IERC20Token.sol


pragma solidity 0.6.12;

/*
    ERC20 Standard Token interface
*/
interface IERC20Token {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);
}

// File: solidity/contracts/utility/TokenHandler.sol


pragma solidity 0.6.12;


contract TokenHandler {
    bytes4 private constant APPROVE_FUNC_SELECTOR = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant TRANSFER_FUNC_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant TRANSFER_FROM_FUNC_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));

    /**
     * @dev executes the ERC20 token's `approve` function and reverts upon failure
     * the main purpose of this function is to prevent a non standard ERC20 token
     * from failing silently
     *
     * @param _token   ERC20 token address
     * @param _spender approved address
     * @param _value   allowance amount
     */
    function safeApprove(
        IERC20Token _token,
        address _spender,
        uint256 _value
    ) internal {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERR_APPROVE_FAILED");
    }

    /**
     * @dev executes the ERC20 token's `transfer` function and reverts upon failure
     * the main purpose of this function is to prevent a non standard ERC20 token
     * from failing silently
     *
     * @param _token   ERC20 token address
     * @param _to      target address
     * @param _value   transfer amount
     */
    function safeTransfer(
        IERC20Token _token,
        address _to,
        uint256 _value
    ) internal {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERR_TRANSFER_FAILED");
    }

    /**
     * @dev executes the ERC20 token's `transferFrom` function and reverts upon failure
     * the main purpose of this function is to prevent a non standard ERC20 token
     * from failing silently
     *
     * @param _token   ERC20 token address
     * @param _from    source address
     * @param _to      target address
     * @param _value   transfer amount
     */
    function safeTransferFrom(
        IERC20Token _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERR_TRANSFER_FROM_FAILED");
    }
}

// File: solidity/contracts/utility/interfaces/ITokenHolder.sol


pragma solidity 0.6.12;



/*
    Token Holder interface
*/
interface ITokenHolder is IOwned {
    function withdrawTokens(
        IERC20Token _token,
        address _to,
        uint256 _amount
    ) external;
}

// File: solidity/contracts/utility/TokenHolder.sol


pragma solidity 0.6.12;






/**
 * @dev This contract provides a safety mechanism for allowing the owner to
 * send tokens that were sent to the contract by mistake back to the sender.
 *
 * We consider every contract to be a 'token holder' since it's currently not possible
 * for a contract to deny receiving tokens.
 *
 * Note that we use the non standard ERC-20 interface which has no return value for transfer
 * in order to support both non standard as well as standard token contracts.
 * see https://github.com/ethereum/solidity/issues/4116
 */
contract TokenHolder is ITokenHolder, TokenHandler, Owned, Utils {
    /**
     * @dev withdraws tokens held by the contract and sends them to an account
     * can only be called by the owner
     *
     * @param _token   ERC20 token contract address
     * @param _to      account to receive the new amount
     * @param _amount  amount to withdraw
     */
    function withdrawTokens(
        IERC20Token _token,
        address _to,
        uint256 _amount
    ) public virtual override ownerOnly validAddress(address(_token)) validAddress(_to) notThis(_to) {
        safeTransfer(_token, _to, _amount);
    }
}