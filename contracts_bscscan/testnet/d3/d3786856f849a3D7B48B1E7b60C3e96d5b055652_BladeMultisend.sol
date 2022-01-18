/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
// BladeMultiSender
// Version 1.0
// testing on bsc testnet.

pragma solidity >=0.8.0 <0.9.0;


interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}



library SafeMath {
    function mul(uint a, uint b) internal pure returns(uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns(uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    function max64(uint64 a, uint64 b) internal pure returns(uint64) {
        return a >= b ? a: b;
    }
    function min64(uint64 a, uint64 b) internal pure returns(uint64) {
        return a < b ? a: b;
    }
    function max256(uint256 a, uint256 b) internal pure returns(uint256) {
        return a >= b ? a: b;
    }
    function min256(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a: b;
    }
}


contract BladeMultisend {
    using SafeMath for uint;

    event LogTokenBulkSentETH(address from, uint256 total);
	event LogTokenBulkSent(address token, address from, uint256 total);
    event LogTokenApproval(address token, uint256 total);

 

    function ethSendSameValue(address[] memory _to, uint256 _value) external payable {
        
        uint256 sendAmount = _to.length.mul(_value);
        uint256 remainingValue = msg.value;
	    address from = msg.sender;

	    require(remainingValue >= sendAmount, 'insuf balance');
        require(_to.length <= 255, 'exceed max allowed');

        for (uint256 i = 0; i < _to.length; i++) {
            require(payable(_to[i]).send(_value), 'failed to send');
        }

        emit LogTokenBulkSentETH(from, remainingValue);
    }

    function ethSendDifferentValue(address[] memory _to, uint[256] memory _value) external payable {
        
        uint sendAmount = _value[0];
        uint remainingValue = msg.value;
	    address from = msg.sender;
    
	    require(remainingValue >= sendAmount, 'insuf balance');
        require(_to.length == _value.length, 'invalid input');
        require(_to.length <= 255, 'exceed max allowed');
        

        for (uint256 i = 0; i < _to.length; i++) {
            require(payable(_to[i]).send(_value[i]));
        }
        emit LogTokenBulkSentETH(from, remainingValue);
        

    }

    function sendSameValue(address _tokenAddress, address[] memory _to, uint256 _value) external {
       
        address from = msg.sender;
        require(_to.length <= 255, 'exceed max allowed');
        uint256 sendAmount = _to.length.mul(_value);
        IERC20 token = IERC20(_tokenAddress);
         
        token.approve(address(this), sendAmount); //aprove token before sending it

        for (uint256 i = 0; i < _to.length; i++) {
            token.transferFrom(from, _to[i], _value);
        }
		emit LogTokenBulkSent(_tokenAddress, from, sendAmount);

    }

    function sendDifferentValue(address _tokenAddress, address[] memory _to, uint[256] memory _value) external {
	    
        address from = msg.sender;
        require(_to.length == _value.length, 'invalid input');
        require(_to.length <= 255, 'exceed max allowed');
        uint256 sendAmount;
        IERC20 token = IERC20(_tokenAddress);

        token.approve(address(this), sendAmount); //aprove token before sending it
    
        for (uint256 i = 0; i < _to.length; i++) {
            token.transferFrom(msg.sender, _to[i], _value[i]);
	        sendAmount.add(_value[i]);
        }
        emit LogTokenBulkSent(_tokenAddress, from, sendAmount);

    }

       function ApproveERC20Token (address _tokenAddress, uint256 _value) external  {
    
        IERC20 token = IERC20(_tokenAddress);
        token.approve(address(this), _value); //Approval of spacific amount or more, this will be an idependent approval
        
        emit LogTokenApproval(_tokenAddress, _value);
    }
    
}