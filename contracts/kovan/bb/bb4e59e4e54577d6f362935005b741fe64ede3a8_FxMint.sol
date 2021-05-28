/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity 0.6.6;

interface IFunctionX {
    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

contract FxMint {
    address public FxUsd;

    constructor() public {
        
    }
    
    function mint(address _receive, uint256 _amount) public {
        IFunctionX(FxUsd).issue(_receive, _amount);
    }
    
    function updateFxUsd(address _fxUsdAddress) public {
        FxUsd = _fxUsdAddress;
    }
}