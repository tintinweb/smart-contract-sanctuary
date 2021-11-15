pragma solidity 0.6.12;


interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        Unpause();
    }
}

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public CREATE_AUCTION_HASH;
    bytes32 public BID_AUCTION_HASH;
    bytes32 public CANCEL_AUCTION_HASH;
    mapping(address => uint256) public nonces;


    constructor() public {
        NAME = "KawaiiMarketPlaceBNB";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );

        CREATE_AUCTION_HASH = keccak256("Data(uint256 _tokenId,uint256 _amount,uint256 _startingPrice,uint256 _endingPrice,uint256 _duration,uint256 nonce)");
        BID_AUCTION_HASH = keccak256("Data(address _nftAddress,uint256 _tokenId,uint256 _tokenIndex,uint256 _amount,uint256 nonce)");
        CANCEL_AUCTION_HASH = keccak256("Data(address _nftAddress,uint256 _tokenId,uint256 _tokenIndex,uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == sender, "Invalid nonce");
    }
}


contract KawaiiMarketPlaceBNB is Pausable, SignData {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    enum Status{AUCTION, CLOSE, CANCEL}
    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 amount;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        uint64 startedAt;
        Status status;
    }

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;
    IBEP20 public bep20Token;
    mapping(address => mapping(uint256 => Auction[])) public auctions;

    event AuctionCreated(address _nftAddress, uint256 indexed _tokenId, uint256 indexed _amount, uint256 indexed _indexAuction, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller);
    event AuctionSuccessful(address indexed _nftAddress, uint256 indexed _tokenId, uint256 indexed _indexAuction, uint256 _totalPrice, address _winner);
    event AuctionCancelled(address indexed _nftAddress, uint256 indexed _tokenId, uint256 indexed _indexAuction);
    event ChangeOwnerCut(uint256 ownerCut);
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

    constructor (uint256 _ownerCut) public {
        require(_ownerCut <= 10000);
        ownerCut = _ownerCut;
    }

    function changeOwnerCut(uint256 _ownerCut) external onlyOwner {
        ownerCut = _ownerCut;
        emit ChangeOwnerCut(_ownerCut);
    }

    function getAuction(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex)
    external view returns (address seller, uint256 amount, Status status, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt)
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        return (_auction.seller, _auction.amount, _auction.status, _auction.startingPrice, _auction.endingPrice, _auction.duration, _auction.startedAt);
    }

    function getLengthAuctioningNFT(address _nftAddress, uint256 _tokenId) external view returns (uint256)
    {
        return auctions[_nftAddress][_tokenId].length;
    }

    function getCurrentPrice(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex) external view returns (uint256)
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        require(_isOnAuction(_auction));
        return _getCurrentPrice(_auction);
    }

    function createAuction(address _nftAddress, uint256 _tokenId, uint256 _amount, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address sender, uint8 v, bytes32 r, bytes32 s)
    external whenNotPaused canBeStoredWith128Bits(_startingPrice) canBeStoredWith128Bits(_endingPrice) canBeStoredWith64Bits(_duration)
    {
        verify(keccak256(abi.encode(CREATE_AUCTION_HASH, _tokenId, _amount, _startingPrice, _endingPrice, _duration, nonces[sender]++)), sender, v, r, s);
        require(IERC1155(_nftAddress).balanceOf(sender, _tokenId) >= _amount, "Holding amount < auctioning amount");
        require(IERC1155(_nftAddress).isApprovedForAll(sender, address(this)), "Account not approve this contract");
        Auction memory _auction = Auction(_tokenId, sender, _amount, uint128(_startingPrice), uint128(_endingPrice), uint64(_duration), uint64(now), Status.AUCTION);
        _addAuction(_nftAddress, _tokenId, _auction, sender);
    }

    function bid(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex, address sender, uint8 v, bytes32 r, bytes32 s) external payable whenNotPaused
    {
        verify(keccak256(abi.encode(BID_AUCTION_HASH, _nftAddress, _tokenId,_tokenIndex, msg.value, nonces[sender]++)), sender, v, r, s);
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        _bid(_nftAddress, _tokenId, _tokenIndex, msg.value, sender);
        _transfer(_nftAddress, _tokenId, _auction.amount, _auction.seller, sender);
    }

    function cancelAuction(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex, address sender, uint8 v, bytes32 r, bytes32 s) external {
        verify(keccak256(abi.encode(CANCEL_AUCTION_HASH, _nftAddress, _tokenId, _tokenIndex, nonces[sender]++)), sender, v, r, s);
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        require(_isOnAuction(_auction));
        require(sender == _auction.seller);
        _cancelAuction(_nftAddress, _tokenId, _tokenIndex);
    }

    function _isOnAuction(Auction memory _auction) internal pure returns (bool) {
        return (_auction.startedAt > 0 && _auction.status == Status.AUCTION);
    }

    function _getCurrentPrice(Auction memory _auction) internal view returns (uint256)
    {
        uint256 _secondsPassed = 0;
        if (now > _auction.startedAt) {
            _secondsPassed = now - _auction.startedAt;
        }

        if (_secondsPassed >= _auction.duration) {
            return _auction.endingPrice;
        } else {
            int256 _totalPriceChange = int256(_auction.endingPrice) - int256(_auction.startingPrice);
            int256 _currentPriceChange = _totalPriceChange * int256(_secondsPassed) / int256(_auction.duration);
            int256 _currentPrice = int256(_auction.startingPrice) + _currentPriceChange;
            return uint256(_currentPrice);
        }
    }

    function _addAuction(address _nftAddress, uint256 _tokenId, Auction memory _auction, address _seller) internal {
        require(_auction.duration >= 1 minutes);
        auctions[_nftAddress][_tokenId].push(_auction);
        AuctionCreated(_nftAddress, _tokenId, _auction.amount, auctions[_nftAddress][_tokenId].length.sub(1), uint256(_auction.startingPrice), uint256(_auction.endingPrice), uint256(_auction.duration), _seller);
    }

    function _cancelAuction(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex) internal {
        auctions[_nftAddress][_tokenId][_tokenIndex].status = Status.CANCEL;
        AuctionCancelled(_nftAddress, _tokenId, _tokenIndex);
    }

    function _transfer(address _nftAddress, uint256 _tokenId, uint256 _amount, address _sender, address _receiver) internal {
        IERC1155(_nftAddress).safeTransferFrom(_sender, _receiver, _tokenId, _amount, "");
    }

    function _bid(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex, uint256 _bidAmount, address sender) internal returns (uint256)
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        require(_isOnAuction(_auction), "Auction is closed");
        uint256 _price = _getCurrentPrice(_auction);
        require(_bidAmount >= _price, "Invalid price");
        address _seller = _auction.seller;
        auctions[_nftAddress][_tokenId][_tokenIndex].status = Status.CLOSE;
        if (_price > 0) {
            uint256 _auctioneerCut = _price * ownerCut / 10000;
            uint256 _sellerProceeds = _price - _auctioneerCut;
            payable(_seller).transfer(_sellerProceeds);
        }
        if (_bidAmount > _price) {
            uint256 _bidExcess = _bidAmount - _price;
            payable(sender).transfer(_bidExcess);
        }
        AuctionSuccessful(_nftAddress, _tokenId, _tokenIndex, _price, sender);
        return _price;
    }

    function claim(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}

