// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ScarceToken.sol";

contract Distributor is Context, Ownable {
        using SafeMath for uint256;
        ScarceToken public src;

        // Tracker for one time setting of Token contract.
        bool public SrcInit;

        event SetSrcAddress(address indexed user, ScarceToken indexed _srcAddress);

        constructor (
            ScarceToken _src
        ) public {
        src = _src;
        }

        receive () external payable {}

        function Distribute (address to, uint256 amount) public onlyOwner {
            bool transferSuccess = false;
            transferSuccess = src.transfer (to, amount);
            require(transferSuccess, "safeSrcDistribute: transfer failed.");
            
        }

        // Update Token address.
        function setSrcAddress(ScarceToken _srcaddr) public onlyOwner {
        require (SrcInit == false,"Already initialized!");
            src = _srcaddr;
            SrcInit = true;
            emit SetSrcAddress(msg.sender, _srcaddr);
    }

        

}