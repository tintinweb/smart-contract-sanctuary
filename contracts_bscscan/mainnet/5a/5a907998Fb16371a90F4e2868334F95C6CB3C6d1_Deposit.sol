/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


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

interface swap{
    function getMidPrice () external view returns(uint);
}
interface Old{
    function checkUserInvitor(address addr_) external view returns (address out_);
    function userInfo(address addr_) external view returns(address invitor,
        uint refer,
        uint inviteRewardBLK,
        uint inviteRewardUSDB,
        uint inviteBlkClaimed,
        uint inviteUsdbClaimed,
        uint claimedBLK,
        uint claimedUSDB);
}

contract Deposit is Ownable {

    using SafeERC20 for IERC20;
    using Address for address;
    IERC20 public BLK;
    IERC20 public USDB;
    IERC20 public FLY;
    address public BLKPair;
    uint public constant decimal = 1e18;
    uint public constant delay = 30 days;
    uint public constant acc = 1e10;
    uint public currentRound = 1;
    Old public  old;
    // uint public constant e = 27182818284;

    struct UserInfo {
        address invitor;
        uint refer;
        uint inviteRewardBLK;
        uint inviteRewardUSDB;
        uint inviteBlkClaimed;
        uint inviteUsdbClaimed;
        uint claimedBLK;
        uint claimedUSDB;
    }

    struct SlotInfo {
        bool status;
        uint round;
        uint mode;
        uint rate;
        uint depositAmount;
        uint depositTime;
        uint endTime;
        uint claimed;
        uint startTime;
        uint apy;
        uint fly;
        uint period;

    }

    struct RoundInfo {
        uint quota;
        uint apy;
        uint contractPeriod;
        uint depositAmount;


    }

    mapping(uint => uint) public e;
    mapping(uint => RoundInfo) public roundInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint => SlotInfo)) public userSlot;
    mapping(address => bool)public Admin;


    event Deposited(address indexed sender_, uint indexed amount_, uint round_, uint slot_, uint mode_);
    event ClaimInterest(address indexed sender_, uint indexed amount_, uint slot_, uint mode_);
    event UnDeposite(address indexed sender_, uint indexed slot_);
    event BondInvitor(address indexed sender_, address indexed invitor_);

    modifier isAdmin(){
        require(Admin[msg.sender], 'not contract');
        _;
    }
    constructor(){
        roundInfo[1] = RoundInfo({
        quota : 500000 * decimal,
        apy : 6500,
        contractPeriod : 90 days,
        depositAmount : 0
        });
        roundInfo[2] = RoundInfo({
        quota : 1500000 * decimal,
        apy : 5500,
        contractPeriod : 90 days,
        depositAmount : 0
        });
        roundInfo[3] = RoundInfo({
        quota : 3000000 * decimal,
        apy : 4500,
        contractPeriod : 90 days,
        depositAmount : 0
        });
        roundInfo[4] = RoundInfo({
        quota : 5000000 * decimal,
        apy : 4000,
        contractPeriod : 90 days,
        depositAmount : 0
        });
        roundInfo[5] = RoundInfo({
        quota : 0,
        apy : 1938,
        contractPeriod : 30 days,
        depositAmount : 0
        });
        roundInfo[6] = RoundInfo({
        quota : 0,
        apy : 2468,
        contractPeriod : 90 days,
        depositAmount : 0
        });
        roundInfo[7] = RoundInfo({
        quota : 0,
        apy : 2978,
        contractPeriod : 180 days,
        depositAmount : 0
        });
        roundInfo[8] = RoundInfo({
        quota : 0,
        apy : 3600,
        contractPeriod : 360 days,
        depositAmount : 0
        });
        e[7] = 3468;
        e[8] = 4333;
    }

    // function getUsdtPrice(address pair) public view returns (uint price){
    //     (uint reserve0, uint reserve1,) = BSCswapPair(pair).getReserves();
    //     price = reserve1 * 10 ** 18 / reserve0;
    //     // reserve0 A, reserve 1 U, it is U price of A
    //     return price;
    // }
    
    function setOld(address addr_) external onlyOwner{
        old = Old(addr_);
    }

    function setToken(address BLK_, address USDB_, address FLY_, address pair_) public onlyOwner {
        BLK = IERC20(BLK_);
        USDB = IERC20(USDB_);
        FLY = IERC20(FLY_);
        BLKPair = pair_;
    }

    function getBLKPrice(address pair) public view returns (uint price_){
        price_ = swap(pair).getMidPrice();
        // reserve0 A, reserve 1 U, it is U price of A
        return price_;
    }

    function updateRound() internal {
        if (currentRound < 5) {
            if (roundInfo[currentRound].quota - roundInfo[currentRound].depositAmount < 100 ether) {
                currentRound++;
            }
        }
    }

    //1 for BLK, 2 for USDB
    function deposit(uint amount_, uint round_, uint slot_, uint mode_, address invitor_) public {
        if (currentRound < 5) {
            require(round_ == currentRound, 'wrong round');
        }
        require(!userSlot[msg.sender][slot_].status, 'staked');
        require(round_ >= 1 && round_ <= 8, 'wrong round_');
        require(mode_ == 1 || mode_ == 2, 'wrong type');
        require(slot_ >= 0 && slot_ <= 4, 'wrong slot');
        if (checkUserInvitor(msg.sender) == address(0)) {
            require(userInfo[invitor_].invitor != address(0) || invitor_ == address(this), 'wrong invitor');
            userInfo[msg.sender].invitor = invitor_;
            emit BondInvitor(msg.sender, invitor_);
            if (checkUserRefer(invitor_)!= 0 && userInfo[invitor_].refer ==0){
            userInfo[invitor_].refer = checkUserRefer(invitor_);
            }
            userInfo[invitor_].refer ++;
        }
        if (mode_ == 1) {
            uint temp = getBLKPrice(BLKPair) * amount_ / decimal;
            require(temp >= 100 * decimal, 'too low');
            if (round_ < 5) {
                require(roundInfo[round_].depositAmount + temp < roundInfo[round_].quota, 'no quota');
            }
            BLK.transferFrom(msg.sender, address(this), amount_);
            roundInfo[round_].depositAmount += temp;
            userSlot[msg.sender][slot_] = SlotInfo({
            status : true,
            round : round_,
            mode : mode_,
            rate : amount_ * roundInfo[round_].apy * acc / 10000 / 360 days,
            depositAmount : amount_,
            depositTime : block.timestamp,
            endTime : block.timestamp + 360 days,
            claimed : 0,
            startTime : block.timestamp,
            apy : roundInfo[round_].apy,
            fly : 0,
            period : roundInfo[round_].contractPeriod
            });
        } else {
            require(amount_ >= 100 * decimal, 'too low');
            if (round_ < 5) {
                require(roundInfo[round_].depositAmount + amount_ < roundInfo[round_].quota, 'no quota');
            }
            USDB.safeTransferFrom(msg.sender, address(this), amount_);
            roundInfo[round_].depositAmount += amount_;
            userSlot[msg.sender][slot_] = SlotInfo({
            status : true,
            round : round_,
            mode : mode_,
            rate : amount_ * (roundInfo[round_].apy *7 /10) * acc / 10000 / 360 days,
            depositAmount : amount_,
            depositTime : block.timestamp,
            endTime : block.timestamp + 360 days,
            claimed : 0,
            startTime : block.timestamp,
            apy : roundInfo[round_].apy *7 /10,
            fly : 0,
            period : roundInfo[round_].contractPeriod
            });
        }
        updateRound();
        emit Deposited(msg.sender, amount_, round_, slot_, mode_);
    }

    function countingFlyCostUSDB(uint amount_) public pure returns (uint){
        uint _temp;
        if (amount_ < 2000 * decimal) {
            _temp = 0;
        } else {
            _temp = amount_ / (2000 * decimal);
        }
        uint cost = (_temp + 1) * 3000 * decimal;
        return cost;
    }

    function countingFlyCostBLK(uint amount_) public view returns (uint){
        uint _temp;
        uint _amount = getBLKPrice(BLKPair) * amount_ / decimal;
        if (_amount < 2000 * decimal) {
            _temp = 0;
        } else {
            _temp = _amount / (2000 * decimal);
        }
        uint cost = (_temp + 1) * 3000 * decimal;
        return cost;
    }

    function depositWithFly(uint amount_, uint round_, uint slot_, uint mode_, address invitor_) public {
        if (currentRound < 5) {
            require(round_ == currentRound, 'wrong round');
        }
        require(!userSlot[msg.sender][slot_].status, 'staked');
        require(round_ >= 1 && round_ <= 8, 'wrong round_');
        require(mode_ == 1 || mode_ == 2, 'wrong type');
        require(slot_ >= 0 && slot_ <= 4, 'wrong slot');
        if (checkUserInvitor(msg.sender) == address(0)) {
            require(userInfo[invitor_].invitor != address(0) || invitor_ == address(this), 'wrong invitor');
            userInfo[msg.sender].invitor = invitor_;
            emit BondInvitor(msg.sender, invitor_);
            if (checkUserRefer(invitor_)!= 0 && userInfo[invitor_].refer ==0){
            userInfo[invitor_].refer = checkUserRefer(invitor_);
        }
            userInfo[invitor_].refer ++;
        }
        if (mode_ == 1) {
            uint temp = getBLKPrice(BLKPair) * amount_ / decimal;
            require(temp >= 500 * decimal, 'too low');
            if (round_ < 5) {
                require(roundInfo[round_].depositAmount + temp < roundInfo[round_].quota, 'no quota');
            }
            uint cost = countingFlyCostUSDB(temp);
            BLK.safeTransferFrom(msg.sender, address(this), amount_);
            roundInfo[round_].depositAmount += temp;
            FLY.safeTransferFrom(msg.sender, address(this), cost);
            userSlot[msg.sender][slot_] = SlotInfo({
            status : true,
            round : round_,
            mode : mode_,
            rate : amount_ * (roundInfo[round_].apy + 500) * acc / 10000 / 360 days,
            depositAmount : amount_,
            depositTime : block.timestamp,
            endTime : block.timestamp + 360 days,
            claimed : 0,
            startTime : block.timestamp,
            apy : roundInfo[round_].apy + 500,
            fly : cost,
            period : roundInfo[round_].contractPeriod
            });
        } else {
            require(amount_ >= 500 * decimal, 'too low');
            if (round_ < 5) {
                require(roundInfo[round_].depositAmount + amount_ < roundInfo[round_].quota, 'no quota');
            }
            uint cost = countingFlyCostUSDB(amount_);
            FLY.safeTransferFrom(msg.sender, address(this), cost);
            roundInfo[round_].depositAmount += amount_;
            USDB.safeTransferFrom(msg.sender, address(this), amount_);
            userSlot[msg.sender][slot_] = SlotInfo({
            status : true,
            round : round_,
            mode : mode_,
            rate : amount_ * ((roundInfo[round_].apy + 500)*7/10) * acc / 10000 / 360 days,
            depositAmount : amount_,
            depositTime : block.timestamp,
            endTime : block.timestamp + 360 days,
            claimed : 0,
            startTime : block.timestamp,
            apy : (roundInfo[round_].apy + 500)*7/10,
            fly : cost,
            period : roundInfo[round_].contractPeriod
            });
        }
        updateRound();
        emit Deposited(msg.sender, amount_, round_, slot_, mode_);
    }

    function checkSlotNum(address addr_) public view returns (uint) {
        for (uint i = 0; i <= 4; i++) {
            if (!userSlot[addr_][i].status) {
                return i;
            } else {
                continue;
            }
        }
        return 20;
    }

    function countingInterest(address addr_,uint slot_) public view returns (uint){
        require(userSlot[addr_][slot_].status, 'wrong slot');
        uint out;
        if (block.timestamp < userSlot[addr_][slot_].endTime) {
            out = userSlot[addr_][slot_].rate * (block.timestamp - userSlot[addr_][slot_].depositTime) / acc;

        } else {
            out = userSlot[addr_][slot_].rate * (userSlot[addr_][slot_].endTime - userSlot[addr_][slot_].depositTime) / acc;
        }

        return out;
    }

    function claimInterest(uint slot_) public {
        require(userSlot[msg.sender][slot_].status, 'wrong slot');
        require(userSlot[msg.sender][slot_].round < 5);
        require(userSlot[msg.sender][slot_].endTime - block.timestamp < 330 days, 'too early');
        uint temp;
        if (userSlot[msg.sender][slot_].mode == 1) {
            temp = countingInterest(msg.sender,slot_);
            BLK.safeTransfer(msg.sender, temp);
            userInfo[msg.sender].claimedBLK += temp;
            userSlot[msg.sender][slot_].depositTime = block.timestamp;
            userInfo[userInfo[msg.sender].invitor].inviteRewardBLK += temp * 3 / 100;
            userSlot[msg.sender][slot_].claimed += temp;
        } else {
            temp = countingInterest(msg.sender,slot_);
            USDB.safeTransfer(msg.sender, temp);
            userInfo[msg.sender].claimedUSDB += temp;
            userSlot[msg.sender][slot_].depositTime = block.timestamp;
            userInfo[userInfo[msg.sender].invitor].inviteRewardUSDB += temp * 3 / 100;
            userSlot[msg.sender][slot_].claimed += temp;
        }
        emit ClaimInterest(msg.sender, temp, slot_, userSlot[msg.sender][slot_].mode);
    }

    function claimAll() public {
        for (uint i = 0; i < 5; i++) {
            if (userSlot[msg.sender][i].status && userSlot[msg.sender][i].endTime - block.timestamp < 330 days) {
                claimInterest(i);
            } else {
                continue;
            }
        }
    }

    function countingAll(address addr_) public view returns (uint){
        uint out;
        for (uint i = 0; i < 5; i++) {
            if (userSlot[addr_][i].status && userSlot[addr_][i].endTime - block.timestamp < 330 days) {
                out += countingInterest(addr_,i);
            } else {
                continue;
            }
        }
        return out;
    }

    function unDeposite(uint slot_) public {
        uint temp;
        SlotInfo storage info = userSlot[msg.sender][slot_];
        require(info.endTime - block.timestamp < 330 days, 'too early');
        if (info.round <= 4) {
            if (block.timestamp < info.endTime - 270 days) {
                temp = (block.timestamp - (info.endTime - 360 days)) * info.rate * 7 / 10 / acc;
                if (temp < info.claimed) {
                    if (info.mode == 1) {
                        BLK.safeTransfer(msg.sender, info.depositAmount - (info.claimed - temp));

                    } else {
                        USDB.safeTransfer(msg.sender, info.depositAmount - (info.claimed - temp));
                    }
                } else {
                    if (info.mode == 1) {
                        BLK.safeTransfer(msg.sender, info.depositAmount + (temp - info.claimed));
                        userInfo[userInfo[msg.sender].invitor].inviteRewardBLK += temp * 3 / 100;

                    } else {
                        USDB.safeTransfer(msg.sender, info.depositAmount + (temp - info.claimed));
                        userInfo[userInfo[msg.sender].invitor].inviteRewardUSDB += temp * 3 / 100;

                    }

                    emit ClaimInterest(msg.sender, temp - info.claimed, slot_, userSlot[msg.sender][slot_].mode);
                }
            } else {
                claimInterest(slot_);
                if (info.mode == 1) {
                    BLK.safeTransfer(msg.sender, info.depositAmount);
                } else {
                    USDB.safeTransfer(msg.sender, info.depositAmount);
                }

            }
        } else if (info.round > 4 && info.round <= 6) {
            uint rate = info.depositAmount * roundInfo[info.round].apy * acc / 10000 / roundInfo[info.round].contractPeriod;
            if (block.timestamp < info.endTime - 360 days + roundInfo[info.round].contractPeriod) {
                temp = (block.timestamp - (info.endTime - 360 days)) * rate * 7 / 10 / acc;
            } else {
                temp = (block.timestamp - (info.endTime - 360 days)) * rate / acc;
            }
            if (info.mode == 1) {
                BLK.safeTransfer(msg.sender, info.depositAmount + temp);
                userInfo[userInfo[msg.sender].invitor].inviteRewardBLK += temp * 3 / 100;

            } else {
                USDB.safeTransfer(msg.sender, info.depositAmount + temp);
                userInfo[userInfo[msg.sender].invitor].inviteRewardUSDB += temp * 3 / 100;

            }
            emit ClaimInterest(msg.sender, temp, slot_, userSlot[msg.sender][slot_].mode);
        } else if (info.round >= 7) {
            if (block.timestamp < info.endTime - 360 days + 90 days) {
                uint rate = info.depositAmount * roundInfo[info.round].apy * acc / 10000 / roundInfo[info.round].contractPeriod;
                temp = (block.timestamp - (info.endTime - 360 days)) * rate * 7 / 10 / acc;
            } else if (block.timestamp > info.endTime - 360 days + 90 days && block.timestamp < info.endTime - 360 days + roundInfo[info.round].contractPeriod) {
                uint rate = info.depositAmount * e[info.round] * acc / 10000 / roundInfo[info.round].contractPeriod;
                temp = (block.timestamp - (info.endTime - 360 days)) * rate * 7 / 10 / acc;
            } else if (block.timestamp > info.endTime - 360 days + roundInfo[info.round].contractPeriod) {
                uint rate = info.depositAmount * e[info.round] * acc / 10000 / roundInfo[info.round].contractPeriod;
                temp = (block.timestamp - (info.endTime - 360 days)) * rate / acc;
            }
            if (info.mode == 1) {
                BLK.safeTransfer(msg.sender, info.depositAmount + temp);
                userInfo[userInfo[msg.sender].invitor].inviteRewardBLK += temp * 3 / 100;

            } else {
                USDB.safeTransfer(msg.sender, info.depositAmount + temp);
                userInfo[userInfo[msg.sender].invitor].inviteRewardUSDB += temp * 3 / 100;

            }
            emit ClaimInterest(msg.sender, temp, slot_, userSlot[msg.sender][slot_].mode);
        }
        if (userSlot[msg.sender][slot_].fly != 0){
            FLY.transfer(msg.sender,userSlot[msg.sender][slot_].fly);
        }
        
        userSlot[msg.sender][slot_] = SlotInfo({
        status : false,
        round : 0,
        mode : 0,
        rate : 0,
        depositAmount : 0,
        depositTime : 0,
        endTime : 0,
        claimed : 0,
        startTime : 0,
        apy : 0,
        fly:0,
        period : 0
        });
        emit UnDeposite(msg.sender, slot_);
    }

    function claimReward() public {
        require(userInfo[msg.sender].inviteRewardBLK > 0 || userInfo[msg.sender].inviteRewardUSDB > 0, 'no rewareds');
        if (userInfo[msg.sender].inviteRewardBLK > 0){
            BLK.safeTransfer(msg.sender, userInfo[msg.sender].inviteRewardBLK);
            userInfo[msg.sender].inviteBlkClaimed += userInfo[msg.sender].inviteRewardBLK;
        }
        if (userInfo[msg.sender].inviteRewardUSDB > 0){
            USDB.safeTransfer(msg.sender, userInfo[msg.sender].inviteRewardUSDB);
            userInfo[msg.sender].inviteUsdbClaimed += userInfo[msg.sender].inviteRewardUSDB;
        }
        
        
        
        userInfo[msg.sender].inviteRewardUSDB = 0;
        userInfo[msg.sender].inviteRewardBLK = 0;
    }

    function checkUserInvitor(address addr_) public view returns (address out_){
        if (old.checkUserInvitor(addr_) != address(0)){
            out_ = old.checkUserInvitor(addr_);
        }else{
            out_ = userInfo[addr_].invitor;
        }
        
    }
    
    function checkUserRefer(address addr_)public view returns(uint ){
        (,uint out_,,,,,,) = old.userInfo(addr_);
        if (out_ != 0 && userInfo[addr_].refer ==0){ 
            return out_;
        }
        return userInfo[addr_].refer;
    }

    function bondUserInvitor(address addr_, address invitor_) public isAdmin {
        require(checkUserInvitor(invitor_) == address(0), 'wrong');
        userInfo[addr_].invitor = invitor_;
        if (checkUserRefer(invitor_)!= 0 && userInfo[invitor_].refer ==0){
            userInfo[invitor_].refer = checkUserRefer(invitor_);
        }
        userInfo[invitor_].refer++;
    }


    function setUserInvitorReward(address addr_, uint BLK_, uint USDB_) public isAdmin {
        require(userInfo[addr_].invitor != address(0), 'wrong address');
        userInfo[addr_].inviteRewardUSDB += USDB_;
        userInfo[addr_].inviteRewardBLK += BLK_;
    }

    function setAdmin(address addr_, bool com_) public onlyOwner {
        Admin[addr_] = com_;
    }

    function safePull(address addr_) public onlyOwner {
        BLK.safeTransfer(addr_, BLK.balanceOf(address(this)));
        USDB.safeTransfer(addr_, USDB.balanceOf(address(this)));
    }

}

library SafeERC20 {

    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}