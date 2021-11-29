/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

pragma solidity ^0.4.0;

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
    
    //開根號
    function sqrt(uint x) internal pure returns(uint) {
        uint z = (x + 1 ) / 2;
        uint y = x;
        while(z < y){
          y = z;
          z = ( x / z + z ) / 2;
        }
        return y;
     }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {

        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721Metadata {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable{
  function totalSupply()external view returns (uint256);
  function tokenByIndex(uint256 _index)external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner,uint256 _index) external view returns (uint256);
}

interface ERC20 {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external view returns (uint256 balance);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}



contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {

        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
} 

contract IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

contract ERC721 is ERC165, IERC721{
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;
    
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    mapping (address => Counters.Counter) private _mintTokensCount;
    
    mapping(address => uint256[]) private _ownedTokens;
    
    // NFT get time
    mapping (uint256 => uint256) private _tokenTime;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    
        _registerInterface(_INTERFACE_ID_ERC721);
        
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }
    
    function get_nft_time(uint256 tokenId) public view returns (uint256) {
        return _tokenTime[tokenId];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
        
        delete_token_owned(from,tokenId);//原擁有者移除
        _ownedTokens[to].push(tokenId);//新擁有者增加
        
        _tokenTime[tokenId] = now;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
        
        delete_token_owned(from,tokenId);//原擁有者移除
        _ownedTokens[to].push(tokenId);//新擁有者增加
        
        _tokenTime[tokenId] = now;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        delete_token_owned(from,tokenId);//原擁有者移除
        _ownedTokens[to].push(tokenId);//新擁有者增加
        
        _tokenTime[tokenId] = now;
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();
        _mintTokensCount[to].increment();
        
        _ownedTokens[to].push(tokenId);
        
        _tokenTime[tokenId] = now;

        emit Transfer(address(0), to, tokenId);
    }
    
    function get_user_token(address addr) public view returns (uint256[]) {
        return _ownedTokens[addr];
    }
    
    function delete_token_owned(address addr,uint256 _tokenid) internal {
    
        for (uint j = 0; j < _ownedTokens[addr].length; j++) {
            if(_ownedTokens[addr][j]==_tokenid)
            {
                delete _ownedTokens[addr][j];
                for (uint i = j; i<_ownedTokens[addr].length-1; i++){
                    _ownedTokens[addr][i] = _ownedTokens[addr][i+1];
                }
                delete _ownedTokens[addr][_ownedTokens[addr].length-1];
                _ownedTokens[addr].length--;
            }
        }
    }
    
    function mint_count(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _mintTokensCount[owner].current();
    }
    
    function name() public view  returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);
        
        delete_token_owned(owner,tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}


contract JBLNFT is ERC721{
    
    struct Card {
        string name; 
        uint8 _type;
        string tokenURI;
        uint256 apy;
        uint256 price;
    }
    
    ERC20 public token;

    uint256 public NFT_APY = 1*10**18; //基礎APY：100 , 加成APY：0
    uint256 public PRICE = 5; //單位5個JBL-Token

    Card[] public cards; // First Item has Index 0
    address public owner;
    mapping (uint256 => string) private _tokenURIs;
    uint8 public maxSupply = 70;
    uint8 public mint_total = 70;
    bool public initialized = true;
    address public JBLtoken;

    event _withdraw(address _addr, uint256 _value, uint256 _time);
    event _chg_price(uint256 old_price, uint256 new_price, uint256 _time);
    event _chg_apy(uint256 old_apy, uint256 new_apy, uint256 _time);
    event _mintBatch(address _sender, address _NFTowner, uint256 _num);

    constructor ()  public ERC721("JBL-HALLOWEEN", "JBL-HALLOWEEN"){
        owner = msg.sender; 
        _set_JBL_TOKEN(0x2148c3ed475fc0a4c70269641e6b76c2a4b8c855);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
     }
    
    function isActive() public view returns (bool) {
        return (initialized == true);
    }
    
    //pay token
    function _set_JBL_TOKEN(address _tokenAddr) internal onlyOwner{
        require(_tokenAddr != 0);
        JBLtoken = _tokenAddr;
        token = ERC20(_tokenAddr);
    }
    
    function mintCard(address account) public returns (uint256) {
        uint256 cardId = cards.length;
        uint256 JBL_B = token.balanceOf(msg.sender);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= PRICE*1*10**18, "Check the JBL token allowance");
        require(JBL_B >= PRICE*1*10**18,"Check your JBL token balance");
        require(isActive());
        require(mint_total > 0 ,"Not enough remaining quantity");
        
        string memory name = "JBL-HALLOWEEN";
        uint256 token_ide = cardId % 3 + 1;
        string memory m = uint2str(token_ide);
        string memory _url = "https://jbl.i-recu.com/nft/halloween/ha";    
        string memory tokenURI = strConcat(_url,m,'.png');

        token.transferFrom(msg.sender, address(this), PRICE*1*10**18);
        
        mint_total = mint_total-1;

        cards.push(Card(name, 4, tokenURI, NFT_APY, PRICE));
        _mint(account, cardId); 
        _setTokenURI(cardId, tokenURI);
        
        return cardId;
        
    }
    
    function mintBatch(address account, uint256 num) public {
        emit _mintBatch(msg.sender, account, num);
        for(uint t = 0; t < num; t++) {
            mintCard(account);
        }
    } 
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
    
    
    function initialize() public onlyOwner {
        if(initialized)
        {
            initialized = false;
        }
        else
        {
            initialized = true;
        }
    }
    // 設定NFT價格 (不需乘 10^18)
    function set_PRICE(uint256 _amount) public onlyOwner {
        emit _chg_price(PRICE, _amount, now);

        PRICE = _amount;
    }

    // 設定APY加乘 (需乘 10^18)
    function set_APY(uint256 _apy) public onlyOwner {
        emit _chg_apy(NFT_APY, _apy, now);
        NFT_APY = _apy;
    }

    function totalSupply()public view returns (uint256) {
        return maxSupply;
    }

    function GRT_NFT_PRICE(uint256 _id)public view returns (uint256) {
        Card storage card = cards[_id];
        return card.price;
    }

    function GRT_NFT_APY(uint256 _id)public view returns (uint256) {
        Card storage card = cards[_id];
        return card.apy;
    }

    function GRT_NFT_TYPE(uint256 _id)public view returns (uint256) {
        Card storage card = cards[_id];
        return card._type;
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        
        string memory ret = new string(_ba.length + _bb.length + _bc.length);
        
        bytes memory bret = bytes(ret);
        
        uint k = 0;
        
        for (uint i = 0; i < _ba.length; i++)
        {
            bret[k++] = _ba[i];
        }
        
        for (uint j = 0; j < _bb.length; j++) 
        {
            bret[k++] = _bb[j];
        }
        
        for (uint y = 0; y < _bc.length; y++) 
        {
            bret[k++] = _bc[y];
        }
        
        return string(ret);
        
    }
    
    
    function uint2str(uint i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            
            bstr[k--] = bytes1(48 + i % 10);
            i /= 10;
        }

        return string(bstr);
    }
    
    //堤幣
    function withdraw() public onlyOwner{
        address contract_addr = address(this);
        uint256 contract_balance = token.balanceOf(contract_addr);
        token.transfer(msg.sender, contract_balance);
        
        emit _withdraw(msg.sender, contract_balance, now);
    }
}