pragma solidity >=0.6.0;
contract CanoEventTest {
   event DataStored(uint256 indexed data1, uint256 indexed data2);
   uint256 data1;
   uint256 data2;
   function storeData(uint256 _data1, uint256 _data2) external {
      data1 = _data1;
      data2 = _data2;
      emit DataStored(data1, data2);
   }
}