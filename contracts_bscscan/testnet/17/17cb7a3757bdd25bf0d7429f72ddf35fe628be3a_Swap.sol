// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IBEP20.sol";
import "./Ownable.sol";

/*

*/
contract Swap is Ownable{
    IBEP20  internal _ZEEX;
    address internal _ownerZEEX;
    IBEP20  internal _USDT;

    uint256 _valueZEEX = 22 * 10 ** 16;  // 1ZEEX = 0,22USDT 

    constructor() {
        _ZEEX      = IBEP20(0xa8f8C76CE1528a20e6E837B9d3f53FDFEe0dCD32); //ZFAUCET
        _ownerZEEX = 0x8A3DA0982DF04988ad04536D92FeFe88701619Bc; //WALLET ZFAUCET - Teste1 tetnet
        _USDT      = IBEP20(0xEdA7631884Ee51b4cAa85c4EEed7b0926954d180); //USDFALCET
    }

    function swap(uint256 amountUSDT) public {
        uint256 _amountZEEX = (amountUSDT * 10 ** 6) / _valueZEEX;
        require(
            _ZEEX.allowance(_ownerZEEX, address(this)) >= _amountZEEX,  
            "ZEEX allowance too low"
        );
        require(
            _USDT.allowance(msg.sender, address(this)) >= amountUSDT,
            "USDT allowance too low"
        );
        _safeTransferFrom(_USDT, msg.sender, _ownerZEEX, amountUSDT);
        _safeTransferFrom(_ZEEX, _ownerZEEX, msg.sender, _amountZEEX);
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

    function setValueZEEX(uint256 valueZEEX) external onlyOwner {
        _valueZEEX = valueZEEX;  
    }

    function setOwnerZEEX(address ownerZEEX) external onlyOwner {
        _ownerZEEX = ownerZEEX;  
    }

    function getParams() external view returns (address, uint256) {
        return (_ownerZEEX, _valueZEEX); 
    }

}