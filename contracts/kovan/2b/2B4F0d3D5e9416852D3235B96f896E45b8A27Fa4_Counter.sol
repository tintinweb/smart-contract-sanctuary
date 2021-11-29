/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
contract KeeperBase {
  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    require(tx.origin == address(0), "only for simulated backend");
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}
interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

contract Counter is KeeperCompatibleInterface {
   
    uint public remainingDays;
    address private _owner;
    LinkTokenInterface internal immutable LINK;
    uint256 private winningPrize = (1 * 10 ** 18);
    uint public immutable interval;
    uint public lastTimeStamp;
    address winningAddress;
    address private   _link = 0xa36085F69e2889c224210F603D836748e7dC0088; 

     function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
    }
    
     function getOwner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(getOwner() == msg.sender);
        _;
    }
    constructor(uint updateInterval) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;
      winningAddress  = msg.sender;
      remainingDays = 14;
      _transferOwnership(msg.sender);
      LINK = LinkTokenInterface(_link);
    }

    function checkUpkeep(bytes calldata ) external override returns (bool upkeepNeeded, bytes memory ) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
         
    }

    function performUpkeep(bytes calldata ) external override {
        lastTimeStamp = block.timestamp;
        if(remainingDays>0){
          remainingDays = remainingDays - 1;
        }
        if(remainingDays ==0){
            remainingDays =13;
        }


    }

    function setWinningAddress(address newWinnningAddress) public onlyOwner{
        winningAddress = newWinnningAddress;
    }
    function getWinningAddress() public view returns(address){
        return winningAddress;
    }
    function claimPrize() public {
        
    
        LINK.transfer(winningAddress,winningPrize);
    }
}