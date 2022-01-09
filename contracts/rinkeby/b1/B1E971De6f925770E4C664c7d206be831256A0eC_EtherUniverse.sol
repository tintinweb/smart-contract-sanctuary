// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Strings} from "./Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 uTokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed uTokenId);
    event Approval(address indexed owner, address indexed approveder, uint256 indexed uTokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool bApproved);
    event NewStellar(uint256 indexed uTokenId, uint256 indexed uValue, string strAppear);
    event RemoveStellar(uint256 indexed uTokenId);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 uTokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 uTokenId) external;
    function safeTransferFrom(address from, address to, uint256 uTokenId, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 uTokenId) external;

    function approve(address to, uint256 uTokenId) external;
    function getApproved(uint256 uTokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _uTokenId) external view returns (string memory);
}

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract EtherUniverse is ERC721, ERC721Metadata, Ownable {

    using Strings for uint16;
    using Strings for uint256;

    address private m_addrOwner = msg.sender;

    string private m_strName;

    string private m_strSymbol;
    
    bool public m_bMintingFinalized = false;

    uint256 public m_countMint;

    uint256 public m_countToken;

    // Mapping from owner address to token ID.
    mapping (address => uint256) private m_mapTokens;

    // Mapping owner address to token count.
    mapping (address => uint256) private m_mapBalances;

    // Mapping from token ID to owner address.
    mapping (uint256 => address) private m_mapOwners;

    // Mapping token ID to value.
    mapping (uint256 => uint256) private m_mapValues;
    mapping (uint256 => uint256) private m_mapAppearance;

    // Mapping from token ID to approved address.
    mapping (uint256 => address) private m_mapTokenApprovals;

    // Mapping from owner to operator approvals.
    mapping (address => mapping (address => bool)) private m_mapOperatorApprovals;

    uint32 immutable u32Size = 16;
    uint8[16] arrTrackBitCount = [4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]; // [5,5,5,5,5,2,2,3,3,3,2,2,2,2,2,2];
    uint256[16] arrTrackBitShift;
    uint256[16] arrTrackBitFlag;
    string public m_baseURI = "https://billserver.me-tech.com.cn/Stellar/getSvg.php?token=";

    address proxyRegistryAddress;

    // modifier onlyOwner() {
    //     require(_msgSender() == m_addrOwner, "msg.sender is not Owner");
    //     _;
    // }
    
    constructor(address _proxyRegistryAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        m_strName = "eUniverse.";
        m_strSymbol = "eu";
        uint32 u32BitShift = 0;
        for(uint32 i=0; i<u32Size; ++i) {
            arrTrackBitShift[i] = 2 ** u32BitShift;
            arrTrackBitFlag[i] = (2 ** arrTrackBitCount[i] - 1) *  arrTrackBitShift[i];
            u32BitShift += arrTrackBitCount[i];
        }
    }

    function name() external view virtual override returns (string memory) {
        return m_strName;
    }

    function symbol() external view virtual override returns (string memory) {
        return m_strSymbol;
    }

    function totalSupply() public view returns (uint256) {
        return m_countToken;
    }

    // function _msgSender() internal view returns (address) {
    //     return msg.sender;
    // }

    function getMsgSender() external view returns (address) {
        return msg.sender;
    }

    function getAllToken() external view returns (uint256[] memory) {
        uint256[] memory list = new uint[](m_countToken);
        uint uIndex = 0;
        for(uint256 i=1; i <= m_countMint; ++i) {
            if(m_mapValues[i] > 0) {
                list[uIndex] = i;
                ++uIndex;
            }
        }
        return list;
    }

    function tokenURI(uint256 uTokenId) external virtual view override returns (string memory) {
        require(_exists(uTokenId), "ERC721: operator query for nonexistent token");
        
        bytes memory byteString;
        byteString = abi.encodePacked(byteString, m_baseURI, uTokenId.toString());
        byteString = abi.encodePacked(byteString, "&mass=", m_mapValues[uTokenId].toString());
        byteString = abi.encodePacked(byteString, "&appear=", m_mapAppearance[uTokenId].toHexString());
        return string(byteString);
    }

    function contractURI() external view returns (string memory) {
        return "https://billserver.me-tech.com.cn/Stellar/openseaInfo.php";
    }

    function setBaseURI(string memory strBaseURI) external {
        m_baseURI = strBaseURI;
    }

    function getJson(uint256 uTokenId) public virtual view returns (string memory) {
        require(_exists(uTokenId), "ERC721: operator query for nonexistent token");
        uint256 uAppear = m_mapAppearance[uTokenId];
        uint256 uValue = m_mapValues[uTokenId];
        bytes memory byteString;
        byteString = abi.encodePacked(byteString, '[');
        bool bNoComma = true;
        for(uint256 i = 0; i<u32Size; ++i) {
            if(uValue > 0 && (uValue & 2**i) > 0) {
                if(bNoComma) {
                    bNoComma = false;
                } else {
                    byteString = abi.encodePacked(byteString, ',');
                }
                uint256 uTeamp = (uAppear  & arrTrackBitFlag[i]) / arrTrackBitShift[i];
                byteString = abi.encodePacked(byteString, '[', i.toString(), ',', uTeamp.toString(), ']');
            }
        }
        byteString = abi.encodePacked(byteString, ']'); 
        return string(byteString);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        return true;
    }    

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return interfaceId == _ERC165_ 
            || interfaceId == _ERC721_
            || interfaceId == _ERC2981_
            || interfaceId == _ERC721Metadata_;
    }

    function mint(uint256[][] memory vecValues) external onlyOwner {
        require(!m_bMintingFinalized, " minting is Finalized");

        uint256 index = m_countMint;

        for (uint256 i = 1; i <= vecValues.length; i++) {

            index = m_countMint + i;
            uint256 _value = vecValues[i-1][0];
            m_mapAppearance[index] = vecValues[i-1][1];
            m_mapValues[index] = _value;

            m_mapOwners[index] = m_addrOwner;

            emit Transfer(address(0), m_addrOwner, index);
            emit NewStellar(index, m_mapValues[index], m_mapAppearance[index].toHexString());
        }

        m_countMint += vecValues.length;
        m_countToken += vecValues.length;

        m_mapBalances[m_addrOwner] = m_countMint;
    }

    function finalize() external onlyOwner {
        m_bMintingFinalized = true;
    }

    function safeTransferFrom(address from, address to, uint256 uTokenId) public virtual override {
        safeTransferFrom(from, to, uTokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 uTokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), uTokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, uTokenId);
        require(_checkOnERC721Received(from, to, uTokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address from, address to, uint256 uTokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), uTokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, uTokenId);
    }

    function rand(uint256 _length, uint256 seed) internal view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
        return random%_length;
    }

    function _transfer(address from, address to, uint256 uTokenId) internal {
        require(_exists(uTokenId), "ERC721: transfer attempt for nonexistent token");
        require(ownerOf(uTokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(from != to, "ERC721: transfer attempt to self");
        // if(to == _dead){
        //     _burn(uTokenId);
        //     return;
        // }

        _approve(address(0), uTokenId);

        if(m_mapTokens[to] == 0){            

            m_mapTokens[to] = uTokenId;
            m_mapOwners[uTokenId] = to;
            m_mapTokens[from] = 0;

            m_mapBalances[to] += 1;
            m_mapBalances[from] -= 1;

            emit Transfer(from, to, uTokenId);
            // emit NewStellar(uTokenId, m_mapValues[uTokenId], m_mapAppearance[uTokenId].toHexString());
            return;
        }
        // merge
        uint256 uToTokenId = m_mapTokens[to];

        uint256 uValue = m_mapValues[uTokenId]; // getValueOf(uTokenId);

        // TODO need modify
        // add value
        m_mapValues[uToTokenId] += uValue;
        uint256 n256FromAppear = m_mapAppearance[uTokenId];
        uint256 n256ToAppear = m_mapAppearance[uToTokenId];
        uint256 n256NewAppear = 0;
        uint256 _seed = 0;
        for(uint32 i = 0; i< u32Size; ++i) {
            uint256 _fromAppear = n256FromAppear & arrTrackBitFlag[i];
            uint256 _toAppear = n256ToAppear & arrTrackBitFlag[i];
            uint256 _max = 0;
            uint256 _min = 0;

            if(_fromAppear < _toAppear) {
                _max = _toAppear;
                _min = _fromAppear;
            } else {
                _max = _fromAppear;
                _min = _toAppear;
            }
            // 75% choose max 
            // 20% choose min
            uint256 nRand = rand(100, _seed);
            _seed += nRand;
            if(nRand < 75) {
                n256NewAppear |= _max;
            }
            else if(nRand < 95) {
                n256NewAppear |= _min;
            } else {
                // 随机一个更小范围的。。。
                if(_min > 0) {
                    _min = _min / arrTrackBitShift[i];
                    nRand = rand(_min, _seed);
                    _seed += nRand;
                    _min = nRand * arrTrackBitShift[i];
                    n256NewAppear |= _min;
                }
            }
        }
        m_mapAppearance[uToTokenId] = n256NewAppear;


        m_mapBalances[to] += 1;
        m_mapBalances[from] -= 1;
        // remove old owner(from)'s tokenid
        m_mapTokens[from] = 0;
        delete m_mapOwners[uTokenId];
        // remove tokenid
        delete m_mapValues[uTokenId];
        delete m_mapAppearance[uTokenId];
        m_countToken -= 1;
        
        emit Transfer(from, to, uTokenId);
        emit NewStellar(uToTokenId, m_mapValues[uToTokenId], m_mapAppearance[uToTokenId].toHexString());
        emit RemoveStellar(uTokenId);
    }

    function getProjOwner() external view virtual returns (address) {
        return m_addrOwner;
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return m_mapBalances[owner];
    }

    function ownerOf(uint256 uTokenId) public view override returns (address) {
        require(_exists(uTokenId), "ERC721: owner query for nonexistent token");        
        return m_mapOwners[uTokenId];
    }

    function getValueOf(uint256 uTokenId) external view virtual returns (uint256) {
        return m_mapValues[uTokenId];
    }

    function getAppearanceOf(uint256 uTokenId) external view virtual returns (uint256) {
        return m_mapAppearance[uTokenId];
    }

    function getHexAppearanceOf(uint256 uTokenId) external view virtual returns (string memory) {
        return m_mapAppearance[uTokenId].toHexString();
    }

    function getTokenOf(address owner) external view virtual returns (uint256) {
        uint256 token = m_mapTokens[owner];
        return token;
    }

    function approve(address to, uint256 uTokenId) public virtual override {
        address owner = ownerOf(uTokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        m_mapTokenApprovals[uTokenId] = to;
        emit Approval(owner, to, uTokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        m_mapTokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
    
    function getApproved(uint256 uTokenId) public view virtual override returns (address) {
        require(_exists(uTokenId), "ERC721: operator query for nonexistent token");       
        return m_mapTokenApprovals[uTokenId];
    }

    function setApprovalForAll(address operator, bool bApproved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        m_mapOperatorApprovals[_msgSender()][operator] = bApproved;
        emit ApprovalForAll(_msgSender(), operator, bApproved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return m_mapOperatorApprovals[owner][operator];
    }

    function _exists(uint256 uTokenId) internal view returns (bool) {
        return m_mapValues[uTokenId] != 0;
    }

    function _isApprovedOrOwner(address operator, uint256 uTokenId) internal view virtual returns (bool) {
        require(_exists(uTokenId), "ERC721: operator query for nonexistent token");

        address owner = ownerOf(uTokenId);
        return (operator == owner || getApproved(uTokenId) == operator || isApprovedForAll(owner, operator));
    }

    function burn(uint256 uTokenId) public {
        require(_isApprovedOrOwner(_msgSender(), uTokenId), "ERC721: caller is not owner nor approved");
        _burn(uTokenId);
    }

    function _burn(uint256 uTokenId) internal {
        address owner = ownerOf(uTokenId);
        _approve(address(0), uTokenId);

        delete m_mapTokens[owner];
        delete m_mapOwners[uTokenId];
        delete m_mapValues[uTokenId];
        delete m_mapAppearance[uTokenId];

        m_countToken -= 1;
        m_mapBalances[owner] -= 1;        

        emit Transfer(owner, address(0), uTokenId);
        emit RemoveStellar(uTokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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

    function toHexString(uint i) public pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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