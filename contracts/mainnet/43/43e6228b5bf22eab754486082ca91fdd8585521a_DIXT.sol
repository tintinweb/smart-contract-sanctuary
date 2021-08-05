// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.8.0;

/* ----------------------------


---------------------------- */

import "./ERC20.sol";
import "./SafeMath.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract DIXT is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    address public minter;

    constructor (
        string memory name,
        string memory symbol,
        address initialAccount,
        uint256 initialBalance
    ) ERC20(name, symbol) {
        _mint(initialAccount, initialBalance);
        minter = owner();
    }

    function mint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

    function burn(uint256 amount) public override {
        ERC20Burnable.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        ERC20Burnable.burnFrom(account, amount);
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    modifier onlyMinter() {
        require(minter == _msgSender(), "Token: caller is not the minter");
        _;
    }
}
