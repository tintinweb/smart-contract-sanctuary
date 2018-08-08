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
    string constant public name = "team locker v2";

    Token public token = Token(&#39;0xb7cB1C96dB6B22b0D3d9536E0108d062BD488F74&#39;);

    function WaltonTokenLocker() public {
        // team account
        beneficiary = address(&#39;0x732f589BA0b134DC35454716c4C87A06C890445b&#39;);
        releaseTime = 1563379200;     // 2019-07-18 00:00
    }

    // when releaseTime reached, and release() has been called
    // WaltonTokenLocker release all eth and wtc to beneficiary
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