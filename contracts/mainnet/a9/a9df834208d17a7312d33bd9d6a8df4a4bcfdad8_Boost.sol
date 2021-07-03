// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./Context.sol";
import "./IERC1155.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

interface ISTAKE {
  function manualUpdate(address account) external;
}

contract Boost is Context, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public BoostNFTID;
    IERC1155 private NFT;
    ISTAKE private LOOTFARM;
    ISTAKE private LPFARM;

    mapping(address => bool) private staked;

    constructor (uint256 _id, address _nft, address lootfarm, address lpfarm) {
        BoostNFTID = _id;
        NFT = IERC1155(_nft);
        LOOTFARM = ISTAKE(lootfarm);
        LPFARM = ISTAKE(lpfarm);
    }

    function stake() public nonReentrant {
        require(staked[_msgSender()] == false, "Already staked NFT");
        LOOTFARM.manualUpdate(_msgSender());
        LOOTFARM.manualUpdate(_msgSender());
        staked[_msgSender()] = true;
        NFT.safeTransferFrom(_msgSender(), address(this), BoostNFTID, 1, "");
    }

    function unstake() public nonReentrant {
        require(staked[_msgSender()] == true, "No staked NFT");
        LOOTFARM.manualUpdate(_msgSender());
        LPFARM.manualUpdate(_msgSender());
        staked[_msgSender()] = false;
        NFT.safeTransferFrom(address(this), _msgSender(), BoostNFTID, 1, "");
    }

    function hasBoost(address account) public view returns (bool) {
        return staked[account];
    }
}