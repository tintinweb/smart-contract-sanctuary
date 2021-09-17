/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

// File: interfaces/LibEverLight.sol


pragma solidity ^0.8.0;

library LibEverLight {

  struct Configurations {
    uint256 _baseFee;                           // base fee for create character
    uint32 _incrPerNum;                         // the block number for increase fee
    uint256 _incrFee;                           // increase fee after increase block number
    uint32 _decrBlockNum;                       // the block number for decrease fee
    uint256 _decrFee;                           // decrease fee after decrease block number
    uint256 _latestCreateBlock;                 // the latest block number for create characters
    uint32 _totalDecrTimes;                     // total decrease times for nonone apply 
    uint32 _totalCreateNum;                     // total number of create characters
    uint256 _currentTokenId;                    // current token id for nft creation
    uint32 _totalSuitNum;                       // total suit number 
    uint32 _maxPosition;                        // max parts number for charater
    uint32 _luckyStonePrice;                    // price of lucky stone
    address _goverContract;                     // address of governance contract
    address _tokenContract;                     // address of token contract
    address[] _mapContracts;                    // addresses of map contracts 
  }
  
  struct SuitInfo {
    string _name;                               // suit name
    uint32 _suitId;                             // suit id, 0 for non suit
  }
 
  struct PartsInfo {
    mapping(uint8 => mapping(uint8 => uint32)) _partsPowerList;     // position -> (rare -> power)
    mapping(uint8 => mapping(uint8 => SuitInfo[])) _partsTypeList;  // position -> (rare -> SuitInfo[])
    mapping(uint8 => uint32) _partsCount;       // position -> count
    mapping(uint8 => string) _rareColor;        // rare -> color
    mapping(uint32 => address) _suitFlag;       // check suit is exists
    mapping(uint256 => bool) _nameFlag;         // parts name is exists
  }
  
  struct TokenInfo {
    uint256 _tokenId;                           // token id
    //address _owner;                             // owner of token
    uint8 _position;                            // parts position
    uint8 _rare;                                // rare level 
    string _name;                               // parts name
    uint32 _suitId;                             // suit id, 0 for non suit
    uint32 _power;                              // parts power
    uint8 _level;                               // parts level
    bool _createFlag;                           // has created new parts
    uint256 _wearToken;                         // character token id which wear this token
  }

  struct Account {
    bool _creationFlag;                         // if the address has created character
    uint32 _luckyNum;                           // lucky number of current address
  }

  struct Character {
    uint256 _tokenId;                           // token id
    //address _owner;                           // owner of character
    uint32 _powerFactor;                        // power factor of character
    mapping(uint8 => uint256) _tokenList;       // position -> tokenID
    uint32 _totalPower;                         // total power of parts list
    mapping(uint256 => string) _extraList;      // 
  }



}

// File: interfaces/IEverLight.sol


pragma solidity ^0.8.0;


interface IEverLight {
  // event list
  event NewTokenType(address indexed creator, uint8 position, uint8 rare, string indexed name, uint256 suitId);

  // read function list
  function queryColorByRare(uint8 rare) external view returns (string memory color);

 /* function queryBaseInfo() external view returns (uint256 baseFee, uint32 incrPerNum, uint256 incrFee, 
                                      uint32 decrBlockNum, uint256 decrFee, uint256 lastestCreateBlock, uint32 totalSuitNum);*/

  function queryAccount(address owner) external view returns (LibEverLight.Account memory account);

  // returns the type for tokenId(1 charactor, 2 parts, 3 lucklyStone)
  function queryTokenType(uint256 tokenId) external view returns (uint8 tokenType);
  
  function queryCharacter(uint256 characterId) external view returns (uint256 tokenId, uint32 powerFactor, uint256[] memory tokenList, uint32 totalPower);

  function queryToken(uint256 tokenId) external view returns (LibEverLight.TokenInfo memory tokenInfo);

  function queryCharacterCount() external view returns (uint32 num);

  function queryLuckyStonePrice() external view returns (uint32 price);

  function queryMapInfo() external view returns (address[] memory addresses);

  function querySuitOwner(uint32 suitId) external view returns (address owner);

  function isNameExist(string memory name) external view returns (bool result);

  function queryCharacterExtra(uint256 characterId, uint256 extraKey) external view returns (string memory);

  // write function list
  function setCharacterExtra(uint256 characterId, uint256 extraKey, string memory extraValue) external;

  function mint() external payable;

  function wear(uint256 characterId, uint256[] memory tokenList) external;

  function takeOff(uint256 characterId, uint8[] memory positions) external;

  function upgradeToken(uint256 firstTokenId, uint256 secondTokenId) external;

  function upgradeWearToken(uint256 characterId, uint256 tokenId) external;

  function exchangeToken(uint32 mapId, uint256[] memory mapTokenList) external;

  function buyLuckyStone(uint8 count) external;

  function useLuckyStone(uint256[] memory tokenId) external;

  function newTokenType(uint256 tokenId, string memory name, uint32 suitId) external;
}

// File: utils/introspection/IERC165.sol



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
// File: interfaces/IERC721.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// File: interfaces/IERC721Proxy.sol


pragma solidity ^0.8.0;

interface IERC721Proxy {

  function mintBy(address owner, uint256 tokenId) external;
  function burnBy(uint256 tokenId) external;
  function ownerOf(uint256 tokenId) external view returns (address owner);
}
// File: interfaces/IERC20.sol


pragma solidity ^0.8.0;

/**
 * @title IERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20Basic {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title IERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Basic {
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}
// File: utils/Address.sol



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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
// File: utils/Strings.sol



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
// File: utils/Base64.sol


pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
// File: utils/Context.sol



pragma solidity ^0.8.0;

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

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _timestamp() internal view virtual returns (uint) {
        return block.timestamp;
    }

    function _blockNum() internal view virtual returns (uint) {
        return block.number;
    }

    function _gasLeft() internal view virtual returns (uint) {
        return gasleft();
    }

    function _value() internal view virtual returns (uint) {
        return msg.value;
    }

    function _gasPrice() internal view virtual returns (uint) {
        return tx.gasprice;
    }
}
// File: Ownable.sol



pragma solidity ^0.8.0;


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
// File: EverLight.sol


pragma solidity ^0.8.0;










contract EverLight is Ownable, IEverLight {
    
  using Address for address;
  using Strings for uint256;

  IERC721Proxy public _erc721Proxy;                          // address of 721 token      
  
  LibEverLight.Configurations _config;                       // all configurations
  LibEverLight.PartsInfo _partsInfo;                         // all parts informations
  mapping(uint256 => LibEverLight.TokenInfo) _tokenList;     // all tokens  
  mapping(address => LibEverLight.Account) _accountList;     // all packages owned by address
  mapping(uint256 => LibEverLight.Character) _characterList; // all character owned by address

  constructor() Ownable() {
    // init the configrations
    _config._baseFee = 25 * 10 ** 18; // 25 matic
    _config._incrPerNum = 2500;        // eth: 256, matic: 1792
    _config._incrFee = 25 * 10 ** 18; 
    _config._decrBlockNum = 25000;       // eth: 4096, matic: 28672
    _config._decrFee = 25 * 10 ** 18;
    // _config._latestCreateBlock = 0;
    // _config._totalDecrTimes = 0;
    // _config._totalCreateNum = 0;
    // _config._currentTokenId = 0;
    // _config._totalSuitNum = 0;
    _config._maxPosition = 11;
    _config._luckyStonePrice = 2000;
  }

  function queryTokenType(uint256 tokenId) external view override returns (uint8 tokenType) {
    if(_tokenList[tokenId]._tokenId == tokenId){
      if(_tokenList[tokenId]._position == 99){
        return 3;
      }
      return 2;
    }
    if(_characterList[tokenId]._tokenId == tokenId){
      return 1;
    }
  }

  function queryColorByRare(uint8 rare) external view override returns (string memory color) {
    return _partsInfo._rareColor[rare];
  }

  function queryAccount(address owner) external view override returns (LibEverLight.Account memory account) {
    account = _accountList[owner];
  }

  function queryCharacter(uint256 characterId) external view override returns (uint256 tokenId, uint32 powerFactor, uint256[] memory tokenList, uint32 totalPower) {
    (tokenId, powerFactor, totalPower) = (_characterList[characterId]._tokenId, _characterList[characterId]._powerFactor, _characterList[characterId]._totalPower);
    
    tokenList = new uint256[](_config._maxPosition);
    for (uint8 i=0; i<_config._maxPosition; ++i) {
      tokenList[i] = _characterList[characterId]._tokenList[i];
    }
  }

  /*function queryBaseInfo() external view override returns (uint256 baseFee, uint32 incrPerNum, uint256 incrFee, 
                                      uint32 decrBlockNum, uint256 decrFee, uint256 lastestCreateBlock, uint32 totalSuitNum) {
    (baseFee, incrPerNum, incrFee, decrBlockNum, decrFee, lastestCreateBlock, totalSuitNum) = (_config._baseFee, _config._incrPerNum, _config._incrFee, _config._decrBlockNum, _config._decrFee, _config._latestCreateBlock, _config._totalSuitNum);
  }*/

  function queryToken(uint256 tokenId) external view override returns (LibEverLight.TokenInfo memory tokenInfo) {
    tokenInfo = _tokenList[tokenId];
  }

  function queryCharacterCount() external view override returns (uint32) {
    return _config._totalCreateNum;
  }

  function queryLuckyStonePrice() external view override returns (uint32) {
    return _config._luckyStonePrice;
  }

  function queryMapInfo() external view override returns (address[] memory addresses) {
    addresses = _config._mapContracts;
  }

  function querySuitOwner(uint32 suitId) external view override returns (address) {
    return _partsInfo._suitFlag[suitId];
  }

  function isNameExist(string memory name) external view override returns (bool) {
    return _partsInfo._nameFlag[uint256(keccak256(abi.encodePacked(name)))];
  }

  function queryCharacterExtra(uint256 characterId, uint256 extraKey) external view override returns (string memory) {
    require(_erc721Proxy.ownerOf(characterId) == tx.origin, "!owner");
    return _characterList[characterId]._extraList[extraKey];
  }

  function setCharacterExtra(uint256 characterId, uint256 extraKey, string memory extraValue) external override {
    require(_erc721Proxy.ownerOf(characterId) == tx.origin, "!owner");
    _characterList[characterId]._extraList[extraKey] = extraValue;
  }

  function mint() external override payable {
    // one address can only apply once
    require(!_accountList[tx.origin]._creationFlag, "Only once");

    // calc the apply fee
    uint32 decrTimes;
    uint256 applyFee = _config._baseFee + _config._totalCreateNum / _config._incrPerNum * _config._incrFee;
    if (_config._latestCreateBlock != 0) {
      decrTimes = uint32( block.number - _config._latestCreateBlock ) / _config._decrBlockNum;
    }
    
    uint decrFee = (_config._totalDecrTimes + decrTimes) * _config._decrFee;
    applyFee = (applyFee - _config._baseFee) > decrFee ? (applyFee - decrFee) : _config._baseFee;
    require(msg.value >= applyFee, "Not enough value");

    // create character
    uint256 characterId = _createCharacter();

    // create package information
    _accountList[tx.origin]._creationFlag = true;
    // _accountList[tx.origin]._luckyNum = 0;

    // return the left fee
    if (msg.value > applyFee) {
      payable(tx.origin).transfer(msg.value - applyFee);
    }

    // update stat information
    _config._totalCreateNum += 1;
    _config._latestCreateBlock = block.number;
    _config._totalDecrTimes += decrTimes;

    // mint nft
    _erc721Proxy.mintBy(tx.origin, characterId);
  }

  function wear(uint256 characterId, uint256[] memory tokenList) external override {
    //require(_characterOwnOf(characterId) == tx.origin, "character not owner");
    require(_erc721Proxy.ownerOf(characterId) == tx.origin);
    require(tokenList.length > 0, "Empty token");
    
    // create new character
    uint256 newCharacterId = ++_config._currentTokenId;
    _copyCharacter(characterId, newCharacterId);

    // deal with all parts
    for (uint i = 0; i < tokenList.length; ++i) {
      if (tokenList[i] == 0) {
        continue;
      }

      //require(_tokenOwnOf(tokenList[i]) == tx.origin, "parts not owner");
      require(_erc721Proxy.ownerOf(tokenList[i]) == tx.origin, "parts !owner");
      require(_tokenList[tokenList[i]]._wearToken == 0, "weared");

      // wear parts
      uint8 position = _tokenList[tokenList[i]]._position;
      uint256 partsId = _characterList[newCharacterId]._tokenList[position];

      _characterList[newCharacterId]._tokenList[position] = tokenList[i];
      _tokenList[tokenList[i]]._wearToken = newCharacterId;
      _erc721Proxy.burnBy(tokenList[i]);

      // mint weared parts
      if (partsId != 0) {
        _tokenList[partsId]._wearToken = 0;
        _erc721Proxy.mintBy(tx.origin, partsId);
      }
    }

    // burn old token and remint character 
    _erc721Proxy.burnBy(characterId);
    delete _characterList[characterId];

    _characterList[newCharacterId]._totalPower = _calcTotalPower(newCharacterId);
    _erc721Proxy.mintBy(tx.origin, newCharacterId);
  }

  function takeOff(uint256 characterId, uint8[] memory positions) external override {
    //require(_characterOwnOf(characterId) == tx.origin, "Not owner");
    require(_erc721Proxy.ownerOf(characterId) == tx.origin, "!owner");
    require(positions.length > 0, "Empty position");
    
    // create new character
    uint256 newCharacterId = ++_config._currentTokenId;
    _copyCharacter(characterId, newCharacterId);

    // deal with all parts
    for (uint i=0; i<positions.length; ++i) {
      require(positions[i]<_config._maxPosition, "Invalid position");

      uint256 partsId = _characterList[newCharacterId]._tokenList[positions[i]];
      if (partsId == 0) {
        continue;
      }

      _characterList[newCharacterId]._tokenList[positions[i]] = 0;
      _tokenList[partsId]._wearToken = 0;
      _erc721Proxy.mintBy(tx.origin, partsId);
    }

    // burn old token and remint character 
    _erc721Proxy.burnBy(characterId);
    delete _characterList[characterId];

    _characterList[newCharacterId]._totalPower = _calcTotalPower(newCharacterId);
    _erc721Proxy.mintBy(tx.origin, newCharacterId);
  }

  function upgradeToken(uint256 firstTokenId, uint256 secondTokenId) external override {
  
    require(_erc721Proxy.ownerOf(firstTokenId) == tx.origin, "first !owner");
    require(_erc721Proxy.ownerOf(secondTokenId) == tx.origin, "second !owner");

    // check pats can upgrade
    require(keccak256(bytes(_tokenList[firstTokenId]._name)) == keccak256(bytes(_tokenList[secondTokenId]._name)), "!name");
    require(_tokenList[firstTokenId]._level == _tokenList[secondTokenId]._level, "!level");
    require(_tokenList[firstTokenId]._position == _tokenList[secondTokenId]._position, "!position");
    require(_tokenList[firstTokenId]._rare == _tokenList[secondTokenId]._rare, "!rare");
    require(_tokenList[firstTokenId]._level < 9, "Max level");
    
    require(_tokenList[firstTokenId]._wearToken == 0, "f weared");
    require(_tokenList[secondTokenId]._wearToken == 0, "s weared");

    // basepower = (basepower * 1.25 ** level) * +1.1
    uint32 basePower = _partsInfo._partsPowerList[_tokenList[firstTokenId]._position][_tokenList[firstTokenId]._rare];
    basePower = uint32(basePower * (125 ** (_tokenList[firstTokenId]._level - 1)) / (100 ** (_tokenList[firstTokenId]._level - 1)));
    uint32 randPower = uint32(basePower < 10 ? _getRandom(uint256(256).toString()) % 1 : _getRandom(uint256(256).toString()) % (basePower / 10));

    // create new parts
    uint256 newTokenId = ++_config._currentTokenId;
    _tokenList[newTokenId] = LibEverLight.TokenInfo(newTokenId, /*tx.origin,*/ _tokenList[firstTokenId]._position, _tokenList[firstTokenId]._rare,
                                                    _tokenList[firstTokenId]._name, _tokenList[firstTokenId]._suitId, basePower + randPower,
                                                    _tokenList[firstTokenId]._level + 1, false, 0);

    // remove old token
    _erc721Proxy.burnBy(firstTokenId);
    delete _tokenList[firstTokenId];
    _erc721Proxy.burnBy(secondTokenId);
    delete _tokenList[secondTokenId];
    
    // mint new token
    _erc721Proxy.mintBy(tx.origin, newTokenId);
  }

  function upgradeWearToken(uint256 characterId, uint256 tokenId) external override {
    //require(_characterOwnOf(characterId) == tx.origin, "Not owner");
    require(_erc721Proxy.ownerOf(characterId) == tx.origin, "!owner");
    //require(_tokenOwnOf(tokenId) == tx.origin, "Not owner");
    require(_erc721Proxy.ownerOf(tokenId) == tx.origin, "parts !owner");

    uint8 position = _tokenList[tokenId]._position;
    uint256 partsId = _characterList[characterId]._tokenList[position];

    // check pats can upgrade
    require(keccak256(bytes(_tokenList[tokenId]._name)) == keccak256(bytes(_tokenList[partsId]._name)), "!token");
    require(_tokenList[tokenId]._level == _tokenList[partsId]._level, "!level");
    require(_tokenList[tokenId]._rare == _tokenList[partsId]._rare, "!rare");
    require(_tokenList[tokenId]._level < 9, "Max level");
    require(_tokenList[tokenId]._wearToken == 0, "Weared");

    // create new character
    uint256 newCharacterId = ++_config._currentTokenId;
    _copyCharacter(characterId, newCharacterId);

    // basepower = (basepower * 1.25 ** level) * +1.1
    uint32 basePower = _partsInfo._partsPowerList[position][_tokenList[partsId]._rare];
    basePower = uint32(basePower * (125 ** (_tokenList[partsId]._level - 1)) / (100 ** (_tokenList[partsId]._level - 1)));
    uint32 randPower = uint32(basePower < 10 ? _getRandom(uint256(256).toString()) % 1 : _getRandom(uint256(256).toString()) % (basePower / 10));

    // create new parts
    uint256 newTokenId = ++_config._currentTokenId;
    _tokenList[newTokenId] = LibEverLight.TokenInfo(newTokenId, /*tx.origin,*/ _tokenList[partsId]._position, _tokenList[partsId]._rare,
                                                    _tokenList[partsId]._name, _tokenList[partsId]._suitId, basePower + randPower,
                                                    _tokenList[partsId]._level + 1, false, newCharacterId);

    _characterList[newCharacterId]._tokenList[position] = newTokenId;
    _characterList[newCharacterId]._totalPower = _calcTotalPower(newCharacterId);

    // remove old parts
    _erc721Proxy.burnBy(tokenId);
    delete _tokenList[tokenId];
    delete _tokenList[partsId];

    // burn old token and remint character 
    _erc721Proxy.burnBy(characterId);
    delete _characterList[characterId];
    _erc721Proxy.mintBy(tx.origin, newCharacterId);
  }

  function exchangeToken(uint32 mapId, uint256[] memory mapTokenList) external override {
    require(mapId < _config._mapContracts.length, "Invalid map");

    for (uint i=0; i<mapTokenList.length; ++i) {
      // burn map token
      _transferERC721(_config._mapContracts[mapId], tx.origin, address(this), mapTokenList[i]);

      // generate new token
      uint256 newTokenId = _genRandomToken(uint8(_getRandom(mapTokenList[i].toString()) % _config._maxPosition));

      _erc721Proxy.mintBy(tx.origin, newTokenId);
    }
  }

  function buyLuckyStone(uint8 count) external override {
    require(_config._tokenContract != address(0), "Not open");

    // transfer token to address 0
    uint256 totalToken = _config._luckyStonePrice * count;
    _transferERC20(_config._tokenContract, tx.origin, address(this), totalToken);

    // mint luck stone 
    for (uint8 i=0; i<count; ++i) {
      uint256 newTokenId = ++_config._currentTokenId;
      (_tokenList[newTokenId]._tokenId, _tokenList[newTokenId]._position, _tokenList[newTokenId]._name) = (newTokenId, 99, "Lucky Stone");

      _erc721Proxy.mintBy(tx.origin, newTokenId);
    }
  }

  function useLuckyStone(uint256[] memory tokenId) external override {
    for (uint i=0; i<tokenId.length; ++i) {
      //require(_tokenOwnOf(tokenId[i]) == tx.origin, "Not owner");
      require(_erc721Proxy.ownerOf(tokenId[i]) == tx.origin, "stone !owner");
      require(_tokenList[tokenId[i]]._position == 99, "Not lucky stone");

      ++_accountList[tx.origin]._luckyNum;

      // burn luck stone token
      _erc721Proxy.burnBy(tokenId[i]);
      delete _tokenList[tokenId[i]];
    }
  }

  function newTokenType(uint256 tokenId, string memory name, uint32 suitId) external override {
    //require(_tokenOwnOf(tokenId) == tx.origin, "Not owner");
    require(_erc721Proxy.ownerOf(tokenId) == tx.origin, "!owner");
    require(_tokenList[tokenId]._level == 9, "level != 9");
    require(!_tokenList[tokenId]._createFlag, "createFlag=true");
    require(bytes(name).length <= 16, "Error name");

    // create new parts type
    uint8 position = _tokenList[tokenId]._position;
    uint8 rare = _tokenList[tokenId]._rare + 1;
    uint256 nameFlag = uint256(keccak256(abi.encodePacked(name)));
    
    require(_partsInfo._partsPowerList[position][rare] > 0, "Not open");
    require(!_partsInfo._nameFlag[nameFlag], "Error name");
    
    if (suitId == 0) {
      suitId = ++_config._totalSuitNum;
      _partsInfo._suitFlag[suitId] = tx.origin;
    } else {
      require(_partsInfo._suitFlag[suitId] == tx.origin, "Not own the suit");
    }

    _partsInfo._partsTypeList[position][rare].push(LibEverLight.SuitInfo(name, suitId));
    _partsInfo._partsCount[position] = _partsInfo._partsCount[position] + 1;
    _partsInfo._nameFlag[nameFlag] = true;
    emit NewTokenType(tx.origin, position, rare, name, suitId);

    // create 3 new token for creator
    for (uint i=0; i<3; ++i) {
      uint256 newTokenId = ++_config._currentTokenId;
      uint32 randPower = uint32(_partsInfo._partsPowerList[position][rare] < 10 ?
                                _getRandom(uint256(256).toString()) % 1 :
                                _getRandom(uint256(256).toString()) % (_partsInfo._partsPowerList[position][rare] / 10));

        // create token information
        _tokenList[newTokenId] = LibEverLight.TokenInfo(newTokenId, /*tx.origin, */position, rare, name, suitId, 
                                                    _partsInfo._partsPowerList[position][rare] + randPower, 1, false, 0);

        _erc721Proxy.mintBy(tx.origin, newTokenId);
    }

    // update token and charactor information
    uint256 newPartsTokenId = ++_config._currentTokenId;
    _tokenList[newPartsTokenId] = LibEverLight.TokenInfo(newPartsTokenId,/* tx.origin,*/ position, rare - 1, _tokenList[tokenId]._name, 
                                                         _tokenList[tokenId]._suitId, _tokenList[tokenId]._power, 9, true, _tokenList[tokenId]._wearToken);

    if (_tokenList[newPartsTokenId]._wearToken != 0) {
      _characterList[_tokenList[newPartsTokenId]._wearToken]._tokenList[position] = newPartsTokenId;
    } else {
      _erc721Proxy.burnBy(tokenId);
      _erc721Proxy.mintBy(tx.origin, newPartsTokenId);
    }

    delete _tokenList[tokenId];
  }

  // internal functions
  /*function _characterOwnOf(uint256 tokenId) internal view returns (address) {
    return _characterList[tokenId]._owner;
  }*/

  /*function _tokenOwnOf(uint256 tokenId) internal view returns (address) {
    return _tokenList[tokenId]._owner;
  }*/

  function _getRandom(string memory purpose) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, tx.origin, purpose)));
  }

  function _genRandomToken(uint8 position) internal returns (uint256 tokenId) {
    // create random number and plus lucky number on msg.sender
    uint256 luckNum = _getRandom(uint256(position).toString()) % _partsInfo._partsCount[position] + _accountList[tx.origin]._luckyNum;
    if (luckNum >= _partsInfo._partsCount[position]) {
      luckNum = _partsInfo._partsCount[position] - 1;
    }

    // find the parts on position by lucky number
    tokenId = ++_config._currentTokenId;
    for(uint8 rare=0; rare<256; ++rare) {
      if (luckNum >= _partsInfo._partsTypeList[position][rare].length) {
        luckNum -= _partsInfo._partsTypeList[position][rare].length;
        continue;
      }

      // calc rand power by base power and +10%
      uint32 randPower = uint32(_partsInfo._partsPowerList[position][rare] <= 10 ?
                                _getRandom(uint256(256).toString()) % 1 :
                                _getRandom(uint256(256).toString()) % (_partsInfo._partsPowerList[position][rare] / 10));

      // create token information
      _tokenList[tokenId] = LibEverLight.TokenInfo(tokenId, /*tx.origin,*/ position, rare, _partsInfo._partsTypeList[position][rare][luckNum]._name,
                                                   _partsInfo._partsTypeList[position][rare][luckNum]._suitId, 
                                                   _partsInfo._partsPowerList[position][rare] + randPower, 1, false, 0);
      break;
    }

    // clear lucky value on msg.sender, only used once
    _accountList[tx.origin]._luckyNum = 0;
  }

  function _createCharacter() internal returns (uint256 tokenId) {
    // create character
    tokenId = ++_config._currentTokenId;
    _characterList[tokenId]._tokenId = tokenId;
    //_characterList[tokenId]._owner = tx.origin;
    _characterList[tokenId]._powerFactor = uint32(_getRandom(uint256(256).toString()) % 30);

    // create all random parts for character
    for (uint8 i=0; i<_config._maxPosition; ++i) {
      uint256 partsId = _genRandomToken(i);

      _characterList[tokenId]._tokenList[i] = partsId;
      _tokenList[partsId]._wearToken = tokenId;
    }

    // calc total power of character
    _characterList[tokenId]._totalPower = _calcTotalPower(tokenId);
  }

  function _calcTotalPower(uint256 tokenId) internal view returns (uint32 totalPower) {
    uint256 lastSuitId;
    bool suitFlag = true;

    // sum parts power
    for (uint8 i=0; i<_config._maxPosition; ++i) {
      uint256 index = _characterList[tokenId]._tokenList[i];
      if (index == 0) {
        suitFlag = false;
        continue;
      }

      totalPower += _tokenList[index]._power;
      
      if (suitFlag == false || _tokenList[index]._suitId == 0) {
        suitFlag = false;
        continue;
      } 

      if (lastSuitId == 0) {
        lastSuitId = _tokenList[index]._suitId;
        continue;
      }

      if (_tokenList[index]._suitId != lastSuitId) {
        suitFlag = false;
      }
    }

    // calc suit power
    if (suitFlag) {
      totalPower += totalPower * 12 / 100;
    }
    totalPower += totalPower * _characterList[tokenId]._powerFactor / 100;
  }

  function _copyCharacter(uint256 oldId, uint256 newId) internal {
    (_characterList[newId]._tokenId, /*_characterList[newId]._owner,*/ _characterList[newId]._powerFactor) = (newId,/* tx.origin,*/ _characterList[oldId]._powerFactor);

    // copy old character's all parts info
    for (uint8 index=0; index<_config._maxPosition; ++index) {
      _characterList[newId]._tokenList[index] = _characterList[oldId]._tokenList[index];
      // 
      _tokenList[_characterList[newId]._tokenList[index]]._wearToken = newId;
    }
  }

  function _transferERC20(address contractAddress, address from, address to, uint256 amount) internal {
    //uint256 balanceBefore = IERC20(contractAddress).balanceOf(from);
    IERC20(contractAddress).transferFrom(from, to, amount);

    bool success;
    assembly {
      switch returndatasize()
        case 0 {                       // This is a non-standard ERC-20
            success := not(0)          // set success to true
        }
        case 32 {                      // This is a compliant ERC-20
            returndatacopy(0, 0, 32)
            success := mload(0)        // Set `success = returndata` of external call
        }
        default {                      // This is an excessively non-compliant ERC-20, revert.
            revert(0, 0)
        }
    }
    require(success, "Transfer failed");
  }

  function _transferERC721(address contractAddress, address from, address to, uint256 tokenId) internal {
    address ownerBefore = IERC721(contractAddress).ownerOf(tokenId);
    require(ownerBefore == from, "Not own token");
    
    IERC721(contractAddress).transferFrom(from, to, tokenId);

    address ownerAfter = IERC721(contractAddress).ownerOf(tokenId);
    require(ownerAfter == to, "Transfer failed");
  }

  // governace functions
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function setMintFee(uint256 baseFee, uint32 incrPerNum, uint256 incrFee, uint32 decrBlockNum, uint256 decrFee) external onlyOwner {
    (_config._baseFee, _config._incrPerNum, _config._incrFee, _config._decrBlockNum, _config._decrFee) = (baseFee, incrPerNum, incrFee, decrBlockNum, decrFee);
  }

  function addPartsType(uint8 position, uint8 rare, string memory color, uint256 power, string[] memory names, uint32[] memory suits) external onlyOwner {
    _partsInfo._partsPowerList[position][rare] = uint32(power);
    _partsInfo._rareColor[rare] = color;

    for (uint i=0; i<names.length; ++i) {
      _partsInfo._partsTypeList[position][rare].push(LibEverLight.SuitInfo(names[i], suits[i]));
      _partsInfo._nameFlag[uint256(keccak256(abi.encodePacked(names[i])))] = true;

      if (suits[i] > 0 ) {
        if (_partsInfo._suitFlag[suits[i]] == address(0)) {
          _config._totalSuitNum = _config._totalSuitNum < suits[i] ? suits[i] : _config._totalSuitNum;
          _partsInfo._suitFlag[suits[i]] = tx.origin;
        } else {
          require(_partsInfo._suitFlag[suits[i]] == tx.origin, "Not own the suit");
        }
      }
    }
    
    _partsInfo._partsCount[position] = uint32(_partsInfo._partsCount[position] + names.length);
  }

  function setLuckStonePrice(uint32 price) external onlyOwner {
    _config._luckyStonePrice = price;
  }
 
  function setMaxPosition(uint32 maxPosition) external onlyOwner {
    _config._maxPosition = maxPosition;
  }

  function setGovernaceAddress(address governaceAddress) external onlyOwner {
    _config._goverContract = governaceAddress;
  }

  function setTokenAddress(address tokenAddress) external onlyOwner {
    _config._tokenContract = tokenAddress;
  }
  
  function addMapAddress(address mapAddress) external onlyOwner {
    _config._mapContracts.push(mapAddress);
  }

  function setERC721Proxy(address proxyAddress) external onlyOwner {
    _erc721Proxy = IERC721Proxy(proxyAddress);
  }
}