pragma solidity ^0.4.11;

// Token abstract definitioin
contract Token {
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);

    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract WaltonTokenLocker {

    address public beneficiary;
    uint256 public releaseTime;
    string public name;
    address public owner;

    Token public token = Token(&#39;0x554622209Ee05E8871dbE1Ac94d21d30B61013c2&#39;);

    function WaltonTokenLocker(string _name, address _token, address _beneficiary, uint256 _releaseTime) public {
        // smn account
        owner = msg.sender;
        name = _name;
        token = Token(_token);
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    // when releaseTime reached, and release() has been called
    // WaltonTokenLocker release all wtc to beneficiary
    function release() public {
        if (block.timestamp < releaseTime)
            throw;

        uint256 totalTokenBalance = token.balanceOf(this);
        if (totalTokenBalance > 0)
            if (!token.transfer(beneficiary, totalTokenBalance))
                throw;
    }


    // help functions
    function releaseTimestamp() public constant returns (uint timestamp) {
        return releaseTime;
    }

    function currentTimestamp() public constant returns (uint timestamp) {
        return block.timestamp;
    }

    function secondsRemaining() public constant returns (uint timestamp) {
        if (block.timestamp < releaseTime)
            return releaseTime - block.timestamp;
        else
            return 0;
    }

    function tokenLocked() public constant returns (uint amount) {
        return token.balanceOf(this);
    }

    // release for safe, will not be called
    function safeRelease() public {
        if (msg.sender != owner)
            throw;

        uint256 totalTokenBalance = token.balanceOf(this);
        if (totalTokenBalance > 0)
            if (!token.transfer(owner, totalTokenBalance))
                throw;
    }

    // functions for debug
    function setReleaseTime(uint256 _releaseTime) public {
        releaseTime = _releaseTime;
    }
}