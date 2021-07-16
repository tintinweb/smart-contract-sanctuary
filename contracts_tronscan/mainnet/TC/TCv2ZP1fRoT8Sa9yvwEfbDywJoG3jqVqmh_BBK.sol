//SourceUnit: BlockBank_dist.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;

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

contract BBK {
    struct Block {
        uint64 nin;
        uint64 ntime;
        uint64 np_profit;
        uint64 tin;
        uint64 tout;
        uint64[6] tp_incomes;
        uint64 mt_in;
        uint64 tc_in;
        uint32 tc_ref;
        uint32 mt_level;
        uint32[3] mt_b;
        address m_paddr;
    }

    uint16[20] private XTEAM_RATE_ARR = [30, 15, 10, 10, 10, 7, 7, 7, 7, 7, 4, 4, 4, 4, 4, 2, 2, 2, 2, 2];
    uint64 private XZONE_BASE = 150000;
    uint64 private XZONE_MAX_GEN = 500;
    uint64 private psmall_last;
    address[] public psmall_candidates;
    uint64 private psmall_amount;
    uint64 private pbig_start;
    uint64 private pbig_end;
    uint64 private pbig_amount;
    address[] public pbig_candidates;
    uint64 private pbig_remain;
    uint64 private c_start_time;
    uint64 private ct_count = 1;
    uint64 private X_COIN_PRECISION = 1000000;
    address private caddr_coin;
    address payable private caddr_operate;
    address payable private caddr_develop;
    address payable private caddr_root;
    mapping (address => Block) private userdb;
    mapping (address => bool) private isBlackListed;
    uint64 private ct_in;
    uint64 private ct_out;
    uint64 private ct_in_operate;
    uint64 private ct_out_develop;
    uint64[] private c_rate_arr;
    uint64[] private c_count_arr;

    ITRC20 trc20Token;

    event DepositAdd(address indexed uaddr, address indexed paddr, uint256 amount);
    event WithdrawAdd(address indexed uaddr, uint256 amount);
    event ProfitReachLimit(address indexed uaddr, uint256 nin, uint256 np_profit);
    event SmallPoolOpen(address indexed uaddr, uint256 amount, uint256 count);
    event BigPoolOpen(address indexed uaddr, uint256 amount, uint256 pbig_start);

    constructor(address payable _caddr_operate, address payable _caddr_develop, address _caddr_coin) public {
        caddr_root = msg.sender;
        caddr_operate = _caddr_operate;
        caddr_develop = _caddr_develop;
        caddr_coin = _caddr_coin;
        trc20Token = ITRC20(caddr_coin);
        c_start_time = uint64(block.timestamp);
        pbig_start = uint64(block.timestamp);
        pbig_end = uint64(block.timestamp + 24 hours);
    }

    modifier onlyOwner {
        require((msg.sender == caddr_operate || msg.sender == caddr_develop), 'Permission Denied');
        _;
    }

    function initOperateAddr(address payable _address) onlyOwner external {
        caddr_operate = _address;
    }

    function initDevelopAddr(address payable _address) onlyOwner external {
        caddr_develop = _address;
    }

    function initZone(uint64 _XZONE_BASE, uint64 _XZONE_MAX_GEN) onlyOwner external {
        XZONE_BASE = _XZONE_BASE;
        XZONE_MAX_GEN = _XZONE_MAX_GEN;
    }

    function calForOperate() external {
        require(msg.sender == caddr_operate, 'Permission Denied');
        uint256 _value = ct_in * 7 / 100 - ct_in_operate;
        trc20Token.transfer(caddr_operate, _value);
        ct_in_operate = ct_in * 7 / 100;
    }

    function calForDevelop() external {
        require(msg.sender == caddr_develop, 'Permission Denied');
        uint256 _value = ct_out * 3 / 100 - ct_out_develop;
        trc20Token.transfer(caddr_develop, _value);
        ct_out_develop = ct_out * 3 / 100;
    }

    function getTopProfit(uint64 investment) view internal returns(uint64) {
        if(investment < 1000 * X_COIN_PRECISION) return investment * 3;
        else if(investment < 5000 * X_COIN_PRECISION) return investment * 35 / 10;
        else return investment * 4;
    }

    function calProfitRate() public returns(uint _ndays, uint64 _ct_count, uint64 _ct_rate) {
        uint ndays = (block.timestamp - c_start_time) / 24 hours;
        if(c_rate_arr.length >= ndays || ndays == 0) return (ndays, 0, 0);
        if(c_rate_arr.length < 15) c_rate_arr.push(10);
        else if(c_rate_arr.length <= ndays - 1) {
            uint ratio = (ct_count - c_count_arr[c_count_arr.length - 1]) * 100 * 15;
            if(c_count_arr[c_count_arr.length - 1] > c_count_arr[c_count_arr.length - 15]) ratio = uint(ratio / (c_count_arr[c_count_arr.length - 1] - c_count_arr[c_count_arr.length - 15]));
            else ratio = 100;
            if(ratio > 350) c_rate_arr.push(20);
            else if(ratio > 320) c_rate_arr.push(19);
            else if(ratio > 290) c_rate_arr.push(18);
            else if(ratio > 260) c_rate_arr.push(17);
            else if(ratio > 230) c_rate_arr.push(16);
            else if(ratio > 200) c_rate_arr.push(15);
            else if(ratio > 180) c_rate_arr.push(14);
            else if(ratio > 160) c_rate_arr.push(13);
            else if(ratio > 140) c_rate_arr.push(12);
            else if(ratio > 120) c_rate_arr.push(11);
            else if(ratio >= 80) c_rate_arr.push(10);
            else if(ratio <= 50) c_rate_arr.push(4);
            else if(ratio < 55) c_rate_arr.push(5);
            else if(ratio < 60) c_rate_arr.push(6);
            else if(ratio < 65) c_rate_arr.push(7);
            else if(ratio < 70) c_rate_arr.push(8);
            else if(ratio < 80) c_rate_arr.push(9);
        }
        if(c_count_arr.length <= ndays - 1) c_count_arr.push(ct_count);
        return (ndays, c_count_arr[c_count_arr.length - 1], c_rate_arr[c_rate_arr.length - 1]);
    }

    function triggerSmallPool() public {
        if((block.timestamp - c_start_time) <= psmall_last * 1 hours) return;
        if(psmall_amount == 0 || psmall_candidates.length == 0) return;
        psmall_last = uint64((block.timestamp - c_start_time) / 1 hours);
        uint randomValue = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % psmall_candidates.length);
        if(randomValue > 0 && randomValue >= psmall_candidates.length) randomValue = psmall_candidates.length - 1;
        userdb[psmall_candidates[randomValue]].tp_incomes[4] += uint64(psmall_amount * 5 / 1000);
        emit SmallPoolOpen(psmall_candidates[randomValue], uint(psmall_amount * 5 / 1000), psmall_last);
        psmall_amount -= (psmall_amount * 5 / 1000);
        delete psmall_candidates;
    }

    function triggerBigPool() public {
        if(block.timestamp >= pbig_end) {
            uint totalInvestment = 0;
            uint count;
            uint index;
            address _accountAddr;
            for(index = 1; index <= pbig_candidates.length && count < 24; index++) {
                _accountAddr = pbig_candidates[pbig_candidates.length - index];
                if(userdb[_accountAddr].ntime < pbig_end) {
                    totalInvestment += userdb[_accountAddr].nin;
                    count++;
                }
            }
            uint bigPrize;
            count = 0;
            for(index = 1; index <= pbig_candidates.length && count < 24; index++) {
                _accountAddr = pbig_candidates[pbig_candidates.length - index];
                if(userdb[_accountAddr].ntime < pbig_end) {
                    bigPrize = uint64(userdb[_accountAddr].nin * pbig_amount / totalInvestment);
                    userdb[_accountAddr].tp_incomes[5] += uint64(bigPrize);
                    emit BigPoolOpen(_accountAddr, bigPrize, pbig_start);
                    count++;
                }
            }
            pbig_amount = 0;
            pbig_remain = 0;
            pbig_start = pbig_end;
            pbig_end = uint64(block.timestamp + 24 hours);
            delete pbig_candidates;
        }
    }

    function invest(uint256 _value, address _paddr) external {
        trc20Token.transferFrom(msg.sender, address(this), _value);
        require(_value >= 1 * X_COIN_PRECISION, "Amount Error");
        if(userdb[msg.sender].m_paddr == address(0)) {
            require(_paddr != address(0) && _paddr != msg.sender && msg.sender != caddr_root && (userdb[_paddr].nin > 0 || _paddr == caddr_root), "No Upline");
            ct_count++;
            userdb[msg.sender].m_paddr = _paddr;
            userdb[_paddr].tc_ref++;
        } else if(userdb[msg.sender].nin > 0) {
            require(userdb[msg.sender].np_profit >= getTopProfit(userdb[msg.sender].nin), "Deposit Already Exists");
            emit ProfitReachLimit(msg.sender, userdb[msg.sender].nin, userdb[msg.sender].np_profit);
            _paddr = userdb[msg.sender].m_paddr;
            userdb[msg.sender].tp_incomes[0] += userdb[msg.sender].np_profit;
            userdb[msg.sender].np_profit = 0;
            userdb[msg.sender].tin += userdb[msg.sender].nin;
        }
        userdb[msg.sender].nin = uint64(_value);
        userdb[msg.sender].ntime = uint64(block.timestamp);
        ct_in += uint64(_value);
        address upline = userdb[msg.sender].m_paddr;
        userdb[upline].tc_in += uint64(_value);
        uint i;
        for(i = 1; i <= 20; i++) {
            if(upline == address(0)) break;
            if(i <= 16 && ((userdb[upline].tc_in + userdb[upline].nin) >= i * 200 * X_COIN_PRECISION)) {
                userdb[upline].tp_incomes[1] += uint64(_value) * 5 / 1000;
            }
            userdb[upline].mt_in += uint64(_value);
            upline = userdb[upline].m_paddr;
        }
        uint mtLevel;
        uint updateLevel = 0;
        upline = userdb[msg.sender].m_paddr;
        for(i = 20; i > 0; i--) {
            if(upline == address(0)) break;
            mtLevel = userdb[upline].mt_level;
            if(updateLevel > 0 && mtLevel <= updateLevel && updateLevel < 4) {
                userdb[upline].mt_b[updateLevel - 1]++;
                if(updateLevel > 1 && updateLevel < 4) userdb[upline].mt_b[updateLevel - 2]--;
            }
            if(mtLevel < 4 && userdb[upline].mt_b[2] >= 3) userdb[upline].mt_level = 4;
            else if(mtLevel < 3 && userdb[upline].mt_b[2] + userdb[upline].mt_b[1]>= 3) userdb[upline].mt_level = 3;
            else if(mtLevel < 2 && userdb[upline].mt_b[2] + userdb[upline].mt_b[1] + userdb[upline].mt_b[0] >= 3) userdb[upline].mt_level = 2;
            else if(mtLevel < 1 && userdb[upline].mt_in >= (XZONE_BASE * X_COIN_PRECISION)) userdb[upline].mt_level = 1;
            if(mtLevel < userdb[upline].mt_level && userdb[upline].mt_level < 4) {
                if(updateLevel < userdb[upline].mt_level) updateLevel = userdb[upline].mt_level;
                i = 20;
            } else if(updateLevel > 0 && mtLevel >= updateLevel) break;
            upline = userdb[upline].m_paddr;
        }
        emit DepositAdd(msg.sender, _paddr, _value);
        psmall_candidates.push(msg.sender);
        if(_value * 3 < 20000 * X_COIN_PRECISION) psmall_amount += uint64(_value * 3 / 100);
        else psmall_amount += uint64(200 * X_COIN_PRECISION);
        pbig_candidates.push(msg.sender);
        if(_value * 5 > 25000 * X_COIN_PRECISION) pbig_amount += uint64(250 * X_COIN_PRECISION);
        else pbig_amount += uint64(_value * 5 / 100);
        if(_value + pbig_remain > 200 * X_COIN_PRECISION) {
            pbig_end = pbig_end + uint64((_value + pbig_remain) / 200 / X_COIN_PRECISION) * 1 hours;
            if(pbig_end - block.timestamp > 24 hours) pbig_end = uint64(block.timestamp + 24 hours);
        }
        pbig_remain = uint64((_value + pbig_remain) % (200 * X_COIN_PRECISION));
    }

    function claim() external {
        require(isBlackListed[msg.sender] == false);
        uint topProfit = getTopProfit(userdb[msg.sender].nin);
        uint newProfit;
        if(userdb[msg.sender].np_profit < topProfit) {
            uint ndays = (block.timestamp - userdb[msg.sender].ntime) / 24 hours;
            uint offset = (userdb[msg.sender].ntime - c_start_time) / 24 hours;
            uint tRate;
            if(ndays > 0 && c_rate_arr.length < ndays) calProfitRate();
            if(offset > c_rate_arr.length) ndays = 0;
            else if(ndays + offset > c_rate_arr.length) ndays = c_rate_arr.length - offset;
            for(uint i = offset; i < (ndays + offset) && i < c_rate_arr.length; i++) {
                tRate += c_rate_arr[i];
            }
            if(userdb[msg.sender].nin < 1000 * X_COIN_PRECISION) tRate = tRate - ndays * 2;
            else if(userdb[msg.sender].nin >= 5000 * X_COIN_PRECISION) tRate = tRate + ndays * 2;
            newProfit = userdb[msg.sender].nin * tRate / 1000 - userdb[msg.sender].np_profit;
            if(userdb[msg.sender].np_profit + newProfit > topProfit) newProfit = topProfit - userdb[msg.sender].np_profit;
            userdb[msg.sender].np_profit += uint64(newProfit);
        }
        if(newProfit > 0) {
            address upline = userdb[msg.sender].m_paddr;
            uint totalZoneRate = 24;
            uint mt_level;
            uint min_level;
            for(uint i = 1; i <= XZONE_MAX_GEN; i++) {
                if(upline == address(0)) break;
                if(i <= 20 && (userdb[upline].tc_in + userdb[upline].nin) >= i * 200 * X_COIN_PRECISION) {
                    userdb[upline].tp_incomes[2] += uint64(newProfit * XTEAM_RATE_ARR[i - 1] / 100);
                }
                if(userdb[upline].mt_level > min_level) {
                    mt_level = userdb[upline].mt_level;
                    if(mt_level == 4 && totalZoneRate <= 8) {
                        userdb[upline].tp_incomes[3] += uint64(newProfit) * 8 / 100;
                        totalZoneRate = 0;
                    } else if(mt_level > 0 && totalZoneRate > 0 && mt_level * 8 > (24 - totalZoneRate)) {
                        if(mt_level < 4) {
                            userdb[upline].tp_incomes[3] += uint64(newProfit * (mt_level * 8 - (24 - totalZoneRate)) / 100);
                            if(totalZoneRate < mt_level * 8) totalZoneRate = 0;
                            else totalZoneRate -= mt_level * 8;
                        } else if(mt_level >= 4) {
                            userdb[upline].tp_incomes[3] += uint64(newProfit * totalZoneRate / 100);
                            totalZoneRate = 0;
                        }
                    }
                    min_level = mt_level;
                }
                upline = userdb[upline].m_paddr;
            }
        } else {
            triggerSmallPool();
            triggerBigPool();
        }
        uint totalIncome = userdb[msg.sender].np_profit + userdb[msg.sender].tp_incomes[0] + userdb[msg.sender].tp_incomes[1] + userdb[msg.sender].tp_incomes[2] + userdb[msg.sender].tp_incomes[3] + userdb[msg.sender].tp_incomes[4] + userdb[msg.sender].tp_incomes[5];
        uint newIncome = totalIncome - userdb[msg.sender].tout;
        require(ct_in * 9 / 10 > ct_out + newIncome + pbig_amount - userdb[msg.sender].tp_incomes[5]);
        userdb[msg.sender].tout = uint64(totalIncome);
        ct_out += uint64(newIncome);
        trc20Token.transfer(msg.sender, newIncome * 97 / 100);
        emit WithdrawAdd(msg.sender, newIncome);
    }

    function getContractInfo() view external returns(uint256 _c_rate, uint256 _avgCount, uint256 _todayCount, uint256 _pbig_amount, uint256 _pbig_end, address[24] memory _pbig_candidates, uint256 _psmall_amount, uint256 _c_start_time) {
        uint256 avgIncrease = 0;
        for(uint16 i = 1; i < 15 && c_count_arr.length >= i; i++) {
            avgIncrease = avgIncrease + c_count_arr[c_count_arr.length - i];
        }
        if(c_count_arr.length > 15) avgIncrease = avgIncrease / 15;
        else if(c_count_arr.length > 0) avgIncrease = avgIncrease / c_count_arr.length;
        else avgIncrease = ct_count;
        uint256 todayCount = ct_count;
        if(c_count_arr.length > 0) todayCount = c_count_arr[c_count_arr.length - 1] - ct_count;
        for(uint8 j = 1; j <= 24 && j <= pbig_candidates.length; j++) {
            _pbig_candidates[j - 1] = pbig_candidates[pbig_candidates.length - j];
        }
        if(c_rate_arr.length == 0) return (10, avgIncrease, todayCount, pbig_amount, pbig_end, _pbig_candidates, psmall_amount, c_start_time);
        else return (c_rate_arr[c_rate_arr.length - 1], avgIncrease, todayCount, pbig_amount, pbig_end, _pbig_candidates, psmall_amount, c_start_time);
    }

    function getUserInfo(address addr) view external returns(uint64 nin, uint64 nt_profit, uint64 tin, uint64 tout, uint64[6] memory tp_incomes) {
        require(addr == msg.sender || msg.sender == caddr_develop || msg.sender == caddr_operate, 'Permission Denied');
        uint64 topProfit = getTopProfit(userdb[addr].nin);
        uint64 np_profit = userdb[addr].np_profit;
        if(np_profit < topProfit) {
            uint16 ndays = uint16((block.timestamp - userdb[addr].ntime) / 24 hours);
            uint16 offset = uint16((userdb[addr].ntime - c_start_time) / 24 hours);
            uint16 tRate = 0;
            if(offset > c_rate_arr.length) ndays = 0;
            else if(ndays + offset > c_rate_arr.length) ndays = uint16(c_rate_arr.length - offset);
            for(uint16 i = offset; i < (ndays + offset) && i < c_rate_arr.length; i++) {
                tRate += uint16(c_rate_arr[i]);
            }
            if(userdb[addr].nin < 1000 * X_COIN_PRECISION) tRate = tRate - uint16(ndays) * 2;
            else if(userdb[addr].nin >= 5000 * X_COIN_PRECISION) tRate = tRate + uint16(ndays) * 2;
            np_profit = userdb[addr].nin * tRate / 1000;
        }
        if(np_profit > topProfit) np_profit = topProfit;
        return (userdb[addr].nin, np_profit, userdb[addr].tin, userdb[addr].tout, userdb[addr].tp_incomes);
    }

    function getTeamInfo(address addr) view external returns(address m_paddr, uint32 mt_level, uint64 tc_ref, uint128 tc_in, uint256 mt_in) {
        require(addr == msg.sender || msg.sender == caddr_develop || msg.sender == caddr_operate, 'Permission Denied');
        return (userdb[addr].m_paddr, userdb[addr].mt_level, userdb[addr].tc_ref, userdb[addr].tc_in, userdb[addr].mt_in);
    }

    function getOperateInfo() view external onlyOwner returns(uint256 _psmall_amount, uint256 _psmall_last, uint256 _pbig_amount, uint256 _pbig_end, uint256 _ct_count, address _caddr_operate, address _caddr_develop, address _caddr_root, uint256 _ct_in, uint256 _ct_out, uint256 _ct_in_operate, uint256 _ct_out_develop, uint256 _yesterdayCount, uint256 _c_rate) {
        if(c_rate_arr.length == 0 || c_count_arr.length == 0) return (psmall_amount, psmall_last, pbig_amount, pbig_end, ct_count, caddr_operate, caddr_develop, caddr_root, ct_in, ct_out, ct_in_operate, ct_out_develop, 0, 0);
        else return (psmall_amount, psmall_last, pbig_amount, pbig_end, ct_count, caddr_operate, caddr_develop, caddr_root, ct_in, ct_out, ct_in_operate, ct_out_develop, c_count_arr[c_count_arr.length - 1], c_rate_arr[c_rate_arr.length - 1]);
    }

    function getInfoByIndex(uint64 index) view external onlyOwner returns(uint64 rate, uint64 count) {
        if(c_rate_arr.length == 0 || c_count_arr.length == 0) return (10, ct_count);
        else if(c_rate_arr.length <= index) return (0, 0);
        else return (c_rate_arr[index], c_count_arr[index]);
    }

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
    }
}