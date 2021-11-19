/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165{
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator,address indexed from,address indexed to,uint256[] ids,uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view  returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes calldata data) external;
    function safeBatchTransferFrom(address from,address to,uint256[] calldata ids,uint256[] calldata amounts,bytes calldata data) external;
}


interface IERC1155Receiver is IERC165 {
    function onERC1155Received(address operator,address from,uint256 id,uint256 value,bytes calldata data) external returns (bytes4);
    function onERC1155BatchReceived(address operator,address from,uint256[] calldata ids,uint256[] calldata values,bytes calldata data) external returns (bytes4);
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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

interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


contract Utopia3301 is IERC1155MetadataURI
{
    using Address for address;

    mapping(address => uint256) private counts;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    string private _defaultUri;
    string public name;
    string public symbol;
    address private _owner;
    address private _owner1;
    address private _owner2;
    address private first25;
    address[] private _whiteListedAddresses;
    
    uint private _minted;
    uint private TOTAL_TOKENS = 500;
    uint private _saleEnable = 0;
    uint private _presaleEnable = 0;
    uint private _price;
    uint private MAX_TOKENS_PER_ADDR1LIST = 2;
    uint private MAX_TOKENS_PER_ADDR2LIST = 1;
    
    mapping(address => uint256) private whitelist1;
    mapping(address => uint256) private whitelist2;
    
    
    
    
    constructor( ) {
        name = "Utopia Pass";
        symbol = "UP";
        
        _setOwner(msg.sender);
        _owner1 = 0xDcb879cA3483A8505A20eb4d2853c6620D65613c;
        _owner2 = 0xEcC487709fE85fa8391c29c4f8F76e4738452687; 
        first25 = 0xDcb879cA3483A8505A20eb4d2853c6620D65613c; 
        
        _defaultUri="ipfs://ipfs/some_CID_/";
        
        _price = 0.25 ether;
        //reserve 25 tokens for addr first25, line 159
        _mint(first25, 1, 25, "");
        _whiteListedAddresses = 
        [
            0xC36f7B00320876EFf1f8F8d2e6eC5340bbA416A8,
            0x696Bd52449Ee4ca76484Bb3Ef9F59C63BA081dd3
        ];
        _addToWhitelist1(_whiteListedAddresses);    
        
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function addToWhitelist(address[] memory newusers, uint numeration) external onlyOwner { // numeration of whitelist
        for(uint256 i=0; i < newusers.length; i++){
            if (numeration == 1) {
                require(whitelist2[newusers[i]] == 0, "Whitelist: the user is already on the whitelist2"); // 
                whitelist1[newusers[i]] = 1;
            } else if (numeration == 2) {
                require(whitelist1[newusers[i]] == 0, "Whitelist: the user is already on the whitelist1");
                whitelist2[newusers[i]] = 1; 
            }
        }
    }

    function _addToWhitelist1(address[] memory newusers) internal { // numeration of whitelist
        for(uint256 i=0; i < newusers.length; i++){
            whitelist1[newusers[i]] = 1;
        }
    }

    function removeFromWhitelist(address[] memory newusers, uint numeration) external onlyOwner { // numeration of whitelist
        for(uint256 i=0; i < newusers.length; i++){
            if (numeration == 1) {
                whitelist1[newusers[i]] = 0;
            } else if (numeration == 2) {
                whitelist2[newusers[i]] = 0;
            }
        }
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    modifier saleEnabled() {
        require( _saleEnable==1, "Sale is disabled");
        _;
    }
    modifier presaleEnabled() {
        require( _presaleEnable ==1, "PreSale is disabled");
        _;
    }
    
    function enableSale() external onlyOwner{
        _saleEnable = 1;
    }
    function disableSale() external onlyOwner{
        _saleEnable = 0;
    }
    
    function enablePresale() external onlyOwner{
        _presaleEnable = 1;
    }
    function disablePresale() external onlyOwner{
        _presaleEnable = 0;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function mint(
        address _to,
        uint256 _quantity
    ) public payable saleEnabled {
        require( _price * _quantity <= msg.value, "Need more money to buy tokens");
        require( _minted + _quantity <= TOTAL_TOKENS, "Max tokens reached");    
        
        if (whitelist1[_to] == 1) {
            require( _balances[1][_to] + _quantity <= MAX_TOKENS_PER_ADDR1LIST, "Max tokens per address reached");
        } else if (whitelist2[_to] == 1) {
            require( _balances[1][_to] + _quantity <= MAX_TOKENS_PER_ADDR2LIST, "Max tokens per address reached");
        }
        
        _mint(_to, 1, _quantity, "");
        
        uint256 half_amount = msg.value / 2;
        payable(_owner1).transfer(half_amount);
        payable(_owner2).transfer(half_amount);
    }
  
    function mintPresale(
        address _to,
        uint256 _quantity
    ) public payable presaleEnabled {
        require( _price * _quantity <= msg.value, "Need more money to buy tokens");
        require( _minted + _quantity <= TOTAL_TOKENS, "Max tokens reached");          
        require(whitelist1[_to] == 1 || whitelist2[_to] == 1, "Address not allowed to buy" );
        
        if (whitelist1[_to] == 1) {
            require( _balances[1][_to] + _quantity <= MAX_TOKENS_PER_ADDR1LIST, "Max tokens per address reached, 2/2");
        } else if (whitelist2[_to] == 1) {
            require( _balances[1][_to] + _quantity <= MAX_TOKENS_PER_ADDR2LIST, "Max tokens per address reached, 1/1");
        }
        
        _mint(_to, 1, _quantity, "");
        
        uint256 half_amount = msg.value / 2;
        payable(_owner1).transfer(half_amount);
        payable(_owner2).transfer(half_amount);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");
        address operator = _msgSender();
        _balances[id][account] += amount;
        _minted = _minted + amount;
        
        emit TransferSingle(operator, address(0), account, id, amount);
        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    function setDefaultUri(string memory _uri)public onlyOwner{
        _defaultUri = _uri;
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()) ,
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()) ,
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");

        if (whitelist1[to] == 1) {
            require( _balances[id][to] + amount <= MAX_TOKENS_PER_ADDR1LIST, "Max tokens per address reached");
        } else if (whitelist2[to] == 1) {
            require( _balances[id][to] + amount <= MAX_TOKENS_PER_ADDR2LIST, "Max tokens per address reached");
        }

        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }


    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }
    
    function uri(uint256 id) public view override returns (string memory) {
        return string(
            abi.encodePacked(
            "https://ipfs.io/ipfs/QmSwgExTCt5RxZeaYntzFpJ13xVtVvqfbNaygWieAhdjrn/",
            Strings.toString(id),
            ".json"
            )
        );
    }
    
     function uri() public view  returns (string memory){
        return _defaultUri;
    }
    
    function totalSupply() public view returns (uint256) {
        return _minted;
    }
    
    function totalSupply(
        uint256 _id
      ) public view returns (uint256) {
        return _minted;
      }
  
     function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }

            if (whitelist1[to] == 1) {
                require( _balances[id][to] + amount <= MAX_TOKENS_PER_ADDR1LIST, "Max tokens per address reached");
            } else if (whitelist2[to] == 1) {
                require( _balances[id][to] + amount <= MAX_TOKENS_PER_ADDR2LIST, "Max tokens per address reached");
            }    
            
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
        function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

}