// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
import "./PriceLibrary.sol";
import "./SafeERC20.sol";
import './IERC20.sol';
import './Ownable.sol';


contract DomInvitation is Ownable {
    using SafeMath for uint256;
    struct user {
        uint256 id;
        uint256 level;
        uint256 burn;
        address referrer;
    }

    uint256 public userCount;
    address public primaryAddr = 0x4d5F606bD431346d67D99420dB1631aF6BEBA0F8;
    
    address public factory;
    address public dead = 0x000000000000000000000000000000000000dEaD;

    IERC20 public pToken;
    IERC20 public domToken;
    IERC20 public usdtToken;

    //uint256[10] public marketList = [30, 20, 10, 9, 8, 7, 6, 4, 4, 4];
    uint256[10] public marketList = [25, 6, 10, 6, 10, 6, 10, 6, 15, 6];
    //uint256[6] public levelList = [0, 100*1e18, 300*1e18, 500*1e18, 1000*1e18, 1500*1e18];
    uint256[6] public levelList = [0, 100*1e18, 200*1e18, 200*1e18, 500*1e18, 500*1e18];
    
    mapping(address => user) public Users;
    mapping(uint256 => address) public index2User;
    mapping(uint256 => uint256[20]) levelReferMap;

    event Register(address indexed _userAddr, address indexed _referrer);
    event Promote(address indexed _userAddr, uint256 level);
    event Burn(address indexed _userAddr, uint256 _amount);
    event Redeem(address indexed _userAddr, uint256 _power);

    constructor(IERC20 _pToken, IERC20 _domToken) public {
        pToken = _pToken;
        domToken = _domToken;

        userCount = userCount.add(1);
        Users[primaryAddr].id = userCount;
        index2User[userCount] = primaryAddr;
        level_init();
        emit Register(primaryAddr, address(0));
    }

    function level_init() internal {
        // init level 0
        levelReferMap[0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // init level 1
        levelReferMap[1] = [15, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // init level 2
        levelReferMap[2] = [16, 11, 9, 6, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // init level 3
        levelReferMap[3] = [18, 13, 11, 9, 7, 5, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // init level 4
        levelReferMap[4] = [20, 15, 13, 11, 9, 7, 6, 5, 4, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0];
        // init level 5
        levelReferMap[5] = [25, 20, 15, 13, 11, 9, 7, 5, 4, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    }

    function setMarketList(uint256[10] memory _marketList) onlyOwner public {
        marketList = _marketList;
    }

    function setLevelRewardList(uint256 _levelId, uint256[20] memory _levelRewardList) onlyOwner public {
        levelReferMap[_levelId] = _levelRewardList;
    }

    function setPToken(IERC20 _pToken) onlyOwner public {
        pToken = _pToken;
    }

    function setDomToken(IERC20 _domToken) onlyOwner public {
        domToken = _domToken;
    }

    function setFactory(address _factory, IERC20 _usdtToken) onlyOwner public {
        usdtToken = _usdtToken;
        factory = _factory;
    }

    function register(address _referrer) public {
        require(!Address.isContract(msg.sender), "contract address is forbidden");
        require(!isExists(msg.sender), "user exists");
        require(isExists(_referrer), "referrer not exists");
        user storage regUser = Users[msg.sender];
        userCount = userCount.add(1);
        regUser.id = userCount;
        index2User[userCount] = msg.sender;
        regUser.referrer = _referrer;
        
        
        emit Register(msg.sender, _referrer);
    }

    function isExists(address _userAddr) view public returns (bool) {
        return Users[_userAddr].id != 0;
    }

    function promote(uint256 _level) public {
        require(isExists(msg.sender), "user not exists");
        require(Users[msg.sender].level < _level, "level is lower than the last one");
        require(_level <= 5, "level exceeds");
        (uint inAmount, uint outAmount) = PriceLibrary.price(factory, address(usdtToken), address(domToken));
        require(outAmount!=0,"Invalid price");
        uint256 levelAmount = 0;
        // due to promote more than one level
        for(uint256 i = Users[msg.sender].level+1; i <= _level; i++) {
            levelAmount = levelAmount.add(levelList[i]);
        }
        uint256 burnAmount = outAmount.mul(levelAmount).div(inAmount);
        require(domToken.balanceOf(msg.sender) >= burnAmount, "dom is not enough");
        marketReward(msg.sender, burnAmount);
        Users[msg.sender].level = _level;
        Users[msg.sender].burn = Users[msg.sender].burn.add(burnAmount);
        emit Promote(msg.sender, _level);
    }

    function referReward(address _userAddr, uint256 _power) external {
        require(msg.sender == address(pToken), "only pToken can call referReward");
        address preAddr = Users[_userAddr].referrer;
        for(uint256 i = 0; i < 20; i++) {
            if(preAddr == address(0)) {
                break;
            }
            uint256 rewardRate = levelReferMap[Users[preAddr].level][i];
            if (rewardRate > 0){
                pToken.mint(preAddr, _power.mul(rewardRate).div(100));
            }
            preAddr = Users[preAddr].referrer;
        }
        emit Promote(msg.sender, _power);
    }

    function redeemPower(address _userAddr, uint256 _power) external {
        require(msg.sender == address(pToken), "only pToken can call redeemPower");
        address preAddr = Users[_userAddr].referrer;
        for(uint256 i = 0; i < 20; i++) {
            if(preAddr == address(0)) {
                break;
            }
            uint256 rewardRate = levelReferMap[Users[preAddr].level][i];
            uint256 bal = pToken.balanceOf(preAddr);
            uint256 rew = _power.mul(rewardRate).div(100);
            if (rew > bal) {
                pToken.burn(preAddr, bal);
            } else {
                pToken.burn(preAddr, rew);
            }
            preAddr = Users[preAddr].referrer;
        }
    }

    function marketReward(address _userAddr, uint256 _amount) internal{
        address preAddr = Users[_userAddr].referrer;
        uint256 amount = _amount.div(2);
        uint256 rewardTotalAmount = 0;
        for(uint256 i = 0; i < 10; i++) {

            if(preAddr == address(0)) {
                break;
            }
            uint256 level = Users[preAddr].level;
            
            if(i<level.mul(2)) {
                uint256 rewardAmount = amount.mul(marketList[i]).div(100);
                domToken.transferFrom(msg.sender, preAddr, rewardAmount);
                rewardTotalAmount = rewardTotalAmount.add(rewardAmount);
            }
            
            preAddr = Users[preAddr].referrer;
        }
        domToken.transferFrom(msg.sender, dead, _amount.sub(rewardTotalAmount));
        emit Burn(msg.sender, _amount.sub(rewardTotalAmount));
    }
}