// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./Context.sol";
import "./IExp.sol";

contract fatigue is Ownable,Context {

    constructor() {
        updateAdminAddress(_msgSender(), true);
    }

    mapping(address => bool) public adminAddress;

    modifier onlyOwnerOrAdminAddress() {
        require(adminAddress[_msgSender()], "permission denied");
        _;
    }

    function updateAdminAddress(address newAddress, bool flag)
        public
        onlyOwner
    {
        require(
            adminAddress[newAddress] != flag,
            "The adminAddress already has that address"
        );
        adminAddress[newAddress] = flag;
    }

    uint256 public maxFatiguePerDay = 3;
    uint256 public fatigueRefreshRange = 24 * 60 * 60;
    uint256 public baseTime = 1640822400;

    function refreshTime() public {
        uint256 day = (block.timestamp - baseTime)/fatigueRefreshRange;
        require(day > 0,"the refresh time has already updated!");
        baseTime += day * fatigueRefreshRange;
        
    }

    function setBaseTime(uint256 _newTime) public onlyOwner {
        baseTime = _newTime;
    }

    mapping(uint256=>uint32) public lenMap;

    IExp public expContract;

    function setExpContract(IExp _addr) public onlyOwner {
        expContract = _addr;
    }

    function addExp(uint256 nftId, uint128 ex) public onlyOwnerOrAdminAddress {
        trySaveLog(nftId);
        expContract.addExp(nftId, ex);
    }

    function setFatigueRefreshRange(uint256 _newRange) public onlyOwner {
        fatigueRefreshRange = _newRange;
    }

    function setMaxFatiguePerDay(uint256 _maxFatiguePerDay) public onlyOwner {
        maxFatiguePerDay = _maxFatiguePerDay;
    }

    mapping(uint256 => uint256[]) nftChallengeLog;

    function trySaveLog(uint256 tokenId) public onlyOwnerOrAdminAddress {
        require(
            checkLogInTimeRange(tokenId, fatigueRefreshRange) <
                maxFatiguePerDay,
            "reach max Fatigue limit!"
        );
        nftChallengeLog[tokenId].push(block.timestamp);
        lenMap[tokenId]++;

    }

    function checkLogInTimeRange(uint256 tokenId, uint256 timeRange)
        public
        view
        returns (uint256)
    {
        uint256 min = baseTime;
        uint256 result = 0;
        uint32 len = lenMap[tokenId] - 0;
        if (len == 0) return result;
        for (uint32 i = len; i > 0;i--) {
            if (nftChallengeLog[tokenId][i-1] >= min) {
                result++;
            } else {
                return result;
            }
        }
        return result;
    }

    function getNftLogs(uint256 tokenId)
        public
        view
        returns (uint256[] memory result)
    {
        uint32 len = lenMap[tokenId] - 0;
        result = new uint256[](len);
        for (uint32 i = 0; i < len; i++) {
            result[i] = nftChallengeLog[tokenId][i];
        }
        return result;
    }

    function bulkGetFatigueByTokenIds(uint256[] calldata _tokenIds,uint256 _timeRange) public view returns(uint256[] memory) {
        uint256 len = _tokenIds.length;
        uint256[] memory result = new uint256[](len);
        for(uint256 i = 0; i < len; i++) {
            result[i] = checkLogInTimeRange(_tokenIds[i],_timeRange);
        }
        return result;
    }
}