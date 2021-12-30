pragma solidity 0.4.24;

import './ERC20.sol';
import "./SafeMath.sol";

contract DexBancannabis {
    using SafeMath for uint256;

    ERC20 public token;

    event Bought(uint256 amount);
    event Sold(uint256 amount);

    constructor(ERC20 _token) public {
        token = _token;
    }

    function buy() payable public {
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some BnB");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        
        uint256 weiAmmount;
        weiAmmount = _getTokenAmount(amountTobuy, _getRate());

        token.transfer(msg.sender, weiAmmount);
        emit Bought(weiAmmount);
    }


    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        // rest 10% (0.1)
        // amount = SafeMath.sub(amount, SafeMath.mul(amount, 100000000000000000));
        msg.sender.transfer(_getEthAmount(amount));
        emit Sold(amount);
    }

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount, uint256 rate) internal view returns (uint256)
    {
        return _weiAmount.mul(rate);
    }

    function _getEthAmount(uint256 _weiAmount) internal view returns (uint256)
    {
        return _weiAmount.div(3025); // 3025 por cada eth
        /*if (block.timestamp < 1643648384) {
            return _weiAmount.div(165);
        }
        else if (block.timestamp < 1646067584) {
            return _weiAmount.div(140);
        }
        else {
            return _weiAmount.div(110);
        }*/
    }

    function _getRate() internal view returns (uint256)
    {
        return 3125;
        /*if (block.timestamp < 1643648384) {
            return 150;
        }
        else if (block.timestamp < 1646067584) {
            return 125;
        }
        else {
            return 100;
        }*/
    }


}