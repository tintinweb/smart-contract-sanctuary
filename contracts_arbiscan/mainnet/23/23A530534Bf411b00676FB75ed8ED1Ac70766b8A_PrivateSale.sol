/**
 *Submitted for verification at arbiscan.io on 2021-11-22
*/

/*SPDX-License-Identifier: UNLICENSED*/
pragma solidity =0.7.6;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}
contract PrivateSale{
    address payable owner;
    address factory;
    address public token;
    address weth;
    uint public immutable price;
    bool public locked;
    uint public timelock;
    mapping(address=>bool) whitlisted;
    mapping(address=>uint) paid;
    mapping(address=>uint) bought;
    mapping(address=>uint) remain;
    uint public notSold;
    bool public open;
    address[] backupAddr;
    uint[] backuppay;
    
    function buyPvt() external payable {
        require(whitlisted[msg.sender] && open,"not whitlisted or closed"); 
        paid[msg.sender]+=msg.value;
        bought[msg.sender]+=msg.value*price;
        remain[msg.sender]+=msg.value*price;
        notSold-=msg.value*price;
    }
    
    function withdraw(uint amount) external {
        require(amount<=canWithdraw(msg.sender),"can't withdraw this amount");
        remain[msg.sender] -= amount;
        IERC20(token).transfer(msg.sender,amount);
    }
    
    function canWithdraw(address sender) internal view returns (uint){
        if(locked && block.timestamp<=timelock+24 weeks){
            if(bought[sender]*75/100<=remain[sender]){
                return (remain[sender]-bought[sender]*75/100)+((bought[sender]*75/100)*(100*(timelock+block.timestamp)/(timelock+24 weeks))/100);
            } else {
                return ((bought[sender]*75/100)*(100*(timelock+block.timestamp)/(timelock+24 weeks))/100)-bought[sender]*75/100+remain[sender];
            }
        } else if (locked && block.timestamp>=timelock+24 weeks){
            return remain[sender];
        } else {
            return 0;
        }
    }

    function whitelist (address[] calldata user,bool access) external {
        require(msg.sender==owner);
        for (uint i; i < user.length; i++) {
            whitlisted[user[i]]=access;
        }
    }   
    function close(bool _open) external{
        require(msg.sender==owner);
        open=_open;
    }
    function isWhitelisted() public view returns (bool){
        return whitlisted[msg.sender];
    }
    
    function getInfo(address who) public view returns (uint,uint,uint){
        return (bought[who], remain[who],canWithdraw(who));
    }

    function checkLiq() external{
        address pair = IUniswapV2Factory(factory).getPair(token,weth);
        require(pair!=address(0) && IERC20(token).balanceOf(pair)!=0,"liquidity not locked yet");
        locked=true;
        timelock=block.timestamp;
    }

    function withdrawETH(uint amount) external{
        require(msg.sender==owner && amount<=address(this).balance);
        owner.transfer(amount);
    }
    
    function withdrawNotSold(uint amount) external{
        require(msg.sender==owner && amount<=notSold);
        notSold-=amount;
        IERC20(token).transfer(owner,notSold);
    }
    
    constructor(){
        owner = msg.sender;
        price = 2000000;
        factory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
        token = 0x5e4e93C73EB0eE2cBEA828ae947b572415237BFB;
        weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        notSold=200000000000000000000000000;
        backupAddr = [0x9A52b6fbCEE874254EB1cCf5B6BB2B7279C62594,0xF08a2FFB0799841f9A6De0eC581EDFf1feC943e0,0xD97c0E3CdF140bA9C269E74Dd42A69Fa8a7F86aA,0x69EEf4C65ea9f66a518D2462905F62721723b8BD,0x42585c791ea09d24ed5628F9051B759d45E780CB,
        0x4f1Af64E5c6A2ae23b990ec9E78640423920c47A, 0xb63ec2430AF9609e6266B400e43E501DAfB6c7C1,0x84bfD0Ef713e027cc2C5D7773C29AD08A59596c7,0x360Fea9F41DE05f9A8772bb893975af558457646];
        backuppay = [670000000000000000,1400000000000000000,10000000000000000,50000000000000000,80000000000000000,100000000000000000,510000000000000000,1000000000000000000,12000000000000000000];
        /*
        ===========tx hash for verifications===========
        0x64acb1cb37bc5027c5d0d997313e024d59d02d04d6d4fc9b20aee6be88052c6d
        0x1d77bebf16261e915a9ecd94529fa2412c14a9b409026810a20b3829a0b2c557
        0x5c31e3de8d83147e4dbf53a09c73c29fde4f612fd8c1f252ca09175fbf5c174a
        0x39e91306bd5588fe2a566dea947f123a39e33594f79cd2bec427183f7aba640a
        0xbbf1a9d59816994d666a6d6af7e10c35080643b37d91ddabc4242b3ca1de1a40
        0x05837ddcd5b6331c9196485c5162d268c1da246fc2168119060d1153432c7a80
        0xa2485a3fb9aab19ea5607821a52a2c754363de3be7f6547579b3062dea205762
        0xf22cffa9ecbab7a4f2634e8d568f4d206be1f46536b9eac9fef6994d213f9ea2
        0x22459857b98ec215b1dd3b57c260a12cd3accbf93c111b6592c7e81e7e641157
        */
        for(uint i;i<backuppay.length;i++){
            paid[backupAddr[i]]=backuppay[i];
            bought[backupAddr[i]]=backuppay[i]*2000000;
            remain[backupAddr[i]]=backuppay[i]*2000000;
            notSold-=backuppay[i]*2000000;
        }
        open=true;
    }
    
    receive() external payable {
        
    }
}