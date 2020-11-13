pragma solidity ^0.5.8;

import "./Context.sol";
import "./ITRC20.sol";
import "./BaseTRC20.sol";

contract Token is ITRC20, BaseTRC20 {
    constructor(address gr, address rewardAddress) public BaseTRC20("mumu", "MUMU", 18, 8, rewardAddress){
        require(gr != address(0), "invalid gr");
        require(rewardAddress != address(0), "invalid rewardAddress");
        _mint(gr, 5000 * 10 ** 18);
    }
}
