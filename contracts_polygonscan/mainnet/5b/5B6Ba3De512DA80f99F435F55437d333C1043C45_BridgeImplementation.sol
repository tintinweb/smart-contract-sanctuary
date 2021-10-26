// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface Structs {
	struct Provider {
		uint16 chainId;
		uint16 governanceChainId;
		bytes32 governanceContract;
	}

	struct GuardianSet {
		address[] keys;
		uint32 expirationTime;
	}

	struct Signature {
		bytes32 r;
		bytes32 s;
		uint8 v;
		uint8 guardianIndex;
	}

	struct VM {
		uint8 version;
		uint32 timestamp;
		uint32 nonce;
		uint16 emitterChainId;
		bytes32 emitterAddress;
		uint64 sequence;
		uint8 consistencyLevel;
		bytes payload;

		uint32 guardianSetIndex;
		Signature[] signatures;

		bytes32 hash;
	}
}

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/external/BytesLib.sol";

import "./BridgeGetters.sol";
import "./BridgeSetters.sol";
import "./BridgeStructs.sol";
import "./BridgeGovernance.sol";

import "./token/Token.sol";
import "./token/TokenImplementation.sol";

contract Bridge is BridgeGovernance {
    using BytesLib for bytes;

    // Produce a AssetMeta message for a given token
    function attestToken(address tokenAddress, uint32 nonce) public payable returns (uint64 sequence){
        // decimals, symbol & token are not part of the core ERC20 token standard, so we need to support contracts that dont implement them
        (,bytes memory queriedDecimals) = tokenAddress.staticcall(abi.encodeWithSignature("decimals()"));
        (,bytes memory queriedSymbol) = tokenAddress.staticcall(abi.encodeWithSignature("symbol()"));
        (,bytes memory queriedName) = tokenAddress.staticcall(abi.encodeWithSignature("name()"));

        uint8 decimals = abi.decode(queriedDecimals, (uint8));

        string memory symbolString = abi.decode(queriedSymbol, (string));
        string memory nameString = abi.decode(queriedName, (string));

        bytes32 symbol;
        bytes32 name;
        assembly {
            // first 32 bytes hold string length
            symbol := mload(add(symbolString, 32))
            name := mload(add(nameString, 32))
        }

        BridgeStructs.AssetMeta memory meta = BridgeStructs.AssetMeta({
        payloadID : 2,
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        tokenAddress : bytes32(uint256(uint160(tokenAddress))),
        // Chain ID of the token
        tokenChain : chainId(),
        // Number of decimals of the token (big-endian uint8)
        decimals : decimals,
        // Symbol of the token (UTF-8)
        symbol : symbol,
        // Name of the token (UTF-8)
        name : name
        });

        bytes memory encoded = encodeAssetMeta(meta);

        sequence = wormhole().publishMessage{
            value : msg.value
        }(nonce, encoded, 15);
    }

    function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) public payable returns (uint64 sequence) {
        uint wormholeFee = wormhole().messageFee();

        require(wormholeFee < msg.value, "value is smaller than wormhole fee");

        uint amount = msg.value - wormholeFee;

        require(arbiterFee <= amount, "fee is bigger than amount minus wormhole fee");

        uint normalizedAmount = normalizeAmount(amount, 18);
        uint normalizedArbiterFee = normalizeAmount(arbiterFee, 18);

        // refund dust
        uint dust = amount - deNormalizeAmount(normalizedAmount, 18);
        if (dust > 0) {
            payable(msg.sender).transfer(dust);
        }

        // deposit into WETH
        WETH().deposit{
            value : amount - dust
        }();

        // track and check outstanding token amounts
        bridgeOut(address(WETH()), normalizedAmount);

        sequence = logTransfer(chainId(), bytes32(uint256(uint160(address(WETH())))), normalizedAmount, recipientChain, recipient, normalizedArbiterFee, wormholeFee, nonce);
    }

    // Initiate a Transfer
    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) public payable returns (uint64 sequence) {
        // determine token parameters
        uint16 tokenChain;
        bytes32 tokenAddress;
        if (isWrappedAsset(token)) {
            tokenChain = TokenImplementation(token).chainId();
            tokenAddress = TokenImplementation(token).nativeContract();
        } else {
            tokenChain = chainId();
            tokenAddress = bytes32(uint256(uint160(token)));
        }

        // query tokens decimals
        (,bytes memory queriedDecimals) = token.staticcall(abi.encodeWithSignature("decimals()"));
        uint8 decimals = abi.decode(queriedDecimals, (uint8));

        // don't deposit dust that can not be bridged due to the decimal shift
        amount = deNormalizeAmount(normalizeAmount(amount, decimals), decimals);

        if (tokenChain == chainId()) {
            // query own token balance before transfer
            (,bytes memory queriedBalanceBefore) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
            uint256 balanceBefore = abi.decode(queriedBalanceBefore, (uint256));

            // transfer tokens
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);

            // query own token balance after transfer
            (,bytes memory queriedBalanceAfter) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
            uint256 balanceAfter = abi.decode(queriedBalanceAfter, (uint256));

            // correct amount for potential transfer fees
            amount = balanceAfter - balanceBefore;
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);

            TokenImplementation(token).burn(address(this), amount);
        }

        // normalize amounts decimals
        uint256 normalizedAmount = normalizeAmount(amount, decimals);
        uint256 normalizedArbiterFee = normalizeAmount(arbiterFee, decimals);

        // track and check outstanding token amounts
        if (tokenChain == chainId()) {
            bridgeOut(token, normalizedAmount);
        }

        sequence = logTransfer(tokenChain, tokenAddress, normalizedAmount, recipientChain, recipient, normalizedArbiterFee, msg.value, nonce);
    }

    function normalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256){
        if (decimals > 8) {
            amount /= 10 ** (decimals - 8);
        }
        return amount;
    }

    function deNormalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256){
        if (decimals > 8) {
            amount *= 10 ** (decimals - 8);
        }
        return amount;
    }

    function logTransfer(uint16 tokenChain, bytes32 tokenAddress, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 fee, uint256 callValue, uint32 nonce) internal returns (uint64 sequence) {
        require(fee <= amount, "fee exceeds amount");

        BridgeStructs.Transfer memory transfer = BridgeStructs.Transfer({
            payloadID : 1,
            amount : amount,
            tokenAddress : tokenAddress,
            tokenChain : tokenChain,
            to : recipient,
            toChain : recipientChain,
            fee : fee
        });

        bytes memory encoded = encodeTransfer(transfer);

        sequence = wormhole().publishMessage{
            value : callValue
        }(nonce, encoded, 15);
    }

    function updateWrapped(bytes memory encodedVm) external returns (address token) {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(encodedVm);

        require(valid, reason);
        require(verifyBridgeVM(vm), "invalid emitter");

        BridgeStructs.AssetMeta memory meta = parseAssetMeta(vm.payload);
        return _updateWrapped(meta, vm.sequence);
    }

    function _updateWrapped(BridgeStructs.AssetMeta memory meta, uint64 sequence) internal returns (address token) {
        address wrapped = wrappedAsset(meta.tokenChain, meta.tokenAddress);
        require(wrapped != address(0), "wrapped asset does not exists");

        // Update metadata
        TokenImplementation(wrapped).updateDetails(bytes32ToString(meta.name), bytes32ToString(meta.symbol), sequence);

        return wrapped;
    }

    function createWrapped(bytes memory encodedVm) external returns (address token) {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(encodedVm);

        require(valid, reason);
        require(verifyBridgeVM(vm), "invalid emitter");

        BridgeStructs.AssetMeta memory meta = parseAssetMeta(vm.payload);
        return _createWrapped(meta, vm.sequence);
    }

    // Creates a wrapped asset using AssetMeta
    function _createWrapped(BridgeStructs.AssetMeta memory meta, uint64 sequence) internal returns (address token) {
        require(meta.tokenChain != chainId(), "can only wrap tokens from foreign chains");
        require(wrappedAsset(meta.tokenChain, meta.tokenAddress) == address(0), "wrapped asset already exists");

        // initialize the TokenImplementation
        bytes memory initialisationArgs = abi.encodeWithSelector(
            TokenImplementation.initialize.selector,
            bytes32ToString(meta.name),
            bytes32ToString(meta.symbol),
            meta.decimals,
            sequence,

            address(this),

            meta.tokenChain,
            meta.tokenAddress
        );

        // initialize the BeaconProxy
        bytes memory constructorArgs = abi.encode(address(this), initialisationArgs);

        // deployment code
        bytes memory bytecode = abi.encodePacked(type(BridgeToken).creationCode, constructorArgs);

        bytes32 salt = keccak256(abi.encodePacked(meta.tokenChain, meta.tokenAddress));

        assembly {
            token := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

            if iszero(extcodesize(token)) {
                revert(0, 0)
            }
        }

        setWrappedAsset(meta.tokenChain, meta.tokenAddress, token);
    }

    function completeTransfer(bytes memory encodedVm) public {
        _completeTransfer(encodedVm, false);
    }

    function completeTransferAndUnwrapETH(bytes memory encodedVm) public {
        _completeTransfer(encodedVm, true);
    }

    // Execute a Transfer message
    function _completeTransfer(bytes memory encodedVm, bool unwrapWETH) internal {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(encodedVm);

        require(valid, reason);
        require(verifyBridgeVM(vm), "invalid emitter");

        BridgeStructs.Transfer memory transfer = parseTransfer(vm.payload);

        require(!isTransferCompleted(vm.hash), "transfer already completed");
        setTransferCompleted(vm.hash);

        require(transfer.toChain == chainId(), "invalid target chain");

        IERC20 transferToken;
        if (transfer.tokenChain == chainId()) {
            transferToken = IERC20(address(uint160(uint256(transfer.tokenAddress))));

            // track outstanding token amounts
            bridgedIn(address(transferToken), transfer.amount);
        } else {
            address wrapped = wrappedAsset(transfer.tokenChain, transfer.tokenAddress);
            require(wrapped != address(0), "no wrapper for this token created yet");

            transferToken = IERC20(wrapped);
        }

        require(unwrapWETH == false || address(transferToken) == address(WETH()), "invalid token, can only unwrap WETH");

        // query decimals
        (,bytes memory queriedDecimals) = address(transferToken).staticcall(abi.encodeWithSignature("decimals()"));
        uint8 decimals = abi.decode(queriedDecimals, (uint8));

        // adjust decimals
        uint256 nativeAmount = deNormalizeAmount(transfer.amount, decimals);
        uint256 nativeFee = deNormalizeAmount(transfer.fee, decimals);

        // transfer fee to arbiter
        if (nativeFee > 0) {
            require(nativeFee <= nativeAmount, "fee higher than transferred amount");

            if (unwrapWETH) {
                WETH().withdraw(nativeFee);

                payable(msg.sender).transfer(nativeFee);
            } else {
                if (transfer.tokenChain != chainId()) {
                    // mint wrapped asset
                    TokenImplementation(address(transferToken)).mint(msg.sender, nativeFee);
                } else {
                    SafeERC20.safeTransfer(transferToken, msg.sender, nativeFee);
                }
            }
        }

        // transfer bridged amount to recipient
        uint transferAmount = nativeAmount - nativeFee;
        address transferRecipient = address(uint160(uint256(transfer.to)));

        if (unwrapWETH) {
            WETH().withdraw(transferAmount);

            payable(transferRecipient).transfer(transferAmount);
        } else {
            if (transfer.tokenChain != chainId()) {
                // mint wrapped asset
                TokenImplementation(address(transferToken)).mint(transferRecipient, transferAmount);
            } else {
                SafeERC20.safeTransfer(transferToken, transferRecipient, transferAmount);
            }
        }
    }

    function bridgeOut(address token, uint normalizedAmount) internal {
        uint outstanding = outstandingBridged(token);
        require(outstanding + normalizedAmount <= type(uint64).max, "transfer exceeds max outstanding bridged token amount");
        setOutstandingBridged(token, outstanding + normalizedAmount);
    }

    function bridgedIn(address token, uint normalizedAmount) internal {
        setOutstandingBridged(token, outstandingBridged(token) - normalizedAmount);
    }

    function verifyBridgeVM(IWormhole.VM memory vm) internal view returns (bool){
        if (bridgeContracts(vm.emitterChainId) == vm.emitterAddress) {
            return true;
        }

        return false;
    }

    function encodeAssetMeta(BridgeStructs.AssetMeta memory meta) public pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(
            meta.payloadID,
            meta.tokenAddress,
            meta.tokenChain,
            meta.decimals,
            meta.symbol,
            meta.name
        );
    }

    function encodeTransfer(BridgeStructs.Transfer memory transfer) public pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(
            transfer.payloadID,
            transfer.amount,
            transfer.tokenAddress,
            transfer.tokenChain,
            transfer.to,
            transfer.toChain,
            transfer.fee
        );
    }

    function parseAssetMeta(bytes memory encoded) public pure returns (BridgeStructs.AssetMeta memory meta) {
        uint index = 0;

        meta.payloadID = encoded.toUint8(index);
        index += 1;

        require(meta.payloadID == 2, "invalid AssetMeta");

        meta.tokenAddress = encoded.toBytes32(index);
        index += 32;

        meta.tokenChain = encoded.toUint16(index);
        index += 2;

        meta.decimals = encoded.toUint8(index);
        index += 1;

        meta.symbol = encoded.toBytes32(index);
        index += 32;

        meta.name = encoded.toBytes32(index);
        index += 32;

        require(encoded.length == index, "invalid AssetMeta");
    }

    function parseTransfer(bytes memory encoded) public pure returns (BridgeStructs.Transfer memory transfer) {
        uint index = 0;

        transfer.payloadID = encoded.toUint8(index);
        index += 1;

        require(transfer.payloadID == 1, "invalid Transfer");

        transfer.amount = encoded.toUint256(index);
        index += 32;

        transfer.tokenAddress = encoded.toBytes32(index);
        index += 32;

        transfer.tokenChain = encoded.toUint16(index);
        index += 2;

        transfer.to = encoded.toBytes32(index);
        index += 32;

        transfer.toChain = encoded.toUint16(index);
        index += 2;

        transfer.fee = encoded.toUint256(index);
        index += 32;

        require(encoded.length == index, "invalid Transfer");
    }

    function bytes32ToString(bytes32 input) internal pure returns (string memory) {
        uint256 i;
        while (i < 32 && input[i] != 0) {
            i++;
        }
        bytes memory array = new bytes(i);
        for (uint c = 0; c < i; c++) {
            array[c] = input[c];
        }
        return string(array);
    }

    // we need to accept ETH sends to unwrap WETH
    receive() external payable {}
}

// contracts/Getters.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IWormhole.sol";

import "./BridgeState.sol";

contract BridgeGetters is BridgeState {
    function governanceActionIsConsumed(bytes32 hash) public view returns (bool) {
        return _state.consumedGovernanceActions[hash];
    }

    function isInitialized(address impl) public view returns (bool) {
        return _state.initializedImplementations[impl];
    }

    function isTransferCompleted(bytes32 hash) public view returns (bool) {
        return _state.completedTransfers[hash];
    }

    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.wormhole);
    }

    function chainId() public view returns (uint16){
        return _state.provider.chainId;
    }

    function governanceChainId() public view returns (uint16){
        return _state.provider.governanceChainId;
    }

    function governanceContract() public view returns (bytes32){
        return _state.provider.governanceContract;
    }

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) public view returns (address){
        return _state.wrappedAssets[tokenChainId][tokenAddress];
    }

    function bridgeContracts(uint16 chainId_) public view returns (bytes32){
        return _state.bridgeImplementations[chainId_];
    }

    function tokenImplementation() public view returns (address){
        return _state.tokenImplementation;
    }

    function WETH() public view returns (IWETH){
        return IWETH(_state.provider.WETH);
    }

    function outstandingBridged(address token) public view returns (uint256){
        return _state.outstandingBridged[token];
    }

    function isWrappedAsset(address token) public view returns (bool){
        return _state.isWrappedAsset[token];
    }
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import "../libraries/external/BytesLib.sol";

import "./BridgeGetters.sol";
import "./BridgeSetters.sol";
import "./BridgeStructs.sol";

import "./token/Token.sol";
import "./token/TokenImplementation.sol";

import "../interfaces/IWormhole.sol";

contract BridgeGovernance is BridgeGetters, BridgeSetters, ERC1967Upgrade {
    using BytesLib for bytes;

    // "TokenBridge" (left padded)
    bytes32 constant module = 0x000000000000000000000000000000000000000000546f6b656e427269646765;

    // Execute a RegisterChain governance message
    function registerChain(bytes memory encodedVM) public {
        (IWormhole.VM memory vm, bool valid, string memory reason) = verifyGovernanceVM(encodedVM);
        require(valid, reason);

        setGovernanceActionConsumed(vm.hash);

        BridgeStructs.RegisterChain memory chain = parseRegisterChain(vm.payload);

        require(chain.chainId == chainId() || chain.chainId == 0, "invalid chain id");
        require(bridgeContracts(chain.emitterChainID) == bytes32(0), "chain already registered");

        setBridgeImplementation(chain.emitterChainID, chain.emitterAddress);
    }

    // Execute a UpgradeContract governance message
    function upgrade(bytes memory encodedVM) public {
        (IWormhole.VM memory vm, bool valid, string memory reason) = verifyGovernanceVM(encodedVM);
        require(valid, reason);

        setGovernanceActionConsumed(vm.hash);

        BridgeStructs.UpgradeContract memory implementation = parseUpgrade(vm.payload);

        require(implementation.chainId == chainId(), "wrong chain id");

        upgradeImplementation(address(uint160(uint256(implementation.newContract))));
    }

    function verifyGovernanceVM(bytes memory encodedVM) internal view returns (IWormhole.VM memory parsedVM, bool isValid, string memory invalidReason){
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole().parseAndVerifyVM(encodedVM);

        if (!valid) {
            return (vm, valid, reason);
        }

        if (vm.emitterChainId != governanceChainId()) {
            return (vm, false, "wrong governance chain");
        }
        if (vm.emitterAddress != governanceContract()) {
            return (vm, false, "wrong governance contract");
        }

        if (governanceActionIsConsumed(vm.hash)) {
            return (vm, false, "governance action already consumed");
        }

        return (vm, true, "");
    }

    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    function upgradeImplementation(address newImplementation) internal {
        address currentImplementation = _getImplementation();

        _upgradeTo(newImplementation);

        // Call initialize function of the new implementation
        (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));

        require(success, string(reason));

        emit ContractUpgraded(currentImplementation, newImplementation);
    }

    function parseRegisterChain(bytes memory encoded) public pure returns (BridgeStructs.RegisterChain memory chain) {
        uint index = 0;

        // governance header

        chain.module = encoded.toBytes32(index);
        index += 32;
        require(chain.module == module, "invalid RegisterChain: wrong module");

        chain.action = encoded.toUint8(index);
        index += 1;
        require(chain.action == 1, "invalid RegisterChain: wrong action");

        chain.chainId = encoded.toUint16(index);
        index += 2;

        // payload

        chain.emitterChainID = encoded.toUint16(index);
        index += 2;

        chain.emitterAddress = encoded.toBytes32(index);
        index += 32;

        require(encoded.length == index, "invalid RegisterChain: wrong length");
    }

    function parseUpgrade(bytes memory encoded) public pure returns (BridgeStructs.UpgradeContract memory chain) {
        uint index = 0;

        // governance header

        chain.module = encoded.toBytes32(index);
        index += 32;
        require(chain.module == module, "invalid UpgradeContract: wrong module");

        chain.action = encoded.toUint8(index);
        index += 1;
        require(chain.action == 2, "invalid UpgradeContract: wrong action");

        chain.chainId = encoded.toUint16(index);
        index += 2;

        // payload

        chain.newContract = encoded.toBytes32(index);
        index += 32;

        require(encoded.length == index, "invalid UpgradeContract: wrong length");
    }
}

// contracts/Implementation.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import "./Bridge.sol";


contract BridgeImplementation is Bridge {
    // Beacon getter for the token contracts
    function implementation() public view returns (address) {
        return tokenImplementation();
    }

    function initialize() initializer public virtual {
        // this function needs to be exposed for an upgrade to pass
    }

    modifier initializer() {
        address impl = ERC1967Upgrade._getImplementation();

        require(
            !isInitialized(impl),
            "already initialized"
        );

        setInitialized(impl);

        _;
    }
}

// contracts/Setters.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./BridgeState.sol";

contract BridgeSetters is BridgeState {
    function setInitialized(address implementatiom) internal {
        _state.initializedImplementations[implementatiom] = true;
    }

    function setGovernanceActionConsumed(bytes32 hash) internal {
        _state.consumedGovernanceActions[hash] = true;
    }

    function setTransferCompleted(bytes32 hash) internal {
        _state.completedTransfers[hash] = true;
    }

    function setChainId(uint16 chainId) internal {
        _state.provider.chainId = chainId;
    }

    function setGovernanceChainId(uint16 chainId) internal {
        _state.provider.governanceChainId = chainId;
    }

    function setGovernanceContract(bytes32 governanceContract) internal {
        _state.provider.governanceContract = governanceContract;
    }

    function setBridgeImplementation(uint16 chainId, bytes32 bridgeContract) internal {
        _state.bridgeImplementations[chainId] = bridgeContract;
    }

    function setTokenImplementation(address impl) internal {
        _state.tokenImplementation = impl;
    }

    function setWETH(address weth) internal {
        _state.provider.WETH = weth;
    }

    function setWormhole(address wh) internal {
        _state.wormhole = payable(wh);
    }

    function setWrappedAsset(uint16 tokenChainId, bytes32 tokenAddress, address wrapper) internal {
        _state.wrappedAssets[tokenChainId][tokenAddress] = wrapper;
        _state.isWrappedAsset[wrapper] = true;
    }

    function setOutstandingBridged(address token, uint256 outstanding) internal {
        _state.outstandingBridged[token] = outstanding;
    }
}

// contracts/State.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./BridgeStructs.sol";

contract BridgeStorage {
    struct Provider {
        uint16 chainId;
        uint16 governanceChainId;
        bytes32 governanceContract;
        address WETH;
    }

    struct Asset {
        uint16 chainId;
        bytes32 assetAddress;
    }

    struct State {
        address payable wormhole;
        address tokenImplementation;

        Provider provider;

        // Mapping of consumed governance actions
        mapping(bytes32 => bool) consumedGovernanceActions;

        // Mapping of consumed token transfers
        mapping(bytes32 => bool) completedTransfers;

        // Mapping of initialized implementations
        mapping(address => bool) initializedImplementations;

        // Mapping of wrapped assets (chainID => nativeAddress => wrappedAddress)
        mapping(uint16 => mapping(bytes32 => address)) wrappedAssets;

        // Mapping to safely identify wrapped assets
        mapping(address => bool) isWrappedAsset;

        // Mapping of native assets to amount outstanding on other chains
        mapping(address => uint256) outstandingBridged;

        // Mapping of bridge contracts on other chains
        mapping(uint16 => bytes32) bridgeImplementations;
    }
}

contract BridgeState {
    BridgeStorage.State _state;
}

// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

contract BridgeStructs {
    struct Transfer {
        // PayloadID uint8 = 1
        uint8 payloadID;
        // Amount being transferred (big-endian uint256)
        uint256 amount;
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Address of the recipient. Left-zero-padded if shorter than 32 bytes
        bytes32 to;
        // Chain ID of the recipient
        uint16 toChain;
        // Amount of tokens (big-endian uint256) that the user is willing to pay as relayer fee. Must be <= Amount.
        uint256 fee;
    }

    struct AssetMeta {
        // PayloadID uint8 = 2
        uint8 payloadID;
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Number of decimals of the token (big-endian uint256)
        uint8 decimals;
        // Symbol of the token (UTF-8)
        bytes32 symbol;
        // Name of the token (UTF-8)
        bytes32 name;
    }

    struct RegisterChain {
        // Governance Header
        // module: "TokenBridge" left-padded
        bytes32 module;
        // governance action: 1
        uint8 action;
        // governance paket chain id: this or 0
        uint16 chainId;

        // Chain ID
        uint16 emitterChainID;
        // Emitter address. Left-zero-padded if shorter than 32 bytes
        bytes32 emitterAddress;
    }

    struct UpgradeContract {
        // Governance Header
        // module: "TokenBridge" left-padded
        bytes32 module;
        // governance action: 2
        uint8 action;
        // governance paket chain id
        uint16 chainId;

        // Address of the new contract
        bytes32 newContract;
    }
}

// contracts/Structs.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract BridgeToken is BeaconProxy {
    constructor(address beacon, bytes memory data) BeaconProxy(beacon, data) {

    }
}

// contracts/TokenImplementation.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./TokenState.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

// Based on the OpenZepplin ERC20 implementation, licensed under MIT
contract TokenImplementation is TokenState, Context {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint64 sequence_,

        address owner_,

        uint16 chainId_,
        bytes32 nativeContract_
    ) initializer public {
        _state.name = name_;
        _state.symbol = symbol_;
        _state.decimals = decimals_;
        _state.metaLastUpdatedSequence = sequence_;

        _state.owner = owner_;

        _state.chainId = chainId_;
        _state.nativeContract = nativeContract_;
    }

    function name() public view returns (string memory) {
        return string(abi.encodePacked(_state.name, " (Wormhole)"));
    }

    function symbol() public view returns (string memory) {
        return _state.symbol;
    }

    function owner() public view returns (address) {
        return _state.owner;
    }

    function decimals() public view returns (uint8) {
        return _state.decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _state.totalSupply;
    }

    function chainId() public view returns (uint16) {
        return _state.chainId;
    }

    function nativeContract() public view returns (bytes32) {
        return _state.nativeContract;
    }

    function balanceOf(address account_) public view returns (uint256) {
        return _state.balances[account_];
    }

    function transfer(address recipient_, uint256 amount_) public returns (bool) {
        _transfer(_msgSender(), recipient_, amount_);
        return true;
    }

    function allowance(address owner_, address spender_) public view returns (uint256) {
        return _state.allowances[owner_][spender_];
    }

    function approve(address spender_, uint256 amount_) public returns (bool) {
        _approve(_msgSender(), spender_, amount_);
        return true;
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public returns (bool) {
        _transfer(sender_, recipient_, amount_);

        uint256 currentAllowance = _state.allowances[sender_][_msgSender()];
        require(currentAllowance >= amount_, "ERC20: transfer amount exceeds allowance");
        _approve(sender_, _msgSender(), currentAllowance - amount_);

        return true;
    }

    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool) {
        _approve(_msgSender(), spender_, _state.allowances[_msgSender()][spender_] + addedValue_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool) {
        uint256 currentAllowance = _state.allowances[_msgSender()][spender_];
        require(currentAllowance >= subtractedValue_, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender_, currentAllowance - subtractedValue_);

        return true;
    }

    function _transfer(address sender_, address recipient_, uint256 amount_) internal {
        require(sender_ != address(0), "ERC20: transfer from the zero address");
        require(recipient_ != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _state.balances[sender_];
        require(senderBalance >= amount_, "ERC20: transfer amount exceeds balance");
        _state.balances[sender_] = senderBalance - amount_;
        _state.balances[recipient_] += amount_;

        emit Transfer(sender_, recipient_, amount_);
    }

    function mint(address account_, uint256 amount_) public onlyOwner {
        _mint(account_, amount_);
    }

    function _mint(address account_, uint256 amount_) internal {
        require(account_ != address(0), "ERC20: mint to the zero address");

        _state.totalSupply += amount_;
        _state.balances[account_] += amount_;
        emit Transfer(address(0), account_, amount_);
    }

    function burn(address account_, uint256 amount_) public onlyOwner {
        _burn(account_, amount_);
    }

    function _burn(address account_, uint256 amount_) internal {
        require(account_ != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _state.balances[account_];
        require(accountBalance >= amount_, "ERC20: burn amount exceeds balance");
        _state.balances[account_] = accountBalance - amount_;
        _state.totalSupply -= amount_;

        emit Transfer(account_, address(0), amount_);
    }

    function _approve(address owner_, address spender_, uint256 amount_) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");

        _state.allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    function updateDetails(string memory name_, string memory symbol_, uint64 sequence_) public onlyOwner {
        require(_state.metaLastUpdatedSequence < sequence_, "current metadata is up to date");

        _state.name = name_;
        _state.symbol = symbol_;
        _state.metaLastUpdatedSequence = sequence_;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "caller is not the owner");
        _;
    }

    modifier initializer() {
        require(
            !_state.initialized,
            "Already initialized"
        );

        _state.initialized = true;

        _;
    }
}

// contracts/State.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

contract TokenStorage {
    struct State {
        string name;
        string symbol;

        uint64 metaLastUpdatedSequence;

        uint256 totalSupply;
        uint8 decimals;

        mapping(address => uint256) balances;

        mapping(address => mapping(address => uint256)) allowances;

        address owner;

        bool initialized;

        uint16 chainId;
        bytes32 nativeContract;
    }
}

contract TokenState {
    TokenStorage.State _state;
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../Structs.sol";

interface IWormhole is Structs {
    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason);

    function verifyVM(Structs.VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Structs.Signature[] memory signatures, Structs.GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason) ;

    function parseVM(bytes memory encodedVM) external pure returns (Structs.VM memory vm);

    function getGuardianSet(uint32 index) external view returns (Structs.GuardianSet memory) ;

    function getCurrentGuardianSetIndex() external view returns (uint32) ;

    function getGuardianSetExpiry() external view returns (uint32) ;

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool) ;

    function isInitialized(address impl) external view returns (bool) ;

    function chainId() external view returns (uint16) ;

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256) ;
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}