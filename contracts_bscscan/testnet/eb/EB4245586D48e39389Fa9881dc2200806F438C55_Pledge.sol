/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

library Address {

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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


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

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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
    uint public priceNBCT = 3;
    address public banker = 0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954;
    uint public upTime;
    uint public dayOutPut;
    uint public rate;
    uint[5] public cycle = [600, 15 days, 30 days, 60 days, 90 days];
    uint[5] public Coe = [8, 9, 10, 11, 12]; //算力系数
    uint public startTime;
    uint public decimal = 1e18;
    bool public statusAll;
    uint public Acc = 1e10;
    uint public TVL;
    uint public NBTCTVL;
    uint public totalPower;
    uint public currentLayer = 1;
    uint[5] public price = [3, 4, 5, 8, 10];
    uint public totalNBTCLeft = 3000000 * 5;
    address public exchangeAddress;
    uint public burnTotal;
    // address public dele;




    event GetNBTC(address indexed sender, uint indexed amount_);
    event CosumeNBCT(address indexed sender, uint indexed amount_);
    event StakeSpe(address indexed sender_, uint indexed slot_, uint indexed amount_);
    event StakeNBTC(address indexed sender_, uint indexed slot_, uint indexed amount_, uint price_);
    event ActivateInvite(address indexed invitor_, address indexed refer_);
    event ClaimCommunity (address indexed sender_, uint indexed amount_);
    event ClaimStatic(address indexed sender_, uint indexed amount_);
    event UnStake(address indexed sender_, uint indexed amount_, uint indexed slot_);
    event Exchange(address indexed sender_, uint indexed amount_,uint indexed cost_);
    event ClaimToWallet(address indexed sender_,uint indexed amount_);
    event ClaimNode(address indexed sender_, uint indexed amount_);

    struct Status {
        bool stake;
        bool exchange;
        bool claimStatic;
        bool claimToWallet;
        bool unstake;
        bool claimCommunity;
        bool claimNode;
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
        uint NBCT;
        uint finalPower;
        uint stakeAmount;
        uint stakeNBTCAmount;
        address invitor;
        uint refer_n;
        uint toClaim;
        uint Claimed;
        uint lockSpe;
        uint lastClearTime;
        uint comTotal;
        uint nodeTotal;
        mapping(uint => slot) userSlot;

    }

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
    modifier checkMounth{
        if (userInfo[msg.sender].lastClearTime == 0 ){
            userInfo[msg.sender].lastClearTime = block.timestamp + 60 days;
        }else if (block.timestamp > userInfo[msg.sender].lastClearTime){
            userInfo[msg.sender].Claimed =0;
        }
        _;
    }
    modifier isStart{
        require(statusAll, '1');
        _;
    }
    function setInit() public onlyOwner {
        require(!statusAll,'7');
        startTime = block.timestamp;

        statusAll = true;
    }
    constructor(){
        priceNBCT = layerInfo[currentLayer].price;
        dayOutPut = 6693000 * decimal / 365;
        rate = dayOutPut / 1 days;

        for (uint i = 0; i < 5; i ++) {
            layerInfo[i + 1] = LayerInfo({
            left : 3000000,
            price : price[i]
            });
        }


    }
    function coutingDebt() public view returns (uint debt_){
        debt_ = totalPower > 0 ? (rate * 4 / 10) * (block.timestamp - debt.timestamp) * Acc / totalPower + debt.debted : 0;

    }

    function calculateSlotRewards(address addr_, uint slot_) public view returns (uint rewards) {
        require(slot_ >= 1 && slot_ <= 10, '4');
        require(userInfo[addr_].userSlot[slot_].stakeAmount > 0, '2');
        rewards = userInfo[addr_].stakeAmount * (coutingDebt() - userInfo[addr_].userSlot[slot_].debt) / Acc;
    }

    function calculateAllSlotRewards(address addr_) public view returns (uint rewards){
        for (uint i = 1; i <= 10; i++) {
            if (userInfo[addr_].userSlot[i].status) {
                rewards += calculateSlotRewards(addr_, i);

            } else {
                continue;
            }
        }
    }

    function checkUserSlotNum() public view returns (uint[10] memory out){
        for (uint i = 1; i <= 10; i++) {
            if (userInfo[msg.sender].userSlot[i].status) {
                out[i] = 1;

            } else {
                continue;
            }
        }
    }

    function stakeWithSpe(uint slot_, uint amount_, uint cycle_) isStart public {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("stakeWithSpe(uint256,uint256,uint256)",slot_,amount_,cycle_));
        require(status.stake, '3');
        require(slot_ >= 1 && slot_ <= 10, '4');
        require(cycle_ >= 1 && cycle_ <= 5, '5');
        require(amount_ >= 30 * decimal, '6');
        require(!userInfo[msg.sender].userSlot[slot_].status, '8');
        require(SpeToken.transferFrom(msg.sender, address(this), amount_), '9');
        uint nowdebt = coutingDebt();
        uint tempPower = amount_ * Coe[cycle_ - 1] / 10;
        userInfo[msg.sender].userSlot[slot_] = slot({
        status : true,
        stakeAmount : amount_,
        debt : nowdebt,
        stakeTime : block.timestamp,
        power : tempPower,
        endTime : block.timestamp + cycle[cycle_ - 1],
        mode : 1
        });

        userInfo[msg.sender].stakeAmount += amount_;
        userInfo[msg.sender].finalPower += tempPower;
        debt.debted = nowdebt;
        debt.timestamp = block.timestamp;
        TVL += amount_;
        totalPower += tempPower;
        emit StakeSpe(msg.sender, slot_, amount_);
        
    }

    function stakeWithNBTC(uint slot_, uint amount_, uint cycle_) isStart public {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("stakeWithNBTC(uint256,uint256,uint256)",slot_,amount_,cycle_));
        require(status.stake, '3');
        require(slot_ >= 1 && slot_ <= 10, '4');
        require(cycle_ >= 1 && cycle_ <= 5, '5');
        priceNBCT = layerInfo[currentLayer].price;
        uint tempSPE = amount_ * priceNBCT * decimal / 10;
        require(tempSPE >= 30, '6');
        require(!userInfo[msg.sender].userSlot[slot_].status, '8');
        require(userInfo[msg.sender].NBCT >= amount_, '10');
        consumeNBCT(msg.sender,amount_);
        uint nowdebt = coutingDebt();
        uint tempPower = tempSPE * 15 / 10;
        NBTCTVL += amount_;
        userInfo[msg.sender].userSlot[slot_] = slot({
        status : true,
        stakeAmount : amount_,
        debt : nowdebt,
        stakeTime : block.timestamp,
        power : tempPower,
        endTime : block.timestamp + cycle[cycle_ - 1],
        mode : 2
        });

        userInfo[msg.sender].stakeNBTCAmount += amount_;
        userInfo[msg.sender].finalPower += tempPower;
        debt.debted = nowdebt;
        debt.timestamp = block.timestamp;
        totalPower += tempPower;
        emit StakeNBTC(msg.sender, slot_, amount_, priceNBCT);
        
    }

    function reStake(uint slot_, uint cycle_) isStart public {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("reStake(uint256,uint256)",slot_,cycle_));
        require(block.timestamp > userInfo[msg.sender].userSlot[slot_].endTime, '11');
        claimStatic(slot_);
        uint amount_ = userInfo[msg.sender].userSlot[slot_].stakeAmount;
        if (userInfo[msg.sender].userSlot[slot_].mode == 1) {
            uint tempPower = amount_ * Coe[cycle_ - 1];
            userInfo[msg.sender].userSlot[slot_] = slot({
            status : true,
            stakeAmount : amount_,
            debt : coutingDebt(),
            stakeTime : block.timestamp,
            power : tempPower,
            endTime : block.timestamp + cycle[cycle_ - 1],
            mode : 1
            });
            emit StakeSpe(msg.sender, slot_, amount_);
        
    }
    }

    function claimStatic(uint slot_) isStart public {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("claimStatic(uint256)",slot_));
        require(status.claimStatic, '1');
        require(slot_ >= 1 && slot_ <= 10, '4');
        require(userInfo[msg.sender].userSlot[slot_].stakeAmount > 0, '2');
        // require(userInfo[msg.sender].userSlot[slot_].stakeTime <userInfo[msg.sender].userSlot[slot_].endTime );
        uint tempDebt;
        uint reward;
        if (block.timestamp >= userInfo[msg.sender].userSlot[slot_].endTime && userInfo[msg.sender].userSlot[slot_].stakeTime < userInfo[msg.sender].userSlot[slot_].endTime) {
            tempDebt = (rate * 4 / 10) * (userInfo[msg.sender].userSlot[slot_].endTime - userInfo[msg.sender].userSlot[slot_].stakeTime) * Acc / totalPower;
            reward = tempDebt * userInfo[msg.sender].userSlot[slot_].power;
            userInfo[msg.sender].toClaim += reward;
            userInfo[msg.sender].userSlot[slot_].stakeTime = block.timestamp;
            userInfo[msg.sender].userSlot[slot_].debt = coutingDebt();
        } else if (block.timestamp < userInfo[msg.sender].userSlot[slot_].endTime) {
            tempDebt = coutingDebt();
            reward = userInfo[msg.sender].userSlot[slot_].power * (tempDebt - userInfo[msg.sender].userSlot[slot_].debt) / Acc;
            userInfo[msg.sender].toClaim += reward * 9 / 10;
            userInfo[msg.sender].lockSpe += reward * 1 / 10;
            userInfo[msg.sender].userSlot[slot_].stakeTime = block.timestamp;
            userInfo[msg.sender].userSlot[slot_].debt = tempDebt;
        }
        emit ClaimStatic(msg.sender, reward);

    }

    function unStake(uint slot_) isStart public {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("unStake(uint256)",slot_));
        require(status.unstake, '1');
        require(slot_ >= 1 && slot_ <= 10, '4');
        require(userInfo[msg.sender].userSlot[slot_].stakeAmount > 0, '2');
        require(userInfo[msg.sender].userSlot[slot_].endTime < block.timestamp, 'not time');
        require(userInfo[msg.sender].userSlot[slot_].mode != 0, 'worng');
        uint tempAmount = userInfo[msg.sender].userSlot[slot_].stakeAmount;
        uint tempPower = userInfo[msg.sender].userSlot[slot_].power;
        if (userInfo[msg.sender].userSlot[slot_].mode == 1) {
            claimStatic(slot_);
            userInfo[msg.sender].userSlot[slot_] = userInfo[msg.sender].userSlot[slot_] = slot({
            status : false,
            stakeAmount : 0,
            debt : 0,
            stakeTime : 0,
            power : 0,
            endTime : 0,
            mode : 0
            });
            totalPower -= tempPower;
            SpeToken.transfer(msg.sender, tempAmount);
        }
        else if (userInfo[msg.sender].userSlot[slot_].mode == 2) {
            claimStatic(slot_);
            userInfo[msg.sender].userSlot[slot_] = userInfo[msg.sender].userSlot[slot_] = slot({
            status : false,
            stakeAmount : 0,
            debt : 0,
            stakeTime : 0,
            power : 0,
            endTime : 0,
            mode : 0
            });
            totalPower -= tempPower;
            getNBTC(msg.sender,tempAmount);

        }
        emit UnStake(msg.sender, tempAmount, slot_);
    }

    function claimStaticAll() external {
        for (uint i = 1; i <= 10; i++) {
            if (userInfo[msg.sender].userSlot[i].status) {
                claimStatic(i);

            } else {
                continue;
            }
        }
    }

    function unstakAll() external {
        for (uint i = 1; i <= 10; i++) {
            if (userInfo[msg.sender].userSlot[i].status) {
                unStake(i);

            } else {
                continue;
            }
        }
    }


    function getNBTC(address addr_, uint amount_) internal {
        userInfo[addr_].NBCT += amount_;
        emit GetNBTC(addr_, amount_);
    }

    function consumeNBCT(address addr_, uint amount_) internal {
        userInfo[addr_].NBCT -= amount_;
        emit CosumeNBCT(addr_, amount_);
    }


    function claimToWallet() isStart external {
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("claimToWallet()"));
        require(status.claimToWallet, '1');
        require(userInfo[msg.sender].toClaim > 0, '12');
        uint tempReward = userInfo[msg.sender].toClaim;
        SpeToken.transfer(msg.sender, tempReward * 99 / 100);
        SpeToken.transfer(address(0), tempReward * 1 / 100);
        burnTotal += tempReward * 1 / 100;
        userInfo[msg.sender].toClaim = 0;
        userInfo[msg.sender].Claimed += tempReward;
         emit ClaimToWallet(msg.sender,tempReward);
    }

    function coutingExchange(uint amount_) internal view returns (uint cost){
        cost = amount_ * layerInfo[currentLayer].price * decimal / 10;
    }

    function exchange(uint amount_) isStart external {
        // require(status.exchange, '1');
        // require(amount_ % 3000 == 0, '13');
        // require(layerInfo[5].left != 0, '14');
        // require(amount_ < totalNBTCLeft, '15');
        //  Address.functionDelegateCall(dele,abi.encodeWithSignature("exchange(uint256)",amount_));
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
        priceNBCT = layerInfo[currentLayer].price;
        emit Exchange(msg.sender,amount_,tempCost);
    }

    function coutingCost(uint amount_) public view returns (uint lockSpe_, uint spe_){
        require(amount_ % 3000 == 0, '13');
        require(layerInfo[5].left != 0, '14');
        require(amount_ < totalNBTCLeft, '15');
        uint tempLeft = amount_;
        uint tempCost;
        uint L = currentLayer;
        for (uint i = currentLayer; i <= 5; i++) {
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


    function activateInvite(address addr_, bytes32 r, bytes32 s, uint8 v) isStart external {
        require(userInfo[addr_].invitor == address(0), '0');
        require(addr_ != msg.sender);
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

    function claimCommunity(uint total_,uint amount_ , uint timestamp_, bytes32 r, bytes32 s, uint8 v) isStart external {
        require(status.claimCommunity, '1');
        require(block.timestamp < timestamp_,'50');
        bytes32 hash = keccak256(abi.encodePacked(total_,amount_,timestamp_,msg.sender));
        address a = ecrecover(hash, v, r, s);
  
        require(a == banker, "15");
        // require(block.timestamp > userInfo[msg.sender].comTime, 'too early');
        SpeToken.transfer(msg.sender, amount_);
        userInfo[msg.sender].comTotal += amount_;
        require(userInfo[msg.sender].comTotal <= total_,'20');
        // userInfo[msg.sender].comTime = block.timestamp - ((block.timestamp - userInfo[msg.sender].comTime) % 86400) + 86400;
        emit ClaimCommunity(msg.sender, amount_);
    }
    function claimNode(uint total_,uint amount_ , uint timestamp_, bytes32 r, bytes32 s, uint8 v) isStart external {
        require(status.claimNode,'1');
        require(block.timestamp < timestamp_,'50');
        bytes32 hash = keccak256(abi.encodePacked(total_,amount_,timestamp_,msg.sender));
        address a = ecrecover(hash, v, r, s);
  
        require(a == banker, "15");
        // require(block.timestamp > userInfo[msg.sender].comTime, 'too early');
        SpeToken.transfer(msg.sender, amount_);
        userInfo[msg.sender].nodeTotal += amount_;
        require(userInfo[msg.sender].nodeTotal <= total_,'20');
        // userInfo[msg.sender].comTime = block.timestamp - ((block.timestamp - userInfo[msg.sender].comTime) % 86400) + 86400;
        emit ClaimNode(msg.sender, amount_);
    }

    function setSpe(address token_) public onlyOwner {
        SpeToken = ISRC20(token_);
    }

    function setStatus(bool stake_, bool claimToWallet_, bool claimStatic_, bool exchange_, bool unstake_, bool claimCommunity_, bool claimNode_) public onlyOwner {
        status = Status({
        stake : stake_,
        claimStatic : claimStatic_,
        claimToWallet : claimToWallet_,
        exchange : exchange_,
        unstake : unstake_,
        claimCommunity : claimCommunity_,
        claimNode : claimNode_
        });
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
    function checkUserTotalReward(address addr_) public view returns(uint out_){
        out_ = calculateAllSlotRewards(addr_) + userInfo[addr_].Claimed + userInfo[addr_].toClaim;
    }
    function checkUserSlotInfo(address addr_,uint slot_) public view returns(slot memory){
        return(userInfo[addr_].userSlot[slot_]);
    }
    
    // function setDele(address addr_) public onlyOwner{
    //     dele = addr_;
    // }


}