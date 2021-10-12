pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract Reward is Ownable {
    using SafeMath for uint256;

    address public bot;

    constructor (address _bot) public {
        bot = _bot;
    }

    function setBot(address _bot) public onlyOwner {
        bot = _bot;
    }

    function dispatchReward(address[] memory accounts) public onlyOwner {
        uint256 total = IERC20(bot).balanceOf(address(this));
        uint256 totalSupply = IERC20(bot).totalSupply();

        for (uint256 i; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 balance =  IERC20(bot).balanceOf(account);
            uint256 amount = total.mul(balance).div(totalSupply);
            if (amount > 0) {
                TransferHelper.safeTransfer(bot, account, amount);
            }
        }
    }

    function withdrawBOT(uint256 amount) public onlyOwner {
        TransferHelper.safeTransfer(bot, owner(), amount);
    }

    function withdrawTRX(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }
}