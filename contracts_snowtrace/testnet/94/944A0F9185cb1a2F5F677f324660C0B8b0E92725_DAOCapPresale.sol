/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-30
*/

pragma solidity ^0.8.9;
// SPDX-License-Identifier:MIT

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
    IERC20 public token;
    AggregatorV3Interface internal priceFeed =
        AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
    
    struct User {
        uint256 tokenBalance;
        uint256 amountInvestedInPreSale;  
        uint256 claimedTokens;      
        bool isInvestedInPresale;
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
    uint256 public totalAmountRaised;

    mapping(address => User) public users;
    mapping(address => bool) public whitelist;

    event BuyToken(address _user, uint256 _amount, bool isPrivate);
    event ClaimToken(address _user, uint256 _amount);

    constructor(address _token)  {
        token = IERC20(_token);
        totalMaxLimit = totalMaxLimit * (10 ** token.decimals());
        maxLimit = maxLimit * (10 ** token.decimals());
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
        require (block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime,"Presale over");
        require (!privateSaleStop || !publicSaleStop, "Presale not started yet");

        if(!privateSaleStop && !users[msg.sender].isInvestedInPresale) {
            require(whitelist[msg.sender], "PreSale: Not a vip user");
            privateParticipants++;
        } else if(!publicSaleStop && !users[msg.sender].isInvestedInPresale) {
            publicParticipants++;
        }

        uint256 numberOfTokens = usdToTokens(avaxToUsd(msg.value));
        
        users[msg.sender].tokenBalance = users[msg.sender].tokenBalance + (numberOfTokens);
        require(users[msg.sender].tokenBalance <= maxLimit, "you have exceeded max limit");

        users[msg.sender].amountInvestedInPreSale = users[msg.sender].amountInvestedInPreSale + (msg.value);
        users[msg.sender].isInvestedInPresale = true;
       
        totalTokensSale = totalTokensSale + (numberOfTokens);
        totalAmountRaised = totalAmountRaised + (msg.value);
        require(totalMaxLimit >= totalTokensSale, "Presale: tokens exceeded");
    }
    
    function claim() public {
        require (isClaimEnabled, "Claim: not enabled yet");
        require(users[msg.sender].isInvestedInPresale, "Presale: Not Participated.");
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
        return (value * (getLatestPrice())) / (10**priceFeed.decimals());
    }

    function usdToTokens(uint256 usd_amount)view public returns(uint256) {
        return usd_amount  * (10**token.decimals()) / (tokenPricePerUsd * 1e18);
    }

    function startClaim(bool _state) external onlyOwner {
        require(
            block.timestamp > presaleEndTime && !isClaimEnabled,
            "Presale: Not over yet."
        );
        isClaimEnabled = _state;
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