//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/ICudlStaker.sol";
import "./interfaces/ICudlFinance.sol";
import "./interfaces/IToken.sol";

contract BazaarV1 {
    IToken public milk;
    ICudlFinance public game;
    IToken public token;

    // 1 hibernate / 2 set name / 3 litter /4 milker

    mapping(uint256 => string) public name;
    mapping(uint256 => bool) public isMilker;

    event BazaarItem(uint256 item, uint256 nftId);

    constructor() {
        milk = IToken(0x65A13209467b81dA63866FA0D1D287FB57F611d2);
        game = ICudlFinance(0x048117BBdD9148FBb6a97385533982184dA5067D);
        token = IToken(0x0f4676178b5c53Ae0a655f1B19A96387E4b8B5f2);
    }

    function hibernate(uint256 nftId) public {
        require(game.isPetOwner(nftId, msg.sender));
        milk.burnFrom(msg.sender, 100 ether); //TODO amount before deployment
        emit BazaarItem(1, nftId);
        game.addTOD(nftId, 30 days);
    }

    function setName(uint256 nftId, string memory _name) public {
        require(game.isPetOwner(nftId, msg.sender));

        milk.burnFrom(msg.sender, 1 ether); //TODO amount before deployment
        name[nftId] = _name;
        emit BazaarItem(2, nftId);
    }

    function litter(uint256 nftId) public {
        require(game.isPetOwner(nftId, msg.sender));

        milk.burnFrom(msg.sender, 10 ether); //TODO set amount before deployment

        // add 100 sore
        game.addScore(nftId, 100);
        emit BazaarItem(3, nftId);
    }

    function getMilkerAchievement(uint256 nftId) public {
        require(game.isPetOwner(nftId, msg.sender));
        milk.burnFrom(msg.sender, 100 ether); //TODO set amount before deployment
        token.burnFrom(msg.sender, 10 ether); //TODO set amount before deployment
        isMilker[nftId] = true;
        emit BazaarItem(4, nftId);
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ICudlStaker {
    function balanceByPool(uint256 pool, address user)
        external
        view
        returns (uint256);

    function earned(address account) external view returns (uint256);

    function burnPoints(address _user, uint256 amount) external;
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ICudlFinance {
    function burnScore(uint256 nftId, uint256 amount) external;

    function addScore(uint256 nftId, uint256 amount) external;

    function addTOD(uint256 nftId, uint256 duration) external;

    function isPetOwner(uint256 petId, address user)
        external
        view
        returns (bool);

    function timeUntilStarving(uint256 _nftId) external view returns (uint256);

    function timePetBorn(uint256 token) external view returns (uint256);

    function nftToId(address nft, uint256 token)
        external
        view
        returns (uint256);

    function getPetInfo(uint256 _nftId)
        external
        view
        returns (
            uint256 _pet,
            bool _isStarving,
            uint256 _score,
            uint256 _level,
            uint256 _expectedReward,
            uint256 _timeUntilStarving,
            uint256 _lastTimeMined,
            uint256 _timepetBorn,
            address _owner,
            address _token,
            uint256 _tokenId,
            bool _isAlive
        );
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}