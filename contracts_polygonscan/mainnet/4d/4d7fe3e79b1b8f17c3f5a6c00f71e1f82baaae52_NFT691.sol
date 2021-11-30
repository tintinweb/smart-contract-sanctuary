/**
 *Submitted for verification at polygonscan.com on 2021-11-28
*/

pragma solidity 0.8.6;

contract NFT691 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping (uint256 /*tokenId*/ => address /*owner*/) public _ownerOf;
    mapping (address /*address*/ => uint256 /*how many tokens user has*/) public _balanceOf;
    mapping (address /*from*/ => mapping (address /*address*/ => uint256 /*tokenId*/)) public _approval;
    mapping (address /*from*/ => mapping (address /*address*/ => bool)) public _approvalForAll;
    mapping (uint256 /*tokenId*/ => string) public _storage;
    mapping (uint256 /*tokenId*/ => address /*approvedFor*/) public _approvedFor;

    uint256 public deployAt;

    constructor () {
        deployAt = block.timestamp;
        }

    function balanceOf(address _owner) external view returns (uint256){
        return _balanceOf[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address){
        return _ownerOf[_tokenId];
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory) public {
        transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        transferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require((_ownerOf[_tokenId] == msg.sender) || (_approval[_from][msg.sender] == _tokenId), "NO_PERMISSION");
        require(_ownerOf[_tokenId] == _from, "NOT_OWNER");
        _ownerOf[_tokenId] = _to;
        _balanceOf[_from] = _balanceOf[_from] - 1;
        _balanceOf[_to] = _balanceOf[_to] + 1;
        emit Transfer(_from, _to, _tokenId);    
    }

    function approve(address _approved, uint256 _tokenId) external payable {
        require(_ownerOf[_tokenId] == msg.sender, "NOT_OWNER");
        _approval[msg.sender][_approved] = _tokenId;
        _approvedFor[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _op, bool _approved) external {
        _approvalForAll[msg.sender][_op] = _approved;
        emit ApprovalForAll(msg.sender, _op, _approved);    
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        return _approvedFor[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _approvalForAll[_owner][_operator];
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string memory _name){
        return "NFT691";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string memory _symbol) {
        return "NFT691";
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return _storage[_tokenId];
    }

    function mint(uint256 _tokenId, string memory metadata) public {
        require(block.timestamp <= deployAt + 24 * 60 * 60, "TOO_LATE");
        require(_ownerOf[_tokenId] == address(0), "ALREADY_MINTED");
        _storage[_tokenId] = metadata;
        _ownerOf[_tokenId] = msg.sender;
        _balanceOf[msg.sender] += 1;
        emit Transfer(address(0), msg.sender, _tokenId);    
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (interfaceId == 0x80ac58cd) || (interfaceId == 0x5b5e139f);
    }
}