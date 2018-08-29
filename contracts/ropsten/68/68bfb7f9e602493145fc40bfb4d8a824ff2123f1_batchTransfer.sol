pragma solidity ^0.4.21;

contract batchTransfer {

address[] public myAddresses = [

0xcD2CAaae37354B7549aC7C526eDC432681821bbb,

0x8948e4b00deb0a5adb909f4dc5789d20d0851d71,

0xce82cf84558add0eff5ecfb3de63ff75df59ace0,

0xa732e7665ff54ba63ae40e67fac9f23ecd0b1223,

0x445b660236c39f5bc98bc49dddc7cf1f246a40ab,

0x60e31b8b79bd92302fe452242ea6f7672a77a80f

];



function () public payable {

require(myAddresses.length>0);

uint256 distr = msg.value/myAddresses.length;

for(uint256 i=0;i<myAddresses.length;i++)

{

myAddresses[i].transfer(distr);

    }

  }

}