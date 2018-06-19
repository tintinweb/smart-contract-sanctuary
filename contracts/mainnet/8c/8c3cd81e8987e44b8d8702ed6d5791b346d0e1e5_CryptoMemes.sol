pragma solidity ^0.4.18;

contract ERC721 {

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    function balanceOf(address _owner) public view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) public view returns (address _owner);

    function transfer(address _to, uint256 _tokenId) public;

    function approve(address _to, uint256 _tokenId) public;

    function takeOwnership(uint256 _tokenId) public;
}

contract CryptoMemes is ERC721 {

    event Transfer(address from, address to, uint256 tokenId);
    event Created(address owner, uint256 tokenId, string url, uint256 hash, uint256 createdAt);
    event UrlUpdated(address owner, uint256 tokenId, string url);

    modifier onlyOwnerOf(uint256 tokenId) {
        require(memeIndexToOwner[tokenId] == msg.sender);
        _;
    }

    modifier onlyOwnerOfContract() {
        require(msg.sender == contractOwner);
        _;
    }

    struct Meme {
        string url;
        uint256 hash;
        uint256 createdAt;
    }

    Meme[] memes;

    //the owner can adjust the meme price
    address contractOwner;

    //the price user must pay to create a meme
    uint price;

    mapping(uint256 => address) memeIndexToOwner;
    mapping(address => uint256) ownershipTokenCount;
    mapping(uint => address) memeApprovals;

    function CryptoMemes() public {
        contractOwner = msg.sender;
        price = 0.005 ether;
    }

    function getPrice() external view returns (uint) {
        return price;
    }

    function getContractOwner() external view returns (address) {
        return contractOwner;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        ownershipTokenCount[_from]--;
        memeIndexToOwner[_tokenId] = _to;
        delete memeApprovals[_tokenId];
        Transfer(_from, _to, _tokenId);
    }

    function _createMeme(string _url, uint256 _hash, address _owner) internal returns (uint256) {
        uint256 newMemeId = memes.push(Meme({url : _url, hash : _hash, createdAt : now})) - 1;
        Created(_owner, newMemeId, _url, _hash, now);
        _transfer(0, _owner, newMemeId);
        return newMemeId;
    }

    function createMeme(string _url, uint256 _hash) payable external {
        _validateUrl(_url);
        require(msg.value == price);
        _createMeme(_url, _hash, msg.sender);
    }

    //validates the url cannot be of ambiguous length
    function _validateUrl(string _url) pure internal {
        require(bytes(_url).length < 1024);
    }

    function getMeme(uint256 _tokenId) public view returns (
        string url,
        uint256 hash,
        uint256 createdAt
    ) {
        Meme storage meme = memes[_tokenId];
        url = meme.url;
        hash = meme.hash;
        createdAt = meme.createdAt;
    }

    function updateMemeUrl(uint256 _tokenId, string _url) external onlyOwnerOf(_tokenId) {
        _validateUrl(_url);
        memes[_tokenId].url = _url;
        UrlUpdated(msg.sender, _tokenId, _url);
    }

    function totalSupply() public view returns (uint256 total) {
        return memes.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        return memeIndexToOwner[_tokenId];
    }

    function approve(address _to, uint256 _tokenId) onlyOwnerOf(_tokenId) public {
        memeApprovals[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) public {
        require(memeApprovals[_tokenId] == msg.sender);
        address owner = ownerOf(_tokenId);
        _transfer(owner, msg.sender, _tokenId);
    }

    function updatePrice(uint _price) external onlyOwnerOfContract() {
        price = _price;
    }

    function transferContractOwnership(address _newOwner) external onlyOwnerOfContract() {
        contractOwner = _newOwner;
    }

    function withdraw() external onlyOwnerOfContract() {
        contractOwner.transfer(address(this).balance);
    }
}