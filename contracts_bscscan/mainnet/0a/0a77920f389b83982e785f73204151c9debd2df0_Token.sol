pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";



contract Token is ERC20, Ownable {

    uint public constant inRate = 17;
    uint public constant outRate = 8;
    address public inAddr;
    address public outAddr;
    address public pair;

    constructor(address _inAddr, address _outAddr) ERC20("Roma", "ROMA") {

        inAddr = _inAddr;
        outAddr = _outAddr;

        _mint(msg.sender, 1_0000_0000 * 10 ** decimals());
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if(pair != address(0)){
            if(sender == pair){
                // out
                uint x = amount * outRate / 100;
                super._transfer(sender, outAddr, x);
                super._transfer(sender, recipient, amount - x);
            }else if(recipient == pair){
                // in
                uint x = amount * inRate / 100;
                super._transfer(sender, inAddr, x);
                super._transfer(sender, recipient, amount - x);
            }else{
                super._transfer(sender, recipient, amount);
            }
        }else{
            super._transfer(sender, recipient, amount);
        }
    }


    function setPair(address _pair) public onlyOwner {
        pair = _pair;
    }


}