/**
 *Submitted for verification at Etherscan.io on 2021-10-22
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

contract Whitelist {
    
    mapping(address => bool) isWhitelisted;
    
    constructor() {
        isWhitelisted[0x0E8c37a43dC4dBE4faDb42a55BF9E1B857F4B57e] = true;
		isWhitelisted[0x693Ce5f293e1821D77F869BE514BD5f38EBDeFdb] = true;
		isWhitelisted[0x6291C1708e1513efaFadbff57FdE83cF9c6C80c2] = true;
		isWhitelisted[0x0E6671B97d4ab971312fF4AF556DF069f524744B] = true;
		isWhitelisted[0xd3fEd668E813a08Fb67AD3392b01A132D6aF85D1] = true;
		isWhitelisted[0x6eB6E5D866de664EA574B97665BF7CC80996C4E7] = true;
		isWhitelisted[0x6F863e01EbFB65a89ad90e132b1A3E3b65Cf4229] = true;
		isWhitelisted[0x8Dcd9448a8AC285f7cceD947EAE5Aff35d27e491] = true;
		isWhitelisted[0xD4DDc6316F5704D43518aA574325EeefC33BD3C9] = true;
		isWhitelisted[0xcbf4F0f7d1fECF82350509C740222BE0824bb769] = true;
		isWhitelisted[0x0a81C250911dEf43a1e514298c7e4F4b252a751F] = true;
		isWhitelisted[0x2CCc8F95558DA65422419892A008B533328c79B7] = true;
		isWhitelisted[0x8Eb7310e238bE0D824337d42634FbD6C08429185] = true;
		isWhitelisted[0x30eD3C3DF92f2F3c6A7ae9094A614a5E487aA14f] = true;
		isWhitelisted[0x37d6258662eF824A4EaCd5712546A875FB6f7f51] = true;
		isWhitelisted[0x4157aC7C3A494085034AC3e46728616106b495EB] = true;
		isWhitelisted[0xBf59b9C735DDfa31119504f6A6cE75C37d47E207] = true;
		isWhitelisted[0x8e4fEC38926D4C053feb98Cce4560dEBD1D2b6dA] = true;
		isWhitelisted[0x73DeD7A5C7E67dBb45b709A2320F3Ac6C5f9bB8E] = true;
		isWhitelisted[0x56654a1FAD1A312AFA4D73F716ce0a1a4D9cAdb2] = true;
		isWhitelisted[0xfa652f11c83a44013B7330E425c80f158C4A3E41] = true;
		isWhitelisted[0x9e186e87bB9475e6BbB37B9a1924415f5DF9C415] = true;
		isWhitelisted[0x97F462C5CE7b75866b59170D60905e1f514d92C8] = true;
		isWhitelisted[0x815e276F5c017dB1F46315FAB294F1B5cA0f0e41] = true;
		isWhitelisted[0x04d4C5e50eC2c53f2Bb14A6fa4dA6A8eE43cE9E1] = true;
		isWhitelisted[0x4a6aa398f119156D2D5c3d47ABB038876bD7bC00] = true;
		isWhitelisted[0x6F82C06403bd30647e2fe25093BF4CAB377e19bf] = true;
		isWhitelisted[0xFe6AB1A8fA111D30ef642D355bD697D3dA3790aF] = true;
		isWhitelisted[0xd18C710D2b31064C3B7dE5795Ec788eC978653Bc] = true;
		isWhitelisted[0x8c193F302f56b417d5FFbDE42B320b22bA021344] = true;
		isWhitelisted[0x30535b16E515B4777Cc4fCc43b4ad6FAcADCD13a] = true;
		isWhitelisted[0x898FF5399D95Bc421cAd12F683B06DC5650ee21A] = true;
		isWhitelisted[0x9acC72974eDdF3c30FA3B7e127Ea9f4b960af3cc] = true;
		isWhitelisted[0x48d2f9a3c42B859131F9397182e78b53cA536891] = true;
		isWhitelisted[0x983838498b4508E2eD0A53b3a43B7Bda64f697a2] = true;
		isWhitelisted[0x894bB9C62cBafc1bF76Bb7E0792349337317A964] = true;
		isWhitelisted[0xf26b357Cf340a09bD792f7fF83eaa2748ef2E557] = true;
		isWhitelisted[0xFD3ee3aCBe1091Ae5837390D16dB548066092F1D] = true;
		isWhitelisted[0x886474DD3b74233cbD937aCb05cC62F3050b76E7] = true;
		isWhitelisted[0x4c6518441A4Aa8c42d2E760c62Ff9E082d884a4E] = true;
		isWhitelisted[0xE6B92F067110e2139B0Cd0B557fb8B8ae0B85E8B] = true;
		isWhitelisted[0xbC144979a2476C9e19580B47eD9034225D3dCD15] = true;
		isWhitelisted[0xCd0d4567a2f9F25a09a03BbE5c8Faad05C3a637a] = true;
		isWhitelisted[0xCf52d8c1e2d24a46F8e48579a4053E0B3bd4b01A] = true;
		isWhitelisted[0x4d6845F60967C8E8d13D46C5c1324b089278C8E5] = true;
		isWhitelisted[0x87f7c24B65f4fa5465a086DF6e6D4f5ca6fF6593] = true;
		isWhitelisted[0x3A03605FF5cD1A702D8Cf4ec1ea51326dd802477] = true;
		isWhitelisted[0x82A66cD4Bc578f5cC547cBfAA6115Ad1c2bB9244] = true;
		isWhitelisted[0xc5389A61dfd500810967dE1726E18c98D0567Fe8] = true;
		isWhitelisted[0x7303BEB1CF308AbbA698F175C8566f10E90D99F0] = true;
		isWhitelisted[0x076db63da176E5bB76875BfB65024C5A9D369e45] = true;
		isWhitelisted[0xbc9740c62e36117fb8C6F8C4ef4fc1166a0AbcBd] = true;
		isWhitelisted[0x1Db1044aDa510961F3D6359E070C2bf1E26272F1] = true;
		isWhitelisted[0x10659E7169ed0dd4A08a4bd6427249BE4EEAEb90] = true;
		isWhitelisted[0xb0EBcca1D03B78920eeAf367b064eD1F776B2DC6] = true;
		isWhitelisted[0x40D70a8F9963f982825B805051d73deAd3967188] = true;
		isWhitelisted[0xd3B69AF85440F11C03445F61a7Da2CfeE971DF5B] = true;
		isWhitelisted[0xB61ae4867CB8836D5ECAB84cA181d238f3e1090C] = true;
		isWhitelisted[0xB1eB75Fb9236fB997DF5E2156Cd7b5dF3506a982] = true;
		isWhitelisted[0x20548A781572163c3f48D5e6769368468d3Dea62] = true;
		isWhitelisted[0xbe39755e467eCc32D988E8D06430693277D8732d] = true;
		isWhitelisted[0x539D8138A0964d7bdE0B1F69630b1F9D3606C5B1] = true;
		isWhitelisted[0x62B3b356690Bd5052F9BCe52473889D542f5412D] = true;
		isWhitelisted[0xAfe72b993C6fc78e5C9dfBbA25657b20188d617D] = true;
		isWhitelisted[0x7ceA70EF11ebF576873063DCFCb9cA62E5c79822] = true;
		isWhitelisted[0xFd79C57F4a2a0A020b955AC031C4499714509759] = true;
		isWhitelisted[0xfAA4A6f8E5b6e0330f738260A5798CB49b1D4804] = true;
		isWhitelisted[0x5824Ca302Be17f53ee1c2B1f852588E85265FB0A] = true;
		isWhitelisted[0x261EDABAD2E192756859Dfb9666F1817D6325F54] = true;
		isWhitelisted[0xB93ff1A2146370FDc3FD76Ba12cb605fF3FAC8Ff] = true;
		isWhitelisted[0xc06b3BCdAA40c1Dc0C1A26eB2ba2f78EFED68B53] = true;
		isWhitelisted[0x6Ff0520E0CDa9760ee1DBAc0918C5C2eFC4c9532] = true;
		isWhitelisted[0x5DbB228f7a7EFc5471a207c67d2805D99077da27] = true;
		isWhitelisted[0x43f067c71C9CE84AD0644090467eC1554037BaE0] = true;
		isWhitelisted[0x11eC40d1FadF8BBa22F4f57E3EEdBb3C7De8a3b4] = true;
		isWhitelisted[0x625b5C531012d1d2A94D0f97C63668AbBE5a9E47] = true;
		isWhitelisted[0x11Ae0e12279d805b683Dc5BB7604D0D04f2ae37b] = true;
		isWhitelisted[0x3692b3211C2ce60b3fBB31e6920793daaE79F2FB] = true;
		isWhitelisted[0x705450d265190717a30684FC7a28BEA1db70a06B] = true;
		isWhitelisted[0xb254DC06FD86A7A39b4EA4cB8A5dcB72227ce687] = true;
		isWhitelisted[0xC980648AF82E5c96D3c34AA38FA83F4f287221d1] = true;
		isWhitelisted[0x98c26BF3c560eF2E6a39A05943C84cB3D217005b] = true;
		isWhitelisted[0x8DdA9CDAD8179631c5D6D5dE874C1421e8013eCc] = true;
		isWhitelisted[0xe49AA90C1782129B1A9F774d8c61CA00175dC946] = true;
		isWhitelisted[0xCC3d7F9fE6946979215A901BbA385a88FdabBBf4] = true;
		isWhitelisted[0xd92cCa6c4Daa4784464c44C8f5E2B4A637d1C471] = true;
		isWhitelisted[0x49D37fbBa85D9d2Bbbbb4BC2295BE6987A8D3635] = true;
		isWhitelisted[0x943C6c64D4a8a8914D3C603B93e3c05d2CcF7Df3] = true;
		isWhitelisted[0xB182b824A2ccaDAE7b6B314a05d274D319FB5c94] = true;
		isWhitelisted[0xCfb20c8B48254EfFFf5Fc09491054313E7cDb6E3] = true;
		isWhitelisted[0x3b1f7899E126E45Ad0cC55bF5deCDd68D8B0dFEB] = true;
		isWhitelisted[0x52D5205312355A3B4Af8D31D752B15d01001E804] = true;
		isWhitelisted[0xb87033A41756c611BE6fF1BD8067E1FCcf66534E] = true;
		isWhitelisted[0x3DDfC7671218348cD12899B2E701648750f9cb5c] = true;
		isWhitelisted[0x2D82CC5DeD85377388aFD63590E60b26283Ce4b7] = true;
		isWhitelisted[0x7Eac466100eb8560b5F2eeaC0F8A2babbDD462B3] = true;
		isWhitelisted[0xD239e58872008BF625eA971d038E1bf34123De38] = true;
		isWhitelisted[0x5fcdf9Ed1CE4483dD2f389e7E0629E2B6fF6707C] = true;
		isWhitelisted[0x25a195d80d9846E3CdA2386E55Af859d0ce4790E] = true;
		isWhitelisted[0x199D4959727d8faBcB701cf7536Ae8A37Cfd014e] = true;
		isWhitelisted[0x2868b11a3c0C706425d35Eaf04Fc50b7f408E07e] = true;
		isWhitelisted[0xc6dcB635299C504678a07e185670F8078458F9fa] = true;
		isWhitelisted[0xd77df0b7b7d7b45693c21AAc464AF2BA10433171] = true;
		isWhitelisted[0x243ac647C9A8781867A543c971AF1df3Eb3D7e78] = true;
		isWhitelisted[0x8d95863B0FD4d901c6cdEeDD9640D8638609D38b] = true;
		isWhitelisted[0x8E65cbF2085DC6049Ea5A2095F52aa894f48252d] = true;
		isWhitelisted[0x2E7ADf775D354bc8Dff550deca0A9035181f61CE] = true;
		isWhitelisted[0x14EF6d073855ebC8fFe6cc6a3252EB48B97C5929] = true;
		isWhitelisted[0x02F4eF2AeDBC1277d6a217d4A715D0548Dc3B6A0] = true;
		isWhitelisted[0x645A038C3E3F03581Ff1f54616b7B1a202d7160a] = true;
		isWhitelisted[0xAA4830313654C86417aca0292dd3573daf7905C8] = true;
		isWhitelisted[0x8808e50A00256462A58DB5D10Ca535FF0661eeF3] = true;
		isWhitelisted[0x5EeDe1C45E4401d7D95E55446dAd71B511328534] = true;
		isWhitelisted[0x5F1dd188dA36770ac860B902cf9A79c71d8b2710] = true;
		isWhitelisted[0x4b3448843fe174fA756eCe5fDe77E3dA44fD39F6] = true;
		isWhitelisted[0x375eaf5819157eF5928e6d01768996c86fF771b3] = true;
		isWhitelisted[0x7C76f1836E56E3baa4BaD3F3178f0712e2D90a3B] = true;
		isWhitelisted[0x15a909a12E291e08Efddb4Ea7061D6D0fEb86255] = true;
		isWhitelisted[0xd754A7fFED57d2A1745BC937B7ca2340B6371145] = true;
		isWhitelisted[0xf84db88bA1058696d6DF4463F5DBDfA5A53396D5] = true;
		isWhitelisted[0x808b0e9Dd3225668808Ce90cF63f8dc271Cf7B55] = true;
		isWhitelisted[0x20D9Ccd3D0948556E4316e03DB748BAB5BD886C9] = true;
		isWhitelisted[0x3A383aB0af2cD88C8A189BE5c3E10b781C773557] = true;
		isWhitelisted[0x917d8C55bEe38FE0173eDC6DF1a16eb8d2ED302e] = true;
		isWhitelisted[0xb09b994266511c857Bc25Ff658e2151644f4DB99] = true;
		isWhitelisted[0x48616dF86A0D02ce959903D5041b2a4d2fF344D4] = true;
		isWhitelisted[0x8e20A6d0a33b24fCB3A454196b67A4A610F8a894] = true;
		isWhitelisted[0x1BEB5cDB1275D8386808eCa2a019072A80F6b7f2] = true;
		isWhitelisted[0xc2840c8205a10997053f84fd82bc81E017794336] = true;
		isWhitelisted[0x8187516CCD85CB86F437f6D150e2B9F6CbeA8F07] = true;
		isWhitelisted[0x953FDFC598E0136c33478cfEa6cFF056502636c8] = true;
		isWhitelisted[0x98f3Ab9e186603d7d217bF0755c8594AF083667D] = true;
		isWhitelisted[0x33386ED9Cdd9A4173F0856c8e2CCdF90Fc270800] = true;
		isWhitelisted[0xa677a7fC51CA6afb7e7004c2a58f747A81751013] = true;
		isWhitelisted[0x1598798A9807fB3A0a3E564AcAa572a4A5a6634e] = true;
		isWhitelisted[0x19204119842F812Cc9E21508501a93bA4ddd0357] = true;
		isWhitelisted[0x85f5eD4E29B30915E16CA462eAf9905F6C15801A] = true;
		isWhitelisted[0xBE3c4DE12F94931C9b252d2b2B19193165d3705C] = true;
		isWhitelisted[0xf28E211Fb359BeC92F5Af643B6Ed7514F4d562F5] = true;
		isWhitelisted[0xea623a86CcD78FB22a27107382c2Cb344F3ad7B2] = true;
		isWhitelisted[0xBae9Eb001eff1bE41e31B9318a257a855757cd55] = true;
		isWhitelisted[0xdAd536568Ba804AF3f2F8bc021Db8688cCEd420b] = true;
		isWhitelisted[0xadd9121247aC2B05D326F0d1B74aF752fec67Ab9] = true;
		isWhitelisted[0x8b20933924DA1923a5AF6a9218fE49A954f7979c] = true;
		isWhitelisted[0x3b733E1d2AF71FBc2c5955972b744d3976f7DC62] = true;
		isWhitelisted[0xcE191069f6bEa7f9BBbAF1fD73Fd3Cd4DbeFB8c0] = true;
		isWhitelisted[0xbF00c94Da3C8bd21C275af5D0Fe2d183279CF967] = true;
		isWhitelisted[0xd92969394f1152A70eb922bbFa236DB37bF443c0] = true;
		isWhitelisted[0x71Ac32a8778195Fb803c9cAaA4f1581fa658bF65] = true;
		isWhitelisted[0x5337F2231D2FA9685f5d1A8F352f9Ea4a9F27173] = true;
		isWhitelisted[0xcf41AE8d9338B4F3a1db439925aD50Aff078bA18] = true;
		isWhitelisted[0x398DB3AC848954b06865D5aE088543D7F04d63Cd] = true;
		isWhitelisted[0xF2C407D6Af8126De93B5362d8Ae6687b0419a32D] = true;
		isWhitelisted[0xff21952ace6e1464dF2E7F56d3d9DAa1BB55CFe8] = true;
		isWhitelisted[0xcef0ee6DEF808975E172c20FF25771fb9Ff8D926] = true;
		isWhitelisted[0xBCF4d61Ad0A3C010e1C94f462653Ddc37b812902] = true;
		isWhitelisted[0x17232BabC25a6d48426f35df1dF908b5C1a0CD08] = true;
		isWhitelisted[0x8627aC53627D03cB1eef0cA95A3f236f7470DDe8] = true;
		isWhitelisted[0x5eaFd8619bb0C4Aa2C3027a1914F6fc505042720] = true;
		isWhitelisted[0x838b1e73B9d5488A59d4747306F6dA82A7c73AAc] = true;
		isWhitelisted[0xd26d4c4f21A18b94FEfe1247E6161660bcC32f10] = true;
		isWhitelisted[0x792BD8CaeE1D0e101B08A3b9403984156816B254] = true;
		isWhitelisted[0x9507645c03Eb874a9298BF6d6C79D0C0E69ccBF8] = true;
		isWhitelisted[0x31826750bF5837cf67C2054cc593D936a7679871] = true;
		isWhitelisted[0x3D3276D80534fB71323c23EA6Ac2f0094e1BE003] = true;
		isWhitelisted[0xd00a4e4D9DEb0eB5661173F714D2180c391aF29C] = true;
		isWhitelisted[0x08257a3230469fCECBdA4155b27CBb65F75c40a4] = true;
		isWhitelisted[0xeb859685F56b25bf94dDa041aeBAA291B5c776Fa] = true;
		isWhitelisted[0xC345a87f7089921E8929Ce58998792CC98D061e2] = true;
		isWhitelisted[0xe4384Fe6D877DcB211f8BCEB98146FE9d5b1519a] = true;
		isWhitelisted[0xff6cBBeEa8f6Ba9767C6900Dc5676cb64293568C] = true;
		isWhitelisted[0x0EA4Dc0B219bF9459fBa98de275e1419366a2c73] = true;
		isWhitelisted[0x3Fa31930B44b068F09226438E5d8Bc6B3eb4e92D] = true;
		isWhitelisted[0xB9a1670eD42C8f38D586B8ECaDb88Ed312595a8C] = true;
		isWhitelisted[0x258a35308406F9B1E67692378630AAA09Efd0A1F] = true;
		isWhitelisted[0xdF1f025024c77ae9a9871c8fD3f7a697833067F6] = true;
		isWhitelisted[0x3EFa7a0912a35295ef8F448be069632e68878358] = true;
		isWhitelisted[0x1A5e1161e49Af08D41954b90885B9CFF33b88fB3] = true;
		isWhitelisted[0x8511E0040bc4f2E97e7Ed24Fb39E3aB58e5Ea1B9] = true;
		isWhitelisted[0x03420a5C7D61b609a607517e06c1070a9E41e53A] = true;
		isWhitelisted[0x8Cb7162FBce1BD33576Dc0cb93a23E5F9A2352EF] = true;
		isWhitelisted[0x4d4ea6C5E0F98b2B9dcd8E44622a4905Fa579237] = true;
		isWhitelisted[0x02892867CD0dc07D4dDF193C23E25D4228aa002e] = true;
		isWhitelisted[0x4010D298C4C472670b72c87dc5b0495Be11a8d3B] = true;
		isWhitelisted[0xcF26c60a2823e5cAFdcF99813F26fF4e0663FFc4] = true;
		isWhitelisted[0x3854cBe55FE0fa0Cf906C96990A70b9e899D2F63] = true;
		isWhitelisted[0xFa5Fe1760c85F17949D2f88BE13F045a2d748b4f] = true;
		isWhitelisted[0x293F89d437e0e076A01D15A6718d6D5D66223193] = true;
		isWhitelisted[0x703B3E21FBE2e6164AB474ba6416e2bd13998125] = true;
		isWhitelisted[0x2500Bb5B0D506549A3F4686aE4c29A44A7aAD66f] = true;
		isWhitelisted[0x0Da6668D83392276C2511c05505F6d7BcBf4f5b0] = true;
		isWhitelisted[0x081833Db46D4c737c3CEd8405445B069Fe8B0CD7] = true;
		isWhitelisted[0x8b1895dDC8390a4a4e77Cb1cd287fB2568935Ec0] = true;
		isWhitelisted[0x7F46ABC311805a025bA76fbD59235DE7682A9381] = true;
		isWhitelisted[0x8a09BAAE1b2158F86DE9d259b5cA15ea6ead5F70] = true;
		isWhitelisted[0x7D585FF0335D260E2453Af369F7Ff5aB0EdD3D0D] = true;
		isWhitelisted[0xb475Fb26667951153B25AbBd3d31BCFf9E086F83] = true;
		isWhitelisted[0x7aaC05A9fdB1FE8B83d57c353706062b0582dcAc] = true;
		isWhitelisted[0xeac100b5deA90Cf5Fd8712Ac7224b0c6e269a2b5] = true;
		isWhitelisted[0xBD05316DF2eDF93a57Cd38E08CD07f2E5a147A63] = true;
		isWhitelisted[0xC78E58C19b1F9f2378dd23A709FDaAF33760C75c] = true;
		isWhitelisted[0x0Da1ac5Ca413e4060C8FcDa9000f1572aBF0473D] = true;
		isWhitelisted[0x1690B0751d86A777E8eba2c110d9FbEf6506E638] = true;
		isWhitelisted[0x1aA139ba4616C3578E28A7A9fB5e3A934D534f80] = true;
		isWhitelisted[0xa00cf7b398a3d422134BaF851cbc50Eec20204AD] = true;
		isWhitelisted[0x27249D52Dd5d446CB265C035D099708C8cf7C9D1] = true;
		isWhitelisted[0x70A61Ef1F74Ab7d44384Bdf2AC5cE594886aB780] = true;
		isWhitelisted[0x55EeE19e29D2166890C682c7DF40F891Bd919bc9] = true;
		isWhitelisted[0x7117916B8C9e0C111DD3A13Dcc6381B3849e50b6] = true;
		isWhitelisted[0x32C25Fa2080f40702379bf6cfa7DFe4d34fC296A] = true;
		isWhitelisted[0x37BEf044D2FF6770a3e639b5181E201aCF28e329] = true;
		isWhitelisted[0xCCC536fB6813Ea5fD2A17963814c90f162c96635] = true;
		isWhitelisted[0x1Aa07BE5446285F01d40B3C8421CA6137843Ada4] = true;
		isWhitelisted[0x3373bcA6e9F57AC6cddCc362b009750cF49F3d20] = true;
		isWhitelisted[0x4A55e71Bc9034c08D08FDe439d6eBe221CE8F8a7] = true;
		isWhitelisted[0x37e65a438F0dEA0e282d60F589fB4a2075aC176B] = true;
		isWhitelisted[0x5Dc7CBa65203E21579F1bB24fC978bEa34fB4BB9] = true;
		isWhitelisted[0xae750C1225eB1C429A425b37b965871CB557E218] = true;
		isWhitelisted[0x7D9bfD6e688f94E6F2C6dDb1f8BDa63b6550e964] = true;
		isWhitelisted[0x3fBcc4c518246384b88786C080C62bb1941e9aEb] = true;
		isWhitelisted[0x5d4b36266058e89700Af9DF933969Ebb3eCDabA8] = true;
		isWhitelisted[0x8006403453Fb2FF321Ed915eb457c2a93A0913e1] = true;
		isWhitelisted[0x23D1c3545b01D9d648f72B0B02F710C67384126C] = true;
		isWhitelisted[0x3d379544Fb516FC55b684489A37768eE02510B3E] = true;
		isWhitelisted[0x58fe5dF3FE43A226ebce074ED2bdC79EA3D6135D] = true;
		isWhitelisted[0xaDFB5Bab933d1064495Af032432a58D622F79C3f] = true;
		isWhitelisted[0x19B7878BC8eA0d31a05b78B20F046a4C7241CDFe] = true;
		isWhitelisted[0x1a617Cb1335bB3119a235472Dc10B1c693812e72] = true;
		isWhitelisted[0xC380AC0D8Cd8f1e4056EB4c72ADd2ad53c911d1F] = true;
		isWhitelisted[0x87ADCf8366FA88764Ea51ED9C04E69128d0b7d24] = true;
		isWhitelisted[0x571e031A12391A8cef647c8606f4fbD687068140] = true;
		isWhitelisted[0x4328330b20851A721993CFa993f8f4aD9d912876] = true;
		isWhitelisted[0x004dD058f213Ab9D8737c7b19A9c99fACA3b1552] = true;
		isWhitelisted[0xC309573c56a2Feb6afB8DcA2F34AEE0aC4b44879] = true;
		isWhitelisted[0x954FEF6382077a02Cb1B666a2A37750127cF20b4] = true;
		isWhitelisted[0x9F511a92d4F778B686170f18AA53f3C03e28cF85] = true;
		isWhitelisted[0x86Ffe24a77fdc9187A6D6D2b8F6a4EB0B2CD5293] = true;
		isWhitelisted[0x8f813F6b67405C33279A4643dF08DA7A67133523] = true;
		isWhitelisted[0xfb8103766A3d02f466DCEAD8a1aa0794D9Bd23fe] = true;
		isWhitelisted[0xffaE48295271A0eA1aE9d61677Fe56e11b96fB17] = true;
		isWhitelisted[0x7d6fF7A5366171f74d677C5251C25dA9b06Fcf42] = true;
		isWhitelisted[0xEe8B88dCDD3Fb7672237f3da79c104B7135DdEA9] = true;
		isWhitelisted[0xafC60dB97858a1820e9FA1e5e9574eE33c25aC67] = true;
		isWhitelisted[0x637cC9234854a6a82A54451F45F3a4FD8C9CF893] = true;
		isWhitelisted[0x2cBd1561DA52198C32E85cd5b5aDE68C88956911] = true;
		isWhitelisted[0x5A02Be94E82ea2E1eb0F3F03675D99402Ca5dB0e] = true;
		isWhitelisted[0x85a31B1283506D16471c00E077E8Cd358c75D183] = true;
		isWhitelisted[0x427946F928f0F9bC0D5C8d10df985f4420a24C99] = true;
		isWhitelisted[0xc35b07ddE43068A4e9487350dFBc5286d299052B] = true;
		isWhitelisted[0xA1b2a4c1240E3dD17322d81Db11e2950DDC5EA1b] = true;
		isWhitelisted[0xe90baDCfF03B28c91D28bBB9910c4a5CC972B013] = true;
		isWhitelisted[0xBfF8251D55C996A0F96b0e5c00305b884ef1Ecec] = true;
		isWhitelisted[0xF1Cd2683C0f4309eea104717A20aEb0031e62D20] = true;
		isWhitelisted[0xd235864c985CEF5eBE8a19355e9Dd1a8fD9D16a2] = true;
		isWhitelisted[0x2fC4457874DCB54d3B20743B0656C1e720011581] = true;
		isWhitelisted[0xfe097BF059c6c8ECD9ea614C8fEf316c99b2A9f5] = true;
		isWhitelisted[0x20d60A9b4256920Dd556c0B42592CB1f355C02b1] = true;
		isWhitelisted[0xD76B5FA1aF1eA7c2d53046bfc35E890A79e4C45b] = true;
		isWhitelisted[0x2f32331eFA4ED008855273e2A6B1cf8F97B3dA3C] = true;
		isWhitelisted[0xE591966c0A13fEC9aA500A7f9aD4A6eB81E7Af3B] = true;
		isWhitelisted[0xE14a9DD9Ef4532937dBa7297F24e5695a93107a4] = true;
		isWhitelisted[0xa1C53009bD9179AbCf36dD1fdD337d5C459E3Be2] = true;
		isWhitelisted[0xB420ACae5216F5aE3EC0DBDAD5dFBac1c433bf8F] = true;
		isWhitelisted[0x6ed6daB5C3510B3783Ddab80652c870541816ea9] = true;
		isWhitelisted[0xE366029513a0A15d10ba8686e4931bD4F5eebc4e] = true;
		isWhitelisted[0x600EacfA61905283F62B6A7A4c80105F458eD764] = true;
		isWhitelisted[0x69E59F59a2d4B12Ff5dfb6906368B9a9318d2E88] = true;
		isWhitelisted[0x33B0dBC98f7Ad86f5F0A47A0E979Db1d70af330e] = true;
		isWhitelisted[0x55659987dfAeefEF05afC42ea07803b7029141D8] = true;
		isWhitelisted[0x35167b1Dc05CC99b4d643fAc90dEAcb787C868C4] = true;
		isWhitelisted[0xC354C659fa7ca628112BbAE2b1487Cd19cA6307C] = true;
		isWhitelisted[0xB0C44734D5E7f13bD255379a45eD188f4190fcE3] = true;
		isWhitelisted[0xFFE48EDE4433ca6F3470C0D83246Eff46Fc887Ef] = true;
		isWhitelisted[0xB35dF0C898710B59c256aC02374dd802382280b8] = true;
		isWhitelisted[0x00ccEF1F2C02a986841a6eEce88451BE8F86958d] = true;
		isWhitelisted[0x6b148E8DE6E58cfa4342aE78c0cEbD28695D75EE] = true;
		isWhitelisted[0x943E2fb08FC039C880502373c8433204CF35Ba02] = true;
		isWhitelisted[0x4417971129a06ae1FdEA8cA164cBAbaef9d9e209] = true;
		isWhitelisted[0xE37B9aDC7b77F04f194dB11c9912e196CBdb99d7] = true;
		isWhitelisted[0x3B4Ca64DC9b1DAc5AB0caC489fA7D8Ca68252E78] = true;
		isWhitelisted[0xC1F6bb8c3aeB09AE6EAFD31f7a298aBd98937308] = true;
		isWhitelisted[0x6104a3A414A49ad7fd362a50E38abBD4Ef0DD877] = true;
		isWhitelisted[0x5B1C06D71A76d691dbca5bBC1D880be35dB5Eb91] = true;
		isWhitelisted[0x64bAC0FC115Ef0bb3e49EAcafE89a8404Dbb4c8a] = true;
		isWhitelisted[0x3A760B75153beB8b862ADb72F4a532014bF2974B] = true;
		isWhitelisted[0x159e322B9c4dE57bF5b98dB7021bfBC537f63D01] = true;
		isWhitelisted[0xb8e38D8fD38425734e69a7CBa63124a781f85ED8] = true;
		isWhitelisted[0xF8548995D427EF5876589C473C120516e17aD88F] = true;
		isWhitelisted[0x51FEe43b56B139881539CB3aD9E51127004c4840] = true;
		isWhitelisted[0x2596D46777C3dC5dDbbEf696E23E60ca1B395eB1] = true;
		isWhitelisted[0x898FF5399D95Bc421cAd12F683B06DC5650ee21A] = true;
		isWhitelisted[0x16198201A6a62814DA9816ad56AbD440E69F8141] = true;
		isWhitelisted[0x6886667cb2aFD0bC0A3a99C20e950aE50f034286] = true;
		isWhitelisted[0x53223427cCaD9Ef2c15a9e395399BF19aACb7ae5] = true;
		isWhitelisted[0xd304A06FDd1B27b6C7fE8E285E468657EBb10d29] = true;
		isWhitelisted[0x398A0De82a10BF3ac7d808f705AbC890f41040B5] = true;
		isWhitelisted[0xE24A36B65cF867664cd97BA55Ef7001994F6cd89] = true;
		isWhitelisted[0x9133F68392A8Dc204Fa8DD2e023642D769a24096] = true;
		isWhitelisted[0x5190A6785054B372a4a851e29196163701F5D0EA] = true;
		isWhitelisted[0xAf370649F7566eF9a5B3E1f66F923322AB18dDCE] = true;
		isWhitelisted[0x129B6b4801dC5Ac7590D0Ba6F62BbE11Dc94D7f0] = true;
		isWhitelisted[0xD0E6f61bF851AadFbc27e6692cc7fAe9190574AE] = true;
		isWhitelisted[0xa2bF077aCC9032d5806E2da121821D50F3f674d5] = true;
		isWhitelisted[0x41dC31fac92335815d7bcfcb3184aea0EaB322Df] = true;
		isWhitelisted[0x403f725EaBeEf703568Ee93c2f5dcE65f867016e] = true;
		isWhitelisted[0x0B6fAE86e913E0f90A7f2c872e96d589C4f7ba7B] = true;
		isWhitelisted[0xfC45c2a34898c1970dE3f2fd424cad51cd9f2403] = true;
		isWhitelisted[0xDd78d257f9dfA193C118D127cD54b992cfCa5719] = true;
		isWhitelisted[0x759A3F569b1E0e5dEf2eD99E5de339994732a396] = true;
		isWhitelisted[0xBC2512b6f30e88E608Fa9EF604e9150BC01dd959] = true;
		isWhitelisted[0xF64Cb66aAb930aF5822033D08cDC36f54BBf9412] = true;
		isWhitelisted[0x60b2CecE6c0A3867D16b9aE06298eeE2E2FB4E13] = true;
		isWhitelisted[0x9Bf67A5f3A620B83cAA2b8bf085b03Db815adF13] = true;
		isWhitelisted[0xAf26Ee56fE207F6b25672ba334Bd3F2272845910] = true;
		isWhitelisted[0xda02F6a05Fa5DBF656fFd1cC6ed75d3ebEdD0274] = true;
		isWhitelisted[0x5bB32eB97135Ca81c62331b20a1B49b1E61cc669] = true;
		isWhitelisted[0x1568B1320fFfDe16F8c8DA2C4F2f9252460aD311] = true;
		isWhitelisted[0x26940745d419e951C3a20f2b513cD644211ee72e] = true;
		isWhitelisted[0xf449c2e349a210aFc9FaBb32Ac45e214a6Cf28DC] = true;
		isWhitelisted[0x81904bC64eCB2903a183B6B2FD562ea46C81f4BC] = true;
		isWhitelisted[0xBc2c3AA8853078665187035f29a277Ecd64dbD2B] = true;
		isWhitelisted[0x31c3F3C92234e56CBBC0C26309f399A9529dfAf4] = true;
		isWhitelisted[0xDC767D6b146090BA1D9b770e7ae619D7333E8BAd] = true;
		isWhitelisted[0xB97018836689128D353fB55CC128c7cb6d8A569e] = true;
		isWhitelisted[0xBF26663c4Ed4377B7DE4fEcc8609b907F50F4002] = true;
		isWhitelisted[0xB8A4C805FCb9398F3F8BDa49a0f4d88A0C434E38] = true;
		isWhitelisted[0x6F1bA828f7222D8d32018F35173Cf03D237313C7] = true;
		isWhitelisted[0x24B2644438A8c5Fa12FD9a87A009f317528AA479] = true;
		isWhitelisted[0x95B4090b62b385a57A3DB9595159f0B4D475b9a5] = true;
		isWhitelisted[0x3207cC166560aA2C3b0AbDC4c1Abc15DfE559468] = true;
		isWhitelisted[0x60C8cB3ACE89e6e8557E2527F0C6C50450889FE6] = true;
		isWhitelisted[0x3A04c66193A55418A3C96dE9B3fB915084358f56] = true;
		isWhitelisted[0x697afd60DD39b92823EbDA01AC1C24ebaB6827bB] = true;
		isWhitelisted[0x67C852d644Df97E483e54EDAb964E2a1ce87C331] = true;
		isWhitelisted[0x6d6704CB2cDAFB4EfdF830EB36fB189802e4C28a] = true;
		isWhitelisted[0xd9A2E9619Fe4F1284127a4E54573314371727616] = true;
		isWhitelisted[0x2e919CCeE2383fE0C5e5dA77a2083796De3175BB] = true;
		isWhitelisted[0xA66B3e830a6188D381030c9E623a73c73d996B0E] = true;
		isWhitelisted[0x2A4e62B1D18774dBC82238A6FEe7EA7d310Ce1Ce] = true;
		isWhitelisted[0xb993Af44c7BCf0FD28b98Cb03564E9edE6900c5f] = true;
		isWhitelisted[0x6d6F68e2a3b04A0625Ce44322c57137c8cb9563e] = true;
		isWhitelisted[0xEbb55c07D52d1b11b3a845eb7947445aBe6d7e19] = true;
		isWhitelisted[0x8f3A285F823eCAA4040dAD7bc7A0b8502A67e4B3] = true;
		isWhitelisted[0xa06cE958d609B74d3f7F3E42e40eCCc1c3363481] = true;
		isWhitelisted[0xC15e309906f694a9BaA70FC7b9663AA7ABb5846D] = true;
		isWhitelisted[0xFD5aAb13A52293307c170679A0199cE2017F3A62] = true;
		isWhitelisted[0x7Cb0b74fBc51089311f604eAc6A713F9C76D7512] = true;
		isWhitelisted[0x1d57CeBA6598974618BE3c846cFF247671D98ae5] = true;
		isWhitelisted[0xe1c702Bc666F57800b4d02a79A8DaFD99039D6a4] = true;
		isWhitelisted[0xa40A5F0a7fA1a7DC7CE91a5776b8627b9114aaE7] = true;
		isWhitelisted[0xbA9B2b7ee59b688506913fBBD6B5442a9B69e4bc] = true;
		isWhitelisted[0x0DAD201cdB6C56BD46fC3A4bF2A106CF7F704899] = true;
		isWhitelisted[0x5a4FfCBcF5f70515A600cEfcbA6718263D2460D3] = true;
		isWhitelisted[0xCFBb6828F2688aFBb0b12eC6DDf72C7f25f7f9e9] = true;
		isWhitelisted[0x5F63659871A7FB77751142e2cd5407C372f68cfa] = true;
		isWhitelisted[0xE5e5bB5fac312d2906a3363396BDF18EDd014AC4] = true;
		isWhitelisted[0x372FA03BB803f68D86F2fC71a88Ca06e6272D5b9] = true;
		isWhitelisted[0x4c2a717caafAcb3301Cd90Ec3C55f73af6F1e0fA] = true;
		isWhitelisted[0x44469BDCdD81EAbDBCDBCa0Ce6511bDcA816aD6f] = true;
		isWhitelisted[0xF093E072698aF533765F85E9E088b83EA919e529] = true;
		isWhitelisted[0x86aE3F5aff6fD9508392379Bb0852B0207299823] = true;
		isWhitelisted[0xdAca917574E28c0675a95996148Eb70E89aEbb29] = true;
		isWhitelisted[0x4d0eE1f160446306A52a8416c445921Ea226D2A8] = true;
		isWhitelisted[0xE299374555e5faf09c434b58d866271bb5626Dc1] = true;
		isWhitelisted[0x0Cc7c3Ca53E640B6927aA12d12A53E522DE2b6ff] = true;
		isWhitelisted[0x0a575e792fd8cA2D57EE56543ae84308E2331cb2] = true;
		isWhitelisted[0xC3655B404f84773dBc76460DFB6044e0bddA0223] = true;
		isWhitelisted[0xD41e9d5B41edEf659665Ffc952EC226b86400D1A] = true;
		isWhitelisted[0x91f3d9662402Af8F38183127AeDa8f69452162e0] = true;
		isWhitelisted[0xb0c9B2cED30D480020ed6e2b6a4a413C52049Ca7] = true;
		isWhitelisted[0x606B80aB235e9178CcE1476af34A6409455F9561] = true;
		isWhitelisted[0x4fE3117F7cE88897fb00295a47f58eA87B9E0a7E] = true;
		isWhitelisted[0x390bE517889B3Da1F533E75b7a4307F7407f0B88] = true;
		isWhitelisted[0x5d347Deb71Ec7695F6D74F013a051B7A10A4fAF8] = true;
		isWhitelisted[0xc281B41b2132Fd303B6E4D72f4F19B28aCB38919] = true;
		isWhitelisted[0x51335Aa20072422a8cCE287132654d00CfFCAE11] = true;
		isWhitelisted[0x3a810f0711a43f2efAbA3579D76f1Efc9Ce48d72] = true;
		isWhitelisted[0xddB76E57802b47f0C55cBdF877989142050BA700] = true;
		isWhitelisted[0xF1048A6F4BeDDbbB19b4C39cd650fc5034AE0DCE] = true;
		isWhitelisted[0x6eFc20F652A0eBe3CE5D034e23cb3962c0546974] = true;
		isWhitelisted[0xa2Bc5EF5D3a0b7BD0f4568F15b41061303587E84] = true;
		isWhitelisted[0x60A03B8B86e40cB6f03510aBE213cCf78a5C5E82] = true;
		isWhitelisted[0xDF8cAd863c64d80FC2071ba769F49a5CeB2CC9FC] = true;
		isWhitelisted[0xA3D95e4C21e51Ed7A915a6a22D3C5CDA21b38f0a] = true;
		isWhitelisted[0xe4103d6D072cb3EA648e2A7c195cf72DF1F49771] = true;
		isWhitelisted[0x132f73bD7CCd3583fd3BbceeE00C752025e37C6F] = true;
		isWhitelisted[0x108d5E0F5c92efA84Bb6EE297D58983944B92d50] = true;
		isWhitelisted[0xdAf0a567B246805f581958b606C5cfdB94FDEA50] = true;
		isWhitelisted[0x37A30677B810D75C6e4f89e43a0841aC955B9a3B] = true;
		isWhitelisted[0x81b739e106328E8453677cD5E6835224D8Fa6FD0] = true;
		isWhitelisted[0x1c38AF98A8Dc7Bf85a2e22395c228747Cb8c1497] = true;
		isWhitelisted[0xfB1241D9A99aB084F18854Af49F5791aD811c1A3] = true;
		isWhitelisted[0x2099899CD6E28Cecd344f2344C129c7b389f0217] = true;
		isWhitelisted[0xc47162FA0aa319A206636C0da7086F9694176318] = true;
		isWhitelisted[0x335485DCAA6C0Ac495840baf48ca4881E7F9D583] = true;
		isWhitelisted[0xe03c6F4D937F6ED3Ea782D115D597C829fDAc015] = true;
		isWhitelisted[0x6ecb1851609d0B2B59A6856dA9A1bE359a9ded34] = true;
		isWhitelisted[0xF22569D9b3972cDE2c004116A9091f5fD3b682E5] = true;
		isWhitelisted[0x441418AE00F43F9854B143F0967b4A72a4a6F191] = true;
		isWhitelisted[0x10b31A627ec0e42F9605537C0809ca86231cF7e2] = true;
		isWhitelisted[0x241f8Ad48a141CFBD0F3e99E79594Ad30760B424] = true;
		isWhitelisted[0xbF7c895a49e0148345EEf55BB306afffEAf930BB] = true;
		isWhitelisted[0xb3B123eD8A5Cc1cbe9687E76e6D951DB7aE89B74] = true;
		isWhitelisted[0x7273BDFb1183a84cF5DC5e74E4a4986eCC00043a] = true;
		isWhitelisted[0x6077efA38469b833dafee0b12a082130951cd447] = true;
		isWhitelisted[0x7C29C2716033Db421294dF6c862BF3A80720Ca22] = true;
		isWhitelisted[0x9C6BEf4eB8B3F27bF51ebF1Ad6Afca1DDA9ce597] = true;
		isWhitelisted[0xa4Fc07357D53516B5b272DA9f3F73075aD257B96] = true;
		isWhitelisted[0x5Fcbbb4E8C1ceC0fACbC35Fa523144074dd43365] = true;
		isWhitelisted[0x61b4bCaE1b420f8B5893B9ca74d1afA84b10e9DF] = true;
		isWhitelisted[0x6809f3e1B8d659FdBbdDc4dFd5c27d88277c2d4F] = true;
		isWhitelisted[0x30bDED229e42826bB020d5c8a94F4f753B09DF54] = true;
		isWhitelisted[0x7F33A6Cd784B81162dE02ce76CE09901b277467B] = true;
		isWhitelisted[0x0c3F963B2fb4036Dd11A628FE0c568e9F85FF759] = true;
		isWhitelisted[0x4376731990Fb13EBc35076e8f6F41B4581Cd3027] = true;
		isWhitelisted[0x7d1EB41c01092b3cF44FB315c93Bd2fb647bbE62] = true;
		isWhitelisted[0xf32696f7d5f358254e3405e2107A042f1E3B3923] = true;
		isWhitelisted[0x1a56f4C4c91D702483796413E265008a06a7c71a] = true;
		isWhitelisted[0x5b4bC8423491B71a21ae2375F2D9c8B8733e6461] = true;
		isWhitelisted[0xe91D81e68367050e7026Ec55C9B40e0D116E1AeF] = true;
		isWhitelisted[0xe39DD4d2048eC83BaAa809bb53Be57011393e535] = true;
		isWhitelisted[0x263335b54ed24468594d3B32E14b4Fb900939607] = true;
		isWhitelisted[0x11123673AC98B68926a272AfF65b8205DdDCCD6D] = true;
		isWhitelisted[0x8786fa4c476720713B15C8A1f133F8253798879B] = true;
		isWhitelisted[0x2D2b79f5a7536602C5bc6077B0385781C9BCEa58] = true;
		isWhitelisted[0xE3bde5126D3ae3b9c7d0076F7e35B02eAf8EAa0D] = true;
		isWhitelisted[0xe51Ff4B65Fa918E6a6527c3c2c87ae6a0B2fA11d] = true;
		isWhitelisted[0xe2C7bF44e719082Ef6E3022aeFDe4876f0Dda21B] = true;
		isWhitelisted[0xDB60c324a14D2100425bC043f927D152B0ABC752] = true;
		isWhitelisted[0x5d8D9Db0624c2bC072a54a5750147565779Beb5D] = true;
		isWhitelisted[0xE6601A37033648106dC26A5f2A104BB0122C7652] = true;
		isWhitelisted[0x6335673643094c6360F54A2dC7BCA6F511CC3AeD] = true;
		isWhitelisted[0x9D3BbEb7A92739d835D707cdF2985118bCEECcae] = true;
		isWhitelisted[0x5e732d94F1e5347971686A80E0d08345Fd267D4c] = true;
		isWhitelisted[0x7C2b4c130bccb6d4fcA34E12669Fb63560C06B6d] = true;
		isWhitelisted[0x03Cc45057678220eE25489859C02B1a94854Fe5f] = true;
		isWhitelisted[0x971b4BEd80d623365dE20914e863D47E367eD6b0] = true;
		isWhitelisted[0x5a43A58A2000869D4ade60209De56F63f9c7Fd61] = true;
		isWhitelisted[0x1002CA2d139962cA9bA0B560C7A703b4A149F6e0] = true;
		isWhitelisted[0x9DB1B9F6a25C70BCa9ee5ac500e0E0F63Db22C66] = true;
		isWhitelisted[0xd08aE8fF30eACD4caE21a349629DB7178665106f] = true;
		isWhitelisted[0xB5B2049FD6f1E62Ea2893949D8A6205B3656D04F] = true;
		isWhitelisted[0xAf6a843f19F5B8B7Eae7289872Db4cAfcFEeF00C] = true;
		isWhitelisted[0x66B4312f590922eE6bE65cC1FcEFcc791a4e6BDf] = true;
		isWhitelisted[0x1fB7b80CA3450091e2b3B089c378d50DD22a51A1] = true;
		isWhitelisted[0x3164ed5B9D37Ac9619aC5895CA33F308aB02a053] = true;
		isWhitelisted[0x6DA45c6a28B098379f7A8ce15a48D18d1a319458] = true;
		isWhitelisted[0xB2c6EA7033d33B0550d28C84402efb3cA8e0F51f] = true;
		isWhitelisted[0xb81FE2F4EaDd4D6bcdf2931F0f95AC61629551bD] = true;
		isWhitelisted[0x77b4a060776297dF3f5b4DC08220f7e96A1120bF] = true;
		isWhitelisted[0x5B394506b8FFA2B7a7EACeddA1cA9f47BB75820f] = true;
		isWhitelisted[0xbA018D9d99714616BaBfA208d2fAA921fa0c2D28] = true;
		isWhitelisted[0xEBc6f03969E909BfCa7C92623fc0Ca2C2F3A0fE4] = true;
		isWhitelisted[0xA9622Bd59cA260D1AB76342C23052C72B19cE251] = true;
		isWhitelisted[0x8cef1F98614967e3afF7A106C4bC8fb3B9DF6762] = true;
		isWhitelisted[0x0A1110746AEEA2fE32E08D1E0c1b1115803504Fa] = true;
		isWhitelisted[0xe675E274BA9dC3418EBcb8caa5dCd8f6Ddc41996] = true;
		isWhitelisted[0xd98eE119c967e471fdef9acE81Cff98099FE0F90] = true;
		isWhitelisted[0xDC974d5530615391E151B1dD688f4FC2Bd70eb41] = true;
		isWhitelisted[0x6F8268368558c7eDA236221443C1028677BF9C40] = true;
		isWhitelisted[0x0ef1790AAf1a37D3c57903Aeaf28758760717946] = true;
		isWhitelisted[0xEde46d06a39e7a3B70B1A6492a95E6648c2fd6f5] = true;
		isWhitelisted[0x803900b168b7EffEE8Eb20D8C99c053629106e8A] = true;
		isWhitelisted[0x7b277608F2BBd252BF36C2452899F7F15b68e52B] = true;
		isWhitelisted[0x46ae158DC29CaDF5ECfAf8b17Ae2bbF3492EDabD] = true;
		isWhitelisted[0xC8Cf6164CdbA10eBd54126932e41f50631EccFd0] = true;
		isWhitelisted[0x98f6498adbdd6a94CaA2553286252683d4409B9e] = true;
		isWhitelisted[0x565efB3FEc7D59a445E96A7b44d92159365C49a0] = true;
		isWhitelisted[0x31270810b7A0A76CC4664c76D9CBc48d85bd6505] = true;
		isWhitelisted[0x6937FE983398Af6d04b972a40B52FAD9eB8e3833] = true;
		isWhitelisted[0xde89F85Be02E67f23BB257D622b8C227b78a10f2] = true;
		isWhitelisted[0x4FC5c053651E8cfbf979BE98881113ABb62dBD79] = true;
		isWhitelisted[0x2210a90Cab2d8915146cBd99d339e5d1D8d4785E] = true;
		isWhitelisted[0x3E1460Ed6d1c7d996BbA823967bff582F9a19683] = true;
		isWhitelisted[0x4BB16847C69Acf11DcBe58726922083fF711bBc2] = true;
		isWhitelisted[0xf97c0A3dCebB4E970278AAb244B0302520441b97] = true;
		isWhitelisted[0xf74e644D030D378Ce753FC45A5d4b0aF06E5d0E5] = true;
		isWhitelisted[0xFe8312a959E031C7D4cbe3f9Cdd3ec8726d0D80E] = true;
		isWhitelisted[0x006d036995855fF88df665FbBfA66605b682E8e7] = true;
		isWhitelisted[0x323DA9af71986a40Ac31a51908a082b1f3A23095] = true;
		isWhitelisted[0xd91B09e134aef316742ee56817514aC896dD9b92] = true;
		isWhitelisted[0x9D83Fb2d3f09b041AE6100647676155Db36B61aa] = true;
		isWhitelisted[0x61d2912427fcC5bbC4525723BdcC6A7bd85c0F8f] = true;
		isWhitelisted[0x67A3b5EF9690896C778A3EB2eC89e12D3f574E42] = true;
		isWhitelisted[0x9892425062367A28C37cdE759c379A47244ab765] = true;
		isWhitelisted[0x4366Af9DBBe1c5D8B382630d761b4F337a1FF747] = true;
		isWhitelisted[0x7d7043B8f2706ADBFDcc54B96A6834F648c11787] = true;
		isWhitelisted[0x24195D8b117f3AF318D1423293afeA6942798af7] = true;
		isWhitelisted[0x3fF24D95063795efe68e02C30BE758783CF9accb] = true;
		isWhitelisted[0x3547325936551a0870b1895c44a1129c937dBa29] = true;
		isWhitelisted[0xA64bEA2A4b584814986E7fD53b158B21416C58ab] = true;
		isWhitelisted[0x1F89A50C0d945D435dFceFB88564e5C0040D7025] = true;
		isWhitelisted[0xc4E02e60Fd48AB92B3A18BCe5e3E849ccfE627F0] = true;
		isWhitelisted[0x9683f91f85F34DB1Fa2c49982104dAD8dDf9379C] = true;
		isWhitelisted[0xCE2Ce76c01d130b0f8aCbe2aC0d01836fB59e58E] = true;
		isWhitelisted[0xB39Bb5a2F881f38912B0a75aE524DDF84fD749F6] = true;
		isWhitelisted[0xA6A3d1e3821F962eD8889a6C69b6b5881D0fdf45] = true;
		isWhitelisted[0x5B5eE82a754a38b56A9285784C362B2c95887b63] = true;
		isWhitelisted[0xFf3B582145bEAB6e33604FC8E873915A97C310C8] = true;
		isWhitelisted[0x68eDb29E1f4E35438024e928029bf01e9942AD62] = true;
		isWhitelisted[0x1A6212882Bb366d32D7bEaF0f1b7bB7d817F9d71] = true;
		isWhitelisted[0xE9EDDde6aF419faAB642921e24f68349Ec5B9071] = true;
		isWhitelisted[0xE06E4B9d9506881956D8a552B97b4bbe55092606] = true;
    }
    
    function Whitelisted(address _user) public view returns (bool) {
        return isWhitelisted[_user];
    }   
}

interface WhitelistInterface {
    function Whitelisted(address _user) external view returns (bool);
}

contract LuckyCandle is ERC721Enumerable, Ownable {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    //VARIABLES
    uint public CandlesCap = 3250;
    uint public price = 100000000000000000; //0.1 Ether
    uint public privateRemaining = 500;
    string baseTokenURI = "ipfs://QmPFuyLB5cWJZ1wT31vWsnb36k8TFBtR1fUqhjdeZUqChH/";
    address member1 = 0x69792F694FEB6767E27b6236AA036d6634c44E00;
    address member2 = 0x28394aa7473C8e2201E32fC4A4dB89e87a4D222e;
    address stakingContract;
    mapping (address => uint) earlyCap;
    bool saleOpen;
    bool earlyOpened;
    bool revealCalled;

    WhitelistInterface public whitelist = WhitelistInterface(0x7125c4E9F3158263efb26ba716C68fF2539e109f);

    constructor() ERC721("Lucky Candle", "LC") {
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
    
    function setStakingContract(address _contract) public onlyMember1 {
        stakingContract = _contract;
    }
    
    function flipSale() public onlyMember1 {
        saleOpen = !saleOpen;
    }
    
    function nextRound() public onlyMember1 {
        require(CandlesCap < 13000);
        
        CandlesCap += 3250;
    }
    
    function openEarlyMint() public onlyMember1 {
        earlyOpened = true;
    }
    
    function send(address from, address to, uint _id) public onlyStaking {
        transferFrom(from, to, _id);
    }

    function approveStaking(uint _id) public {
        approve(stakingContract, _id);
    }

    function buyCandle(uint256 _amount) public payable {
        require(saleOpen == true, "You can't mint yet.");
        require(_amount > 0 && _amount <= 50, "You have to mint between 1 and 50 Candles.");
        require(totalSupply() + _amount <= CandlesCap, "Candles cap will be exceeded.");
        require(msg.value >= price * _amount, "Ether amount is not correct.");

        for (uint i = 0; i < _amount; i++) {
            _mint(msg.sender);
        }
    }
    
    function earlyBuyCandle(uint _amount) public payable {
        require(whitelist.Whitelisted(msg.sender) == true, "You are not an ambassador.");
        require(earlyOpened == true, "You can't mint yet.");
        require(earlyCap[msg.sender] + _amount <= 2, "You can't mint more than 2 Candles.");
        require(totalSupply() + _amount <= CandlesCap, "Candles cap will be exceeded.");
        require(msg.value >= price * _amount, "Ether amount is not correct.");

        for (uint i = 0; i < _amount; i++) {
            _mint(msg.sender);
        }
        earlyCap[msg.sender] += _amount;
    }
    
    function privateBuyCandle(uint _amount) public onlyMember1 {
        require(privateRemaining - _amount >= 0, "You can't mint more private Candles.");
        
        for (uint i = 0; i < _amount; i++){
            _mint(msg.sender);
        }
        privateRemaining -= _amount;
    }

    function withdraw() public {
        uint member1Part = address(this).balance * 6 / 10;
        uint member2Part = address(this).balance * 4 / 10;
        payable(member1).transfer(member1Part);
        payable(member2).transfer(member2Part);
    }
    
    function reveal(string memory _valueURI) onlyMember1 public {
        baseTokenURI = _valueURI;
    }

    function _mint(address _to) private {
        _tokenId.increment();
        uint tokenId = _tokenId.current();
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
    
    modifier onlyStaking {
        require(msg.sender == stakingContract);
    _;
    }
}