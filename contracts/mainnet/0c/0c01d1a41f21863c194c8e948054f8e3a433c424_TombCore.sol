pragma solidity ^0.4.13;

contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TombAccessControl {
    address public ownerAddress;

    modifier onlyOwner() {
        require(msg.sender == ownerAddress);
        _;
    }

    function withdrawBalance() external onlyOwner {
        address contractAddress = this;
        ownerAddress.transfer(contractAddress.balance);
    }
}

contract TombBase is TombAccessControl {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    struct Tomb {
        // The timestamp from the block when this tomb came into existence.
        address sculptor;
        string data;
    }

    // An array containing all existing tomb
    Tomb[] tombs;
    mapping (uint => address) public tombToOwner;
    mapping (address => uint) ownerTombCount;
    mapping (uint => address) tombApprovals;

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        tombToOwner[_tokenId] = _to;
        ownerTombCount[_to] = ownerTombCount[_to].add(1);
        if (_from != address(0)) {
            ownerTombCount[_from] = ownerTombCount[_from].sub(1);
            delete tombApprovals[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }

    function _createTombWithData(address _owner, string givenData) internal returns (uint) {
        Tomb memory _tomb = Tomb({
            data: givenData,
            sculptor: _owner
        });
        uint256 newTombId = (tombs.push(_tomb)).sub(1);
        _transfer(0, _owner, newTombId);
        return newTombId;
    }

    function getTombByOwner(address _owner) external view returns(uint[]) {
        uint[] memory result = new uint[](ownerTombCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < tombs.length; i++) {
            if (tombToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getAllTombs() external view returns(uint[]) {
        uint[] memory result = new uint[](tombs.length);
        for (uint i = 0; i < tombs.length; i++) {
            result[i] = i;
        }
        return result;
    }

    function getTombDetail(uint index) external view returns(address, address, string) {
        return (tombToOwner[index], tombs[index].sculptor, tombs[index].data);
    }
}

contract TombOwnership is ERC721, TombBase {
    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public name = "EtherFen";
    string public symbol = "ETF";

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function totalSupply() public view returns (uint) {
        return tombs.length;
    }

    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ownerTombCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return tombToOwner[_tokenId];
    }

    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        tombApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public
    {
        require(_to != address(0));
        require(_to != address(this));
        require(tombApprovals[_tokenId] == msg.sender);
        require(tombToOwner[_tokenId] == _from);
        _transfer(_from, _to, _tokenId);
    }

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(tombToOwner[_tokenId] == msg.sender);
        _;
    }
}

contract TombAction is TombOwnership {
    uint256 currentPrice;

    function buyAndCrave(string data) payable external {
        if (msg.value < currentPrice) revert();
        _createTombWithData(msg.sender, data);
    }
 
    function changePrice(uint256 newPrice) external onlyOwner {
        //gwei to ether
        uint256 gweiUnit = 1000000000;
        currentPrice = newPrice.mul(gweiUnit);
    }

    function getPrice() external view returns(uint256) {
        return currentPrice;
    }
}

contract TombCore is TombAction {
    function TombCore() public {
        ownerAddress = msg.sender;
        currentPrice = 0.02 ether;
    }
}