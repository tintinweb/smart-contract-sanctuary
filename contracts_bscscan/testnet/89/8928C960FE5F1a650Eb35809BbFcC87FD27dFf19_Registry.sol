/**
 *Submitted for verification at BscScan.com on 2021-07-30
*/

pragma solidity ^0.4.21;

contract Ownable {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

//This is used for upgrade
contract Storage {
    //address payable public rewardAddress;
    bool public _enabled;
    bool public buyBackEnabled;
    uint256 public _taxFee;
    uint256 public _liquidityFee;
    uint256 public rewardDivisor;
    uint256 public _maxTxAmount;
    uint256 public minimumTokensBeforeSwap;
    uint256 public buyBackUpperLimit;
}


contract Registry is Storage, Ownable {

    address public logic_contract;

    // admin to set contract
    function setLogicContract(address _c) public onlyOwner returns (bool success){
        logic_contract = _c;
        return true;
    }

    // fall back function
    function () payable public {

        address target = logic_contract;

        assembly {
            // Copy the data sent to the memory address starting free mem position
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            // Proxy the call to the contract address with the provided gas and data
            let result := delegatecall(gas, target, ptr, calldatasize, 0, 0)

            // Copy the data returned by the proxied call to memory
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            // Check what the result is, return and revert accordingly
            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }

}