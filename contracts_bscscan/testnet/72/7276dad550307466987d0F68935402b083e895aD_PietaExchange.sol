// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./AbsPietaExchange.sol";

contract PietaExchange is AbsPietaExchange, Initializable, OwnableUpgradeable,  EIP712Upgradeable, ReentrancyGuardUpgradeable  {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    // using AddressUpgradeable for address;
    
    CountersUpgradeable.Counter private _saleId;

    address private _pietaTokenAddress;
    address private _pietaNftAddress;
    
    mapping (uint256 => OriginInfo) private _originusers; // _originusers[tokenId] = OriginInfo{user, 400000 (<--4%)}
    mapping (uint256 => SaleInfo) private _saleInfos; // _saleInfos[saleId]
    mapping (uint256 => SaleApproveInfo) private _saleAppove; // _saleAppove[saleId]
    mapping (uint256 => uint8) private _tokenSaleStatus; // _tokenSaleStatus[tokenId]
    mapping (uint256 => uint256) private _latestSaleId; // _latestSaleId[tokenId]

    function initialize(address __pietaTokenAddress, address __pietaNftAddress) public initializer {
        __Ownable_init();
        __EIP712_init("PietaExchange", "1");
        __ReentrancyGuard_init();
        setPietaTokenAddress(__pietaTokenAddress);
        setPietaNftAddress(__pietaNftAddress);
    } 

    function setPietaTokenAddress(address _address) public onlyOwner {
        _pietaTokenAddress = _address;
    }

    function setPietaNftAddress(address _address) public onlyOwner {
        _pietaNftAddress = _address;
    }

    function pietaTokenAddress() public override view returns (address) {
        return _pietaTokenAddress;
    }

    function pietaNftAddress() public override view returns (address) {
        return _pietaNftAddress;
    }

    function getSale(uint256 saleId) public override view returns (SaleInfo memory) {
        return _saleInfos[saleId];
    }

    function getSaleApproveInfo(uint256 saleId) public override view returns (SaleApproveInfo memory) {
        return _saleAppove[saleId];
    }
    
    function getLatestSaleId() external override view returns(uint256) {
        return _saleId.current();
    }

    function getSaleStatus(uint256 saleId) public view returns (uint8) {
        SaleInfo storage saleInfo = _saleInfos[saleId];
        if(_latestSaleId[saleInfo.tokenId] != saleId || saleInfo.expire < block.timestamp) {
            return SALESTATUS_EXPIRED;
        } else {
            return _tokenSaleStatus[saleInfo.tokenId];
        }
    }

    function getOriginInfo(uint256 tokenId) public override view returns (OriginInfo memory)  {
        return _originusers[tokenId];
    }

    function saleApprove(uint256 saleId, address toAddress, uint256 amount) public override returns(bool) {
        SaleInfo storage saleInfo = _saleInfos[saleId];
        require(saleInfo.maker != address(0), 'ER1');
        require(saleInfo.maker == _msgSender(), 'ER2');
        require(saleInfo.tradeMethod == TRADEMETHOD_BID, 'ER3');
        require(_tokenSaleStatus[saleInfo.tokenId] == SALESTATUS_ONSALE, 'ER4');


        uint8 status = getSaleStatus(saleId);
        require(status != SALESTATUS_EXPIRED, 'ER5');
        
        _saleAppove[saleId] = SaleApproveInfo(toAddress, amount);
        _tokenSaleStatus[saleInfo.tokenId] = SALESTATUS_APPROVE;
        emit SaleApprove(saleId, saleInfo.maker, toAddress, amount);
        return true;
    }

    modifier validSaleInfo(uint256 saleId, uint8 payType) {
        SaleInfo storage saleInfo = _saleInfos[saleId];
        require(saleInfo.maker != address(0), 'ER1');
        require(saleInfo.maker != _msgSender(), 'ER2');
        require(saleInfo.payType == payType, 'ER3');
        uint8 status = getSaleStatus(saleId);
        require(status != SALESTATUS_EXPIRED, 'ER4');
        require( 
                (saleInfo.tradeMethod == TRADEMETHOD_DIRECT && status == SALESTATUS_ONSALE)
            ||  (saleInfo.tradeMethod == TRADEMETHOD_BID && status == SALESTATUS_APPROVE),
            'ER5');
        _;
    }


    function buyByEth(uint256 saleId) public payable override nonReentrant validSaleInfo(saleId,  PAYTYPE_ETH) returns(bool) {        
        SaleInfo storage saleInfo = _saleInfos[saleId];
        SaleApproveInfo storage saleApproveInfo = _saleAppove[saleId];
        // Condition TradeMethod == BID 
        require(saleInfo.tradeMethod == TRADEMETHOD_DIRECT
            ||  (saleInfo.tradeMethod == TRADEMETHOD_BID && saleApproveInfo.buyer == _msgSender()),
            'ER1');

        // Condition TradeMethod == BID 
        require(saleInfo.tradeMethod == TRADEMETHOD_DIRECT
            || (saleInfo.tradeMethod == TRADEMETHOD_BID && saleApproveInfo.amount == msg.value),
            'ER2');

        // Condition TradeMethod == DIRECT 
        require(saleInfo.tradeMethod == TRADEMETHOD_BID
            || (saleInfo.tradeMethod == TRADEMETHOD_DIRECT && saleInfo.minOrAskPrice == msg.value),
            'ER3');

        // 구매자에게 erc721 token 전송
        _transferErc721(saleInfo.maker, _msgSender(), saleInfo.tokenId);

        OriginInfo storage originInfo = _originusers[saleInfo.tokenId];

        if(saleInfo.maker == originInfo.owner) { // 원작자 판매자 같으면 총 금액 전송
            (bool success, ) = payable(saleInfo.maker).call{value: msg.value}("");
            require(success, 'ER4');
            _tokenSaleStatus[saleInfo.tokenId] = SALESTATUS_COMPLETE;
            emit SaleComplete(saleId, saleInfo.maker, _msgSender(), msg.value, 0);
            return success;
        } else {
            uint256 royalties = msg.value * originInfo.royalties / (10 ** 7); // decimals 5 + percentage 2... pow 7
            uint256 receiveAmount = msg.value - royalties;

            // 판매자에게 이더 전송        
            (bool success1, ) = payable(saleInfo.maker).call{value: receiveAmount}("");
            // 원작자에게 이더 전송
            (bool success2, ) = payable(originInfo.owner).call{value: royalties}("");
            require(success1 && success2, 'ER5');
            
            _tokenSaleStatus[saleInfo.tokenId] = SALESTATUS_COMPLETE;
            emit SaleComplete(saleId, saleInfo.maker, _msgSender(), receiveAmount, royalties);
            return success1 && success2;
        }
    }

    function buyByToken(uint256 saleId, uint256 tokenAmount) public override nonReentrant validSaleInfo(saleId, PAYTYPE_TOKEN) returns(bool) {
        SaleInfo storage saleInfo = _saleInfos[saleId];
        SaleApproveInfo storage saleApproveInfo = _saleAppove[saleId];

        // Condition TradeMethod == BID 
        require(saleInfo.tradeMethod == TRADEMETHOD_DIRECT
            ||  (saleInfo.tradeMethod == TRADEMETHOD_BID && saleApproveInfo.buyer == _msgSender()),
            'ER1');

        // Condition TradeMethod == BID 
        require(saleInfo.tradeMethod == TRADEMETHOD_DIRECT
            || (saleInfo.tradeMethod == TRADEMETHOD_BID && saleApproveInfo.amount == tokenAmount),
            'ER2');

        // Condition TradeMethod == DIRECT 
        require(saleInfo.tradeMethod == TRADEMETHOD_BID
            || (saleInfo.tradeMethod == TRADEMETHOD_DIRECT && saleInfo.minOrAskPrice == tokenAmount),
            'ER3');


        uint256 allowance = _tokenAllowance(_msgSender());
        require(allowance >= tokenAmount, 'ER4');

        _transferErc721(saleInfo.maker, _msgSender(), saleInfo.tokenId);

        OriginInfo storage originInfo = _originusers[saleInfo.tokenId];

        if(saleInfo.maker == originInfo.owner) { // 원작자 판매자 같으면 총 금액 전송
            require(_transferErc20(_msgSender(), saleInfo.maker, tokenAmount), 'ER4');
            _tokenSaleStatus[saleInfo.tokenId] = SALESTATUS_COMPLETE;
            emit SaleComplete(saleId, saleInfo.maker, _msgSender(), tokenAmount, 0);
            return true;

        } else {
            uint256 royalties = tokenAmount * originInfo.royalties / (10 ** 7); // decimals 5 + percentage 2... pow 7
            uint256 receiveAmount = tokenAmount - royalties;
            require(_transferErc20(_msgSender(), saleInfo.maker, receiveAmount), 'ER5');
            require(_transferErc20(_msgSender(), originInfo.owner, royalties), 'ER6');
            _tokenSaleStatus[saleInfo.tokenId] = SALESTATUS_COMPLETE;
            emit SaleComplete(saleId, saleInfo.maker, _msgSender(), receiveAmount, royalties);
            return true;
        }
    }

    function cancel(uint256 saleId) public override returns(bool) {
        SaleInfo storage saleInfo = _saleInfos[saleId];
        require(saleInfo.maker != address(0), 'ER1');

        require(saleInfo.maker == _msgSender(), 'ER2');
        uint8 status = _tokenSaleStatus[saleInfo.tokenId];
        require(status == SALESTATUS_ONSALE, 'ER3');

        _tokenSaleStatus[saleInfo.tokenId] = SALESTATUS_CANCEL;
        emit SaleCancel(saleId, saleInfo.maker);
        return true;
    }

    function verifyMessage(bytes memory singmessag, 
        address maker,
        uint256 tokenId,
        uint8 tradeMethod,
        uint8 payType,
        uint256 minOrAskPrice, 
        uint32 expire,
        uint32 royalties) internal view returns(bool) {

        bytes32 eip712DomainHash = _domainSeparatorV4();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("create(address maker,uint256 tokenId,uint8 tradeMethod,uint8 payType,uint256 minOrAskPrice,uint32 expire,uint32 royalties)"),
                maker,
                tokenId,
                tradeMethod,
                payType,
                minOrAskPrice,
                expire,
                royalties
            )
        );
        bytes32 dataHash = ECDSAUpgradeable.toTypedDataHash(eip712DomainHash, structHash);

        address recoverAddress = ECDSAUpgradeable.recover(dataHash, singmessag);
        return recoverAddress == maker;
    }

    function saleRegister(bytes memory signmessag, 
        address maker,
        uint256 tokenId,
        uint8 tradeMethod,
        uint8 payType,
        uint256 minOrAskPrice, 
        uint32 expire,
        uint32 royalties) public override nonReentrant returns(uint256)  {

        // 서명 검증
        require(verifyMessage(signmessag, maker, tokenId, tradeMethod, payType, minOrAskPrice, expire, royalties), 
                'ER1');

        // 토큰이 maker의 소유, 컨트랙트 승인. 체크
        require(_tokenValidator(maker, tokenId), 
                'ER2');
        uint8 status = _tokenSaleStatus[tokenId];

        bool available = false;
        if(status == SALESTATUS_ONSALE || status == SALESTATUS_APPROVE) { // 판매중..
            uint256 latestSaleId = _latestSaleId[tokenId];
            if(latestSaleId > 0) {
                if(block.timestamp > _saleInfos[latestSaleId].expire) {
                    available = true;
                    emit SaleExpired(latestSaleId);
                }
            }
        } else {
            available = true;
        }
        // 현재 같은 토큰이 판매 중인지 체크
        require(available
            , 'ER3');

        _saleId.increment();


        _saleInfos[_saleId.current()] = SaleInfo(
            maker,
            tokenId,
            tradeMethod,
            payType,
            minOrAskPrice,
            expire
        );
        _tokenSaleStatus[tokenId] = SALESTATUS_ONSALE;
        _latestSaleId[tokenId] = _saleId.current();

        // 최초 등록한 사람. 로얄티
        if(_originusers[tokenId].owner == address(0)) {
            _originusers[tokenId] = OriginInfo(
                maker,
                royalties
            );
        }

        // _saleIdByUserToken[]
        emit SaleCreated(_saleId.current(), maker, tokenId);
        return _saleId.current();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

abstract contract AbsPietaExchange {

    using AddressUpgradeable for address;
    
    event SaleCreated(uint256 indexed saleId, address indexed maker, uint256 indexed tokenId);
    event SaleApprove(uint256 indexed saleId, address indexed maker, address indexed buyer, uint256 amount);
    event SaleComplete(uint256 indexed saleId, address indexed maker, address indexed buyer, uint256 saleAmount, uint256 royalties);
    event SaleCancel(uint256 indexed saleId, address indexed maker);
    event SaleExpired(uint256 indexed saleId);
    
    
    // enum PayType {
    //     TOKEN,
    //     ETH
    // }

    // enum TradeMethod {
    //     BID,
    //     DIRECT
    // }

    // enum SaleStatus {
    //     None,
    //     OnSale,
    //     Approve,
    //     Complete,
    //     Cancel,
    //     Expired
    // }

    uint8 constant PAYTYPE_TOKEN  = 0;
    uint8 constant PAYTYPE_ETH  = 1;

    
    uint8 constant TRADEMETHOD_BID  = 0;
    uint8 constant TRADEMETHOD_DIRECT  = 1;

    uint8 constant SALESTATUS_NONE = 0;
    uint8 constant SALESTATUS_ONSALE = 1;
    uint8 constant SALESTATUS_APPROVE = 2;
    uint8 constant SALESTATUS_COMPLETE = 3;
    uint8 constant SALESTATUS_CANCEL = 4;
    uint8 constant SALESTATUS_EXPIRED = 5;




    struct OriginInfo {
        address owner;
        uint32 royalties; // decimals 5
    }
    

    struct SaleInfo {
        address maker;
        uint256 tokenId;
        uint8 tradeMethod;
        uint8 payType;
        uint256 minOrAskPrice;
        uint32 expire;
    }

    struct SaleApproveInfo {
        address buyer;
        uint256 amount;
    }

    function saleRegister(bytes memory singmessag, 
        address maker,
        uint256 tokenId,
        uint8 tradeMethod,
        uint8 payType,
        uint256 minOrAskPrice, 
        uint32 expire,
        uint32 royalties) public virtual returns(uint256);
    
    function saleApprove(uint256 saleId, address toAddress, uint256 amount) public virtual returns(bool);

    function buyByEth(uint256 saleId) public payable virtual returns(bool);

    function buyByToken(uint256 saleId, uint256 tokenAmount) public virtual returns(bool);

    function cancel(uint256 saleId) public virtual returns(bool);

    function getOriginInfo(uint256 tokenId) public view virtual returns (OriginInfo memory);

    function getSale(uint256 saleId) public virtual view returns (SaleInfo memory);

    function getLatestSaleId() external virtual view returns(uint256);

    function getSaleApproveInfo(uint256 saleId) public virtual view returns (SaleApproveInfo memory);


    function pietaTokenAddress() public view  virtual returns (address);

    function pietaNftAddress() public view virtual returns (address);

    function _transferErc721(address from, address to, uint256 tokenId) internal  {
        bytes memory safeTransferPayload = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)"
                                            , from, to, tokenId);
        pietaNftAddress().functionCall(safeTransferPayload);
    }

    function _transferErc20(address from, address to, uint256 amount) internal returns(bool) {
        bytes memory transferPayload = abi.encodeWithSignature("transferFrom(address,address,uint256)"
                                            , from, to, amount);
        bytes memory result = pietaTokenAddress().functionCall(transferPayload);
        bool r = abi.decode(result, (bool));
        return r;
    }


    function _tokenAllowance(address owner) internal view returns (uint256) {
        bytes memory allowancePayload = abi.encodeWithSignature("allowance(address,address)", owner, address(this));
        bytes memory allowanceResult = pietaTokenAddress().functionStaticCall(allowancePayload);
        uint256 amount = abi.decode(allowanceResult, (uint256));
        return amount;
    }

    function _tokenValidator(address maker, uint256 tokenId) internal view returns (bool) {
        bytes memory isApprovedForAllPayLoad = abi.encodeWithSignature("isApprovedForAll(address,address)", maker, address(this));
        bytes memory approvedResult = pietaNftAddress().functionStaticCall(isApprovedForAllPayLoad);
        bool isApproved = abi.decode(approvedResult, (bool));
        

        bytes memory ownerOfPayload = abi.encodeWithSignature("ownerOf(uint256)", tokenId);
        bytes memory ownerOfResult = pietaNftAddress().functionStaticCall(ownerOfPayload);
        address tokenOwner = abi.decode(ownerOfResult, (address));
        
        return isApproved && maker == tokenOwner;
    }

    



}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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