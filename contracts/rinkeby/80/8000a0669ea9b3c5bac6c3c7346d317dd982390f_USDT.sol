pragma solidity 0.6.6;


import "./ERC20.sol";

contract USDT is ERC20("USDT", "USDT") {
    /// @notice Creates `_amount` token to `_to`.
    function mint(address _to, uint256 _amount) public  {
        _mint(_to, _amount);
    }

    receive() external payable { } 

    constructor() public {
        _setupDecimals(6);
        mint(msg.sender,1e30);
    }
}