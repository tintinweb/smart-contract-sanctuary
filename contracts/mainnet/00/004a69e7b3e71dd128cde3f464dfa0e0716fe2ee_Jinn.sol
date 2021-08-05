// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IRipper.sol";
import "./RichBitchCoin.sol";


contract Jinn is IRipper{
    address owner;
    address payable treasurer;
    address public pyramid;
    bool eol;
    event LogCreatedPyramid(address pyramid);

    constructor(address payable _treasurer) public {
        owner = msg.sender;
        treasurer = _treasurer;
        deploy();
    }

    function setEndOfLife(bool _eol) public {
        require(msg.sender == owner, "Go home loser");
        eol = _eol;
    }

    function redeploy() external override {
        require(msg.sender == pyramid, "Go home loser");
        if(eol){
            selfdestruct(treasurer);
        } else
            deploy();
    }

    function deploy() private {
        RichBitchCoin p = new RichBitchCoin(treasurer);
        pyramid = address(p);
        emit LogCreatedPyramid(pyramid);
    }
}
