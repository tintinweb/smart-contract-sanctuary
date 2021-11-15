pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SushiRelayHelper.sol";

contract SushiRelayer is SushiRelayHelper {

    mapping(address => uint256) public nonces;
    mapping(address => bool) public whitelistedStrategies;
    mapping(address => uint256) public pendingStrategies;

    string  public constant name = "SushiRelayer";
    string  public constant version = "1";
    
    bytes32 public immutable DOMAIN_SEPARATOR;
    
    bool public enforceTimeLock;
    
    event LogQueueStrategy (address strategy);
    event LogApproveStrategy (address strategy);
    event LogRemoveStrategy (address strategy);

    constructor() public {
        uint256 chainId;
        assembly { chainId := chainid() }
        DOMAIN_SEPARATOR = keccak256(abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
        ));
    }
    
    function execute(bytes memory data) public {
        (
            address strategy, 
            address owner, 
            uint256 nonce,
            uint256 deadline,
            bytes4 functionSelector
            
        ) = abi.decode(data, (address, address, uint256, uint256, bytes4));
        
        require(nonce == nonces[owner]++, "!nonce");
        require(deadline > block.timestamp, "expired");
        require(whitelistedStrategies[strategy], "!whitelisted");
        
        (bool success, ) = strategy.delegatecall(
            abi.encodeWithSelector(
                bytes4(functionSelector), 
                data
            )
        );
        
        // Incase the transaction at the strategy fail or returns false as they do in safeMethods.
        require(success, "Transaction Failed");
    }
    
    function whitelistStrategy(address _strategy) onlyOwner external {
        if (enforceTimeLock && pendingStrategies[_strategy] == 0) {        
            
            pendingStrategies[_strategy] = block.timestamp + 10 days;
            emit LogQueueStrategy(_strategy);

        } else if (pendingStrategies[_strategy] < block.timestamp) {
            
            whitelistedStrategies[_strategy] = true;
            pendingStrategies[_strategy] = 0;
            emit LogApproveStrategy(_strategy);

        }
    }

    function removeStrategy(address _strategy) onlyOwner external {
        whitelistedStrategies[_strategy] = false;
        pendingStrategies[_strategy] = 0;
        emit LogRemoveStrategy(_strategy);
    }

    function activateTimeLock() onlyOwner external {
        enforceTimeLock = true;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

// import "https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol";
// import "https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/libraries/BoringERC20.sol";

interface IBentoBoxV1 {
    function transfer(IERC20 token, address from, address to, uint256 share) external;
    function balanceOf(IERC20, address) external view returns (uint256);
}

contract SushiRelayHelper is BoringOwnable {

    using BoringERC20 for IERC20;

    address public feeTo;

    IBentoBoxV1 public constant bentoBox = IBentoBoxV1(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966); // mainnet

    event LogFeesCollected (IERC20 token, uint256 amount);
    event LogFeesCollectedBento (IERC20 token, uint256 amount);

    function swipeFees(IERC20[] memory tokens) external {
        uint256 balance;
        for (uint256 i = 0; i < tokens.length; i++) {
            balance = tokens[i].balanceOf(address(this));
            if (balance > 1) {
                tokens[i].safeTransfer(feeTo, balance - 1);
            }
        }
    }

    function swipeFeesBento(IERC20[] memory tokens) external {        
        uint256 balance;
        for (uint256 i = 0; i < tokens.length; i++) {
            balance = bentoBox.balanceOf(tokens[i], address(this));
            if (balance > 1) {
                bentoBox.transfer(tokens[i], address(this), feeTo, balance);
                emit LogFeesCollected(tokens[i], balance);
            }
        }
    }

    function setFeeTo(address _feeTo) onlyOwner public {
        feeTo = _feeTo;
    }

    /// Call the permit function of an ERC20 token
    /// Approves spending of users tokens
    /// @param payload parameters for permit function encoded with signature e.g. abi.encodeWithSignature("permit(address, ...)", 0x...)
    function approveUsersTokensWithPermit(address tokenContract, bytes memory payload) public {
        (bool success,) = tokenContract.call(payload);
        require(success);
    }

    // WIP this has not yet been tested
    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    function batch(bytes[] calldata calls) external returns (bool success) {
        success = true;
        for (uint256 i = 0; i < calls.length; i++) {
            (bool _success, ) = address(this).delegatecall(calls[i]);
            success = success && _success;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while(i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

