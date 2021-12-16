// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CommoDefiSwap {
  uint public cdBNBtoCopperRate=500000000000000000;
  uint public cdUSDTtoCopperRate=100000000000000000;
  address public cdCopperAddress=0x5C22044BF9DFa487d7eA65366D5185bDa377d0cb;

  uint public cdBNBtoNaturalGasRate=600000000000000000;
  uint public cdUSDTtoNaturalGasRate=20000000000000000000;
  address public cdNaturalGasAddress=0x4Fd1fEF010d55C0a9456994B0B6eC4Dd3aAe9aD8;

  uint public cdBNBtoGoldRate=700000000000000000;
  uint public cdUSDTtoGoldRate=300000000000000000;
  address public cdGoldAddress=0x0b20940C5820b67DFeFDbFe7DbE26e63cb1BD401;

  uint public cdBNBtoBrentCrudeOilRate=800000000000000000;
  uint public cdUSDTtoBrentCrudeOilRate=400000000000000000;
  address public cdBrentCrudeOilAddress=0xB07d4C5C517E782f8c52e95F0E728EFD18B12781;

  uint public cdBNBtoSilverRate=900000000000000000;
  uint public cdUSDTtoSilverRate=500000000000000000;
  address public cdSilverAddress=0x6fC9249d195Ea8aD5072E0Bbbe62ec37fB51b078;

  address public owner = msg.sender;
  uint256 oneEther=1000000000000000000;
  address public USDTaddress=0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

  receive() external payable {}

  function BNBtoToken(address tokenAddress) public payable{
        require(msg.value>=(oneEther/100));
        require(tokenAddress==cdSilverAddress||tokenAddress==cdBrentCrudeOilAddress||tokenAddress==cdGoldAddress||tokenAddress==cdNaturalGasAddress||tokenAddress==cdCopperAddress);
  
        IERC20 tokenContract = IERC20(tokenAddress);

        if(tokenAddress==cdSilverAddress){
        uint256 _amountTo =(msg.value*cdBNBtoSilverRate)/oneEther;
        tokenContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdBrentCrudeOilAddress){
        uint256 _amountTo =(msg.value*cdBNBtoBrentCrudeOilRate)/oneEther;
        tokenContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdGoldAddress){
        uint256 _amountTo =(msg.value*cdBNBtoGoldRate)/oneEther;
        tokenContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdNaturalGasAddress){
        uint256 _amountTo =(msg.value*cdBNBtoNaturalGasRate)/oneEther;
        tokenContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCopperAddress){
        uint256 _amountTo =(msg.value*cdBNBtoCopperRate)/oneEther;
        tokenContract.transfer(msg.sender, _amountTo);
        }

  }

   function TokentoBNB(uint256 amount,address tokenAddress) public{
        require(amount>=(oneEther/100));
        require(tokenAddress==cdSilverAddress||tokenAddress==cdBrentCrudeOilAddress||tokenAddress==cdGoldAddress||tokenAddress==cdNaturalGasAddress||tokenAddress==cdCopperAddress);

        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transferFrom(msg.sender, address(this), amount);

        if(tokenAddress==cdSilverAddress){
        uint256 _amountTo =(oneEther*amount)/cdBNBtoSilverRate;
        payable(msg.sender).transfer(_amountTo);
        }
        else if(tokenAddress==cdBrentCrudeOilAddress){
        uint256 _amountTo =(oneEther*amount)/cdBNBtoBrentCrudeOilRate;
        payable(msg.sender).transfer(_amountTo);
        }
        else if(tokenAddress==cdGoldAddress){
        uint256 _amountTo =(oneEther*amount)/cdBNBtoGoldRate;
        payable(msg.sender).transfer(_amountTo);
        }
        else if(tokenAddress==cdNaturalGasAddress){
        uint256 _amountTo =(oneEther*amount)/cdBNBtoNaturalGasRate;
        payable(msg.sender).transfer(_amountTo);
        }
        else if(tokenAddress==cdCopperAddress){
        uint256 _amountTo =(oneEther*amount)/cdBNBtoCopperRate;
        payable(msg.sender).transfer(_amountTo);
        }
  }

  function USDTtoToken(uint256 amount,address tokenAddress) public{
        require(amount>=(oneEther/100));
        require(tokenAddress==cdSilverAddress||tokenAddress==cdBrentCrudeOilAddress||tokenAddress==cdGoldAddress||tokenAddress==cdNaturalGasAddress||tokenAddress==cdCopperAddress);
        IERC20 tokenContract = IERC20(USDTaddress);
        tokenContract.transferFrom(msg.sender, address(this), amount);
        
        if(tokenAddress==cdSilverAddress){
        uint256 _amountTo =(amount*cdUSDTtoSilverRate)/oneEther;
        IERC20 cdSilverContract = IERC20(cdSilverAddress);
        cdSilverContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdBrentCrudeOilAddress){
        uint256 _amountTo =(amount*cdUSDTtoBrentCrudeOilRate)/oneEther;
        IERC20 cdBrentCrudeOilContract = IERC20(cdBrentCrudeOilAddress);
        cdBrentCrudeOilContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdGoldAddress){
        uint256 _amountTo =(amount*cdUSDTtoGoldRate)/oneEther;
        IERC20 cdGoldContract = IERC20(cdGoldAddress);
        cdGoldContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdNaturalGasAddress){
        uint256 _amountTo =(amount*cdUSDTtoNaturalGasRate)/oneEther;
        IERC20 cdNaturalGasContract = IERC20(cdNaturalGasAddress);
        cdNaturalGasContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCopperAddress){
        uint256 _amountTo =(amount*cdUSDTtoCopperRate)/oneEther;
        IERC20 cdCopperContract = IERC20(cdCopperAddress);
        cdCopperContract.transfer(msg.sender, _amountTo);
        }
  }


    function TokenToUSDT(uint256 amount,address tokenAddress) public{
        require(amount>=(oneEther/100));
        require(tokenAddress==cdSilverAddress||tokenAddress==cdBrentCrudeOilAddress||tokenAddress==cdGoldAddress||tokenAddress==cdNaturalGasAddress||tokenAddress==cdCopperAddress);
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transferFrom(msg.sender, address(this), amount);
        IERC20 USDTContract = IERC20(USDTaddress);

        if(tokenAddress==cdSilverAddress){
        uint256 _amountTo =(oneEther*amount)/cdUSDTtoSilverRate;
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdBrentCrudeOilAddress){
        uint256 _amountTo =(oneEther*amount)/cdUSDTtoBrentCrudeOilRate;
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdGoldAddress){
        uint256 _amountTo =(oneEther*amount)/cdUSDTtoGoldRate;
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdNaturalGasAddress){
        uint256 _amountTo =(oneEther*amount)/cdUSDTtoNaturalGasRate;
        USDTContract.transfer(msg.sender, _amountTo);
        }
        else if(tokenAddress==cdCopperAddress){
        uint256 _amountTo =(oneEther*amount)/cdUSDTtoCopperRate;
        USDTContract.transfer(msg.sender, _amountTo);
        }
  }



  function updateBNBtoTokenRate(uint256[] memory _rate) restricted public {
    cdBNBtoSilverRate=_rate[0];
    cdBNBtoBrentCrudeOilRate=_rate[1];
    cdBNBtoGoldRate=_rate[2];
    cdBNBtoNaturalGasRate=_rate[3];
    cdBNBtoCopperRate=_rate[4];

    cdUSDTtoSilverRate=_rate[5];
    cdUSDTtoBrentCrudeOilRate=_rate[6];
    cdUSDTtoGoldRate=_rate[7];
    cdUSDTtoNaturalGasRate=_rate[8];
    cdUSDTtoCopperRate=_rate[9];
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

 
}