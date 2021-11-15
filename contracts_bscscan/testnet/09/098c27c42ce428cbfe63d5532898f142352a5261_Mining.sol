// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ITnt.sol";
import "./IPancakePair.sol";

contract Mining is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // 所有算力都保留了18位小数
    uint256 public globalStaticComputingPower; // 全网总静态算力
    uint256 public globalDynamicComputingPower; // 全网总动态算力
    uint256 public lastRewardBlock;  // Last block number that tnt distribution occurs.
    uint256 public accTntPerComputingPower; // 每算力多少TNT, times 1e12.
    uint256 private constant DECIMAL_18 = 1e18;

    struct UserInfo {
        uint256 id;
        address referer; // 邀请人，必须是有效用户
        uint256 vipLevel; // vip等级，v1到v8，对应1到8
        uint256 teamAmount; // 所有直推用户的团队业绩
        uint256 staticComputingPower; // 个人静态算力
        uint256 dynamicComputingPower; // 个人动态算力
        uint256 rewardDebt; // Reward debt
        uint256 rewardChange;
        uint256 exitNum;
    }
    
    ITnt public tnt;    // The tnt Token
    IERC20 public tntBusdLp;
    IERC20 public didBusdLp;
    IERC20 public bedBusdLp;
    IERC20 public busd;
    uint256 public tntPerBlock = 0.30864198 * 1e18;  // tnt tokens created per block.
    mapping(address => mapping(address => uint256)) public amount; // user address => lpToken address => amount
    mapping(address => uint256) public totalAmount; // lpToken address => totalAmount
    mapping(address => bool) public canBuy;
    mapping(address => UserInfo) public userMap;
    mapping(address => mapping(uint256 => mapping(address => uint256))) public referToUserTeam; // address1 => exitNum => address2 =>团队业绩。地址2给地址1带来的团队业绩
    mapping(address => mapping(uint256 => mapping(address => uint256))) public referToUserDy; // address1 => exitNum => address2 =>动态奖励。地址2给地址1带来的动态奖励
    bool public paused = false; // Control mining
    uint256 public startBlock; // The block number when tnt mining starts.
    uint256 public halvingPeriod = 10512000; // How many blocks are halved
    
    // ------------------------用于统计用户---------------------------------
    uint256 public userIdCount;
    address[] public userAddrs;
    // ------------------------用于统计用户---------------------------------
    
    event Deposit(address indexed user, IERC20 indexed lpToken, uint256 amount, address referer);
    event WithdrawReward(address indexed user, uint256 amount);
    event WithdrawAll(address indexed _user, uint256 _tnts, uint256 _dids, uint256 _beds);
    event EmergencyWithdrawAll(address indexed _user, uint256 _tnts, uint256 _dids, uint256 _beds);

    constructor(ITnt _tnt, IERC20 _busd, IERC20 _tntBusdLp, IERC20 _didBusdLp, IERC20 _bedBusdLp) {
        tnt = _tnt;
        busd = _busd;
        startBlock = block.number;
        tntBusdLp = _tntBusdLp;
        didBusdLp = _didBusdLp;
        bedBusdLp = _bedBusdLp;
        canBuy[address(_tntBusdLp)] = true;
        canBuy[address(_didBusdLp)] = true;
        canBuy[address(_bedBusdLp)] = true;
    }

    function setPause() public onlyOwner {
        paused = !paused;
    }

    function globalComputingPower() public view returns (uint256) {
        return globalStaticComputingPower.add(globalDynamicComputingPower);
    }
    
    function userComputingPower(address _user) public view returns (uint256) {
        return userMap[_user].staticComputingPower.add(userMap[_user].dynamicComputingPower);
    }
    
    function userTotalLpTokens(address _user) public view returns (uint256) {
        return amount[_user][address(tntBusdLp)].add(amount[_user][address(didBusdLp)]).add(amount[_user][address(bedBusdLp)]);
    }

    function phase(uint256 blockNumber) public view returns (uint256) {
        if (halvingPeriod == 0) {
            return 0;
        }
        if (blockNumber > startBlock) {
            return (blockNumber.sub(startBlock).sub(1)).div(halvingPeriod);
        }
        return 0;
    }

    function reward(uint256 blockNumber) public view returns (uint256) {
        uint256 _phase = phase(blockNumber);
        return tntPerBlock.div(2 ** _phase);
    }

    function getTntBlockReward() public view returns (uint256) {
        uint256 _lastRewardBlock = lastRewardBlock;
        uint256 blockReward = 0;
        uint256 n = phase(_lastRewardBlock);
        uint256 m = phase(block.number);
        while (n < m) {
            n++;
            uint256 r = n.mul(halvingPeriod).add(startBlock);
            blockReward = blockReward.add((r.sub(_lastRewardBlock)).mul(reward(r)));
            _lastRewardBlock = r;
        }
        blockReward = blockReward.add((block.number.sub(_lastRewardBlock)).mul(reward(block.number)));
        return blockReward;
    }
    
    function update() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (globalComputingPower() == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 blockReward = getTntBlockReward();
        if (blockReward <= 0) {
            return;
        }
        bool minRet = tnt.mint(address(this), blockReward);
        if (minRet) {
            accTntPerComputingPower = accTntPerComputingPower.add(blockReward.mul(1e12).div(globalComputingPower()));
        }
        lastRewardBlock = block.number;
    }

    function pending(address _user) external view returns (uint256) {
        uint256 _accTntPerComputingPower = accTntPerComputingPower;
        uint256 _userComputingPower = userComputingPower(_user);
        uint256 _rewardDebt = userMap[_user].rewardDebt;
        if (_userComputingPower > 0) {
            if (block.number > lastRewardBlock) {
                uint256 blockReward = getTntBlockReward();
                _accTntPerComputingPower = _accTntPerComputingPower.add(blockReward.mul(1e12).div(globalComputingPower()));
                return (_userComputingPower.mul(_accTntPerComputingPower).div(1e12).add(userMap[_user].rewardChange)).sub(_rewardDebt);
            }
            if (block.number == lastRewardBlock) {
                return (_userComputingPower.mul(_accTntPerComputingPower).div(1e12).add(userMap[_user].rewardChange)).sub(_rewardDebt);
            }
        }
        return 0;
    }
    
    function deposit(IERC20 _lpToken, uint256 _amount, address _referer) public notPause {
        require(_amount >= 100, "_amount least 100");
        require(canBuy[address(_lpToken)], "Does not support this token");
        // 统计用户
        address _user = msg.sender;
        if (userMap[_user].id == 0) {
            userIdCount++;
            userMap[_user].id = userIdCount;
            userMap[_user].exitNum = 1;
            userAddrs.push(_user);
            if (userMap[_referer].id > 0) {
                userMap[_user].referer = _referer;
            }
        }
        depositTnt(_lpToken, _amount, _user, userMap[_user].referer);
    }

    function depositTnt(IERC20 _lpToken, uint256 _amount, address _user, address _referer) private {
        update();
        uint256 _accTntPerComputingPower = accTntPerComputingPower;
        uint256 _userComputingPower = userComputingPower(_user);
        if (_userComputingPower > 0) {
            // TODO
            require((_userComputingPower.mul(_accTntPerComputingPower).div(1e12)).add(userMap[_user].rewardChange) >= userMap[_user].rewardDebt, "aaaaaaaaaaaaaaaaa1");
            uint256 pendingAmount = (_userComputingPower.mul(_accTntPerComputingPower).div(1e12)).add(userMap[_user].rewardChange).sub(userMap[_user].rewardDebt);
            if (pendingAmount > 0) {
                safeTntTransfer(_user, pendingAmount);
                userMap[_user].rewardChange = 0;
            }
        }
        _lpToken.safeTransferFrom(_user, address(this), _amount);
        address _lpTokenAddr = address(_lpToken);
        amount[_user][_lpTokenAddr] = amount[_user][_lpTokenAddr].add(_amount);
        totalAmount[_lpTokenAddr] = totalAmount[_lpTokenAddr].add(_amount);
        // 计算算力
        compute(_lpTokenAddr, _amount, _user, _referer);
        userMap[_user].rewardDebt = userComputingPower(_user).mul(_accTntPerComputingPower).div(1e12);
        emit Deposit(_user, _lpToken, _amount, _referer);
    }
    
    function compute(address _lpToken, uint256 _amount, address _user, address _referer) private {
        uint256 _busdAmount = tvl(_lpToken, _amount); // _amount换算成算力
        globalStaticComputingPower = globalStaticComputingPower.add(_busdAmount);
        userMap[_user].staticComputingPower = userMap[_user].staticComputingPower.add(_busdAmount);
        
        if (userMap[_referer].id > 0) {
            userMap[_referer].teamAmount = userMap[_referer].teamAmount.add(_busdAmount);
            // 累加_user给_referer带来的团队业绩
            referToUserTeam[_referer][userMap[_referer].exitNum][_user] = referToUserTeam[_referer][userMap[_referer].exitNum][_user].add(_busdAmount);
            setVipLevel(_referer);
            refererReward(_user, _busdAmount);
        }
    }
    
    function setVipLevel(address _referer) private {
        uint256 _teamAmount = userMap[_referer].teamAmount;
        uint256 _vipLevel = 0;
        if (_teamAmount >= 1000000e18) {
            _vipLevel = 8;
        } else if (_teamAmount >= 500000e18) {
            _vipLevel = 7;
        } else if (_teamAmount >= 200000e18) {
            _vipLevel = 6;
        } else if (_teamAmount >= 100000e18) {
            _vipLevel = 5;
        } else if (_teamAmount >= 50000e18) {
            _vipLevel = 4;
        } else if (_teamAmount >= 10000e18) {
            _vipLevel = 3;
        } else if (_teamAmount >= 5000e18) {
            _vipLevel = 2;
        } else if (_teamAmount >= 1000e18) {
            _vipLevel = 1;
        }
        if (_vipLevel != userMap[_referer].vipLevel) {
            userMap[_referer].vipLevel = _vipLevel;
        }
    }
    
    // 没有找到规律，只能硬编码
    function refererReward(address _user, uint256 _computingPower) private {
        address _oldUser = _user;
        for (uint256 i = 1; i <= 20; i++) {
            address _referer = userMap[_user].referer;
            if (userMap[_referer].id == 0) {
                return;
            }
            uint256 vip = userMap[_referer].vipLevel;
            if (vip == 1) {
                refererReward1(_oldUser, i, _referer, _computingPower);
            } else if (vip == 2) {
                refererReward2(_oldUser, i, _referer, _computingPower);
            } else if (vip == 3) {
                refererReward3(_oldUser, i, _referer, _computingPower);
            } else if (vip == 4) {
                refererReward4(_oldUser, i, _referer, _computingPower);
            } else if (vip == 5) {
                refererReward5(_oldUser, i, _referer, _computingPower);
            } else if (vip == 6) {
                refererReward6(_oldUser, i, _referer, _computingPower);
            } else if (vip == 7) {
                refererReward7(_oldUser, i, _referer, _computingPower);
            } else if (vip == 8) {
                refererReward8(_oldUser, i, _referer, _computingPower);
            }
            _user = _referer;
        }
    }
    
    function refererReward1(address _oldUser, uint256 i, address _referer, uint256 _computingPower) private {
        if (i <= 2) {
            uint256 _base = base(_referer);
            if (_base > 0) {
                uint256 _computingPowerReward;
                if (i == 1) {
                    _computingPowerReward = _computingPower.mul(5).mul(_base).div(10000);
                } else if (i == 2) {
                    _computingPowerReward = _computingPower.mul(2).mul(_base).div(10000);
                }
                addDynamicComputingPower(_referer, _computingPowerReward); // 累加上级的动态算力
                // 累加_oldUser给_referer带来的动态算力
                referToUserDy[_referer][userMap[_referer].exitNum][_oldUser] = referToUserDy[_referer][userMap[_referer].exitNum][_oldUser].add(_computingPowerReward);
            }
        }
    }
    
    function refererReward2(address _oldUser, uint256 i, address _referer, uint256 _computingPower) private {
        if (i <= 4) {
            uint256 _base = base(_referer);
            if (_base > 0) {
                uint256 _computingPowerReward = _computingPower.mul(6 - i).mul(_base).div(10000);
                addDynamicComputingPower(_referer, _computingPowerReward);
                // 累加_oldUser给_referer带来的动态算力
                referToUserDy[_referer][userMap[_referer].exitNum][_oldUser] = referToUserDy[_referer][userMap[_referer].exitNum][_oldUser].add(_computingPowerReward);
            }
        }
    }
    
    function refererReward3(address _oldUser, uint256 i, address _referer, uint256 _computingPower) private {
        if (i <= 6) {
            uint256 _base = base(_referer);
            if (_base > 0) {
                uint256 _computingPowerReward;
                if (i == 6) {
                    _computingPowerReward = _computingPower.mul(2).mul(_base).div(10000);
                } else {
                    _computingPowerReward = _computingPower.mul(7 - i).mul(_base).div(10000);
                }
                addDynamicComputingPower(_referer, _computingPowerReward);
                // 累加_oldUser给_referer带来的动态算力
                referToUserDy[_referer][userMap[_referer].exitNum][_oldUser] = referToUserDy[_referer][userMap[_referer].exitNum][_oldUser].add(_computingPowerReward);
            }
        }
    }
    
    function refererReward4(address _oldUser, uint256 i, address _referer, uint256 _computingPower) private {
        if (i <= 8) {
            uint256 _base = base(_referer);
            if (_base > 0) {
                uint256 _computingPowerReward;
                if (i == 1) {
                    _computingPowerReward = _computingPower.mul(8).mul(_base).div(10000);
                } else if (i == 7 || i == 8) {
                    _computingPowerReward = _computingPower.mul(2).mul(_base).div(10000);
                } else {
                    _computingPowerReward = _computingPower.mul(8 - i).mul(_base).div(10000);
                }
                addDynamicComputingPower(_referer, _computingPowerReward);
                // 累加_oldUser给_referer带来的动态算力
                referToUserDy[_referer][userMap[_referer].exitNum][_oldUser] = referToUserDy[_referer][userMap[_referer].exitNum][_oldUser].add(_computingPowerReward);
            }
        }
    }
    
    function refererReward5(address _oldUser, uint256 i, address _referer, uint256 _computingPower) private {
        if (i <= 11) {
            uint256 _base = base(_referer);
            if (_base > 0) {
                uint256 _computingPowerReward;
                if (i == 1) {
                    _computingPowerReward = _computingPower.mul(9).mul(_base).div(10000);
                } else if (i >= 8 && i <= 11) {
                    _computingPowerReward = _computingPower.mul(2).mul(_base).div(10000);
                } else {
                    _computingPowerReward = _computingPower.mul(9 - i).mul(_base).div(10000);
                }
                addDynamicComputingPower(_referer, _computingPowerReward);
                // 累加_oldUser给_referer带来的动态算力
                referToUserDy[_referer][userMap[_referer].exitNum][_oldUser] = referToUserDy[_referer][userMap[_referer].exitNum][_oldUser].add(_computingPowerReward);
            }
        }
    }
    
    function refererReward6(address _oldUser, uint256 i, address _referer, uint256 _computingPower) private {
        if (i <= 14) {
            uint256 _base = base(_referer);
            if (_base > 0) {
                uint256 _computingPowerReward;
                if (i == 1) {
                    _computingPowerReward = _computingPower.mul(10).mul(_base).div(10000);
                } else if (i >= 9 && i <= 14) {
                    _computingPowerReward = _computingPower.mul(2).mul(_base).div(10000);
                } else {
                    _computingPowerReward = _computingPower.mul(10 - i).mul(_base).div(10000);
                }
                addDynamicComputingPower(_referer, _computingPowerReward);
                // 累加_oldUser给_referer带来的动态算力
                referToUserDy[_referer][userMap[_referer].exitNum][_oldUser] = referToUserDy[_referer][userMap[_referer].exitNum][_oldUser].add(_computingPowerReward);
            }
        }
    }
    
    function refererReward7(address _oldUser, uint256 i, address _referer, uint256 _computingPower) private {
        if (i <= 17) {
            uint256 _base = base(_referer);
            if (_base > 0) {
                uint256 _computingPowerReward;
                if (i == 1) {
                    _computingPowerReward = _computingPower.mul(12).mul(_base).div(10000);
                } else if (i == 2) {
                    _computingPowerReward = _computingPower.mul(10).mul(_base).div(10000);
                } else if (i >= 10 && i <= 17) {
                    _computingPowerReward = _computingPower.mul(2).mul(_base).div(10000);
                } else {
                    _computingPowerReward = _computingPower.mul(11 - i).mul(_base).div(10000);
                }
                addDynamicComputingPower(_referer, _computingPowerReward);
                // 累加_oldUser给_referer带来的动态算力
                referToUserDy[_referer][userMap[_referer].exitNum][_oldUser] = referToUserDy[_referer][userMap[_referer].exitNum][_oldUser].add(_computingPowerReward);
            }
        }
    }
    
    function refererReward8(address _oldUser, uint256 i, address _referer, uint256 _computingPower) private {
        if (i <= 20) {
            uint256 _base = base(_referer);
            if (_base > 0) {
                uint256 _computingPowerReward;
                if (i == 1) {
                    _computingPowerReward = _computingPower.mul(16).mul(_base).div(10000);
                } else if (i == 2) {
                    _computingPowerReward = _computingPower.mul(12).mul(_base).div(10000);
                } else if (i == 3) {
                    _computingPowerReward = _computingPower.mul(10).mul(_base).div(10000);
                } else if (i >= 11 && i <= 20) {
                    _computingPowerReward = _computingPower.mul(2).mul(_base).div(10000);
                } else {
                    _computingPowerReward = _computingPower.mul(12 - i).mul(_base).div(10000);
                }
                addDynamicComputingPower(_referer, _computingPowerReward);
                // 累加_oldUser给_referer带来的动态算力
                referToUserDy[_referer][userMap[_referer].exitNum][_oldUser] = referToUserDy[_referer][userMap[_referer].exitNum][_oldUser].add(_computingPowerReward);
            }
        }
    }
    
    function addDynamicComputingPower(address _user, uint256 _computingPowerReward) private {
        userMap[_user].dynamicComputingPower = userMap[_user].dynamicComputingPower.add(_computingPowerReward);
        globalDynamicComputingPower = globalDynamicComputingPower.add(_computingPowerReward);
    }
    
    function base(address _user) private view returns (uint256 _base) {
        uint256 _userTotalLpTokens = userTotalLpTokens(_user);
        if (_userTotalLpTokens >= 500e18) {
            _base = 100;
        } else if (_userTotalLpTokens >= 250e18) {
            _base = 70;
        }  else if (_userTotalLpTokens >= 50e18) {
            _base = 50;
        }
    }
    
    function tvl(address _lpToken, uint256 _amount) public view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        /*address _token0 = IPancakePair(_lpToken).token0();
        address _token1 = IPancakePair(_lpToken).token1();
        address _busdAddr = address(busd);
        require(_token0 == _busdAddr || _token1 == _busdAddr, "lpToken is error");*/
        return busd.balanceOf(_lpToken).mul(_amount).div(IERC20(_lpToken).totalSupply()).mul(2);
    }

    function withdrawReward() public notPause {
        address _user = _msgSender();
        uint256 _userComputingPower = userComputingPower(_user);
        require(_userComputingPower > 0, "no reward");
        UserInfo storage user = userMap[_user];
        update();
        // TODO
        require((_userComputingPower.mul(accTntPerComputingPower).div(1e12)).add(userMap[_user].rewardChange) >= user.rewardDebt, "aaaaaaaaaaaaaaaaa2");
        uint256 pendingAmount = (_userComputingPower.mul(accTntPerComputingPower).div(1e12)).add(userMap[_user].rewardChange).sub(user.rewardDebt);
        if (pendingAmount > 0) {
            safeTntTransfer(_user, pendingAmount);
            userMap[_user].rewardChange = 0;
        }
        user.rewardDebt = userComputingPower(_user).mul(accTntPerComputingPower).div(1e12);
        emit WithdrawReward(_user, pendingAmount);
    }
    
    function withdrawAll() public notPause {
        address _user = _msgSender();
        uint256 _userComputingPower = userComputingPower(_user);
        require(_userComputingPower > 0, "no reward");
        UserInfo storage user = userMap[_user];
        update();
        // TODO
        require((_userComputingPower.mul(accTntPerComputingPower).div(1e12)).add(userMap[_user].rewardChange) >= user.rewardDebt, "aaaaaaaaaaaaaaaaa3");
        uint256 pendingAmount = (_userComputingPower.mul(accTntPerComputingPower).div(1e12)).add(userMap[_user].rewardChange).sub(user.rewardDebt);
        if (pendingAmount > 0) {
            safeTntTransfer(_user, pendingAmount);
            userMap[_user].rewardChange = 0;
        }
        
        require(userTotalLpTokens(_user) > 0, "no lpTokens");
        globalStaticComputingPower = globalStaticComputingPower.sub(user.staticComputingPower);
        user.staticComputingPower = 0;
        globalDynamicComputingPower = globalDynamicComputingPower.sub(user.dynamicComputingPower);
        user.dynamicComputingPower = 0;
        user.teamAmount = 0;
        user.vipLevel = 0;
        user.exitNum++;
        address tntBusdLpAddr = address(tntBusdLp);
        uint256 _tnts = amount[_user][tntBusdLpAddr];
        if (_tnts > 0) {
            amount[_user][tntBusdLpAddr] = 0;
            tntBusdLp.safeTransfer(_user, _tnts);
            totalAmount[tntBusdLpAddr] = totalAmount[tntBusdLpAddr].sub(_tnts);
        }
        address didBusdLpAddr = address(didBusdLp);
        uint256 _dids = amount[_user][didBusdLpAddr];
        if (_dids > 0) {
            amount[_user][didBusdLpAddr] = 0;
            didBusdLp.safeTransfer(_user, _dids);
            totalAmount[didBusdLpAddr] = totalAmount[didBusdLpAddr].sub(_dids);
        }
        address bedBusdLpAddr = address(bedBusdLp);
        uint256 _beds = amount[_user][bedBusdLpAddr];
        if (_beds > 0) {
            amount[_user][bedBusdLpAddr] = 0;
            bedBusdLp.safeTransfer(_user, _beds);
            totalAmount[bedBusdLpAddr] = totalAmount[bedBusdLpAddr].sub(_beds);
        }
        user.rewardDebt = userComputingPower(_user).mul(accTntPerComputingPower).div(1e12);
        
        _removeDynamic(_user); // 减去所有上级用户的动态算力
        _removeTeam(_user); // 减去上一级的团队业绩，并且重新计算上一级的等级
        emit WithdrawAll(_user, _tnts, _dids, _beds);
    }
    
    // 减去上一级的团队业绩，并且重新计算上一级的等级
    function _removeTeam(address _user) private {
        address _oldUser = _user;
        address _referer = userMap[_user].referer;
        if (userMap[_referer].id == 0) {
            return;
        }
        
        uint256 _removeTe = referToUserTeam[_referer][userMap[_referer].exitNum][_oldUser];
        if (_removeTe > 0) { // _referer下面有_oldUser给的团队业绩，所以要全部移除
            referToUserTeam[_referer][userMap[_referer].exitNum][_oldUser] = 0;
            userMap[_referer].teamAmount = userMap[_referer].teamAmount.sub(_removeTe);
        }
        setVipLevel(_referer);
    }
    
    // 减去所有上级用户的动态算力
    function _removeDynamic(address _user) private {
        address _oldUser = _user;
        for (uint256 i = 1; i <= 20; i++) {
            address _referer = userMap[_user].referer;
            if (userMap[_referer].id == 0) {
                return;
            }
            uint256 _removeDy = referToUserDy[_referer][userMap[_referer].exitNum][_oldUser];
            if (_removeDy > 0) { // _referer下面有_oldUser给的动态算力，所以要全部移除
                _removeDynamicDetail(_oldUser, _referer, _removeDy);
            }
            _user = _referer;
        }
    }
    
    function _removeDynamicDetail(address _oldUser, address _referer, uint256 _removeDy) private {
        // TODO
        require(userComputingPower(_referer).mul(accTntPerComputingPower).div(1e12) >= userMap[_referer].rewardDebt, "aaaaaaaaaaaaaaaaaaaaaaaaaaa4");
        // 减去用户动态算力之前，先保存用户已获得的收益
        userMap[_referer].rewardChange = userMap[_referer].rewardChange.add(userComputingPower(_referer).mul(accTntPerComputingPower).div(1e12).sub(userMap[_referer].rewardDebt));
        
        referToUserDy[_referer][userMap[_referer].exitNum][_oldUser] = 0;
        userMap[_referer].dynamicComputingPower = userMap[_referer].dynamicComputingPower.sub(_removeDy);
        globalDynamicComputingPower = globalDynamicComputingPower.sub(_removeDy);
        
        // 减去动态算力之后，重新计算rewardDebt
        userMap[_referer].rewardDebt = userComputingPower(_referer).mul(accTntPerComputingPower).div(1e12);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdrawAll() public notPause {
        address _user = _msgSender();
        require(userTotalLpTokens(_user) > 0, "no lpTokens");
        globalStaticComputingPower = globalStaticComputingPower.sub(userMap[_user].staticComputingPower);
        userMap[_user].staticComputingPower = 0;
        userMap[_user].dynamicComputingPower = 0;
        userMap[_user].rewardDebt = 0;
        uint256 _tnts = amount[_user][address(tntBusdLp)];
        if (_tnts > 0) {
            amount[_user][address(tntBusdLp)] = 0;
            tntBusdLp.safeTransfer(_user, _tnts);
            totalAmount[address(tntBusdLp)] = totalAmount[address(tntBusdLp)].sub(_tnts);
        }
        uint256 _dids = amount[_user][address(didBusdLp)];
        if (_dids > 0) {
            amount[_user][address(didBusdLp)] = 0;
            didBusdLp.safeTransfer(_user, _dids);
            totalAmount[address(didBusdLp)] = totalAmount[address(didBusdLp)].sub(_dids);
        }
        uint256 _beds = amount[_user][address(bedBusdLp)];
        if (_beds > 0) {
            amount[_user][address(bedBusdLp)] = 0;
            bedBusdLp.safeTransfer(_user, _beds);
            totalAmount[address(bedBusdLp)] = totalAmount[address(bedBusdLp)].sub(_beds);
        }
        emit EmergencyWithdrawAll(_user, _tnts, _dids, _beds);
    }

    function safeTntTransfer(address _to, uint256 _amount) internal {
        uint256 tntBal = tnt.balanceOf(address(this));
        if (_amount > tntBal) {
            tnt.transfer(_to, tntBal);
        } else {
            tnt.transfer(_to, _amount);
        }
    }

    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITnt is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

