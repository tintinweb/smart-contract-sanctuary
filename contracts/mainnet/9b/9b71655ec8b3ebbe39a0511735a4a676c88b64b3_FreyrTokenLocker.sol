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


contract FreyrTokenLocker {

    address public beneficiary;
    uint256 public releaseTime;
    string constant public name = "freyr team locker";

    Token public token = Token(&#39;0x17e67d1CB4e349B9CA4Bc3e17C7DF2a397A7BB64&#39;);

    function FreyrTokenLocker() public {
        // team account
        beneficiary = address(&#39;0x31F3EcDb1d0450AEc3e5d6d98B6e0e5B322b864a&#39;);
        releaseTime = 1552492800;     // 2019-03-14 00:00
    }

    // when releaseTime reached, and release() has been called
    // FreyrTokenLocker release all eth and wtc to beneficiary
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

    // functions for debug
    // function setReleaseTime(uint256 _releaseTime) public {
    //     releaseTime = _releaseTime;
    // }

}