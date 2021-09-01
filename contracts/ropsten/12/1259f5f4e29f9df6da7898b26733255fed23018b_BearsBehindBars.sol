// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "SafeMath.sol";
import "ERC721Enumerable.sol";
import "ERC721URIStorage.sol";
import "Counters.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";

contract BearsBehindBars is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public max_supply = 9999;
    uint256 public max_Full_Bear = 3333;
    string private _contractURI;
    address payable admin;
    

    ProxyRegistry private _proxyRegistry;
    Counters.Counter private _tokenIds;

    mapping(uint256 => uint256) bHash;
    
    struct traits {
        uint256 ear;
        uint256 head;
        uint256 body;
        uint256 rarm;
        uint256 larm;
        uint256 rleg;
        uint256 lleg;
    }
    
    traits Btraits;
    mapping(uint256 => traits) public BearTraits;

    modifier onlyAdmin() {
        require(admin == msg.sender, "Not yours");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address payable _admin,
        address openseaProxyRegistry_
    ) ERC721(_name, _symbol) {
        admin = _admin;
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }
    }

    function mint(uint256 _amount) public payable nonReentrant {
        require(
            uint256(10000000000000000).mul(_amount) == msg.value,
            "value"
        );
        require(_amount <= 15, "over 15");
        require(
            _tokenIds.current().add(_amount) <= max_Full_Bear,
            "Im Out"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 newNftTokenId = _tokenIds.current();
            bHash[newNftTokenId] = uint256(
                keccak256(abi.encodePacked(address(msg.sender), newNftTokenId, block.timestamp,blockhash(block.number-1),gasleft()))
            );
            randomizer(newNftTokenId);
            _mint(msg.sender, newNftTokenId);
        }
    }
    
    function mintPart(uint256 _amount, uint256 part) public payable nonReentrant {
        require(
            uint256(3000000000000000).mul(_amount) == msg.value,
            "value"
        );
        require(_amount <= 30, "over 30");
        require(
            _tokenIds.current().add(_amount) <= max_supply,
            "Im Out"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 newNftTokenId = _tokenIds.current();
            bHash[newNftTokenId] = uint256(
                keccak256(abi.encodePacked(address(msg.sender), newNftTokenId,block.timestamp,blockhash(block.number-1),gasleft()))
            );
            randomPart(newNftTokenId,part);
            _mint(msg.sender, newNftTokenId);
        }
    }
    
    function mergeBear(uint256[] memory parts) public nonReentrant {
        for (uint256 i = 0; i< parts.length; i++){
            require(_isApprovedOrOwner(_msgSender(), parts[i]), "not owner approved");
            if(BearTraits[parts[i]].ear != 55){
                Btraits.ear = BearTraits[parts[i]].ear;
            }
            if(BearTraits[parts[i]].head != 55){
                Btraits.head = BearTraits[parts[i]].head;
            }
            if(BearTraits[parts[i]].body != 55){
                Btraits.body = BearTraits[parts[i]].body;
            }
            if(BearTraits[parts[i]].rarm != 55){
                Btraits.rarm = BearTraits[parts[i]].rarm;
            }
            if(BearTraits[parts[i]].larm != 55){
                Btraits.larm = BearTraits[parts[i]].larm;
            }
            if(BearTraits[parts[i]].rleg != 55){
                Btraits.rleg = BearTraits[parts[i]].rleg;
            }
            if(BearTraits[parts[i]].lleg != 55){
                Btraits.lleg = BearTraits[parts[i]].lleg;
            }
            _burn(parts[i]);
        }
        _tokenIds.increment();
        uint256 newNftTokenId = _tokenIds.current();
        bHash[newNftTokenId] = uint256(
            keccak256(abi.encodePacked(address(msg.sender), newNftTokenId,block.timestamp,blockhash(block.number-1),gasleft()))
        );
        BearTraits[newNftTokenId] = Btraits;
        _mint(msg.sender, newNftTokenId);
    }
    

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "no exist");
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"',
                    uint2str(_tokenId),
                    '","image_data":"',
                    baseImg(_tokenId),
                    '"}'
                )
            );
    }


    function baseImg(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        uint256 _ear  = BearTraits[_tokenId].ear;
        uint256 _head = BearTraits[_tokenId].head;
        uint256 _body = BearTraits[_tokenId].body;
        uint256 _rarm = BearTraits[_tokenId].rarm;
        uint256 _larm = BearTraits[_tokenId].larm;
        uint256 _rleg = BearTraits[_tokenId].rleg;
        uint256 _lleg = BearTraits[_tokenId].lleg;
        
        return
            string(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' width='600px' height='612px'>",
                    "<image width='600' height='612' href='https://bearsbehindbars.eth.link/background.png'/>",
                    "<image width='600' height='612' href='https://bearsbehindbars.eth.link/ears/",
                    uint2str(_ear),
                    ".png'/>",
                    "<image width='600' height='612' href='https://bearsbehindbars.eth.link/heads/",
                    uint2str(_head),
                    ".png'/>",
                    "<image width='600' height='612' href='https://bearsbehindbars.eth.link/bodies/",
                    uint2str(_body),
                    ".png'/>",
                    "<image width='600' height='612' href='https://bearsbehindbars.eth.link/rightArms/",
                    uint2str(_rarm),
                    ".png'/>",
                    "<image width='600' height='612' href='https://bearsbehindbars.eth.link/leftArms/",
                    uint2str(_larm),
                    ".png'/>",
                    "<image width='600' height='612' href='https://bearsbehindbars.eth.link/rightLegs/",
                    uint2str(_rleg),
                    ".png'/>",
                    "<image width='600' height='612' href='https://bearsbehindbars.eth.link/leftLegs/",
                    uint2str(_lleg),
                    ".png'/>",
                    "<image width='600' height='612' href='https://bearsbehindbars.eth.link/bars.png'/>",
                    "</svg>"
                )
            );
    }
    
    function randomizer(uint256 _tokenId) internal {
        uint256 rand0 = bHash[_tokenId] % 100;
        uint256 HMx;
        uint256 LAMx;
        uint256 RAMx;
        uint256 rand1 = rand0>50?rand0%8:rand0%2;
        uint256 randy = uint256(keccak256(abi.encodePacked(msg.sender,block.timestamp,_tokenId,blockhash(block.number-rand1+1),gasleft())));
        if(rand0>80){
            LAMx = 33;
            RAMx = 22;
            HMx  = 11;
        }
        if(rand0>94){
            LAMx = 33;
            RAMx = 22;
            HMx  = 22;
        }else{
            LAMx = 11;
            RAMx = 11;
            HMx  = 11;
        }
        
        Btraits.ear =  (randy/33)%11;
        Btraits.head = (randy/77)%HMx;
        Btraits.body = (randy/133)%33;
        Btraits.rarm = (randy/111)%RAMx;
        Btraits.larm = (randy/222)%LAMx;
        Btraits.rleg = (randy/333)%11;
        Btraits.lleg = (randy/444)%11;
        BearTraits[_tokenId] = Btraits;
    }
    
    function randomPart(uint256 _tokenId, uint256 part) internal {
        uint256 rand0 = bHash[_tokenId] % 100;
        uint256 rand1 = rand0>50?rand0%8:rand0%2;
        uint256 randy = uint256(keccak256(abi.encodePacked(msg.sender,block.timestamp,_tokenId,part,blockhash(block.number-rand1+1),gasleft())));
        uint256 RAMx;
        uint256 LAMx;
        uint256 HMx;
        if(rand0>80){
            RAMx = 22;
            LAMx = 33;
            HMx  = 11;
        }
        if(rand0>94){
            LAMx = 33;
            RAMx = 22;
            HMx  = 22;
        }else{
            RAMx = 11;
            LAMx = 11;
            HMx  = 11;
        }
        
        if(part == 0){
            Btraits.rarm = randy%RAMx;
            Btraits.larm = 55;
            Btraits.head = 55;
            Btraits.ear =  55;
            Btraits.body = 55;
            Btraits.rleg = 55;
            Btraits.lleg = 55;
        }
        if(part == 1){
            Btraits.rarm = 55;
            Btraits.larm = randy%LAMx;
            Btraits.ear =  55;
            Btraits.head = 55;
            Btraits.body = 55;
            Btraits.rleg = 55;
            Btraits.lleg = 55;
        }
        if(part == 2){
            Btraits.rarm = 55;
            Btraits.larm = 55;
            Btraits.head = randy%HMx;
            Btraits.ear =  55;
            Btraits.body = 55;
            Btraits.rleg = 55;
            Btraits.lleg = 55;
        }
        if(part == 3){
            Btraits.rarm = 55;
            Btraits.larm = 55;
            Btraits.head = 55;
            Btraits.ear =  randy%11;
            Btraits.body = 55;
            Btraits.rleg = 55;
            Btraits.lleg = 55;
        }
        if(part == 4){
            Btraits.rarm = 55;
            Btraits.larm = 55;
            Btraits.head = 55;
            Btraits.ear =  55;
            Btraits.body = randy%33;
            Btraits.rleg = 55;
            Btraits.lleg = 55;
        }
        if(part == 5){
            Btraits.rarm = 55;
            Btraits.larm = 55;
            Btraits.head = 55;
            Btraits.ear =  55;
            Btraits.body = 55;
            Btraits.rleg = randy%11;
            Btraits.lleg = 55;
        }
        if(part == 6){
            Btraits.rarm = 55;
            Btraits.larm = 55;
            Btraits.head = 55;
            Btraits.ear =  55;
            Btraits.body = 55;
            Btraits.rleg = 55;
            Btraits.lleg = randy%11;
        }
        
        BearTraits[_tokenId] = Btraits;
    }
    

    function withdraw(uint256 amount) external payable onlyAdmin {
        require(amount <= address(this).balance);
        admin.transfer(amount);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    

    /// @notice Returns the contract URI function. Used on OpenSea to get details
    //          about a contract (owner, royalties etc...)
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Helper for OpenSea gas-less trading
    /// @dev Allows to check if `operator` is owner's OpenSea proxy
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return
            // we have a proxy registry address
            address(proxyRegistry) != address(0) &&
            // current operator is owner's proxy address
            address(proxyRegistry.proxies(owner)) == operator;
    }

    /// @dev Internal function to set the _contractURI
    /// @param contractURI_ the new contract uri
    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the Proxy of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function setOpenSeaRegistry(address proxyRegistryAddress)
        external
        onlyAdmin
    {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}