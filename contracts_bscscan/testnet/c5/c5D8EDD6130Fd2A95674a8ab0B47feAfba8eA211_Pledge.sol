/**
 *Submitted for verification at BscScan.com on 2021-09-03
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


interface ISRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address addr_, uint amount_) external returns (bool);

    function checkHolder() external view returns (uint out);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract Pledge is Ownable {
    ISRC20 public SpeToken;
    uint public priceNBTC = 3;
    address public constant banker = 0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954;
    uint public dayOutPut;
    uint public rate;
    uint[5] public  cycle = [600, 60 * 15, 30 * 60 , 60 * 60 , 90 * 60];
    uint[5] public  Coe = [8, 9, 10, 11, 12]; //算力系数
    uint public startTime;
    uint public constant decimal = 1e18;
    bool public statusAll;
    uint public constant Acc = 1e10;
    uint public TVL;
    uint public NBTCTVL;
    uint public totalPower;
    uint public currentLayer = 1;
    uint[5] public  price = [3, 4, 5, 8, 10];
    uint public totalNBTCLeft = 3000000 * 5;
    address public exchangeAddress;
    uint public burnTotal;
    uint[4] public  airDropRate = [1, 10, 20, 30];
    uint public constant AirDropAmount = 1000000 * decimal;

    // address public dele;




    event GetNBTC(address indexed sender, uint indexed amount_);
    event CosumeNBTC(address indexed sender, uint indexed amount_);
    event StakeSpe(address indexed sender_, uint indexed slot_, uint indexed amount_, uint cycle_);
    event StakeNBTC(address indexed sender_, uint indexed slot_, uint indexed amount_, uint cycle_);
    event ActivateInvite(address indexed invitor_, address indexed refer_);
    event ClaimCommunity (address indexed sender_, uint indexed amount_);
    event ClaimStatic(address indexed sender_, uint indexed amount_);
    event UnStake(address indexed sender_, uint indexed amount_, uint indexed slot_);
    event Exchange(address indexed sender_, uint indexed amount_, uint indexed cost_);
    event ClaimToWallet(address indexed sender_, uint indexed amount_);
    event ClaimNode(address indexed sender_, uint indexed amount_);
    event ClaimAirDrop(address indexed sender_, uint indexed amount_, uint indexed round_);
    event ClaimIDO(address indexed sender_, uint indexed amount_);
    event BuyAmount(address indexed sender_, uint indexed amount_);

    struct AirDrop {
        bool status;
        uint regTotal;
        uint regTime;
        uint regEnd;
        uint claimTime;
        uint claimEnd;
        uint round;
        uint toClaim;
        uint claimed;
    }

    AirDrop public airDropInfo;

    struct Status {
        bool stake;
        bool exchange;
        bool claimStatic;
        bool claimToWallet;
        bool unstake;
        bool claimCommunity;
        bool claimNode;
        bool stock;
    }

    Status public status;

    struct Debt {
        uint timestamp;
        uint debted;
    }


    Debt public debt;

    struct slot {
        bool status;
        uint stakeAmount;
        uint debt;
        uint stakeTime;
        uint power;
        uint endTime;
        uint mode;
    }

    // mapping(address => userSlot)slotInfo;
    struct UserInfo {
        uint NBTC;
        uint finalPower;
        uint stakeAmount;
        uint stakeNBTCAmount;
        address invitor;
        uint refer_n;
        uint Claimed;
        uint lockSpe;
        uint lastClearTime;
        // mapping(uint => slot) userSlot;

    }
    mapping(address=> uint)public IDOTime;

    mapping(address => mapping(uint => slot)) public userSlot;

    struct UserClaim {
        uint comTotal;
        uint nodeTotal;
        uint IDOTotal;
        uint stock;
        uint quota;
        mapping(uint => bool) regAir;
        mapping(uint => bool) claimAir;
    }

    mapping(address => UserClaim) public userClaim;

    struct LayerInfo {
        uint left;
        uint price;

    }

    mapping(uint => LayerInfo) public layerInfo;
    mapping(address => UserInfo) public userInfo;
    modifier checkTime{
        if (block.timestamp - startTime >= 365 days) {
            startTime += 365 days;
            dayOutPut = dayOutPut * 80 / 100;
            rate = dayOutPut / 1 days;
        }
        _;
    }
    modifier checkHolder{
        uint temp = SpeToken.checkHolder();
        if (airDropInfo.status) {

        } else if (temp > 25 && airDropInfo.round == 3) {
            airDropInfo.regTotal = 0;
            airDropInfo.status = true;
            airDropInfo.regTime = block.timestamp;
            airDropInfo.regEnd = block.timestamp + 3600;
            airDropInfo.claimTime = block.timestamp + 3600;
            airDropInfo.claimEnd = block.timestamp + 7200;
            airDropInfo.round = 4;
            airDropInfo.toClaim = checkRoundTotal();
            airDropInfo.claimed = 0;
        } else if (temp > 20 && airDropInfo.round == 2) {
            airDropInfo.regTotal = 0;
            airDropInfo.status = true;
            airDropInfo.regTime = block.timestamp;
            airDropInfo.regEnd = block.timestamp + 3600;
            airDropInfo.claimTime = block.timestamp + 3600;
            airDropInfo.claimEnd = block.timestamp + 7200;
            airDropInfo.round = 3;
            airDropInfo.toClaim = checkRoundTotal();
            airDropInfo.claimed = 0;
        } else if (temp > 16 && airDropInfo.round == 1) {
            airDropInfo.regTotal = 0;
            airDropInfo.status = true;
            airDropInfo.regTime = block.timestamp;
            airDropInfo.regEnd = block.timestamp + 3600;
            airDropInfo.claimTime = block.timestamp + 3600;
            airDropInfo.claimEnd = block.timestamp + 7200;
            airDropInfo.round = 2;
            airDropInfo.toClaim = checkRoundTotal();
            airDropInfo.claimed = 0;
        } else if (temp > 1 && airDropInfo.round == 0) {
            airDropInfo.regTotal = 0;
            airDropInfo.status = true;
            airDropInfo.regTime = block.timestamp;
            airDropInfo.regEnd = block.timestamp + 3600;
            airDropInfo.claimTime = block.timestamp + 3600;
            airDropInfo.claimEnd = block.timestamp + 7200;
            airDropInfo.round = 1;
            airDropInfo.toClaim = checkRoundTotal();
            airDropInfo.claimed = 0;
        }
        if (block .timestamp > airDropInfo.claimEnd) {
            airDropInfo.status = false;

        }
        _;
    }
    modifier checkMounth{
        if (userInfo[msg.sender].lastClearTime == 0) {
            userInfo[msg.sender].lastClearTime = block.timestamp + 60 days;
        } else if (block.timestamp > userInfo[msg.sender].lastClearTime) {
            userInfo[msg.sender].Claimed = 0;
        }
        _;
    }
    modifier isStart{
        require(statusAll, '1');
        _;
    }
    function setInit() public onlyOwner {
        require(!statusAll, '7');
        startTime = block.timestamp;

        statusAll = true;
    }
    constructor(){
        priceNBTC = layerInfo[currentLayer].price;
        dayOutPut = 6693000 * decimal / 365;
        rate = dayOutPut / 1 days;

        for (uint i = 0; i < 5; i ++) {
            layerInfo[i + 1] = LayerInfo({
            left : 3000000,
            price : price[i]
            });
        }


    }
    function coutingDebt() public view returns (uint){
        uint debt_ = totalPower > 0 ? (rate * 4 / 10) * (block.timestamp - debt.timestamp) * Acc / totalPower + debt.debted : 0 + debt.debted;
        return debt_;
    }

    function calculateSlotRewards(address addr_, uint slot_) public view returns (uint) {
        require(slot_ >= 0 && slot_ <= 9, '4');
        require(userSlot[addr_][slot_].stakeAmount > 0, '2');
        // rewards = userSlot[addr_][slot_].power * (coutingDebt() - userSlot[addr_][slot_].debt) / Acc;
        uint tempDebt;
        uint rewards;
        // uint reward;
        if (block.timestamp >= userSlot[msg.sender][slot_].endTime && userSlot[msg.sender][slot_].stakeTime < userSlot[msg.sender][slot_].endTime) {
            tempDebt = (rate * 4 / 10) * (userSlot[msg.sender][slot_].endTime - userSlot[msg.sender][slot_].stakeTime) * Acc / totalPower;
            rewards = tempDebt * userSlot[msg.sender][slot_].power / Acc;

        } else if (block.timestamp < userSlot[msg.sender][slot_].endTime) {
            tempDebt = coutingDebt();
            rewards = userSlot[msg.sender][slot_].power * (tempDebt - userSlot[msg.sender][slot_].debt) / Acc;

        }
        return rewards;
    }
    

    function calculateAllSlotRewards(address addr_) public view returns (uint){
        uint rewards;
        for (uint i = 0; i <= 9; i++) {
            if (userSlot[addr_][i].status) {
                rewards += calculateSlotRewards(addr_, i);

            } else {
                continue;
            }
        }
        
        return rewards;
    }

    function checkUserSlotNum() public view returns (uint[10] memory out){
        for (uint i = 0; i <= 9; i++) {
            if (userSlot[msg.sender][i].status) {
                out[i] = 1;

            } else {
                continue;
            }
        }
    }

    function stakeWithSpe(uint slot_, uint amount_, uint cycle_) isStart checkTime checkHolder public {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("stakeWithSpe(uint256,uint256,uint256)",slot_,amount_,cycle_));
        require(userInfo[msg.sender].invitor != address(0), '20');
        require(status.stake, '3');
        require(slot_ >= 0 && slot_ <= 9, '4');
        require(cycle_ >= 0 && cycle_ <= 4, '5');
        require(amount_ >= 30 * decimal, '6');
        require(!userSlot[msg.sender][slot_].status, '8');
        require(SpeToken.transferFrom(msg.sender, address(this), amount_), '9');
        uint nowdebt = coutingDebt();
        uint tempPower = amount_ * Coe[cycle_] / 10;
        userSlot[msg.sender][slot_] = slot({
        status : true,
        stakeAmount : amount_,
        debt : nowdebt,
        stakeTime : block.timestamp,
        power : tempPower,
        endTime : block.timestamp + cycle[cycle_],
        mode : 1
        });

        userInfo[msg.sender].stakeAmount += amount_;
        userInfo[msg.sender].finalPower += tempPower;
        debt.debted = nowdebt;
        debt.timestamp = block.timestamp;
        TVL += amount_;
        totalPower += tempPower;
        emit StakeSpe(msg.sender, slot_, amount_, cycle[cycle_]);

    }

    function stakeWithNBTC(uint slot_, uint amount_, uint cycle_) isStart checkTime checkHolder public {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("stakeWithNBTC(uint256,uint256,uint256)",slot_,amount_,cycle_));
        require(status.stake, '3');
        require(slot_ >= 0 && slot_ <= 9, '4');
        require(cycle_ >= 0 && cycle_ <= 4, '5');
        priceNBTC = layerInfo[currentLayer].price;
        uint tempSPE = amount_ * priceNBTC * decimal / 10;
        require(tempSPE >= 30, '6');
        require(!userSlot[msg.sender][slot_].status, '8');
        require(userInfo[msg.sender].NBTC >= amount_, '10');
        consumeNBTC(msg.sender, amount_);
        uint nowdebt = coutingDebt();
        uint tempPower = tempSPE * Coe[cycle_] *  15 / 100  ;
        NBTCTVL += amount_;
        userSlot[msg.sender][slot_] = slot({
        status : true,
        stakeAmount : amount_,
        debt : nowdebt,
        stakeTime : block.timestamp,
        power : tempPower,
        endTime : block.timestamp + cycle[cycle_],
        mode : 2
        });

        userInfo[msg.sender].stakeNBTCAmount += amount_;
        userInfo[msg.sender].finalPower += tempPower;
        debt.debted = nowdebt;
        debt.timestamp = block.timestamp;
        totalPower += tempPower;
        emit StakeNBTC(msg.sender, slot_, amount_, cycle[cycle_]);

    }

    // function reStake(uint slot_, uint cycle_) isStart checkTime checkHolder public {
    //     //  Address.functionDelegateCall(dele,abi.encodeWithSignature("reStake(uint256,uint256)",slot_,cycle_));
    //     require(cycle_ >= 0 && cycle_ <= 4, '5');
    //     require(block.timestamp > userSlot[msg.sender][slot_].endTime, '11');
    //     // require(userSlot[msg.sender][slot_].status,'16');
    //     claimStatic(slot_);
    //     totalPower -= userSlot[msg.sender][slot_].power;
    //     userInfo[msg.sender].finalPower -= userSlot[msg.sender][slot_].power;
    //     uint amount_ = userSlot[msg.sender][slot_].stakeAmount;
    //     if (userSlot[msg.sender][slot_].mode == 1) {
    //         uint tempPower = amount_ * Coe[cycle_];
    //         userSlot[msg.sender][slot_] = slot({
    //         status : true,
    //         stakeAmount : amount_,
    //         debt : coutingDebt(),
    //         stakeTime : block.timestamp,
    //         power : tempPower,
    //         endTime : block.timestamp + cycle[cycle_],
    //         mode : 1
    //         });
    //         totalPower += tempPower;
    //         userInfo[msg.sender].finalPower += tempPower;
    //         emit StakeSpe(msg.sender, slot_, amount_, cycle[cycle_]);

    //     } else {
    //         uint tempSPE = amount_ * priceNBTC * decimal / 10;
    //         uint tempPower = tempSPE * 15 / 10;
    //         userSlot[msg.sender][slot_] = slot({
    //         status : true,
    //         stakeAmount : amount_,
    //         debt : coutingDebt(),
    //         stakeTime : block.timestamp,
    //         power : tempPower,
    //         endTime : block.timestamp + cycle[cycle_],
    //         mode : 2
    //         });
    //         totalPower += tempPower;
    //         userInfo[msg.sender].finalPower += tempPower;
    //         emit StakeNBTC(msg.sender, slot_, amount_, cycle[cycle_]);
    //     }
    // }

    function claimStatic(uint slot_) isStart checkTime checkHolder internal returns (uint out_) {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("claimStatic(uint256)",slot_));
        require(status.claimStatic, '1');
        require(slot_ >= 0 && slot_ <= 9, '4');
        require(userSlot[msg.sender][slot_].stakeAmount > 0, '2');
        // require(userSlot[msg.sender][slot_].stakeTime <userSlot[msg.sender][slot_].endTime );
        uint tempDebt;
        uint reward;
        if (block.timestamp >= userSlot[msg.sender][slot_].endTime && userSlot[msg.sender][slot_].stakeTime < userSlot[msg.sender][slot_].endTime) {
            tempDebt = (rate * 4 / 10) * (userSlot[msg.sender][slot_].endTime - userSlot[msg.sender][slot_].stakeTime) * Acc / totalPower;
            reward = tempDebt * userSlot[msg.sender][slot_].power / Acc;
            out_ = reward * 9 / 10;
            userInfo[msg.sender].lockSpe += reward * 1 / 10;
            userInfo[msg.sender].Claimed += out_;
            userSlot[msg.sender][slot_].stakeTime = block.timestamp;
            userSlot[msg.sender][slot_].debt = coutingDebt();
        } else if (block.timestamp < userSlot[msg.sender][slot_].endTime) {
            tempDebt = coutingDebt();
            reward = userSlot[msg.sender][slot_].power * (tempDebt - userSlot[msg.sender][slot_].debt) / Acc;
            out_ = reward * 9 / 10;
            userInfo[msg.sender].Claimed += out_;
            userInfo[msg.sender].lockSpe += reward * 1 / 10;
            userSlot[msg.sender][slot_].stakeTime = block.timestamp;
            userSlot[msg.sender][slot_].debt = tempDebt;
        }
        emit ClaimStatic(msg.sender, reward);

    }

    function claim(uint slot_) public {
        uint temp = claimStatic(slot_);
        SpeToken.transfer(msg.sender, temp);
    }

    function unStake(uint slot_) isStart checkTime checkHolder public {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("unStake(uint256)",slot_));
        require(status.unstake, '1');
        require(slot_ >= 0 && slot_ <= 9, '4');
        require(userSlot[msg.sender][slot_].stakeAmount > 0, '2');
        require(userSlot[msg.sender][slot_].endTime < block.timestamp, 'not time');
        require(userSlot[msg.sender][slot_].mode != 0, 'worng');
        uint tempAmount = userSlot[msg.sender][slot_].stakeAmount;
        uint tempPower = userSlot[msg.sender][slot_].power;
        if (userSlot[msg.sender][slot_].mode == 1) {
            uint temp = claimStatic(slot_);
            userSlot[msg.sender][slot_] = userSlot[msg.sender][slot_] = slot({
            status : false,
            stakeAmount : 0,
            debt : 0,
            stakeTime : 0,
            power : 0,
            endTime : 0,
            mode : 0
            });
            totalPower -= tempPower;
            TVL -= tempAmount;
            userInfo[msg.sender].finalPower -= tempPower;
            userInfo[msg.sender].stakeAmount -= tempAmount;
            SpeToken.transfer(msg.sender, tempAmount + (temp * 99 / 100));
            if (temp != 0){
                
                userInfo[msg.sender].Claimed += temp * 99 / 100;
                SpeToken.transfer(address(0), temp / 100);
                burnTotal += temp / 100;
            } 
        }
        else if (userSlot[msg.sender][slot_].mode == 2) {

            uint temp = claimStatic(slot_);
            SpeToken.transfer(msg.sender, tempAmount + (temp * 99 / 100));
            SpeToken.transfer(address(0), temp / 100);
            burnTotal += temp / 100;
            userSlot[msg.sender][slot_] = userSlot[msg.sender][slot_] = slot({
            status : false,
            stakeAmount : 0,
            debt : 0,
            stakeTime : 0,
            power : 0,
            endTime : 0,
            mode : 0
            });
            totalPower -= tempPower;
            NBTCTVL -= tempAmount;
            userInfo[msg.sender].finalPower -= tempPower;
            userInfo[msg.sender].stakeNBTCAmount -= tempAmount;
            getNBTC(msg.sender, tempAmount);
            if (temp != 0){
                userInfo[msg.sender].Claimed += temp * 99 / 100;
                SpeToken.transfer(msg.sender,  temp * 99 / 100);
                SpeToken.transfer(address(0), temp / 100);
                burnTotal += temp / 100;
            } 
            

        }
        emit UnStake(msg.sender, tempAmount, slot_);
    }

    function claimStaticAll() external {
        uint temp;
        for (uint i = 0; i <= 9; i++) {
            if (userSlot[msg.sender][i].status) {
                temp += claimStatic(i);


            } else {
                continue;
            }
        }
        SpeToken.transfer(msg.sender, temp * 99 / 100);
        SpeToken.transfer(address(0), temp / 100);
        burnTotal += temp / 100;
        emit ClaimToWallet(msg.sender,temp * 99 / 100);
    }


    function getNBTC(address addr_, uint amount_) internal {
        userInfo[addr_].NBTC += amount_;
        emit GetNBTC(addr_, amount_);
    }

    function consumeNBTC(address addr_, uint amount_) internal {
        require(userInfo[addr_].NBTC >= amount_, '50');
        userInfo[addr_].NBTC -= amount_;
        emit CosumeNBTC(addr_, amount_);
    }


    function coutingExchange(uint amount_) internal view returns (uint){
        uint cost = amount_ * layerInfo[currentLayer].price * decimal / 10;
        return cost;
    }

    function exchange(uint amount_) isStart checkTime checkHolder external {
        require(userInfo[msg.sender].invitor != address(0), '20');
        require(status.exchange, '1');
        require(amount_ % 3000 == 0, '13');
        require(layerInfo[5].left != 0, '14');
        require(amount_ < totalNBTCLeft, '14');
        uint tempLeft = amount_;
        uint tempCost;
        for (uint i = currentLayer; i <= 5; i++) {
            if (tempLeft > layerInfo[i].left) {

                tempLeft = amount_ - layerInfo[i].left;
                tempCost += coutingExchange(layerInfo[i].left);
                getNBTC(msg.sender, layerInfo[i].left);
                totalNBTCLeft -= layerInfo[i].left;
                layerInfo[i].left = 0;
                currentLayer = i + 1;

                continue;
            }
            if (tempLeft <= layerInfo[i].left) {
                layerInfo[i].left -= tempLeft;
                tempCost += coutingExchange(tempLeft);
                getNBTC(msg.sender, tempLeft);
                currentLayer = i;
                totalNBTCLeft -= tempLeft;
                break;
            }
        }
        if (tempCost > userInfo[msg.sender].lockSpe) {
            uint left = tempCost - userInfo[msg.sender].lockSpe;
            userInfo[msg.sender].lockSpe = 0;
            SpeToken.transferFrom(msg.sender, address(this), left);

        } else {
            userInfo[msg.sender].lockSpe -= tempCost;
        }
        SpeToken.transfer(exchangeAddress, tempCost * 8 / 10);
        SpeToken.transfer(address(0), tempCost * 2 / 10);
        burnTotal += tempCost * 2 / 10;
        priceNBTC = layerInfo[currentLayer].price;
        emit Exchange(msg.sender, amount_, tempCost);
    }

    function coutingCost(uint amount_) public view returns (uint lockSpe_, uint spe_){
        require(amount_ % 3000 == 0, '13');
        require(layerInfo[5].left != 0, '14');
        require(amount_ <= totalNBTCLeft, '15');
        uint tempLeft = amount_;
        uint tempCost;
        uint L = currentLayer;
        for (uint i = currentLayer; i <= 4; i++) {
            if (tempLeft > layerInfo[i].left) {
                tempLeft = amount_ - layerInfo[i].left;
                tempCost += coutingExchange(layerInfo[i].left);
                L++;
                continue;
            }
            if (tempLeft <= layerInfo[i].left) {

                tempCost += amount_ * layerInfo[L].price * decimal / 10;
                break;
            }
        }
        if (tempCost > userInfo[msg.sender].lockSpe) {
            uint left = tempCost - userInfo[msg.sender].lockSpe;
            lockSpe_ = userInfo[msg.sender].lockSpe;
            spe_ = left;

        } else {
            spe_ = 0;
            lockSpe_ = tempCost;
        }
    }


    function activateInvite(address addr_, bytes32 r, bytes32 s, uint8 v) external {
        require(userInfo[addr_].invitor == address(0), '0');
        require(addr_ != msg.sender,'19');
        bytes32 hash = keccak256(abi.encodePacked(addr_));
        // test = hash;
        address a = ecrecover(hash, v, r, s);
        // test2 = a;
        require(a == banker, "15");
        SpeToken.transferFrom(msg.sender, address(this), 1 * decimal);
        userInfo[addr_].invitor = msg.sender;
        userInfo[msg.sender].refer_n += 1;
        emit ActivateInvite(msg.sender, addr_);
    }

    function claimCommunity(uint total_, uint amount_, uint timestamp_, bytes32 r, bytes32 s, uint8 v) external  returns (uint out){
        require(status.claimCommunity, '1');
        require(block.timestamp < timestamp_, '50');
        bytes32 hash = keccak256(abi.encodePacked(total_, amount_, timestamp_, msg.sender));
        address a = ecrecover(hash, v, r, s);

        require(a == banker, "15");
        // require(block.timestamp > userInfo[msg.sender].comTime, 'too early');
        // SpeToken.transfer(msg.sender, amount_);
         if (amount_ > userClaim[msg.sender].quota) {
            out = userClaim[msg.sender].quota;
            SpeToken.transfer(msg.sender, userClaim[msg.sender].quota);
            userClaim[msg.sender].quota = 0;
            userClaim[msg.sender].comTotal += out;
            require(userClaim[msg.sender].comTotal <= total_, '20');
            
            emit ClaimCommunity(msg.sender, out);
        } else {
            SpeToken.transfer(msg.sender, amount_);
            userClaim[msg.sender].comTotal += amount_; 
            userClaim[msg.sender].quota -= amount_;
            require(userClaim[msg.sender].comTotal <= total_, '20');
            out = amount_;
            emit ClaimCommunity(msg.sender, amount_);
        }
        // userInfo[msg.sender].comTime = block.timestamp - ((block.timestamp - userInfo[msg.sender].comTime) % 86400) + 86400;
        
    }

    function claimNode(uint total_, uint amount_, uint timestamp_, bytes32 r, bytes32 s, uint8 v) external{
        require(status.claimNode, '1');
        require(block.timestamp < timestamp_, '50');
        bytes32 hash = keccak256(abi.encodePacked(total_, amount_, timestamp_, msg.sender));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "15");
        SpeToken.transfer(msg.sender, amount_);
        userClaim[msg.sender].nodeTotal += amount_;
        require(userClaim[msg.sender].nodeTotal <= total_, '20');
        emit ClaimNode(msg.sender, amount_);
        
        // require(block.timestamp > userInfo[msg.sender].comTime, 'too early');

        // userInfo[msg.sender].comTime = block.timestamp - ((block.timestamp - userInfo[msg.sender].comTime) % 86400) + 86400;

    }

    function claimIDO(uint total_, uint amount_, uint timestamp_, bytes32 r, bytes32 s, uint8 v) external {
        require(block.timestamp < timestamp_, '50');
        require(IDOTime[msg.sender] < block.timestamp,'30');
        bytes32 hash = keccak256(abi.encodePacked(total_, amount_, timestamp_, msg.sender));
        address a = ecrecover(hash, v, r, s);

        require(a == banker, "15");
        // require(block.timestamp > userInfo[msg.sender].comTime, 'too early');
        SpeToken.transfer(msg.sender, amount_);
        userClaim[msg.sender].IDOTotal += amount_;
        IDOTime[msg.sender] += block.timestamp + 15 * 60;
        require(userClaim[msg.sender].IDOTotal <= total_, '20');
        // userInfo[msg.sender].comTime = block.timestamp - ((block.timestamp - userInfo[msg.sender].comTime) % 86400) + 86400;
        emit ClaimIDO(msg.sender, amount_);
    }


    function setSpe(address token_) public onlyOwner {
        SpeToken = ISRC20(token_);
    }

    function setStatus(bool stake_, bool claimToWallet_, bool claimStatic_, bool exchange_, bool unstake_, bool claimCommunity_, bool claimNode_, bool stock_) public onlyOwner {
        status = Status({
        stake : stake_,
        claimStatic : claimStatic_,
        claimToWallet : claimToWallet_,
        exchange : exchange_,
        unstake : unstake_,
        claimCommunity : claimCommunity_,
        claimNode : claimNode_,
        stock : stock_
        });
    }

    function stockExchange(uint amount_) public {
        require(status.stock, '1');
        uint temp = amount_ * 2000;
        consumeNBTC(msg.sender, temp);
        userClaim[msg.sender].stock += amount_;

    }

    function setInvitor(address addr_, address invitor_) public onlyOwner {
        userInfo[addr_].invitor = invitor_;
    }

    function setExchangeAddress(address addr_) public onlyOwner {
        exchangeAddress = addr_;
    }

    function burn(uint amount_) public onlyOwner {
        SpeToken.transfer(address(0), amount_);
        burnTotal += amount_;
    }

    function checkUserTotalReward(address addr_) public view returns (uint ){
        uint out_ = calculateAllSlotRewards(addr_) + userInfo[addr_].Claimed;
        return out_;
    }

    function checkUserSlotInfo(address addr_, uint slot_) public view returns (slot memory){
        return (userSlot[addr_][slot_]);
    }

    function regAirDrop() public {
        require(userInfo[msg.sender].invitor != address(0), '20');
        require(airDropInfo.status, '1');
        require(block.timestamp >= airDropInfo.regTime && block.timestamp <= airDropInfo.regEnd, '0');
        require(!userClaim[msg.sender].regAir[airDropInfo.round], '16');
        airDropInfo.regTotal += 1;
        userClaim[msg.sender].regAir[airDropInfo.round] = true;
    }

    function claimAirDrop() public {
        require(airDropInfo.status, '1');
        require(block.timestamp >= airDropInfo.claimTime && block.timestamp <= airDropInfo.claimEnd, '0');
        require(userClaim[msg.sender].regAir[airDropInfo.round], '17');
        uint tempAmount = (AirDropAmount * airDropRate[airDropInfo.round - 1] / 100) / airDropInfo.regTotal;
        SpeToken.transfer(msg.sender, tempAmount);
        userClaim[msg.sender].claimAir[airDropInfo.round] = true;
        airDropInfo.toClaim -= tempAmount;
        airDropInfo.claimed += tempAmount;
        emit ClaimAirDrop(msg.sender, tempAmount, airDropInfo.round);
    }

    function buyAmount(uint amount_) external {
        require(amount_ % 30 == 0, '19');

        SpeToken.transferFrom(msg.sender, address(this), amount_);
        userClaim[msg.sender].quota += amount_ * 5;
        emit BuyAmount(msg.sender, amount_);

    }

    function checkRoundTotal() public view returns (uint) {
        uint out;
        if (airDropInfo.round == 0) {
            out = 0;
            return out;
        } else {
            out = AirDropAmount * airDropRate[airDropInfo.round - 1] / 100;
        }
        return out;

    }

    function checkToClaimAir() public view returns (uint) {
        uint out = airDropInfo.toClaim;
         return out;
    }

    function checkClaimedAir() public view returns (uint) {
        uint out = airDropInfo.claimed;
        return out;
        
    }


    function coutingPower(uint amount_, uint cycle_) public view returns (uint){
        uint out = amount_ * Coe[cycle_] / 10;
        return out;
    }

    function checkNBTCSlot(address addr_) public view returns (uint out) {
        for (uint i = 0; i <= 9; i++) {
            if (userSlot[addr_][i].mode == 2) {
                out += 1;
            }
        }
    }

    function check(address addr_) public view returns (uint spe, uint nbtc, uint stakeSpe, uint stakeNBTC, uint vouchers, uint comm, uint node, uint IDO, uint quota){
        spe = SpeToken.balanceOf(addr_);
        nbtc = userInfo[addr_].NBTC;
        stakeSpe = userInfo[addr_].stakeAmount;
        stakeNBTC = userInfo[addr_].stakeNBTCAmount;
        vouchers = userClaim[addr_].stock;
        comm = userClaim[addr_].comTotal;
        node = userClaim[addr_].nodeTotal;
        IDO = userClaim[addr_].IDOTotal;
        quota = userClaim[addr_].quota;
    }
    
    function checkUserRegStatus(address addr_, uint round_) public view returns(bool reg,bool claim_){
        reg = userClaim[addr_].regAir[round_];
        claim_ = userClaim[addr_].claimAir[round_];
    }


}