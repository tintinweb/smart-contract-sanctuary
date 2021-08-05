/**
 *Submitted for verification at Etherscan.io on 2020-08-15
*/

pragma solidity ^0.6.0;

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

contract Stores {
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
  * @dev Connector Details.
  */
  function connectorID() public view returns(uint model, uint id) {
    (model, id) = (1, 39);
  }

}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
}

contract DSMath {
  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }
}

interface ICurve {
  function claim(address addr) external;
}

contract CurveVestingHelpers is Stores, DSMath {
  /**
  * @dev Return Curve Token Address
  */
  function getCurveTokenAddr() internal pure returns (address) {
    return 0xD533a949740bb3306d119CC777fa900bA034cd52;
  }

  /**
  * @dev Return Curve Vesting Address
  */
  function getCurveVestingAddr() internal pure returns (address) {
    return 0x575CCD8e2D300e2377B43478339E364000318E2c;
  }
}

contract CurveVestingProtocol is CurveVestingHelpers {
  event LogClaim(address account, uint256 claimAmount, uint256 getId, uint256 setId);

  /**
  * @dev Claim Curve DAO Token.
  * @param getId Get token amount at this ID from `InstaMemory` Contract.
  * @param setId Set token amount at this ID in `InstaMemory` Contract.
  */
  function claim(uint getId, uint setId) external{
    TokenInterface curveTokenContract = TokenInterface(getCurveTokenAddr());

    uint initialCurveBal = curveTokenContract.balanceOf(address(this));
    ICurve(getCurveVestingAddr()).claim(address(this));
    uint finalCurveBal = curveTokenContract.balanceOf(address(this));

    uint claimedAmt = sub(finalCurveBal, initialCurveBal);

    setUint(setId, claimedAmt);

    emit LogClaim(address(this), claimedAmt, getId, setId);
    bytes32 _eventCode = keccak256("LogClaim(address,uint256,uint256,uint256)");
    bytes memory _eventParam = abi.encode(address(this), claimedAmt, getId, setId);
    emitEvent(_eventCode, _eventParam);
  }
}

contract ConnectCurveVesting is CurveVestingProtocol {
  string public name = "Curve-vesting-v1";
}