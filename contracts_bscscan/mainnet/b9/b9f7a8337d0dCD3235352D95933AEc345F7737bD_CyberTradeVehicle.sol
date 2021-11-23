/**
 *Submitted for verification at BscScan.com on 2021-11-23
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

contract CyberTradeVehicle is TokenBase {

    uint256 lastVehicleIndex = 0;
    mapping (uint256 => Vehicle) vehicles;
    
    constructor(string memory _name, string memory _symbol, string memory _baseURI) TokenBase(_name, _symbol, _baseURI) {
    }
    
    struct Vehicle {
        uint8 top_speed;
        uint8 acceleration;
        uint8 handling;
        uint8 traction;
        
        uint8 level;
        uint16 xp;
        string name;
        string class;
        string tag;
        uint16 potentialMax;
        
        uint16[] skins;
        uint16 activeSkin;
    }

    function createToken(address _owner, string memory _name, string memory _class, string memory _tag, uint16 _potentialMax
    ) public onlyAuthorizedContract ifNotPaused returns (uint256) {
        Vehicle memory _vehicle;
        _vehicle.name = _name;
        _vehicle.class = _class;
        _vehicle.tag = _tag;
        _vehicle.potentialMax = _potentialMax;
        
        totalSupply++;
        lastVehicleIndex++;
        vehicles[lastVehicleIndex] = _vehicle;
        vehicles[lastVehicleIndex].skins.push(0);
        _transfer(address(0), _owner, lastVehicleIndex);

        return lastVehicleIndex;
    }
    
    function getVehicle(uint256 _id) external view returns (uint8 level, uint16 xp, 
        string memory name, string memory class, string memory tag, uint16 potentialMax
    ) {
        Vehicle memory vehicle = vehicles[_id];

        level = vehicle.level;
        xp = vehicle.xp;
        name = vehicle.name;
        class = vehicle.class;
        tag = vehicle.tag;
        potentialMax = vehicle.potentialMax;
    }
    
    function getVehicleAttrs(uint256 _id) external view returns (uint8 top_speed, uint8 acceleration, uint8 handling, uint8 traction, uint16 activeSkin) {
        Vehicle memory vehicle = vehicles[_id];
        top_speed = vehicle.top_speed;
        acceleration = vehicle.acceleration;
        handling = vehicle.handling;
        traction = vehicle.traction;
        activeSkin = vehicle.activeSkin;
    }
    
    function getVehicleSkins(uint256 _id) external view returns (uint16[] memory skins) {
        Vehicle memory vehicle = vehicles[_id];
        return vehicle.skins;
    }
 
    function setAttr(uint256 _vehicle, address _user, uint8 _attr, string memory _stringValue, uint16 _intValue, bool _boolValue) public onlyContractOwnerOrAuthorizedContract ifNotPaused {
        require(_user == tokenToOwner[_vehicle]);
        Vehicle storage vehicle = vehicles[_vehicle];
        uint16 i;
        
        if (_attr == 0) {
            vehicle.xp += _intValue;
        } else if (_attr == 1) {
            _stringValue = _stringValue;
        } else if (_attr == 2) {
            // activate skin
            bool owned = false;
            for (i = 0; i < vehicle.skins.length; i++) {
                if (vehicle.skins[i] == _intValue) {
                    owned = true;
                }
            }
            require(owned, "You do not own this skin.");
            vehicle.activeSkin = _intValue;
        } else if (_attr == 3) {
            
        } else if (_attr == 4) {
            // used for adding and removing skins
            require(_intValue > 0 && vehicle.activeSkin != _intValue);
            uint16 owned_index = 0;
            for (i = 1; i < vehicle.skins.length; i++) {
                if (vehicle.skins[i] == _intValue) {
                    owned_index = i;
                    break;
                }
            }
            if (owned_index > 0 && !_boolValue){
                vehicle.skins[owned_index] = vehicle.skins[vehicle.skins.length-1];
                vehicle.skins.pop();
            } else if (owned_index == 0 && _boolValue) {
                vehicle.skins.push(_intValue);
            }
        }
    }
 
    function levelUp(uint256 _nft, uint8 _ts, uint8 _a, uint8 _h, uint8 _t, uint16 _potentialMax) public onlyContractOwnerOrAuthorizedContract ifNotPaused{
        Vehicle storage vehicle = vehicles[_nft];
        vehicle.level++;
        vehicle.xp = 0;
        vehicle.top_speed = _ts;
        vehicle.acceleration = _a;
        vehicle.handling = _h;
        vehicle.traction = _t;
        vehicle.potentialMax = _potentialMax;
    }

}