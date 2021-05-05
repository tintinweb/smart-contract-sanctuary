// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './ERC20.sol';

contract NoremToken is ERC20 {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () ERC20("Norem", "NRM", 18) {
        uint256 _initialSupply = 10000000 * 10 ** decimals(); // initial supply: 10 million
        address msgSender = _msgSender();
        _mint(msgSender, _initialSupply);
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function burn(address account, uint256 amount) public {
        _burn(account,  amount);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renouceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zsero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}