/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity >=0.4.0;
   
contract erc721{
    
    string private _name = "My NFT";
    string private _symbol = "MNFT";
    string private baseURI = "https://ipfs.io/ipfs/QmZ7vLC9UjfTh7MFo3xhBJw7WF9t8QdJaCSWJF734XSULn?filename=";
    mapping (uint => address) private _owners;
    mapping (address => uint) private _balances;
    mapping (uint => address) private _tokenApprovals;
    mapping (address => mapping(address => bool)) private _operatorApprovals;
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    function name() external view returns (string ){
        return _name;
    }
    
    function symbol() external view returns (string){
        return _symbol;
    }

    function balanceOf(address _owner) external view returns (uint256){
        return _balances[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address){
        return _owners[_tokenId];
    }
        
    function tokenURI(uint256 _tokenId) public view returns (string){
        require(_owners[_tokenId] != address(0));
        string memory buri= baseURI;
        return string(abi.encodePacked(buri, uintToString(_tokenId), ".json"));
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable{
       require(_owners[_tokenId] != address(0));
       address owner =ownerOf(_tokenId);
       require(msg.sender == owner || msg.sender == getApproved(_tokenId) || isApprovedForAll(owner, msg.sender));
       _transfer(_from, _to, _tokenId);
    }
    
    function approve(address _approved, uint256 _tokenId) external payable{
        address owner = erc721.ownerOf(_tokenId);
        require(msg.sender == owner);
        require(owner != _approved);
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) external{
        require(msg.sender != _operator);
        _operatorApprovals[msg.sender][_operator]=_approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function getApproved(uint256 _tokenId) public view returns (address){
        require(_owners[_tokenId] != address(0));
        return _tokenApprovals[_tokenId];
    }
    
    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        return _operatorApprovals[_owner][_operator];
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        require(_owners[_tokenId] == _from);
        require(_to !=address(0));
        _balances[_from]-=1;
        _balances[_to]+=1;
        _owners[_tokenId]=_to;
        emit Transfer(_from, _to, _tokenId);
    }
    function uintToString(uint v) public pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }
    
    function mint(address _to, uint _tokenId) external{
        require(_to != address(0), "ERC721: mint to the zero address");
        require(_owners[_tokenId] == address(0), "ERC721: token already minted");

        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);
    }
}