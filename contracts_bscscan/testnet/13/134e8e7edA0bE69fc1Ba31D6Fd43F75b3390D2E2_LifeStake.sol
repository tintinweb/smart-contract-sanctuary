/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

contract LifeStake {
    //constant
    uint256 public constant percentDivider = 1_000;
    uint256 public maxStake = 2_500_000_000;
    uint256 public minStake = 10_000;
    uint256 public totalStaked;
    uint256 public currentStaked;
    uint256 public TimeStep = 1 minutes;
    //address
    IERC20 public TOKEN;
    address payable public Admin;
    address payable public RewardAddress;

    // structures
    struct Stake {
        uint256 StakePercent;
        uint256 StakePeriod;
    }
    struct Staker {
        uint256 Amount;
        uint256 Claimed;
        uint256 Claimable;
        uint256 MaxClaimable;
        uint256 TokenPerDay;
        uint256 LastClaimTime;
        uint256 UnStakeTime;
        uint256 StakeTime;
    }

    Stake public StakeI;
    Stake public StakeII;
    Stake public StakeIII;
    // mapping & array
    mapping(address => Staker) private PlanI;
    mapping(address => Staker) private PlanII;
    mapping(address => Staker) private PlanIII;

    modifier onlyAdmin() {
        require(msg.sender == Admin, "Stake: Not an Admin");
        _;
    }
    modifier validDepositId(uint256 _depositId) {
        require(_depositId >= 1 && _depositId <= 3, "Invalid depositId");
        _;
    }
    event StakeIIIBUY(address user, uint256 amount, uint256 time);
    event StakeIBUY(address user, uint256 amount, uint256 time);
    event StakeIIBUY(address user, uint256 amount, uint256 time);
    event StakeIIICLAIMED(address user, uint256 amount, uint256 time);
    event StakeICLAIMED(address user, uint256 amount, uint256 time);
    event StakeIICLAIMED(address user, uint256 amount, uint256 time);

    constructor(address _TOKEN) {
        Admin = payable(msg.sender);
        RewardAddress = payable(msg.sender);
        TOKEN = IERC20(_TOKEN);
        StakeI.StakePercent = 25;
        StakeI.StakePeriod = 30 minutes;

        StakeII.StakePercent = 175;
        StakeII.StakePeriod = 180 minutes;

        StakeIII.StakePercent = 390;
        StakeIII.StakePeriod = 360 minutes;

        maxStake = maxStake * (10**TOKEN.decimals());
        minStake = minStake * (10**TOKEN.decimals());
    }

    receive() external payable {}

    // to buy  token during Stake time => for web3 use
    function deposit(uint256 _depositId, uint256 _amount)
        public
        validDepositId(_depositId)
        
    {
        require(currentStaked <= maxStake, "MaxStake limit reached");
        require(_amount >= minStake, "Deposit more than 10_000");
        TOKEN.transferFrom(msg.sender, address(this), _amount);
        totalStaked = totalStaked + (_amount);
        currentStaked = currentStaked + (_amount);

        if (_depositId == 1) {
            PlanI[msg.sender].Claimable = calcRewards(msg.sender,_depositId);
            PlanI[msg.sender].Amount = PlanI[msg.sender].Amount + (_amount);
            PlanI[msg.sender].TokenPerDay =
                (
                    CalculatePerDay(
                        ((PlanI[msg.sender].Amount * (StakeI.StakePercent)) / (percentDivider))-PlanI[msg.sender].Claimable,
                        StakeI.StakePeriod
                    )
                );
            PlanI[msg.sender].MaxClaimable =
                ((PlanI[msg.sender].Amount * (StakeI.StakePercent)) / (percentDivider));
            
            PlanI[msg.sender].LastClaimTime = block.timestamp;
        
            PlanI[msg.sender].StakeTime = block.timestamp;
            PlanI[msg.sender].UnStakeTime =
                block.timestamp +
                (StakeI.StakePeriod);
            
            emit StakeIBUY(
                msg.sender,
                _amount / (10**(TOKEN.decimals())),
                block.timestamp
            );
        } else if (_depositId == 2) {
            PlanII[msg.sender].Claimable = calcRewards(msg.sender,_depositId);
            
            PlanII[msg.sender].Amount = PlanII[msg.sender].Amount + (_amount);
            PlanII[msg.sender].TokenPerDay =
                (
                    CalculatePerDay(
                        ((PlanII[msg.sender].Amount * (StakeII.StakePercent)) / (percentDivider)-PlanII[msg.sender].Claimable),
                        StakeII.StakePeriod
                    )
                );
            PlanII[msg.sender].MaxClaimable =
                ((PlanII[msg.sender].Amount * (StakeII.StakePercent)) / (percentDivider));
            
            PlanII[msg.sender].LastClaimTime = block.timestamp;
        
            PlanII[msg.sender].StakeTime = block.timestamp;
            PlanII[msg.sender].UnStakeTime =
                block.timestamp +
                (StakeII.StakePeriod);
            PlanII[msg.sender].Amount = PlanII[msg.sender].Amount + (_amount);
            emit StakeIIBUY(
                msg.sender,
                _amount / (10**(TOKEN.decimals())),
                block.timestamp
            );
        } else if (_depositId == 3) {
            PlanIII[msg.sender].Claimable = calcRewards(msg.sender,_depositId);
            PlanIII[msg.sender].Amount = PlanIII[msg.sender].Amount + (_amount);
            PlanIII[msg.sender].TokenPerDay =
                (
                    CalculatePerDay(
                        ((PlanIII[msg.sender].Amount * (StakeIII.StakePercent)) / (percentDivider))-PlanIII[msg.sender].Claimable,
                        StakeIII.StakePeriod
                    )
                );
            PlanIII[msg.sender].MaxClaimable =
                ((PlanIII[msg.sender].Amount * (StakeIII.StakePercent)) / (percentDivider));
            
            PlanIII[msg.sender].LastClaimTime = block.timestamp;
        
            PlanIII[msg.sender].StakeTime = block.timestamp;
            PlanIII[msg.sender].UnStakeTime =
                block.timestamp +
                (StakeIII.StakePeriod);
            emit StakeIIIBUY(
                msg.sender,
                _amount / (10**(TOKEN.decimals())),
                block.timestamp
            );
        }
    }

    function withdrawAll(uint256 _depositId)
        external
        validDepositId(_depositId)
    {
        _withdraw(msg.sender, _depositId);
    }

    function _withdraw(address _user, uint256 _depositId)
        internal
        validDepositId(_depositId)
    {
        if (_depositId == 1) {
            require(
                PlanI[_user].TokenPerDay > 0 &&
                    PlanI[_user].Claimed <= PlanI[_user].MaxClaimable,
                "no claimable amount available3"
            );
            require(
                block.timestamp > PlanI[_user].LastClaimTime + TimeStep,
                "time not reached3"
            );
            uint256 claimable = PlanI[_user].TokenPerDay *
                ((block.timestamp - (PlanI[_user].LastClaimTime)) / (TimeStep));
                claimable = claimable+PlanI[_user].Claimable;
            if (
                claimable > PlanI[_user].MaxClaimable - (PlanI[_user].Claimed)
            ) {
                claimable = PlanI[_user].MaxClaimable - (PlanI[_user].Claimed);
            }

            PlanI[_user].Claimed = PlanI[_user].Claimed + (claimable);
            if(claimable > 0){
            TOKEN.transferFrom(RewardAddress, _user, claimable);
            }
            PlanI[_user].LastClaimTime = block.timestamp;
            emit StakeICLAIMED(
                _user,
                PlanI[_user].Claimed / (10**(TOKEN.decimals())),
                block.timestamp
            );
        }
        if (_depositId == 2) {
            require(
                PlanII[_user].TokenPerDay > 0 &&
                    PlanII[_user].Claimed <= PlanII[_user].MaxClaimable,
                "no claimable amount available3"
            );
            require(
                block.timestamp > PlanII[_user].LastClaimTime + TimeStep,
                "time not reached3"
            );
            uint256 claimable = PlanII[_user].TokenPerDay *
                ((block.timestamp - (PlanII[_user].LastClaimTime)) /
                    (TimeStep));
                    claimable = claimable+PlanII[_user].Claimable;
            if (
                claimable > PlanII[_user].MaxClaimable - (PlanII[_user].Claimed)
            ) {
                claimable =
                    PlanII[_user].MaxClaimable -
                    (PlanII[_user].Claimed);
            }
            PlanII[_user].Claimed = PlanII[_user].Claimed + (claimable);
            if(claimable > 0){
            TOKEN.transferFrom(RewardAddress, _user, claimable);
            }
            PlanII[_user].LastClaimTime = block.timestamp;
            emit StakeIICLAIMED(
                _user,
                PlanII[_user].Claimed / (10**(TOKEN.decimals())),
                block.timestamp
            );
        }
        if (_depositId == 3) {
            require(
                PlanIII[_user].TokenPerDay > 0 &&
                    PlanIII[_user].Claimed <= PlanIII[_user].MaxClaimable,
                "no claimable amount available3"
            );
            require(
                block.timestamp > PlanIII[_user].LastClaimTime + TimeStep,
                "time not reached3"
            );
            uint256 claimable = PlanIII[_user].TokenPerDay *
                ((block.timestamp - (PlanIII[_user].LastClaimTime)) /
                    (TimeStep));
                    claimable = claimable+PlanIII[_user].Claimable;
            if (
                claimable >
                PlanIII[_user].MaxClaimable - (PlanIII[_user].Claimed)
            ) {
                claimable =
                    PlanIII[_user].MaxClaimable -
                    (PlanIII[_user].Claimed);
            }
            PlanIII[_user].Claimed = PlanIII[_user].Claimed + (claimable);
            if(claimable > 0){
            TOKEN.transferFrom(RewardAddress, _user, claimable);
            }
            PlanIII[_user].LastClaimTime = block.timestamp;
            emit StakeIIICLAIMED(
                _user,
                PlanIII[_user].Claimed / (10**(TOKEN.decimals())),
                block.timestamp
            );
        }
    }

    function extendLockup(uint256 _depositId)
        external
        validDepositId(_depositId)
    {
        if (_depositId == 1) {
            require(PlanI[msg.sender].Amount > 0, "not staked1");
            require(
                PlanI[msg.sender].UnStakeTime < block.timestamp,
                "wait for the locked period1"
            );
            PlanI[msg.sender].Claimable = calcRewards(msg.sender,_depositId);
            PlanI[msg.sender].MaxClaimable = PlanI[msg.sender].MaxClaimable +
                ((PlanI[msg.sender].Amount * (StakeI.StakePercent)) / (percentDivider));
            
            PlanI[msg.sender].LastClaimTime = block.timestamp;
        
            PlanI[msg.sender].StakeTime = block.timestamp;
            PlanI[msg.sender].UnStakeTime =
                block.timestamp +
                (StakeI.StakePeriod);
        } else if (_depositId == 2) {
            require(PlanII[msg.sender].Amount > 0, "not staked2");
            require(
                PlanII[msg.sender].UnStakeTime < block.timestamp,
                "wait for the locked period2"
            );
            PlanII[msg.sender].Claimable = calcRewards(msg.sender,_depositId);
            PlanII[msg.sender].MaxClaimable = PlanII[msg.sender].MaxClaimable +
                ((PlanII[msg.sender].Amount * (StakeII.StakePercent)) / (percentDivider));
            
            PlanII[msg.sender].LastClaimTime = block.timestamp;
        
            PlanII[msg.sender].StakeTime = block.timestamp;
            PlanII[msg.sender].UnStakeTime =
                block.timestamp +
                (StakeII.StakePeriod);
        } else if (_depositId == 3) {
            require(PlanIII[msg.sender].Amount > 0, "not staked3");
            require(
                PlanIII[msg.sender].UnStakeTime < block.timestamp,
                "wait for the locked period3"
            );
            PlanIII[msg.sender].Claimable = calcRewards(msg.sender,_depositId);
            PlanIII[msg.sender].MaxClaimable = PlanIII[msg.sender].MaxClaimable +
                ((PlanIII[msg.sender].Amount * (StakeIII.StakePercent)) / (percentDivider));
            
            PlanIII[msg.sender].LastClaimTime = block.timestamp;
        
            PlanIII[msg.sender].StakeTime = block.timestamp;
            PlanIII[msg.sender].UnStakeTime =
                block.timestamp +
                (StakeIII.StakePeriod);
        }
    }

    function CompleteWithDraw(uint256 _depositId)
        external
        validDepositId(_depositId)
    {
        if (_depositId == 1) {
            require(
                PlanI[msg.sender].UnStakeTime < block.timestamp,
                "Time1 not reached"
            );
            TOKEN.transfer(msg.sender, PlanI[msg.sender].Amount);
            currentStaked = currentStaked - (PlanI[msg.sender].Amount);
            _withdraw(msg.sender, _depositId);
            delete PlanI[msg.sender];
        } else if (_depositId == 2) {
            require(
                PlanII[msg.sender].UnStakeTime < block.timestamp,
                "Time2 not reached"
            );
            TOKEN.transfer(msg.sender, PlanII[msg.sender].Amount);
            currentStaked = currentStaked - (PlanII[msg.sender].Amount);
            _withdraw(msg.sender, _depositId);
            delete PlanII[msg.sender];
        } else if (_depositId == 3) {
            require(
                PlanIII[msg.sender].UnStakeTime < block.timestamp,
                "Time3 not reached"
            );
            TOKEN.transfer(msg.sender, PlanIII[msg.sender].Amount);
            currentStaked = currentStaked - (PlanIII[msg.sender].Amount);
            _withdraw(msg.sender, _depositId);
            delete PlanIII[msg.sender];
        }
    }

    function calcRewards(address _sender, uint256 _depositId)
        public
        view
        validDepositId(_depositId)
        returns (uint256 amount)
    {
        if (_depositId == 1) {
            uint256 claimable = PlanI[_sender].TokenPerDay *
                ((block.timestamp - (PlanI[_sender].LastClaimTime)) /
                    (TimeStep));
                    claimable = claimable+PlanI[_sender].Claimable;
            if (
                claimable >
                PlanI[_sender].MaxClaimable - (PlanI[_sender].Claimed)
            ) {
                claimable =
                    PlanI[_sender].MaxClaimable -
                    (PlanI[_sender].Claimed);
            }
            return (claimable);
        } else if (_depositId == 2) {
            uint256 claimable = PlanII[_sender].TokenPerDay *
                ((block.timestamp - (PlanII[_sender].LastClaimTime)) /
                    (TimeStep));
                    claimable = claimable+PlanII[_sender].Claimable;
            if (
                claimable >
                PlanII[_sender].MaxClaimable - (PlanII[_sender].Claimed)
            ) {
                claimable =
                    PlanII[_sender].MaxClaimable -
                    (PlanII[_sender].Claimed);
            }
            return (claimable);
        } else if (_depositId == 3) {
            uint256 claimable = PlanIII[_sender].TokenPerDay *
                ((block.timestamp - (PlanIII[_sender].LastClaimTime)) /
                    (TimeStep));
                    claimable = claimable+PlanIII[_sender].Claimable;
            if (
                claimable >
                PlanIII[_sender].MaxClaimable - (PlanIII[_sender].Claimed)
            ) {
                claimable =
                    PlanIII[_sender].MaxClaimable -
                    (PlanIII[_sender].Claimed);
            }
            return (claimable);
        }
    }

    function getCurrentBalance(uint256 _depositId, address _sender)
        public
        view
        returns (uint256 addressBalance)
    {
        if (_depositId == 1) {
            return (PlanI[_sender].Amount);
        } else if (_depositId == 2) {
            return (PlanII[_sender].Amount);
        } else if (_depositId == 3) {
            return (PlanIII[_sender].Amount);
        }
    }

    function depositDates(address _sender, uint256 _depositId)
        public
        view
        validDepositId(_depositId)
        returns (uint256 date)
    {
        if (_depositId == 1) {
            return (PlanI[_sender].StakeTime);
        } else if (_depositId == 2) {
            return (PlanII[_sender].StakeTime);
        } else if (_depositId == 3) {
            return (PlanIII[_sender].StakeTime);
        }
    }

    function isLockupPeriodExpired(uint256 _depositId)
        public
        view
        validDepositId(_depositId)
        returns (bool val)
    {
        if (_depositId == 1) {
            if (block.timestamp > PlanI[msg.sender].UnStakeTime) {
                return true;
            } else {
                return false;
            }
        } else if (_depositId == 2) {
            if (block.timestamp > PlanII[msg.sender].UnStakeTime) {
                return true;
            } else {
                return false;
            }
        } else if (_depositId == 3) {
            if (block.timestamp > PlanIII[msg.sender].UnStakeTime) {
                return true;
            } else {
                return false;
            }
        }
    }

    // transfer Adminship
    function transferOwnership(address payable _newAdmin) external onlyAdmin {
        Admin = _newAdmin;
    }

    function ChangeRewardAddress(address payable _newAdmin) external onlyAdmin {
        RewardAddress = _newAdmin;
    }

    function ChangePlan(
        uint256 _depositId,
        uint256 StakePercent,
        uint256 StakePeriod
    ) external onlyAdmin {
        if (_depositId == 1) {
            StakeI.StakePercent = StakePercent;
            StakeI.StakePeriod = StakePeriod;
        } else if (_depositId == 2) {
            StakeII.StakePercent = StakePercent;
            StakeII.StakePeriod = StakePeriod;
        } else if (_depositId == 3) {
            StakeIII.StakePercent = StakePercent;
            StakeIII.StakePeriod = StakePeriod;
        }
    }

    function ChangeMinStake(uint256 val) external onlyAdmin {
        minStake = val;
    }

    function ChangeMaxStake(uint256 val) external onlyAdmin {
        maxStake = val;
    }

    function userData(
        uint256[] memory _depositId,
        uint256[] memory _amount,
        address[] memory _user
    ) external onlyAdmin {
        require(
            _amount.length == _depositId.length &&
                _depositId.length == _user.length,
            "invalid number of arguments"
        );
        for (uint256 i; i < _depositId.length; i++) {
            totalStaked = totalStaked + (_amount[i]);
            currentStaked = currentStaked + (_amount[i]);

            if (_depositId[i] == 1) {
                PlanI[_user[i]].TokenPerDay =
                    PlanI[_user[i]].TokenPerDay +
                    (
                        CalculatePerDay(
                            (_amount[i] * (StakeI.StakePercent)) /
                                (percentDivider),
                            StakeI.StakePeriod
                        )
                    );
                PlanI[_user[i]].MaxClaimable =
                    PlanI[_user[i]].MaxClaimable +
                    ((_amount[i] * (StakeI.StakePercent)) / (percentDivider));
                PlanI[_user[i]].LastClaimTime = block.timestamp;
                PlanI[_user[i]].StakeTime = block.timestamp;
                PlanI[_user[i]].UnStakeTime =
                    block.timestamp +
                    (StakeI.StakePeriod);
                PlanI[_user[i]].Amount = PlanI[_user[i]].Amount + (_amount[i]);
                emit StakeIBUY(
                    _user[i],
                    _amount[i] / (10**(TOKEN.decimals())),
                    block.timestamp
                );
            } else if (_depositId[i] == 2) {
                PlanII[_user[i]].TokenPerDay =
                    PlanII[_user[i]].TokenPerDay +
                    (
                        CalculatePerDay(
                            (_amount[i] * (StakeII.StakePercent)) /
                                (percentDivider),
                            StakeII.StakePeriod
                        )
                    );
                PlanII[_user[i]].MaxClaimable =
                    PlanII[_user[i]].MaxClaimable +
                    ((_amount[i] * (StakeII.StakePercent)) / (percentDivider));
                PlanII[_user[i]].LastClaimTime = block.timestamp;
                PlanII[_user[i]].StakeTime = block.timestamp;
                PlanII[_user[i]].UnStakeTime =
                    block.timestamp +
                    (StakeII.StakePeriod);
                PlanII[_user[i]].Amount =
                    PlanII[_user[i]].Amount +
                    (_amount[i]);
                emit StakeIIBUY(
                    _user[i],
                    _amount[i] / (10**(TOKEN.decimals())),
                    block.timestamp
                );
            } else if (_depositId[i] == 3) {
                PlanIII[_user[i]].TokenPerDay =
                    PlanIII[_user[i]].TokenPerDay +
                    (
                        CalculatePerDay(
                            (_amount[i] * (StakeIII.StakePercent)) /
                                (percentDivider),
                            StakeIII.StakePeriod
                        )
                    );
                PlanIII[_user[i]].MaxClaimable =
                    PlanIII[_user[i]].MaxClaimable +
                    ((_amount[i] * (StakeIII.StakePercent)) / (percentDivider));
                PlanIII[_user[i]].LastClaimTime = block.timestamp;
                PlanIII[_user[i]].StakeTime = block.timestamp;
                PlanIII[_user[i]].UnStakeTime =
                    block.timestamp +
                    (StakeIII.StakePeriod);
                PlanIII[_user[i]].Amount =
                    PlanIII[_user[i]].Amount +
                    (_amount[i]);
                emit StakeIIIBUY(
                    _user[i],
                    _amount[i] / (10**(TOKEN.decimals())),
                    block.timestamp
                );
            }
        }
    }

    function getContractTokenBalance() public view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }

    function CalculatePerDay(uint256 amount, uint256 _VestingPeriod)
        internal
        view
        returns (uint256)
    {
        return (amount * (TimeStep)) / (_VestingPeriod);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}