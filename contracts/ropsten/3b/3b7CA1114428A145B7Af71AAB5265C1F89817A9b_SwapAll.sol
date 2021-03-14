/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);
    
    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface Token {
  function balanceOf(address _address) external view returns (uint256);
  function transfer(address _to, uint256 _value) external;
}

contract SwapAll is Ownable {
    
    event Airdrop(address _token, uint256 _total);
    event AirdropEth(uint256 _total);
    
    constructor () payable {}
    
    fallback() external payable {}
    
    receive() external payable {}

    function transferErc20(address _token, address[] calldata _dsts, uint256[] calldata _values) public onlyOwner {
        require(_dsts.length == _values.length);
        Token token = Token(_token);
        uint256 total = 0;
        for (uint256 i = 0; i < _dsts.length; i++) {
            token.transfer(_dsts[i], _values[i]);
            total += _values[i];
        }
        emit Airdrop(_token, total);
    }
    
    function balanceOfErc20(address _token) public view returns (uint256){
        Token token = Token(_token);
        return token.balanceOf(address(this));
    }
    
    function transferEth(address payable[] calldata _dsts, uint256[] calldata _values) public onlyOwner {
        require(_dsts.length == _values.length);
        uint256 total = 0;
        for (uint256 i = 0; i < _dsts.length; i++) {
            _dsts[i].transfer(_values[i]);
            total += _values[i];
        }
        emit AirdropEth(total);
    }
    
    function balance() public view returns (uint256){
        return address(this).balance;
    }
}