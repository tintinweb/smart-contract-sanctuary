/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
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

library SafeMath {

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        return x / y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

}

contract Ownable {
  address public owner;
 
  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract Airdropper is Ownable {
    uint public eth;

    constructor() {
        eth=0;
    }

    function ERC20AirTransfer(address[] calldata _recipients, uint[] calldata _values, address _tokenAddress) onlyOwner public returns (bool) {
        require(_recipients.length > 0 && _recipients.length==_values.length);

        for(uint i = 0; i < _recipients.length; i++){
            require(IERC20(_tokenAddress).allowance(msg.sender, address(this))>=_values[i]);
            IERC20(_tokenAddress).transferFrom(owner, _recipients[i], _values[i]);
        }
 
        return true;
    }

    function ETHAirTransfer(address[] calldata _recipients, uint[] calldata _values) onlyOwner public returns (bool) {
        require(_recipients.length > 0 && _recipients.length==_values.length);

        for(uint i = 0; i < _recipients.length; i++){
            require(eth>=_values[i], "ETH is not sufficient");
            payable(_recipients[i]).transfer(_values[i]);
            eth = eth - _values[i];
        }

        return true;
    }

    receive() external payable {
        //eth.add(msg.value);
        eth = eth + msg.value;
    }

    function withdraw() onlyOwner public {
        payable(msg.sender).transfer(eth);
    }

}