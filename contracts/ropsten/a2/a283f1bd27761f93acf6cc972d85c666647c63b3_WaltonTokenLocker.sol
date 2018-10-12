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

    address public smnAddress;
    uint256 public releaseTimestamp;
    string public name;
    address public wtcFundation;

    Token public token = Token(&#39;0x554622209Ee05E8871dbE1Ac94d21d30B61013c2&#39;);

    function WaltonTokenLocker(string _name, address _token, address _beneficiary, uint256 _releaseTime) public {
        // smn account
        wtcFundation = msg.sender;
        name = _name;
        token = Token(_token);
        smnAddress = _beneficiary;
        releaseTimestamp = _releaseTime;
    }

    // when releaseTimestamp reached, and release() has been called
    // WaltonTokenLocker release all wtc to smnAddress
    function release() public {
        if (block.timestamp < releaseTimestamp)
            throw;

        uint256 totalTokenBalance = token.balanceOf(this);
        if (totalTokenBalance > 0)
            if (!token.transfer(smnAddress, totalTokenBalance))
                throw;
    }


    // help functions
    function releaseTimestamp() public constant returns (uint timestamp) {
        return releaseTimestamp;
    }

    function currentTimestamp() public constant returns (uint timestamp) {
        return block.timestamp;
    }

    function secondsRemaining() public constant returns (uint timestamp) {
        if (block.timestamp < releaseTimestamp)
            return releaseTimestamp - block.timestamp;
        else
            return 0;
    }

    function tokenLocked() public constant returns (uint amount) {
        return token.balanceOf(this);
    }

    // release for safe, will never be called in normal condition
    function safeRelease() public {
        if (msg.sender != wtcFundation)
            throw;

        uint256 totalTokenBalance = token.balanceOf(this);
        if (totalTokenBalance > 0)
            if (!token.transfer(wtcFundation, totalTokenBalance))
                throw;
    }

    // functions for debug
    //function setReleaseTime(uint256 _releaseTime) public {
    //    releaseTimestamp = _releaseTime;
    //}
}