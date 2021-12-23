//Abdullah Rangoonwala
pragma solidity 0.8.7;
 
import "./token.sol";
import "./ownable.sol";
import "./tokenMeta.sol";
import "./erc721.sol";

 contract nebulaNFT is NFTokenMetadata, Ownable {
    uint256 currentID = 0;
    uint256 supply = 100;
    constructor() payable {
      nftName = "Nebula 41";
      nftSymbol = "NEB";
    }
    fallback() external payable { }
    receive() external payable { }

    address[] public nebulaTeamAddresses;
    address[] public whiteAddresses;

    bool public publicMint = false;
    bool public privateMint = false;

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function mint(address _to) public payable{
      require(currentID<supply, "Max Supply Reached");
      require(msg.value >= 80000000000000000 wei, "Invalid ETH Amount");
      string memory _uri = string(abi.encodePacked("https://nebula41.io/",uint2str(currentID),".json","",""));
      
      uint256 _tokenId = currentID;
      super._mint(_to, _tokenId);
      currentID = currentID+1;
      super._setTokenUri(_tokenId, _uri);
    } 

    function preMint() public {
      require(isNebulaTeam(msg.sender));
      for (uint i = 0; i < 1101; i++) {
        string memory _uri = string(abi.encodePacked("https://nebula41.io/",uint2str(currentID),".json","",""));
        
        uint256 _tokenId = currentID;
        super._mint(msg.sender, _tokenId);
        currentID = currentID+1;
        super._setTokenUri(_tokenId, _uri);
      }
    }
    
    function setTokenURI(uint256 _tokenId, string memory _uri) public {
      require(isNebulaTeam(msg.sender));
      super._setTokenUri(_tokenId, _uri);
    }

    function enablePublicMint() public {
      require(isNebulaTeam(msg.sender));
      publicMint = true;
    }

    function enablePrivateMint() public {
      require(isNebulaTeam(msg.sender));
      privateMint = true;
    }

    function extractEther() external onlyOwner {
      payable(msg.sender).transfer(address(this).balance);
    }

    function nebulaTeam(address[] calldata _users) public onlyOwner {
      delete nebulaTeamAddresses;
      nebulaTeamAddresses = _users;
    }

    function isNebulaTeam(address _user) public view returns (bool) {
      for (uint i = 0; i < nebulaTeamAddresses.length; i++) {
        if (nebulaTeamAddresses[i] == _user) {
            return true;
        }
      }
      return false;
    }

    function isWhitelisted(address[] calldata _users) public onlyOwner {
      delete whiteAddresses;
      whiteAddresses = _users;
    }

    function isWhitelisted(address _user) public view returns (bool) {
      for (uint i = 0; i < whiteAddresses.length; i++) {
        if (whiteAddresses[i] == _user) {
            return true;
        }
      }
      return false;
    }
 }