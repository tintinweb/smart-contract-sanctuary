// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IGotei_13.sol";


/**
 *  @dev Gotei_13.sol
 *
 *  The Gotei 13 (護廷十三隊, Goteijūsantai; lit. "13 Division Imperial Guards";
 *  Viz "Thirteen Court Guard Companies") is the primary military branch of Soul Society
 *  and the main military organization most Shinigami join after leaving the Shin'ō Academy.
 */
contract Gotei_13 is IGotei_13 {

    uint public _roarCount;
    uint public _scatterCount;
    uint public _growlCount;
    uint public _getsugaCount;
    uint public _killCount;
    uint public _shatterCount;

    /**
     *  @dev Initializes counter state variables.
     */
    constructor() {

        _roarCount = 0;
        _scatterCount = 0;
        _growlCount = 0;
        _getsugaCount = 0;
        _killCount = 0;
        _shatterCount = 0;
    }

    /**
     *  @dev roarZabimaru
     *
     *  Zabimaru has two heads of intelligent beings within his spirit form. The first head of
     *  Zabimaru is a large, white baboon with long, purple markings along his back and arms.
     *  The second head is a white snake, which extends from the back of the baboon in the form
     *  of a tail with the snake head on the end. Both of these heads have their own consciousness
     *  and speak independently of one another, though the snake depends on the baboon for independent
     *  movement. Overall, his appearance strongly resembles that of a nue.
     */
    function roarZabimaru() external payable override {

        uint j;
        for (j = 0; j < 200; j++) {
            _roarCount++;
        }
    }

    /**
     *  @dev scatterSenbonzakura
     *
     *  Upon release, Senbonzakura's sword form separates into a thousand tiny blade petals,
     *  which fly toward Senbonzakura's target. Senbonzakura can control and direct the blade
     *  petals by slashing at his target with the hilt of his sword. The blade petals themselves
     *  reflect light in such a way as to resemble cherry blossom petals, and possess enough cutting
     *  power to instantly defeat a Sword Beast.
     */
    function scatterSenbonzakura() external payable override {

        uint j;
        for (j = 0; j < 1000; j++) {
            _scatterCount++;
        }
    }

    /**
     *  @dev growlHaineko
     *
     *  By making a slashing motion with the hilt of her sword, Haineko can cut anything which the ash
     *  has landed on. However, she frequently uses the ash as a weapon by itself, crushing and slashing
     *  her enemies with it. Additionally, she can create a tornado of ash around herself and anyone else
     *  she chooses in order to protect them from outside attacks.
     */
    function growlHaineko() external payable override {

        uint j;
        for (j = 0; j < 100; j++) {
            _growlCount++;
        }
    }

    /**
     *  @dev getsugaTensho
     *
     *  At the instant of the slash, the Zanpakutō absorbs and condenses the user's Reiatsu before releasing
     *  it at the tip of the blade, magnifying the slash attack, which flies forward. This slash takes the shape
     *  of a crescent moon or wave.[2] Ichigo uses this ability without knowing its name several times, but later
     *  masters the technique during his Bankai training. As stated by Zangetsu, knowing the name of an attack
     *  heightens its power compared to its strength when the wielder does not know its name.
     */
    function getsugaTensho() external payable override {

        uint j;
        for (j = 0; j < 2000; j++) {
            _getsugaCount++;
        }
    }

    /**
     *  @dev shootToKillShinso
     *
     *  Gin has made claim that his Bankai can achieve its full length at 500 times the speed of sound: exactly
     *  171,500 meters per second in order to arrive at its full length of 13km in under 0.08 seconds, which would
     *  make Kamishini no Yari not the longest Zanpakutō, but the fastest. Because the blade's extension and contraction
     *  speed is a highly dangerous ability, Gin tends to downplay its speed whenever he talks about his Zanpakutō,
     *  and instead focuses on the length and power of the blade in order to gain a psychological advantage over his opponent.
     *
     */
    function shootToKillShinso() external payable override {

        uint j;
        for (j = 0; j < 1000; j++) {
            _killCount++;
        }
    }

    /**
     *  @dev shatterKyokaSuigetsu
     *
     *  Kyōka Suigetsu's most fearsome power is known as Kanzen Saimin (完全催眠, "Complete Hypnosis").
     */
    function shatterKyokaSuigetsu(uint countLimit) external payable override {

        uint j;
        for (j = 0; j < countLimit; j++) {
            _shatterCount++;
        }
    }
}