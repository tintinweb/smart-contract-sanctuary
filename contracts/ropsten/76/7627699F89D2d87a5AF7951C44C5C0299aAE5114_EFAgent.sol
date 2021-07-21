/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.17;



// Part: TrustListInterface

contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}

// Part: TrustListTools

contract TrustListTools{
  TrustListInterface public trustlist;
  constructor(address _list) public {
    //require(_list != address(0x0));
    trustlist = TrustListInterface(_list);
  }

  modifier is_trusted(address addr){
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

}

// File: EFAgent.sol

contract EFAgent is TrustListTools {
    constructor (address trustlist_addr) public TrustListTools(trustlist_addr) {
    }

    // to be used for ERC20
    function exec(address callee, bytes calldata payload) external is_trusted(msg.sender) returns (bytes memory)  {
        (bool success, bytes memory returnData) = address(callee).call(payload);
        require(success, "callee return failed when executing payload");
        return returnData;
    }

    // fallback function for receive ETH
    event ReceiveETH(uint256);
    function() external payable {
        emit ReceiveETH(msg.value);
    }

    // to be used for ETH
    function exec(address callee, uint256 ETH_amount, bytes calldata payload) external payable is_trusted(msg.sender) returns (bytes memory) {
        (bool success, bytes memory returnData) = address(callee).call.value(ETH_amount)(payload);
        require(success, "callee return failed when executing payload");
        return returnData;
    }
}