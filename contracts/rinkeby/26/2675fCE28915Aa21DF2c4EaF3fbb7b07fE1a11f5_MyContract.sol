/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.4.26;

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
}

contract MyContract is ERC721 {
    struct Champion{
        string name;
        uint16 rarity;
        uint8 totalSupply;
    }
    struct Item{
        string name;
        
    }
    Champion[] public champions; 
    mapping (uint => address) championToOwner;
    mapping (address => uint) totalChampionsByOwner;
    mapping (uint => address) approvals;

    function createNew(string memory _name, uint16 _rarity, uint8 _totalSupply) public {
        champions.push(Champion(_name, _rarity, _totalSupply));
        championToOwner[champions.length - 1] = msg.sender;
    } 

    function getTotalChampionsByOwner(address _owner) public view returns (uint) {
        return totalChampionsByOwner[_owner];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        championToOwner[_tokenId] = _to;
        totalChampionsByOwner[_from]--;
        totalChampionsByOwner[_to]++;
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require (championToOwner[_tokenId] == msg.sender || approvals[_tokenId] == msg.sender, "You dont have permission");
        _transfer(_from, _to, _tokenId);
    }

    function balanceOf(address _owner) external view returns (uint256) {
        uint total = totalChampionsByOwner[_owner];
        return total;
    }
    function ownerOf(uint256 _tokenId) external view returns (address) {
        return championToOwner[_tokenId];
    }
    function approve(address _approved, uint256 _tokenId) external payable {
        require(championToOwner[_tokenId] == msg.sender);
        approvals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }
}