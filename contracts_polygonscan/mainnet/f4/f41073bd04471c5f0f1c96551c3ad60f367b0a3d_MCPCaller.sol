/**
 *Submitted for verification at polygonscan.com on 2021-07-27
*/

pragma solidity 0.5.9;

library Strings {
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    function bytes32ToString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function bytesToUInt(bytes32 b) internal pure returns (uint256){
        uint256 number;
        for (uint i = 0; i < b.length; i++) {
            number = number + uint256(uint8(b[i])) * (2 ** (8 * (b.length - (i + 1))));
        }
        return number;
    }

}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function getApproved(uint256 _tokenId) external view returns (address);

    function balanceOf(address _owner) external view returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function baseTokenURI() external view returns (string memory);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;


    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


}

contract Ownable {
    address public owner;


    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Transfer to null address is not allowed");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

}

contract Beneficiary is Ownable {

    function setBeneficiary(address payable _beneficiary) public onlyOwner { }

    function withdrawal(uint256 value) public onlyOwner { }

    function withdrawalAll() public onlyOwner { }

    event BeneficiaryPayout(uint256 value);
}


contract Manageable is Beneficiary {
    uint DEFAULT_GAME_PERIOD = 1 days;

    uint256 DECIMALS = 10e8;

    bool maintenance = false;

    mapping(address => bool) public managers;

    modifier onlyManager() {
        require(managers[msg.sender] || msg.sender == address(this), "Only managers allowed");
        _;
    }

    modifier notOnMaintenance() {
        require(!maintenance);
        _;
    }

    bool saleOpen = false;

    modifier onlyOnSale() {
        require(saleOpen);
        _;
    }

    constructor() public {
        managers[msg.sender] = true;
    }

    function setMaintenanceStatus(bool _status) public onlyManager { }

    function setManager(address _manager) public onlyOwner { }

    function deleteManager(address _manager) public onlyOwner { }

    function setGameDefaultPeriod(uint _period) public onlyManager { }

    event Maintenance(bool status);
    event FailedPayout(address to, uint256 value);

}


contract LockableToken is Manageable {
    mapping(uint256 => bool) public locks;

    modifier onlyNotLocked(uint256 _tokenId) {
        require(!locks[_tokenId]);
        _;
    }

    function isLocked(uint256 _tokenId) public view returns (bool) { }

    function lockToken(uint256 _tokenId) public onlyManager { }

    function unlockToken(uint256 _tokenId) public onlyManager { }

    function _lockToken(uint256 _tokenId) internal { }

    function _unlockToken(uint256 _tokenId) internal { }

}

contract ERC721 is Manageable, LockableToken, IERC721, IERC165 {
    using Strings for string;
    address public market;


    mapping(address => uint256) public balances;
    mapping(uint256 => address) public approved;
    mapping(address => mapping(address => bool)) private operators;
    mapping(uint256 => address) private tokenOwner;

    uint256 public totalSupply = 0;

    string private _tokenURI = "";

    string private tokenName = '';
    string private tokenSymbol = '';

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(msg.sender == tokenOwner[_tokenId]);
        _;
    }

    function setName(string memory _name) public onlyManager { }

    function setSymbol(string memory _symbol) public onlyManager { }

    function name() external view returns (string memory _name) { }

    function symbol() external view returns (string memory _symbol) { }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) { }

    function setBaseTokenURI(string memory _newTokenURI) public onlyManager { }

    function setMarketContract(address _market) public onlyManager { }

    function ownerOf(uint256 _tokenId) public view returns (address) { }

    function transferFrom(address _from, address _to, uint256 _tokenId) public onlyNotLocked(_tokenId) { }

    function approve(address _approved, uint256 _tokenId) public onlyNotLocked(_tokenId) { }

    function setApprovalForAll(address _operator, bool _approved) public { }

    function setApprovalForAllSender(address payable _sender, address _operator, bool _approved) public onlyManager { }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) { }

    function getApproved(uint256 _tokenId) public view returns (address) { }

    function balanceOf(address _owner) public view returns (uint256) { }

    function transfer(address _from, address _to, uint256 _tokenId) public onlyTokenOwner(_tokenId) onlyNotLocked(_tokenId) { }

    function transferSender(address payable _sender, address _from, address _to, uint256 _tokenId) public onlyManager onlyNotLocked(_tokenId) { }

    function baseTokenURI() public view returns (string memory) { }

    function tokenURI(uint256 _tokenId) external view returns (string memory) { }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable { }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable { }

    function burn(uint256 _tokenId) public onlyManager { }


    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

contract ResourcesToken is Manageable, ERC721 {

    struct ResourceBatch {
        uint8 kind;
        uint256 amount;
        bool presale;
    }

    mapping(uint => ResourceBatch) public tokens;

    uint256[3] public presaleAmount;

    function mintPresalePack(address _owner, uint8 _kind, uint8 _size) public onlyManager { }

    function mintPack(address _owner, uint8 _kind, uint256 _amount) public onlyManager { }

    function batchMintPack(address[] memory _owner, uint[] memory _tokenId, uint8[] memory _kind, uint256[] memory _amount, bool[] memory _isPresale) public onlyManager { }
}

contract MCPCaller is Ownable
{
    ResourcesToken rt;
    
    function SetResourceAddress(address _t) public onlyOwner {
        rt = ResourcesToken(_t);
    }

    function getAmount(uint256 _tokenId) public view returns (uint256 _amount){
        (uint8 kind, uint256 amount, bool presale) = rt.tokens(_tokenId);
        return amount;
    }

    function enumAllPacksOfType(uint8 kind, uint256 from, uint256 to) public view returns (uint256 _amount){
        if(to == 0)
            to = rt.totalSupply();

        uint256 amount = 0;

        for(uint256 i = from; i < to; i++){
            if(rt.ownerOf(i) != address(0)){ 
                (uint8 tokenKind, uint256 tokenAmount, bool presale) = rt.tokens(i);

                if(kind == tokenKind){
                    amount += tokenAmount;
                }
            }
        }

        return amount;
    }
}