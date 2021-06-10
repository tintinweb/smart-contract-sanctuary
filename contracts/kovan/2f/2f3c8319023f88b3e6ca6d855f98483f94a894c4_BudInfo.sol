/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.5.16;

contract ChainlinkLike {
    function latestAnswer() external view returns(int);
}

contract BudConnectorLike {
    function read(bytes32 ilk) external view returns (bytes32);
}


contract BChainlinkInfo {
    address constant ADMIN = 0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4;
    address constant POOL_ADMIN = 0x7Ba651De9B7186F6F9665cf5Cc0f19e491dB3538;
    mapping(bytes32 => address) public chainlink;
   
    function setChainlink(bytes32 ilk, address c) external {
        if(chainlink[ilk] == address(0)) require(msg.sender == ADMIN, "!admin");
        else require(msg.sender == POOL_ADMIN, "!poolAdmin");
        
        chainlink[ilk] = c;
    }
   
    function latestAnswer(bytes32 ilk) external view returns(int) {
        return ChainlinkLike(chainlink[ilk]).latestAnswer();
    }
}

contract BudInfo {
    address constant ADMIN = 0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4;
    address constant POOL_ADMIN = 0x7Ba651De9B7186F6F9665cf5Cc0f19e491dB3538;
    BudConnectorLike BUD_CONNECTOR = BudConnectorLike(0x2325aa20DEAa9770a978f1dc7C073589ffC79DC3);
   
    mapping(address => bool) public auth;

    function authorize(address c) external {
        require(msg.sender == ADMIN, "!admin");
        auth[c] = true;
    }
    
    function deauthorize(address c) external {
        require(msg.sender == POOL_ADMIN, "!poolAdmin");
        auth[c] = false;
    }

    function latestAnswer(bytes32 ilk) external view returns(int) {
        require(auth[msg.sender], "!auth");
        return int(uint(BUD_CONNECTOR.read(ilk)));
    }
}