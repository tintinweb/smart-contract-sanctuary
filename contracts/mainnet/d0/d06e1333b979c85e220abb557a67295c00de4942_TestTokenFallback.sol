pragma solidity ^0.4.18;

import "./Ownable.sol";

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TestTokenFallback is Ownable {
    bool public requireFlag = true;
    bool public successFlag = true;

    event LogTokenFallback(address indexed msgSender, address indexed from, uint256 amount, bytes data);
    event LogReceiveApproval(address indexed msgSender, uint256 amount, address indexed token, bytes data);

    function setRequireFlag(bool _requireFlag) public onlyOwner {
        requireFlag = _requireFlag;
    }

    function setSuccessFlag(bool _successFlag) public onlyOwner {
        successFlag = _successFlag;
    }

    function tokenFallback(address from, uint256 amount, bytes data) public returns (bool success) {
        // ERC20Interface(token).transferFrom(from, address(this), tokens);
        require(requireFlag);
        LogTokenFallback(msg.sender, from, amount, data);
        return successFlag;
    }

    function receiveApproval(address from, uint256 amount, address token, bytes data) public {
        require(requireFlag);
        ERC20Interface(token).transferFrom(from, address(this), amount);
        LogReceiveApproval(msg.sender, amount, token, data);
    }
}