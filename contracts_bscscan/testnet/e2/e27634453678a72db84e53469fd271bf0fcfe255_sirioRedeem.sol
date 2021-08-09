// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
}



import "IERC20.sol";

contract sirioRedeem{
    using SafeMath for uint256;
    
    IERC20 public sirio;
    IERC20 public dummy;
    mapping (address =>uint256) amounts;
    
    event redeemed(address who, uint256 amount);
    
    constructor (address _sirio,address _dummy){
        sirio=IERC20(_sirio);
        dummy=IERC20(_dummy);
    }
    

    function lockDummyToken() external{
	uint256 balance=dummy.balanceOf(msg.sender);
         dummy.transferFrom(msg.sender, address(this), balance);
         amounts[msg.sender]=amounts[msg.sender].add(balance);
    }
    
    function getRedeemableTokens(address who) external view returns (uint256){
        return amounts[who];
    }
    
    function redeem() external{
        sirio.transfer(msg.sender,amounts[msg.sender]);
        amounts[msg.sender]=0;
    }
    
}