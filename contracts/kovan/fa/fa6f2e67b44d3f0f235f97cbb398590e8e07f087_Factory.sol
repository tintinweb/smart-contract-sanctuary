pragma solidity ^0.6.12;

import './IERC20.sol';

contract Factory{
    
    address owner;
    IERC20 daitoken;
    
    constructor() public{
        owner = msg.sender;
        daitoken = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
    }
    
    function transferDaiToContract(address _owner, address _token, uint _amount) public {
        require(IERC20(_token) == daitoken);
        IERC20(_token).transferFrom(_owner, address(this), _amount);
    }
    
    function getBalanceOfDai() public view returns (uint) {
        return daitoken.balanceOf(address(this));
    }

    
}