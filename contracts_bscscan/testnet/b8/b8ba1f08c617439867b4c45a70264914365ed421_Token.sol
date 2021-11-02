pragma solidity ^0.6.2;

import "./ERC20.sol";
contract Token is ERC20{

    string private _name;
    string private _symbol;

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    constructor() public{
        _name='Token';
        _symbol='TK';
        _mint(msg.sender, 21000000 * (10 ** 18));
    }

    function _transfer(address recipient,uint256 amount) public returns(bool){
        return super.transfer(recipient, amount);
    }

    function _transferFrom(address sender,address recipient,uint256 amount) public returns(bool){
        return super.transferFrom(sender,recipient,amount);
    }

}