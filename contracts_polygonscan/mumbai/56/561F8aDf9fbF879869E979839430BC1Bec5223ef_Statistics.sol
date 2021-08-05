// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
import "../utils/ITopPlayers.sol";

contract Statistics {
    uint256 onePromo; //%20
    uint256 twoPromo; //%10
    uint256 threePromo; //%5

    ITopPlayers topPlayers;

    function setTopPlayerAddress(address _topPlayers) external {
        topPlayers = ITopPlayers(_topPlayers);
    }

    function getPlayerPromo(address player) external view returns (uint256) {
        userInfo[3] memory users;

        users = topPlayers.getTopPlayers();

        if (users[0].user == player) {
            return onePromo;
        } else if (users[1].user == player) {
            return twoPromo;
        } else if (users[2].user == player) {
            return threePromo;
        }
        //1 ether neutral element for partition
        return 1;
    }

    /**@notice _setPromo  all parameters should be 1-100 range */
    function setPromo(
        uint256 _onePromo,
        uint256 _twoPromo,
        uint256 _threePromo
    ) external {
        onePromo = _onePromo;
        twoPromo = _twoPromo;
        threePromo = _threePromo;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
struct userInfo {
    address user;
    uint256 totalBetAmount;
}

interface ITopPlayers {
    function getTopPlayers() external view returns (userInfo[3] memory);

    function update(address user, uint256 amount) external;
}