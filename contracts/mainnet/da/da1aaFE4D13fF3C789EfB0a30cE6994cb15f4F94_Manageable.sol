// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Randomizable.sol";

contract Manageable is Randomizable {
    event MigrationComplete(address to);
    event TokenNameChange(string name);
    event TokenSymbolChange(string symbol);

    function migrate(address to) public onlyOwner whenNotLockedL {
        uint256 reservesLength = getReserves().length();
        for (uint256 i = 0; i < reservesLength; i++) {
            uint256 tokenId = getReserves().at(i);
            getCPM().transferPunk(to, tokenId);
        }
        emit MigrationComplete(to);
    }

    function changeTokenName(string memory newName)
        public
        onlyOwner
        whenNotLockedM
    {
        getERC20().changeName(newName);
        emit TokenNameChange(newName);
    }

    function changeTokenSymbol(string memory newSymbol)
        public
        onlyOwner
        whenNotLockedM
    {
        getERC20().changeSymbol(newSymbol);
        emit TokenSymbolChange(newSymbol);
    }

    function setReverseLink() public onlyOwner whenNotLockedS {
        getERC20().setVaultAddress(address(this));
    }
}
