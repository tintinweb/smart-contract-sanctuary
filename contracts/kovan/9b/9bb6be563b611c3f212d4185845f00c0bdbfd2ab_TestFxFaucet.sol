/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

pragma solidity 0.6.6;

interface IFunctionX {
    function transfer(address to, uint256 value) external;
    function balanceOf(address who) external view returns (uint256);
}

contract TestFxFaucet {
    address public Fx;

    constructor() public {
    }

    function mint(address _receive) public {
        require(IFunctionX(Fx).balanceOf(address(this)) > 100e18, 'FxFaucet insufficient balance');
        IFunctionX(Fx).transfer(_receive, 100e18);
    }

    function updateFx(address _fxAddress) public {
        Fx = _fxAddress;
    }

    function getBalance() public view returns(uint256){
        return  IFunctionX(Fx).balanceOf(address(this));
    }
}