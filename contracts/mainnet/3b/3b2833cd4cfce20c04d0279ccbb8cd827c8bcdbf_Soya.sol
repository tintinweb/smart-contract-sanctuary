pragma solidity >=0.4.22 < 0.7.0;


import "./ERC20.sol";
import "./MinterRole.sol";

contract Soya is ERC20, MinterRole {

    string public constant name = 'SoyaCoin';
    string public constant symbol = 'SOYA';
    uint8 public constant decimals = 18;

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}