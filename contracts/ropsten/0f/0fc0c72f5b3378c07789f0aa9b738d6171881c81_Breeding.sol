//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Fewmans.sol";
import "./ERC20PresetFixedSupply.sol";
import "./AccessControl.sol";

contract Breeding is AccessControl {
    Fewmans public immutable fewmans;
    IERC20 public immutable fewgold;
    mapping(uint256 => uint8) public generation;
    mapping(uint256 => uint256) public childOf;
    string constant seed = "We Like Fewmans";
    uint256 public nextFewvulation;
    uint256 public fewvulationDuration;

    // prettier-ignore
    uint8[6][6] internal genProb = [
        [128, 0x0, 0x0,  0x0, 0x0,  0x0],
        [255, 0x0,  32,   32,  32,   32],
        [255, 224, 0x0,   64,  64,   64],
        [255, 224, 192,  0x0, 128,  128],
        [255, 224, 192,  128, 0x0,  128],
        [255, 224, 192,  128, 128,  0x0]
    ];

    uint8[11] internal starsRequired = [0, 1, 2, 3, 4, 5, 6, 6, 7, 8, 8];

    uint256[13] internal prices = [
        0,
        1e18,
        3e18,
        9e18,
        27e18,
        81e18,
        243e18,
        729e18,
        2187e18,
        6561e18,
        19683e18,
        59049e18,
        177147e18
    ];

    constructor(Fewmans fewmans_, IERC20 fewgold_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        fewmans = fewmans_;
        fewgold = fewgold_;
    }

    function breed(uint256 f1, uint256 f2) external {
        require(
            block.timestamp - nextFewvulation < fewvulationDuration,
            "Wait for next fewvulation"
        );
        uint8 gen = generation[f1] > generation[f2]
            ? generation[f1]
            : generation[f2];
        require((f1 ^ f2) & 1 == 1, "Need fewmans with different genders");
        require(gen < 13, "The fewman is too old");

        if (gen > 10)
            require(
                _has3stars(f1) || _has3stars(f2),
                "The rarest fewman is required"
            );
        else
            require(
                _countStars(f1) >= starsRequired[gen] ||
                    _countStars(f2) >= starsRequired[gen],
                "Some more stars are required for this breeding"
            );

        uint256 price = prices[gen];
        require(fewgold.balanceOf(msg.sender) >= price, "Insufficient funds");

        fewmans.burn(f1);
        fewmans.burn(f2);

        uint256 child = fewmans.createFor(
            msg.sender,
            _getChildPersonality(f1, f2)
        );
        childOf[f1] = child;
        childOf[f2] = child;
        generation[child] = gen + 1;
        fewgold.transfer(msg.sender, price);
    }

    function _countStars(uint256 f) internal view returns (uint8 res) {
        uint8[8] memory personality = fewmans.personality(f);
        for (uint8 i; i < 8; i++)
            if (personality[i] < 3) res += 3 - personality[i];
    }

    function _getChildPersonality(uint256 f1, uint256 f2)
        internal
        returns (uint8[8] memory childPersonality)
    {
        if (f1 & 1 == 0) (f1, f2) = (f2, f1);
        uint256 random = uint256(
            keccak256(abi.encodePacked(uint16(f1), uint16(f2), seed))
        );

        uint8[8] memory f1Personality = fewmans.personality(f1);
        uint8[8] memory f2Personality = fewmans.personality(f2);

        for (uint8 i; i < 8; i++) {
            uint256 rValue = random % 256;
            random /= 256;
            childPersonality[i] = genProb[f1Personality[i]][f2Personality[i]] <
                rValue
                ? f1Personality[i]
                : f2Personality[i];
        }
    }

    function _has3stars(uint256 f) internal returns (bool) {
        uint8[8] memory personality = fewmans.personality(f);
        for (uint8 i; i < 8; i++) if (personality[i] == 0) return true;
        return false;
    }

    function setFewvulation(uint256 start, uint256 duration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nextFewvulation = start;
        fewvulationDuration = duration;
    }

    function withdrawERC20(IERC20 token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}