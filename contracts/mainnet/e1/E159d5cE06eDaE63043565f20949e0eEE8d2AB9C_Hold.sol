/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity ^0.6.6;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}


contract Hold{

    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;
    
    constructor () public {
        controller = msg.sender;
    }

    function changeController(address _newController) public onlyController {
        controller = _newController;
    }


    function proxy(address token, address recipient,uint amount) public onlyController returns(bool) {
        IERC20 TOKEN = IERC20(token);
        bool succ = TOKEN.transfer(recipient, amount);
        require(succ);
        return true;
    }
}