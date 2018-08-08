pragma solidity ^0.4.18;
// -------------------------------------------------
// ethPoker.io EPX token AirDrop round 1
// -------------------------------------------------
// ERC Token Standard #20 interface:
// https://github.com/ethereum/EIPs/issues/20
// EPX contract sources:
// https://github.com/EthPokerIO/ethpokerIO
// ------------------------------------------------

contract owned {
  address public owner;

  function owned() internal {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}

contract StandardToken is owned {
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract EPXAirDrop is owned {
  // owner/admin & token reward
  address        public admin                     = owner;    // admin address
  StandardToken  public tokenReward;                          // address of the token used as reward
  string         public currentStatus             = "";       // current crowdsale status
  bool           public alive                     = true;

  // AirDrop uses ERC20 transfer event for logging
  event Transfer(address indexed from, address indexed to, uint256 value);

  // default function, map admin
  function EPXAirDrop() public onlyOwner {
    admin = msg.sender;
    tokenReward                             = StandardToken(0x35BAA72038F127f9f8C8f9B491049f64f377914d);
    alive                                   = true;
    currentStatus                           = "Contract is deployed";
  }

  function PerformAirDrop() public onlyOwner {
    // 0. conditions (not halted);
    require(alive);

    // 1. interaction - perform AirDrop to round 1 recipients and winners

    // a. - Winners
    tokenReward.transfer(0xa904Baa2c81342dD45ADbCad17fAC09DC92bD4DC,7000000);
    tokenReward.transfer(0x877B6209b0D1f25A0c9dC79c0F61917745C773Eb,7000000);
    tokenReward.transfer(0xBBF268DB73a76D07aFF331F815E189DC1F9bc5B6,7000000);
    tokenReward.transfer(0x791BAa2A1F4c5c08D4E38c31eed9092Db80f5EcD,7000000);
    tokenReward.transfer(0x28288818a01077b7ac1B3B4a2f23304D36a8CD46,7000000);
    tokenReward.transfer(0xa54c3e55B25eAD5A040078dE561AF000f20512CF,7000000);
    tokenReward.transfer(0xFe48EE31De261E3Bf680d3099C33391E043dEB20,7000000);
    tokenReward.transfer(0xA375aa5AE466Fa40f4B4022C155660159690885D,7000000);
    tokenReward.transfer(0xe4Be2a8E9abACf3d5e05276930e27B334B8c3fAD,7000000);
    tokenReward.transfer(0x503ac4CB768ef45e2CA87772a0a2E289D8Cb02d7,9500000);
    tokenReward.transfer(0xD563bFD598BA5dE849A2EcDE017393f52529F3b8,9500000);
    tokenReward.transfer(0x59cbB4bfbA70A6fCCd73F59BA3a305291677926B,9500000);
    tokenReward.transfer(0x7389Ca09D9280E4243A30157A75B928D9472D452,9500000);
    tokenReward.transfer(0x375978E1c87571A26B64b276dE01E65C9893B832,15500000);

    // b. - Mainblock
    tokenReward.transfer(0x3931D0c8b7781F193aC9dDAaD9BEB12F3dBEf7F1,4500000);
    tokenReward.transfer(0x2a637b30Cf84F3C8ddBe5817160FB6130e2E723D,4500000);
    tokenReward.transfer(0xF88150aE0Ed2C6959494335F7Cd2285396a2f2d6,4500000);
    tokenReward.transfer(0xCb560Ad8DEbABA32f4901dd1a46f668384F6E030,4500000);
    tokenReward.transfer(0xc274B9E94ada95111551855D5AF06Ff8EDcE3fA9,4500000);
    tokenReward.transfer(0xd8f60e1d57B79CAA8585B2CC839dcB91deb0FD30,4500000);
    tokenReward.transfer(0x1F97Bce52135BF3d463627d68E8a174082dF55bd,4500000);
    tokenReward.transfer(0x681845c8f1D319948E80aD659bA7a34d62b80Df1,4500000);
    tokenReward.transfer(0x710A7286a6449B5b07299b08Ddf51Ee35DCb4F83,4500000);
    tokenReward.transfer(0x597b84EcE6c34dA9EA58C268F6C43742F523D921,4500000);
    tokenReward.transfer(0x4145A5fD4943868f16697585F45b02Deb740F2cc,4500000);
    tokenReward.transfer(0xA01eACc480734003565DFb4340C08631c6854d31,4500000);
    tokenReward.transfer(0x6547972F994f42479459733c302a30E869DCbA86,4500000);
    tokenReward.transfer(0xc301FD184cB1F9De4d6BE75dbB98f7dc097E63c4,4500000);
    tokenReward.transfer(0xb621AF7184154dDD305cE03516D45eb6a7961Be8,4500000);
    tokenReward.transfer(0xAA18c35549a05B5cdc594FCA014fbBe526D3835D,4500000);
    tokenReward.transfer(0x92f38D66cA43e13271C0311a93531a8D0f4A2306,4500000);
    tokenReward.transfer(0x8D1F288b97F6DC3a7EFA3E3D881152e97973bC85,4500000);
    tokenReward.transfer(0x7b624712c4C831a73e32e6285453A3937158c503,4500000);
    tokenReward.transfer(0x82Ec48363200c7b8DbD4F4251bc5be9a6feb6E98,4500000);
    tokenReward.transfer(0x458c70c0f0b34488cf481568cb786e687AD69e42,4500000);
    tokenReward.transfer(0xA6bA8cc7064Ff6371d9e6de1d107ba908aba9b7D,4500000);
    tokenReward.transfer(0xa807714CC5A22De6e92C6b923C3dF0f71E5B6A9A,4500000);
    tokenReward.transfer(0xdEe32A01B37DB53526392733901c42275359fbfA,4500000);
    tokenReward.transfer(0xd62251f345699A5C6322bC274037727C086201d8,4500000);
    tokenReward.transfer(0x9aAcdbD89E45595Eab5848e713252E950F7f8E07,4500000);
    tokenReward.transfer(0xD99ECF24770f856EfF4252445540f51Bda1cefdd,4500000);
    tokenReward.transfer(0x75A47aFA69e67c5b4F8908a2Bb4F92FB03D68058,4500000);
    tokenReward.transfer(0x30073FdC22043Ef428FF4f1e6e1Fd13a0A931998,4500000);
    tokenReward.transfer(0x662E860FF8b4850b4266C1ed081BA798af019f4A,4500000);
    tokenReward.transfer(0x1dEd06e76D839361d1253e5403633d9bBb7822AF,4500000);
    tokenReward.transfer(0xDd069B69E3c9EF9315cD6b031f25dB4d24224B0C,4500000);
    tokenReward.transfer(0x930B94D27FaEB62Ae55866076a95686339449a9e,4500000);
    tokenReward.transfer(0x8837FB0fce8ce3fd4C5f3562b708a682fdb4FB3e,4500000);
    tokenReward.transfer(0x681a19a96B8BE6dAFBfC89042CAd159E703A90e9,4500000);
    tokenReward.transfer(0x332d3f7A75BE742808B315B2F6A1d1ec8A1Cfb71,4500000);
    tokenReward.transfer(0xEA6ec1Ef67503e45A8716a4A72aE037b4a7453BB,4500000);
    tokenReward.transfer(0x1Ca7e0cE6885586056436f7132bfbe229F5fF6d0,4500000);
    tokenReward.transfer(0xb1fDC2257938d52499B100d5f431eB054022B0b3,4500000);
    tokenReward.transfer(0x0b5dAE293292c912aBD2E578ac4A8deF543bb4cd,4500000);
    tokenReward.transfer(0x30De8942CBA17Ce567933ace2824e422785390CC,4500000);
    tokenReward.transfer(0xCbC90c8b229eb204c7215fEd2eeab7a0641F2851,4500000);
  }
}