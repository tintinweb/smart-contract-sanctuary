/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// File: @openzeppelin\contracts\utils\introspection\IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: node_modules\@ethereansos\swissknife\contracts\generic\model\ILazyInitCapableElement.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;


interface ILazyInitCapableElement is IERC165 {

    function lazyInit(bytes calldata lazyInitData) external returns(bytes memory initResponse);
    function initializer() external view returns(address);

    event Host(address indexed from, address indexed to);

    function host() external view returns(address);
    function setHost(address newValue) external returns(address oldValue);

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
}

// File: @ethereansos\swissknife\contracts\dynamicMetadata\model\IDynamicMetadataCapableElement.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;


interface IDynamicMetadataCapableElement is ILazyInitCapableElement {

    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);

    function setUri(string calldata newValue) external returns (string memory oldValue);

    function dynamicUriResolver() external view returns(address);
    function setDynamicUriResolver(address newValue) external returns(address oldValue);
}

// File: contracts\core\model\IOrganization.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;


interface IOrganization is IDynamicMetadataCapableElement {

    struct Component {
        bytes32 key;
        address location;
        bool active;
        bool log;
    }

    function keyOf(address componentAddress) external view returns(bytes32);
    function history(bytes32 key) external view returns(address[] memory componentsAddresses);
    function batchHistory(bytes32[] calldata keys) external view returns(address[][] memory componentsAddresses);

    function get(bytes32 key) external view returns(address componentAddress);
    function list(bytes32[] calldata keys) external view returns(address[] memory componentsAddresses);
    function isActive(address subject) external view returns(bool);
    function keyIsActive(bytes32 key) external view returns(bool);

    function set(Component calldata) external returns(address replacedComponentAddress);
    function batchSet(Component[] calldata) external returns (address[] memory replacedComponentAddresses);

    event ComponentSet(bytes32 indexed key, address indexed from, address indexed to, bool active);

    function submit(address location, bytes calldata payload, address restReceiver) external payable returns(bytes memory response);
}

// File: node_modules\@ethereansos\swissknife\contracts\dynamicMetadata\model\IDynamicUriResolver.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;

interface IDynamicUriResolver {
    function resolve(address subject, string calldata plainUri, bytes calldata inputData, address caller) external view returns(string memory);
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX_License_Identifier: MIT

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

// File: node_modules\@ethereansos\swissknife\contracts\lib\GeneralUtilities.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;


library BehaviorUtilities {

    function randomKey(uint256 i) internal view returns (bytes32) {
        return keccak256(abi.encode(i, block.timestamp, block.number, tx.origin, tx.gasprice, block.coinbase, block.difficulty, msg.sender, blockhash(block.number - 5)));
    }

    function calculateProjectedArraySizeAndLoopUpperBound(uint256 arraySize, uint256 start, uint256 offset) internal pure returns(uint256 projectedArraySize, uint256 projectedArrayLoopUpperBound) {
        if(arraySize != 0 && start < arraySize && offset != 0) {
            uint256 length = start + offset;
            if(start < (length = length > arraySize ? arraySize : length)) {
                projectedArraySize = (projectedArrayLoopUpperBound = length) - start;
            }
        }
    }
}

library ReflectionUtilities {

    function read(address subject, bytes memory inputData) internal view returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.staticcall(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function submit(address subject, uint256 value, bytes memory inputData) internal returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.call{value : value}(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function isContract(address subject) internal view returns (bool) {
        if(subject == address(0)) {
            return false;
        }
        uint256 codeLength;
        assembly {
            codeLength := extcodesize(subject)
        }
        return codeLength > 0;
    }

    function clone(address originalContract) internal returns(address copyContract) {
        assembly {
            mstore(
                0,
                or(
                    0x5880730000000000000000000000000000000000000000803b80938091923cF3,
                    mul(originalContract, 0x1000000000000000000)
                )
            )
            copyContract := create(0, 0, 32)
            switch extcodesize(copyContract)
                case 0 {
                    invalid()
                }
        }
    }
}

library BytesUtilities {

    bytes private constant ALPHABET = "0123456789abcdef";

    function asAddress(bytes memory b) internal pure returns(address) {
        if(b.length == 0) {
            return address(0);
        }
        if(b.length == 20) {
            address addr;
            assembly {
                addr := mload(add(b, 20))
            }
            return addr;
        }
        return abi.decode(b, (address));
    }

    function asAddressArray(bytes memory b) internal pure returns(address[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (address[]));
        }
    }

    function asBool(bytes memory bs) internal pure returns(bool) {
        return asUint256(bs) != 0;
    }

    function asBoolArray(bytes memory b) internal pure returns(bool[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bool[]));
        }
    }

    function asBytesArray(bytes memory b) internal pure returns(bytes[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bytes[]));
        }
    }

    function asString(bytes memory b) internal pure returns(string memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string));
        }
    }

    function asStringArray(bytes memory b) internal pure returns(string[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string[]));
        }
    }

    function asUint256(bytes memory bs) internal pure returns(uint256 x) {
        if (bs.length >= 32) {
            assembly {
                x := mload(add(bs, add(0x20, 0)))
            }
        }
    }

    function asUint256Array(bytes memory b) internal pure returns(uint256[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (uint256[]));
        }
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = ALPHABET[uint(uint8(data[i] >> 4))];
            str[3+i*2] = ALPHABET[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

library StringUtilities {

    bytes1 private constant CHAR_0 = bytes1('0');
    bytes1 private constant CHAR_A = bytes1('A');
    bytes1 private constant CHAR_a = bytes1('a');
    bytes1 private constant CHAR_f = bytes1('f');

    function isEmpty(string memory test) internal pure returns (bool) {
        return equals(test, "");
    }

    function equals(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function toLowerCase(string memory str) internal pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }

    function asBytes(string calldata str) internal pure returns(bytes memory toDecode) {
        bytes memory data = abi.encodePacked(str);
        if(data.length == 0 || data[0] != "0" || (data[1] != "x" && data[1] != "X")) {
            return "";
        }
        uint256 start = 2;
        toDecode = new bytes((data.length - 2) / 2);

        for(uint256 i = 0; i < toDecode.length; i++) {
            toDecode[i] = bytes1(_fromHexChar(uint8(data[start++])) + _fromHexChar(uint8(data[start++])) * 16);
        }
    }

    function _fromHexChar(uint8 c) private pure returns (uint8) {
        bytes1 charc = bytes1(c);
        return charc < CHAR_0 || charc > CHAR_f ? 0 : (charc < CHAR_A ? 0 : 10) + c - uint8(charc < CHAR_A ? CHAR_0 : charc < CHAR_a ? CHAR_A : CHAR_a);
    }
}

library Uint256Utilities {
    function asSingletonArray(uint256 n) internal pure returns(uint256[] memory array) {
        array = new uint256[](1);
        array[0] = n;
    }

    function toString(uint256 _i) internal pure returns (string memory) {
        return BytesUtilities.toString(abi.encodePacked(_i));
    }
}

library AddressUtilities {
    function asSingletonArray(address a) internal pure returns(address[] memory array) {
        array = new address[](1);
        array[0] = a;
    }

    function toString(address _addr) internal pure returns (string memory) {
        return _addr == address(0) ? "0x0000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(_addr));
    }
}

library Bytes32Utilities {

    function asSingletonArray(bytes32 a) internal pure returns(bytes32[] memory array) {
        array = new bytes32[](1);
        array[0] = a;
    }

    function toString(bytes32 bt) internal pure returns (string memory) {
        return bt == bytes32(0) ?  "0x0000000000000000000000000000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(bt));
    }
}

library TransferUtilities {
    using ReflectionUtilities for address;

    function balanceOf(address erc20TokenAddress, address account) internal view returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return account.balance;
        }
        return abi.decode(erc20TokenAddress.read(abi.encodeWithSelector(IERC20(erc20TokenAddress).balanceOf.selector, account)), (uint256));
    }

    function allowance(address erc20TokenAddress, address account, address spender) internal view returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return 0;
        }
        return abi.decode(erc20TokenAddress.read(abi.encodeWithSelector(IERC20(erc20TokenAddress).allowance.selector, account, spender)), (uint256));
    }

    function safeApprove(address erc20TokenAddress, address spender, uint256 value) internal {
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).approve.selector, spender, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'APPROVE_FAILED');
    }

    function safeTransfer(address erc20TokenAddress, address to, uint256 value) internal {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
    }

    function safeTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) internal {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).transferFrom.selector, from, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFERFROM_FAILED');
    }
}

// File: node_modules\@ethereansos\swissknife\contracts\generic\impl\LazyInitCapableElement.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;



abstract contract LazyInitCapableElement is ILazyInitCapableElement {
    using ReflectionUtilities for address;

    address public override initializer;
    address public override host;

    constructor(bytes memory lazyInitData) {
        if(lazyInitData.length > 0) {
            _privateLazyInit(lazyInitData);
        }
    }

    function lazyInit(bytes calldata lazyInitData) override external returns (bytes memory lazyInitResponse) {
        return _privateLazyInit(lazyInitData);
    }

    function supportsInterface(bytes4 interfaceId) override external view returns(bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == this.supportsInterface.selector ||
            interfaceId == type(ILazyInitCapableElement).interfaceId ||
            interfaceId == this.lazyInit.selector ||
            interfaceId == this.initializer.selector ||
            interfaceId == this.subjectIsAuthorizedFor.selector ||
            interfaceId == this.host.selector ||
            interfaceId == this.setHost.selector ||
            _supportsInterface(interfaceId);
    }

    function setHost(address newValue) external override authorizedOnly returns(address oldValue) {
        emit Host(oldValue = host, host = newValue);
    }

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) public override virtual view returns(bool) {
        (bool chidlElementValidationIsConsistent, bool chidlElementValidationResult) = _subjectIsAuthorizedFor(subject, location, selector, payload, value);
        if(chidlElementValidationIsConsistent) {
            return chidlElementValidationResult;
        }
        if(subject == host) {
            return true;
        }
        if(!host.isContract()) {
            return false;
        }
        (bool result, bytes memory resultData) = host.staticcall(abi.encodeWithSelector(ILazyInitCapableElement(host).subjectIsAuthorizedFor.selector, subject, location, selector, payload, value));
        return result && abi.decode(resultData, (bool));
    }

    function _privateLazyInit(bytes memory lazyInitData) private returns (bytes memory lazyInitResponse) {
        require(initializer == address(0), "init");
        initializer = msg.sender;
        (host, lazyInitResponse) = abi.decode(lazyInitData, (address, bytes));
        emit Host(address(0), host);
        lazyInitResponse = _lazyInit(lazyInitResponse);
    }

    function _lazyInit(bytes memory) internal virtual returns (bytes memory) {
        return "";
    }

    function _supportsInterface(bytes4 interfaceId) internal virtual view returns (bool);

    function _subjectIsAuthorizedFor(address, address, bytes4, bytes calldata, uint256) internal virtual view returns(bool, bool) {
    }

    modifier authorizedOnly {
        require(_authorizedOnly(), "unauthorized");
        _;
    }

    function _authorizedOnly() internal returns(bool) {
        return subjectIsAuthorizedFor(msg.sender, address(this), msg.sig, msg.data, msg.value);
    }
}

// File: @ethereansos\swissknife\contracts\dynamicMetadata\impl\DynamicMetadataCapableElement.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;




abstract contract DynamicMetadataCapableElement is IDynamicMetadataCapableElement, LazyInitCapableElement {

    string public override plainUri;
    address public override dynamicUriResolver;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory lazyInitResponse) {
        (plainUri, dynamicUriResolver, lazyInitResponse) = abi.decode(lazyInitData, (string, address, bytes));
        lazyInitResponse = _dynamicMetadataElementLazyInit(lazyInitResponse);
    }

    function _supportsInterface(bytes4 interfaceId) internal override view returns(bool) {
        return
            interfaceId == type(IDynamicMetadataCapableElement).interfaceId ||
            interfaceId == this.plainUri.selector ||
            interfaceId == this.uri.selector ||
            interfaceId == this.dynamicUriResolver.selector ||
            interfaceId == this.setUri.selector ||
            interfaceId == this.setDynamicUriResolver.selector ||
            _dynamicMetadataElementSupportsInterface(interfaceId);
    }

    function uri() external override view returns(string memory) {
        return _uri(plainUri, "");
    }

    function setUri(string calldata newValue) external override authorizedOnly returns (string memory oldValue) {
        oldValue = plainUri;
        plainUri = newValue;
    }

    function setDynamicUriResolver(address newValue) external override authorizedOnly returns(address oldValue) {
        oldValue = dynamicUriResolver;
        dynamicUriResolver = newValue;
    }

    function _uri(string memory _plainUri, bytes memory additionalData) internal view returns(string memory) {
        if(dynamicUriResolver == address(0)) {
            return _plainUri;
        }
        return IDynamicUriResolver(dynamicUriResolver).resolve(address(this), _plainUri, additionalData, msg.sender);
    }

    function _dynamicMetadataElementLazyInit(bytes memory lazyInitData) internal virtual returns(bytes memory);

    function _dynamicMetadataElementSupportsInterface(bytes4 interfaceId) internal virtual view returns(bool);
}

// File: contracts\core\impl\Organization.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;




contract Organization is IOrganization, DynamicMetadataCapableElement {
    using ReflectionUtilities for address;

    mapping(bytes32 => address[]) private _history;
    mapping(address => bytes32) public override keyOf;

    mapping(bytes32 => address) public override get;
    mapping(bytes32 => bool) public override keyIsActive;

    constructor(bytes memory lazyInitData) DynamicMetadataCapableElement(lazyInitData) {
    }

    function _dynamicMetadataElementLazyInit(bytes memory lazyInitData) internal virtual override returns(bytes memory) {
        require(host == address(0));
        return abi.encode(_set(abi.decode(lazyInitData, (Component[]))));
    }

    function _dynamicMetadataElementSupportsInterface(bytes4 interfaceId) internal virtual override pure returns(bool) {
        return
            interfaceId == type(IOrganization).interfaceId ||
            interfaceId == this.keyOf.selector ||
            interfaceId == this.history.selector ||
            interfaceId == this.batchHistory.selector ||
            interfaceId == this.get.selector ||
            interfaceId == this.list.selector ||
            interfaceId == this.isActive.selector ||
            interfaceId == this.keyIsActive.selector ||
            interfaceId == this.set.selector ||
            interfaceId == this.batchSet.selector ||
            interfaceId == this.submit.selector;
    }

    function history(bytes32 key) override external view returns(address[] memory componentsAddresses) {
        return _history[key];
    }

    function batchHistory(bytes32[] calldata keys) override external view returns(address[][] memory componentsAddresses) {
        componentsAddresses = new address[][](keys.length);
        for(uint256 i = 0; i < componentsAddresses.length; i++) {
            componentsAddresses[i] = _history[keys[i]];
        }
    }

    function list(bytes32[] calldata keys) override external view returns(address[] memory componentsAddresses) {
        componentsAddresses = new address[](keys.length);
        for(uint256 i = 0; i < componentsAddresses.length; i++) {
            componentsAddresses[i] = get[keys[i]];
        }
    }

    function isActive(address componentAddress) override public view returns(bool) {
        return get[keyOf[componentAddress]] == componentAddress && keyIsActive[keyOf[componentAddress]];
    }

    function set(Component calldata component) override authorizedOnly external returns(address replacedComponentAddress) {
        replacedComponentAddress = _set(component);
    }

    function batchSet(Component[] calldata components) override authorizedOnly external returns (address[] memory replacedComponentAddresses) {
        replacedComponentAddresses =  _set(components);
    }

    function submit(address location, bytes calldata payload, address restReceiver) override authorizedOnly external payable returns(bytes memory response) {
        uint256 oldBalance = address(this).balance - msg.value;
        response = location.submit(msg.value, payload);
        uint256 actualBalance = address(this).balance;
        if(actualBalance > oldBalance) {
            (restReceiver != address(0) ? restReceiver : msg.sender).submit(address(this).balance - oldBalance, "");
        }
    }

    function _subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata, uint256) internal override view returns(bool, bool) {
        if(location == address(this) && selector == this.setHost.selector) {
            return (true, false);
        }
        return (true, isActive(subject));
    }

    function _set(Component[] memory components) private returns(address[] memory replacedComponentAddresses) {
        replacedComponentAddresses = new address[](components.length);
        for(uint256 i = 0; i < components.length; i++) {
            replacedComponentAddresses[i] = _set(components[i]);
        }
    }

    function _set(Component memory component) internal returns(address replacedComponentAddress) {
        require(component.key != bytes32(0), "key");
        if(!component.active || component.location == address(0)) {
            delete keyIsActive[component.key];
        }
        replacedComponentAddress = get[component.key];
        get[component.key] = component.location;
        if(component.location != address(0)) {
            address location = component.location;
            uint256 codeSize;
            assembly {
                codeSize := extcodesize(location)
            }
            require(codeSize != 0, "address");
            keyIsActive[keyOf[component.location] = component.key] = component.active;
            if(component.log) {
                _history[component.key].push(component.location);
            }
        }
        if(component.log) {
            emit ComponentSet(component.key, replacedComponentAddress, component.location, component.active);
        }
    }
}