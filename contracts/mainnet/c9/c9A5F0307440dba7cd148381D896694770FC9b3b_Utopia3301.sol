/**
 *Submitted for verification at Etherscan.io on 2021-11-23
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
        first25 = 0x1FcEfb472F0e1586F79f26e5E8e13741E4076c7A; 
        
        _defaultUri="ipfs://ipfs/some_CID_/";
        
        _price = 0.25 ether;
        //reserve 25 tokens for addr first25, line 159
        _mint(first25, 1, 25, "");
        _whiteListedAddresses = 
        [
            0xCEa18c22806f2adb61bac1B3db031980A45fB5Ea,
            0x4ee470c6f6A678adF8ddD5879Fd85A0d9cbD386b,
            0xB9556D93CCFA3Cc4d66CC9A3D426Ecd7A2F21bbb,
            0xC8f9711387A6E6966D039B554d656a5c375cA97E,
            0x5a84ff45A6400dD3c203317Bb1a2Ac6CE78C4D9F,
            0x98Cd36875331bAB6Af1d99fdDC6f41d32f9f7f23,
            0xBbc6b65F6E25ADE2A97c8ff47f8adD5163849A60,
            0x9De33BeE1353E65fE86Cc274F86Ade0439021576,
            0x526Dc23263a5ed4EC20b0944AC1951C348199Ef3,
            0x39fC4291f38FFb27d17B9c2b46BB8e5019e23AcE,
            0x972A6D9674A261a3C4BEcb2038B7E5D6ec9b09e9,
            0x12569E01f1F8d64AC0367B5ECA6948EABa5D97e2,
            0x1DbEa852180D4B51bAd2a90eB5791309515d49c7,
            0x9B03891a8251c448B6C5D55556c43c3E0C64b924,
            0x4eBb9E1909feC61A035Aac994053260522262919,
            0xd80438E0CF0b60e41ee8B21387b724F6609b5cE4,
            0x5819Ee729ec366Ce1e4C681A1d23DE2C966CddA5,
            0x379e916535e017Cc2B22c4C099F61FA2D73a960C,
            0x467cc59F1ce2045b0cDc4E85d941BD8cb8DCBd2e,
            0xC55C754b9F11198BFcB5b6f1315D47DaADa0C4ab,
            0xcd38e361c232CE889CB4458D90eBc031D63c2A8A,
            0x8d701bD0504A13aa89BdBD30ad45688d11AdEaCa,
            0x58d5b48Bdc6270F9eD3DBCe945960d390ea281eE,
            0x05d93eC016c4aE7a653fE79E6DA7746073AFB94f,
            0x2b6cD34F241a34C24b058C70616eF4C81C5f9eb8,
            0xa3b11D1f06d71eaA9cD3d0142F08E7AcE9b474eC,
            0x5f444d38bB4CD9338EB727d3E2E0A6A24aAAc886,
            0xc59f2589aFC329Bd0008D7Ce19348031dffA28aa,
            0x41F8EAFDE35fEB8A5962C0E0Ba445ceeA2e5c12e,
            0xBf3633ed017339328a7C00a54dAEF8Eb306c103e,
            0x221fCe6B6dAc61520C1C283825e29Bb556979111,
            0xC539AC0aaE0a5f1B1A0C0dB9d5bBD2E6D4d50288,
            0x612952a8D811B3Cd5626eBc748d5eB835Fcf724B,
            0xF21a309D02ffAd0C133577e50937892C4643B709,
            0xd79a9865F5866760B77D7f82e35316662dEC6793,
            0xbC19738d9D26F587be394574253CD8efa732505d,
            0x2953D07a05c71C5C4A9DB463e26Fb80749199A61,
            0x22E7259B76fB34ABc2ee4d60BC996727b3B79a83,
            0xE098CD6692Bf1af1F1287dd8e56D4A3D9C543dEB,
            0xeA57994eb2d110888905fbB9D90DC29a54D0ea3C,
            0xA8e1a4D37884aE493d63ac5224028Cf98a6eA233,
            0xDb11B192249b414Aa6cc1e7F1d7414eCF59C36aF,
            0x3c5FAAf770511E403fD907E6d77Ac8F5bC699CBe,
            0x78d13A345B7987fEdbC54Ead3E6f8d75CE668bd3,
            0xB7e5A2fcE41196D74f200Cc7Ce926EF20a8Ff452,
            0x7701cC2986207232b88e88DFDd4E1BE18B5381b9,
            0xE67A7dD0a6E086ea3a3b61edB0406a04e335CFCf,
            0xaf68d7887074963722888a91362d0D542F29Dea3,
            0xe169B92348e5BE50D9eF9310b46ce17716bFb78D,
            0xc3Abc862eA13fF183DBbB9676163C1E13e4647ba,
            0x5B7E678C85BF2C8Df77D2bcD30b74AdAe6b7874F,
            0x5F77b880eae0E97B3E00c0c442f4605f6BCC61aD,
            0x37660b87525559598c053f0f5b4c93C44Ec35E13,
            0x71651F0053C3c4ef3658809e9898c649a1b67aEb,
            0xebE9f2bBD5e7b3b8099233aFff654c6a9BaC679C,
            0xbe8D8FBfc6582C55869222BceB30Be3fe9572056,
            0xace354020076D59E4920cC9f271E5A151014e760,
            0x4923179E970f4e466e446a228EF86792EDe2A6C3,
            0x995e7FC77F43343A23A90c65e4Ea84F7b54B24E9,
            0x6d4678D0B9E4e1D1E025aC30f0BADC3871B96183,
            0xa61ca29DB1A127bcBBf55AE85c2B917Ed5D9089a,
            0x2987fcD32d9D1Cd4Dbd30425D0DCeB05DEED0318,
            0x469264AfE93730d82e386e72B24cb1F736f164Ef,
            0xdfDC3d90E83Ad1e283265E9206d2aCB15EF87f74,
            0x8365236b8b29EBe2A67eE167E605cFb7f28bd393,
            0x3808fD269346976fDb5753ba25761899EAaA8C0A,
            0x6Af844c98BF3eb3d918f371b3c59417D7c851a71,
            0xA1F6E60B2C65A660580671764933247562c901A4,
            0x4162eA18d68e2e385a9e39325aeFFCebb70f42D6,
            0xACcC4cf8258B619027FF8058d7737Ed3CCd28965,
            0x041A6c3bB3784465ec6d1042BD97b608AD88ECd4,
            0xe77064473BE26ce57405f2aAa341470d9626f725,
            0xa1c985c386E3B1588e1c8c910AC742077cA01Bd7,
            0x71e9CA9e48Eb2d621535C274Dd21a985B73E0Dd4,
            0x4e3D5a999FfB1AF101E780d491F325bBEb413285,
            0x8482B54C571530A5f155bdb2BfFf31DcD1DB1e34,
            0x3808fD269346976fDb5753ba25761899EAaA8C0A,
            0x0029dd4662551C9939e3aD378417100A3fED3b8C,
            0xd943843977daEB63d8e1e2Dd7172f69390a231A0,
            0x8365236b8b29EBe2A67eE167E605cFb7f28bd393,
            0xaf32e3A19A551487D0191E07C939B0ED18eDA1f0,
            0x160583a6C15f6E59085827c9c7ce5D744603eFDb,
            0x462872d18dB59f13e7A965788A89B0e43469965F,
            0x2a094A27AE3a79BfEFf1483502A9783e2504041B,
            0x9Bd4b05B6F3cD3778012f72C16c42Fd0490CfB3e,
            0x515B8339eFF4CB3bb87C3627aCFbF242B612a708,
            0x468B589384265937a5983E7a9C4F0B0B5A11B82f,
            0x93823D23e3eEbf844093C11cB0d0710C8c0c8eA4,
            0x877444579532453050720cEd6a8A66C0c60B04C8,
            0x0E918674b6e34B03FdDD5b7F2F61deA4252b3b82,
            0xCb2e90B72F33B4d9FB8541a410E16aD3e6EE7625,
            0x619d70d46b64239bf5060bc12011F4b47d2aC825,
            0x191EB06b656AF55004a02d9e207b5C379978200A,
            0x360f58916AbB5cc07b5512B5a6dF50Eb603Aa4A4,
            0x05Ae78DD0DFDCB23f1B09186D07f0BD3dFcBa4F2,
            0xEb1dF5995575e7882a767092ab52F4e6b3EFe55b,
            0x4eB166aA490547E12dD3a9EDed8D2b5E8E5De0B5,
            0xb47C91f55896fe899393f9A7ecFD6A4426bb0AbF,
            0xE4eD0Dd880ae6B5761F8C73f38509A4d377021BA,
            0xee183D9E1e2D133648829b37f5a0aB6436628C55
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
            _defaultUri,
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