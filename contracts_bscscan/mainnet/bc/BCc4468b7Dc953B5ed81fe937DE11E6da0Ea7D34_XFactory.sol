/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// File: contracts/XFactory/storage/XFactorySlot.sol
pragma solidity ^0.6.12;

 /**
  * @title BiFi-X XFactorySlot contract
  * @notice For prevent proxy storage variable mismatch
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract XFactorySlot {
  address public storageAddr;
  address public _implements;
  address public _storage;

  address public owner;
  address public NFT;

  address public bifiManagerAddr;
  address public uniswapV2Addr;

  address public bifiAddr;
  address public wethAddr;

  // bifi fee variable
  uint256 fee;
  uint256 discountBase;
}

// File: contracts/XFactory/XFactory.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

 /**
  * @title BiFi-X XFactory proxy contract
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract XFactory is XFactorySlot {
  /**
	* @dev Constructor
	* @param implementsAddr The address of XFactoryExternal logic contract
  * @param _storageAddr The address of XFactory data storage
  * @param _bifiManagerAddr The address of bifi manager
  * @param _uniswapV2Addr The address of uniswap v2
  * @param _bifiAddr The address of bifi token
  * @param _wethAddr The address of weth token
  * @param _fee The amount of static bifi-x fee
  * @param _discountBase The minimum amount hold to get a flashloan fee discount
	*/
  constructor(
    address implementsAddr,
    address _storageAddr,
    address _bifiManagerAddr,
    address _uniswapV2Addr,
    address _bifiAddr,
    address _wethAddr,
    uint256 _fee,
    uint256 _discountBase
  )
  public {
    owner = msg.sender;
    _implements = implementsAddr;
    storageAddr = _storageAddr;

    // set slot
    bifiManagerAddr = _bifiManagerAddr;
    uniswapV2Addr = _uniswapV2Addr;
    bifiAddr = _bifiAddr;
    wethAddr = _wethAddr;
    fee = _fee;
    discountBase = _discountBase;
  }

  fallback() external payable {
    address addr = _implements;
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  receive() external payable {}
}