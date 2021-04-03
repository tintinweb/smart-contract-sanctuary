pragma solidity =0.8.3;

import "./ERC20.sol";

contract Token is ERC20("Good Token", "GT") {
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount*10**18);
    }
}