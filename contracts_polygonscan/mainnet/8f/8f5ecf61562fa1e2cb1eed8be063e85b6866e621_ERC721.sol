/**
 *Submitted for verification at polygonscan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;
    
    
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
        
        event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
        event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    
        event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
        function balanceOf(address _owner) external view returns (uint256);
    
        function ownerOf(uint256 _tokenId) external view returns (address);
        
        function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;
    
        function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    
        function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
        function approve(address _approved, uint256 _tokenId) external;
    
        function setApprovalForAll(address _operator, bool _approved) external;
    
        function getApproved(uint256 _tokenId) external view returns (address);
    
        function isApprovedForAll(address _owner, address _operator) external view returns (bool);
        
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
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
        
        function totalSupply() external view returns(uint256);
        
        /**
         * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
         */
        function tokenURI(uint256 tokenId) external view returns (string memory);
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
            // solhint-disable-next-line no-inline-assembly
            assembly { size := extcodesize(account) }
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
            (bool success, ) = recipient.call{ value: amount }("");
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
            (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    
        function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
    
    library Strings {
        bytes16 private constant alphabet = "0123456789abcdef";
    
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
                buffer[i] = alphabet[value & 0xf];
                value >>= 4;
            }
            require(value == 0, "Strings: hex length insufficient");
            return string(buffer);
        }
    
    }
    
    abstract contract ERC165 is IERC165 {
        /**
         * @dev See {IERC165-supportsInterface}.
         */
        function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
            return interfaceId == type(IERC165).interfaceId;
        }
    }
    
    contract ERC721 is ERC165, IERC721, IERC721Metadata {
        using Address for address;
        using Strings for uint256;
    
        string private uriLink = "siudgusdjagsdahsd.com";
        
        bool private _minting = true;
        
        address payable private _owner;
        
        uint256 private _count;
        
        string private _name;
    
        string private _symbol;
    
        mapping(uint256 => address) private _owners;
        
        mapping(uint256 => string) private _uri;
    
        mapping(address => uint256) private _balances;
    
        mapping(uint256 => address) private _tokenApprovals;
        
        mapping(address => bool) private _minted;
    
        mapping(address => mapping(address => bool)) private _operatorApprovals;
    
        constructor (string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
            _owners[0] = msg.sender;
            _balances[msg.sender] = 1;
            _owner = payable(msg.sender);
        }
        
        function setMinting(bool boolean) external {
            require(msg.sender == _owner);
            _minting = boolean;
        }
        
        function transferOwnership(address to) external {
            require(msg.sender == _owner);
            _owner = payable(to);
        }
        
        function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
            return interfaceId == type(IERC721).interfaceId
                || interfaceId == type(IERC721Metadata).interfaceId
                || super.supportsInterface(interfaceId);
        }
    
        function balanceOf(address owner) public view virtual override returns (uint256) {
            require(owner != address(0), "ERC721: balance query for the zero address");
            return _balances[owner];
        }
    
        function ownerOf(uint256 tokenId) public view virtual override returns (address) {
            address owner = _owners[tokenId];
            require(owner != address(0), "ERC721: owner query for nonexistent token");
            return owner;
        }
    
        function name() public view virtual override returns (string memory) {
            return _name;
        }
    
        function symbol() public view virtual override returns (string memory) {
            return _symbol;
        }
        
        function totalSupply() external view override returns(uint256){return 4444;}
    
        function tokenURI(uint256 tokenId) external view override returns (string memory) {
            return _uri[tokenId];
        }
    
        function _baseURI() internal view virtual returns (string memory) {
            return "";
        }
    
        function approve(address to, uint256 tokenId) external override {
            address owner = ERC721.ownerOf(tokenId);
            require(to != owner, "ERC721: approval to current owner");
    
            require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
                "ERC721: approve caller is not owner nor approved for all"
            );
    
            _approve(to, tokenId);
        }
    
        function getApproved(uint256 tokenId) public view virtual override returns (address) {
            require(_exists(tokenId), "ERC721: approved query for nonexistent token");
    
            return _tokenApprovals[tokenId];
        }
    
        function setApprovalForAll(address operator, bool approved) public virtual override {
            require(operator != msg.sender, "ERC721: approve to caller");
    
            _operatorApprovals[msg.sender][operator] = approved;
            emit ApprovalForAll(msg.sender, operator, approved);
        }
    
        function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
            return _operatorApprovals[owner][operator];
        }
    
        function transferFrom(address from, address to, uint256 tokenId) external override {
            //solhint-disable-next-line max-line-length
            require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    
            _transfer(from, to, tokenId);
        }
    
        function safeTransferFrom(address from, address to, uint256 tokenId) external override {
            _transfer(from, to, tokenId);
            require(_checkOnERC721Received(from, to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
        }
    
        function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external override {
            require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
            _safeTransfer(from, to, tokenId, _data);
        }
    
        function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
            _transfer(from, to, tokenId);
            require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
        }
    
        function _exists(uint256 tokenId) internal view returns (bool) {
            return _owners[tokenId] != address(0);
        }
    
        function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
            require(_exists(tokenId), "ERC721: operator query for nonexistent token");
            address owner = _owners[tokenId];
            require(spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender), "ERC721: Not approved or owner");
            return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
        }
    
        function mint(address to) external payable returns(uint256 ID){
            require(!_minted[msg.sender]);
            require(_count < 4444, "All NFT's minted");
            require(_minting, "Minting disabeled");
            require(msg.value == 50000000000000000, "Insufficient Eth");
            _owner.transfer(address(this).balance);
            require(to != address(0), "ERC721: mint to the zero address");
            
            uint256 count = _count;
            string memory link = uriLink;
            
            ++_balances[to];
            _owners[count] = to;
                
            string memory uri = concat(link, count.toString());
            uri = concat(uri, ".json");
            _uri[count] = uri;
            
            ++_count;
            
            emit Transfer(address(0), to, count);
            
            _minted[msg.sender] = true;
            return count;
        }
    
        function concat(string memory _base, string memory _value) pure internal returns (string memory) {
            bytes memory _baseBytes = bytes(_base);
            bytes memory _valueBytes = bytes(_value);
            
            string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
            bytes memory _newValue = bytes(_tmpValue);
            
            uint i;
            uint j;
            
            for(i=0;i<_baseBytes.length;i++) {
                _newValue[j++] = _baseBytes[i];
            }
            
            for(i=0;i<_valueBytes.length;i++) {
                _newValue[j++] = _valueBytes[i];
            }
            
            return string(_newValue);
        }
    
        function _transfer(address from, address to, uint256 tokenId) internal virtual {
            require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
            require(to != address(0), "ERC721: transfer to the zero address");
    
            // Clear approvals from the previous owner
            _approve(address(0), tokenId);
    
            _balances[from] -= 1;
            _balances[to] += 4;
            _owners[tokenId] = to;
    
            emit Transfer(from, to, tokenId);
        }
    
        function _approve(address to, uint256 tokenId) internal virtual {
            _tokenApprovals[tokenId] = to;
            emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
        }
    
        function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
            private returns (bool)
        {
            if (to.isContract()) {
                try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                    return retval == IERC721Receiver(to).onERC721Received.selector;
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERC721: transfer to non ERC721Receiver implementer");
                    } else {
                        // solhint-disable-next-line no-inline-assembly
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            } else {
                return true;
            }
        }
    }