// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IDiaoBox {
    function setShop(address shop, bool enabled) external;

    function mint(address to, uint256 packageId) external;

    function open(uint256 packageId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./IERC721.sol";

interface IDiaoTotem is IERC721 {
    function mint(address owner, uint256 id) external;

    function burn(uint256 tokenId) external;

    function setKarmaBase(uint256 race, uint256 _base) external;

    function getKarmaBase(uint256 race) external view returns (uint256);

    function setKarmaBuff(uint256 rarety, uint256 buff) external;

    function getKarmaBuff(uint256 rarety) external view returns (uint256);

    function parseTokenId(uint256 tokenId)
        external
        pure
        returns (
            uint256 race,
            uint256 design,
            uint256 rarety,
            uint256 index
        );

    function buildNewTokenId(
        uint256 race,
        uint256 rarety,
        uint256 design,
        uint256 index
    ) external pure returns (uint256);

    function setOriginalSupply(uint256 rarety, uint256 supply) external;

    function getOriginalSupply(uint256 rarety) external view returns (uint256);

    function setWarshipBuff(uint256 tokenId, uint256 buff) external;

    function getWarshipBuff(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.0;

/// @title 不可分割代币标准
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// Note: ERC165标识符为0x80ac58cd

interface IERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface INonce {
    function getNonce(address token, address owner)
        external
        view
        returns (uint256);

    function setNonce(
        address token,
        address owner,
        uint256 nonce
    ) external;

    function getNonceKey(address token, address owner)
        external
        pure
        returns (bytes32);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;


library Address {
    // 该方法目的是为了防止合约调用方法.但合约构造时codesize为0,所以不能总是符合预期
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));

        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
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
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles:account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.7.0;

library UintLibrary {
    function toString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }
}

library String {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b)
        internal
        pure
        returns (string memory)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);

        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory babc = new bytes(_ba.length + _bb.length + _bc.length);

        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babc[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babc[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babc[k++] = _bc[i];

        return string(babc);
    }

    function equals(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);

        uint256 la = ba.length;
        uint256 lb = bb.length;

        for (uint256 i = 0; i != la && i != lb; ++i) {
            if (ba[i] != bb[i]) {
                return false;
            }
        }

        return la == lb;
    }

    function toSigHash(string memory message) internal pure returns (bytes32) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0),
            new bytes(0),
            new bytes(0),
            new bytes(0)
        );
        return keccak256(fullMessage);
    }

    function concat(
        bytes memory _ba,
        bytes memory _bb,
        bytes memory _bc,
        bytes memory _bd,
        bytes memory _be,
        bytes memory _bf,
        bytes memory _bg
    ) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(
            _ba.length +
                _bb.length +
                _bc.length +
                _bd.length +
                _be.length +
                _bf.length +
                _bg.length
        );

        uint256 k = 0;

        for (uint256 i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint256 i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint256 i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];

        return resultBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../role/Ownable.sol";

contract Manager is Ownable {
    /// Oracle=>"Oracle"

    mapping(string => address) public members;

    mapping(address => mapping(string => bool)) public permits; //地址是否有某个权限

    function setMember(string memory name, address member) external onlyOwner {
        members[name] = member;
    }

    function setUserPermit(
        address user,
        string calldata permit,
        bool enable
    ) external onlyOwner {
        permits[user][permit] = enable;
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Manager.sol";

abstract contract Member is Ownable {
    //检查权限
    modifier CheckPermit(string memory permit) {
        require(manager.permits(msg.sender, permit), "no permit");
        _;
    }

    Manager public manager;

    function getMember(string memory _name) public view returns (address) {
        return manager.members(_name);
    }

    function setManager(address addr) external onlyOwner {
        manager = Manager(addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../lib/Role.sol";
import "./Ownable.sol";

contract OperatorRole is Context {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private _operators;

    modifier onlyOperator() {
        require(
            isOperator(_msgSender()),
            "OperatorRole: caller does not have the operator role"
        );
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
    }
}

contract OwnableOperatorRole is Ownable, OperatorRole {
    function addOperator(address account) public onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) public onlyOwner {
        _removeOperator(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./TotemShop.sol";

contract FirstShop is TotemShop {
    constructor(uint256 price, string memory _uri) TotemShop(1, price, _uri) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../role/Member.sol";
import "../role/OwnableOperatorRole.sol";
import "../utils/SignHelper.sol";

import "../interface/IDiaoTotem.sol";
import "../interface/IDiaoBox.sol";
import "../interface/IERC20.sol";
import "../interface/IERC721.sol";
import "../interface/INonce.sol";
import "../lib/ECDSA.sol";
import "../lib/String.sol";
import "../lib/Address.sol";

/// @title 盲盒售卖机
/// @author BrefChan
/// @notice 负责盲盒的售卖以及相关的辅助功能
abstract contract TotemShop is Member, OwnableOperatorRole, SignHelper {
    uint256 public period;
    uint256 public price;
    uint256[] public awards;
    uint256 public awardsAmount;
    uint256 public sellAmount;
    uint256 public sellCap = 0;

    string public packageURI;

    constructor(
        uint256 _period,
        uint256 _price,
        string memory _uri
    ) {
        period = _period;
        price = _price;
        packageURI = _uri;
    }

    function changeSellCap(uint256 _cap) external CheckPermit("Config") {
        sellCap = _cap;
    }

    function recoverERC20(
        address erc20,
        uint256 amount,
        address recoverMan
    ) external CheckPermit("Config") {
        if (erc20 == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(erc20).transferFrom(address(this), recoverMan, amount);
        }
    }

    function recoverERC721(
        address erc721,
        uint256 tokenId,
        address recoverMan
    ) external CheckPermit("Config") {
        IERC721(erc721).safeTransferFrom(address(this), recoverMan, tokenId);
    }

    function buy(
        address _buyer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(msg.value >= price, "Wrong Price");
        require(sellAmount < sellCap, "Has been sold out");
        // Check Sig
        INonce nonce = INonce(getMember("Nonce"));
        address totemAddress = getMember("DiaoTotem");
        uint256 nonceValue = nonce.getNonce(totemAddress, _buyer);
        nonce.setNonce(totemAddress, _buyer, nonceValue + 1);
        string memory signMessage = prepareMessage(
            totemAddress,
            _buyer,
            period,
            nonceValue
        );

        require(
            isOperator(recover(signMessage, v, r, s)),
            "signature is wrong"
        );

        uint256 buybackAmount = msg.value / 4;
        uint256 remainAmount = msg.value - buybackAmount;
        address buybackAddress = getMember("BuyBack");
        address cashAddress = getMember("Cash");

        payable(buybackAddress).transfer(buybackAmount);
        payable(cashAddress).transfer(remainAmount);

        IDiaoBox diaoBox = IDiaoBox(getMember("DiaoBox"));
        sellAmount++;
        uint256 packageId = period * 10**6 + sellAmount;
        diaoBox.mint(_buyer, packageId);
    }

    function addAwards(uint256[] memory array) public CheckPermit("Config") {
        for (uint256 index = 0; index < array.length; index++) {
            awards.push(array[index]);
        }
        awardsAmount += array.length;
        sellCap += array.length;
    }

    function setAwards(uint256[] memory array) public CheckPermit("Config") {
        awards = array;
        awardsAmount = array.length;
        sellCap = array.length;
    }

    /// @notice 从奖励池中移除指定下标的奖励token
    /// @dev 外部调用,仅由管理员调用
    /// @param index 需要移除的奖励的指定下标
    function removeAwards(uint256 index) external CheckPermit("Config") {
        _removeAwards(index);
    }

    /// @notice 从奖励池中移除指定下标的奖励token
    /// @dev 内部调用
    /// @param index 需要移除的奖励的指定下标
    function _removeAwards(uint256 index) internal {
        awards[index] = awards[awardsAmount - 1];
        awards.pop();
        awardsAmount -= 1;
    }

    /// @notice 移除所有奖励池里的token数据
    /// @dev 仅由管理员调用,注意:只是清除数据,并不会转移
    function removeAllAwards() external CheckPermit("Config") {
        delete awards;
        awardsAmount = 0;
    }

    function getAwardArray() external view returns (uint256[] memory) {
        return awards;
    }

    /// @notice 获取当前售卖机的期数
    /// @return 返回当前的期数
    function getPeriod() public view returns (uint256) {
        return period;
    }

    /// @notice 获取当前售卖机中的卡包的TokenURI
    /// @dev 每一期的售卖机售卖的卡包URI都可以是不同的,所以卡包的URI由售卖机合约维护
    /// @return 返回当前售卖机维护的TokenURI
    function getPackageURI() public view returns (string memory) {
        return packageURI;
    }

    /// @notice 卡包开启的辅助方法,会计算开启卡包后获得的Token,并转移给卡包的拥有者
    /// @dev 仅由拥有开启卡包权限的角色调用(目前仅为卡包合约)
    /// @param bh 指定区块的blockhash,用作随机数种子
    /// @return 随机出来的Totem TokenId
    function onOpenPackage(address, bytes32 bh)
        external
        CheckPermit("OpenPackage")
        returns (uint256)
    {
        uint256 randomIndex = randomUint(abi.encode(bh), 0, awardsAmount - 1);
        uint256 awardTokenId = awards[randomIndex];
        _removeAwards(randomIndex);
        return awardTokenId;
    }

    /// @notice 随机数方法
    /// @dev 仅合约内部调用
    /// @param seed 随机数种子
    /// @param min 随机数区间最小值
    /// @param max 随机数区间最大值
    /// @return 随机出来的结果
    function randomUint(
        bytes memory seed,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256) {
        if (min >= max) {
            return min;
        }

        uint256 number = uint256(keccak256(seed));
        return (number % (max - min + 1)) + min;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../lib/ECDSA.sol";
import "../lib/String.sol";
import "../lib/Address.sol";

contract SignHelper {
    using ECDSA for bytes32;
    using String for string;
    using Address for address;
    using UintLibrary for uint256;

    function recover(
        string memory signMessage,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        return signMessage.toSigHash().recover(v, r, s);
    }

    function prepareMessage(
        address addressOne,
        address addressTwo,
        uint256 uintOne,
        uint256 _nonce
    ) internal pure returns (string memory) {
        string memory result = string(
            strConcat(
                bytes(addressOne.toString()),
                bytes(". addressTwo: "),
                bytes(addressTwo.toString()),
                bytes(". uintOne: "),
                bytes(uintOne.toString()),
                bytes(". nonce: "),
                bytes(_nonce.toString())
            )
        );

        return result;
    }

    function strConcat(
        bytes memory _ba,
        bytes memory _bb,
        bytes memory _bc,
        bytes memory _bd,
        bytes memory _be,
        bytes memory _bf,
        bytes memory _bg
    ) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(
            _ba.length +
                _bb.length +
                _bc.length +
                _bd.length +
                _be.length +
                _bf.length +
                _bg.length
        );

        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint256 i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint256 i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];

        return resultBytes;
    }
}

