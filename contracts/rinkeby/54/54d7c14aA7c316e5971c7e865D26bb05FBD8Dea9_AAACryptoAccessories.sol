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


contract AAACryptoAccessories is IERC1155MetadataURI
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
            0x3b10256766A47d39D3ED484cF7C6c10987d0F33a,
            0x3b10256766A47d39D3ED484cF7C6c10987d0F33a,
            0xe9099FfeecA205007e5E34269093496723f51931,
            0x32d74c620Da3DB24747F453c5d01c87a83462139,
            0x37660b87525559598c053f0f5b4c93C44Ec35E13,
            0x05Ae78DD0DFDCB23f1B09186D07f0BD3dFcBa4F2,
            0x0d9D145c19E9C1a25a8F48a1Ca786c3306Ca2C4A,
            0x2b1f45DD72b278A829f0d047eB7Ed8A64EC80D92,
            0xee183D9E1e2D133648829b37f5a0aB6436628C55,
            0xE484a9d4E2b4Ecd2375EE77872241801dfC2aB4e,
            0x619d70d46b64239bf5060bc12011F4b47d2aC825,
            0x1d16F4dE6e3d0700ee9820772C0653C0F0A45ca2,
            0x7255FE6f25ecaED72E85338c131D0daA60724Ecc,
            0x373EBaf766B3cC6AA5f3758e73b1EbE47ff51caD,
            0xb2B66dEE9aFbfAF5f58fBD856be93e872D0C93af,
            0xe690246B2d5EA702c7bEF844f8e5dD73694405Ca,
            0x83656f67BeEa8F4Df00a5089Aa82b41Bc11cdCE9,
            0x09678D7f6187Ce98a2333F509D9fa8F9bCaA2C5E,
            0x1094bBE0BB8cbFA94d549DF5ce122020F6add50A,
            0x387Fd01eb7B7Fd5B99A5f5b8419148288d3898a4,
            0x8150c915503aD4ED19c89145B5cec16b838aD902,
            0x3808fD269346976fDb5753ba25761899EAaA8C0A,
            0xadAE7d61F8Da4E626493646Ea14fd713045E6d1f,
            0x2b43aeC1A9aF8E63E56f9B56E4Ab37348bFad139,
            0x3ECB064c3b116Fe3C60Fd3950C68DeC7CF8A7cfc,
            0xE2efacc45cb0e006172c91dd3FcD9A60Dd4AE0D5,
            0xD5FcCFe43D2d3A84f4cc8864b88A202D9d8cF69d,
            0x99BF3b218bEE3aA3c8b90d727EB9057c4B224251,
            0xdea5f0ced7F50e0A2b37C7Ad9df0e2eD368739D4,
            0xB4282b8B6feafAd7A4731Cb377340C2a519d770b,
            0xc955Ce75796eF64eB1F09e9eff4481c8968C9346,
            0x9B03891a8251c448B6C5D55556c43c3E0C64b924,
            0xC3096eACEd76Bf8140920Cfc532191a818FAcB45,
            0x5d8aA9Df3696f30817C20F515DA0D5e0aB98E7f2,
            0x09209A7BA708da2111f971ad6800386F68441754,
            0xdfDC3d90E83Ad1e283265E9206d2aCB15EF87f74,
            0xeC88381602b2ea9BfC959984f0F33495282bFf0B,
            0x987994601E75C643eE13CaA861975524c2EaF7aC,
            0xC87f562f77Ef747e232D89ba952570F59C298A2B,
            0x344bA2F42077B7206ed62cE745fd15477Bdf1795,
            0xa1CFaE3082b21009495fAA57455Ee69A696dA4dD,
            0x7704B95D00e01016bE164a32ad37a20Ae8234b89,
            0xF8298fCFA36981DD5aE401fD1d880B16464C5860,
            0xB8E75Ec8021759919819240d62ed89028f3e4B9D,
            0x99BF3b218bEE3aA3c8b90d727EB9057c4B224251,
            0x191EB06b656AF55004a02d9e207b5C379978200A,
            0x4d4f7453F3a6139B24386d844785e6b4C01871A3,
            0xe50E67bDB542340647Af845e94E1F6926b24c181,
            0x849E0998e3276753bb3a90884480D7154e42Fb61,
            0x8a94cC6Cf58d6318Cc7834a1195C85c013C08DB9,
            0x57E2d6B9c4548eF6E44A05828fF1D369DE3F9dFc,
            0xD79A5d91b4510cd26103591F83Ccb2268715F664,
            0x4ee470c6f6A678adF8ddD5879Fd85A0d9cbD386b,
            0x360f58916AbB5cc07b5512B5a6dF50Eb603Aa4A4,
            0xb47C91f55896fe899393f9A7ecFD6A4426bb0AbF,
            0x4edbfC403139860085a8a68e716ef9c2a0ec8471,
            0x909D001fa57D69595abFf923355f0bA3D3a2a0B9
        ];
        _addToWhitelist1(_whiteListedAddresses);    
        
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function addToWhitelist(address[] memory newusers, uint numeration) external { // numeration of whitelist
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

    function removeFromWhitelist(address[] memory newusers, uint numeration) external { // numeration of whitelist
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

    function uri(uint256 id) public view override returns (string memory){
            return string(abi.encodePacked(_defaultUri, id));
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