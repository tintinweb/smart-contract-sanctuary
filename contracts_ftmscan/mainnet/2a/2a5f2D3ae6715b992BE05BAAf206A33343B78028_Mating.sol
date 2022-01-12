// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";

interface ISnakeskin {
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

interface ISassySnakes {
    function ownerOf(uint256 tokenId) external view returns (address);
    function snakeSize(uint256 tokenId) external view returns (uint256);
    function snakeRarity(uint256 tokenId) external view returns (uint256);
}

interface ISnakeEggs {
    function mintEgg(address recipient, uint256 numEggs) external;
}

contract Mating is Ownable, Pausable {

    address public SS_ERC721;
    address public SS_EGGS_ERC721;
    address public SKIN_ERC20;
    uint256 public skinCost;

    mapping(uint256 => bool) public hasMated;
    bool public isPaused = false;
    uint256 public numberMated;

    constructor(
        address _ssErc721,
        address _ssEggsErc721,
        address _skinErc20,
        uint256 _skinCost
    ) {
        SS_ERC721 = _ssErc721;
        SS_EGGS_ERC721 = _ssEggsErc721;
        SKIN_ERC20 = _skinErc20;
        skinCost = _skinCost;
    }

    function mate(uint256 snake1, uint256 snake2) public whenNotPaused {
        require (ISassySnakes(SS_ERC721).snakeSize(snake1) >= 4 && ISassySnakes(SS_ERC721).snakeSize(snake2) >= 4, "Both snakes must be at least size 4");
        require (!(hasMated[snake1]) && !(hasMated[snake2]), "Both snakes must have not mated before");
        require (ISassySnakes(SS_ERC721).ownerOf(snake1) == msg.sender && ISassySnakes(SS_ERC721).ownerOf(snake2) == msg.sender , "You must own both the snakes you intend to mate");

        hasMated[snake1] = true;
        hasMated[snake2] = true;

        numberMated += 2;

        // burn must be approved
        ISnakeskin(SKIN_ERC20).burnFrom(msg.sender, skinCost);

        ISnakeEggs(SS_EGGS_ERC721).mintEgg(msg.sender, 1);
    }

    function getMateStatus(uint256[] memory tokenIds) public view returns (bool[] memory) {
        bool[] memory mateStatus = new bool[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {  
            mateStatus[i] = hasMated[tokenIds[i]];
        }

        return mateStatus;
    }


    function alterCost(uint256 cost) public onlyOwner {
        skinCost = cost;
    }


}