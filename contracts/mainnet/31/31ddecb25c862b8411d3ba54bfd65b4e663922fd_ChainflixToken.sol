pragma solidity ^0.4.24;

import "./ERC20Pausable.sol";
import "./ERC20Detailed.sol";
import "./ERC20Mintable.sol";

contract ChainflixToken is ERC20Pausable, ERC20Detailed, ERC20Mintable {

    mapping (address => uint256) _holder;
    address _owner;

    constructor()
        ERC20Mintable()
        ERC20Detailed('CHAINFLIX', 'CFXT', 18)
        ERC20()
        public
    {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier whenNotHolder() {
        require(!isHolder(msg.sender));
        _;
    }

    function isHolder(address account) public view returns (bool) {
        require(account != address(0));
        return _holder[account] > block.number;
    }

    function addHolder(address account, uint256 expired) external onlyOwner {
        require(account != address(0));
        require(_holder[account] == 0);
        _holder[account] = expired;
    }

    function removeHolder(address account) external onlyOwner {
        _holder[account] = 0;
    }

    function transfer(address to, uint256 value) public whenNotHolder returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from,address to, uint256 value) public whenNotHolder returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotHolder returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotHolder returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotHolder returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }


}
