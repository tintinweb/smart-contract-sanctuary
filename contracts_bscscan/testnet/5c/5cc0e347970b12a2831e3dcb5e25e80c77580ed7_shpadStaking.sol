/**
 *Submitted for verification at BscScan.com on 2021-12-10
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

struct Stake {
    bool staked;
    uint stakedAmount;
    uint stakedTime;
    uint stakedNum;
    uint stakedShare;
    uint stakedTypeCoin;
}
/*
stakedNum - number of staking type,
share - share of ...,
stakedTypeCoin: 0 - shpad, 1 - usdt
*/




contract shpadStaking {
    mapping(address => Stake) public user;
    address public contractAddr = address(this);
    address public stakeTokenAddr = 0xDdDFAB53EEFc866ec4e62580543E2514A2e1C1d3;
    address[] public userAddressArr;

    uint Launch1; uint Launch2; uint Launch3; uint Launch4; uint Launch5; uint Launch6; uint Launch7; uint Launch8; uint Launch9; uint Launch10;
    uint Launch11; uint Launch12; uint Launch13; uint Launch14; uint Launch15; uint Launch16; uint Launch17; uint Launch18; uint Launch19; uint Launch20;
    uint Launch21; uint Launch22; uint Launch23; uint Launch24; uint Launch25; uint Launch26; uint Launch27; uint Launch28; uint Launch29; uint Launch30;



    function stake(uint amount, uint stakedNum, uint share) external returns(uint) {
        address sender = msg.sender;
        BEP20 token = BEP20(stakeTokenAddr);
            
        require(token.balanceOf(sender) >= amount, "Insufficient balance of user");
        require(amount >= 1 * 10**18, "Minimun stake is 1 token");
        
        token.transferFrom(sender, contractAddr, amount);
        user[sender].stakedAmount = amount;
        user[sender].stakedTime = block.timestamp;
        user[sender].staked = true;
        user[sender].stakedNum = stakedNum;
        user[sender].stakedShare = share;

        //Запись в долю тира лаунчпада
        if(stakedNum==1) {
            Launch1=Launch1+share;
        }

        return token.balanceOf(sender);
    }

    //Список застейкавших адресов
    function ListOfUserAddress() public view returns(address[] memory userAddrList) {
        userAddrList = userAddressArr;
        return userAddrList;
    }

    //Дата разлока монет
    function unlockTime(address addr) public view returns (uint unlockTime_) {
        unlockTime_ = user[addr].stakedTime + 30 days;
        return unlockTime_;
    }

    //Вывод со стейкинга
    function unstake() public returns(bool) {
        return true;
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
}