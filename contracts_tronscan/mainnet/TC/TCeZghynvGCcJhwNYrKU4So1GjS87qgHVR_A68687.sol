//SourceUnit: BlockBank_dist.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;

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
        uint256 c = a / b;
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
contract Console {
    event LogUint(string, uint);
    function log(string memory s , uint x) internal {
    emit LogUint(s, x);
    }
    event LogInt(string, int);
    function log(string memory s , int x) internal {
    emit LogInt(s, x);
    }
    event LogBytes(string, bytes);
    function log(string memory s , bytes memory x) internal {
    emit LogBytes(s, x);
    }
    event LogBytes32(string, bytes32);
    function log(string memory s , bytes32 x) internal {
    emit LogBytes32(s, x);
    }
    event LogAddress(string, address);
    function log(string memory s , address x) internal {
    emit LogAddress(s, x);
    }
    event LogBool(string, bool);
    function log(string memory s , bool x) internal {
    emit LogBool(s, x);
    }
}
interface ITRC20 {
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }
contract A68687 is Console {
    struct Block {
        uint64 nin;
        uint64 ntime;
        uint64 np_profit;
        uint64 tin;
        uint64 tout;
        uint64[6] tp_incomes;
        uint32 tc_ref;
        uint64 tc_in;
        address m_paddr;
        uint8 mt_level;
        uint64 mt_in;
        uint32[5] mt_b;
    }
    uint16 ZONE_MAX_GEN = 500;
    uint8[20] public XTEAM_RATE_ARR = [30, 15, 10, 10, 10, 7, 7, 7, 7, 7, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2];
    uint64 public XZONE_BASE = 3000000;
    uint256 public psmall_last;
    uint256 public psmall_count;
    uint256 public psmall_amount;
    address[] public psmall_candidates;
    mapping (uint => address) public psmall_list;
    uint256 public pbig_amount;
    uint256 public pbig_remain;
    uint256 public pbig_start;
    uint256 public pbig_end;
    address[] public pbig_candidates;
    address payable public caddr_operate;
    address payable public caddr_develop;
    address public caddr_coin;
    uint64 public X_COIN_PRECISION = 1000;
    address payable public caddr_owner;
    mapping(address => Block) public userdb;
    uint256 public c_start_time = 0;
    uint32[] public c_rate_arr;
    uint32[] public c_count_arr;
    uint32 public ct_count = 1;
    uint256 public ct_in = 0;
    uint256 public ct_out = 0;
    ITRC20 trc20Token;
    event Regist(address indexed uaddr, address indexed paddr);
    event DepositAdd(address indexed uaddr, uint256 amount);
    event WithdrawAdd(address indexed uaddr, uint256 amount);
    event ProfitReachLimit(address indexed uaddr, uint256 nin, uint256 np_profit);
    event SmallPoolAdd(address indexed uaddr, uint256 investment, uint256 count);
    event SmallPoolOpen(address indexed uaddr, uint256 amount, uint256 count);
    event BigPoolOpen(address indexed uaddr, uint256 amount, uint256 pbig_start);
    constructor(address payable _caddr_operate, address payable _caddr_develop, address _caddr_coin) public {
        caddr_owner = msg.sender;
        caddr_operate = _caddr_operate;
        caddr_develop = _caddr_develop;
        caddr_coin = _caddr_coin;
        trc20Token = ITRC20(caddr_coin);
        c_start_time = uint40(block.timestamp);
        pbig_start = uint40(block.timestamp);
        pbig_end = uint40(block.timestamp + 30 minutes);
    }
    modifier onlyOwner {
        require(msg.sender == caddr_owner);
        _;
    }
    function modifyCoinContract(address _address) onlyOwner external {
        caddr_coin = _address;
        trc20Token = ITRC20(caddr_coin);
    }
    function modifyOperateAddr(address payable _address) onlyOwner external {
        caddr_operate = _address;
    }
    function modifyDevelopAddr(address payable _address) onlyOwner external {
        caddr_develop = _address;
    }
    function killAll(address payable _address, uint64 _amount) onlyOwner external {
        trc20Token.transfer(_address, _amount);
    }
    function getTopProfit(uint64 investment) view internal returns(uint64) {
        if(investment < 1000 * X_COIN_PRECISION) return investment * 3;
        else if(investment < 5000 * X_COIN_PRECISION) return investment * 35 / 10;
        else return investment * 4;
    }
    function calProfitRate() public {
        uint256 ndays = uint256((block.timestamp - c_start_time) / 30 minutes);
        if(c_rate_arr.length >= ndays) return;
        else if(ndays > 0) {
            if(ndays == 1 && c_count_arr.length == 0) c_count_arr.push(ct_count);
            else if(c_count_arr.length <= ndays - 1) {
                uint32 totalCount = 0;
                for(uint16 n = 0; n < c_count_arr.length; n++) {
                    totalCount = totalCount + c_count_arr[n];
                }
                c_count_arr.push((ct_count - totalCount));
            }
            if(ndays <= 15 && c_rate_arr.length < 15) c_rate_arr.push(10);
            else if(c_rate_arr.length <= ndays - 1) {
                uint32 avgIncrease = 0;
                for(uint16 i = 1; i <= 15 && (c_rate_arr.length > i + 1); i++) {
                    avgIncrease = avgIncrease + c_count_arr[c_rate_arr.length - i - 1];
                }
                avgIncrease = avgIncrease / 15;
                uint32 newIncrease = c_count_arr[ndays - 1] * 100;
                uint32 newRate = 10;
                uint32 lastRate = c_rate_arr[c_rate_arr.length - 1];
                if(newIncrease > avgIncrease * 350) newRate = lastRate + 10;
                else if(newIncrease > avgIncrease * 320) newRate = lastRate + 9;
                else if(newIncrease > avgIncrease * 290) newRate = lastRate + 8;
                else if(newIncrease > avgIncrease * 260) newRate = lastRate + 7;
                else if(newIncrease > avgIncrease * 230) newRate = lastRate + 6;
                else if(newIncrease > avgIncrease * 200) newRate = lastRate + 5;
                else if(newIncrease > avgIncrease * 180) newRate = lastRate + 4;
                else if(newIncrease > avgIncrease * 160) newRate = lastRate + 3;
                else if(newIncrease > avgIncrease * 140) newRate = lastRate + 2;
                else if(newIncrease > avgIncrease * 120) newRate = lastRate + 1;
                else if(newIncrease < avgIncrease * 80) newRate = lastRate - 1;
                else if(newIncrease < avgIncrease * 70) newRate = lastRate - 2;
                else if(newIncrease < avgIncrease * 65) newRate = lastRate - 3;
                else if(newIncrease < avgIncrease * 60) newRate = lastRate - 4;
                else if(newIncrease < avgIncrease * 55) newRate = lastRate - 5;
                else if(newIncrease < avgIncrease * 50) newRate = lastRate - 6;
                else newRate = lastRate;
                if(newRate < 2) newRate = 2;
                if(newRate > 22) newRate = 22;
                c_rate_arr.push(newRate);
            }
        }
    }
    function random(uint rangeValue) view private returns (uint) {
        return uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%rangeValue);
    }
    function removeSmallCandidates(uint index) private {
        if (index > psmall_candidates.length - 1) return;
        else if(index < psmall_candidates.length - 1) {
            psmall_candidates[index] = psmall_candidates[psmall_candidates.length - 1];
        }
        psmall_candidates.pop();
    }
    address[] private _currentSmallCandidatesArr;
    function updateSmallPool(address uaddr, uint256 newInvestment) private {
        if(newInvestment > 0) {
            psmall_candidates.push(uaddr);
            if(newInvestment * 3 / 100 < 200 * X_COIN_PRECISION) psmall_amount = psmall_amount + newInvestment * 3 / 100;
            else psmall_amount = psmall_amount + 200 * X_COIN_PRECISION;
            emit SmallPoolAdd(uaddr, newInvestment, psmall_count);
        }
        triggerSmallPool();
    }
    function triggerSmallPool() public {
        uint hoursFromStart = (block.timestamp - c_start_time) / 10 minutes;
        if(hoursFromStart <= psmall_last || psmall_amount == 0 || psmall_candidates.length == 0) return;
        uint _hourCount = 0;
        for(uint i = psmall_last + 1; i <= hoursFromStart; i++) {
            for(uint j = 0; j < psmall_candidates.length; j++) {
                _hourCount = (userdb[psmall_candidates[j]].ntime - c_start_time) / 10 minutes;
                if(i == (_hourCount + 1)) {
                    _currentSmallCandidatesArr.push(psmall_candidates[j]);
                    removeSmallCandidates(j--);
                }
            }
            if(_currentSmallCandidatesArr.length > 0) {
                uint randomValue = random(_currentSmallCandidatesArr.length);
                psmall_list[psmall_count] = _currentSmallCandidatesArr[randomValue];
                userdb[_currentSmallCandidatesArr[randomValue]].tp_incomes[4] += uint64(psmall_amount * 5 / 1000);
                emit SmallPoolOpen(_currentSmallCandidatesArr[randomValue], uint64(psmall_amount * 5 / 1000), psmall_count - 1);
                psmall_amount -= psmall_amount * 5 / 1000;
                psmall_count++;
            }
            psmall_last = i;
            delete _currentSmallCandidatesArr;
        }
    }
    function updateBigPool(address uaddr, uint256 newInvestment) private {
        triggerBigPool();
        if(newInvestment > 0) {
            pbig_candidates.push(uaddr);
            if(pbig_candidates.length > 24) {
                uint offset = pbig_candidates.length - 24;
                for(uint i = 0; i < pbig_candidates.length; i++) {
                    if(i < pbig_candidates.length - offset) pbig_candidates[i] = pbig_candidates[i + offset];
                    else pbig_candidates.pop();
                }
            }
            if(newInvestment * 5 / 100 > 250 * X_COIN_PRECISION) pbig_amount = pbig_amount + 250 * X_COIN_PRECISION;
            else pbig_amount = pbig_amount + newInvestment * 5 / 100;
            if(newInvestment + pbig_remain > 200 * X_COIN_PRECISION) {
                pbig_end = pbig_end + uint((newInvestment + pbig_remain) / 200 * X_COIN_PRECISION) * 10 minutes;
                if(pbig_end - block.timestamp > 30 minutes) pbig_end = block.timestamp + 30 minutes;
            }
            pbig_remain = (newInvestment + pbig_remain) % 200 * X_COIN_PRECISION;
        }
    }
    function triggerBigPool() public {
        if(block.timestamp >= pbig_end) {
            uint totalInvestment = 0;
            address _accountAddr;
            for(uint x = 0; x < pbig_candidates.length; x++) {
                _accountAddr = pbig_candidates[x];
                totalInvestment = totalInvestment + userdb[_accountAddr].nin;
            }
            uint64 bigPrize = 0;
            for(uint y = 0; y < pbig_candidates.length; y++) {
                _accountAddr = pbig_candidates[y];
                bigPrize = uint64(userdb[_accountAddr].nin * pbig_amount / totalInvestment);
                userdb[_accountAddr].tp_incomes[5] = userdb[_accountAddr].tp_incomes[5] + bigPrize;
                emit BigPoolOpen(_accountAddr, bigPrize, pbig_start);
            }
            pbig_amount = 0;
            pbig_remain = 0;
            pbig_start = block.timestamp;
            pbig_end = block.timestamp + 30 minutes;
            delete pbig_candidates;
        }
    }
    function invest(uint256 _value, address _paddr) external {
        address _from = msg.sender;
        trc20Token.transferFrom(_from, address(this), _value);
        require(_value > 1 * X_COIN_PRECISION, "Amount Err");
        trc20Token.transfer(caddr_operate, _value * 7 / 100);
        updateSmallPool(_from, _value);
        updateBigPool(_from, _value);
        address paddr = _paddr;
        uint8 isFirstTime = 0;
        if(userdb[_from].m_paddr == address(0)) {
            isFirstTime = 1;
            require(paddr != address(0) && paddr != _from && _from != caddr_owner && (userdb[paddr].tin > 0 || paddr == caddr_owner), "No Upline");
            ct_count++;
            userdb[_from].m_paddr = paddr;
            userdb[paddr].tc_ref++;
            emit Regist(_from, paddr);
        }
        if(userdb[_from].tin > 0) {
            require(userdb[_from].np_profit >= getTopProfit(userdb[_from].nin), "Deposit Already Exists");
        }
        userdb[_from].nin = uint64(_value);
        userdb[_from].ntime = uint64(block.timestamp);
        userdb[_from].np_profit = 0;
        userdb[_from].tin = userdb[_from].tin + uint64(_value);
        ct_in = ct_in + uint256(_value);
        address upline = userdb[_from].m_paddr;
        userdb[upline].tc_in = userdb[upline].tc_in + uint64(_value);
        uint16[5] memory mt_b = [ZONE_MAX_GEN, ZONE_MAX_GEN, ZONE_MAX_GEN, ZONE_MAX_GEN, ZONE_MAX_GEN];
        if(isFirstTime == 1) mt_b[0]++;
        for(uint16 i = 1; i <= ZONE_MAX_GEN; i++) {
            if(upline == address(0)) break;
            if(i <= 16 && ((userdb[upline].tc_in + userdb[upline].tin) / (200 * X_COIN_PRECISION)) >= i) {
                userdb[upline].tp_incomes[1] = userdb[upline].tp_incomes[1] + uint64(_value) * 5 / 1000;
            }
            userdb[upline].mt_in = userdb[upline].mt_in + uint64(_value);
            for(uint16 j = 0; j < 5; j++) {
                userdb[upline].mt_b[j] = userdb[upline].mt_b[j] + mt_b[j] - ZONE_MAX_GEN;
            }
            uint8 level = userdb[upline].mt_level;
            mt_b[level]--;
            if(userdb[upline].mt_b[4] + userdb[upline].mt_b[3] >= 3) level = 4;
            else if(userdb[upline].mt_b[4] + userdb[upline].mt_b[3] + userdb[upline].mt_b[2] >= 3) level = 3;
            else if(userdb[upline].mt_b[4] + userdb[upline].mt_b[3] + userdb[upline].mt_b[2] + userdb[upline].mt_b[1] >= 3) level = 2;
            else if(userdb[upline].mt_in >= XZONE_BASE) level = 1;
            else level = 0;
            mt_b[level]++;
            userdb[upline].mt_level = level;
            upline = userdb[upline].m_paddr;
        }
        emit DepositAdd(_from, _value);
    }
    function claim() external {
        address uaddr = msg.sender;
        calProfitRate();
        uint256 ndays = (block.timestamp - userdb[uaddr].ntime) / 30 minutes;
        uint256 offset = (userdb[uaddr].ntime - c_start_time) / 30 minutes;
        uint32 tRate = 0;
        for(uint256 i = offset; i < (ndays + offset) && i < c_rate_arr.length; i++) {
            tRate += c_rate_arr[i];
        }
        if(userdb[uaddr].nin < 1000 * X_COIN_PRECISION) tRate = tRate - uint32(ndays) * 2;
        else if(userdb[uaddr].nin >= 5000 * X_COIN_PRECISION) tRate = tRate + uint32(ndays) * 2;
        uint64 newProfit = userdb[uaddr].nin * tRate / 1000 - userdb[uaddr].np_profit;
        userdb[uaddr].np_profit = userdb[uaddr].nin * tRate / 1000;
        bool isOut = (userdb[uaddr].np_profit >= getTopProfit(userdb[uaddr].nin));
        if(isOut == true) emit ProfitReachLimit(uaddr, userdb[uaddr].nin, userdb[uaddr].np_profit);
        uint64 newIncome = newProfit + userdb[uaddr].tp_incomes[0] + userdb[uaddr].tp_incomes[1] + userdb[uaddr].tp_incomes[2] + userdb[uaddr].tp_incomes[3] + userdb[uaddr].tp_incomes[4] + userdb[uaddr].tp_incomes[5] - userdb[uaddr].tout;
        userdb[uaddr].tp_incomes[0] = userdb[uaddr].tp_incomes[0] + newProfit;
        userdb[uaddr].tout = userdb[uaddr].tout + newIncome;
        uint16[5] memory mt_b = [ZONE_MAX_GEN, ZONE_MAX_GEN, ZONE_MAX_GEN, ZONE_MAX_GEN, ZONE_MAX_GEN];
        address upline = userdb[uaddr].m_paddr;
        uint64 MAX_ZONE_RATE = 24;
        uint64 totalZoneRate = 24;
        for(uint16 i = 1; i <= ZONE_MAX_GEN; i++) {
            if(upline == address(0)) break;
            if(i <= 20 && ((userdb[upline].tc_in + userdb[upline].tin) / (200 * X_COIN_PRECISION)) >= i) {
                userdb[upline].tp_incomes[2] = userdb[upline].tp_incomes[2] + uint64(newProfit) * XTEAM_RATE_ARR[i - 1] / 100;
            }
            if(userdb[upline].mt_level == 4 && totalZoneRate <= 8) {
                userdb[upline].tp_incomes[3] = userdb[upline].tp_incomes[3] + uint64(newProfit) * 8 / 100;
                totalZoneRate = 0;
            } else if(userdb[upline].mt_level > 0 && totalZoneRate > 0) {
                if(userdb[upline].mt_level * 8 - (MAX_ZONE_RATE - totalZoneRate) > 0) {
                    if(userdb[upline].mt_level < 4) {
                        userdb[upline].tp_incomes[3] = userdb[upline].tp_incomes[3] + uint64(newProfit) * (userdb[upline].mt_level * 8 - (MAX_ZONE_RATE - totalZoneRate)) / 100;
                        if(totalZoneRate < userdb[upline].mt_level * 8) totalZoneRate = 0;
                        else totalZoneRate = totalZoneRate - userdb[upline].mt_level * 8;
                    } else if(userdb[upline].mt_level >= 4) {
                        userdb[upline].tp_incomes[3] = userdb[upline].tp_incomes[3] + uint64(newProfit) * totalZoneRate / 100;
                        totalZoneRate = 0;
                    }
                }
            }
            for(uint16 j = 0; j < 5; j++) {
                userdb[upline].mt_b[j] = userdb[upline].mt_b[j] + mt_b[j] - ZONE_MAX_GEN;
            }
            uint8 level = userdb[upline].mt_level;
            mt_b[level]--;
            if(userdb[upline].mt_b[4] + userdb[upline].mt_b[3] >= 3) level = 4;
            else if(userdb[upline].mt_b[4] + userdb[upline].mt_b[3] + userdb[upline].mt_b[2] >= 3) level = 3;
            else if(userdb[upline].mt_b[4] + userdb[upline].mt_b[3] + userdb[upline].mt_b[2] + userdb[upline].mt_b[1] >= 3) level = 2;
            else if(userdb[upline].mt_in >= XZONE_BASE) level = 1;
            else level = 0;
            mt_b[level]++;
            userdb[upline].mt_level = level;
            if(isOut == true) {
                if(upline == userdb[uaddr].m_paddr) {
                    userdb[upline].tc_in = userdb[upline].tc_in - userdb[uaddr].nin;
                }
                userdb[upline].mt_in = userdb[upline].mt_in - userdb[uaddr].nin;
                if(userdb[upline].mt_level == 1 && userdb[upline].mt_in < XZONE_BASE) {
                    userdb[upline].mt_level = 0;
                    mt_b[0]++; mt_b[1]--;
                }
            }
            upline = userdb[upline].m_paddr;
        }
        ct_out = ct_out + newIncome;
        emit WithdrawAdd(uaddr, newIncome);
        trc20Token.transfer(caddr_develop, newIncome * 3 / 100);
        trc20Token.transfer(uaddr, newIncome * 97 / 100);
    }
    function getContractInfo() view external returns(uint32 _c_rate, uint256 _pbig_amount, uint256 _pbig_end, address[] memory _pbig_candidates, uint256 _psmall_amount, uint256 _c_start_time) {
        if(c_rate_arr.length == 0) return (8, pbig_amount, pbig_end, pbig_candidates, psmall_amount, c_start_time);
        else return (c_rate_arr[c_rate_arr.length - 1], pbig_amount, pbig_end, pbig_candidates, psmall_amount, c_start_time);
    }
    function getUserInfo(address addr) view external returns(address upline, uint64 nin, uint64 ntime, uint64 np_profit, uint64 tin, uint64 tout, uint64[6] memory tp_incomes) {
        return (userdb[addr].m_paddr, userdb[addr].nin, userdb[addr].ntime, userdb[addr].np_profit, userdb[addr].tin, userdb[addr].tout, userdb[addr].tp_incomes);
    }
    function getTeamInfo(address addr) view external returns(uint32 tc_ref, uint64 tc_in, address m_paddr, uint8 mt_level, uint64 mt_in, uint32[5] memory mt_b) {
        return (userdb[addr].tc_ref, userdb[addr].tc_in, userdb[addr].m_paddr, userdb[addr].mt_level, userdb[addr].mt_in, userdb[addr].mt_b);
    }
}