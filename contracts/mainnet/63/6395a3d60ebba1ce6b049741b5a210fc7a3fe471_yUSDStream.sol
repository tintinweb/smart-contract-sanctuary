/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity >=0.4.21 <0.6.0;

pragma solidity >=0.4.21 <0.6.0;

contract IYieldStream{

  string public name;

  function target_token() public view returns(address);

  function getVirtualPrice() public view returns(uint256);

  function getDecimal() public pure returns(uint256);

  function getPriceDecimal() public pure returns(uint256);
}

contract yyCRVInterface{
  function getPricePerFullShare() public view returns(uint256);
}

contract yCRVInterface{
  function get_virtual_price() public view returns (uint256);
}

contract yUSDStream is IYieldStream{
  yyCRVInterface public yycrv_address;
  yCRVInterface public ycrv_address;

  constructor() public{
    name = "yUSD yield stream";
    yycrv_address = yyCRVInterface(address(0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c));
    ycrv_address = yCRVInterface(address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51));
  }

  function getyyCRVPrice() public view returns(uint256){
    return yycrv_address.getPricePerFullShare();
  }
  function getyCRVPrice() public view returns(uint256){
    return ycrv_address.get_virtual_price();
  }

  function target_token() public view returns(address){
    return address(0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c);
  }

  function getVirtualPrice() public view returns(uint256){
    return getyyCRVPrice() * getyCRVPrice() / 1e18;
  }
  function getDecimal() public pure returns(uint256){
    return 1e18;
  }

  function getPriceDecimal() public pure returns(uint256){
    return 1e18;
  }
}