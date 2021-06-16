pragma solidity ^0.5.0;

import "./ERC20DetailedMock.sol";
import "./ERC20MintableMock.sol";
import "./ERC20BurnableMock.sol";


contract AuthencityERC20 is ERC20DetailedMock, ERC20MintableMock, ERC20BurnableMock{
    constructor (string memory name, string memory symbol)
        public
        ERC20DetailedMock(name, symbol)
    {
        // solhint-disable-previous-line no-empty-blocks
    }
}