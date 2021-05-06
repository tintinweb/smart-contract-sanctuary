pragma solidity ^0.5.16;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract MockToken is ERC20, ERC20Detailed {
    address public owner;
    mapping(address => uint) public role;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public ERC20Detailed(name, symbol, decimals) {
        owner = msg.sender;
        role[msg.sender] = 1;

        _mint(msg.sender, 10000000000 * (10**uint256(decimals)));
    }

    function addRole(address account) public onlyOwner {
        role[account] = 1;
    }

    function removeRole(address account) public onlyOwner {
        delete role[account];
    }

    function mint(address account, uint amount) public mint_burn {
        _mint(account, amount);
    }

    function burn(address account, uint amount) public mint_burn {
        _burn(account, amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Option is invalid");
        _;
    }

    modifier mint_burn() {
        require(role[msg.sender] > 0, "Option is invalid");
        _;
    }
}