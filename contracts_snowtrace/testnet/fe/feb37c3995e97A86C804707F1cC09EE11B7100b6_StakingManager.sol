/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
    
contract StakingManager {
    // users staking info
    struct tokenStaked {
        uint tokenId;
        uint lastStaked;
        uint nextStaked;
    }
    mapping (address => mapping(uint => tokenStaked)) public tokensStaked; // mapping of all tokens staked per addresses
    mapping (uint => uint) private tokenIdIndex; // index for all token Id
    mapping (address => uint) public tokensStakedByAddress; // number of tokens staked per addresses
    mapping (address => uint) public totalTokensStakedByAddress; // total number of tokens staked per addresses
    mapping (address => uint) private firstStakedId; // the unique id of the first token staked per addresses
    mapping (address => uint) private lastStakedId; // the unique id of the last token staked per addresses

    address public owner;
    address public quest;
    
    constructor () {
        owner == msg.sender;
    }

    function setQuest(address _quest) external {
        quest = _quest;
    }

    function _addToStaked(address _user, uint _tokenId) external {
        require(msg.sender == quest);

        tokensStaked[_user][totalTokensStakedByAddress[_user]] = tokenStaked(_tokenId, lastStakedId[_user], 0);

        tokensStaked[_user][lastStakedId[_user]].nextStaked = totalTokensStakedByAddress[_user];
        lastStakedId[_user] = totalTokensStakedByAddress[_user];
        tokenIdIndex[_tokenId] = totalTokensStakedByAddress[_user];
        tokensStakedByAddress[_user] += 1;
        totalTokensStakedByAddress[_user] += 1;
    }

    function _removeFromStaked(address _user, uint _tokenId) external {
        require(msg.sender == quest);

        // reboot staked tree without this staked
        if (tokenIdIndex[_tokenId] == firstStakedId[_user]) {
            // remove the first staked and make the second to first staked, the first staked
            uint _nextStakedId = tokensStaked[_user][tokenIdIndex[_tokenId]].nextStaked;

            tokensStaked[_user][_nextStakedId].lastStaked = 0;
            firstStakedId[_user] = _nextStakedId;
        } else if (tokenIdIndex[_tokenId] == lastStakedId[_user]) {
            // remove the last staked and make the second to last staked, the last staked
            uint _lastStakedId = tokensStaked[_user][tokenIdIndex[_tokenId]].lastStaked;

            tokensStaked[_user][_lastStakedId].nextStaked = 0;
            lastStakedId[_user] = _lastStakedId;
        } else {
            // just connect the last staked to the next staked without the removed staked id
            tokensStaked[_user][tokensStaked[_user][tokenIdIndex[_tokenId]].lastStaked].nextStaked = tokensStaked[_user][tokenIdIndex[_tokenId]].nextStaked;
            tokensStaked[_user][tokensStaked[_user][tokenIdIndex[_tokenId]].nextStaked].lastStaked = tokensStaked[_user][tokenIdIndex[_tokenId]].lastStaked;
        }
        tokensStakedByAddress[_user] -= 1;
        tokenIdIndex[_tokenId] = 0;
    }

    function getTokensStakedByAddress(address _user) external view returns (uint[] memory) {
        uint[] memory _tokensStaked = new uint[](tokensStakedByAddress[_user]);
        uint nextId = firstStakedId[msg.sender];

        for (uint i=0; i < tokensStakedByAddress[_user]; i++) {
            _tokensStaked[i] = tokensStaked[msg.sender][nextId].tokenId;
            nextId = tokensStaked[msg.sender][nextId].nextStaked;
        }

        return _tokensStaked;
    }
}