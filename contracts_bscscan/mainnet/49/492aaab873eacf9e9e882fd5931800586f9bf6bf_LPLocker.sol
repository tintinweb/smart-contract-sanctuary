import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract LPLocker {

    using SafeBEP20 for IBEP20;
    
    IBEP20 public immutable lpToken;
    uint256 public immutable unlockTime;
    address public immutable unlockTo;
    
    constructor (IBEP20 _lpToken, uint256 _unlockTime, address _unlockTo) public{
        lpToken = _lpToken;
        unlockTime = _unlockTime;
        unlockTo = _unlockTo;
    }
    
    function unlock() external {
        require(block.timestamp > unlockTime, "Before unlock time");
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeTransfer(unlockTo, bal);
    }
}