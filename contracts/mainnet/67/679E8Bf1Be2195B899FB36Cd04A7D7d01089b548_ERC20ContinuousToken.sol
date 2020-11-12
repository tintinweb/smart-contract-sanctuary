pragma solidity 0.4.25;

import "./ContinuousToken.sol";

contract ERC20ContinuousToken is ContinuousToken {
    ERC20 public reserveToken;

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint _initialSupply,
        uint32 _reserveRatio,
        address _reserveTokenAddress
    ) public ContinuousToken(_name, _symbol, _decimals, _initialSupply, _reserveRatio) {
        reserveToken = ERC20(_reserveTokenAddress);
    }

    function () public { revert("Cannot call fallback function."); }

    function mint(uint _amount, uint _minReceived) public {
        _continuousMint(_amount, _minReceived);
        require(reserveToken.transferFrom(msg.sender, address(this), _amount), "mint() ERC20.transferFrom failed.");
    }

    function burn(uint _amount, uint _minReceived) public {
        uint returnAmount = _continuousBurn(_amount, _minReceived);
        require(reserveToken.transfer(msg.sender, returnAmount), "burn() ERC20.transfer failed.");
    }

    function reserveBalance() public view returns (uint) {
        return reserveToken.balanceOf(address(this));
    }
}