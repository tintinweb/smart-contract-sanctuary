pragma solidity ^0.4.19;

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable returns(bool);
    function approve(address _approved, uint256 _tokenId) external payable returns(bool);
    function getApproved(uint256 _tokenId) external view returns (address);
}

/* taking ideas from FirstBlood token */
contract RpSafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      require((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
      require(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x * y;
      require((x == 0)||(z/x == y));
      return z;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) { 
          return a;
        } else { 
          return b; 
        }
    }
    
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) { 
          return a;
        } else { 
          return b; 
        }
    }
}


contract TestERC721 is RpSafeMath, ERC721 {
    NFT[] public nfts;
    struct NFT{
        bytes32 name;
        uint nftId;
    }

    mapping (uint => uint) nftIdToIndex;

    mapping (uint => address) nftToOwner;
    mapping (uint => address) nftIdToApproved;
    mapping (address => uint) ownerNftCount;

    function balanceOf(address _owner) public view returns (uint) { return ownerNftCount[_owner]; }
    function ownerOf(uint _nftId) public view returns (address) { return nftToOwner[_nftId]; }
    function getApproved(uint _nftId) public view returns (address) { return nftIdToApproved[_nftId]; }


    function getNftsByOwner(address _owner) external view returns(uint[]) {
        uint[] memory result = new uint[](ownerNftCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < nfts.length; i++) {
            if (nftToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function addNtf(bytes32 _name, uint _nftId, address _owner) public {
        require(nftToOwner[_nftId] == 0x0);
        require(_owner != 0x0);

        nftIdToIndex[_nftId] = nfts.push(NFT(_name, _nftId)) - 1;
        ownerNftCount[_owner] = safeAdd(ownerNftCount[_owner], 1);
        nftToOwner[_nftId] = _owner;
    }

    function transferFrom(address _from, address _to, uint256 _nftId) external payable returns(bool) {
        address owner = nftToOwner[_nftId];
        require(owner != 0x0, "the bundle dont exist");
        require(owner == msg.sender || nftIdToApproved[_nftId] == msg.sender, "sender its not the owner or not approved");
        require(owner != _to, "the owner and `_to` should not be equal");
        require(owner == _from, "the owner and `_from` should be equal");
        require(_to != address(0), "`_to` is the zero address");

        ownerNftCount[_from]--;
        ownerNftCount[_to]++;

        nftToOwner[_nftId] = _to;

        emit Transfer(msg.sender, _to, _nftId);

        return true;
    }

    function approve(address _to, uint _nftId) public returns(bool) {
        require(msg.sender == nftToOwner[_nftId]);
        require(msg.sender != _to);

        nftIdToApproved[_nftId] = _to;

        emit Approval(msg.sender, _to, _nftId);

        return true;
    }
}