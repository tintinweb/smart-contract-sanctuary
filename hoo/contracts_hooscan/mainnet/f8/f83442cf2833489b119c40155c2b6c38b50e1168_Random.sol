/**
 *Submitted for verification at hooscan.com on 2021-07-17
*/

// SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Random is Ownable {
    
    mapping(uint256 => address) addressList;
    
    uint256[] keyList;
    
    uint256 subNum = 36421;
    
    event Winaddress(address ,address  ,address  ,address  ,address  ,
    address  ,address  ,address  ,address  ,address  );
    
    constructor(){
        keyList = [5226,8010,10776,13136,15468,17459,19243,21009,22632,23834,25015,26115,27001,27769,28519,29169,29769,30211,30644,31078,31511,31944,32340,
        32710,32912,33113,33313,33513,33713,33913,34080,34237,34387,34538,34688,34838,34988,35138,35288,35438,35588,35738,35888,36038,36188,36319,36420];
       

        addressList[5226] = 0xD36E1f82aB796435F65e062b040f30be512Cd04A;
        addressList[8010] = 0x9908DFc48DEf4D7ba91Aec80AB3713b272E42A00;
        addressList[10776] = 0xd27f35E0df6e3F687a3f9e1638df83dBFbBc0Df8;
        addressList[13136] = 0x16D7A732D09641f17B9D41FAcac0b79C03f46280;
        addressList[15468] = 0xfD85a335640a631Bcbf4e13DAeEa7607bd809CB8;
        addressList[17459] = 0xd23cFe97706C2880105B077F002A677C9821D52B;
        addressList[19243] = 0xa41928022bc06dB550B51EDDf39D87DFB8fadD62;
        addressList[21009] = 0xfC5D4F6fD8272eB63bbd3c99d434f5362Fb08f5F;
        addressList[22632] = 0x40AEADD497C7cf9F313e091FcAc85d7f368B30C6;
        addressList[23834] = 0x123e2E92663dDeb79521b20fbb39E5d861b32947;
        addressList[25015] = 0x74adaE898E7063f5864e18668557142026EF10B7;
        addressList[26115] = 0x19520eF2016351466EE84aa5eBE152Ebd508009B;
        addressList[27001] = 0x3E4e7f4027BbD9D134ffF783c8cb9440139D321c;
        addressList[27769] = 0x31Ea57E3ab911353a939F928E7E7FCA384eee981;
        addressList[28519] = 0x167dE9e8d00d65cEc711B4c53E86cf3E238d46F4;
        addressList[29169] = 0x7C67476ab14F3218E0768b0a3D2076FdE46D7F2f;
        addressList[29769] = 0x882439B7c708C8543fE35D983429A3E10dB92bf4;
        addressList[30211] = 0xC0D4ca72C4567A8A805ed7691176AcD976441a46;
        addressList[30644] = 0xC61e6005DA3Da723372FF65170c317e1Ca0F7D3D;
        addressList[31078] = 0x5bF652D87999c0F68039d0de4CB6421d35D1Cb11;
        addressList[31511] = 0xFC9649ddc331715364bfFACb27eC340B6f03b45E;
        addressList[31944] = 0xF0f5c9E20C4278378dE2d66585Ca9fA512ba1387;
        addressList[32340] = 0xCFDe3602Afce9E2CA56363F31DA681173720761b;
        addressList[32710] = 0x22666CAa5d150ee909fC90FDAda59d91B06c90E8;
        addressList[32912] = 0xA9924BfD70916f2Cf6cbd7F18db3E92F1397A957;
        addressList[33113] = 0xd57f81f426bF6C70683B07294c4bb19a03a686Fa;
        addressList[33313] = 0x5d928E63f725450DD9ECB1aBaa1194AE3b67bf08;
        addressList[33513] = 0xf4B07eD1907bec8AF8Db5D66c569585293Eb3F26;
        addressList[33713] = 0x62Dd043Dc274C73Cc8B327ecabD5b29b75E608c0;
        addressList[33913] = 0x74AB2169dC230E0445de2308B2C14d80D2679B2C;
        addressList[34080] = 0x11503fBdbA3192aB5a27258CE98773A68fa484E2;
        addressList[34237] = 0x6Fae9fA9837091d52789bDcda5f93792402AC337;
        addressList[34387] = 0x27525ec1e1b6Cb5E00d2cF5d023b86068615648B;
        addressList[34538] = 0x689A9c1F84bb856Ee5AdcA501F4115216dB33DdA;
        addressList[34688] = 0x9b1C08e6add220094087A3b03aA7fab44e42c9e4;
        addressList[34838] = 0x956595370cf28cDbaFE93707D36133d016cD3955;
        addressList[34988] = 0x75Ec9ABAD75D50a79A189d34cF78AE8E0674E34B;
        addressList[35138] = 0xA5Bf246eCfADdC7Dcd3D18831f45E1C569d23481;
        addressList[35288] = 0xbB7348e56a6DFe8a8906B51dF660bB283d03B8Bd;
        addressList[35438] = 0xF90eB893287e29e8c88BF331ccA7A0c9306C22C1;
        addressList[35588] = 0xE0f7A8428bF26841f7c048c28c15ab39bD833B17;
        addressList[35738] = 0x284c5Eeba11Fd1aAFc011e7D78e90e7BA703d285;
        addressList[35888] = 0xE306f6449bFcA5Fb0C57A824DE0eB883228EdB23;
        addressList[36038] = 0xc48BC17A31A4B23Df86a9c1E40A11729fd2db296;
        addressList[36188] = 0xa26a13c4b6479d5013e99873b1258499487dC036;
        addressList[36319] = 0x8f6364CA2F9a5BA06B0e3d94ba646578f2d03541;
        addressList[36420] = 0xA593b9092Cb9E270EA2de52a0dd959A58049bc8F;
    }
 
    mapping(address => bool)  addresses;

    function getLucky(uint256 luckyNum) public onlyOwner{
        
        uint srcNum = block.timestamp;
        address[] memory winers = new  address[](10);

        for(uint i = 0;i<10;i++){
            uint256 nonce = 1;
            uint256 key;
            
            while(true){
                uint256 calcuNum = (srcNum*luckyNum*nonce)%subNum;
                
                for(uint j=0; j<keyList.length;j++){
                    if(calcuNum < keyList[j]){
                        key = keyList[j];
                        break;
                    }
                }
                
                address winer  = addressList[key];
                if(!addresses[winer]){
                    addresses[winer] = true;
                    winers[i]=winer;
                    break;
                }
                
                nonce +=1;
                
            }
        }
        emit Winaddress(winers[0],winers[1],winers[2],winers[3],winers[4],winers[5],winers[6],winers[7],winers[8],winers[9]);
    }
 

}