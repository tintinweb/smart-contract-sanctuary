/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

contract TokenAccessControl {
    
    bool public paused = false;
    address public owner;
    address public newContractOwner;
    mapping(address => bool) public authorizedContracts;
 
    event Pause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor () {
        owner = msg.sender;
    }
 
    modifier ifNotPaused {
        require(!paused);
        _;
    }
 
    modifier onlyContractOwner {
        require(msg.sender == owner);
        _;
    }
 
    modifier onlyAuthorizedContract {
        require(authorizedContracts[msg.sender]);
        _;
    }
    
    modifier onlyContractOwnerOrAuthorizedContract {
        require(authorizedContracts[msg.sender] || msg.sender == owner);
        _;
    }
 
    function transferOwnership(address _newOwner) external onlyContractOwner {
        require(_newOwner != address(0));
        newContractOwner = _newOwner;
    }
 
    function acceptOwnership() external {
        require(msg.sender == newContractOwner);
        emit OwnershipTransferred(owner, newContractOwner);
        owner = newContractOwner;
        newContractOwner = address(0);
    }
 
    function setAuthorizedContract(address _buyContract, bool _approve) public onlyContractOwner {
        if (_approve) {
            authorizedContracts[_buyContract] = true;
        } else {
            delete authorizedContracts[_buyContract];
        }
    }
 
    function setPause(bool _paused) public onlyContractOwner {
        paused = _paused;
        if (paused) {
            emit Pause();
        }
    }
   
}

contract TokenBase is TokenAccessControl {

    string public name;
    string public symbol;
    string public baseURI;
    uint256 public totalSupply;
    address royaltyReceiver;
    uint256 royaltyPercentage;
    
    mapping (uint256 => address) tokenToOwner;
    mapping (uint256 => address) tokenToApproved;
    mapping (address => uint256) ownerBalance;
    mapping (address => mapping (address => bool)) ownerToOperators;
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) ^
        bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('setApprovalForAll(address,bool)')) ^
        bytes4(keccak256('getApproved(uint256)')) ^
        bytes4(keccak256('isApprovedForAll(address,address)'));

    bytes4 constant InterfaceSignature_ERC721Metadata =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('tokenURI(uint256)'));
        
    constructor(string memory _name, string memory _symbol, string memory _baseURI) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        totalSupply = 0;
    }

    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) || 
                (_interfaceID == InterfaceSignature_ERC721) || 
                (_interfaceID == InterfaceSignature_ERC721Metadata));
    }
    
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
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    function changeNameAndSymbol(string memory _name, string memory _symbol) public onlyContractOwner {
        name = _name;
        symbol = _symbol;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return string(abi.encodePacked(baseURI, uint2str(_tokenId), ".json"));
    }

    function setTokenURI(string memory _baseURI) external onlyContractOwner {
        baseURI = _baseURI;
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return tokenToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return tokenToApproved[_tokenId] == _claimant;
    }

    function _operatorFor(address _operator, address _owner) internal view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }
    
    function _canReceive(address _addr, address _sender, address _owner, uint256 _tokenId, bytes memory _data) internal returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        bool isContract = (size > 0);
        
        if (isContract) {
            ERC721TokenReceiver receiver = ERC721TokenReceiver(_addr);
            if (receiver.onERC721Received(_sender, _owner, _tokenId, _data) != 
                bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))) {
                return false;
            }
        }
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownerBalance[_to]++;
        tokenToOwner[_tokenId] = _to;
        
        if (_from != address(0)) {
            ownerBalance[_from]--;
            delete tokenToApproved[_tokenId];
        }
        
        emit Transfer(_from, _to, _tokenId);
    }

    function balanceOf(address _owner) external view returns (uint256 count) {
        require(_owner != address(0));
        return ownerBalance[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = tokenToOwner[_tokenId];
        require(owner != address(0));
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable ifNotPaused {
        require(_owns(msg.sender, _tokenId) || 
                _approvedFor(msg.sender, _tokenId) || 
                ownerToOperators[tokenToOwner[_tokenId]][msg.sender]);  // owns, is approved or is operator
        require(_to != address(0) && _to != address(this));  // valid address
        require(tokenToOwner[_tokenId] != address(0));  // is valid NFT

        _transfer(_from, _to, _tokenId);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external payable ifNotPaused {
        this.transferFrom(_from, _to, _tokenId);
        require(_canReceive(_to, msg.sender, _from, _tokenId, _data));
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable ifNotPaused {
        this.safeTransferFrom(_from, _to, _tokenId, "");
    }

    function approve(address _to, uint256 _tokenId) external payable ifNotPaused {
        require(_owns(msg.sender, _tokenId) || 
                _operatorFor(msg.sender, this.ownerOf(_tokenId)));

        tokenToApproved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function setApprovalForAll(address _to, bool _approved) external ifNotPaused {
        if (_approved) {
            ownerToOperators[msg.sender][_to] = _approved;
        } else {
            delete ownerToOperators[msg.sender][_to];
        }
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(tokenToOwner[_tokenId] != address(0));
        return tokenToApproved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }
    
    function setRoyalty(address _receiver, uint8 _percentage) external onlyContractOwner {
        royaltyReceiver = _receiver;
        royaltyPercentage = _percentage;
    }
    
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        _tokenId = _tokenId;
        receiver = royaltyReceiver;
        royaltyAmount = uint256(_salePrice / 100) * royaltyPercentage;
    }
    
    receive() external payable {
        
    }
    
    fallback() external payable {
        
    }
    
    function withdrawBalance(uint256 _amount) external onlyContractOwner {
        payable(owner).transfer(_amount);
    }
    
}

contract CyberTradeFighter is TokenBase {

    uint256 lastFighterIndex = 0;
    mapping (uint256 => Fighter) fighters;
    
    constructor(string memory _name, string memory _symbol, string memory _baseURI) TokenBase(_name, _symbol, _baseURI) {
    }
    
    struct Fighter {
        uint8 hp;
        uint8 attack;
        uint8 defense;
        uint8 agility;
        
        uint8 level;
        uint16 xp;
        string name;
        string class;
        string tag;
        string syndicate;
        string genAttribute;
        string genElement;
        uint16 potentialMax;
        
        uint16[] skins;
        uint16 activeSkin;
    }

    function createToken(address _owner, string memory _name, string memory _class, string memory _syndicate, bool _isBoss,
                        string memory _genAttr, string memory _genElem
    ) public onlyAuthorizedContract ifNotPaused returns (uint256) {
        Fighter memory _fighter;
        _fighter.name = _name;
        _fighter.class = _class;
        _fighter.tag = _isBoss ? "Legendary Boss" : "Original Fighter";
        _fighter.syndicate = _syndicate;
        _fighter.genAttribute = _genAttr;
        _fighter.genElement = _genElem;
        
        totalSupply++;
        lastFighterIndex++;
        fighters[lastFighterIndex] = _fighter;
        fighters[lastFighterIndex].skins.push(0);
        _transfer(address(0), _owner, lastFighterIndex);

        return lastFighterIndex;
    }
    
    function getFighter(uint256 _id) external view returns (uint8 level, uint16 xp, 
        string memory name, string memory class, string memory tag, string memory syndicate, 
        string memory genAttribute, string memory genElement, uint16 potentialMax
    ) {
        Fighter memory fighter = fighters[_id];

        level = fighter.level;
        xp = fighter.xp;
        name = fighter.name;
        class = fighter.class;
        tag = fighter.tag;
        syndicate = fighter.syndicate;
        genAttribute = fighter.genAttribute;
        genElement = fighter.genElement;
        potentialMax = fighter.potentialMax;
    }
    
    function getFighterAttrs(uint256 _id) external view returns (uint8 hp, uint8 attack, uint8 defense, uint8 agility, uint16 activeSkin) {
        Fighter memory fighter = fighters[_id];
        hp = fighter.hp;
        attack = fighter.attack;
        defense = fighter.defense;
        agility = fighter.agility;
        activeSkin = fighter.activeSkin;
    }
    
    function getFighterSkins(uint256 _id) external view returns (uint16[] memory skins) {
        Fighter memory fighter = fighters[_id];
        return fighter.skins;
    }
    
    function deathFight(uint256 _fighter1, uint256 _fighter2) public ifNotPaused {
        require(msg.sender == tokenToOwner[_fighter1] &&
                msg.sender == tokenToOwner[_fighter2] &&
                _fighter1 != _fighter2);
        
        Fighter storage fighter1 = fighters[_fighter1];
        Fighter storage fighter2 = fighters[_fighter2];
        
        require(fighter1.level == 1 && fighter2.level == 1);
        require(keccak256(bytes(fighter1.class)) == keccak256(bytes(fighter2.class)));
        
        if (fighter1.hp < fighter2.hp) {
            fighter1.hp = fighter2.hp;
        }
        if (fighter1.attack < fighter2.attack) {
            fighter1.attack = fighter2.attack;
        }
        if (fighter1.defense < fighter2.defense) {
            fighter1.defense = fighter2.defense;
        }
        if (fighter1.agility < fighter2.agility) {
            fighter1.agility = fighter2.agility;
        }
        
        address owner = tokenToOwner[_fighter2];
        totalSupply--;
        delete fighters[_fighter2];
        delete tokenToOwner[_fighter2];
        delete tokenToApproved[_fighter2];
        ownerBalance[owner]--;
    }
 
    function setAttr(uint256 _fighter, address _user, uint8 _attr, string memory _stringValue, uint16 _intValue, bool _boolValue) public onlyContractOwnerOrAuthorizedContract ifNotPaused {
        require(_user == tokenToOwner[_fighter]);
        Fighter storage fighter = fighters[_fighter];
        uint16 i;
        
        if (_attr == 0) {
            fighter.xp += _intValue;
        } else if (_attr == 1) {
            require(keccak256(bytes(fighter.syndicate)) == keccak256(bytes("")), "You can set this attribute only once.");
            fighter.syndicate = _stringValue;
        } else if (_attr == 2) {
            // activate skin
            bool owned = false;
            for (i = 0; i < fighter.skins.length; i++) {
                if (fighter.skins[i] == _intValue) {
                    owned = true;
                }
            }
            require(owned, "You do not own this skin.");
            fighter.activeSkin = _intValue;
        } else if (_attr == 3) {
            // set gen element
            require(keccak256(bytes(fighter.genElement)) == keccak256(bytes("")), "You can set this attribute only once.");
            fighter.genElement = _stringValue;
        } else if (_attr == 4) {
            // used for adding and removing skins
            require(_intValue > 0 && fighter.activeSkin != _intValue);
            uint16 owned_index = 0;
            for (i = 1; i < fighter.skins.length; i++) {
                if (fighter.skins[i] == _intValue) {
                    owned_index = i;
                    break;
                }
            }
            if (owned_index > 0 && !_boolValue){
                fighter.skins[owned_index] = fighter.skins[fighter.skins.length-1];
                fighter.skins.pop();
            } else if (owned_index == 0 && _boolValue) {
                fighter.skins.push(_intValue);
            }
        }
    }
 
    function levelUp(uint256 _fighter, uint8 _h, uint8 _a, uint8 _d, uint8 _s, uint16 _potentialMax) public onlyContractOwnerOrAuthorizedContract ifNotPaused{
        Fighter storage fighter = fighters[_fighter];
        if (keccak256(bytes(fighter.tag)) == keccak256(bytes("Original Fighter")) && fighter.level == 10) {
            fighter.tag = "Original Boss";
            fighter.level = 1;
            fighter.xp = 0;
            fighter.potentialMax = _potentialMax;
        } else {
            fighter.level++;
            fighter.xp = 0;
            fighter.hp = _h;
            fighter.attack = _a;
            fighter.defense = _d;
            fighter.agility = _s;
            if (_potentialMax != 0) {
                fighter.potentialMax = _potentialMax;
            }
        }
    }

}