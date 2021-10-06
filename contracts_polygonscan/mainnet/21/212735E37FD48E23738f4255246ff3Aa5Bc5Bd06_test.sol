pragma solidity 0.6.12;

import { IERC20 } from "./Interfaces.sol";
import { SafeMath } from "./Libraries.sol";

contract test {
    using SafeMath for uint256;
    address augustusAddr = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    address usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;

    function executeFlashSwap(
        bytes calldata params
    )
        external
        returns (bool)
    {
        IERC20(usdc).transferFrom(msg.sender, address(this), 10000);

        (bool success,) = augustusAddr.call(params);
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        uint daiBalance = IERC20(dai).balanceOf(address(this));
        IERC20(dai).transferFrom(address(this), msg.sender, daiBalance);

        return true;
    }

}