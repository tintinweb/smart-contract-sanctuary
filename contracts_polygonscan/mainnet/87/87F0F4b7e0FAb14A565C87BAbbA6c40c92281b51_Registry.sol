/**
 *Submitted for verification at polygonscan.com on 2021-11-28
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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


abstract contract IERC20Token is IERC20 {
    function upgrade(uint256 value) public virtual;
}

interface IHermesContract {
    enum Status { Active, Paused, Punishment, Closed }
    function initialize(address _token, address _operator, uint16 _hermesFee, uint256 _minStake, uint256 _maxStake, address payable _routerAddress) external;
    function openChannel(address _party, uint256 _amountToLend) external;
    function getOperator() external view returns (address);
    function getStake() external view returns (uint256);
    function getStatus() external view returns (Status);
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender || _owner == address(0x0), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract FundsRecovery is Ownable, ReentrancyGuard {
    address payable internal fundsDestination;
    IERC20Token public token;

    event DestinationChanged(address indexed previousDestination, address indexed newDestination);

    /**
     * Setting new destination of funds recovery.
     */
    function setFundsDestination(address payable _newDestination) public virtual onlyOwner {
        require(_newDestination != address(0));
        emit DestinationChanged(fundsDestination, _newDestination);
        fundsDestination = _newDestination;
    }

    /**
     * Getting funds destination address.
     */
    function getFundsDestination() public view returns (address) {
        return fundsDestination;
    }

    /**
     * Possibility to recover funds in case they were sent to this address before smart contract deployment
     */
    function claimEthers() public nonReentrant {
        require(fundsDestination != address(0));
        fundsDestination.transfer(address(this).balance);
    }

    /**
       Transfers selected tokens into owner address.
    */
    function claimTokens(address _token) public nonReentrant {
        require(fundsDestination != address(0));
        require(_token != address(token), "native token funds can't be recovered");
        uint256 _amount = IERC20Token(_token).balanceOf(address(this));
        IERC20Token(_token).transfer(fundsDestination, _amount);
    }
}

contract Utils {
    function getChainID() internal view returns (uint256) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }
        return chainID;
    }

    function max(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    function round(uint a, uint m) internal pure returns (uint ) {
        return ((a + m - 1) / m) * m;
    }
}



interface Channel {
    function initialize(address _token, address _dex, address _identityHash, address _hermesId, uint256 _fee) external;
}

contract Registry is FundsRecovery, Utils {
    using ECDSA for bytes32;

    uint256 public lastNonce;
    address payable public dex;     // Any uniswap v2 compatible DEX router address
    uint256 public minimalHermesStake;
    Registry public parentRegistry; // If there is parent registry, we will check for

    struct Implementation {
        address channelImplAddress;
        address hermesImplAddress;
    }
    Implementation[] internal implementations;

    struct Hermes {
        address operator;   // hermes operator who will sign promises
        uint256 implVer;    // version of hermes implementation smart contract
        function() external view returns(uint256) stake;
        bytes url;          // hermes service URL
    }
    mapping(address => Hermes) private hermeses;

    mapping(address => address) private identities;   // key: identity, value: beneficiary wallet address

    event RegisteredIdentity(address indexed identity, address beneficiary);
    event RegisteredHermes(address indexed hermesId, address hermesOperator, bytes ur);
    event HermesURLUpdated(address indexed hermesId, bytes newURL);
    event ConsumerChannelCreated(address indexed identity, address indexed hermesId, address channelAddress);
    event BeneficiaryChanged(address indexed identity, address newBeneficiary);
    event MinimalHermesStakeChanged(uint256 newMinimalStake);

    // Reject any ethers sent to this smart-contract
    receive() external payable {
        revert("Registry: Rejecting tx with ethers sent");
    }

    // We're using `initialize` instead of `constructor` to ensure easy way to deploy Registry into
    // deterministic address on any EVM compatible chain. Registry should be first be deployed using
    // `deployRegistry` scripts and then initialized with wanted token and implementations.
    function initialize(address _tokenAddress, address payable _dexAddress, uint256 _minimalHermesStake, address _channelImplementation, address _hermesImplementation, address payable _parentRegistry) public onlyOwner {
        require(!isInitialized(), "Registry: is already initialized");

        minimalHermesStake = _minimalHermesStake;

        require(_tokenAddress != address(0));
        token = IERC20Token(_tokenAddress);

        require(_dexAddress != address(0));
        dex = _dexAddress;

        // Set initial channel implementations
        setImplementations(_channelImplementation, _hermesImplementation);

        // We set initial owner to be sure
        transferOwnership(msg.sender);

        // Set parent registry, if `0x0` then this is root registry
        parentRegistry = Registry(_parentRegistry);
    }

    function isInitialized() public view returns (bool) {
        return address(token) != address(0);
    }

    // Register provider and open his channel with given hermes
    // _stakeAmount - it's amount of tokens staked into hermes to guarantee incomming channel's balance.
    // _beneficiary - payout address during settlements in hermes channel, if provided 0x0 then will be set to consumer channel address.
    function registerIdentity(address _hermesId, uint256 _stakeAmount, uint256 _transactorFee, address _beneficiary, bytes memory _signature) public {
        require(isActiveHermes(_hermesId), "Registry: provided hermes have to be active");

        // Check if given signature is valid
        address _identity = keccak256(abi.encodePacked(getChainID(), address(this), _hermesId, _stakeAmount, _transactorFee, _beneficiary)).recover(_signature);
        require(_identity != address(0), "Registry: wrong identity signature");

        // Tokens amount to get from channel to cover tx fee and provider's stake
        uint256 _totalFee = _stakeAmount + _transactorFee;
        require(_totalFee <= token.balanceOf(getChannelAddress(_identity, _hermesId)), "Registry: not enought funds in channel to cover fees");

        // Open consumer channel
        _openChannel(_identity, _hermesId, _beneficiary, _totalFee);

        // If stake is provided we additionally are opening channel with hermes (a.k.a provider channel)
        if (_stakeAmount > 0) {
            IHermesContract(_hermesId).openChannel(_identity, _stakeAmount);
        }

        // Pay fee for transaction maker
        if (_transactorFee > 0) {
            token.transfer(msg.sender, _transactorFee);
        }
    }

    // Deploys consumer channel and sets beneficiary as newly created channel address
    function openConsumerChannel(address _hermesId, uint256 _transactorFee, bytes memory _signature) public {
        require(isActiveHermes(_hermesId), "Registry: provided hermes have to be active");

        // Check if given signature is valid
        address _identity = keccak256(abi.encodePacked(getChainID(), address(this), _hermesId, _transactorFee)).recover(_signature);
        require(_identity != address(0), "Registry: wrong channel openinig signature");

        require(_transactorFee <= token.balanceOf(getChannelAddress(_identity, _hermesId)), "Registry: not enought funds in channel to cover fees");

        _openChannel(_identity, _hermesId, address(0), _transactorFee);
    }

    // Allows to securely deploy channel's smart contract without consumer signature
    function openConsumerChannel(address _identity, address _hermesId) public {
        require(isActiveHermes(_hermesId), "Registry: provided hermes have to be active");
        require(!isChannelOpened(_identity, _hermesId), "Registry: such consumer channel is already opened");

        _openChannel(_identity, _hermesId, address(0), 0);
    }

    // Deploy payment channel for given consumer identity
    // We're using minimal proxy (EIP1167) to save on gas cost and blockchain space.
    function _openChannel(address _identity, address _hermesId, address _beneficiary, uint256 _fee) internal returns (address) {
        bytes32 _salt = keccak256(abi.encodePacked(_identity, _hermesId));
        bytes memory _code = getProxyCode(getChannelImplementation(hermeses[_hermesId].implVer));
        Channel _channel = Channel(deployMiniProxy(uint256(_salt), _code));
        _channel.initialize(address(token), dex, _identity, _hermesId, _fee);

        emit ConsumerChannelCreated(_identity, _hermesId, address(_channel));

        // If beneficiary was not provided, then we're going to use consumer channel for that
        if (_beneficiary == address(0)) {
            _beneficiary = address(_channel);
        }

        // Mark identity as registered (only during first channel opening)
        if (!isRegistered(_identity)) {
            identities[_identity] = _beneficiary;
            emit RegisteredIdentity(_identity, _beneficiary);
        }

        return address(_channel);
    }

    function registerHermes(address _hermesOperator, uint256 _hermesStake, uint16 _hermesFee, uint256 _minChannelStake, uint256 _maxChannelStake, bytes memory _url) public {
        require(isInitialized(), "Registry: only initialized registry can register hermeses");
        require(_hermesOperator != address(0), "Registry: hermes operator can't be zero address");
        require(_hermesStake >= minimalHermesStake, "Registry: hermes have to stake at least minimal stake amount");

        address _hermesId = getHermesAddress(_hermesOperator);
        require(!isHermes(_hermesId), "Registry: hermes already registered");

        // Deploy hermes contract (mini proxy which is pointing to implementation)
        IHermesContract _hermes = IHermesContract(deployMiniProxy(uint256(uint160(_hermesOperator)), getProxyCode(getHermesImplementation())));

        // Transfer stake into hermes smart contract
        token.transferFrom(msg.sender, address(_hermes), _hermesStake);

        // Initialise hermes
        _hermes.initialize(address(token), _hermesOperator, _hermesFee, _minChannelStake, _maxChannelStake, dex);

        // Save info about newly created hermes
        hermeses[_hermesId] = Hermes(_hermesOperator, getLastImplVer(), _hermes.getStake, _url);

        // Approve hermes contract to `transferFrom` registry (used during hermes channel openings)
        token.approve(_hermesId, type(uint256).max);

        emit RegisteredHermes(_hermesId, _hermesOperator, _url);
    }

    function getChannelAddress(address _identity, address _hermesId) public view returns (address) {
        bytes32 _code = keccak256(getProxyCode(getChannelImplementation(hermeses[_hermesId].implVer)));
        bytes32 _salt = keccak256(abi.encodePacked(_identity, _hermesId));
        return getCreate2Address(_salt, _code);
    }

    function getHermes(address _hermesId) public view returns (Hermes memory) {
        return isHermes(_hermesId) || !hasParentRegistry() ? hermeses[_hermesId] : parentRegistry.getHermes(_hermesId);
    }

    function getHermesAddress(address _hermesOperator) public view returns (address) {
        bytes32 _code = keccak256(getProxyCode(getHermesImplementation()));
        return getCreate2Address(bytes32(uint256(uint160(_hermesOperator))), _code);
    }

    function getHermesAddress(address _hermesOperator, uint256 _implVer) public view returns (address) {
        bytes32 _code = keccak256(getProxyCode(getHermesImplementation(_implVer)));
        return getCreate2Address(bytes32(uint256(uint160(_hermesOperator))), _code);
    }

    function getHermesURL(address _hermesId) public view returns (bytes memory) {
        return hermeses[_hermesId].url;
    }

    function updateHermesURL(address _hermesId, bytes memory _url, bytes memory _signature) public {
        require(isActiveHermes(_hermesId), "Registry: provided hermes has to be active");

        // Check if given signature is valid
        address _operator = keccak256(abi.encodePacked(address(this), _hermesId, _url, lastNonce++)).recover(_signature);
        require(_operator == hermeses[_hermesId].operator, "wrong signature");

        // Update URL
        hermeses[_hermesId].url = _url;

        emit HermesURLUpdated(_hermesId, _url);
    }

    // ------------ UTILS ------------
    function getCreate2Address(bytes32 _salt, bytes32 _code) internal view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            bytes32(_salt),
            bytes32(_code)
        )))));
    }

    function getProxyCode(address _implementation) public pure returns (bytes memory) {
        // `_code` is EIP 1167 - Minimal Proxy Contract
        // more information: https://eips.ethereum.org/EIPS/eip-1167
        bytes memory _code = hex"3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3";

        bytes20 _targetBytes = bytes20(_implementation);
        for (uint8 i = 0; i < 20; i++) {
            _code[20 + i] = _targetBytes[i];
        }

        return _code;
    }

    function deployMiniProxy(uint256 _salt, bytes memory _code) internal returns (address payable) {
        address payable _addr;

        assembly {
            _addr := create2(0, add(_code, 0x20), mload(_code), _salt)
            if iszero(extcodesize(_addr)) {
                revert(0, 0)
            }
        }

        return _addr;
    }

    function getBeneficiary(address _identity) public view returns (address) {
        if (hasParentRegistry())
            return parentRegistry.getBeneficiary(_identity);

        return identities[_identity];
    }

    function setBeneficiary(address _identity, address _newBeneficiary, bytes memory _signature) public {
        require(_newBeneficiary != address(0), "Registry: beneficiary can't be zero address");

        // Always set beneficiary into root registry
        if (hasParentRegistry()) {
            parentRegistry.setBeneficiary(_identity, _newBeneficiary, _signature);
        } else {
            lastNonce = lastNonce + 1;

            // In signatures we should always use root registry (for backward compatibility)
            address _rootRegistry = hasParentRegistry() ? address(parentRegistry) : address(this);
            address _signer = keccak256(abi.encodePacked(getChainID(), _rootRegistry, _identity, _newBeneficiary, lastNonce)).recover(_signature);
            require(_signer == _identity, "Registry: have to be signed by identity owner");

            identities[_identity] = _newBeneficiary;

            emit BeneficiaryChanged(_identity, _newBeneficiary);
        }
    }

    function setMinimalHermesStake(uint256 _newMinimalStake) public onlyOwner {
        require(isInitialized(), "Registry: only initialized registry can set new minimal hermes stake");
        minimalHermesStake = _newMinimalStake;
        emit MinimalHermesStakeChanged(_newMinimalStake);
    }

    // -------- UTILS TO WORK WITH CHANNEL AND HERMES IMPLEMENTATIONS ---------

    function getChannelImplementation() public view returns (address) {
        return implementations[getLastImplVer()].channelImplAddress;
    }

    function getChannelImplementation(uint256 _implVer) public view returns (address) {
        return implementations[_implVer].channelImplAddress;
    }

    function getHermesImplementation() public view returns (address) {
        return implementations[getLastImplVer()].hermesImplAddress;
    }

    function getHermesImplementation(uint256 _implVer) public view returns (address) {
        return implementations[_implVer].hermesImplAddress;
    }

    function setImplementations(address _newChannelImplAddress, address _newHermesImplAddress) public onlyOwner {
        require(isInitialized(), "Registry: only initialized registry can set new implementations");
        require(isSmartContract(_newChannelImplAddress) && isSmartContract(_newHermesImplAddress), "Registry: implementations have to be smart contracts");
        implementations.push(Implementation(_newChannelImplAddress, _newHermesImplAddress));
    }

    // Version of latest hermes and channel implementations
    function getLastImplVer() public view returns (uint256) {
        return implementations.length-1;
    }

    // ------------------------------------------------------------------------

    function isSmartContract(address _addr) internal view returns (bool) {
        uint _codeLength;

        assembly {
            _codeLength := extcodesize(_addr)
        }

        return _codeLength != 0;
    }

    // If `parentRegistry` is not set, this is root registry and should return false
    function hasParentRegistry() public view returns (bool) {
        return address(parentRegistry) != address(0);
    }

    function isRegistered(address _identity) public view returns (bool) {
        if (hasParentRegistry())
            return parentRegistry.isRegistered(_identity);

        // If we know its beneficiary address it is registered identity
        return identities[_identity] != address(0);
    }

    function isHermes(address _hermesId) public view returns (bool) {
        // To check if it actually properly created hermes address, we need to check if he has operator
        // and if with that operator we'll get proper hermes address which has code deployed there.
        address _hermesOperator = hermeses[_hermesId].operator;
        uint256 _implVer = hermeses[_hermesId].implVer;
        address _addr = getHermesAddress(_hermesOperator, _implVer);
        if (_addr != _hermesId)
            return false; // hermesId should be same as generated address

        return isSmartContract(_addr) || parentRegistry.isHermes(_hermesId);
    }

    function isActiveHermes(address _hermesId) internal view returns (bool) {
        // First we have to ensure that given address is registered hermes and only then check its status
        require(isHermes(_hermesId), "Registry: hermes have to be registered");

        IHermesContract.Status status = IHermesContract(_hermesId).getStatus();
        return status == IHermesContract.Status.Active;
    }

    function isChannelOpened(address _identity, address _hermesId) public view returns (bool) {
        return isSmartContract(getChannelAddress(_identity, _hermesId)) || isSmartContract(parentRegistry.getChannelAddress(_identity, _hermesId));
    }

    function transferCollectedFeeTo(address _beneficiary) public onlyOwner{
        uint256 _collectedFee = token.balanceOf(address(this));
        require(_collectedFee > 0, "collected fee cannot be less than zero");
        token.transfer(_beneficiary, _collectedFee);
    }
}