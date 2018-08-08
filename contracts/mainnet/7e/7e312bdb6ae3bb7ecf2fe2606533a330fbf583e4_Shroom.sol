pragma solidity ^0.4.21;

contract TokenInterface {
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Kitty {
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function getKitty(uint256 _id) external view returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes
    );
}

contract Ownable {
    address owner;
    Kitty kitty;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function () external payable {
        owner.transfer(address(this).balance);
    }

    function getTokens(address _contract, uint256 _amount) external {
        TokenInterface(_contract).transfer(owner, _amount);
    }

    function setKitty(address _contract) external onlyOwner {
        kitty = Kitty(_contract);
    }
}

contract Token {
    string public constant name = "Crypto Shrooms"; // ERC-721
    string public constant symbol = "SHRM"; // ERC-721
    uint256[] public tokenIdToDna;
    mapping (address => uint256) public balanceOf; // ERC-721
    mapping (uint256 => address) public tokenIdToApproved;
    mapping (uint256 => address) tokenIdToOwner;

    event Transfer(address from, address to, uint256 tokenId); // ERC-721
    event Approval(address owner, address approved, uint256 tokenId); // ERC-721

    constructor() public {
        tokenIdToDna.push(0);
    }

    // ERC-721
    function totalSupply() public view returns(uint256) {
        return tokenIdToDna.length - 1;
    }

    // ERC-721
    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = tokenIdToOwner[_tokenId];
        require(owner != address(0));
    }

    // ERC-721
    function approve(address _to, uint256 _tokenId) external {
        require(msg.sender != address(0));
        require(tokenIdToOwner[_tokenId] == msg.sender);
        tokenIdToApproved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    // ERC-721
    function transfer(address _to, uint256 _tokenId) external {
        require(msg.sender != address(0));
        require(tokenIdToOwner[_tokenId] == msg.sender);
        require(_to != address(0));
        balanceOf[msg.sender]--;
        tokenIdToOwner[_tokenId] = _to;
        balanceOf[_to]++;
        delete tokenIdToApproved[_tokenId];
        emit Transfer(msg.sender, _to, _tokenId);
    }

    // ERC-721
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(msg.sender != address(0));
        require(tokenIdToApproved[_tokenId] == msg.sender);
        require(_from != address(0));
        require(tokenIdToOwner[_tokenId] == _from);
        require(_to != address(0));
        balanceOf[_from]--;
        tokenIdToOwner[_tokenId] = _to;
        balanceOf[_to]++;
        delete tokenIdToApproved[_tokenId];
        emit Transfer(_from, _to, _tokenId);
    }

    // ERC-721
    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds) {
        uint256 tokenCount = balanceOf[_owner];
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = tokenIdToDna.length - 1;
            uint256 resultIndex = 0;
            for (uint i = 1; i <= total; i++) {
                if (tokenIdToOwner[i] == _owner) {
                    result[resultIndex] = i;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function _create(uint256 _dna, address _owner) internal {
        uint256 tokenId = tokenIdToDna.push(_dna) - 1;
        tokenIdToOwner[tokenId] = _owner;
        balanceOf[_owner]++;
        emit Transfer(address(this), _owner, tokenId);
    }

    function _move(uint256 _tokenId, address _from, address _to) internal {
        balanceOf[_from]--;
        tokenIdToOwner[_tokenId] = _to;
        balanceOf[_to]++;
        delete tokenIdToApproved[_tokenId];
        emit Transfer(_from, _to, _tokenId);
    }
}

contract Shroom is Ownable, Token {
    mapping (uint256 => bool) public kittyIdToDead;
    mapping (uint256 => uint256) shroomIdToPrice;
    uint256 salt;

    event SaleCreated(uint256 shroomId, uint256 price);
    event SaleSuccessful(uint256 shroomId);
    event SaleCancelled(uint256 shroomId);

    constructor() public {
        salt = now;
    }

    function getNewShroom(uint256 _kittyId) external {
        require(msg.sender != address(0));
        require(!kittyIdToDead[_kittyId]);
        require(kitty.ownerOf(_kittyId) == msg.sender);
        uint256 dna;
        (,,,,,,,,,dna) = kitty.getKitty(_kittyId);
        require(dna != 0);
        salt++;
        dna = uint256(keccak256(dna + salt + now));
        kittyIdToDead[_kittyId] = true;
        _create(dna, msg.sender);
    }

    function createSale(uint256 _shroomId, uint256 _price) external {
        address currentOwner = tokenIdToOwner[_shroomId];
        require(currentOwner != address(0));
        require(currentOwner == msg.sender);
        shroomIdToPrice[_shroomId] = _price;
        emit SaleCreated(_shroomId, _price);
    }

    function buy(uint256 _shroomId) external payable {
        address newOwner = msg.sender;
        require(newOwner != address(0));
        address currentOwner = tokenIdToOwner[_shroomId];
        require(currentOwner != address(0));
        uint256 price = shroomIdToPrice[_shroomId];
        require(price > 0);
        require(msg.value >= price);
        delete shroomIdToPrice[_shroomId];
        currentOwner.transfer(price);
        emit SaleSuccessful(_shroomId);
        _move(_shroomId, currentOwner, newOwner);
    }

    function cancelSale(uint256 _shroomId) external {
        address currentOwner = tokenIdToOwner[_shroomId];
        require(currentOwner != address(0));
        require(currentOwner == msg.sender);
        require(shroomIdToPrice[_shroomId] > 0);
        delete shroomIdToPrice[_shroomId];
        emit SaleCancelled(_shroomId);
    }

    function getPrice(uint256 _shroomId) external view returns (uint256) {
        uint256 price = shroomIdToPrice[_shroomId];
        require(price > 0);
        return price;
    }
}