pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "./SafeMath.sol";

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface EventInterface {
    function emitEvent(uint connectorType, uint connectorID, bytes32 eventCode, bytes calldata eventData) external;
}

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

}

contract Stores {

  /**
   * @dev Return ethereum address
   */
  function getEthAddr() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
  }

  /**
   * @dev Return memory variable address
   */
  function getMemoryAddr() internal pure returns (address) {
    return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
  }

  /**
   * @dev Return InstaEvent Address.
   */
  function getEventAddr() internal pure returns (address) {
    return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
  }

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
  }

  /**
  * @dev emit event on event contract
  */
  function emitEvent(bytes32 eventCode, bytes memory eventData) virtual internal {
    (uint model, uint id) = connectorID();
    EventInterface(getEventAddr()).emitEvent(model, id, eventCode, eventData);
  }

  /**
  * @dev Connector Details - needs to be changed before deployment
  */
  function connectorID() public view returns(uint model, uint id) {
    (model, id) = (0, 0);
  }

}


interface IStakingRewards {
  function stake(uint256 amount) external;
  function withdraw(uint256 amount) external;
  function getReward() external;
  function balanceOf(address) external view returns(uint);
}

interface SynthetixMapping {

  struct StakingData {
    address stakingPool;
    address stakingToken;
  }

  function stakingMapping(bytes32) external view returns(StakingData memory);

}

contract StakingHelper is DSMath, Stores {
  /**
   * @dev Return InstaDApp Staking Mapping Addresses
   */
  function getMappingAddr() internal virtual view returns (address) {
    return 0x772590F33eD05b0E83553650BF9e75A04b337526; // InstaMapping Address
  }

  /**
   * @dev Convert String to bytes32.
   */
  function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
    require(bytes(str).length != 0, "string-empty");
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      result := mload(add(str, 32))
    }
  }

  /**
   * @dev Get staking data
   */
  function getStakingData(string memory stakingName)
  internal
  virtual
  view
  returns (
    IStakingRewards stakingContract,
    TokenInterface stakingToken,
    bytes32 stakingType
  )
  {
    stakingType = stringToBytes32(stakingName);
    SynthetixMapping.StakingData memory stakingData = SynthetixMapping(getMappingAddr()).stakingMapping(stakingType);
    require(stakingData.stakingPool != address(0) && stakingData.stakingToken != address(0), "Wrong Staking Name");
    stakingContract = IStakingRewards(stakingData.stakingPool);
    stakingToken = TokenInterface(stakingData.stakingToken);
  }
}

contract Staking is StakingHelper {
  event LogDeposit(
    address token,
    bytes32 stakingType,
    uint256 amount,
    uint getId,
    uint setId
  );

  event LogWithdraw(
    address token,
    bytes32 stakingType,
    uint256 amount,
    uint getId,
    uint setId
  );

  event LogClaimedReward(
    address token,
    bytes32 stakingType,
    uint256 rewardAmt,
    uint setId
  );

  /**
  * @dev Deposit Token.
    * @param stakingPoolName staking token address.
    * @param amt staking token amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function deposit(
    string calldata stakingPoolName,
    uint amt,
    uint getId,
    uint setId
  ) external payable {
    uint _amt = getUint(getId, amt);
    (IStakingRewards stakingContract, TokenInterface stakingToken, bytes32 stakingType) = getStakingData(stakingPoolName);
    _amt = _amt == uint(-1) ? stakingToken.balanceOf(address(this)) : _amt;

    stakingToken.approve(address(stakingContract), _amt);
    stakingContract.stake(_amt);

    setUint(setId, _amt);
    emit LogDeposit(address(stakingToken), stakingType, _amt, getId, setId);
    bytes32 _eventCode = keccak256("LogDeposit(address,bytes32,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(address(stakingToken), stakingType, _amt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }

  /**
  * @dev Withdraw Token.
    * @param stakingPoolName staking token address.
    * @param amt staking token amount.
    * @param getId Get token amount at this ID from `InstaMemory` Contract.
    * @param setIdAmount Set token amount at this ID in `InstaMemory` Contract.
    * @param setIdReward Set reward amount at this ID in `InstaMemory` Contract.
  */
  function withdraw(
    string calldata stakingPoolName,
    uint amt,
    uint getId,
    uint setIdAmount,
    uint setIdReward
  ) external payable {
    uint _amt = getUint(getId, amt);
    (IStakingRewards stakingContract, TokenInterface stakingToken, bytes32 stakingType) = getStakingData(stakingPoolName);

    _amt = _amt == uint(-1) ? stakingContract.balanceOf(address(this)) : _amt;
    uint intialBal = stakingToken.balanceOf(address(this));
    stakingContract.withdraw(_amt);
    stakingContract.getReward();
    uint finalBal = stakingToken.balanceOf(address(this));

    uint rewardAmt = sub(finalBal, intialBal);

    setUint(setIdAmount, _amt);
    setUint(setIdReward, rewardAmt);

    emit LogWithdraw(address(stakingToken), stakingType, _amt, getId, setIdAmount);
    bytes32 _eventCodeWithdraw = keccak256("LogWithdraw(address,bytes32,uint256,uint256,uint256)");
    bytes memory _eventParamWithdraw = abi.encode(address(stakingToken), _amt, getId, setIdAmount);
    emitEvent(_eventCodeWithdraw, _eventParamWithdraw);

    emit LogClaimedReward(address(stakingToken), stakingType, rewardAmt, setIdReward);
    bytes32 _eventCodeReward = keccak256("LogClaimedReward(address,bytes32,uint256,uint256)");
    bytes memory _eventParamReward = abi.encode(address(stakingToken), rewardAmt, setIdReward);
    emitEvent(_eventCodeReward, _eventParamReward);
  }

  /**
  * @dev Claim Reward.
    * @param stakingPoolName staking token address.
    * @param setId Set reward amount at this ID in `InstaMemory` Contract.
  */
  function claimReward(
    string calldata stakingPoolName,
    uint setId
  ) external payable {
    (IStakingRewards stakingContract, TokenInterface stakingToken, bytes32 stakingType) = getStakingData(stakingPoolName);

    uint intialBal = stakingToken.balanceOf(address(this));
    stakingContract.getReward();
    uint finalBal = stakingToken.balanceOf(address(this));

    uint rewardAmt = sub(finalBal, intialBal);

    setUint(setId, rewardAmt);
    emit LogClaimedReward(address(stakingToken), stakingType, rewardAmt, setId);
    bytes32 _eventCode = keccak256("LogClaimedReward(address,bytes32,uint256,uint256)");
    bytes memory _eventParam = abi.encode(address(stakingToken), stakingType, rewardAmt, setId);
    emitEvent(_eventCode, _eventParam);
  }
}

contract ConnectStaking is Staking {
  string public name = "staking-v1";
}

