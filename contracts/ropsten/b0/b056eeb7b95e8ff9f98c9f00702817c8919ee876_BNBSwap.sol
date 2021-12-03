pragma solidity ^0.5.16;

import "./BEP20Token.sol";
import "./Context.sol";
import "./IBNBSwap.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract BNBSwap is Context, IBNBSwap, Ownable {
    using SafeMath for uint256;

    BEP20Token private _token;

    string private _name;
    uint256 private _rate;

    constructor(BEP20Token token) public {
        _token = token;
        _name = "BNB Swap Instant Exchange";
        _rate = 100;
    }

    /**
     * @dev Returns the name.
     */
    function name() external view returns(string memory) {
        return _name;
    }

    /**
     * @dev Returns the rate.
     */
    function rate() external view returns(uint256) {
        return _rate;
    }

    /**
     * @dev Returns true if successful.
     */
    function buyTokens() external payable returns(bool) {
        _buyTokens(_msgSender(), _msgValue());
        return true;
    }

    /**
     * @dev Returns true if successful.
     * @param value Tokens amount.
     */
    function sellTokens(uint256 value) external payable returns(bool) {
        _sellTokens(_msgSender(), value);
        return true;
    }

    /**
     * @param sender Sender's address.
     * @param value Sender's value.
     */
    function _buyTokens(address sender, uint256 value) internal {
        uint256 _tokenAmount = value.mul(_rate);
        require(_token.balanceOf(address(this)) >= _tokenAmount, "Not enough tokens available");
        _token.transfer(sender, _tokenAmount);
        emit TokensPurchased(sender, address(_token), _tokenAmount, _rate);
    }

    /**
     * @param sender Sender's address.
     * @param value Sender's value.
     */
    function _sellTokens(address payable sender, uint256 value) internal {
        require(_token.balanceOf(sender) >= value);
        uint256 _bnbAmount = value.div(_rate);
        require(address(this).balance >= _bnbAmount);
        _token.transferFrom(sender, address(this), value);
        sender.transfer(_bnbAmount);
        emit TokensSold(sender, address(_token), value, _rate);
    }
}