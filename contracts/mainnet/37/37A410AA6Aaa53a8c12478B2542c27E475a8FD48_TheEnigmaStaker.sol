// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";

contract TheEnigmaStaker is ERC721 {

    modifier stakingStarted() {
        require(
            startStakeDate != 0 && startStakeDate <= block.timestamp,
            "You are too early"
        );

        _;
    }

    uint256 private startStakeDate = 1638389498;

    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public minersAddress;

    //Mapping of enigma to timestamp
    mapping(uint256 => uint256) public tokenIdToTimeStamp;

    //Mapping of enigma to staker
    mapping(uint256 => address) public tokenIdToStaker;

    //Mapping of staker to enigma
    mapping(address => uint256[]) public stakerToTokenIds;

    // Mapping of address to its tokens with number of seconds for each token
    mapping(address => mapping(uint256 => uint256)) public totalStakingTimeByTokenForAddress;

    uint256 public totalTokensStaked = 0;

    constructor() ERC721("TheEnigmaStaker", "ENGST") {}

    fallback() external payable { }

    receive() external payable { }

    function setEnigmaContractAddress(address _minersAddress) external onlyOwner {
        minersAddress = _minersAddress;
        return;
    }

    /**
     * @dev Sets the date that users can start staking and unstaking
     */
    function setStartStakeDate(uint256 _startStakeDate)
        external
        onlyOwner
    {
        startStakeDate = _startStakeDate;
    }

    function getTokensStaked(address staker)
        external
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) external stakingStarted {

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(minersAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721(minersAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;

            totalTokensStaked += 1;
        }
    }

    function unstakeAll() external stakingStarted {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least one token staked!"
        );

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            IERC721(minersAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            
            totalStakingTimeByTokenForAddress[msg.sender][tokenId] += ((block.timestamp - tokenIdToTimeStamp[tokenId]));

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = nullAddress;

            totalTokensStaked = totalTokensStaked - 1;
        }
    }

    function unstakeByIds(uint256[] memory tokenIds) external stakingStarted {

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(minersAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalStakingTimeByTokenForAddress[msg.sender][tokenIds[i]] += ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]));

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = nullAddress;

            totalTokensStaked = totalTokensStaked - 1;
        }
    }

    function unstakeByIdByOwner(uint256 tokenId, address addr) external stakingStarted onlyOwner {

        require(
            tokenIdToStaker[tokenId] == addr,
            "Staker address is not valid!"
        );

        IERC721(minersAddress).transferFrom(
            address(this),
            addr,
            tokenId
        );

        totalStakingTimeByTokenForAddress[addr][tokenId] += ((block.timestamp - tokenIdToTimeStamp[tokenId]));

        removeTokenIdFromStaker(addr, tokenId);

        tokenIdToStaker[tokenId] = nullAddress;

        totalTokensStaked = totalTokensStaked - 1;
    }

    function getSecondsStakedByTokenId(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        require(
            tokenIdToStaker[tokenId] != nullAddress,
            "Token is not staked!"
        );

        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[tokenId];

        return secondsStaked;
    }

    function getStaker(uint256 tokenId) external view returns (address) {
        return tokenIdToStaker[tokenId];
    }
}