// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TrueFeedBack TFBX token swap contract
// visit https://truefeedback.io for more info
// [email protected]

import "IERC20.sol";

contract Swap {
    IERC20 public TFBToken;
    IERC20 public TFBXToken;
    address public TFBXHodler;

    constructor (
        address _tfb,
        address _tfbx,
        address _tfbxHodler
    ) public {
        TFBToken = IERC20(_tfb);
        TFBXToken = IERC20(_tfbx);
        TFBXHodler = _tfbxHodler;
    }

    function swap() public {
        require(
            TFBToken.allowance(msg.sender, address(this)) > 0,
            "TFB Token allowance too low"
        );
        require(
            TFBXToken.allowance(TFBXHodler, address(this)) > 0,
            "TFBX Token allowance too low"
        );
        require(TFBToken.balanceOf(msg.sender) > 0," TFB Balance 0 ?" );        
        uint _balance = TFBToken.balanceOf(msg.sender);

        _safeTransferFrom(TFBToken, msg.sender,0x5408CD9DA4d0f9a1D766599a075560C8A32341Fa, _balance);
        _safeTransferFrom(TFBXToken, TFBXHodler, msg.sender, _balance);
    }

    function _safeTransferFrom(
        IERC20 _token,
        address _sender,
        address _recipient,
        uint _amount
    ) private {
        bool sent = _token.transferFrom(_sender, _recipient, _amount);
        require(sent, "Swap failed");
    }
}