/**
 *Submitted for verification at hecoinfo.com on 2022-05-05
*/

pragma solidity ^0.8.0;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}





pragma solidity >=0.8.4;



interface CToken {   
    function underlying() external view returns (address);
}

interface ILiquidateHelperV2 { 
     struct TokenInfo {
        address cTokenAddr;
        address underlying;
        uint amount;     
        uint processedAmtInUSD; 
        uint processedAmt; 
        string  tokenName;
        uint decimals;
        uint price;
    }

    function getLiquidateInfo(address _borrower) 
                           external view returns 
                          (uint, TokenInfo[] memory, TokenInfo[] memory);
    function getexchangeRateStored(address _ctoken) external view returns (uint);
    function amountToBeLiquidatedSieze(
                                    address _cToken, 
                                    address _cTokenCollateral, 
                                    uint    _actualRepayAmount) 
                                    external view returns (uint) ;
    function liquidateForNativeToken(  
                                    address _borrower, 
                                    address _cTokenCollateral,
                                    bool    isRedeem) 
                                    external payable returns (uint256);
    function liquidateForErc20(
                              address _borrower,
                              address _cRepayToken, 
                              address _cTokenCollateral,
                              uint    _repayAmount,
                              bool    isRedeem) 
                              external returns (uint256);
}


contract LiquidateHelperErrTry {
  event ErrorLogging(string reason);
  event Logging(string reason);
 
  address public liquidateHelperv2Addr;
  ILiquidateHelperV2 public liquidatev2Contract;
  constructor (address _liquidateHelperAddr) {
 require(_liquidateHelperAddr != address(0), "invalid LiquidateHelperAddr!");
 liquidateHelperv2Addr = _liquidateHelperAddr;
 liquidatev2Contract = ILiquidateHelperV2(liquidateHelperv2Addr);

} 

function getLiquidateInfo(address _borrower) 
                           external view returns 
                          (uint rhealth, 
                          ILiquidateHelperV2.TokenInfo[] memory returnBorrows, 
                          ILiquidateHelperV2.TokenInfo[] memory returnSupplys) {
    try liquidatev2Contract.getLiquidateInfo( _borrower) returns (uint health,
                          ILiquidateHelperV2.TokenInfo[] memory retBorrows, 
                          ILiquidateHelperV2.TokenInfo[] memory retSupplys) {
        rhealth = health;
        returnBorrows = retBorrows;
        returnSupplys = retSupplys;
    } catch {
        rhealth = 0;
        returnBorrows = new ILiquidateHelperV2.TokenInfo[](0);
        returnSupplys = new ILiquidateHelperV2.TokenInfo[](0);
    }    
}

function getexchangeRateStored(address _ctoken) external view returns (uint) {      
      return liquidatev2Contract.getexchangeRateStored(_ctoken);
}

function amountToBeLiquidatedSieze(
                                    address _cToken, 
                                    address _cTokenCollateral, 
                                    uint    _actualRepayAmount) 
                                    external view returns (uint)  { 
  return liquidatev2Contract.amountToBeLiquidatedSieze(_cToken,_cTokenCollateral,_actualRepayAmount);
}

function liquidateForErc20(
                              address _borrower,
                              address _cRepayToken, 
                              address _cTokenCollateral,
                              uint    _repayAmount,
                              bool    isRedeem) 
                              external returns(bool ret, string memory info) {
                        
    address erc20Token = CToken(_cRepayToken).underlying();
    IERC20 token = IERC20(erc20Token); 
    token.approve(liquidateHelperv2Addr, _repayAmount);

    token.transferFrom(msg.sender, address(this), _repayAmount); 

    try liquidatev2Contract.liquidateForErc20( _borrower,
                                       _cRepayToken, 
                                       _cTokenCollateral,
                                       _repayAmount,
                                       isRedeem) returns (uint256 diff) {
        info = strConcat("Success liquidateForErc20 return: [",uint2str(diff),"]"); 
        ret = true;
        emit Logging(info);
   } catch Error(string memory reason) {
       info = strConcat("external call [liquidateForErc20] failed: [", reason,"]");
        emit ErrorLogging(info);
        ret = false;
    }

  }

  function liquidateForNativeToken(  
                                    address _borrower, 
                                    address _cTokenCollateral,
                                    bool    isRedeem) 
                                    external payable returns(bool ret, string memory info){   
    try liquidatev2Contract.liquidateForNativeToken{value:msg.value}( _borrower,                                        
                                                              _cTokenCollateral,
                                                              isRedeem) returns (uint256 diff) {
        info = strConcat("Success liquidateForNativeToken return: [", uint2str(diff),"] msg.value: " , uint2str(msg.value)); 
        emit Logging(info);
        ret = true;
    } catch Error(string memory reason) {
        info = strConcat("external call [liquidateForNativeToken] failed: [", reason,"]");
        emit ErrorLogging(info);
        ret = false;
    }    
  }

function uint2str(uint256 _i) public pure returns (string memory str)
{
  if (_i == 0)
  {
    return "0";
  }
  uint256 j = _i;
  uint256 length;
  while (j != 0)
  {
    length++;
    j /= 10;
  }
  bytes memory bstr = new bytes(length);
  uint256 k = length;
  j = _i;
  while (j != 0)
  {
    bstr[--k] = bytes1(uint8(48 + j % 10));
    j /= 10;
  }
  str = string(bstr);
}

function strConcat(
    string memory _a, 
    string memory _b, 
    string memory _c, 
    string memory _d, 
    string memory _e) public pure returns (string memory){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    uint i = 0;
    for (i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
}

function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) public pure returns (string memory) {
    return strConcat(_a, _b, _c, _d, "");
}

function strConcat(string memory _a, string memory _b, string memory _c) public pure returns (string memory) {
    return strConcat(_a, _b, _c, "", "");
}

function strConcat(string memory _a, string memory _b) public pure returns (string memory) {
    return strConcat(_a, _b, "", "", "");
}

}