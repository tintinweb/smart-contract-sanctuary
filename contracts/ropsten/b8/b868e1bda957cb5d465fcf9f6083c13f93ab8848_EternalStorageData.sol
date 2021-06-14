pragma solidity 0.5.17;

/**
 * @author Quant Network
 * @title EternalStorageData
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 * After V1.0 audit
 */
contract EternalStorageData {

  mapping(bytes32 => bool) internal boolStorage;
  mapping(bytes32 => address) internal addressStorage;
  mapping(bytes32 => string) internal stringStorage;
  mapping(bytes32 => bytes) internal bytesStorage;

  mapping(bytes32 => bytes1) internal bytes1Storage;
  mapping(bytes32 => bytes2) internal bytes2Storage;
  mapping(bytes32 => bytes4) internal bytes4Storage;
  mapping(bytes32 => bytes8) internal bytes8Storage;
  mapping(bytes32 => bytes16) internal bytes16Storage;
  mapping(bytes32 => bytes32) internal bytes32Storage;
  
  mapping(bytes32 => int8) internal int8Storage;
  mapping(bytes32 => int16) internal int16Storage;
  mapping(bytes32 => int32) internal int32Storage;
  mapping(bytes32 => int64) internal int64Storage;
  mapping(bytes32 => int128) internal int128Storage;
  mapping(bytes32 => int256) internal int256Storage;
  
  mapping(bytes32 => uint8) internal uint8Storage;
  mapping(bytes32 => uint16) internal uint16Storage;
  mapping(bytes32 => uint32) internal uint32Storage;
  mapping(bytes32 => uint64) internal uint64Storage;
  mapping(bytes32 => uint128) internal uint128Storage;
  mapping(bytes32 => uint256) internal uint256Storage;


}