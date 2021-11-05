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
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
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
        _name = "<3";
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

}