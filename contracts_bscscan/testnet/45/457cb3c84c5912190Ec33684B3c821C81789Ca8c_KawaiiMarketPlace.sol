//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;


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
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
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
        NAME = "KawaiiMarketPlace";
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

        CREATE_AUCTION_HASH = keccak256("Data(address _nftAddress,uint256 _tokenId,uint256 _startingPrice,uint256 _endingPrice,uint256 _duration,uint256 nonce)");
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


contract KawaiiMarketPlace is Pausable, SignData {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    struct Auction {
        address seller;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        uint64 startedAt;
    }

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;
    IBEP20 public bep20Token;
    bool public isInitialized;

    mapping(address => Auction[]) public userAuctions;
    mapping(address => mapping(uint256 => Auction[])) public auctions;

    event AuctionCreated(address indexed _nftAddress, uint256 indexed _tokenId, uint256 indexed _indexToken, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller);
    event AuctionSuccessful(address indexed _nftAddress, uint256 indexed _tokenId, uint256 _totalPrice, address _winner);
    event AuctionCancelled(address indexed _nftAddress, uint256 indexed _tokenId);



    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

    constructor (uint256 _ownerCut, IBEP20 _bep20Token) public {
        require(_ownerCut <= 10000);
        ownerCut = _ownerCut;
        bep20Token = _bep20Token;
    }

    function changeOwnerCut(uint256 _ownerCut) public onlyOwner {
        ownerCut = _ownerCut;
    }

    function changeBEP20Token(IBEP20 _bep20Token) public onlyOwner {
        bep20Token = _bep20Token;
    }


    function getAuction(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex)
    external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt)
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        require(_isOnAuction(_auction));
        return (_auction.seller, _auction.startingPrice, _auction.endingPrice, _auction.duration, _auction.startedAt);
    }

    function getLengthAuctioningNFT(address _nftAddress, uint256 _tokenId) external view returns (uint256)
    {
        return auctions[_nftAddress][_tokenId].length;
    }

    function getLengthUserAuctioningNFT(address _user) external view returns (uint256)
    {
        return userAuctions[_user].length;
    }

    function getCurrentPrice(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex) external view returns (uint256)
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        require(_isOnAuction(_auction));
        return _getCurrentPrice(_auction);
    }

    function createAuction(address _nftAddress, uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address sender, uint8 v, bytes32 r, bytes32 s)
    external whenNotPaused canBeStoredWith128Bits(_startingPrice) canBeStoredWith128Bits(_endingPrice) canBeStoredWith64Bits(_duration)
    {
        verify(keccak256(abi.encode(CREATE_AUCTION_HASH, _nftAddress, _tokenId, _startingPrice, _endingPrice, _duration, nonces[sender]++)), sender, v, r, s);
        address _seller = sender;
        require(_owns(_nftAddress, _seller, _tokenId), "Account not owner this nft");
        require(isApproved(_nftAddress, _seller), "Account not approve this contract");
        Auction memory _auction = Auction(_seller, uint128(_startingPrice), uint128(_endingPrice), uint64(_duration), uint64(now));
        _addAuction(_nftAddress, _tokenId, _auction, _seller);
    }

    function bid(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex, uint256 _amount, address sender, uint8 v, bytes32 r, bytes32 s) external whenNotPaused
    {
        verify(keccak256(abi.encode(BID_AUCTION_HASH, _nftAddress, _tokenId, _tokenIndex, _amount, nonces[sender]++)), sender, v, r, s);
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        _bid(_nftAddress, _tokenId, _tokenIndex, _amount, sender);
        _transfer(_nftAddress, _tokenId, 1, _auction.seller, sender);
    }

    function cancelAuction(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex, address sender, uint8 v, bytes32 r, bytes32 s) external {
        verify(keccak256(abi.encode(CANCEL_AUCTION_HASH, _nftAddress, _tokenId, _tokenIndex, nonces[sender]++)), sender, v, r, s);
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        require(_isOnAuction(_auction));
        require(sender == _auction.seller);
        _cancelAuction(_nftAddress, _tokenId, _tokenIndex);
    }


    function _isOnAuction(Auction memory _auction) internal pure returns (bool) {
        return (_auction.startedAt > 0);
    }

    function _getCurrentPrice(Auction memory _auction) internal view returns (uint256)
    {
        uint256 _secondsPassed = 0;
        if (now > _auction.startedAt) {
            _secondsPassed = now - _auction.startedAt;
        }
        return _computeCurrentPrice(_auction.startingPrice, _auction.endingPrice, _auction.duration, _secondsPassed);
    }

    function _computeCurrentPrice(uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint256 _secondsPassed)
    internal pure returns (uint256)
    {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 _totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            int256 _currentPriceChange = _totalPriceChange * int256(_secondsPassed) / int256(_duration);
            int256 _currentPrice = int256(_startingPrice) + _currentPriceChange;
            return uint256(_currentPrice);
        }
    }

    function _owns(address _nftAddress, address _claimant, uint256 _tokenId) private view returns (bool) {
        return IERC1155(_nftAddress).balanceOf(_claimant, _tokenId) > 0;
    }

    function isApproved(address _nftAddress, address _claimant) private view returns (bool) {
        return IERC1155(_nftAddress).isApprovedForAll(_claimant, address(this));
    }

    function _addAuction(address _nftAddress, uint256 _tokenId, Auction memory _auction, address _seller) internal {
        require(_auction.duration >= 1 minutes);
        userAuctions[_seller].push(_auction);
        auctions[_nftAddress][_tokenId].push(_auction);
        AuctionCreated(_nftAddress, _tokenId, auctions[_nftAddress][_tokenId].length.sub(1), uint256(_auction.startingPrice), uint256(_auction.endingPrice), uint256(_auction.duration), _seller);
    }

    function _removeAuction(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex) internal {
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        uint256 userAuctionLength = userAuctions[_auction.seller].length;
        for (uint256 i = 0; i < userAuctionLength; i++) {
            if (userAuctions[_auction.seller][i].endingPrice == _auction.endingPrice &&
            userAuctions[_auction.seller][i].startingPrice == _auction.startingPrice &&
            userAuctions[_auction.seller][i].startedAt == _auction.startedAt &&
                userAuctions[_auction.seller][i].duration == _auction.duration
            ) {
                userAuctions[_auction.seller][i] = userAuctions[_auction.seller][userAuctionLength - 1];
                userAuctions[_auction.seller].pop();
                break;
            }
        }
        auctions[_nftAddress][_tokenId][_tokenIndex] = auctions[_nftAddress][_tokenId][auctions[_nftAddress][_tokenId].length - 1];
        auctions[_nftAddress][_tokenId].pop();
    }

    function _cancelAuction(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex) internal {
        _removeAuction(_nftAddress, _tokenId, _tokenIndex);
        AuctionCancelled(_nftAddress, _tokenId);
    }

    function _transfer(address _nftAddress, uint256 _tokenId, uint256 _amount, address _sender, address _receiver) internal {
        IERC1155(_nftAddress).safeTransferFrom(_sender, _receiver, _tokenId, _amount, "");
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }

    function _bid(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex, uint256 _bidAmount, address sender) internal returns (uint256)
    {
        Auction memory _auction = auctions[_nftAddress][_tokenId][_tokenIndex];
        require(_isOnAuction(_auction), "Auction is closed");
        uint256 _price = _getCurrentPrice(_auction);
        require(_bidAmount >= _price, "Invalid price");
        address _seller = _auction.seller;
        _removeAuction(_nftAddress, _tokenId, _tokenIndex);
        if (_price > 0) {
            uint256 _auctioneerCut = _computeCut(_price);
            uint256 _sellerProceeds = _price - _auctioneerCut;
            bep20Token.safeTransferFrom(sender, _seller, _sellerProceeds);
            bep20Token.safeTransferFrom(sender, address(this), _auctioneerCut);
        }
        AuctionSuccessful(_nftAddress, _tokenId, _price, sender);
        return _price;
    }
}

