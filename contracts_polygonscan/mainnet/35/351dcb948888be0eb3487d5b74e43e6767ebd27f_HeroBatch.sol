/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHeroNFT {
    function ownerOf(uint256 tokenId) external view returns (address);

    function approve(address, uint256) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IMonster {
    function fightVitality(uint256 _tokenId) external view returns (uint256);

    function tokenInfo(uint256[] calldata _tokenIds)
        external
        view
        returns (
            uint256[] calldata vitalities,
            uint256[] calldata lastFightTime
        );

    function fight(uint256 _monsterId, uint256 _tokenId) external view;

    function fightAll(uint256 _monsterId, uint256 _tokenId) external view;
}

contract HeroBatch {
    IMonster _monster;
    IHeroNFT _hero;

    constructor(address _heroNFTAddress, address _monsterAddress) {
        _hero = IHeroNFT(_heroNFTAddress);
        _monster = IMonster(_monsterAddress);
    }

    function batch_fight(uint256 _monsterId, uint256[] calldata _tokenIds)
        external
        view
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_monster.fightVitality(_tokenIds[i]) > 0) {
                _monster.fightAll(_monsterId, _tokenIds[i]);
            }
        }
    }

    function batch_transfer(address _to, uint256[] calldata _tokenIds)
        external
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_hero.ownerOf(_tokenIds[i]) == msg.sender) {
                _hero.transferFrom(msg.sender, _to, _tokenIds[i]);
            }
        }
    }

    function approve_all(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _hero.approve(address(this), _tokenIds[i]);
        }
    }

    function approve_all_not_approved(uint256[] calldata _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (!is_approved(_tokenIds[i])) {
                _hero.approve(address(this), _tokenIds[i]);
            }
        }
    }

    function is_approved(uint256 _tokenId) public view returns (bool) {
        return (_hero.getApproved(_tokenId) == address(this));
    }

    function is_all_approved(uint256[] calldata _tokenIds)
        external
        view
        returns (bool[] memory _is_approved)
    {
        _is_approved = new bool[](_tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _is_approved[i] = _hero.getApproved(_tokenIds[i]) == address(this);
        }
    }

    function is_approved_for_all(uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _hero.isApprovedForAll(_hero.ownerOf(_tokenId), address(this));
    }
}