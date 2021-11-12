/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IBEP721 {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
    function balanceOf(address _owner) external view returns(uint256);
    function ownerOf(uint256 _cardId) external view returns(address);

    function CreateCard(address _owner) external returns(uint256);
    function TransferCard(uint256 _cardId, address _fromowner, address _newowner) external returns(uint256);
    function getOwnerNFTCount(address _owner) external view returns(uint256);
    function getOwnerNFTIDs(address _owner) external view returns(uint256[] memory);
    function totalSupply() external view returns(uint256);
}

contract AccessControl {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event ControllerAccessChanged(address indexed _controller, bool indexed _access);

    mapping(address => bool) whitelistController;
    modifier onlyOwner {
        require(msg.sender == owner, "invalid owner");
        _;
    }
    modifier onlyController {
        require(whitelistController[msg.sender] == true, "invalid controller");
        _;
    }
    function TransferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
    function WhitelistController(address _controller) public onlyOwner {
        whitelistController[_controller] = true;
        emit ControllerAccessChanged(_controller, true);
    }
    function BlacklistController(address _controller) public onlyOwner {
        whitelistController[_controller] = false;
        emit ControllerAccessChanged(_controller, false);
    }
    function Controller(address _controller) public view returns(bool) {
        return whitelistController[_controller];
    }
}

contract TestNFT is IBEP721, AccessControl {
    
    // Token name
    string public name = "Test NFT";
    // Token symbol
    string public symbol = "TEST";
    
    // Mapping from token ID to owner address
    mapping(uint256 => address) owners;
    // Mapping owner address to token count
    mapping(address => uint256) balances;

    //dev Array of all NFT IDs.
    uint256[] internal tokens;
    //Mapping from token ID to its index in global tokens array.
    mapping(uint256 => uint256) internal idToIndex;
    //Mapping from owner to list of owned NFT IDs.
    mapping(address => uint256[]) internal ownerToIds;
    //Mapping from NFT ID to its index in the owner tokens list.
    mapping(uint256 => uint256) internal idToOwnerIndex;

    uint256 public TokenId;

    constructor() {
        AccessControl.owner = msg.sender;
    }


    function CreateCard(address _owner) onlyController external virtual override returns(uint256) {
        TokenId += 1;
        owners[TokenId] = _owner;

        //add new nft item 
        _mint(_owner, TokenId);

        //set owner of new nft item
        addNFToken(_owner, TokenId);
        return TokenId;
    }
    
    function TransferCard(uint256 _cardId, address _fromowner, address _newowner) onlyController external virtual override returns(uint256)  {
        require(ownerOf(_cardId) == _fromowner, "invalid owner");
        require(_newowner != address(0), "invalid new owner address");
        //cardForSale[_cardId] = false;
        //_beforeTokenTransfer(from, to, tokenId);

        removeNFToken(_fromowner, _cardId);

        //set nft to the new owner
        addNFToken(_newowner, _cardId);
        
        emit Transfer(_fromowner, _newowner, _cardId);
        return _cardId;
    }
   
    

    

    function tokenByIndex(uint256 _index) internal view returns(uint256)
    {
        require(_index < tokens.length, "invalid index");
        return tokens[_index];
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) internal view returns(uint256)
    {
        require(_index < ownerToIds[_owner].length, "invalid index");
        return ownerToIds[_owner][_index];
    }

    function getOwnerNFTCount(address _owner) external override virtual view returns(uint256)
    {
        return ownerToIds[_owner].length;
    }

    function getOwnerNFTIDs(address _owner) external override  virtual view returns(uint256[] memory)
    {
        return ownerToIds[_owner];
    }
    
    

    function addNFToken(address _to, uint256 _cardId) internal
    {
        balances[_to] += 1;
        owners[_cardId] = _to;
        ownerToIds[_to].push(_cardId);
        idToOwnerIndex[_cardId] = ownerToIds[_to].length - 1;
    }

    function removeNFToken(address _from, uint256 _cardId) internal  virtual
    {
        delete owners[_cardId];
        balances[_from] -= 1;
        uint256 tokenToRemoveIndex = idToOwnerIndex[_cardId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    function _mint(address to, uint256 _cardId) internal virtual {
        require(to != address(0), "invalid owner address");
        tokens.push(_cardId);
        idToIndex[_cardId] = tokens.length - 1;

        emit Transfer(address(0), to, _cardId);
    }
    
    
    //total count of nfts
    function totalSupply() external override view returns(uint256)
    {
        return tokens.length;
    }
    
    function balanceOf(address _owner) public view virtual override returns(uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return balances[_owner];
    }
    
    function ownerOf(uint256 _cardId) public view virtual override returns(address) {
        address owner = owners[_cardId];
        require(owner != address(0), "owner query for nonexistent token");
        return owner;
    }
    
    function shutdown()  public onlyOwner {
        selfdestruct(payable(AccessControl.owner));
    }



}