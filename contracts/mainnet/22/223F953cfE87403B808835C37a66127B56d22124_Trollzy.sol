/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Counters {
    struct Counter {
        uint256 _value;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);
    
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC165 is IERC165 {
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

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

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

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

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

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

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
        return _verifyCallResult(success, returndata, errorMessage);
    }

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

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

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

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

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

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

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

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

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

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

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

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

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

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

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

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

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

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

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

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }
    
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

contract WhitelistPremint {
    
    mapping(address => bool) isWhitelistedPremint;
    
    constructor() {
        isWhitelistedPremint[0x68bCaECbDe98A2B0086C7B8196182b74169BC940] = true;
        isWhitelistedPremint[0xa5b51559ed72a558368742E50394e089c53716aE] = true;
        isWhitelistedPremint[0xa9793B01BA723A37463E2e35ac7Ed98773820650] = true;
        isWhitelistedPremint[0x5E2FBCbbD05841159dCe188C315f0fAda689C123] = true;
        isWhitelistedPremint[0xd3022599033430bF3fDFb6D9CE41D3CdA7E20245] = true;
        isWhitelistedPremint[0xEf9Fdc930d645299D01440D82B6c417CBd8F7162] = true;
        isWhitelistedPremint[0x3bb9B35DDA5286b58d0Cf17d39F5a8c7122E81F0] = true;
        isWhitelistedPremint[0x976Cce61E57d9bfCfaaa53Ce25E4f9B839664043] = true;
        isWhitelistedPremint[0x539F3B2B465BDa0B4113a8C27c196ABF69e72EC0] = true;
        isWhitelistedPremint[0x90339c3d449b908eb51Ba9A5FC42Ef2Dc170C0a1] = true;
        isWhitelistedPremint[0x4253d654b574d29E118faE5A513C0C3793b6bAD5] = true;
        isWhitelistedPremint[0x6F82C06403bd30647e2fe25093BF4CAB377e19bf] = true;
        isWhitelistedPremint[0x7B07f10723e213E8E73f9E86DdaE0A03E7E126d6] = true;
        isWhitelistedPremint[0xfe0D666e2B1A69d57475C4D516AF1fD47FD2173c] = true;
        isWhitelistedPremint[0x1ab7079292872fC69052dc4Ef0f9c3417547C43b] = true;
        isWhitelistedPremint[0x1fe14e53d8C857DFcBFE01243dd922ACfB7cF46C] = true;
        isWhitelistedPremint[0x9bCBf958364AAd003552DE214Ab562B8aacbeE68] = true;
        isWhitelistedPremint[0x135e0109E96cb885DB973516CE37554d5764Cab9] = true;
        isWhitelistedPremint[0xC844A4a63bb232B8c1C761663bD5e98f4068b43F] = true;
        isWhitelistedPremint[0xc94894B2f11F68CF41e493673C5eE6cDC52e28D4] = true;
        isWhitelistedPremint[0xD24c3b537571826C11f48D8A27575eCb5e744604] = true;
        isWhitelistedPremint[0x590d531d00A3F83ee254fE8D0b8267b0189e9118] = true;
        isWhitelistedPremint[0xeA0e95671074c0B8fB9a699C2562932651021C32] = true;
        isWhitelistedPremint[0x16F49EA10C8F47Efb7035e1f2FCC1a7CB6D50a64] = true;
        isWhitelistedPremint[0xe715A88AC6166f9899B9ffE8C687d00CAC884CC0] = true;
        isWhitelistedPremint[0x76114A36054e02745F5aBeC5702606e7d6e5A584] = true;
        isWhitelistedPremint[0x6f2d9b59F562d3148845676646eA053cDA537632] = true;
        isWhitelistedPremint[0xe4c07654Ff5246AE3d3Fe94d630cD017F4CdfC3B] = true;
        isWhitelistedPremint[0x0755a358A82834569C81Ca4751649f2B763eEe8F] = true;
        isWhitelistedPremint[0xE13Bd3DE23D437B1EDde24b082b9AfB731f2f277] = true;
        isWhitelistedPremint[0x425c2E78D4d72A56DC3D8D134ef4b10a98EaAAd9] = true;
        isWhitelistedPremint[0x002A9a4A1c2a5bfB889833a1Af14eEC452bE86Da] = true;
        isWhitelistedPremint[0x30e867D2F3D1D5b645B21E0C4Cb451d492424A40] = true;
        isWhitelistedPremint[0x7cBF5D9d5FBB582045660C4BC81FE0339dcd12F8] = true;
        isWhitelistedPremint[0x111d2a98D67dE15fBA25661ebC8276B0Fd87DCF8] = true;
        isWhitelistedPremint[0x64EC28aba72F4C1a9dedc4EDA6c9CC72c0Ba2b1e] = true;
        isWhitelistedPremint[0x3E4a6212fF392A739010E203a7b82448A3f177cA] = true;
        isWhitelistedPremint[0xdAd536568Ba804AF3f2F8bc021Db8688cCEd420b] = true;
        isWhitelistedPremint[0xc0A4D627b3466c39878259d86debC362c3f96e7b] = true;
        isWhitelistedPremint[0x7dE874cD783C8387c63Aa86C7Bfd23254FF3832c] = true;
        isWhitelistedPremint[0x1002CA2d139962cA9bA0B560C7A703b4A149F6e0] = true;
        isWhitelistedPremint[0x80e151f1074C0D1cdcA8546BEe30934a4e6d1Af8] = true;
        isWhitelistedPremint[0x5B394506b8FFA2B7a7EACeddA1cA9f47BB75820f] = true;
    }
    
    function WhitelistedPremint(address _user) public view returns (bool) {
        return isWhitelistedPremint[_user];
    }   
}

contract WhitelistEarly {
    
    mapping(address => bool) isWhitelistedEarly;
    
    constructor() {
        isWhitelistedEarly[0xAA4830313654C86417aca0292dd3573daf7905C8] = true;
        isWhitelistedEarly[0xFb5c4E3ACc53038B2d610F30c017479E9665C442] = true;
        isWhitelistedEarly[0x08257a3230469fCECBdA4155b27CBb65F75c40a4] = true;
        isWhitelistedEarly[0x20d60A9b4256920Dd556c0B42592CB1f355C02b1] = true;
        isWhitelistedEarly[0x5D9a1979c554F9f199d8390EBA88E25234882d3f] = true;
        isWhitelistedEarly[0x5f96816E479631903068520A407b5F170E989D2C] = true;
        isWhitelistedEarly[0x9D83Fb2d3f09b041AE6100647676155Db36B61aa] = true;
        isWhitelistedEarly[0x070339e8016ffC869dfAf647fbd78513a7d735b1] = true;
        isWhitelistedEarly[0x20548A781572163c3f48D5e6769368468d3Dea62] = true;
        isWhitelistedEarly[0x22aAce211cdd0280021D48717200c0119A8C3764] = true;
        isWhitelistedEarly[0xd1C72714182A7444DC543B7022ad4BeaB6A5dA45] = true;
        isWhitelistedEarly[0x353339c5EBc17B740BE010A6F7C5627b46B005e5] = true;
        isWhitelistedEarly[0xBA93f4686CBA0aA9652080EcC17d581425Ed7F13] = true;
        isWhitelistedEarly[0x168970485A76690DEF9CB863C11B49B608f49203] = true;
        isWhitelistedEarly[0x74C609f880EB4655fa3aBB448e221dE38325fa84] = true;
        isWhitelistedEarly[0x1002CA2d139962cA9bA0B560C7A703b4A149F6e0] = true;
        isWhitelistedEarly[0x353339c5EBc17B740BE010A6F7C5627b46B005e5] = true;
        isWhitelistedEarly[0x111d2a98D67dE15fBA25661ebC8276B0Fd87DCF8] = true;
        isWhitelistedEarly[0x1eb54C74F5f68502A5F270cb5609798caD6AC6F4] = true;
        isWhitelistedEarly[0x3b464c069A714F4d9a12B349b6120AF74c817bAA] = true;
    }
    
    function WhitelistedEarly(address _user) public view returns (bool) {
        return isWhitelistedEarly[_user];
    }   
}

interface WhitelistInterfacePremint {
    function isWhitelistedPremint(address _user) external view returns (bool);
}

interface WhitelistInterfaceEarly {
    function isWhitelistedEarly(address _user) external view returns (bool);
}

contract Trollzy is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    //VARIABLES
    uint public TrollzyCap = 1000;
    uint public price = 70000000000000000; //0.07 Ether
    uint public maxMint = 20;
    uint public maxMintEarly = 20;
    uint public blockStart = 13405840;
    uint public premintAdvantage = 43;
    uint public earlyAdvantage = 6170;
    uint public teamMint = 10;
    string baseTokenURI;
    address member1 = 0x5833A1675BF894abeCF365Fcd8C8741EC7Ad3630; //61%
    address member2 = 0x49282E5E05fE59A724641eE867641b5883C02E58; //13%
    address member3 = 0xAd3948B4Aa2917c36fc0125C266b323f81805D36; //13%
    address member4 = 0x1002CA2d139962cA9bA0B560C7A703b4A149F6e0; //13%
    bool privateCalled;
    bool revealCalled;
    mapping (address => uint) earlyMembers;
    
    WhitelistInterfacePremint public whitelistPremint = WhitelistInterfacePremint(0x2808f8D0f349785543f2AcFbE4C56C682E60e056);
    WhitelistInterfaceEarly public whitelistEarly = WhitelistInterfaceEarly(0xa726Dc23052c81821BCe1ea1b7a0A5A748015D13);

    constructor() ERC721("Trollzy", "TRZY") {
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function buyTrollzy(uint256 _amount) public payable {
        require(_amount <= maxMint, "You have to mint between 1 and 20 Trollzy.");
        require(block.number >= blockStart, "Sales did not start.");
        require(totalSupply() + _amount <= TrollzyCap, "Trollzy cap will be exceeded.");
        require(msg.value >= price * _amount, "Ether amount is not correct.");

        for (uint256 i = 0; i < _amount; i++) {
            _mint(msg.sender);
        }
    }
    
    function buyTrollzyPremint(uint256 _amount) public payable {
        require(whitelistPremint.isWhitelistedPremint(msg.sender) == true, "You are not whitelisted.");
        
        require(earlyMembers[msg.sender] + _amount <= maxMintEarly, "You have to mint between 1 and 20 Trollzy.");
        require(block.number >= blockStart - premintAdvantage, "Sales did not start.");
        require(totalSupply() + _amount <= TrollzyCap, "Trollzy cap will be exceeded.");
        require(msg.value >= price * _amount, "Ether amount is not correct.");

        for (uint256 i = 0; i < _amount; i++) {
            _mint(msg.sender);
        }
    }
    
    function buyTrollzyEarly(uint256 _amount) public payable {
        require(whitelistEarly.isWhitelistedEarly(msg.sender) == true, "You are not whitelisted.");
        
        require(earlyMembers[msg.sender] + _amount <= maxMintEarly, "You have to mint between 1 and 20 Trollzy.");
        require(block.number >= blockStart - earlyAdvantage, "Sales did not start.");
        require(totalSupply() + _amount <= TrollzyCap, "Trollzy cap will be exceeded.");
        require(msg.value >= price * _amount, "Ether amount is not correct.");

        for (uint256 i = 0; i < _amount; i++) {
            _mint(msg.sender);
        }
    }
    
    function mintTrollzyPrivate() public onlyMember1 {
        require(privateCalled == false, "You already called this function.");
        require(totalSupply() + teamMint <= TrollzyCap, "Trollzy cap will be exceeded.");
        
        for (uint256 i = 0; i < teamMint; i++) {
            _mint(msg.sender);
        }
        privateCalled = true;
    }
    
    function setUnrevealURI(string memory _valueURI) onlyMember1 public {
        require(revealCalled == false);
        
        baseTokenURI = _valueURI;
    }
    
    function reveal(string memory _valueURI) onlyMember1 public {
        require(revealCalled == false);
        
        baseTokenURI = _valueURI;
        revealCalled == true;
    }
    
    function withdraw() payable public {
        uint256 member1Share = address(this).balance * 61 / 100;
        uint256 member2Share = address(this).balance * 13 / 100;
        uint256 member3Share = address(this).balance * 13 / 100;
        uint256 member4Share = address(this).balance * 13 / 100;
        payable(member1).transfer(member1Share);
        payable(member2).transfer(member2Share);
        payable(member3).transfer(member3Share);
        payable(member4).transfer(member4Share);
    }

    function _mint(address _to) private {
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();
        _safeMint(_to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    //MODIFIER
    modifier onlyMember1 {
        require(msg.sender == member1);
    _;
    }
    
    modifier onlyMember2 {
        require(msg.sender == member2);
    _;
    }
}