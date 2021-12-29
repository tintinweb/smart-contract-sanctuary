pragma solidity ^0.5.17;

import "./Context.sol";

contract ThgBox is Context{
    string private _name;
    string private _symbol;
    address payable private _owner;
    uint private _boxPrice;

    constructor()public{
        _name = "Garena Hero Box";
        _symbol = "GHB";
        _owner = _msgSender();
        _boxPrice = 100000000000000000;
    }

    event PaidGarenaHeroBox(address spender);

    function paidGarenaHeroBox() external returns (bool) {
        require(_msgSender().balance >= _boxPrice);
        _owner.transfer(_boxPrice);

        emit PaidGarenaHeroBox(_msgSender());
        return true;
    }
}