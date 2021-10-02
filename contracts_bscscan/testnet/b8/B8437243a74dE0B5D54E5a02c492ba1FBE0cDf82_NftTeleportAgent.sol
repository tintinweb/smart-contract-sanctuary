/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: MIT

// Aye there, human behind the electronic device!
// Scotty's on the line. Where you may see a silly hamster,
// others see a miracle worker, a captain by rank,
// and an engineer by calling.
// I have spent my whole life
// trying to figure out crazy ways of doing things.
// Now my duty is to maintain and operate the NFT Transporter,
// which can beam your precious NFTs from Ethereum to the Binance Smart Chain
// and other way around. Wee bit tricky, but I can show you how it works.
// Ready?
// All right, you lovelies, hold together!


// &&&&&&&%%&&&&&&&&&&&&&&&&&&&&&&&&&%&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%&%%%&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%&&&&&&
// &&&&%&&&&&&&&&&&&&&&&&&&&&&&&&%&&&&&&%##(((#%&&&&&&&&&%%%%%%%%%%%%%%%%%%%&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&/*//////////////****/*/,.(%%%%&%%%%%%%%%%%%%&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&(*///////////////////****,*,***//*.%%%%%%%%%%%%%%&&&&&&&&
// &&&&&&&&&&&&&&&&&&&%/////////////((((((((((///////***///((((*/&%%%%%%%%&&&&&&%&%
// &&&&&&&&&&&&&&&&&///////////(((((((((((((##(#####((((((((((((((,#%%%%%&&&&&&%%%%
// &&&&&&&&&&&&&&&/////////((/(((((((####################(###(((((((*(%%&%&&&&&%%%%
// &&&&&&&&&&&&&///////******/((#(############%%%########(//**/(####(#*%&&&&&%%%%%%
// &&&&&&&&&&&%//////(*,,**,,/*/####(//********//(#%%###*//,*,*,*(###(##,&&&%%%%%%%
// &&&&&&&%&&#/(///((((/,,,,,,/////******************/(/(,*****,/########.&%%%&%%%%
// &&&&&&&&&#/(((((((((((#//,/**//***********************(,,,,(###########,&%%%%%&%
// &&&&&&&&&/(((((((((((####/////**************************(%%%%####%%%%###*&%%%%%%
// &&&&&&&&(((((((((((#####(*////*****/((((***********/((#((/#%%%%%%%%%%###*%%%%%%%
// &&&&&&&&/(((((((((#####(*////***/(////////#******(/////////(%%%%%%%%#####(%%%%%%
// &&&&&&&&/(((((((######(*////***/.   .*(#((*(****/,     */   #%#%%%%#((((#/%%%%%%
// &&&&&%&&(((((((######//////*****/          (*****(         /%%%%%%#(////((%%%&&&
// &&&&&&&&/((((######///////*******/(      (/********(,    /(*/%%%%%##(((((#%&&&%%
// &&&&&&&&#(#######(*//////*****************/*(####(***********/%%%%%%%%%%(&&&%%%%
// &&&&&&&&&/#######/*//////********************/**/************//%%%%%%%%#&&&&%%%%
// &&&&&&&&&&/######////////********************(*/*(*************#%%%%%%%%&%&&&%%%
// &&&&&&&&&&&/#####////////**************************************#%%%%%%&&&&&%%%%%
// &&&&&#&&&&&&#(##%#////////************************************(%%%%%%&&&&&&&&&&%
// &&&&&&&&&&&&&&/#%%%(////////*********************************(&%%%%&&&&&&&#&&&&&
// &&&&&&&&&&&&&&&&/(%&&(////////*****************************(%%%&#&&&&&&&&&&%&&&&
// &&&&&&&&&&&&&&&%###*&&&&((///////**********************/#%&&&%%&&&&&&&&&&&&&&&&%
// &&&&&&&&&&&&&&########*%@@@&(/(((/////*********//(((#@@@###%&&%&&&&&%%%&%&&&%%%%
// &&&&&&&&&&&&%############%//@@@@@@@@&#(//////(&@@@@@@#/#%##%&&&&&&&&%%%&&&%%%%%%
// &&&&&&&&&&&%###################%#//(#%%&&&&%%##%&@&#######%#%%&%&&%&&&&%%&&&%&%%
// &%&&&&&&&&&%###########################&@@@@@@@@%############%##%%&&&&%%%%%%%%%%
// &&&&&&&&&&%#############%%%%###############%@@&########((#####%######%%%%%&&&%%%

//  ____                         __  __        _   _          ____            _   _         _ 
// | __ )  ___  __ _ _ __ ___   |  \/  | ___  | | | |_ __    / ___|  ___ ___ | |_| |_ _   _| |
// |  _ \ / _ \/ _` | '_ ` _ \  | |\/| |/ _ \ | | | | '_ \   \___ \ / __/ _ \| __| __| | | | |
// | |_) |  __/ (_| | | | | | | | |  | |  __/ | |_| | |_) |   ___) | (_| (_) | |_| |_| |_| |_|
// |____/ \___|\__,_|_| |_| |_| |_|  |_|\___|  \___/| .__( ) |____/ \___\___/ \__|\__|\__, (_)
//                                                  |_|  |/                           |___/   

pragma solidity =0.8.4;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721Transfer {
    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

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
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/*
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
}

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
     * @dev Initializes the contract setting the initial owner.
     */
    function initializeOwnable(address ownerAddr_) internal {
        _setOwner(ownerAddr_);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
        // solhint-disable-next-line no-inline-assembly
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
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
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
    function _beforeFallback() internal virtual {
    }
}

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract ERC1967Proxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if (_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967Proxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

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

interface INftMintBurn {
    function initialize(string calldata name, string calldata symbol, address owner) external;
    function mintTo(address recipient, uint256 tokenId, string calldata tokenUri) external returns (bool);
    function burn(uint256 tokenId) external returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

struct OriginalToken {
    uint256 chainId;
    address addr;
}

struct NftToken {
    uint tokenId;
    string tokenURI;
}

contract NftTeleportAgent is Ownable, Initializable {

    mapping(uint256/*fromChainId*/ => mapping(uint256/*fromChainTeleportId*/ => bool/*finished*/)) public finishedTeleports;
    mapping(uint256/*original chain id*/ => mapping(address/*original token address*/ => address/*wrapped token address*/)) public originalToWrappedTokens;
    mapping(address/*wrapped token address*/ => OriginalToken) public wrappedToOriginalTokens;

    address public signOwner;
    address public feeOwner;
    address public wrappedTokenImplementation;

    uint256 public teleportIdGenerator;
    uint256 public teleportBaseFee;
    uint256 public teleportSingleTokenFee;

    bytes4 private constant INTERFACE_ID_ERC_721_METADATA = 0x5b5e139f;

    string private constant ERROR_ALREADY_EXECUTED = "already executed";
    string private constant ERROR_MINT_FAILED = "mint failed";

    event SetSignOwner(
        address indexed oldValue,
        address indexed newValue);

    event SetFeeOwner(
        address indexed oldValue,
        address indexed newValue);

    event SetTeleportBaseFee(
        uint256 oldValue,
        uint256 newValue);

    event SetTeleportSingleTokenFee(
        uint256 oldValue,
        uint256 newValue);

    event WrappedTokenCreated(
        address indexed sponsor,
        uint256 originalTokenChainId,
        address indexed originalTokenAddr,
        address indexed wrappedTokenAddr,
        string name,
        string symbol);

    event TeleportStarted(
        uint256 teleportId,
        address indexed sender,
        uint256 originalTokenChainId,
        address indexed originalTokenAddr,
        address indexed tokenAddr,
        NftToken[] tokens,
        uint256 toChainId,
        address recipient,
        uint256 feeAmount);

    event TeleportFinished(
        address indexed recipient,
        uint256 fromChainId,
        uint256 fromChainTeleportId,
        uint256 originalTokenChainId,
        address indexed originalTokenAddr,
        address indexed tokenAddr,
        NftToken[] tokens);

    event TeleportCancelStarted(
        uint256 fromChainId,
        uint256 fromChainTeleportId);

    event TeleportCancelFinished(
        uint256 teleportId,
        address tokenAddr,
        NftToken[] tokens,
        address recipient);

    function initialize(
        address payable _ownerAddr,
        address _signOwner,
        address _feeOwner,
        uint256 _teleportBaseFee,
        uint256 _teleportSingleTokenFee,
        address _wrappedTokenImpl) external virtual initializer {

        _ensureNotZeroAddress(_ownerAddr);
        _ensureNotZeroAddress(_signOwner);
        _ensureNotZeroAddress(_feeOwner);
        _ensureNotZeroAddress(_wrappedTokenImpl);

        initializeOwnable(_ownerAddr);

        signOwner = _signOwner;
        emit SetSignOwner(address(0), _signOwner);

        feeOwner = _feeOwner;
        emit SetFeeOwner(address(0), _feeOwner);

        teleportBaseFee = _teleportBaseFee;
        emit SetTeleportBaseFee(0, _teleportBaseFee);

        teleportSingleTokenFee = _teleportSingleTokenFee;
        emit SetTeleportSingleTokenFee(0, _teleportSingleTokenFee);

        wrappedTokenImplementation = _wrappedTokenImpl;
    }

    function setSignOwner(address _signOwner) onlyOwner external {
        _ensureNotZeroAddress(_signOwner);
        require(signOwner != _signOwner, ERROR_ALREADY_EXECUTED);
        emit SetSignOwner(signOwner, _signOwner);
        signOwner = _signOwner;
    }

    function setFeeOwner(address _feeOwner) onlyOwner external {
        _ensureNotZeroAddress(_feeOwner);
        require(feeOwner != _feeOwner, ERROR_ALREADY_EXECUTED);
        emit SetFeeOwner(feeOwner, _feeOwner);
        feeOwner = _feeOwner;
    }

    function setTeleportBaseFee(uint256 _teleportBaseFee) onlyOwner external {
        require(teleportBaseFee != _teleportBaseFee, ERROR_ALREADY_EXECUTED);
        emit SetTeleportBaseFee(teleportBaseFee, _teleportBaseFee);
        teleportBaseFee = _teleportBaseFee;
    }

    function setTeleportSingleTokenFee_(uint256 _teleportSingleTokenFee) onlyOwner external {
        require(teleportSingleTokenFee != _teleportSingleTokenFee, ERROR_ALREADY_EXECUTED);
        emit SetTeleportSingleTokenFee(teleportSingleTokenFee, _teleportSingleTokenFee);
        teleportSingleTokenFee = _teleportSingleTokenFee;
    }

    /**
     * @dev This function is called by the oracle to create wrapped token in present chain.
     * Wrapped token will represent the original token from another chain.
     * This function is optional but it will reduce the cost of the first {teleportFinish} function call
     * for given token pair.
     */
    function createWrappedToken(
        uint256 _originalTokenChainId,
        address _originalTokenAddr,
        string calldata _name,
        string calldata _symbol) onlyOwner external {

        _createWrappedToken(
            _originalTokenChainId,
            _originalTokenAddr,
            _name,
            _symbol);
    }

    /**
     * @dev This function is called by the user to create wrapped token in present chain.
     * Wrapped token will represent the original token from another chain.
     * This function is optional but it will reduce the cost of the first {teleportFinish} function call
     * for given token pair.
     * All parameters of this function are signed with oracle private key. The signature is passed in
     * {_signature} parameter.
     */
    function createWrappedToken(
        uint256 _originalTokenChainId,
        address _originalTokenAddr,
        string calldata _name,
        string calldata _symbol,
        bytes calldata _signature) external {

        string memory message = string(abi.encodeWithSignature(
            "sign(address,uint256,uint256,string,string)",
            _msgSender(),
            _originalTokenChainId,
            _originalTokenAddr,
            _name,
            _symbol));

        _verify(message, _signature);

        _createWrappedToken(
            _originalTokenChainId,
            _originalTokenAddr,
            _name,
            _symbol);
    }

    function _createWrappedToken(
        uint256 _originalTokenChainId,
        address _originalTokenAddr,
        string memory _name,
        string memory _symbol) private returns (address) {

        _ensureNotZeroAddress(_originalTokenAddr);
        require(block.chainid != _originalTokenChainId, "can't create wrapped token in original chain");
        require(originalToWrappedTokens[_originalTokenChainId][_originalTokenAddr] == address(0), "already created");

        address msgSender = _msgSender();

        address wrappedToken = _deployMinimalProxy(wrappedTokenImplementation);
        INftMintBurn(wrappedToken).initialize(_name, _symbol, address(this));

        originalToWrappedTokens[_originalTokenChainId][_originalTokenAddr] = wrappedToken;
        wrappedToOriginalTokens[wrappedToken] = OriginalToken({chainId : _originalTokenChainId, addr : _originalTokenAddr});

        emit WrappedTokenCreated(
            msgSender,
            _originalTokenChainId,
            _originalTokenAddr,
            wrappedToken,
            _name,
            _symbol);

        return wrappedToken;
    }


    /**
     * @dev Anyone can call this function to start the token teleportation process.
     * It either freezes the {_tokenAddr} tokens on the bridge or burns them and emits a signal to the oracle.
     */
    function teleportStart(address _tokenAddr, uint256[] calldata _tokenIds, uint256 _toChainId, address _recipient) payable external {
        _ensureNotZeroAddress(_tokenAddr);
        _ensureNotZeroAddress(_recipient);
        require(msg.value >= (teleportBaseFee + (teleportSingleTokenFee * _tokenIds.length)), "fee mismatch");

        if (msg.value != 0) {
            (bool sent,) = feeOwner.call{value : msg.value}("");
            require(sent, "fee send failed");
        }

        NftToken[] memory tokens = new NftToken[](_tokenIds.length);

        if (IERC165(_tokenAddr).supportsInterface(INTERFACE_ID_ERC_721_METADATA)) {
            for (uint16 i = 0; i < _tokenIds.length; ++i) {
                tokens[i].tokenURI = IERC721Metadata(_tokenAddr).tokenURI(_tokenIds[i]);
                tokens[i].tokenId = _tokenIds[i];
            }
        } else {
            for (uint16 i = 0; i < _tokenIds.length; ++i) {
                tokens[i].tokenId = _tokenIds[i];
            }
        }

        address msgSender = _msgSender();

        OriginalToken storage originalToken = wrappedToOriginalTokens[_tokenAddr];

        if (originalToken.addr == address(0)) {// teleportable token {_tokenAddr} is original token

            for (uint16 i = 0; i < _tokenIds.length; i++) {
                IERC721Transfer(_tokenAddr).safeTransferFrom(msgSender, address(this), _tokenIds[i]);
            }

            emit TeleportStarted(
                ++teleportIdGenerator,
                msgSender,
                block.chainid,
                _tokenAddr,
                _tokenAddr,
                tokens,
                _toChainId,
                _recipient,
                msg.value);

            return;
        }

        // teleportable token {_tokenAddr} is wrapped token

        for (uint16 i = 0; i < _tokenIds.length; ++i) {
            require(INftMintBurn(_tokenAddr).burn(_tokenIds[i]), "burn failed");
        }

        emit TeleportStarted(
            ++teleportIdGenerator,
            msgSender,
            originalToken.chainId,
            originalToken.addr,
            _tokenAddr,
            tokens,
            _toChainId,
            _recipient,
            msg.value);
    }

    /**
     * @dev This function is called by the oracle to finish the token teleportation process.
     * The required tokens is minted or unfreezed to {_toAddress} address in present chain.
     */
    function teleportFinish(
        uint256 _fromChainId,
        uint256 _fromChainTeleportId,
        uint256 _originalTokenChainId,
        address _originalTokenAddr,
        string memory _name,
        string memory _symbol,
        NftToken[] calldata _tokens,
        address _recipient) onlyOwner external {

        _teleportFinish(
            _fromChainId,
            _fromChainTeleportId,
            _originalTokenChainId,
            _originalTokenAddr,
            _name,
            _symbol,
            _tokens,
            _recipient);
    }

    /**
     * @dev This function is called by the user to finish the token teleportation process.
     * All parameters of this function are signed with oracle private key. The signature is passed in
     * {_signature} parameter.
     * The required tokens is minted or unfreezed to {_toAddress} address in present chain.
     */
    function teleportFinish(
        uint256 _fromChainId,
        uint256 _fromChainTeleportId,
        uint256 _originalTokenChainId,
        address _originalTokenAddr,
        string memory _name,
        string memory _symbol,
        NftToken[] calldata _tokens,
        bytes memory _signature) external {

        address recipient = _msgSender();

        string memory message = string(abi.encodeWithSignature(
            "sign(address,uint256,uint256,uint256,address,string,string,(uint256,string)[])",
            recipient,
            _fromChainId,
            _fromChainTeleportId,
            _originalTokenChainId,
            _originalTokenAddr,
            _name,
            _symbol,
            _tokens));

        _verify(message, _signature);

        _teleportFinish(
            _fromChainId,
            _fromChainTeleportId,
            _originalTokenChainId,
            _originalTokenAddr,
            _name,
            _symbol,
            _tokens,
            recipient);
    }

    function _teleportFinish(
        uint256 _fromChainId,
        uint256 _fromChainTeleportId,
        uint256 _originalTokenChainId,
        address _originalTokenAddr,
        string memory _name,
        string memory _symbol,
        NftToken[] calldata _tokens,
        address _recipient) private {

        _ensureNotZeroAddress(_originalTokenAddr);
        _ensureNotZeroAddress(_recipient);

        require(!finishedTeleports[_fromChainId][_fromChainTeleportId], ERROR_ALREADY_EXECUTED);
        finishedTeleports[_fromChainId][_fromChainTeleportId] = true;

        address tokenAddr;

        if (_originalTokenChainId == block.chainid) {
            for (uint16 i = 0; i < _tokens.length; i++) {
                IERC721Transfer(_originalTokenAddr).safeTransferFrom(address(this), _recipient, _tokens[i].tokenId);
            }
            tokenAddr = _originalTokenAddr;
        } else {
            tokenAddr = originalToWrappedTokens[_originalTokenChainId][_originalTokenAddr];

            if (tokenAddr == address(0)) {
                tokenAddr = _createWrappedToken(
                    _originalTokenChainId,
                    _originalTokenAddr,
                    _name,
                    _symbol);
            }

            for (uint16 i = 0; i < _tokens.length; i++) {
                require(INftMintBurn(tokenAddr).mintTo(_recipient, _tokens[i].tokenId, _tokens[i].tokenURI), ERROR_MINT_FAILED);
            }
        }

        emit TeleportFinished(
            _recipient,
            _fromChainId,
            _fromChainTeleportId,
            _originalTokenChainId,
            _originalTokenAddr,
            tokenAddr,
            _tokens);
    }

    function teleportCancelStart(uint256 _fromChainId, uint256 _fromChainTeleportId) onlyOwner external {
        require(!finishedTeleports[_fromChainId][_fromChainTeleportId], ERROR_ALREADY_EXECUTED);
        finishedTeleports[_fromChainId][_fromChainTeleportId] = true;

        emit TeleportCancelStarted(_fromChainId, _fromChainTeleportId);
    }

    function teleportCancelFinish(
        uint256 _teleportId,
        address _tokenAddr,
        NftToken[] calldata _tokens,
        address _recipient) onlyOwner external {

        OriginalToken storage originalToken = wrappedToOriginalTokens[_tokenAddr];

        if (originalToken.addr == address(0)) {// {_tokenAddr} is original token
            for (uint16 i = 0; i < _tokens.length; i++) {
                IERC721Transfer(_tokenAddr).safeTransferFrom(address(this), _recipient, _tokens[i].tokenId);
            }
        } else {// {_tokenAddr} is wrapped token
            for (uint16 i = 0; i < _tokens.length; i++) {
                require(INftMintBurn(_tokenAddr).mintTo(_recipient, _tokens[i].tokenId, _tokens[i].tokenURI), ERROR_MINT_FAILED);
            }
        }

        emit TeleportCancelFinished(_teleportId, _tokenAddr, _tokens, _recipient);
    }

    function _deployMinimalProxy(address _logic) private returns (address proxy) {
        // Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
        bytes20 targetBytes = bytes20(_logic);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create(0, clone, 0x37)
        }
    }

    function _verify(string memory _message, bytes memory _sig) private view {
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_message))));
        address messageSigner = _recover(messageHash, _sig);

        require(messageSigner == signOwner, "verification failed");
    }

    function _recover(bytes32 _hash, bytes memory _sig) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        require(_sig.length == 65, "_recover: invalid sig size");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "_recover: invalid sig");

        return ecrecover(_hash, v, r, s);
    }

    function _ensureNotZeroAddress(address _address) private pure {
        require(_address != address(0), "zero address");
    }
}