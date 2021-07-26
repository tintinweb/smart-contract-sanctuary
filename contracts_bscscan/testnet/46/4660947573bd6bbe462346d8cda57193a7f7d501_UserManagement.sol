// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './IUserManagement.sol';
import './IERC20.sol';
import './PriceLibrary.sol';
import './Ownable.sol';

contract UserManagement is IUserManagement, Ownable {
    
    using SafeMath for uint256;
    
    struct User {
        uint id;
        uint referCount;
        uint withdrew;
        uint exceed200;
        uint referAmount;
        uint totalAmount;
        address referrer;
    }

    uint256 public userCounter;
    uint256 public pendingReward;
    uint[2] internal DYNAMIC_RATE = [5, 8];
    address public primaryAddr;
    address public poolAddr;
    address public rewardPoolAddr;
    address public factory;
    address public usdtToken;
    IERC20 public hToken;
    

    mapping(uint=>address) public uids;
    mapping(address=>User) public users;
    mapping(address=>uint) public awards;

    event Register(address indexed _user, address indexed _referrer);
    event Reward(address indexed _user, address indexed _referrer, uint256 _amount);

    constructor(address _primaryAddr, address _poolAddr, IERC20 _hToken) public {
        poolAddr = _poolAddr;
        hToken = _hToken;
        primaryAddr = _primaryAddr;
        registration(_primaryAddr, address(0));        
    }

    function setPoolAddr(address _poolAddr) public onlyOwner{
        poolAddr = _poolAddr;
    }

    function setFactory(address _factory, address _usdtToken) public onlyOwner {
        factory = _factory;
        usdtToken = _usdtToken;
    }

    modifier onlyPool() {
        require(msg.sender == address(poolAddr), "only allow poolAddr");
        _;
    }

    function register(address _referrer) public {
        require(!isUserExists(msg.sender), "exist");
        require(isUserExists(_referrer), "ref not register");
        registration(msg.sender, _referrer);
        emit Register(msg.sender, _referrer);
    }

    function registration(address uaddress, address _referrer) internal {
        userCounter++;
        uids[userCounter] = uaddress;
        users[uaddress] = User({
            id: userCounter,
            referCount: 0,
            withdrew: 0,
            exceed200: 0,
            referAmount: 0,
            totalAmount: 0,
            referrer: _referrer
        });
        users[_referrer].referCount++;
    }
    
    function isUserExists(address uaddress) public override view returns(bool) {
        return users[uaddress].id!=0;
    }
    
    function harvest(address uaddress, uint amount) external override onlyPool {
        if(amount>0){
            uint256 totalReward = 0;
            address up = users[uaddress].referrer;
            for(uint i; i < DYNAMIC_RATE.length; i++){
                if(up == address(0)) break;
                uint award;
                if ((i == 0 && users[up].exceed200 >= 2) || 
                    (i == 1 && users[up].referCount >=3 && users[up].referAmount >= 1000)) {
                    award = amount.mul(DYNAMIC_RATE[i]).div(100);
                } else {
                    award = 0;
                }
                if(pendingReward + award > hToken.balanceOf(rewardPoolAddr)) {
                    award = hToken.balanceOf(rewardPoolAddr) - pendingReward;
                }
                if(award > 0) {
                    totalReward += award;
                    awards[up] += award;
                    pendingReward += award;
                    if(i == 0) {
                        emit Reward(uaddress, up, award);
                    }
                }
                up = users[up].referrer;
            }
        }
    }

    function withdraw() public override returns(uint amount){
        amount = awards[msg.sender];
        require(amount > 0, "not good");
        delete awards[msg.sender];
        if(amount > hToken.balanceOf(rewardPoolAddr)) {
            amount = hToken.balanceOf(rewardPoolAddr);
        }
        if(amount > 0) {
            pendingReward -= amount;
            users[msg.sender].withdrew += amount;
            hToken.transferFrom(rewardPoolAddr, msg.sender, amount);
        }
    }

    function updateManager(address _userAddr, address _lpToken, uint256 _amount, bool _isPair) external override onlyPool {
        User storage tuser = users[_userAddr];
        address referrer = users[_userAddr].referrer;
        if(_amount > 0){
            uint256 swapAmount = PriceLibrary.getPrice(factory, _lpToken, address(usdtToken), _amount, _isPair);
            if (referrer != address(0)){
                if(tuser.totalAmount < 200*1e18 && tuser.totalAmount + swapAmount > 200*1e18) {
                    users[referrer].exceed200 += 1;
                }
                users[referrer].referAmount += swapAmount;
            }
            tuser.totalAmount += swapAmount;
        }
    }


}