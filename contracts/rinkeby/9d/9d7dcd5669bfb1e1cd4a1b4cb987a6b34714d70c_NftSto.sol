/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner == msg.sender);
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != address(0));
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

}



pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;


contract NftSto is Authorizable {
    struct Nft {
        string symbol;
        string name;
        string icon;
        uint goal;
        string[] files;
    }

    uint public totalSupply;
    Nft[] public nftList;
    mapping (address => uint[]) private _holderTokens;
    mapping (string => uint) private _symbolMap;
    mapping (string => bool) private _nameMap;

    constructor() public {}

    function mintNft(address _to, string memory _symbol, string memory _name, string memory _icon, uint _goal) external onlyAuthorized returns (uint256) {
        require(_symbolMap[_symbol] == 0,"symbol exist");
        require(_nameMap[_name] == false,"name exist");
        uint tokenId = totalSupply;
        _symbolMap[_symbol]= tokenId+1;
        _nameMap[_name] = true;
        string[] memory _files;
        Nft memory n = Nft({symbol:_symbol,name:_name,icon:_icon,goal: _goal, files:_files});
        nftList.push(n);
        _holderTokens[_to].push(tokenId);
        totalSupply++;
        return tokenId;
    }

    function addFile(uint _tokenId, string memory _file) external onlyAuthorized  {
        require(_tokenId < totalSupply,"tokenId too big");
        nftList[_tokenId].files.push( _file);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (string memory, string memory, string memory) {
        uint length = _holderTokens[owner].length;
        require(length>0, "owner has no token");
        require(length > index,"index too big");
        uint tokenId =  _holderTokens[owner][index];
        return (nftList[tokenId].symbol,nftList[tokenId].name,nftList[tokenId].icon);
    }

    function filesOfOwnerByIndex(address owner, uint256 index) public view returns (string[] memory) {
        uint length = _holderTokens[owner].length;
        require(length>0, "owner has no token");
        require(length > index,"index too big");
        uint tokenId =  _holderTokens[owner][index];
        return nftList[tokenId].files;
    }

    function tokenBySymbol(string calldata _symbol) public view returns (string memory, string memory, string memory) {
        uint index = _symbolMap[_symbol];
        require(index>0, "symbol not found");
        uint tokenId =  index - 1;
        return (nftList[tokenId].symbol,nftList[tokenId].name,nftList[tokenId].icon);
    }

    function filesBySymbol(string calldata _symbol) public view returns (string[] memory) {
        uint index = _symbolMap[_symbol];
        require(index>0, "symbol not found");
        uint tokenId =  index - 1;
        return nftList[tokenId].files;
    }

    function filesByTokenId(uint _tokenId) public view returns (string[] memory) {
        return nftList[_tokenId].files;
    }

}