/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

pragma solidity >=0.5.0;

interface IERC20forsutdy {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Interfacestudy {

    function approvetoken(address token, address spender, uint value) public returns(bool){
        IERC20forsutdy(token).approve(spender,value);
    }

    function transfertoken(address token, address to, uint amount) public returns(bool){
        IERC20forsutdy(token).transfer(to,amount);
    }

    function transferfromtoken(address token, address from, address to, uint amount) public returns(bool){
        IERC20forsutdy(token).transferFrom(from, to,amount);
    }

    function getbalanceOf(address token, address owner) public view returns(uint){
        IERC20forsutdy(token).balanceOf(owner);
    }

    function getallowance(address token, address owner, address spender) public view returns(uint){
        IERC20forsutdy(token).allowance(owner,spender);
    }

    function getdecimals(address token) public view returns(uint){
        IERC20forsutdy(token).decimals();
    }
}