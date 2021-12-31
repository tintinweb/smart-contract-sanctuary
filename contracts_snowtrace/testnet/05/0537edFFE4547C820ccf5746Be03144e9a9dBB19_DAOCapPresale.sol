/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-30
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

interface IERC20 {

    function decimals() external view returns(uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "$KRED: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "$KRED: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DAOCapPresale is Ownable {
    using SafeMath for uint256;
    IERC20 public token;
    AggregatorV3Interface internal priceFeed =
        AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
    
    struct User {
        uint256 tokenBalance;
        uint256 amountInvestedInPreSale;  
        uint256 claimedTokens;      
        bool isInvestedInPreslae;
        bool claimed;
    }
    
    uint256 public claimStartTime;
    bool public isClaimEnabled = false;
    bool public privateSaleStop = true;
    uint256 public privateParticipants;

    bool public publicSaleStop = true;
    uint256 public publicParticipants;
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public tokenPricePerUsd = 3;

    uint256 public totalMaxLimit = 40_000;
    uint256 public maxLimit = 500;
    uint256 public totalTokensSale;

    mapping(address => User) public users;
    mapping(address => bool) public whitelist;

    event BuyToken(address _user, uint256 _amount, bool isPrivate);
    event ClaimToken(address _user, uint256 _amount);

    constructor(address _token)  {
        token = IERC20(_token);

        totalMaxLimit = totalMaxLimit.mul(10 ** token.decimals());
        maxLimit = maxLimit.mul(10 ** token.decimals());
        tokenPricePerUsd = tokenPricePerUsd.mul(10 ** token.decimals());
    }
    
    modifier isPrivateSaleStop(){
        require(!privateSaleStop, "Private sale is not started yet");
        _;
    }

    modifier isPublicSaleStop(){
        require(!publicSaleStop, "Private sale is not started yet");
        _;
    }

    modifier isWhitelisted(address _user) {
        require(whitelist[_user], "PreSale: Not a vip user");
        _;
    }

    function buyTokens() public payable {
        require (block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime);
        require (!privateSaleStop || !publicSaleStop, "Presale not started yet");

        if(!privateSaleStop && !users[msg.sender].isInvestedInPreslae) {
            require(whitelist[msg.sender], "PreSale: Not a vip user");
            privateParticipants++;
        } else if(!publicSaleStop && !users[msg.sender].isInvestedInPreslae) {
            publicParticipants++;
        }

        uint256 tokens = usdToTokens(avaxToUsd(msg.value));
        
        users[msg.sender].tokenBalance = users[msg.sender].tokenBalance.add(tokens);
        require(users[msg.sender].tokenBalance <= maxLimit, "you have exceeded max limit");

        users[msg.sender].amountInvestedInPreSale = users[msg.sender].amountInvestedInPreSale.add(msg.value);
        users[msg.sender].isInvestedInPreslae = true;
       
        totalTokensSale = totalTokensSale.add(tokens);
        require(totalMaxLimit >= totalTokensSale, "Presale: tokens exceeded");
    }

    // function buyPrivatePresale()public payable isPrivateSaleStop{
    //     require (block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime);

    //     if(!users[msg.sender].isInvestedInPreslae){
    //         privateParticipants++;
    //     }
    //     buyTokens(msg.sender, msg.value);
    // }

    // function buyPublicPresale()public payable isPublicSaleStop{
    //     require (block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime);

    //     if(!users[msg.sender].isInvestedInPreslae){
    //         publicParticipants++;
    //     }
    //     buyTokens(msg.sender, msg.value);        
    // }
    
    function claim() public {
        require (isClaimEnabled, "Claim: not enabled yet");
        require(users[msg.sender].isInvestedInPreslae, "Presale: Not Participated.");
        require(!users[msg.sender].claimed, "Presale: Alread claimed.");
        token.transferFrom(
            owner(),
            msg.sender,
            users[msg.sender].tokenBalance - users[msg.sender].claimedTokens
        );
        users[msg.sender].claimedTokens -= users[msg.sender].tokenBalance;
        if(users[msg.sender].claimedTokens == users[msg.sender].tokenBalance) {
            users[msg.sender].claimed = true;
        }
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function usdToAvax(uint256 value) public view returns (uint256) {
        return (value * (1e18) * (10**priceFeed.decimals())) / (getLatestPrice());
    }

    function avaxToUsd(uint256 value) public view returns (uint256) {
        return (value * (1e18) * (getLatestPrice())) / (10**priceFeed.decimals());
    }
    
    // function avaxToTokens(uint256 _value)view public returns(uint256) {
    //     return(usdtToTokensForPrivateSale(getUSDT(_value)));
    // }

    function usdToTokens(uint256 usd_amount)view public returns(uint256) {
        return (usd_amount * (10**priceFeed.decimals()) * (1e18)) / tokenPricePerUsd;
    }

    // Read
    function startClaim() external onlyOwner {
        require(
            block.timestamp > presaleEndTime && !isClaimEnabled,
            "Presale: Not over yet."
        );
        isClaimEnabled = true;
        claimStartTime = block.timestamp;
    }

    // set presale for whitelist users.
    function setVipUsers(address[] memory _users, bool _status) external onlyOwner {
        require(_users.length > 0, "Invalid users length.");

        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = _status;
        }
    }

    function withdrawTokenByOwner()external onlyOwner{
        token.transfer(owner(), token.balanceOf(address(this)));
    }
    
    function withdrawFundByOwner()external onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    function updateToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }
    
    function setPublicPresale(uint256 _startTime, uint256 _endTime, bool _stop) external onlyOwner {
        presaleStartTime = _startTime;
        presaleEndTime = _endTime;
        publicSaleStop = _stop;
    }

    function setPrivatePresale(uint256 _startTime, uint256 _endTime, bool _stop) external onlyOwner {
        presaleStartTime = _startTime;
        presaleEndTime = _endTime;
        privateSaleStop = _stop;
    }
    
    function setPresaleMaxLimit(uint256 value)onlyOwner external{
        totalMaxLimit = value;
    }
    
    function setPresaleMaxLimitByUser(uint256 value)onlyOwner external {
        maxLimit = value;
    }
    
    function setTokenPrice(uint256 _price)onlyOwner external {
        tokenPricePerUsd = _price;
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