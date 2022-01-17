/**
 *Submitted for verification at polygonscan.com on 2022-01-17
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
  address public cdCopperAddress=0x5C22044BF9DFa487d7eA65366D5185bDa377d0cb;

  uint public cdUSDTtoNaturalGasRate;
  address public cdNaturalGasAddress=0x4Fd1fEF010d55C0a9456994B0B6eC4Dd3aAe9aD8;

  uint public cdUSDTtoGoldRate;
  address public cdGoldAddress=0x0b20940C5820b67DFeFDbFe7DbE26e63cb1BD401;

  uint public cdUSDTtoBrentCrudeOilRate;
  address public cdBrentCrudeOilAddress=0xB07d4C5C517E782f8c52e95F0E728EFD18B12781;

  uint public cdUSDTtoSilverRate;
  address public cdSilverAddress=0x6fC9249d195Ea8aD5072E0Bbbe62ec37fB51b078;

  uint public cdUSDTtoWTIOilRate;
  address public cdWTIOilAddress=0xaDD682eDbbe2ffF525Cc9FE477c17A8aFa23201F;

  uint public cdUSDTtoPlatinumRate;
  address public cdPlatinumAddress=0x3939b116A304ddEbe7B605ca9F70241f516779F0;

  uint public cdUSDTtoPalladiumRate;
  address public cdPalladiumAddress=0x307C429a348E909024c383d54b95Dae1774DC168;

  uint public cdUSDTtoWheatRate;
  address public cdWheatAddress=0x7F1d1F9Ca4952d9f5815a4a39BeB95717912c669;
  
  uint public cdUSDTtoCottonRate;
  address public cdCottonAddress=0x3cC682466a1B58e44f26886fC7313b8349C7c7AE;

  uint public cdUSDTtoCornRate;
  address public cdCornAddress=0x2D54Ad78dea55B96563225e47dC74D1A87ca0759;

  uint public cdUSDTtoCoffeeRate;
  address public cdCoffeeAddress=0xB3083aB77cA0c5093d0359CAC72a993Cdb0C6a8D;


  address public owner = msg.sender;
  uint256 oneEther=1000000000000000000;

  address public priceUpdater=0xCDeF3CC7cDBdC8695674973Ad015D9f2B01dD4C4;
  address public USDTaddress=0x55d398326f99059fF775485246999027B3197955;
  address public BUSDaddress=0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

  bool public swapStatus=true;

  receive() external payable {}

  function USDTtoToken(uint256 amount,address tokenAddress) public{
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
        IERC20 tokenContract = IERC20(USDTaddress);
        tokenContract.transferFrom(msg.sender, address(this), amount);
        
        if(tokenAddress==cdSilverAddress){
        uint256 _amountTo =((amount*cdUSDTtoSilverRate)/oneEther)-(cdUSDTtoSilverRate*2/1000);
        IERC20 cdSilverContract = IERC20(cdSilverAddress);
        cdSilverContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdBrentCrudeOilAddress){
        uint256 _amountTo =((amount*cdUSDTtoBrentCrudeOilRate)/oneEther)-(cdUSDTtoBrentCrudeOilRate/1000);
        IERC20 cdBrentCrudeOilContract = IERC20(cdBrentCrudeOilAddress);
        cdBrentCrudeOilContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdGoldAddress){
        uint256 _amountTo =((amount*cdUSDTtoGoldRate)/oneEther)-(cdUSDTtoGoldRate/1000);
        IERC20 cdGoldContract = IERC20(cdGoldAddress);
        cdGoldContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdNaturalGasAddress){
        uint256 _amountTo =((amount*cdUSDTtoNaturalGasRate)/oneEther)-(cdUSDTtoNaturalGasRate*3/1000);
        IERC20 cdNaturalGasContract = IERC20(cdNaturalGasAddress);
        cdNaturalGasContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCopperAddress){
        uint256 _amountTo =((amount*cdUSDTtoCopperRate)/oneEther)-(cdUSDTtoCopperRate*3/1000);
        IERC20 cdCopperContract = IERC20(cdCopperAddress);
        cdCopperContract.transfer(msg.sender, _amountTo);
        }

        else if(tokenAddress==cdWTIOilAddress){
        uint256 _amountTo =((amount*cdUSDTtoWTIOilRate)/oneEther)-(cdUSDTtoWTIOilRate/1000);
        IERC20 cdWTIOilContract = IERC20(cdWTIOilAddress);
        cdWTIOilContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdPlatinumAddress){
        uint256 _amountTo =((amount*cdUSDTtoPlatinumRate)/oneEther)-(cdUSDTtoPlatinumRate/1000);
        IERC20 cdPlatinumContract = IERC20(cdPlatinumAddress);
        cdPlatinumContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdPalladiumAddress){
        uint256 _amountTo =((amount*cdUSDTtoPalladiumRate)/oneEther)-(cdUSDTtoPalladiumRate*25/10000);
        IERC20 cdPalladiumContract = IERC20(cdPalladiumAddress);
        cdPalladiumContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdWheatAddress){
        uint256 _amountTo =((amount*cdUSDTtoWheatRate)/oneEther)-(cdUSDTtoWheatRate*2/1000);
        IERC20 cdWheatContract = IERC20(cdWheatAddress);
        cdWheatContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCottonAddress){
        uint256 _amountTo =((amount*cdUSDTtoCottonRate)/oneEther)-(cdUSDTtoCottonRate*2/1000);
        IERC20 cdCottonContract = IERC20(cdCottonAddress);
        cdCottonContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCornAddress){
        uint256 _amountTo =((amount*cdUSDTtoCornRate)/oneEther)-(cdUSDTtoCornRate*2/1000);
        IERC20 cdCornContract = IERC20(cdCornAddress);
        cdCornContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCoffeeAddress){
        uint256 _amountTo =((amount*cdUSDTtoCoffeeRate)/oneEther)-(cdUSDTtoCoffeeRate*3/1000);
        IERC20 cdCoffeeContract = IERC20(cdCoffeeAddress);
        cdCoffeeContract.transfer(msg.sender, _amountTo);
        }

  }


  function BUSDtoToken(uint256 amount,address tokenAddress) public{
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
        IERC20 tokenContract = IERC20(BUSDaddress);
        tokenContract.transferFrom(msg.sender, address(this), amount);
        
        if(tokenAddress==cdSilverAddress){
        uint256 _amountTo =((amount*cdUSDTtoSilverRate)/oneEther)-(cdUSDTtoSilverRate*2/1000);
        IERC20 cdSilverContract = IERC20(cdSilverAddress);
        cdSilverContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdBrentCrudeOilAddress){
        uint256 _amountTo =((amount*cdUSDTtoBrentCrudeOilRate)/oneEther)-(cdUSDTtoBrentCrudeOilRate/1000);
        IERC20 cdBrentCrudeOilContract = IERC20(cdBrentCrudeOilAddress);
        cdBrentCrudeOilContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdGoldAddress){
        uint256 _amountTo =((amount*cdUSDTtoGoldRate)/oneEther)-(cdUSDTtoGoldRate/1000);
        IERC20 cdGoldContract = IERC20(cdGoldAddress);
        cdGoldContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdNaturalGasAddress){
        uint256 _amountTo =((amount*cdUSDTtoNaturalGasRate)/oneEther)-(cdUSDTtoNaturalGasRate*3/1000);
        IERC20 cdNaturalGasContract = IERC20(cdNaturalGasAddress);
        cdNaturalGasContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCopperAddress){
        uint256 _amountTo =((amount*cdUSDTtoCopperRate)/oneEther)-(cdUSDTtoCopperRate*3/1000);
        IERC20 cdCopperContract = IERC20(cdCopperAddress);
        cdCopperContract.transfer(msg.sender, _amountTo);
        }

        else if(tokenAddress==cdWTIOilAddress){
        uint256 _amountTo =((amount*cdUSDTtoWTIOilRate)/oneEther)-(cdUSDTtoWTIOilRate/1000);
        IERC20 cdWTIOilContract = IERC20(cdWTIOilAddress);
        cdWTIOilContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdPlatinumAddress){
        uint256 _amountTo =((amount*cdUSDTtoPlatinumRate)/oneEther)-(cdUSDTtoPlatinumRate*25/10000);
        IERC20 cdPlatinumContract = IERC20(cdPlatinumAddress);
        cdPlatinumContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdPalladiumAddress){
        uint256 _amountTo =((amount*cdUSDTtoPalladiumRate)/oneEther)-(cdUSDTtoPalladiumRate*3/1000);
        IERC20 cdPalladiumContract = IERC20(cdPalladiumAddress);
        cdPalladiumContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdWheatAddress){
        uint256 _amountTo =((amount*cdUSDTtoWheatRate)/oneEther)-(cdUSDTtoWheatRate*2/1000);
        IERC20 cdWheatContract = IERC20(cdWheatAddress);
        cdWheatContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCottonAddress){
        uint256 _amountTo =((amount*cdUSDTtoCottonRate)/oneEther)-(cdUSDTtoCottonRate*2/1000);
        IERC20 cdCottonContract = IERC20(cdCottonAddress);
        cdCottonContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCornAddress){
        uint256 _amountTo =((amount*cdUSDTtoCornRate)/oneEther)-(cdUSDTtoCornRate*2/1000);
        IERC20 cdCornContract = IERC20(cdCornAddress);
        cdCornContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCoffeeAddress){
        uint256 _amountTo =((amount*cdUSDTtoCoffeeRate)/oneEther)-(cdUSDTtoCoffeeRate*3/1000);
        IERC20 cdCoffeeContract = IERC20(cdCoffeeAddress);
        cdCoffeeContract.transfer(msg.sender, _amountTo);
        }

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
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdBrentCrudeOilAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoBrentCrudeOilRate)-(cdUSDTtoBrentCrudeOilRate/1000);
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdGoldAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoGoldRate)-(cdUSDTtoGoldRate/1000);
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdNaturalGasAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoNaturalGasRate)-(cdUSDTtoNaturalGasRate*3/1000);
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCopperAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoCopperRate)-(cdUSDTtoCopperRate*3/1000);
        USDTContract.transfer(msg.sender, _amountTo);
        }
 
        else if(tokenAddress==cdWTIOilAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoWTIOilRate)-(cdUSDTtoWTIOilRate/1000);
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdPlatinumAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoPlatinumRate)-(cdUSDTtoPlatinumRate*25/10000);
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdPalladiumAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoPalladiumRate)-(cdUSDTtoPalladiumRate*3/1000);
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdWheatAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoWheatRate)-(cdUSDTtoWheatRate*2/1000);
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCottonAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoCottonRate)-(cdUSDTtoCottonRate*2/1000);
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCornAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoCornRate)-(cdUSDTtoCornRate*2/1000);
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCoffeeAddress){
        uint256 _amountTo =((oneEther*amount)/cdUSDTtoCoffeeRate)-(cdUSDTtoCoffeeRate*3/1000);
        USDTContract.transfer(msg.sender, _amountTo);
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