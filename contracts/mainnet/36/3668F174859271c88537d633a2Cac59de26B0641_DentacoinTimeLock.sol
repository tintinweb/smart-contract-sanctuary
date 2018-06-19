/*
Dentacoin Foundation TimeLock Contract 2018

6 088 888 888 888 DCN will be locked in total
Every year a certain amount will be released:
01/01/2018 = 121777777777   //2% Contract Address: 0x3668F174859271c88537d633a2Cac59de26B0641
01/01/2019 = 182666666666   //3% Contract Address: 0xf20fC45f6e6204C3C0a97da219D714937CA7321D
01/01/2020 = 243555555555   //4% Contract Address: 0x1b6F112B2C6fbe28Cf9394B64f493E0ffeb5c020
01/01/2021 = 304444444444   //5% Contract Address: 0x3d666A7932De1F34121F768fd1Ed27386E84A422
01/01/2022 = 365333333333   //6% Contract Address: 0x572f457882102FfeaaC4121338Ced3E94A006Cdc
01/01/2023 = 487111111111   //8% Contract Address: 0x2FD80316c6271CbeF643742A3CA8265cF6ab4480
01/01/2024 = 608888888888   //10% Contract Address: 0x5fd371718415DaB653D42cc65105AF88dB0205de
01/01/2025 = 547999999999   //9% Contract Address: 0xf1EAB24B40C0D040ccfD1d3BbB3419003074E3D9
01/01/2026 = 487111111111   //8% Contract Address: 0xEa63C813253E1d30b74A1f46E76a67D499B6d4C8
01/01/2027 = 487111111111   //8% Contract Address: 0x2a1bb55f021d40d98f937665b42e69f4be7cc8f9
01/01/2028 = 365333333333   //6% Contract Address: 0xA407A4f537e0Ee4936e3Fc32DB64914d4d5d3f43
01/01/2029 = 304444444444   //5% Contract Address: 0x3572DE393113A3b4faCDB12deE3e92733058EF67
01/01/2030 = 121777777777   //2% Contract Address: 0x22877c076B09A65dbB865b4a29e5436231634Fc4
01/01/2031 = 121777777777   //2% Contract Address: 0xE3345eb610C2F3B0d9884A4784B0e980eA420dA3
01/01/2032 = 121777777777   //2% Contract Address: 0xbBaf33931dbCFcE91337986f5B953e555DFA0526
01/01/2033 = 121777777777   //2% Contract Address: 0x864F9244aF3aBeB595c8d825861E3767FE3849DC
01/01/2034 = 121777777777   //2% Contract Address: 0xb8e6Eae57A926b393C3d040CF3F4f9f663c6C487
01/01/2035 = 121777777777   //2% Contract Address: 0x0e5a15e153Bd89C113A6e8fb3d14A99004C9CD94
01/01/2036 = 121777777777   //2% Contract Address: 0x0d4346f96B7512222448bAD36AC01709634f76B0
01/01/2037 = 121777777777   //2% Contract Address: 0x1c6A6cdEE958F3FeF8A9c9ccC9f49649aF9311C1
01/01/2038 = 121777777777   //2% Contract Address: 0xA5d2CC94C9251c92C29126C6869E111F8D0a1275
01/01/2039 = 121777777777   //2% Contract Address: 0x977a1A431c94d0725E06eAE00F5e33f0F8666274
01/01/2040 = 121777777777   //2% Contract Address: 0x918cddD8394bDb7C258bAc66E3DBa4f47078BE87
01/01/2041 = 121777777777   //2% Contract Address: 0xa3f9Fe2E8bf25E48E5098cBd48b16B88e7D4742A
01/01/2042 = 121777777777   //2% Contract Address: 0xC8C1a15d6Be8eC0c923a3D251AB85935223d2105
01/01/2042 = everything else     Contract Address: 0x24f4F418adc1007F90763a47493aDe189DeFD7Ed
*/


pragma solidity ^0.4.11;

//Dentacoin token import
contract exToken {
  function transfer(address, uint256) returns (bool) {  }
  function balanceOf(address) constant returns (uint256) {  }
}


// Timelock
contract DentacoinTimeLock {

  uint constant public year = 2018;
  address public owner;
  uint public lockTime = 192 days;
  uint public startTime;
  uint256 lockedAmount;
  exToken public tokenAddress;

  modifier onlyBy(address _account){
    require(msg.sender == _account);
    _;
  }

  function () payable {}

  function DentacoinTimeLock() {

    //owner = msg.sender;
    owner = 0xd560Be7E053f6bDB113C2814Faa339e29f4a385f;  // Dentacoin Foundation owner
    startTime = now;
    tokenAddress = exToken(0x08d32b0da63e2C3bcF8019c9c5d849d7a9d791e6);
  }

  function withdraw() onlyBy(owner) {
    lockedAmount = tokenAddress.balanceOf(this);
    if ((startTime + lockTime) < now) {
      tokenAddress.transfer(owner, lockedAmount);
    } else { throw; }
  }
}