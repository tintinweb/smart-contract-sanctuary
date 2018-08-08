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
    string constant public name = "refund locker";

    Token public token = Token(&#39;0xb7cB1C96dB6B22b0D3d9536E0108d062BD488F74&#39;);

    function WaltonTokenLocker() public {
        // refund account
        beneficiary = address(&#39;0x38A9e09E14397Fe3A5Fe59dfc1d98D8B8897D610&#39;);
        releaseTime = 1538236800;     // 2018-09-30 00:00
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
    // release token by token contract address
    function releaseToken(address _tokenContractAddress) public {
        if (block.timestamp < releaseTime)
            throw;

        Token _token = Token(_tokenContractAddress);
        uint256 totalTokenBalance = _token.balanceOf(this);
        if (totalTokenBalance > 0)
            if (!_token.transfer(beneficiary, totalTokenBalance))
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