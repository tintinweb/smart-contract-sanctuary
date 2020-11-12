// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Randomizable.sol";

contract Manageable is Randomizable {
    event MigrationComplete(address to);
    event TokenNameChange(string name);
    event TokenSymbolChange(string symbol);

    function migrate(address to, uint256 max) public onlyOwner whenNotLockedL {
        uint256 count = 0;
        uint256 reservesLength = getReserves().length();
        for (uint256 i = 0; i < reservesLength; i++) {
            if (count >= max) {
                return;
            }
            uint256 tokenId = getReserves().at(0);
            getCPM().transferPunk(to, tokenId);
            getReserves().remove(tokenId);
            count = count.add(1);
        }
        getERC20().transferOwnership(to);
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

    function setReverseLink() public onlyOwner {
        getERC20().setVaultAddress(address(this));
    }
}
