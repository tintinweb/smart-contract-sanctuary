pragma solidity =0.8.3;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

contract Swapper {
    event Swap(uint256 amount, address indexed to);

    address immutable public ohGeez;
    address immutable public levx;

    constructor(address _ohGeez, address _levx) {
        ohGeez = _ohGeez;
        levx = _levx;
    }

    function swap(uint256 amount, address to) external {
        require(amount > 0, "LEVX: ZERO_AMOUNT_OH_GEEZ");
        require(to != address(0), "LEVX: NULL_ADDRESS_OH_GEEZ");

        IERC20(ohGeez).transferFrom(msg.sender, address(this), amount);
        IERC20(levx).transfer(to, amount * 10);

        emit Swap(amount, to);
    }
}