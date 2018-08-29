pragma solidity 0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC721Interface {
    //ERC721
    function balanceOf(address owner) public view returns (uint256 _balance);
    function ownerOf(uint256 tokenID) public view returns (address owner);
    function transfer(address to, uint256 tokenID) public returns (bool);
    function approve(address to, uint256 tokenID) public returns (bool);
    function takeOwnership(uint256 tokenID) public;
    function totalSupply() public view returns (uint);
    function owns(address owner, uint256 tokenID) public view returns (bool);
    function allowance(address claimant, uint256 tokenID) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenID) public returns (bool);
    function createLand(address owner) external returns (uint);
}


contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address public owner;
    mapping(address => bool) admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddAdmin(address indexed admin);
    event DelAdmin(address indexed admin);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }


    function addAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0));
        admins[_adminAddress] = true;
        emit AddAdmin(_adminAddress);
    }

    function delAdmin(address _adminAddress) external onlyOwner {
        require(admins[_adminAddress]);
        admins[_adminAddress] = false;
        emit DelAdmin(_adminAddress);
    }

    function isAdmin(address _adminAddress) public view returns (bool) {
        return admins[_adminAddress];
    }
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}

interface NewAuctionContract {
    function receiveAuction(address _token, uint _tokenId, uint _startPrice, uint _stopTime) external returns (bool);
}


contract ArconaMarketplaceContract is Ownable {
    using SafeMath for uint;

    ERC20 public arconaToken;

    struct Auction {
        address owner;
        address token;
        uint tokenId;
        uint startPrice;
        uint stopTime;
        address winner;
        uint executeTime;
        uint finalPrice;
        bool executed;
        bool exists;
    }

    mapping(address => bool) public acceptedTokens;
    mapping(address => bool) public whiteList;
    mapping (address => bool) public users;
    mapping(uint256 => Auction) public auctions;
    //token => token_id = auction id
    mapping (address => mapping (uint => uint)) public auctionIndex;
    mapping(address => uint256[]) private ownedAuctions;
    uint private lastAuctionId;
    uint defaultExecuteTime = 24 hours;
    uint public auctionFee = 300; //3%
    uint public gasInTokens = 1000000000000000000;
    uint public minDuration = 1;
    uint public maxDuration = 20160;
    address public profitAddress;

    event ReceiveCreateAuction(address from, uint tokenId, address token);
    event AddAcceptedToken(address indexed token);
    event DelAcceptedToken(address indexed token);
    event AddWhiteList(address indexed addr);
    event DelWhiteList(address indexed addr);
    event NewAuction(address indexed owner, uint tokenId, uint auctionId);
    event AddUser(address indexed user);
    event GetToken(uint auctionId, address winner);
    event SetWinner(address winner, uint auctionId, uint finalPrice, uint executeTime);
    event CancelAuction(uint auctionId);
    event RestartAuction(uint auctionId);

    constructor(address _token, address _profitAddress) public {
        arconaToken = ERC20(_token);
        profitAddress = _profitAddress;
    }


    function() public payable {
        if (!users[msg.sender]) {
            users[msg.sender] = true;
            emit AddUser(msg.sender);
        }
    }


    function receiveCreateAuction(address _from, address _token, uint _tokenId, uint _startPrice, uint _duration) public returns (bool) {
        require(isAcceptedToken(_token));
        require(_duration >= minDuration && _duration <= maxDuration);
        _createAuction(_from, _token, _tokenId, _startPrice, _duration);
        emit ReceiveCreateAuction(_from, _tokenId, _token);
        return true;
    }


    function createAuction(address _token, uint _tokenId, uint _startPrice, uint _duration) external returns (bool) {
        require(isAcceptedToken(_token));
        require(_duration >= minDuration && _duration <= maxDuration);
        _createAuction(msg.sender, _token, _tokenId, _startPrice, _duration);
        return true;
    }


    function _createAuction(address _from, address _token, uint _tokenId, uint _startPrice, uint _duration) internal returns (uint) {
        require(ERC721Interface(_token).transferFrom(_from, this, _tokenId));

        auctions[++lastAuctionId] = Auction({
            owner : _from,
            token : _token,
            tokenId : _tokenId,
            startPrice : _startPrice,
            //startTime : now,
            stopTime : now + (_duration * 1 minutes),
            winner : address(0),
            executeTime : now + (_duration * 1 minutes) + defaultExecuteTime,
            finalPrice : 0,
            executed : false,
            exists: true
            });

        auctionIndex[_token][_tokenId] = lastAuctionId;
        ownedAuctions[_from].push(lastAuctionId);

        emit NewAuction(_from, _tokenId, lastAuctionId);
        return lastAuctionId;
    }


    function setWinner(address _winner, uint _auctionId, uint _finalPrice, uint _executeTime) onlyAdmin external {
        require(auctions[_auctionId].exists);
        require(!auctions[_auctionId].executed);
        require(now > auctions[_auctionId].stopTime);
        //require(auctions[_auctionId].winner == address(0));
        require(_finalPrice >= auctions[_auctionId].startPrice);

        auctions[_auctionId].winner = _winner;
        auctions[_auctionId].finalPrice = _finalPrice;
        if (_executeTime > 0) {
            auctions[_auctionId].executeTime = now + (_executeTime * 1 minutes);
        }
        emit SetWinner(_winner, _auctionId, _finalPrice, _executeTime);
    }


    function getToken(uint _auctionId) external {
        require(auctions[_auctionId].exists);
        require(!auctions[_auctionId].executed);
        require(now <= auctions[_auctionId].executeTime);
        require(msg.sender == auctions[_auctionId].winner);

        uint fullPrice = auctions[_auctionId].finalPrice;
        require(arconaToken.transferFrom(msg.sender, this, fullPrice));

        if (!inWhiteList(auctions[_auctionId].owner)) {
            uint fee = valueFromPercent(fullPrice, auctionFee);
            fullPrice = fullPrice.sub(fee).sub(gasInTokens);
        }
        arconaToken.transfer(auctions[_auctionId].owner, fullPrice);

        require(ERC721Interface(auctions[_auctionId].token).transfer(auctions[_auctionId].winner, auctions[_auctionId].tokenId));
        auctions[_auctionId].executed = true;
        emit GetToken(_auctionId, msg.sender);
    }


    function cancelAuction(uint _auctionId) external {
        require(auctions[_auctionId].exists);
        require(!auctions[_auctionId].executed);
        require(msg.sender == auctions[_auctionId].owner);
        require(now > auctions[_auctionId].executeTime);

        require(ERC721Interface(auctions[_auctionId].token).transfer(auctions[_auctionId].owner, auctions[_auctionId].tokenId));
        emit CancelAuction(_auctionId);
    }

    function restartAuction(uint _auctionId, uint _startPrice, uint _duration) external {
        require(auctions[_auctionId].exists);
        require(!auctions[_auctionId].executed);
        require(msg.sender == auctions[_auctionId].owner);
        require(now > auctions[_auctionId].executeTime);

        auctions[_auctionId].startPrice = _startPrice;
        auctions[_auctionId].stopTime = now + (_duration * 1 minutes);
        auctions[_auctionId].executeTime = now + (_duration * 1 minutes) + defaultExecuteTime;
        emit RestartAuction(_auctionId);
    }

    function migrateAuction(uint _auctionId, address _newAuction) external {
        require(auctions[_auctionId].exists);
        require(!auctions[_auctionId].executed);
        require(msg.sender == auctions[_auctionId].owner);
        require(now > auctions[_auctionId].executeTime);

        require(ERC721Interface(auctions[_auctionId].token).approve(_newAuction, auctions[_auctionId].tokenId));
        require(NewAuctionContract(_newAuction).receiveAuction(
                auctions[_auctionId].token,
                auctions[_auctionId].tokenId,
                auctions[_auctionId].startPrice,
                auctions[_auctionId].stopTime
            ));
    }


    function ownerAuctionCount(address _owner) external view returns (uint256) {
        return ownedAuctions[_owner].length;
    }


    function auctionsOf(address _owner) external view returns (uint256[]) {
        return ownedAuctions[_owner];
    }


    function addAcceptedToken(address _token) onlyAdmin external {
        require(_token != address(0));
        acceptedTokens[_token] = true;
        emit AddAcceptedToken(_token);
    }


    function delAcceptedToken(address _token) onlyAdmin external {
        require(acceptedTokens[_token]);
        acceptedTokens[_token] = false;
        emit DelAcceptedToken(_token);
    }


    function addWhiteList(address _address) onlyAdmin external {
        require(_address != address(0));
        whiteList[_address] = true;
        emit AddWhiteList(_address);
    }


    function delWhiteList(address _address) onlyAdmin external {
        require(whiteList[_address]);
        whiteList[_address] = false;
        emit DelWhiteList(_address);
    }


    function setDefaultExecuteTime(uint _hours) onlyAdmin external {
        defaultExecuteTime = _hours * 1 hours;
    }


    function setAuctionFee(uint _fee) onlyAdmin external {
        auctionFee = _fee;
    }


    function setGasInTokens(uint _gasInTokens) onlyAdmin external {
        gasInTokens = _gasInTokens;
    }


    function setMinDuration(uint _minDuration) onlyAdmin external {
        minDuration = _minDuration;
    }


    function setMaxDuration(uint _maxDuration) onlyAdmin external {
        maxDuration = _maxDuration;
    }


    function setProfitAddress(address _profitAddress) onlyOwner external {
        require(_profitAddress != address(0));
        profitAddress = _profitAddress;
    }


    function isAcceptedToken(address _token) public view returns (bool) {
        return acceptedTokens[_token];
    }


    function inWhiteList(address _address) public view returns (bool) {
        return whiteList[_address];
    }


    function withdrawTokens() onlyAdmin public {
        require(arconaToken.balanceOf(this) > 0);
        arconaToken.transfer(profitAddress, arconaToken.balanceOf(this));
    }

    //1% - 100, 10% - 1000 50% - 5000
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }

    function destruct() onlyOwner public {
        selfdestruct(owner);
    }
}