/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity =0.8.10;

contract BRPNTokenLock {

    uint256 totalLockedTokens = 0;
    mapping (address => uint256) private lockedTokensAmount;
    mapping(address => mapping(uint => LockedData)) public lockedTokens;
    Token private token = Token(address(0xc20b579F8db516ebfECb4746072D05BD30F8C22B));

    event LockedTokens(address locker, uint256 amountOfTokens, uint256 expiresAt);
    event WithdrawnTokens(address locker, uint256 amountOfTokens);

    function lockTokens(uint256 amountOfTokens, uint256 duration) public returns(bool, LockedData memory) {
        require(amountOfTokens > 0, "You cannot lock less then 1 token.");
        require(duration > 0, "You cannot lock lock your tokens for less then 1 ms");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amountOfTokens, "Allowance to low.");

        lockedTokensAmount[msg.sender] += 1;

        LockedData memory lockedData;
        lockedData.initialized = true;
        lockedData.lockedId = lockedTokensAmount[msg.sender];
        lockedData.withdrawableAt = block.timestamp + duration;
        lockedData.amountOfTokens = amountOfTokens;
        lockedData.withdrawn = false;

        token.transferFrom(msg.sender, address(this), amountOfTokens);
        return (true, lockedData);
    }

    function withdrawTokens(uint256 lockedDataID) public returns(bool, LockedData memory) {
        require(lockedTokens[msg.sender][lockedDataID].initialized, "LockedData cannot be found.");
        require(lockedTokens[msg.sender][lockedDataID].withdrawn == false, "You already withdrawn these tokens.");
        require(lockedTokens[msg.sender][lockedDataID].withdrawableAt <= block.timestamp, "You cannot withdraw these locked tokens yet.");

        lockedTokens[msg.sender][lockedDataID].withdrawn = true;
        token.transfer(msg.sender, lockedTokens[msg.sender][lockedDataID].amountOfTokens);

        emit WithdrawnTokens(msg.sender, lockedTokens[msg.sender][lockedDataID].amountOfTokens);
        return (true, lockedTokens[msg.sender][lockedDataID]);
    }

}

struct LockedData {
    bool initialized;
    uint256 lockedId;
    uint256 amountOfTokens;
    uint256 withdrawableAt;
    bool withdrawn;
}

abstract contract Token {
    function totalSupply() public virtual returns (uint);
    function balanceOf(address tokenOwner) public virtual returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}