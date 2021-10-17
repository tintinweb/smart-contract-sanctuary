pragma solidity =0.7.3;

import "./ERC20.sol";

contract DEX {
    IERC20 public token;

    event Bought(uint256 amount);
    event Sold(uint256 amount);

    constructor() public {
        token = new Muscoin();
    }

    function buy() payable public {
        uint256 amountToBuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this)); // total Supply = 100 ether;
        require(amountToBuy > 0, 'You need to send some ether!');
        require(dexBalance >= amountToBuy, 'Not enough tokens tin the treasury');
        token.transfer(msg.sender, amountToBuy);
        emit Bought(amountToBuy);
    }

    function sell() public payable {

    }
}