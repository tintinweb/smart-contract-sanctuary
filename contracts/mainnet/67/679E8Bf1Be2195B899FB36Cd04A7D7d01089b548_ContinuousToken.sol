pragma solidity 0.4.25;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./BancorBondingCurve.sol";


contract ContinuousToken is Ownable, ERC20, ERC20Detailed, BancorBondingCurve {
    using SafeMath for uint;

    event Minted(address sender, uint amount, uint deposit);
    event Burned(address sender, uint amount, uint refund);

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint _initialSupply,
        uint32 _reserveRatio
    ) public ERC20Detailed(_name, _symbol, _decimals) BancorBondingCurve(_reserveRatio) {
        _mint(msg.sender, _initialSupply);
    }

    function continuousSupply() public view returns (uint) {
        return totalSupply(); // Continuous Token total supply
    }

    function _continuousMint(uint _deposit, uint _minReward) internal returns (uint) {
        require(_deposit > 0, "Deposit must be non-zero.");

        uint rewardAmount = getContinuousMintReward(_deposit);
        require(rewardAmount >= _minReward);
        _mint(msg.sender, rewardAmount);
        emit Minted(msg.sender, rewardAmount, _deposit);
        return rewardAmount;
    }

    function _continuousBurn(uint _amount, uint _minRefund) internal returns (uint) {
        require(_amount > 0, "Amount must be non-zero.");
        require(balanceOf(msg.sender) >= _amount, "Insufficient tokens to burn.");

        uint refundAmount = getContinuousBurnRefund(_amount);
        require(refundAmount >= _minRefund);
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount, refundAmount);
        return refundAmount;
    } 
}