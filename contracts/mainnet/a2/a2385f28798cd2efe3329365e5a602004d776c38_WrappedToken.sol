// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface IWrappedToken {
    event Burn(address indexed _sender, bytes32 indexed _to, uint256 _amount);

    function burn(uint256 _amount, bytes32 _to) external;

    function mint(address _account, uint256 _amount) external;
}

contract WrappedToken is IWrappedToken, ERC20, Ownable {
    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {}

    function burn(uint256 amount, bytes32 to) public override {
        _burn(_msgSender(), amount);

        emit Burn(_msgSender(), to, amount);
    }

    function mint(address account, uint256 amount) public override onlyOwner {
        _mint(account, amount);
    }
}