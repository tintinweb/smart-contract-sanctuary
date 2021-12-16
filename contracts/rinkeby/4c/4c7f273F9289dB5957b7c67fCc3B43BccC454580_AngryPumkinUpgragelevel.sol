/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

interface preStaking {
    
    struct details{
        uint256 amount;
        uint256 stakingTime;
        uint256 withdrawTime;
        uint256 stakingID;
        uint256 APYpercentage;
        uint256 rewardReserve;
        uint256 rewardingTime;
        bool claim;
    }
    
   function userDetails(address stakers, uint256 stakerID) external view returns(details calldata);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

interface IupgradeContract{
    function upgradeLevel(uint256 _tokenAmount, address _account, uint256 tokenID) external ;
    function transferProfile(address OldAccount, address newAccount, uint256 tokenID ) external ;
}

contract AngryPumkinUpgragelevel is Ownable, ReentrancyGuard{
    using SafeMath for uint256;

    uint256[] public levels;
    IERC20 public PumkinCoin;
    IERC20 public USDT;
    address public burnAddress = address(0x0);
    uint256 public tokenPerETH;
    uint256 public tokenPerUSDT;
    uint256 public pumkinAmount;
    address public PumkinNFT;

    struct levelInfo{
        uint256 level;
        uint256 rewardAmount;
        uint256 burnAmount;
        uint256 house;
        uint256 vechile;
    }

    struct UserInfo{
        address user;
        uint256 rewardAmount;
        uint256 assertID;
        uint256 lastRewardTime;
        uint256 userLevel;
    }

    mapping (uint256 => levelInfo) viewLevelDetails;
    mapping (address => mapping(uint256 => UserInfo)) userDetails;
    mapping (address => bool) isOperator;

    event UpgradeLevel(address indexed user,uint256 userLevel, uint256 burnAmount);
    event TransferProfile(address indexed TokenOwner, address indexed newOwner, uint256 assertID);
    event SetPumkinNFTAddress(address indexed owner,address pumkinAddress, bool Operator);
    event ClaimRewardTokens(address indexed user, uint256 rewardAmount);
    event SetOperatorAddress(address indexed owner, address operator, bool status);
    event EmergencySafe(address indexed owner, address TokenAddress, address receiver, uint256 TokenAmount);
    event BuyPumkinToken(address indexed user, address tokenAddress, uint256 BuyTokens, uint256 exchangeAmount);
    event AdminDeposit(address indexed owner, uint256 TokenAmount);
    event SetLevelArguments(address indexed owner, levelInfo LevelUpdateParams);

    constructor (address _PumkinCoin, address _USDT, uint256 _tokenPerETH, uint256 _tokenPerUSDT) {
        PumkinCoin = IERC20(_PumkinCoin);
        USDT = IERC20(_USDT);
        tokenPerUSDT = _tokenPerUSDT;
        tokenPerETH = _tokenPerETH;

        intialize();
    }

    modifier onlyOperator() {
        require(isOperator[_msgSender()],"call is not a operator");
        _;
    }

    function intialize() internal {
        viewLevelDetails[1] = levelInfo({ level : 1, rewardAmount : 0, burnAmount : 0, house: 0, vechile: 0});
        viewLevelDetails[2] = levelInfo({ level : 2, rewardAmount : 3e18, burnAmount : 20e18, house: 1e18, vechile: 10e18});
        viewLevelDetails[3] = levelInfo({ level : 3, rewardAmount : 50e18, burnAmount : 100e18, house: 5e18, vechile: 25e18});
        viewLevelDetails[4] = levelInfo({ level : 4, rewardAmount : 75e18, burnAmount : 200e18, house: 10e18, vechile: 50e18});
        viewLevelDetails[5] = levelInfo({ level : 5, rewardAmount : 1e18, burnAmount : 500e18, house: 15e18, vechile: 100e18});
        viewLevelDetails[6] = levelInfo({ level : 6, rewardAmount : 15e17, burnAmount : 750e18, house: 20e18, vechile: 200e18});
        viewLevelDetails[7] = levelInfo({ level : 7, rewardAmount : 2e18, burnAmount : 1250e18, house: 25e18, vechile: 350e18});
        viewLevelDetails[8] = levelInfo({ level : 8, rewardAmount : 25e17, burnAmount : 2000e18, house: 30e18, vechile: 750e18});
        viewLevelDetails[9] = levelInfo({ level : 9, rewardAmount : 3e18, burnAmount : 5000e18, house: 50e18, vechile: 1500e18});
        viewLevelDetails[10] = levelInfo({ level : 10, rewardAmount : 5e18, burnAmount : 10000e18, house: 75e18, vechile: 5000e18});
        viewLevelDetails[11] = levelInfo({ level : 11, rewardAmount : 7e18, burnAmount : 10000e18, house: 100e18, vechile: 5000e18});
        viewLevelDetails[12] = levelInfo({ level : 12, rewardAmount : 10e18, burnAmount : 10000e18, house: 350e18, vechile: 5000e18});
        viewLevelDetails[13] = levelInfo({ level : 13, rewardAmount : 15e18, burnAmount : 10000e18, house: 1000e18, vechile: 5000e18});
        viewLevelDetails[14] = levelInfo({ level : 14, rewardAmount : 35e18, burnAmount : 10000e18, house: 3000e18, vechile: 5000e18});
        viewLevelDetails[15] = levelInfo({ level : 15, rewardAmount : 50e18, burnAmount : 10000e18, house: 20000e18, vechile: 5000e18});
    }

    function viewLevel(uint256 _levelNumber) external view returns(levelInfo memory) {
        return viewLevelDetails[_levelNumber];
    }

    function viewUsers(uint256 _assertID, address _account) external view returns(UserInfo memory) {
        return userDetails[_account][_assertID];
    }

    function viewLevelTokens(uint256 _level) public view returns(uint256 tokenValue){
        levelInfo storage level = viewLevelDetails[_level];
        return level.burnAmount.add(level.house).add(level.vechile);
    }

    function updateLevelItems(uint256 _level, levelInfo calldata updateLevel) external onlyOwner {
        require(_level > 0 && _level < 16,"Invalid level");
        viewLevelDetails[_level] = levelInfo({
                level : updateLevel.level, 
                rewardAmount : updateLevel.rewardAmount, 
                burnAmount : updateLevel.burnAmount, 
                house: updateLevel.house, 
                vechile: updateLevel.vechile
            });
        emit SetLevelArguments(msg.sender, updateLevel);
    }

    function upgradeLevel(uint256 _tokenAmount, address _account, uint256 _assertID) external {
        UserInfo storage user = userDetails[_account][_assertID];
        if(user.userLevel == 0) {
            require(msg.sender == PumkinNFT,"caller not buy any NFTs");
            user.user = _account;
            user.lastRewardTime = block.timestamp;
        }
        require(user.lastRewardTime > 0,"Caller not have a account");
        claimReward(_assertID);
        user.userLevel = user.userLevel.add(1);
        levelInfo storage level = viewLevelDetails[user.userLevel];
        require(user.userLevel < 16,"already level is max");
        require(level.burnAmount.add(level.house).add(level.vechile) <= _tokenAmount,"");
        PumkinCoin.transferFrom(msg.sender, address(this), viewLevelTokens(user.userLevel));
        PumkinCoin.burn(level.burnAmount);

        emit UpgradeLevel(_account, user.userLevel, _tokenAmount);
    }

    function transferProfile(address _OldAccount, address _newAccount, uint256 _assertID ) external onlyOperator {
        UserInfo storage user1 = userDetails[_OldAccount][_assertID];
        UserInfo storage user2 = userDetails[_newAccount][_assertID];

        user2.user = _newAccount;
        user2.userLevel = user1.userLevel;
        user2.lastRewardTime = block.timestamp;

        delete userDetails[_OldAccount][_assertID];
        emit TransferProfile(_OldAccount, _newAccount, _assertID);
    }

    function claimReward(uint256 _assertID) public {
        UserInfo storage user = userDetails[msg.sender][_assertID];
        levelInfo storage level = viewLevelDetails[user.userLevel];
        uint256 dayCount;
        if(user.lastRewardTime.add(86400) < block.timestamp){
            dayCount = (block.timestamp).sub(user.lastRewardTime).div(86400);
            user.lastRewardTime = user.lastRewardTime.add(dayCount.mul(86400));
            user.rewardAmount = user.rewardAmount.add(level.rewardAmount.mul(dayCount));
            PumkinCoin.transfer(msg.sender, level.rewardAmount);
        }
        emit ClaimRewardTokens(user.user, level.rewardAmount.mul(dayCount));
    }

    function setPumkinNFT(address _PumkinNFTAddress) external onlyOwner {
        PumkinNFT = _PumkinNFTAddress;
        isOperator[_PumkinNFTAddress] = true;

        emit SetPumkinNFTAddress(msg.sender, _PumkinNFTAddress, true);
    }

    function setOperator(address _newOperator, bool status) external onlyOwner {
        isOperator[_newOperator] = status;
        emit SetOperatorAddress(msg.sender, _newOperator, status);
    }

    function buyPumkin(address _tokenAddress,uint256 _USDTamount) external payable nonReentrant {
        require(IERC20(_tokenAddress) == USDT || _tokenAddress == address(0x0),"");
        uint256 buyTokens;
        if(_tokenAddress == address(0x0)) {
            buyTokens = tokenPerETH.mul(msg.value); 
            emit BuyPumkinToken(msg.sender, _tokenAddress, buyTokens, msg.value);
        }
        else{ buyTokens = tokenPerUSDT.mul(_USDTamount); 
            USDT.transferFrom(msg.sender, address(this), _USDTamount);
            emit BuyPumkinToken(msg.sender, _tokenAddress, buyTokens, _USDTamount);
        }
        pumkinAmount = pumkinAmount.sub(buyTokens,"Sale Token Finished");
        PumkinCoin.transfer(msg.sender, buyTokens);

    }

    function adminDeposit(uint256 _tokenAmount) external onlyOwner {
        pumkinAmount += _tokenAmount;
        PumkinCoin.transferFrom(msg.sender, address(this),_tokenAmount);
        emit AdminDeposit(msg.sender, _tokenAmount);
    }

    function emergency(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        if(_tokenAddress == address(0x0)){
            require(payable(_to).send(_amount),"Transaction Failed");
        } else {
            IERC20(_tokenAddress).transfer(_to,_amount);
        }
        emit EmergencySafe(msg.sender, _tokenAddress, _to, _amount);
    }
}