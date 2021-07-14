/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

//SPDX-License_Identifier: MIT
pragma solidity ^0.6.0; 

abstract contract ERC721 {
    // Required methods
    function approve(address _to, uint256 _tokenId) virtual public;
    function balanceOf(address _owner) virtual public view returns (uint256 balance);
    function implementsERC721() virtual public pure returns (bool);
    function ownerOf(uint256 _tokenId) virtual public view returns (address addr);
    function takeOwnership(uint256 _tokenId) virtual public;
    function totalSupply() virtual public view returns (uint256 total);
    function transferFrom(address _from, address _to, uint256 _tokenId) virtual public;
    function transfer(address _to, uint256 _tokenId) virtual public;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}


contract SportStarToken is ERC721 {
    address public ceoAddress;
    address public masterContractAddress;
    uint256 public promoCreatedCount;
    
    // ***** STORAGE

    mapping (uint256 => address) public tokenIndexToOwner;

    mapping (address => uint256) private ownershipTokenCount;

    mapping (uint256 => address) public tokenIndexToApproved;

    mapping (uint256 => bytes32) public tokenIndexToData;

    event Transfer(address from, address to, uint256 tokenId);

    // ***** TokenTypes
    struct Token {
        string name;
        string team;
    }

    Token[ ] public tokens;

    // ***** ACCESS MODIFIERS
    
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyMasterContract() {
        require(msg.sender == masterContractAddress);
        _;
    }

    // ***** CONSTRUCTOR
    constructor () public {
        ceoAddress = msg.sender;
    }
    
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setMasterContract(address _newMasterContract) public onlyCEO {
        require(_newMasterContract != address(0));

        masterContractAddress = _newMasterContract;
    }

    function getToken(uint256 _tokenId) public view returns (
        string memory tokenName,
        string memory tokenTeam,
        address owner
    ) {
        Token storage token = tokens[_tokenId];
        tokenName = token.name;
        tokenTeam = token.team;
        owner = tokenIndexToOwner[_tokenId];
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {

            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = totalSupply();
            uint256 resultIndex = 0;

            uint256 tokenId;
            for (tokenId = 0; tokenId <= totalTokens; tokenId++) {
                if (tokenIndexToOwner[tokenId] == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function getTokenData(uint256 _tokenId) public view returns (bytes32 tokenData) {
        return tokenIndexToData[_tokenId];
    }

    function approve(address _to, uint256 _tokenId) override public {
        // Caller must own token.
        require(_owns(msg.sender, _tokenId));

        tokenIndexToApproved[_tokenId] = _to;

        emit Approval(msg.sender, _to, _tokenId);
    }

    function balanceOf(address _owner) override public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

    function name() public pure returns (string memory) {
        return "CryptoSportStars";
    }
    function team() public pure returns (string memory) {
        return "CryptoSportTeam";
    }

    function symbol() public pure returns (string memory) {
        return "SportStarToken";
    }

    function implementsERC721() override public pure returns (bool) {
        return true;
    }

    function ownerOf(uint256 _tokenId) override public view returns (address owner)
    {
        owner = tokenIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    function takeOwnership(uint256 _tokenId) override public {
        address newOwner = msg.sender;
        address oldOwner = tokenIndexToOwner[_tokenId];

        // Safety check to prevent against an unexpected 0x0 default.
        require(_addressNotNull(newOwner));

        // Making sure transfer is approved
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

    // querying totalSupply of token
    function totalSupply() override public view returns (uint256 total) {
        return tokens.length;
    }

    function transfer(address _to, uint256 _tokenId) override public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) override public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }

    function createToken(string memory _name, string memory _team, address _owner) public onlyMasterContract returns (uint256 _tokenId) {
        return _createToken(_name, _team, _owner);
    }

    function updateOwner(address _from, address _to, uint256 _tokenId) public onlyMasterContract {
        _transfer(_from, _to, _tokenId);
    }

    function setTokenData(uint256 _tokenId, bytes32 tokenData) public onlyMasterContract {
        tokenIndexToData[_tokenId] = tokenData;
    }

    // PRIVATE FUNCTIONS
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    // For checking approval of transfer for address _to
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return tokenIndexToApproved[_tokenId] == _to;
    }

    // For creating Token
    function _createToken(string memory _name, string memory _team, address _owner) private returns (uint256 _tokenId) {
        Token memory _token = Token({
            name: _name,
            team: _team
            });
        // uint256 newTokenId = tokens.push(_token) - 1;
       // require(newTokenId == uint256(uint32(newTokenId)));
       //  _transfer(address(0), _owner, newTokenId);
       //  return newTokenId;
    
    }
    


    // Check for token ownership
    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == tokenIndexToOwner[_tokenId];
    }

    // @dev Assigns ownership of a specific Token to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        tokenIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete tokenIndexToApproved[_tokenId];
        }
        
        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }
}