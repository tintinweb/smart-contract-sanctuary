/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;



library Bep20TransferHelper {


    function safeApprove(address token, address to, uint256 value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint256 value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

}




library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
    
    function power(uint256 a, uint256 b) internal pure returns (uint256){

        if(a == 0) return 0;
        if(b == 0) return 1;
        
        uint256 c = a ** b;
        require(c > 0, "SafeMathForUint256: modulo by zero");
        return c;
    }
}









contract LpMiner {
    
    using SafeMath for uint256;
    
    mapping (address => mapping(uint256 => uint256)) private cancelHeightMap;
    
    mapping (address => mapping(uint256 => StakeRecord)) private addressStakeIdMap;
    mapping (address => uint256) private addressIdMap;
    
    mapping(address => StakeRecord[]) addressStakeRecords;
    address[] stakeAddresses;
    
    mapping (uint256 => uint256) private unitCoinPerBlock;// 区块高度 - 单位质押量的产币量
    uint256 private lastUnitPerBlock;// 最近记录的区块高度的单位产币量
    
    uint256 netTotalStake;// DPCQ LP全网总质押量
    
    uint256 STATUS_STAKING = 1;// 质押中
    uint256 STATUS_CANCELED = 2;// 已赎回
    
    address LP_CONTRACT_ADDRESS;
    uint256 LP_DECIMAL;
    
    address DP_CONTRACT_ADDRESS;
    uint256 DP_DECIMAL;
    
    address private owner;// 发行此合约地址
    
    bool startMine = false;// 启动挖矿
    uint256 startMineTime;// 启动挖矿时间
    
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only publisher can operate");
        _;
    }
    
    struct StakeRecord {
        uint256 id;// 质押id
        uint256 stake;// 质押数量
        uint256 time;// 质押时间
        uint256 taked;// 收益
        uint256 lastTakeHeight;// 上次提取的区块高度
        uint256 status;// 状态
    }
    
    mapping(address => mapping(uint256 => ExtractRecord[])) private addressExtractRecords;
    
    struct ExtractRecord {
        uint256 qty;// 提取数量
        uint256 time;// 提取时间
    }
    
    constructor(address lpContractAddress, uint256 lpDecimal, 
                address dpContractAddress, uint256 dpDecimal) {
        LP_CONTRACT_ADDRESS = lpContractAddress;
        LP_DECIMAL = lpDecimal;
        DP_CONTRACT_ADDRESS = dpContractAddress;
        DP_DECIMAL = dpDecimal;
        owner = msg.sender;
    }
    
    // 启动挖矿
    function setStartMine() public onlyOwner {
        startMine = true;
        startMineTime = block.timestamp;
    }
    
    // 全网总质押  全网24H产量  本地址总质押  本地址已领取收益
    function getNetData() public view returns (uint256[4] memory) {
        uint256[2] memory addressData = getAddressTotalData(msg.sender);
        uint256[4] memory s = [netTotalStake, getDailyAmount(), addressData[0], addressData[1]];
        return s;
    }
    
    // 地址总质押量
    function getAddressTotalData(address user) internal view returns (uint256[2] memory) {
        uint256 l = addressStakeRecords[user].length;
        uint256 totalStake = uint256(0);
        uint256 totalTaked = uint256(0);
        for (uint256 i = 0; i < l; i++) {
            if (addressStakeRecords[user][i].status == STATUS_STAKING) {
                totalStake = totalStake.add(addressStakeRecords[user][i].stake);
            }
            totalTaked = totalTaked.add(addressStakeRecords[user][i].taked);
        }
        uint256[2] memory s = [totalStake, totalTaked];
        return s;
    }
    
    // 24H产币量
    function getDailyAmount() internal view returns (uint256) {
        uint256 totalCoin = getTotalPerBlock(getBlockHeight());
        uint256 p = totalCoin.div(10);
        return SafeMath.mul(p, 144);
    }
    
    // 质押量，已领取收益，待领取收益
    function getStakeData(uint256 id) public view returns (uint256[3] memory) {
        uint256 h = addressStakeIdMap[msg.sender][id].status == STATUS_CANCELED ? cancelHeightMap[msg.sender][id] : getBlockHeight();
        uint256 pendingProfit = getPendingProfit(msg.sender, id, h);
        uint256[3] memory s = [addressStakeIdMap[msg.sender][id].stake, addressStakeIdMap[msg.sender][id].taked, 
            pendingProfit];
        return s;
    }
    
    // 单质押记录实时计算未领取收益
    function getPendingProfit(address user, uint256 id, uint256 currentBlockHeight) internal view returns (uint256) {
        uint256 itemu = 0;
        uint256 t = 0;
        for (uint256 i = addressStakeIdMap[user][id].lastTakeHeight; i < currentBlockHeight; i++) {
            itemu = unitCoinPerBlock[i];
            if (itemu <= 0) {
                itemu = addressStakeIdMap[user][id].stake.mul(getTotalPerBlock(i));
                itemu = itemu.div(10).div(netTotalStake);
                t = t.add(itemu);
            } else {
                t = t.add(itemu.mul(addressStakeIdMap[user][id].stake));
            }
        }
        return t;
    }
    
    // 得到当前区块高度
    function getBlockHeight() public view returns (uint256) {
        uint256 ds = SafeMath.sub(block.timestamp, startMineTime);
        return SafeMath.div(ds, 600);
    }
    
    // 产币高度对应的每个区块的产币量
    function getTotalPerBlock(uint256 blockHeight) internal view returns (uint256) {
        if (!startMine) return uint256(0);
        if (blockHeight <= 4320) {
            return uint256(10).power(DP_DECIMAL).mul(50);
        } else if (blockHeight >= 4321 && blockHeight <= 8640) {
            return uint256(10).power(DP_DECIMAL).mul(25);
        } else if (blockHeight >= 8641 && blockHeight <= 12960) {
            return uint256(10).power(DP_DECIMAL).mul(125).div(10);
        } else {
            return uint256(10).power(DP_DECIMAL).mul(625).div(100);
        }
    }
    
    // 质押
    function stake(uint256 amount) public {
        require(Bep20TransferHelper.safeTransferFrom(LP_CONTRACT_ADDRESS, msg.sender, address(this), amount), "asset insufficient");
        uint256 currentBlockHeight = getBlockHeight();
        if (addressStakeRecords[msg.sender].length == 0) {
            stakeAddresses.push(msg.sender);
        }
        
        uint256 sid = addressIdMap[msg.sender];
        
        StakeRecord memory o = StakeRecord({
            id: sid,
            stake: amount,
            time: block.timestamp,
            taked: 0,
            lastTakeHeight: currentBlockHeight,
            status: STATUS_STAKING
        });
        addressStakeRecords[msg.sender].push(o);
        addressStakeIdMap[msg.sender][sid] = o;
        addressIdMap[msg.sender] = sid.add(1);
        
        if (netTotalStake > 0 && currentBlockHeight >= 1 && lastUnitPerBlock < currentBlockHeight.sub(1)) {
            for (uint256 i = lastUnitPerBlock.add(1); i < currentBlockHeight; i++) {
                uint256 p = calculateBlockPer(i);
                unitCoinPerBlock[i] = p;
            }
        }
        netTotalStake = netTotalStake.add(amount);
        
        unitCoinPerBlock[currentBlockHeight] = calculateBlockPer(currentBlockHeight);
        lastUnitPerBlock = currentBlockHeight;
    }

    // 此高度单位质押应该拿到的收益
    function calculateBlockPer(uint256 blockHeight) internal view returns (uint256) {
        uint256 blockTotalCoin = getTotalPerBlock(blockHeight);
        uint256 blockLpTotal = blockTotalCoin.div(10);
        uint256 p = blockLpTotal.div(netTotalStake);
        return p;
    }
    
    // 赎回
    function take(uint256 id) public {
        require(addressStakeIdMap[msg.sender][id].status == STATUS_STAKING, "staking less than 0");
        require(Bep20TransferHelper.safeTransfer(LP_CONTRACT_ADDRESS, msg.sender, addressStakeIdMap[msg.sender][id].stake), "asset insufficient");
        uint256 currentBlockHeight = getBlockHeight();
        uint256 stakes = addressStakeRecords[msg.sender].length;
        for (uint256 i = 0; i < stakes; i++) {
            if (addressStakeRecords[msg.sender][i].id == id) {
                addressStakeRecords[msg.sender][i].status = STATUS_CANCELED;
                break;
            }
        }
        addressStakeIdMap[msg.sender][id].status = STATUS_CANCELED;
        
        if (netTotalStake > 0 && currentBlockHeight >= 1 && lastUnitPerBlock < currentBlockHeight.sub(1)) {
            for (uint256 i = lastUnitPerBlock.add(1); i < currentBlockHeight; i++) {
                unitCoinPerBlock[i] = calculateBlockPer(i);
            }
        }
        netTotalStake = netTotalStake.sub(addressStakeIdMap[msg.sender][id].stake);
        
        if (netTotalStake <= 0) {
            unitCoinPerBlock[currentBlockHeight] = 0;
        } else {
            unitCoinPerBlock[currentBlockHeight] = calculateBlockPer(currentBlockHeight); 
        }
        lastUnitPerBlock = currentBlockHeight;
        
        cancelHeightMap[msg.sender][id] = currentBlockHeight;
    }
    
    // 单记录提取收益
    function extract(uint256 id) public {
        uint256 currentBlockHeight = getBlockHeight();
        
        uint256 pendingProfit = getPendingProfit(msg.sender, id, addressStakeIdMap[msg.sender][id].status == STATUS_CANCELED ? cancelHeightMap[msg.sender][id] : currentBlockHeight);
        require(pendingProfit > 0, "avail less than 0");
        require(Bep20TransferHelper.safeTransfer(DP_CONTRACT_ADDRESS, msg.sender, pendingProfit), "asset insufficient");
        
        uint256 stakes = addressStakeRecords[msg.sender].length;
        for (uint256 i = 0; i < stakes; i++) {
            if (addressStakeRecords[msg.sender][i].id == id) {
                addressStakeRecords[msg.sender][i].lastTakeHeight = currentBlockHeight;
                addressStakeRecords[msg.sender][i].taked = addressStakeRecords[msg.sender][i].taked.add(pendingProfit);
                break;
            }
        }
        addressStakeIdMap[msg.sender][id].lastTakeHeight = currentBlockHeight;
        addressStakeIdMap[msg.sender][id].taked = addressStakeIdMap[msg.sender][id].taked.add(pendingProfit);
        
        if (netTotalStake > 0 && lastUnitPerBlock < currentBlockHeight) {
            for (uint256 i = lastUnitPerBlock.add(1); i <= currentBlockHeight; i++) {
                unitCoinPerBlock[i] = calculateBlockPer(i);
            }
            lastUnitPerBlock = currentBlockHeight;
        }
        
        addressExtractRecords[msg.sender][id].push(ExtractRecord({
            qty: pendingProfit,
            time: block.timestamp
        }));
    }
    
    // 同步高度的单位收益，防止高度差太大用户操作失败
    function syncHeight(uint256 heightNum) public onlyOwner {
        uint256 currentBlockHeight = getBlockHeight();
        if (lastUnitPerBlock < currentBlockHeight) {
            uint256 limit = lastUnitPerBlock.add(heightNum);
            if (limit > currentBlockHeight) limit = currentBlockHeight;
            for (uint256 i = lastUnitPerBlock.add(1); i <= limit; i++) {
                if (netTotalStake > 0) {
                    uint256 blockTotalCoin = getTotalPerBlock(i);
                    uint256 blockLpTotal = blockTotalCoin.div(10);
                    uint256 p = blockLpTotal.div(netTotalStake);
                    unitCoinPerBlock[i] = p; 
                } else {
                    unitCoinPerBlock[i] = 0; 
                }
            }
            lastUnitPerBlock = limit;
        }
    }
    
    // 质押记录
    function stakeRecord() public view returns (StakeRecord[] memory) {
        return addressStakeRecords[msg.sender];
    }
    
     // 提取记录
    function extractRecord(uint256 id) public view returns (ExtractRecord[] memory) {
        return addressExtractRecords[msg.sender][id];
    }
    
    /*******************************************************************/
    function transferTrx(uint256 amount) public payable onlyOwner {
        address payable a = payable(msg.sender);
        a.transfer(amount);
    }
    
    function transferBep20(address contractAddress, uint256 amount) public onlyOwner {
        require(Bep20TransferHelper.safeTransfer(contractAddress, msg.sender, amount), "asset insufficient");
    }
    
}