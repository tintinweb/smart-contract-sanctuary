// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC20.sol";

abstract contract Faucet{
    function getTokens() public virtual;
}

abstract contract Home{
    function registerAsStudent(string memory name) public virtual;
}

contract HW2{
    IERC20  token_contract;
    address token_faucet;
    address token_home;
    address owner;

    constructor(IERC20  _token_contract, address _token_faucet, address _token_home){
        token_contract = _token_contract;
        token_faucet = _token_faucet;
        token_home = _token_home;
        owner = msg.sender;
    }

    function faucet() public{
        Faucet _faucet = Faucet(token_faucet);   
        _faucet.getTokens();
    }

    function approve() public{
        uint256 balance = token_contract.balanceOf(address(this));
        token_contract.approve(token_home, balance);
    }

    function refund() public{
        uint256 balance = token_contract.balanceOf(address(this));
        token_contract.transfer(address(token_contract), balance);
    }

    function balanceOf() public view returns(uint256){
        return token_contract.balanceOf(address(this));
    }

    function balanceContract() public view returns(uint256){
        return token_contract.balanceOf(address(token_contract));
    }

    function allowance() public{
        uint256 balance = token_contract.allowance(address(this), token_home);
        token_contract.approve(address(this), balance);
    }

    function registerAsStudent(string memory name) public{
        require(bytes(name).length>0, "Name too small!!!");
        Home _home = Home(token_home);   
        _home.registerAsStudent(name);
    }    
}