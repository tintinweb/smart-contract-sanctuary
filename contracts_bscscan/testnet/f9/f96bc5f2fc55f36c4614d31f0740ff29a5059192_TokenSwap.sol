// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IBEP20.sol";
import "./Ownable.sol";

/*

*/
contract TokenSwap is Ownable{
    IBEP20  internal _token1;
    address internal _owner1;
    IBEP20  internal _token2;

    uint256 _valueTK1  = 1 * 10 ** 17;  // 1usdFacucet = 0.1ZFaucet if usdFacucet with  18 decimals 
    //uint8 decimalsTk2 = 6;

    constructor() {
        _token1 = IBEP20(0xa8f8C76CE1528a20e6E837B9d3f53FDFEe0dCD32); //ZFAUCET
        _owner1 = 0x8A3DA0982DF04988ad04536D92FeFe88701619Bc; //WALLET ZFAUCET - Teste1 tetnet
        _token2 = IBEP20(0xEdA7631884Ee51b4cAa85c4EEed7b0926954d180); //USDFALCET
    }

    function swap(uint256 amountTK2) public {
        uint256 _amountTK1 = (amountTK2 / _valueTK1) * (10 ** 18);
        //require(owner2[msg.sender], "Not authorized");  //user 
        // require(
        //     _token1.allowance(_owner1, address(this)) >= _amountTK1,  // wallet zeex
        //     "Token1 allowance too low"
        // );
        // require(
        //     _token2.allowance(msg.sender, address(this)) >= amountTK2,  //USDT
        //     "Token2 allowance too low"
        // );
        _safeTransferFrom(_token2, msg.sender, _owner1, amountTK2);
        _safeTransferFrom(_token1, _owner1, msg.sender, _amountTK1);
    }

    function _safeTransferFrom (
        IBEP20 token,
        address sender,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

    function setParams(address token1, address owner1, address token2, uint256 valueTK1) external onlyOwner {
        _token1 = IBEP20(token1);
        _owner1 = owner1;
        _token2 = IBEP20(token2);
        _valueTK1 = valueTK1;  
    }

    function getParams() external view returns (IBEP20, address, IBEP20, uint256) {
        return (_token1, _owner1, _token2, _valueTK1); 
    }

}