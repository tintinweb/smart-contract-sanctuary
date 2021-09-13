pragma solidity 0.7.5;
import "./ERC20.sol";
import "./Ownable.sol";

contract MockZCNToken is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){
        _setupDecimals(10);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}