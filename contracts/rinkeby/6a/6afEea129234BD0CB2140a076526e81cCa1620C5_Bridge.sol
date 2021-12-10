/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// File: contracts/Ownable.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        // address msgSender = _msgSender();
        _owner = msg.sender;
        // emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        // emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Bridge.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/// @title   Network Bridge
/// @author chandrashekhar
/// @notice You can use this contract for transfer token between two blockchain networks
/// @dev All function calls are currently implemented without side effects

contract Bridge is Ownable {
    IERC20 irc20Token;
    uint256 nonce;
    address signer; // signer
    mapping(uint256 => bool) public processNonce; // processNonce gose inside the mapping
    // mapping(bytes32 => bool) public processSecretData; // processSecretData
    address[] public availableTokens; // availableTokens;

    event TransferToken(
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        uint256 nonce
    );
    event WithdrawToken(
        address indexed from,
        address indexed receiver,
        uint256 amount,
        uint256 nonces
    );

    event AddnewToken(address indexed tokenAddress);
    event RemoveToken(address indexed tokenAddress);

    constructor(address _signer) {
        signer = _signer;
    }

    /// @notice Add the new token to bridge
    /// @dev This function calls onlyOwner to add the new token address in future
    /// @param _token The addresss of newly token

    function addIRC20Token(address _token) public onlyOwner {
        require(!tokenExists(_token), "this token already in list");
        availableTokens.push(_token);
        emit AddnewToken(_token);
    }

    /// @notice remove the  token from bridge
    /// @dev This function calls onlyOwner to remove the  token address in future
    /// @param _token The addresss of  token to remove

    function removeIRC20Token(address _token) public onlyOwner {
        if (availableTokens.length >= 1) {
            for (uint256 i = 0; i < availableTokens.length; i++) {
                if (availableTokens[i] == _token) {
                    availableTokens[i] = availableTokens[
                        availableTokens.length - 1
                    ];
                    availableTokens.pop();
                    emit RemoveToken(_token);
                }
            }
        }
    }

    function getAvailableTokens() public view returns (address[] memory) {
        return availableTokens;
    }

    function tokenExists(address _token) public view returns (bool exist) {
        if (availableTokens.length >= 1) {
            for (uint256 i = 0; i < availableTokens.length; i++) {
                if (availableTokens[i] == _token) {
                    exist = true;
                    return exist;
                }
            }
            return false;
        }
    }

    /// @notice transfer the  token from bridge one network to the other network
    /// @dev This function call by any public user
    /// @param from _amount .selectedToeken, _nonce

    function transferToken(
        address from,
        uint256 _amount,
        address fromToken
    ) public {
        irc20Token = IERC20(fromToken);

        require(tokenExists(fromToken), "This token is not available");

        require(
            irc20Token.allowance(from, address(this)) == _amount,
            "insufficent amount allowance"
        );

        // bytes32 _secretData = keccak256(
        //     abi.encodePacked(((block.timestamp + _amount + nonce)))
        // );

        irc20Token.transferFrom(from, address(this), _amount);
        nonce = nonce + 1;

        emit TransferToken(from, address(this), _amount, nonce);
    }

    /// @notice Redeem the  token from bridge to the other network
    /// @dev This function call by any public user who transfer the token form the other network using bridge
    /// @param from  ,to, _amount, nonce,secretData,messageHash,v,r,s,selectedToken

    function RedeemToken(
        address from,
        address to,
        uint256 amount,
        uint256 _nonce,
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address selectedToken
    ) public {
        irc20Token = IERC20(selectedToken);
        require(tokenExists(selectedToken), "This token is not available");
        require(processNonce[_nonce] == false, "This nonce Already process ");
        require(
            ecrecover(messageHash, v, r, s) == signer,
            "The amount or vrs is not correct "
        );
        irc20Token.transfer(to, amount);
        emit WithdrawToken(from, to, amount, _nonce);
        processNonce[_nonce] = true;
    }
}