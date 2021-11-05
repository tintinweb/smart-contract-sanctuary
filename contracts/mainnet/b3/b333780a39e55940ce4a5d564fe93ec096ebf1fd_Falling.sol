/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

/** 
 *         .     .
 *     ...  :``..':
 *      : ````.'   :''::'
 *    ..:..  :     .'' :
 * ``.    `:    .'     :
 *     :    :   :        :
 *      :   :   :         :
 *      :    :   :        :
 *       :    :   :..''''``::.
 *        : ...:..'     .''
 *        .'   .'  .::::'
 *       :..'''``:::::::
 *       '         `::::
 *                   `::.
 *                    `::
 *                     :::.
 *          ..:```.:'`. ::'`.
 *        ..'      `:.: ::
 *       .:        .:``:::
 *       .:    ..''     :::
 *        : .''         .::
 *         :          .'`::
 *                       ::
 *                       ::
 *                        :
 *                        :
 *                        :
 *                        :
 *                        .
 */
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract Falling is ERC721, ERC721Metadata {
    string public _name;
    string public _symbol;
    uint256 public _balance;
    address public _owner;

    constructor() {
        _balance = 1;
        _name = "Falling";
        _symbol = "ROSE";
        
        _owner = 0x2ee8D80de1c389f1254e94bc44D2d1Bc391eD402;
        emit Transfer(address(0), _owner, _balance);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return "https://gist.githubusercontent.com/smatthewenglish/dd4086bceaf4252d7c91de36de105958/raw/20f0c11d66f87327695038e754c462a0ddf06063/falling.json";
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balance;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(msg.sender != _owner, "ERC721: not yours to give away!");
        _owner = 0xAB915162DB74d70b7C2E2aE57Be147Ebbd9e18F5;
        emit Transfer(from, 0xAB915162DB74d70b7C2E2aE57Be147Ebbd9e18F5, _balance);
    }

    function burn() public virtual {
        require(msg.sender != _owner, "ERC721: not yours to break!");
        _owner = 0x000000000000000000000000000000000000dEaD;
        emit Transfer(_owner, 0x000000000000000000000000000000000000dEaD, _balance);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {}

    function getApproved(uint256 tokenId) public view virtual override returns (address) {}

    function setApprovalForAll(address operator, bool approved) public virtual override {}

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        bytes4 ERC165 = 0x01ffc9a7;
        bytes4 ERC721 = 0x80ac58cd;
        bytes4 ERC721Metadata = 0x5b5e139f;
        return interfaceId == ERC165 
            || interfaceId == ERC721
            || interfaceId == ERC721Metadata;
    }
}