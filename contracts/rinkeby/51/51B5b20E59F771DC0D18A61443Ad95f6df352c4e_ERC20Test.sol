pragma solidity >=0.6.0 <0.8.0;
import "./ERC20.sol";

contract ERC20Test is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}