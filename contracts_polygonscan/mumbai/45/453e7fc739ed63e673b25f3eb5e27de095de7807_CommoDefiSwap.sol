/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CommoDefiSwap {

  uint public cdUSDTtoCopperRate;
  address public cdCopperAddress=0x956f4E92563b9Fb660F16Ab183F84B4535088931;

  uint public cdUSDTtoNaturalGasRate;
  address public cdNaturalGasAddress=0x830Fe3cDE4804FFFB2640224e8DFcAcEd261602D;

  uint public cdUSDTtoGoldRate;
  address public cdGoldAddress=0x010C049b6AD8ff91fCfEE0ac2F6f997849E174A7;

  uint public cdUSDTtoBrentCrudeOilRate;
  address public cdBrentCrudeOilAddress=0x5f366A4c60158F0744a2F60CFC8B9256abA98f10;

  uint public cdUSDTtoSilverRate;
  address public cdSilverAddress=0xdB350336d41935b105a3914a7e934CA8285C5b34;

  uint public cdUSDTtoWTIOilRate;
  address public cdWTIOilAddress=0xfaa7A98514CC21F1812EF309d51A462A9962114b;

  uint public cdUSDTtoPlatinumRate;
  address public cdPlatinumAddress=0xcA66A2E36C1EA1011EfA06011556CA6C7ec68Af6;

  uint public cdUSDTtoPalladiumRate;
  address public cdPalladiumAddress=0xaaB9fe82Af8ff82d5444Af11900c552be38143e0;

  uint public cdUSDTtoWheatRate;
  address public cdWheatAddress=0x0924801F286412D05b32559633baDBE5881A76ec;
  
  uint public cdUSDTtoCottonRate;
  address public cdCottonAddress=0x0b2C125bFD3fa6f3394108C4587C3b75f9F833F1;

  uint public cdUSDTtoCornRate;
  address public cdCornAddress=0x9087595FB1aa9a76Dde421C68021B1C9056c9a28;

  uint public cdUSDTtoCoffeeRate;
  address public cdCoffeeAddress=0xCa5BE561612B6509bbDE960C1c9FF8a33c217a6f;


  address public owner = msg.sender;
  uint256 oneEther=1000000000000000000;

  address public priceUpdater=0xCDeF3CC7cDBdC8695674973Ad015D9f2B01dD4C4;
  address public USDTaddress=0x2e032F1b20E03fc371f99a154AC0b7e52409CF8B;
  address public BUSDaddress=0x2e032F1b20E03fc371f99a154AC0b7e52409CF8B;

  bool public swapStatus=true;

  receive() external payable {}

  function USDTtoToken(uint256 amount,address tokenAddress) public{
        require(swapStatus==true);
        require(
          tokenAddress==cdSilverAddress
        ||tokenAddress==cdBrentCrudeOilAddress
        ||tokenAddress==cdGoldAddress
        ||tokenAddress==cdNaturalGasAddress
        ||tokenAddress==cdCopperAddress
        ||tokenAddress==cdWTIOilAddress
        ||tokenAddress==cdPlatinumAddress
        ||tokenAddress==cdPalladiumAddress
        ||tokenAddress==cdWheatAddress
        ||tokenAddress==cdCottonAddress
        ||tokenAddress==cdCornAddress
        ||tokenAddress==cdCoffeeAddress
        
        );
        IERC20 tokenContract = IERC20(USDTaddress);
        tokenContract.transferFrom(msg.sender, address(this), amount);
        
        if(tokenAddress==cdSilverAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoSilverRate)/oneEther)-(cdUSDTtoSilverRate*2/1000);
        IERC20 cdSilverContract = IERC20(cdSilverAddress);
        cdSilverContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdBrentCrudeOilAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoBrentCrudeOilRate)/oneEther)-(cdUSDTtoBrentCrudeOilRate/1000);
        IERC20 cdBrentCrudeOilContract = IERC20(cdBrentCrudeOilAddress);
        cdBrentCrudeOilContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdGoldAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoGoldRate)/oneEther)-(cdUSDTtoGoldRate/1000);
        IERC20 cdGoldContract = IERC20(cdGoldAddress);
        cdGoldContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdNaturalGasAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoNaturalGasRate)/oneEther)-(cdUSDTtoNaturalGasRate*3/1000);
        IERC20 cdNaturalGasContract = IERC20(cdNaturalGasAddress);
        cdNaturalGasContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCopperAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoCopperRate)/oneEther)-(cdUSDTtoCopperRate*3/1000);
        IERC20 cdCopperContract = IERC20(cdCopperAddress);
        cdCopperContract.transfer(msg.sender, _amountTo);
        }

        else if(tokenAddress==cdWTIOilAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoWTIOilRate)/oneEther)-(cdUSDTtoWTIOilRate/1000);
        IERC20 cdWTIOilContract = IERC20(cdWTIOilAddress);
        cdWTIOilContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdPlatinumAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoPlatinumRate)/oneEther)-(cdUSDTtoPlatinumRate/1000);
        IERC20 cdPlatinumContract = IERC20(cdPlatinumAddress);
        cdPlatinumContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdPalladiumAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoPalladiumRate)/oneEther)-(cdUSDTtoPalladiumRate*25/10000);
        IERC20 cdPalladiumContract = IERC20(cdPalladiumAddress);
        cdPalladiumContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdWheatAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoWheatRate)/oneEther)-(cdUSDTtoWheatRate*2/1000);
        IERC20 cdWheatContract = IERC20(cdWheatAddress);
        cdWheatContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCottonAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoCottonRate)/oneEther)-(cdUSDTtoCottonRate*2/1000);
        IERC20 cdCottonContract = IERC20(cdCottonAddress);
        cdCottonContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCornAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoCornRate)/oneEther)-(cdUSDTtoCornRate*2/1000);
        IERC20 cdCornContract = IERC20(cdCornAddress);
        cdCornContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCoffeeAddress){
        uint256 _amountTo =(((amount*10**12)*cdUSDTtoCoffeeRate)/oneEther)-(cdUSDTtoCoffeeRate*3/1000);
        IERC20 cdCoffeeContract = IERC20(cdCoffeeAddress);
        cdCoffeeContract.transfer(msg.sender, _amountTo);
        }

  }


  function BUSDtoToken(uint256 amount,address tokenAddress) public{
     

  }





    function TokenToUSDT(uint256 amount,address tokenAddress) public{
        require(swapStatus==true);
        require(amount>=(oneEther/100));
        require(
          tokenAddress==cdSilverAddress
        ||tokenAddress==cdBrentCrudeOilAddress
        ||tokenAddress==cdGoldAddress
        ||tokenAddress==cdNaturalGasAddress
        ||tokenAddress==cdCopperAddress
        ||tokenAddress==cdWTIOilAddress
        ||tokenAddress==cdPlatinumAddress
        ||tokenAddress==cdPalladiumAddress
        ||tokenAddress==cdWheatAddress
        ||tokenAddress==cdCottonAddress
        ||tokenAddress==cdCornAddress
        ||tokenAddress==cdCoffeeAddress
        
        );
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transferFrom(msg.sender, address(this), amount);
        IERC20 USDTContract = IERC20(USDTaddress);

        if(tokenAddress==cdSilverAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoSilverRate)-(cdUSDTtoSilverRate*2/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
        else if(tokenAddress==cdBrentCrudeOilAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoBrentCrudeOilRate)-(cdUSDTtoBrentCrudeOilRate/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
        else if(tokenAddress==cdGoldAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoGoldRate)-(cdUSDTtoGoldRate/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
        else if(tokenAddress==cdNaturalGasAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoNaturalGasRate)-(cdUSDTtoNaturalGasRate*3/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
        else if(tokenAddress==cdCopperAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoCopperRate)-(cdUSDTtoCopperRate*3/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
 
        else if(tokenAddress==cdWTIOilAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoWTIOilRate)-(cdUSDTtoWTIOilRate/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
        else if(tokenAddress==cdPlatinumAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoPlatinumRate)-(cdUSDTtoPlatinumRate*25/10000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
        else if(tokenAddress==cdPalladiumAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoPalladiumRate)-(cdUSDTtoPalladiumRate*3/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
        else if(tokenAddress==cdWheatAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoWheatRate)-(cdUSDTtoWheatRate*2/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
        else if(tokenAddress==cdCottonAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoCottonRate)-(cdUSDTtoCottonRate*2/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
        else if(tokenAddress==cdCornAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoCornRate)-(cdUSDTtoCornRate*2/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }
        else if(tokenAddress==cdCoffeeAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoCoffeeRate)-(cdUSDTtoCoffeeRate*3/1000);
        USDTContract.transfer(msg.sender, _amountTo*10**12);
        }


  }



  function updateRate(uint256[] memory _rate) priceUpdaterOnly public {
    cdUSDTtoSilverRate=_rate[0];
    cdUSDTtoBrentCrudeOilRate=_rate[1];
    cdUSDTtoGoldRate=_rate[2];
    cdUSDTtoNaturalGasRate=_rate[3];
    cdUSDTtoCopperRate=_rate[4];
    cdUSDTtoWTIOilRate=_rate[5];
    cdUSDTtoPlatinumRate=_rate[6];
    cdUSDTtoPalladiumRate=_rate[7];
    cdUSDTtoWheatRate=_rate[8];
    cdUSDTtoCottonRate=_rate[9];
    cdUSDTtoCornRate=_rate[10];
    cdUSDTtoCoffeeRate=_rate[11];

  }
  

  
function pause(bool status) public restricted{
   swapStatus=status;
}





  function widthDrawToken(uint256 amount,address tokenAddress) public restricted{
    IERC20 tokenContract = IERC20(tokenAddress);
    tokenContract.transfer(msg.sender, amount);
  }

   function widthDrawBNB(uint256 amount) public restricted{
    payable(msg.sender).transfer(amount);
  }
   function changeOwner(address _newOwner) restricted public {
    owner=_newOwner;
  }

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

   modifier priceUpdaterOnly() {
    require(
      msg.sender == priceUpdater,
      "This function is restricted to the contract's price updater"
    );
    _;
  }

 
}