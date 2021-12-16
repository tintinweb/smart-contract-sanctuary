/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface BEP20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}




contract shpadStaking {

    struct Stake {
        bool staked;
        uint stakedAmount;
        uint stakedTime;
        uint stakedNum;
        uint stakedShare;
        uint stakedTypeCoin;
        Deposit[] deposits;
    }
    /*
    stakedNum - number of staking type,
    share - share of ...,
    stakedTypeCoin: 0 - shpad, 1 - usdt
    stakedAllNum - number all staking
    */

    struct Deposit {
        uint amount;
        uint timeStake;
        uint typeStake;
        uint active;
        uint endTime;
    }

    /*
    typeStake: 0 - funds
        1... - buying share
    active: true, false
    endTime - end time of staking (+ 30 days)
    */

    event Staked(address, uint);
    event Received(address, uint);

    mapping(address => Stake) public user;
    address public contractAddr = address(this);
    address public stakeTokenAddr = 0xDdDFAB53EEFc866ec4e62580543E2514A2e1C1d3;
    address[] public userAddressArr;


    uint Launch1; uint Launch2; uint Launch3; uint Launch4; uint Launch5; uint Launch6; uint Launch7; uint Launch8; uint Launch9; uint Launch10;
    uint Launch11; uint Launch12; uint Launch13; uint Launch14; uint Launch15; uint Launch16; uint Launch17; uint Launch18; uint Launch19; uint Launch20;
    uint Launch21; uint Launch22; uint Launch23; uint Launch24; uint Launch25; uint Launch26; uint Launch27; uint Launch28; uint Launch29; uint Launch30;

    uint[] listOfShare;
    uint active;
    uint endTime;

    function stake(uint amount, uint stakedNum, uint share) public {
        address sender = msg.sender;
        BEP20 token = BEP20(stakeTokenAddr);
            
        require(token.balanceOf(sender) >= amount, "Insufficient balance of user");
        require(amount >= 1 * 10**18, "Minimun stake is 1 token");
        
        token.transferFrom(sender, contractAddr, amount);
        /*user[sender].stakedAmount = amount;
        user[sender].stakedTime = block.timestamp;
        user[sender].staked = true;
        user[sender].stakedNum = stakedNum;
        user[sender].stakedShare = share;*/

       active = 1;

        endTime = block.timestamp + 0 days;

        user[sender].deposits.push(Deposit(amount, block.timestamp, stakedNum, active, endTime));

        //Запись в долю тира лаунчпада
        //listOfShare[stakedNum]=listOfShare[stakedNum]+share;

        emit Staked(sender, amount);
    }

    function userDetails(address addr) public view returns(uint[] memory amt, uint[] memory time, uint[] memory typeStaked, uint[] memory activeStake, uint[] memory endTimeStake, uint length) {
        length = user[addr].deposits.length;
        
        amt = new uint[](length);
        time = new uint[](length);
        typeStaked = new uint[](length);
        activeStake = new uint[](length);
        endTimeStake = new uint[](length);
        
        for(uint i = 0; i < length; i++){
            Stake storage stake_ = user[addr];
            Deposit storage dep = stake_.deposits[i];
            
            amt[i] = dep.amount;
            time[i] = dep.timeStake;
            typeStaked[i] = dep.typeStake;
            activeStake[i] = dep.active;
            endTimeStake[i] = dep.endTime;
            
        }
        return(amt, time, typeStaked, activeStake, endTimeStake, length);
    }
//sdfsd
    //Получение доли тиров лаунчпада
    function getTierList(uint num) public view returns(uint shareNum) {
        return listOfShare[num];
    }

    //Список застейкавших адресов
    function ListOfUserAddress() public view returns(address[] memory userAddrList) {
        userAddrList = userAddressArr;
        return userAddrList;
    }

    //Функция разлока
    function withdrow(address addr, uint timeInput) public returns(uint[] memory amt, uint[] memory time, uint[] memory typeStaked, uint[] memory activeStake, uint[] memory endTimeStake, uint length) {
        BEP20 token = BEP20(stakeTokenAddr);
        
        address addr = msg.sender;
        Stake storage stake_ = user[addr];

        length = user[addr].deposits.length;
        
        amt = new uint[](length);
        time = new uint[](length);
        typeStaked = new uint[](length);
        activeStake = new uint[](length);
        endTimeStake = new uint[](length);
     
        for(uint i = 0; i < length; i++){
            Stake storage stake_ = user[addr];
            Deposit storage dep = stake_.deposits[i];
            
            amt[i] = dep.amount;
            time[i] = dep.timeStake;
            typeStaked[i] = dep.typeStake;
            activeStake[i] = dep.active;
            endTimeStake[i] = dep.endTime;
            
            if(time[i]==timeInput) {
                require(activeStake[i] == 0, "Already withdrawn");
                require(block.timestamp >= endTimeStake[i], "End Time not reached");
                token.transfer(addr, amt[i]);
                activeStake[i]=0;
            }
        }

        return(amt, time, typeStaked, activeStake, endTimeStake, length);  

    }

    //Дата разлока монет
    function unlockTime(address addr) public view returns (uint unlockTime_) {
        unlockTime_ = user[addr].stakedTime + 30 days;
        return unlockTime_;
    }

    //Получение значений доли
    function getShareOfTier() public view returns(uint shareOfTier) {
        shareOfTier=1;
        return shareOfTier;
    }

    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }
    function invest() external payable {
    
    }

    function getLauhcn1() public view returns(uint) {
        return Launch1;
    }

    

    /// Fallback function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}