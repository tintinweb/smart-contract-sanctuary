/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier:UNLICENSED
pragma solidity >=0.7.0 <0.9.0;


contract MFFUtils {
    
    // qty per pack
    mapping(string => uint) public nft_qte_per_pack;
    
    // Bronze
    uint[3] public bronze_choice_common;
    uint[3] public bronze_choice_uncommon;
    uint[5] public bronze_choice_rare;
    
    // Silver
    uint[3] public silver_choice_common;
    uint[10] public silver_choice_rare;
    uint[5] public silver_choice_epic;
    
    // Gold
    uint[5] public gold_choice_rare;
    uint[4] public gold_choice_epic;
    uint[9] public gold_choice_legendary;
    
    mapping (string => string) public category_list;
    mapping (string => uint) public price_list;
    mapping (string => uint) public availableNFT;
    mapping (string => uint) public pack_price_list;
    mapping (string => uint) public availableNFTPack;
    
    bool private first_price_set = false;
    
    
    function getPrice(string memory _player) public view returns (uint) {
        return price_list[category_list[substring(_player,8,15)]];
    }
    
    function getQte(string memory _player) public view returns (uint) {
        return availableNFT[getNFTName(_player)];
    }

    function getNFTName(string memory _player) public pure returns (string memory) {
        return concat(substring(_player,0,15), substring(_player,23,39));
    }
    
    function firstSetting() public {
        
        if (first_price_set == false) {
            first_price_set = true;
            
            category_list["bak-000"] = "mythic";
            category_list["bak-001"] = "common";
            category_list["bak-002"] = "uncommon";
            category_list["bak-003"] = "rare";
            category_list["bak-004"] = "epic";
            category_list["bak-005"] = "legendary";
            
            // Goals
            category_list["bak-006"] = "uncommon";
            category_list["bak-007"] = "rare";
            category_list["bak-008"] = "epic";
            category_list["bak-009"] = "legendary";
            category_list["bak-010"] = "mythic";
            
            price_list["common"] = 0.05 ether;
            price_list["uncommon"] = 0.1 ether;
            price_list["rare"] = 0.2 ether;
            price_list["epic"] = 0.5 ether;
            price_list["legendary"] = 1 ether;
            price_list["mythic"] = 10 ether;
            
            pack_price_list["bronze"] = 0.5 ether;
            pack_price_list["silver"] = 1 ether;
            pack_price_list["gold"] = 2 ether;
            
            availableNFTPack["bronze"] = 400;
            availableNFTPack["silver"] = 500;
            availableNFTPack["gold"] = 90;
            
            nft_qte_per_pack["bronze_common_007"] = 300;
            nft_qte_per_pack["bronze_common_008"] = 300;
            nft_qte_per_pack["bronze_common_012"] = 200;
            
            nft_qte_per_pack["bronze_uncommon_007"] = 300;
            nft_qte_per_pack["bronze_uncommon_008"] = 300;
            nft_qte_per_pack["bronze_uncommon_012"] = 200;
            
            nft_qte_per_pack["bronze_rare_000"] = 131;
            nft_qte_per_pack["bronze_rare_001"] = 131;
            nft_qte_per_pack["bronze_rare_002"] = 46;
            nft_qte_per_pack["bronze_rare_003"] = 46;
            nft_qte_per_pack["bronze_rare_004"] = 46;
            
            nft_qte_per_pack["silver_common_007"] = 250;
            nft_qte_per_pack["silver_common_008"] = 150;
            nft_qte_per_pack["silver_common_012"] = 100;
            
            nft_qte_per_pack["silver_rare_002"] = 100;
            nft_qte_per_pack["silver_rare_003"] = 100;
            nft_qte_per_pack["silver_rare_004"] = 100;
            nft_qte_per_pack["silver_rare_005"] = 200;
            nft_qte_per_pack["silver_rare_006"] = 200;
            nft_qte_per_pack["silver_rare_007"] = 200;
            nft_qte_per_pack["silver_rare_008"] = 200;
            nft_qte_per_pack["silver_rare_009"] = 200;
            nft_qte_per_pack["silver_rare_011"] = 100;
            nft_qte_per_pack["silver_rare_012"] = 100;
            
            nft_qte_per_pack["silver_epic_000"] = 100;
            nft_qte_per_pack["silver_epic_001"] = 100;
            nft_qte_per_pack["silver_epic_002"] = 100;
            nft_qte_per_pack["silver_epic_003"] = 100;
            nft_qte_per_pack["silver_epic_004"] = 100;
            
            nft_qte_per_pack["gold_rare_000"] = 54;
            nft_qte_per_pack["gold_rare_001"] = 54;
            nft_qte_per_pack["gold_rare_002"] = 54;
            nft_qte_per_pack["gold_rare_003"] = 54;
            nft_qte_per_pack["gold_rare_004"] = 54;
            
            nft_qte_per_pack["gold_epic_005"] = 10;
            nft_qte_per_pack["gold_epic_006"] = 10;
            nft_qte_per_pack["gold_epic_009"] = 35;
            nft_qte_per_pack["gold_epic_011"] = 35;
            
            nft_qte_per_pack["gold_legendary_000"] = 10;
            nft_qte_per_pack["gold_legendary_001"] = 10;
            nft_qte_per_pack["gold_legendary_002"] = 10;
            nft_qte_per_pack["gold_legendary_003"] = 10;
            nft_qte_per_pack["gold_legendary_004"] = 10;
            nft_qte_per_pack["gold_legendary_005"] = 10;
            nft_qte_per_pack["gold_legendary_006"] = 10;
            nft_qte_per_pack["gold_legendary_009"] = 10;
            nft_qte_per_pack["gold_legendary_011"] = 10;
            
            
            bronze_choice_common[0] = 7;
            bronze_choice_common[1] = 8;
            bronze_choice_common[2] = 12;
            
            bronze_choice_uncommon[0] = 7;
            bronze_choice_uncommon[1] = 8;
            bronze_choice_uncommon[2] = 12;
            
            bronze_choice_rare[0] = 0;
            bronze_choice_rare[1] = 1;
            bronze_choice_rare[2] = 2;
            bronze_choice_rare[3] = 3;
            bronze_choice_rare[4] = 4;
            
            
            silver_choice_common[0] = 7;
            silver_choice_common[1] = 8;
            silver_choice_common[2] = 12;
            
            silver_choice_rare[0] = 2;
            silver_choice_rare[1] = 3;
            silver_choice_rare[2] = 4;
            silver_choice_rare[3] = 5;
            silver_choice_rare[4] = 6;
            silver_choice_rare[5] = 7;
            silver_choice_rare[6] = 8;
            silver_choice_rare[7] = 9;
            silver_choice_rare[8] = 11;
            silver_choice_rare[9] = 12;
            
            silver_choice_epic[0] = 0;
            silver_choice_epic[1] = 1;
            silver_choice_epic[2] = 2;
            silver_choice_epic[3] = 3;
            silver_choice_epic[4] = 4;
            
            
            gold_choice_rare[0] = 0;
            gold_choice_rare[1] = 1;
            gold_choice_rare[2] = 2;
            gold_choice_rare[3] = 3;
            gold_choice_rare[4] = 4;
            
            gold_choice_epic[0] = 5;
            gold_choice_epic[1] = 6;
            gold_choice_epic[2] = 9;
            gold_choice_epic[3] = 11;
            
            gold_choice_legendary[0] = 0;
            gold_choice_legendary[1] = 1;
            gold_choice_legendary[2] = 2;
            gold_choice_legendary[3] = 3;
            gold_choice_legendary[4] = 4;
            gold_choice_legendary[5] = 5;
            gold_choice_legendary[6] = 6;
            gold_choice_legendary[7] = 9;
            gold_choice_legendary[8] = 11;

        }
    }
 
     // utils
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function substring(string memory str, uint256 startIndex, uint256 endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
    
    function concat(string memory _base, string memory _value) public pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }
    
    function randint() internal view returns (uint) {
        // sha3 and now have been deprecated
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        // convert hash to integer
        // players is an array of entrants
        
    }
    
    function randrange(uint a, uint b) public view returns(uint) {
        return a + (randint() % b);
    }
    
    function uint2str(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }   
    
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}





library Counters {
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}


contract MFFPlayers is ERC721URIStorage, Ownable, MFFUtils {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(address => uint256[]) public userOwnedTokens;
    mapping(uint256 => int256) public tokenIsAtIndex;
    address payable payeeAddr = _to_payable(owner());
    uint256 randNonce = 0;
    uint256 choice = 0;
    uint256 choice2 = 0;

    // units NFTs
    constructor() ERC721("MFFPlayer", "MFF") {}

    function mintPlayer(
        address user,
        string memory tokenURI,
        string memory _player
    ) public payable returns (uint256) {
        require(availableNFT[getNFTName(_player)] > 0, "This NFT is sold out");
        require(msg.value == getPrice(_player));

        availableNFT[getNFTName(_player)]--;

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(user, newItemId);
        _setTokenURI(newItemId, tokenURI);

        userOwnedTokens[user].push(newItemId);
        uint256 arrayLength = userOwnedTokens[user].length;
        tokenIsAtIndex[newItemId] = int256(arrayLength);

        return newItemId;
    }

    // NFTs packs
    function setNFTPackCost(uint256 _price, string memory _packName)
        external
        onlyOwner
    {
        pack_price_list[_packName] = _price;
    }

    function setNFTPackNb(string memory _packName, uint256 _qte)
        external
        onlyOwner
    {
        availableNFTPack[_packName] = _qte;
    }

    function preformat_nameForPack(
        uint256 _i,
        string memory _packName,
        string memory _niveau,
        string memory _color
    ) internal pure returns (string[3] memory) {
        string memory tokenURI;
        string memory player;
        string memory nft_name_pack;
        string memory pos;
        string memory pack_nft_url;

        tokenURI = "";
        player = "";
        nft_name_pack = "";
        pos = "";
        pack_nft_url = "https://gateway.pinata.cloud/ipfs/QmRfyKhuY3naXiWZUCj89aWFfDDDQFpfFgyupLSrAa8zeo/";

        nft_name_pack = concat(_packName, "_");
        nft_name_pack = concat(nft_name_pack, _niveau);
        nft_name_pack = concat(nft_name_pack, "_");

        if (_i < 10) {
            nft_name_pack = concat(nft_name_pack, "00");
            nft_name_pack = concat(nft_name_pack, uint2str(_i));
            player = concat("tet-00", uint2str(_i));
            pos = concat("-pos-00", uint2str(_i));
        } else {
            if (_i < 100) {
                nft_name_pack = concat(nft_name_pack, "0");
                nft_name_pack = concat(nft_name_pack, uint2str(_i));
                player = concat("tet-0", uint2str(_i));
                pos = concat("-pos-0", uint2str(_i));
            } else {
                nft_name_pack = concat(nft_name_pack, uint2str(_i));
                player = concat("tet-", uint2str(_i));
                pos = concat("-pos-", uint2str(_i));
            }
        }

        pos = concat(pos, "-");

        tokenURI = concat(pack_nft_url, concat(player, "-"));
        tokenURI = concat(tokenURI, _niveau);
        tokenURI = concat(tokenURI, ".json");

        if (_i == 9 || _i == 11 || _i == 12) {
            if (compareStrings(_niveau, "common")) {
                player = concat(player, "-bak-001-");
            }
            if (compareStrings(_niveau, "uncommon")) {
                player = concat(player, "-bak-006-");
            }
            if (compareStrings(_niveau, "rare")) {
                player = concat(player, "-bak-007-");
            }
            if (compareStrings(_niveau, "epic")) {
                player = concat(player, "-bak-008-");
            }
            if (compareStrings(_niveau, "legendary")) {
                player = concat(player, "-bak-009-");
            }

            player = concat(player, _color);
            player = concat(player, pos);
            player = concat(player, "cor-000");
        } else {
            if (compareStrings(_niveau, "common")) {
                player = concat(player, "-bak-001-");
            }
            if (compareStrings(_niveau, "uncommon")) {
                player = concat(player, "-bak-002-");
            }
            if (compareStrings(_niveau, "rare")) {
                player = concat(player, "-bak-003-");
            }
            if (compareStrings(_niveau, "epic")) {
                player = concat(player, "-bak-004-");
            }
            if (compareStrings(_niveau, "legendary")) {
                player = concat(player, "-bak-005-");
            }

            player = concat(player, _color);
            player = concat(player, pos);
            player = concat(player, "cor-001");
        }

        string[3] memory retour;

        retour[0] = nft_name_pack;
        retour[1] = player;
        retour[2] = tokenURI;

        return retour;
    }

    function mintPack(
        address user,
        string memory _packName,
        string memory _color
    ) public payable returns (uint256[5] memory) {
        require(availableNFTPack[_packName] > 0, "This Pack is sold out");
        require(msg.value == pack_price_list[_packName]);

        availableNFTPack[_packName]--;

        uint256 nb_goals;
        uint256 nb_joueurs;
        uint256 nb_c;
        uint256 i;
        uint256[5] memory nft_list;
        string[3] memory formatedName;
        string memory tokenURI;
        string memory player;
        string memory nft_name_pack;

        tokenURI = "";
        player = "";
        nft_name_pack = "";
        nb_goals = 1;
        nb_joueurs = 4;
        nb_c = 0;

        if (compareStrings(_packName, "bronze")) {
            i = 12;

            if (nft_qte_per_pack["bronze_common_012"] > 0) {
                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "common",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_goals--;
                nb_c = 1;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[0] = mintPlayerPack(user, tokenURI, player);
            } else {
                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "uncommon",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_goals--;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[0] = mintPlayerPack(user, tokenURI, player);
            }

            if (nb_c == 1) {
                i = 0;
                if (choice >= bronze_choice_uncommon.length) {
                    choice = 0;
                }

                for (choice; choice < bronze_choice_uncommon.length; choice++) {
                    if (i == 0) {
                        i = getJoueurID("bronze_uncommon", choice);
                    }
                }

                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "uncommon",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_joueurs--;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[1] = mintPlayerPack(user, tokenURI, player);
            } else {
                i = 0;
                if (choice >= bronze_choice_common.length) {
                    choice = 0;
                }

                for (choice; choice < bronze_choice_common.length; choice++) {
                    if (i == 0) {
                        i = getJoueurID("bronze_common", choice);
                    }
                }

                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "common",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_joueurs--;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[1] = mintPlayerPack(user, tokenURI, player);
            }

            // Common
            if (choice >= bronze_choice_common.length) {
                choice = 0;
            }

            for (choice; choice < bronze_choice_common.length; choice++) {
                if (i == 0) {
                    i = getJoueurID("bronze_common", choice);
                }
            }

            formatedName = preformat_nameForPack(
                i,
                _packName,
                "common",
                _color
            );

            nft_name_pack = formatedName[0];
            player = formatedName[1];
            tokenURI = formatedName[2];

            nb_joueurs--;

            nft_qte_per_pack[nft_name_pack]--;
            nft_list[2] = mintPlayerPack(user, tokenURI, player);

            // uncommon

            if (nft_qte_per_pack["bronze_uncommon_008"] > 0) {
                i = 8;
            } else {
                i = 7;
            }

            formatedName = preformat_nameForPack(
                i,
                _packName,
                "uncommon",
                _color
            );

            nft_name_pack = formatedName[0];
            player = formatedName[1];
            tokenURI = formatedName[2];

            nb_joueurs--;

            nft_qte_per_pack[nft_name_pack]--;
            nft_list[3] = mintPlayerPack(user, tokenURI, player);

            // Rare 1
            if (choice2 >= bronze_choice_rare.length) {
                choice2 = 0;
            }

            i = bronze_choice_rare[choice2];
            nft_name_pack = "bronze_rare_";

            if (i < 10) {
                nft_name_pack = concat(nft_name_pack, "00");
                nft_name_pack = concat(nft_name_pack, uint2str(i));
            } else {
                if (i < 100) {
                    nft_name_pack = concat(nft_name_pack, "0");
                    nft_name_pack = concat(nft_name_pack, uint2str(i));
                } else {
                    nft_name_pack = concat(nft_name_pack, uint2str(i));
                }
            }

            if (nft_qte_per_pack[nft_name_pack] == 0) {
                choice2 = 0;
                for (choice2; choice2 < bronze_choice_rare.length; choice2++) {
                    if (i == 0) {
                        i = getJoueurID("bronze_rare", choice2);
                    }
                }
            }

            choice2++;

            formatedName = preformat_nameForPack(i, _packName, "rare", _color);

            nft_name_pack = formatedName[0];
            player = formatedName[1];
            tokenURI = formatedName[2];

            nb_joueurs--;

            nft_qte_per_pack[nft_name_pack]--;
            nft_list[4] = mintPlayerPack(user, tokenURI, player);
        }

        if (compareStrings(_packName, "silver")) {
            i = 12;

            if (nft_qte_per_pack["silver_common_012"] > 0) {
                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "common",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_goals--;
                nb_c = 1;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[0] = mintPlayerPack(user, tokenURI, player);
            } else {
                if (nft_qte_per_pack["silver_rare_012"] > 0) {
                    formatedName = preformat_nameForPack(
                        i,
                        _packName,
                        "rare",
                        _color
                    );

                    nft_name_pack = formatedName[0];
                    player = formatedName[1];
                    tokenURI = formatedName[2];

                    nb_goals--;

                    nft_qte_per_pack[nft_name_pack]--;
                    nft_list[0] = mintPlayerPack(user, tokenURI, player);
                } else {
                    if (nft_qte_per_pack["silver_rare_011"] > 0) {
                        i = 11;
                        formatedName = preformat_nameForPack(
                            i,
                            _packName,
                            "rare",
                            _color
                        );

                        nft_name_pack = formatedName[0];
                        player = formatedName[1];
                        tokenURI = formatedName[2];

                        nb_goals--;

                        nft_qte_per_pack[nft_name_pack]--;
                        nft_list[0] = mintPlayerPack(user, tokenURI, player);
                    } else {
                        i = 9;
                        formatedName = preformat_nameForPack(
                            i,
                            _packName,
                            "rare",
                            _color
                        );

                        nft_name_pack = formatedName[0];
                        player = formatedName[1];
                        tokenURI = formatedName[2];

                        nb_goals--;

                        nft_qte_per_pack[nft_name_pack]--;
                        nft_list[0] = mintPlayerPack(user, tokenURI, player);
                    }
                }
            }

            if (nb_c == 1) {
                i = 0;
                if (choice >= silver_choice_rare.length) {
                    choice = 0;
                }

                for (uint256 j = 0; j < silver_choice_rare.length - 3; j++) {
                    if (i == 0) {
                        i = getJoueurID("silver_rare", choice);
                        choice++;
                    }
                }

                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "rare",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_joueurs--;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[1] = mintPlayerPack(user, tokenURI, player);
            } else {
                i = 0;
                if (choice >= silver_choice_common.length - 1) {
                    choice = 0;
                }

                for (choice; choice < silver_choice_common.length; choice++) {
                    if (i == 0) {
                        i = getJoueurID("silver_common", choice);
                    }
                }

                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "common",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_joueurs--;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[1] = mintPlayerPack(user, tokenURI, player);
            }

            // Rare
            if (choice >= silver_choice_rare.length - 3) {
                choice = 0;
            }
            i = 0;
            for (uint256 j = 0; j < silver_choice_rare.length; j++) {
                if (i == 0) {
                    i = getJoueurID("silver_rare", choice);
                    choice++;
                }
            }

            formatedName = preformat_nameForPack(i, _packName, "rare", _color);

            nft_name_pack = formatedName[0];
            player = formatedName[1];
            tokenURI = formatedName[2];

            nb_joueurs--;

            nft_qte_per_pack[nft_name_pack]--;
            nft_list[2] = mintPlayerPack(user, tokenURI, player);

            // Rare
            if (choice >= silver_choice_rare.length - 3) {
                choice = 0;
            }
            i = 0;
            for (uint256 j = 0; j < silver_choice_rare.length; j++) {
                if (i == 0) {
                    i = getJoueurID("silver_rare", choice);
                    choice++;
                }
            }

            formatedName = preformat_nameForPack(i, _packName, "rare", _color);

            nft_name_pack = formatedName[0];
            player = formatedName[1];
            tokenURI = formatedName[2];

            nb_joueurs--;

            nft_qte_per_pack[nft_name_pack]--;
            nft_list[3] = mintPlayerPack(user, tokenURI, player);

            // Epic
            if (choice2 >= silver_choice_epic.length) {
                choice2 = 0;
            }

            i = silver_choice_epic[choice2];
            nft_name_pack = "silver_epic_";

            if (i < 10) {
                nft_name_pack = concat(nft_name_pack, "00");
                nft_name_pack = concat(nft_name_pack, uint2str(i));
            } else {
                if (i < 100) {
                    nft_name_pack = concat(nft_name_pack, "0");
                    nft_name_pack = concat(nft_name_pack, uint2str(i));
                } else {
                    nft_name_pack = concat(nft_name_pack, uint2str(i));
                }
            }

            if (nft_qte_per_pack[nft_name_pack] == 0) {
                choice2 = 0;
                for (choice2; choice2 < silver_choice_epic.length; choice2++) {
                    if (i == 0) {
                        i = getJoueurID("silver_epic", choice2);
                    }
                }
            }

            choice2++;

            formatedName = preformat_nameForPack(i, _packName, "epic", _color);

            nft_name_pack = formatedName[0];
            player = formatedName[1];
            tokenURI = formatedName[2];

            nb_joueurs--;

            nft_qte_per_pack[nft_name_pack]--;
            nft_list[4] = mintPlayerPack(user, tokenURI, player);
        }

        if (compareStrings(_packName, "gold")) {
            i = 11;

            if (nft_qte_per_pack["gold_epic_011"] > 0) {
                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "epic",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_goals--;
                nb_c = 1;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[0] = mintPlayerPack(user, tokenURI, player);
            } else {
                if (nft_qte_per_pack["gold_epic_009"] > 0) {
                    i = 9;
                    formatedName = preformat_nameForPack(
                        i,
                        _packName,
                        "epic",
                        _color
                    );

                    nft_name_pack = formatedName[0];
                    player = formatedName[1];
                    tokenURI = formatedName[2];

                    nb_goals--;
                    nb_c = 1;

                    nft_qte_per_pack[nft_name_pack]--;
                    nft_list[0] = mintPlayerPack(user, tokenURI, player);
                } else {
                    if (nft_qte_per_pack["gold_legendary_011"] > 0) {
                        i = 11;
                        formatedName = preformat_nameForPack(
                            i,
                            _packName,
                            "legendary",
                            _color
                        );

                        nft_name_pack = formatedName[0];
                        player = formatedName[1];
                        tokenURI = formatedName[2];

                        nb_goals--;

                        nft_qte_per_pack[nft_name_pack]--;
                        nft_list[0] = mintPlayerPack(user, tokenURI, player);
                    } else {
                        i = 9;
                        formatedName = preformat_nameForPack(
                            i,
                            _packName,
                            "legendary",
                            _color
                        );

                        nft_name_pack = formatedName[0];
                        player = formatedName[1];
                        tokenURI = formatedName[2];

                        nb_goals--;

                        nft_qte_per_pack[nft_name_pack]--;
                        nft_list[0] = mintPlayerPack(user, tokenURI, player);
                    }
                }
            }

            if (nb_c == 1) {
                i = 0;
                if (choice >= gold_choice_legendary.length) {
                    choice = 0;
                }

                for (uint256 j = 0; j < gold_choice_legendary.length - 2; j++) {
                    if (i == 0) {
                        i = getJoueurID("gold_legendary", choice);
                    }
                }

                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "legendary",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_joueurs--;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[1] = mintPlayerPack(user, tokenURI, player);
            } else {
                i = 0;
                if (choice >= gold_choice_epic.length) {
                    choice = 0;
                }

                for (choice; choice < gold_choice_epic.length - 2; choice++) {
                    if (i == 0) {
                        i = getJoueurID("gold_epic", choice);
                    }
                }

                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "epic",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_joueurs--;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[1] = mintPlayerPack(user, tokenURI, player);
            }

            // Rare
            for (uint256 t = 2; t < 5; t++) {
                if (choice >= gold_choice_rare.length) {
                    choice = 0;
                }
                i = 0;
                for (uint256 j = 0; j < gold_choice_rare.length; j++) {
                    if (i == 0) {
                        i = getJoueurID("gold_rare", choice);
                        choice++;
                    }
                }

                formatedName = preformat_nameForPack(
                    i,
                    _packName,
                    "rare",
                    _color
                );

                nft_name_pack = formatedName[0];
                player = formatedName[1];
                tokenURI = formatedName[2];

                nb_joueurs--;

                nft_qte_per_pack[nft_name_pack]--;
                nft_list[t] = mintPlayerPack(user, tokenURI, player);
            }
        }

        return nft_list;
    }

    function mintPlayerPack(
        address user,
        string memory tokenURI,
        string memory _player
    ) internal returns (uint256) {
        require(availableNFT[getNFTName(_player)] > 0, "This NFT is sold out");

        availableNFT[getNFTName(_player)]--;

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(user, newItemId);
        _setTokenURI(newItemId, tokenURI);

        userOwnedTokens[user].push(newItemId);
        uint256 arrayLength = userOwnedTokens[user].length;
        tokenIsAtIndex[newItemId] = int256(arrayLength);

        return newItemId;
    }

    function getJoueurID(string memory _card, uint256 _nb)
        internal
        view
        returns (uint256)
    {
        uint256 i = _nb;
        string memory nft_name_pack = concat(_card, "_");

        if (compareStrings(_card, "bronze_common")) {
            i = bronze_choice_common[i];
        }
        if (compareStrings(_card, "bronze_uncommon")) {
            i = bronze_choice_uncommon[i];
        }
        if (compareStrings(_card, "bronze_rare")) {
            i = bronze_choice_rare[i];
        }

        if (compareStrings(_card, "silver_common")) {
            i = silver_choice_common[i];
        }
        if (compareStrings(_card, "silver_rare")) {
            i = silver_choice_rare[i];
        }
        if (compareStrings(_card, "silver_epic")) {
            i = silver_choice_epic[i];
        }

        if (compareStrings(_card, "gold_rare")) {
            i = gold_choice_rare[i];
        }
        if (compareStrings(_card, "gold_epic")) {
            i = gold_choice_epic[i];
        }
        if (compareStrings(_card, "gold_legendary")) {
            i = gold_choice_legendary[i];
        }

        if (i < 10) {
            nft_name_pack = concat(nft_name_pack, "00");
            nft_name_pack = concat(nft_name_pack, uint2str(i));
        } else {
            if (i < 100) {
                nft_name_pack = concat(nft_name_pack, "0");
                nft_name_pack = concat(nft_name_pack, uint2str(i));
            } else {
                nft_name_pack = concat(nft_name_pack, uint2str(i));
            }
        }

        if (nft_qte_per_pack[nft_name_pack] == 0) {
            return 0;
        } else {
            return i;
        }
    }

    // Utils
    function withdraw() public onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }

    function _to_payable(address adr)
        internal
        view
        virtual
        returns (address payable)
    {
        return payable(adr); // added payable
    }

    function setNewCatList(string memory _bak, string memory _cat)
        external
        onlyOwner
    {
        category_list[_bak] = _cat;
    }

    function addNewNFT(string memory _player, uint256 _nb) external onlyOwner {
        availableNFT[getNFTName(_player)] = _nb;
    }

    function setNFTCost(uint256 _price, string memory _Cardtype)
        external
        onlyOwner
    {
        price_list[_Cardtype] = _price;
    }
}