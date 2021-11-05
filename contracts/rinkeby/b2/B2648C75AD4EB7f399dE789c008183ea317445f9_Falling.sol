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
interface ERC721 {
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
    string public _tokenURI;
    uint256 public _balance;
    address public _owner;

    constructor() {
        _balance = 1;
        _name = "Rose";
        _symbol = "LOVE";
        
        _tokenURI = "https://gist.githubusercontent.com/smatthewenglish/f574266c068213f9420472b603ae33e1/raw/90c1dda44662b2050945d1624713d3e27dbe0fac/rose.json";

        _owner = 0xBDbAEe6326cF7164EDaf107C525c1928B66d133f;
        emit Transfer(address(0), _owner, _balance);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return _tokenURI;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _balance;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(from == _owner, "ERC721: not yours to transfer");
        _owner = from;
        emit Transfer(from, to, _balance);
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

}