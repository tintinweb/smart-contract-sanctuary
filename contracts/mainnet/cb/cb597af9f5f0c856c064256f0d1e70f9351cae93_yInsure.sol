pragma solidity ^0.5.0;

contract Context {

    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => Counters.Counter) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        _ownedTokens[from].length--;
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
    string private _name;
    string private _symbol;
    string private _baseURI;
    mapping(uint256 => string) private _tokenURIs;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        _notEntered = true;
    }
    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

interface Pool1  {
    function changeDependentContractAddress() external;
    function makeCoverBegin(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] calldata coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
        payable;
    function makeCoverUsingCA(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] calldata coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external;
    function getWei(uint amount) external view returns(uint);
    function sellNXMTokens(uint _amount) external  returns (bool);
}

contract INXMMaster {
    address public tokenAddress;
    address public owner;
    uint public pauseTime;
    function masterInitialized() external view returns(bool);
    function isPause() external view returns(bool check);
    function isMember(address _add) external view returns(bool);
    function getLatestAddress(bytes2 _contractName) external view returns(address payable contractAddress);
}

interface DSValue {
    function peek() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
}

interface PoolData {

    struct ApiId {
        bytes4 typeOf;
        bytes4 currency;
        uint id;
        uint64 dateAdd;
        uint64 dateUpd;
    }

    struct CurrencyAssets {
        address currAddress;
        uint baseMin;
        uint varMin;
    }

    struct InvestmentAssets {
        address currAddress;
        bool status;
        uint64 minHoldingPercX100;
        uint64 maxHoldingPercX100;
        uint8 decimals;
    }

    struct IARankDetails {
        bytes4 maxIACurr;
        uint64 maxRate;
        bytes4 minIACurr;
        uint64 minRate;
    }

    struct McrData {
        uint mcrPercx100;
        uint mcrEther;
        uint vFull; //Pool funds
        uint64 date;
    }

    function setCapReached(uint val) external;
    function getInvestmentAssetDecimals(bytes4 curr) external returns(uint8 decimal);
    function getCurrencyAssetAddress(bytes4 curr) external view returns(address);
    function getInvestmentAssetAddress(bytes4 curr) external view returns(address);
    function getInvestmentAssetStatus(bytes4 curr) external view returns(bool status);

}

interface QuotationData {

    enum HCIDStatus { NA, kycPending, kycPass, kycFailedOrRefunded, kycPassNoCover }
    enum CoverStatus { Active, ClaimAccepted, ClaimDenied, CoverExpired, ClaimSubmitted, Requested }

    struct Cover {
        address payable memberAddress;
        bytes4 currencyCode;
        uint sumAssured;
        uint16 coverPeriod;
        uint validUntil;
        address scAddress;
        uint premiumNXM;
    }

    struct HoldCover {
        uint holdCoverId;
        address payable userAddress;
        address scAddress;
        bytes4 coverCurr;
        uint[] coverDetails;
        uint16 coverPeriod;
    }

    function getCoverLength() external returns(uint len);
    function getAuthQuoteEngine() external returns(address _add);
    function getAllCoversOfUser(address _add) external returns(uint[] memory allCover);
    function getUserCoverLength(address _add) external returns(uint len);
    function getCoverStatusNo(uint _cid) external returns(uint8);
    function getCoverPeriod(uint _cid) external returns(uint32 cp);
    function getCoverSumAssured(uint _cid) external returns(uint sa);
    function getCurrencyOfCover(uint _cid) external returns(bytes4 curr);
    function getValidityOfCover(uint _cid) external returns(uint date);
    function getscAddressOfCover(uint _cid) external returns(uint, address);
    function getCoverMemberAddress(uint _cid) external returns(address payable _add);
    function getCoverPremiumNXM(uint _cid) external returns(uint _premiumNXM);
    function getCoverDetailsByCoverID1(
        uint _cid
    )
        external
        returns (
            uint cid,
            address _memberAddress,
            address _scAddress,
            bytes4 _currencyCode,
            uint _sumAssured,
            uint premiumNXM
        );
    function getCoverDetailsByCoverID2(
        uint _cid
    )
        external
        view
        returns (
            uint cid,
            uint8 status,
            uint sumAssured,
            uint16 coverPeriod,
            uint validUntil
        );
    function getHoldedCoverDetailsByID1(
        uint _hcid
    )
        external
        view
        returns (
            uint hcid,
            address scAddress,
            bytes4 coverCurr,
            uint16 coverPeriod
        );
    function getUserHoldedCoverLength(address _add) external returns (uint);
    function getUserHoldedCoverByIndex(address _add, uint index) external returns (uint);
    function getHoldedCoverDetailsByID2(
        uint _hcid
    )
        external
        returns (
            uint hcid,
            address payable memberAddress,
            uint[] memory coverDetails
        );
    function getTotalSumAssuredSC(address _add, bytes4 _curr) external returns(uint amount);

}

contract TokenData {
    function lockTokenTimeAfterCoverExp() external returns (uint);
}

interface Claims {
    function getClaimbyIndex(uint _claimId) external view returns (
        uint claimId,
        uint status,
        int8 finalVerdict,
        address claimOwner,
        uint coverId
    );
    function submitClaim(uint coverId) external;
}

contract ClaimsData {
    function actualClaimLength() external view returns(uint);
}

interface NXMToken {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);

}

interface MemberRoles {
    function switchMembership(address) external;
}

contract yInsure is
    ERC721Full("yInsureNFT", "yNFT"),
    Ownable,
    ReentrancyGuard {
    
    struct Token {
        uint expirationTimestamp;
        bytes4 coverCurrency;
        uint coverAmount;
        uint coverPrice;
        uint coverPriceNXM;
        uint expireTime;
        uint generationTime;
        uint coverId;
        bool claimInProgress;
        uint claimId;
    }
    
    event ClaimRedeemed (
        address receiver,
        uint value,
        bytes4 currency
    );
    
    using SafeMath for uint;

    INXMMaster constant public nxMaster = INXMMaster(0x01BFd82675DBCc7762C84019cA518e701C0cD07e);
    
    enum CoverStatus {
        Active,
        ClaimAccepted,
        ClaimDenied,
        CoverExpired,
        ClaimSubmitted,
        Requested
    }
    
    enum ClaimStatus {
        PendingClaimAssessorVote, // 0
        PendingClaimAssessorVoteDenied, // 1
        PendingClaimAssessorVoteThresholdNotReachedAccept, // 2
        PendingClaimAssessorVoteThresholdNotReachedDeny, // 3
        PendingClaimAssessorConsensusNotReachedAccept, // 4
        PendingClaimAssessorConsensusNotReachedDeny, // 5
        FinalClaimAssessorVoteDenied, // 6
        FinalClaimAssessorVoteAccepted, // 7
        FinalClaimAssessorVoteDeniedMVAccepted, // 8
        FinalClaimAssessorVoteDeniedMVDenied, // 9
        FinalClaimAssessorVotAcceptedMVNoDecision, // 10
        FinalClaimAssessorVoteDeniedMVNoDecision, // 11
        ClaimAcceptedPayoutPending, // 12
        ClaimAcceptedNoPayout, // 13
        ClaimAcceptedPayoutDone // 14
    }
    
    function _buyCover(
        address coveredContractAddress,
        bytes4 coverCurrency,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal returns (uint coverId) {
    
        uint coverPrice = coverDetails[1];
        Pool1 pool1 = Pool1(nxMaster.getLatestAddress("P1"));
        if (coverCurrency == "ETH") {
            pool1.makeCoverBegin.value(coverPrice)(coveredContractAddress, coverCurrency, coverDetails, coverPeriod, _v, _r, _s);
        } else {
            address payable pool1Address = address(uint160(address(pool1)));
            PoolData poolData = PoolData(nxMaster.getLatestAddress("PD"));
            IERC20 erc20 = IERC20(poolData.getCurrencyAssetAddress(coverCurrency));
            erc20.approve(pool1Address, coverPrice);
            pool1.makeCoverUsingCA(coveredContractAddress, coverCurrency, coverDetails, coverPeriod, _v, _r, _s);
        }
    
        QuotationData quotationData = QuotationData(nxMaster.getLatestAddress("QD"));
        // *assumes* the newly created claim is appended at the end of the list covers
        coverId = quotationData.getCoverLength().sub(1);
    }
    
    function _submitClaim(uint coverId) internal returns (uint) {
        Claims claims = Claims(nxMaster.getLatestAddress("CL"));
        claims.submitClaim(coverId);
    
        ClaimsData claimsData = ClaimsData(nxMaster.getLatestAddress("CD"));
        uint claimId = claimsData.actualClaimLength() - 1;
        return claimId;
    }
    
    function getMemberRoles() public view returns (address) {
        return nxMaster.getLatestAddress("MR");
    }
    
    function getCover(
        uint coverId
    ) internal view returns (
        uint cid,
        uint8 status,
        uint sumAssured,
        uint16 coverPeriod,
        uint validUntil
    ) {
        QuotationData quotationData = QuotationData(nxMaster.getLatestAddress("QD"));
        return quotationData.getCoverDetailsByCoverID2(coverId);
    }
    
    function _sellNXMTokens(uint amount) internal returns (uint ethValue) {
        address payable pool1Address = nxMaster.getLatestAddress("P1");
        Pool1 p1 = Pool1(pool1Address);
    
        NXMToken nxmToken = NXMToken(nxMaster.tokenAddress());
    
        ethValue = p1.getWei(amount);
        nxmToken.approve(pool1Address, amount);
        p1.sellNXMTokens(amount);
    }
    
    function _getCurrencyAssetAddress(bytes4 currency) internal view returns (address) {
        PoolData pd = PoolData(nxMaster.getLatestAddress("PD"));
        return pd.getCurrencyAssetAddress(currency);
    }
    
    function _getLockTokenTimeAfterCoverExpiry() internal returns (uint) {
        TokenData tokenData = TokenData(nxMaster.getLatestAddress("TD"));
        return tokenData.lockTokenTimeAfterCoverExp();
    }
    
    function _getTokenAddress() internal view returns (address) {
        return nxMaster.tokenAddress();
    }
    
    function _payoutIsCompleted(uint claimId) internal view returns (bool) {
        uint256 status;
        Claims claims = Claims(nxMaster.getLatestAddress("CL"));
        (, status, , , ) = claims.getClaimbyIndex(claimId);
        return status == uint(ClaimStatus.FinalClaimAssessorVoteAccepted)
            || status == uint(ClaimStatus.ClaimAcceptedPayoutDone);
    }
  
    bytes4 internal constant ethCurrency = "ETH";
    
    uint public distributorFeePercentage;
    uint256 internal issuedTokensCount;
    mapping(uint256 => Token) public tokens;
    
    mapping(bytes4 => uint) public withdrawableTokens;
    
    constructor(uint _distributorFeePercentage) public {
        distributorFeePercentage = _distributorFeePercentage;
    }
    
    function switchMembership(address _newMembership) external onlyOwner {
        NXMToken nxmToken = NXMToken(nxMaster.tokenAddress());
        nxmToken.approve(getMemberRoles(),uint(-1));
        MemberRoles(getMemberRoles()).switchMembership(_newMembership);
    }
    
    // Arguments to be passed as coverDetails, from the quote api:
    //    coverDetails[0] = coverAmount;
    //    coverDetails[1] = coverPrice;
    //    coverDetails[2] = coverPriceNXM;
    //    coverDetails[3] = expireTime;
    //    coverDetails[4] = generationTime;
    function buyCover(
        address coveredContractAddress,
        bytes4 coverCurrency,
        uint[] calldata coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
    
        uint coverPrice = coverDetails[1];
        uint requiredValue = distributorFeePercentage.mul(coverPrice).div(100).add(coverPrice);
        if (coverCurrency == "ETH") {
            require(msg.value == requiredValue, "Incorrect value sent");
        } else {
            IERC20 erc20 = IERC20(_getCurrencyAssetAddress(coverCurrency));
            require(erc20.transferFrom(msg.sender, address(this), requiredValue), "Transfer failed");
        }
        
        uint coverId = _buyCover(coveredContractAddress, coverCurrency, coverDetails, coverPeriod, _v, _r, _s);
        withdrawableTokens[coverCurrency] = withdrawableTokens[coverCurrency].add(requiredValue.sub(coverPrice));
        
        // mint token
        uint256 nextTokenId = issuedTokensCount++;
        uint expirationTimestamp = block.timestamp + _getLockTokenTimeAfterCoverExpiry() + coverPeriod * 1 days;
        tokens[nextTokenId] = Token(expirationTimestamp,
          coverCurrency,
          coverDetails[0],
          coverDetails[1],
          coverDetails[2],
          coverDetails[3],
          coverDetails[4],
          coverId, false, 0);
        _mint(msg.sender, nextTokenId);
    }
    
    function submitClaim(uint256 tokenId) external onlyTokenApprovedOrOwner(tokenId) {
    
        if (tokens[tokenId].claimInProgress) {
            uint8 coverStatus;
            (, coverStatus, , , ) = getCover(tokens[tokenId].coverId);
            require(coverStatus == uint8(CoverStatus.ClaimDenied),
            "Can submit another claim only if the previous one was denied.");
        }
        require(tokens[tokenId].expirationTimestamp > block.timestamp, "Token is expired");
        
        uint claimId = _submitClaim(tokens[tokenId].coverId);
        
        tokens[tokenId].claimInProgress = true;
        tokens[tokenId].claimId = claimId;
    }
    
    function redeemClaim(uint256 tokenId) public onlyTokenApprovedOrOwner(tokenId)  nonReentrant {
        require(tokens[tokenId].claimInProgress, "No claim is in progress");
        uint8 coverStatus;
        uint sumAssured;
        (, coverStatus, sumAssured, , ) = getCover(tokens[tokenId].coverId);
        
        require(coverStatus == uint8(CoverStatus.ClaimAccepted), "Claim is not accepted");
        require(_payoutIsCompleted(tokens[tokenId].coverId), "Claim accepted but payout not completed");
        
        _burn(tokenId);
        _sendAssuredSum(tokens[tokenId].coverCurrency, sumAssured);
        emit ClaimRedeemed(msg.sender, sumAssured, tokens[tokenId].coverCurrency);
    }
    
    function _sendAssuredSum(bytes4 coverCurrency, uint sumAssured) internal {
        if (coverCurrency == ethCurrency) {
            msg.sender.transfer(sumAssured);
        } else {
            IERC20 erc20 = IERC20(_getCurrencyAssetAddress(coverCurrency));
            require(erc20.transfer(msg.sender, sumAssured), "Transfer failed");
        }
    }
    
    function getCoverStatus(uint256 tokenId) external view returns (uint8 coverStatus, bool payoutCompleted) {
        (, coverStatus, , , ) = getCover(tokens[tokenId].coverId);
        payoutCompleted = _payoutIsCompleted(tokenId);
    }
    
    function nxmTokenApprove(address _spender, uint256 _value) public onlyOwner {
        IERC20 nxmToken = IERC20(_getTokenAddress());
        nxmToken.approve(_spender, _value);
    }
    
    function withdrawEther(address payable _recipient, uint256 _amount) external onlyOwner nonReentrant {
        require(withdrawableTokens[ethCurrency] >= _amount, "Not enough ETH");
        withdrawableTokens[ethCurrency] = withdrawableTokens[ethCurrency].sub(_amount);
        _recipient.transfer(_amount);
    }
    
    function withdrawTokens(address payable _recipient, uint256 _amount, bytes4 _currency) external onlyOwner nonReentrant {
        require(withdrawableTokens[_currency] >= _amount, "Not enough tokens");
        withdrawableTokens[_currency] = withdrawableTokens[_currency].sub(_amount);
    
        IERC20 erc20 = IERC20(_getCurrencyAssetAddress(_currency));
        require(erc20.transfer(_recipient, _amount), "Transfer failed");
    }
    
    function sellNXMTokens(uint amount) external onlyOwner {
        uint ethValue = _sellNXMTokens(amount);
        withdrawableTokens[ethCurrency] = withdrawableTokens[ethCurrency].add(ethValue);
    }
    
    modifier onlyTokenApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        _;
    }
    
    function () payable external {
    }
}