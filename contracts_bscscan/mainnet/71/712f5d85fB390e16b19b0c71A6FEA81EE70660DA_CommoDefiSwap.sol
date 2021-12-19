// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CommoDefiSwap {
  uint public cdBNBtoCopperRate;
  uint public cdUSDTtoCopperRate;
  address public cdCopperAddress=0x192b9B89E4E37A7274d2248a95706B3CD56D83b7;

  uint public cdBNBtoNaturalGasRate;
  uint public cdUSDTtoNaturalGasRate;
  address public cdNaturalGasAddress=0x4e950657B9c674fBCce450C9bc5f1D97F3612Ffb;

  uint public cdBNBtoGoldRate;
  uint public cdUSDTtoGoldRate;
  address public cdGoldAddress=0xF749f937902A560D36CF255216D68F950cb1dC02;

  uint public cdBNBtoBrentCrudeOilRate;
  uint public cdUSDTtoBrentCrudeOilRate;
  address public cdBrentCrudeOilAddress=0xad60bB54a3121fC0c03EDa57c2D87013Ed0F5A0E;

  uint public cdBNBtoSilverRate;
  uint public cdUSDTtoSilverRate;
  address public cdSilverAddress=0x22b00e763Cc91c2dc313761d251CCd0820D96AEe;

  address public owner = msg.sender;
  uint256 oneEther=1000000000000000000;
  address public USDTaddress=0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

  bool public swapStatus=true;

  receive() external payable {}

  function BNBtoToken(address tokenAddress) public payable{
        require(swapStatus==true);
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
        require(swapStatus==true);
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
        require(swapStatus==true);
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
        require(swapStatus==true);
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



  function updateRate(uint256[] memory _rate) restricted public {
    cdBNBtoSilverRate=_rate[0]-(_rate[0]/1000); // commission 0.1%
    cdBNBtoBrentCrudeOilRate=_rate[1]-(_rate[1]/1000);
    cdBNBtoGoldRate=_rate[2]-(_rate[2]/1000);
    cdBNBtoNaturalGasRate=_rate[3]-(_rate[3]/1000);
    cdBNBtoCopperRate=_rate[4]-(_rate[4]/1000);

    cdUSDTtoSilverRate=_rate[5]-(_rate[5]/1000);
    cdUSDTtoBrentCrudeOilRate=_rate[6]-(_rate[6]/1000);
    cdUSDTtoGoldRate=_rate[7]-(_rate[7]/1000);
    cdUSDTtoNaturalGasRate=_rate[8]-(_rate[8]/1000);
    cdUSDTtoCopperRate=_rate[9]-(_rate[9]/1000);
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

 
}