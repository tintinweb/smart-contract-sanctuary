/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity ^0.6.8;
interface FlashstakePoolInterface {
    function reserveFlashAmount () external view returns (uint256); 
    function reserveAltAmount () external view returns (uint256);
}
interface ERC20 {
    function balanceOf(address _address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}
contract FlashstakeProtocolQuery {
    address _protocolAddress = 0x15EB0c763581329C921C8398556EcFf85Cc48275;
    address _flashToken = 0x20398aD62bb2D930646d45a6D4292baa0b860C1f;
    function getReserves(address[] memory _pools) public view returns (uint[] memory) {
        uint[] memory _output = new uint[](_pools.length * 5);
         for (uint i = 0; i < _pools.length; i++) {
             uint j = i*5;
            _output[j] = ERC20(_flashToken).balanceOf(_protocolAddress);
            _output[j+1] = ERC20(_flashToken).totalSupply();
            _output[j+2]= FlashstakePoolInterface(_pools[i]).reserveFlashAmount();
            _output[j+3]= FlashstakePoolInterface(_pools[i]).reserveAltAmount();
            _output[j+4]= ERC20(_pools[i]).totalSupply();
         }
        return _output;
    }
}