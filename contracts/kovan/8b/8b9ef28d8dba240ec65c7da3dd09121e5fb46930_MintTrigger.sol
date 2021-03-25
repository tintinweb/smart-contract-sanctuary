pragma solidity ^0.8.0;
import "IERC20.sol";

contract MintTrigger
{
    event func_sig(bytes);
    function biu(address token, uint256 amount) public {
        //uint256 amount = 1000000000000000000;
        //address token = 0xe22da380ee6B445bb8273C81944ADEB6E8450422;
        bytes memory payload = abi.encodeWithSignature("mint(address,uint256)", token, amount);
        emit func_sig(payload);
        address addr = 0x600103d518cC5E8f3319D532eB4e5C268D32e604;
        (bool success,) = addr.call{gas: 1000000, value: 0}(payload);
        if (success)
        {
            IERC20 t = IERC20(token);
            uint256 balance = t.balanceOf(address(this));
            t.transfer(msg.sender, balance);
        }
    }

}