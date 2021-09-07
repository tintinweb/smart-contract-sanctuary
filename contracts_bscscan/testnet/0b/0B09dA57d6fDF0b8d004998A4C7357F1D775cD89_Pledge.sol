/**
 *Submitted for verification at BscScan.com on 2021-09-06
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

interface AirDrop {
    function openAirDrop(uint round_) external;

    function closeAirDrop() external;

    function status() external view returns (bool);

    function round() external view returns (uint);

    function claimEnd() external view returns (uint);
    
    function toClaim() external view returns(uint);
    
}
interface Claim{
    function userClaim(address addr_) external view returns( uint comTotal,
        uint nodeTotal,
        uint IDOTotal,
        uint quota);
}

contract Pledge is Ownable {
    ISRC20 public SpeToken;
    AirDrop public air;
    Claim public claim;
    uint public priceNBTC = 3;
    address public constant banker = 0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954;
    uint public dayOutPut;
    uint public rate;
    uint[5] public  cycle = [600, 60 * 15, 30 * 60, 60 * 60, 90 * 60];
    uint[5] public  Coe = [6, 8, 10, 11, 12]; //算力系数
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
    // address public dele;




    event GetNBTC(address indexed sender, uint indexed amount_);
    event CosumeNBTC(address indexed sender, uint indexed amount_);
    event StakeSpe(address indexed sender_, uint indexed slot_, uint indexed amount_, uint cycle_);
    event StakeNBTC(address indexed sender_, uint indexed slot_, uint indexed amount_, uint cycle_);
    event ActivateInvite(address indexed invitor_, address indexed refer_);

    event ClaimStatic(address indexed sender_, uint indexed amount_);
    event UnStake(address indexed sender_, uint indexed amount_, uint indexed slot_);
    event Exchange(address indexed sender_, uint indexed amount_, uint indexed cost_);
    event ClaimToWallet(address indexed sender_, uint indexed amount_);


    struct Status {
        bool stake;
        bool exchange;
        bool claimStatic;
        bool claimToWallet;
        bool unstake;
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
    }

    // mapping(address => userSlot)slotInfo;
    struct UserInfo {
        uint NBTC;
        uint stock;
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


    mapping(address => mapping(uint => slot)) public userSlotSPE;
    mapping(address => mapping(uint => slot)) public userSlotNBTC;


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
        if (air.status()) {
            if (block .timestamp > air.claimEnd()) {
                air.closeAirDrop();

            }
        } else if (temp > 25 && air.round() == 1) {
            air.openAirDrop(2);
        } else if (temp > 15 && air.round() == 0) {
            air.openAirDrop(1);
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

    function calculateSPESlotRewards(address addr_, uint slot_) public view returns (uint) {
        require(slot_ >= 0 && slot_ <= 9, '4');
        require(userSlotSPE[addr_][slot_].stakeAmount > 0, '2');
        // rewards = userSlot[addr_][slot_].power * (coutingDebt() - userSlot[addr_][slot_].debt) / Acc;
        uint tempDebt;
        uint rewards;
        // uint reward;
        if (block.timestamp >= userSlotSPE[msg.sender][slot_].endTime && userSlotSPE[msg.sender][slot_].stakeTime < userSlotSPE[msg.sender][slot_].endTime) {
            tempDebt = (rate * 4 / 10) * (userSlotSPE[msg.sender][slot_].endTime - userSlotSPE[msg.sender][slot_].stakeTime) * Acc / totalPower;
            rewards = tempDebt * userSlotSPE[msg.sender][slot_].power / Acc;

        } else if (block.timestamp < userSlotSPE[msg.sender][slot_].endTime) {
            tempDebt = coutingDebt();
            rewards = userSlotSPE[msg.sender][slot_].power * (tempDebt - userSlotSPE[msg.sender][slot_].debt) / Acc;

        }
        return rewards;
    }

    function calculateNBTCSlotRewards(address addr_, uint slot_) public view returns (uint) {
        require(slot_ >= 0 && slot_ <= 9, '4');
        require(userSlotNBTC[addr_][slot_].stakeAmount > 0, '2');
        // rewards = userSlot[addr_][slot_].power * (coutingDebt() - userSlot[addr_][slot_].debt) / Acc;
        uint tempDebt;
        uint rewards;
        // uint reward;
        if (block.timestamp >= userSlotNBTC[msg.sender][slot_].endTime && userSlotNBTC[msg.sender][slot_].stakeTime < userSlotNBTC[msg.sender][slot_].endTime) {
            tempDebt = (rate * 4 / 10) * (userSlotNBTC[msg.sender][slot_].endTime - userSlotNBTC[msg.sender][slot_].stakeTime) * Acc / totalPower;
            rewards = tempDebt * userSlotNBTC[msg.sender][slot_].power / Acc;

        } else if (block.timestamp < userSlotNBTC[msg.sender][slot_].endTime) {
            tempDebt = coutingDebt();
            rewards = userSlotNBTC[msg.sender][slot_].power * (tempDebt - userSlotNBTC[msg.sender][slot_].debt) / Acc;

        }
        return rewards;
    }


    function calculateAllSlotRewards(address addr_) public view returns (uint){
        uint rewards;
        for (uint i = 0; i <= 9; i++) {
            if (userSlotSPE[addr_][i].status) {
                rewards += calculateSPESlotRewards(addr_, i);

            } else {
                continue;
            }
            if (userSlotNBTC[addr_][i].status) {
                rewards += calculateNBTCSlotRewards(addr_, i);

            } else {
                continue;
            }
        }

        return rewards;
    }

    function checkUserSPESlotNum() public view returns (uint[10] memory out){
        for (uint i = 0; i <= 9; i++) {
            if (userSlotSPE[msg.sender][i].status) {
                out[i] = 1;

            } else {
                continue;
            }
        }
    }

    function checkUserNBTCSlotNum() public view returns (uint[10] memory out){
        for (uint i = 0; i <= 9; i++) {
            if (userSlotNBTC[msg.sender][i].status) {
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
        require(!userSlotSPE[msg.sender][slot_].status, '8');
        require(SpeToken.transferFrom(msg.sender, address(this), amount_), '9');
        uint nowdebt = coutingDebt();
        uint tempPower = amount_ * Coe[cycle_] / 10;
        userSlotSPE[msg.sender][slot_] = slot({
        status : true,
        stakeAmount : amount_,
        debt : nowdebt,
        stakeTime : block.timestamp,
        power : tempPower,
        endTime : block.timestamp + cycle[cycle_]
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
        require(!userSlotNBTC[msg.sender][slot_].status, '8');
        require(userInfo[msg.sender].NBTC >= amount_, '10');
        consumeNBTC(msg.sender, amount_);
        uint nowdebt = coutingDebt();
        uint tempPower = tempSPE * Coe[cycle_] * 15 / 100;
        NBTCTVL += amount_;
        userSlotNBTC[msg.sender][slot_] = slot({
        status : true,
        stakeAmount : amount_,
        debt : nowdebt,
        stakeTime : block.timestamp,
        power : tempPower,
        endTime : block.timestamp + cycle[cycle_]
        });

        userInfo[msg.sender].stakeNBTCAmount += amount_;
        userInfo[msg.sender].finalPower += tempPower;
        debt.debted = nowdebt;
        debt.timestamp = block.timestamp;
        totalPower += tempPower;
        emit StakeNBTC(msg.sender, slot_, amount_, cycle[cycle_]);

    }


    function claimStatic(uint slot_, uint mode_) isStart checkTime checkHolder internal returns (uint out_) {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("claimStatic(uint256)",slot_));
        require(status.claimStatic, '1');
        require(slot_ >= 0 && slot_ <= 9, '4');
        require(mode_ == 0 || mode_ == 1, '18');

        // require(userSlot[msg.sender][slot_].stakeTime <userSlot[msg.sender][slot_].endTime );
        uint tempDebt;
        uint reward;
        if (mode_ == 0) {
            require(userSlotSPE[msg.sender][slot_].stakeAmount > 0, '2');
            if (block.timestamp >= userSlotSPE[msg.sender][slot_].endTime && userSlotSPE[msg.sender][slot_].stakeTime < userSlotSPE[msg.sender][slot_].endTime) {
                tempDebt = (rate * 4 / 10) * (userSlotSPE[msg.sender][slot_].endTime - userSlotSPE[msg.sender][slot_].stakeTime) * Acc / totalPower;
                reward = tempDebt * userSlotSPE[msg.sender][slot_].power / Acc;
                out_ = reward * 9 / 10;
                userInfo[msg.sender].lockSpe += reward * 1 / 10;
                userInfo[msg.sender].Claimed += out_;
                userSlotSPE[msg.sender][slot_].stakeTime = block.timestamp;
                userSlotSPE[msg.sender][slot_].debt = coutingDebt();
            } else if (block.timestamp < userSlotSPE[msg.sender][slot_].endTime) {
                tempDebt = coutingDebt();
                reward = userSlotSPE[msg.sender][slot_].power * (tempDebt - userSlotSPE[msg.sender][slot_].debt) / Acc;
                out_ = reward * 9 / 10;
                userInfo[msg.sender].Claimed += out_;
                userInfo[msg.sender].lockSpe += reward * 1 / 10;
                userSlotSPE[msg.sender][slot_].stakeTime = block.timestamp;
                userSlotSPE[msg.sender][slot_].debt = tempDebt;
            }
        } else {
            require(userSlotNBTC[msg.sender][slot_].stakeAmount > 0, '2');
            if (block.timestamp >= userSlotNBTC[msg.sender][slot_].endTime && userSlotNBTC[msg.sender][slot_].stakeTime < userSlotNBTC[msg.sender][slot_].endTime) {
                tempDebt = (rate * 4 / 10) * (userSlotNBTC[msg.sender][slot_].endTime - userSlotNBTC[msg.sender][slot_].stakeTime) * Acc / totalPower;
                reward = tempDebt * userSlotSPE[msg.sender][slot_].power / Acc;
                out_ = reward * 9 / 10;
                userInfo[msg.sender].lockSpe += reward * 1 / 10;
                userInfo[msg.sender].Claimed += out_;
                userSlotNBTC[msg.sender][slot_].stakeTime = block.timestamp;
                userSlotNBTC[msg.sender][slot_].debt = coutingDebt();
            } else if (block.timestamp < userSlotNBTC[msg.sender][slot_].endTime) {
                tempDebt = coutingDebt();
                reward = userSlotNBTC[msg.sender][slot_].power * (tempDebt - userSlotNBTC[msg.sender][slot_].debt) / Acc;
                out_ = reward * 9 / 10;
                userInfo[msg.sender].Claimed += out_;
                userInfo[msg.sender].lockSpe += reward * 1 / 10;
                userSlotNBTC[msg.sender][slot_].stakeTime = block.timestamp;
                userSlotNBTC[msg.sender][slot_].debt = tempDebt;
            }
        }

        emit ClaimStatic(msg.sender, reward);

    }


    function unStake(uint slot_, uint mode_) isStart checkTime checkHolder public {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("unStake(uint256)",slot_));
        require(status.unstake, '1');
        require(slot_ >= 0 && slot_ <= 9, '4');
        require(mode_ == 0 || mode_ == 1, '18');
        require(userSlotSPE[msg.sender][slot_].stakeAmount > 0, '2');
        require(userSlotSPE[msg.sender][slot_].endTime < block.timestamp, 'not time');
        uint tempAmount = userSlotSPE[msg.sender][slot_].stakeAmount;
        uint tempPower = userSlotSPE[msg.sender][slot_].power;
        if (mode_ == 0) {
            uint temp = claimStatic(slot_, mode_);
            userSlotSPE[msg.sender][slot_] = slot({
            status : false,
            stakeAmount : 0,
            debt : 0,
            stakeTime : 0,
            power : 0,
            endTime : 0
            });
            totalPower -= tempPower;
            TVL -= tempAmount;
            userInfo[msg.sender].finalPower -= tempPower;
            userInfo[msg.sender].stakeAmount -= tempAmount;
            SpeToken.transfer(msg.sender, tempAmount + (temp * 99 / 100));
            if (temp != 0) {

                userInfo[msg.sender].Claimed += temp * 99 / 100;
                SpeToken.transfer(address(0), temp / 100);
                burnTotal += temp / 100;
            }
        }
        else if (mode_ == 1) {

            uint temp = claimStatic(slot_, mode_);
            SpeToken.transfer(msg.sender, tempAmount + (temp * 99 / 100));
            SpeToken.transfer(address(0), temp / 100);
            burnTotal += temp / 100;
            userSlotNBTC[msg.sender][slot_] = slot({
            status : false,
            stakeAmount : 0,
            debt : 0,
            stakeTime : 0,
            power : 0,
            endTime : 0
            });
            totalPower -= tempPower;
            NBTCTVL -= tempAmount;
            userInfo[msg.sender].finalPower -= tempPower;
            userInfo[msg.sender].stakeNBTCAmount -= tempAmount;
            getNBTC(msg.sender, tempAmount);
            if (temp != 0) {
                userInfo[msg.sender].Claimed += temp * 99 / 100;
                SpeToken.transfer(msg.sender, temp * 99 / 100);
                SpeToken.transfer(address(0), temp / 100);
                burnTotal += temp / 100;
            }


        }
        emit UnStake(msg.sender, tempAmount, slot_);
    }

    function claimStaticAll() external {
        uint temp;
        for (uint i = 0; i <= 9; i++) {
            if (userSlotSPE[msg.sender][i].status) {
                temp += claimStatic(i, 0);


            } else {
                continue;
            }
            if (userSlotNBTC[msg.sender][i].status) {
                temp += claimStatic(i, 1);


            } else {
                continue;
            }
        }
        SpeToken.transfer(msg.sender, temp * 99 / 100);
        SpeToken.transfer(address(0), temp / 100);
        burnTotal += temp / 100;
        emit ClaimToWallet(msg.sender, temp * 99 / 100);
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

    function exchange(uint amount_) isStart checkTime  external {
        require(userInfo[msg.sender].invitor != address(0), '20');
        require(status.exchange, '1');
        require(amount_ % 10 == 0, '13');
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
        require(addr_ != msg.sender, '19');
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


    function setSpe(address token_) public onlyOwner {
        SpeToken = ISRC20(token_);
    }

    function setStatus(bool stake_, bool claimToWallet_, bool claimStatic_, bool exchange_, bool unstake_, bool stock_) public onlyOwner {
        status = Status({
        stake : stake_,
        claimStatic : claimStatic_,
        claimToWallet : claimToWallet_,
        exchange : exchange_,
        unstake : unstake_,
        stock : stock_
        });
    }

    function stockExchange(uint amount_) public {
        require(status.stock, '1');
        uint temp = amount_ * 2000;
        consumeNBTC(msg.sender, temp);
        userInfo[msg.sender].stock += amount_;

    }

    function setInvitor(address addr_, address invitor_) public onlyOwner {
        userInfo[addr_].invitor = invitor_;
    }
    
    function checkUserInvitor(address addr_) public view returns(address out){
        out = userInfo[addr_].invitor;
    }

    function setExchangeAddress(address addr_) public onlyOwner {
        exchangeAddress = addr_;
    }
    
    function setAir(address addr_) public onlyOwner {
        air = AirDrop(addr_);
    }

    function burn(uint amount_) public onlyOwner {
        SpeToken.transfer(address(0), amount_);
        burnTotal += amount_;
    }

    function checkUserTotalReward(address addr_) public view returns (uint){
        uint out_ = calculateAllSlotRewards(addr_) + userInfo[addr_].Claimed;
        return out_;
    }

    function checkUserSlotInfo(address addr_, uint slot_, uint mode_) public view returns (slot memory){
        require(mode_ == 0 || mode_ == 1, '18');
        if (mode_ == 0) {
            return (userSlotSPE[addr_][slot_]);
        } else {
            return (userSlotNBTC[addr_][slot_]);
        }

    }

    function coutingPower(uint amount_, uint cycle_) public view returns (uint){
        uint out = amount_ * Coe[cycle_] / 10;
        return out;
    }
    function changeLayerInfo(uint layer_, uint left_, uint price_)public onlyOwner {
        layerInfo[layer_] = LayerInfo({
                        left : left_,
                        price : price_
        });
    }



    function check(address addr_) public view returns (uint spe, uint nbtc, uint stakeSpe, uint stakeNBTC, uint vouchers, uint comm, uint node, uint IDO, uint quota){
        spe = SpeToken.balanceOf(addr_);
        nbtc = userInfo[addr_].NBTC;
        stakeSpe = userInfo[addr_].stakeAmount;
        stakeNBTC = userInfo[addr_].stakeNBTCAmount;
        vouchers = userInfo[addr_].stock;
        (comm,node,IDO,quota)= claim.userClaim(addr_);
         
    }

}