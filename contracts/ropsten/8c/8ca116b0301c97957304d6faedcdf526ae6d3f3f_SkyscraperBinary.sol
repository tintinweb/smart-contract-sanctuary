pragma solidity ^0.4.24;

// File: contracts/SafeMath.sol

/**
* SafeMath Library
* from: https://hackmd.io/s/HkkT9H5NX#MIT-License
*/
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
    internal
    pure
    returns (uint256 y)
    {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
    internal
    pure
    returns (uint256)
    {
        return (mul(x, x));
    }

    /**
     * @dev x to the power of y
     */
    function pwr(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
    {
        if (x == 0)
            return (0);
        else if (y == 0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++)
                z = mul(z, x);
            return (z);
        }
    }
}

// File: contracts/SkyscraperLayersCalc.sol

/**
* https://cryptoskyscraper.io    https://cryptoskyscraper.io    https://cryptoskyscraper.io    https://cryptoskyscraper.io    https://cryptoskyscraper.io
*
*  ██████╗██████╗ ██╗   ██╗██████╗ ████████╗ ██████╗     ███████╗██╗  ██╗██╗   ██╗███████╗ ██████╗██████╗  █████╗ ██████╗ ███████╗██████╗ 
* ██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝██╔═══██╗    ██╔════╝██║ ██╔╝╚██╗ ██╔╝██╔════╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
* ██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   ██║   ██║    ███████╗█████╔╝  ╚████╔╝ ███████╗██║     ██████╔╝███████║██████╔╝█████╗  ██████╔╝
* ██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   ██║   ██║    ╚════██║██╔═██╗   ╚██╔╝  ╚════██║██║     ██╔══██╗██╔══██║██╔═══╝ ██╔══╝  ██╔══██╗
* ╚██████╗██║  ██║   ██║   ██║        ██║   ╚██████╔╝    ███████║██║  ██╗   ██║   ███████║╚██████╗██║  ██║██║  ██║██║     ███████╗██║  ██║
*  ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝    ╚═════╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝
*
* https://cryptoskyscraper.io
*
* ╔═╗┬─┐┌─┐┌─┐┌─┐┌┐┌┌┬┐  ┌┐ ┬ ┬
* ╠═╝├┬┘├┤ └─┐├┤ │││ │   ├┴┐└┬┘
* ╩  ┴└─└─┘└─┘└─┘┘└┘ ┴   └─┘ ┴ 
*    ___       ___       ___       ___            ___       ___       ___       ___       ___       ___   
*   /\  \     /\  \     /\  \     /\__\          /\  \     /\  \     /\  \     /\  \     /\  \     /\  \  
*   \:\  \   /::\  \   /::\  \   /::L_L_         \:\  \   /::\  \   /::\  \   _\:\  \   /::\  \    \:\  \ 
*   /::\__\ /::\:\__\ /::\:\__\ /:/L:\__\        /::\__\ /::\:\__\ /:/\:\__\ /\/::\__\ /\:\:\__\   /::\__\
*  /:/\/__/ \:\:\/  / \/\::/  / \/_/:/  /       /:/\/__/ \/\::/  / \:\/:/  / \::/\/__/ \:\:\/__/  /:/\/__/
*  \/__/     \:\/  /    /:/  /    /:/  /        \/__/      /:/  /   \::/  /   \:\__\    \::/  /   \/__/   
*             \/__/     \/__/     \/__/                    \/__/     \/__/     \/__/     \/__/    
*
* This product is protected under license.  Any unauthorized copy, modification, or use without 
* express written consent from the creators is prohibited.
* 
* WARNING:  THIS PRODUCT IS HIGHLY ADDICTIVE.  IF YOU HAVE AN ADDICTIVE NATURE.  DO NOT PLAY.
*/

library SkyscraperLayersCalc {
    using SafeMath for *;

    function layersRec(uint256 _curEth, uint256 _newEth)
    internal
    pure
    returns (uint256)
    {
        uint256 _layers = (layers((_curEth).add(_newEth)).sub(layers(_curEth)));
        if (_layers <= 0) {
            return _layers;
        }
        if (_layers >= 100) {
            _layers = 100;
        } else if (_layers >= 20 && _layers < 100) {
            _layers = 20;
        } else if (_layers >= 5 && _layers < 20) {
            _layers = 5;
        } else {
            _layers = 1;
        }
        return _layers;
    }

    function layers(uint256 _eth)
    internal
    pure
    returns (uint256)
    {
        return _eth / 10000000000000000;
    }

    function eth(uint256 _layers)
    internal
    pure
    returns (uint256)
    {
        return _layers.mul(10000000000000000);
    }

    function tokens(uint256 _eth)
    internal
    pure
    returns (uint256)
    {
        return _eth / 10000000000000000;
    }

    function specialBaseLayer(uint256 _layerNum)
    internal
    pure
    returns (uint256)
    {
        uint256 _basePerLayer = 0;
        if (_layerNum > 0 && _layerNum <= 10000) {
            _basePerLayer = 1000;
        } else {
            _basePerLayer = 10000;
        }
        return _basePerLayer;
    }

    function countRecommendFund(uint256 _eth)
    internal
    pure
    returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        return ((_eth.mul(10) / 100), (_eth.mul(3) / 100), (_eth.mul(1) / 100), (_eth.mul(1) / 100), (_eth.mul(1) / 100), (_eth.mul(1) / 100));
    }

    function countLayersGasLimit(uint256 _layers)
    internal
    pure
    returns (uint256)
    {
        if (_layers == 1) {
            return 650000;
        } else if (_layers == 5) {
            return 850000;
        } else {
            return 2000000;
        }
    }
}

// File: contracts/SkyscraperBinary.sol

/**
* https://cryptoskyscraper.io    https://cryptoskyscraper.io    https://cryptoskyscraper.io    https://cryptoskyscraper.io    https://cryptoskyscraper.io
*
*  ██████╗██████╗ ██╗   ██╗██████╗ ████████╗ ██████╗     ███████╗██╗  ██╗██╗   ██╗███████╗ ██████╗██████╗  █████╗ ██████╗ ███████╗██████╗ 
* ██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝██╔═══██╗    ██╔════╝██║ ██╔╝╚██╗ ██╔╝██╔════╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
* ██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   ██║   ██║    ███████╗█████╔╝  ╚████╔╝ ███████╗██║     ██████╔╝███████║██████╔╝█████╗  ██████╔╝
* ██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   ██║   ██║    ╚════██║██╔═██╗   ╚██╔╝  ╚════██║██║     ██╔══██╗██╔══██║██╔═══╝ ██╔══╝  ██╔══██╗
* ╚██████╗██║  ██║   ██║   ██║        ██║   ╚██████╔╝    ███████║██║  ██╗   ██║   ███████║╚██████╗██║  ██║██║  ██║██║     ███████╗██║  ██║
*  ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝    ╚═════╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝
*
*
* ╔═╗┬─┐┌─┐┌─┐┌─┐┌┐┌┌┬┐  ┌┐ ┬ ┬
* ╠═╝├┬┘├┤ └─┐├┤ │││ │   ├┴┐└┬┘
* ╩  ┴└─└─┘└─┘└─┘┘└┘ ┴   └─┘ ┴ 
*    ___       ___       ___       ___            ___       ___       ___       ___       ___       ___   
*   /\  \     /\  \     /\  \     /\__\          /\  \     /\  \     /\  \     /\  \     /\  \     /\  \  
*   \:\  \   /::\  \   /::\  \   /::L_L_         \:\  \   /::\  \   /::\  \   _\:\  \   /::\  \    \:\  \ 
*   /::\__\ /::\:\__\ /::\:\__\ /:/L:\__\        /::\__\ /::\:\__\ /:/\:\__\ /\/::\__\ /\:\:\__\   /::\__\
*  /:/\/__/ \:\:\/  / \/\::/  / \/_/:/  /       /:/\/__/ \/\::/  / \:\/:/  / \::/\/__/ \:\:\/__/  /:/\/__/
*  \/__/     \:\/  /    /:/  /    /:/  /        \/__/      /:/  /   \::/  /   \:\__\    \::/  /   \/__/   
*             \/__/     \/__/     \/__/                    \/__/     \/__/     \/__/     \/__/    
*
* This product is protected under license.  Any unauthorized copy, modification, or use without 
* express written consent from the creators is prohibited.
* 
* WARNING:  THIS PRODUCT IS HIGHLY ADDICTIVE.  IF YOU HAVE AN ADDICTIVE NATURE.  DO NOT PLAY.
*/



interface SkyscraperPlayerInfoInterface {
    function updatePlayerWin(address _addr, uint256 _prize) external returns (uint256);

    function updatePlayerGen(address _addr, uint256 _prize) external;

    function updateCurGamePrizeInfoWithDraw(uint256 _gameRound, address _addr, uint256 _gen) external;

    function updatePlayerContinusFund(address _addr, uint256 _prize, uint256 _gameRound) external;

    function getWithdraw(address _addr) external view returns (uint256);

    function recommendFundToPlayer(uint256 _eth, address _curPlayer, uint256 _gameRound) external returns (uint256);

    function getPlayerRecommond(address _addr) external view returns (address);

    function clearPlayerPrize(address _addr) external;

    function updatePlayerFund(uint _gameRound, address _addr, uint _gen, uint _cf, uint _sf, uint _op) external;
}

interface SkyscraperHistoryBuildInterface {
    function addPlayerHistory(address _addr, uint _gameRound, uint cR, uint sL, uint sR, uint rebackToVaults, uint rebackType) external;

    function addHistory(address _winner, uint256[4] _infos) external;
}

interface SkyscraperBinaryInterface {


    function buyPredictForContract(address _buyPlayer, uint8 _buildType) external payable;

    function buyXaddrForContract(address _buyPlayer, uint pID) external payable;

    function buyXwithdrawForContract(address _buyPlayer, uint pID, uint _buyNum) external payable;
}


contract SkyscraperBinary {


    struct GamePlayer {
        uint eth;
        uint curPrize;
    }

    struct CurBuyEvent {
        uint8 lastLayerType;
        address commercePrizePlayer;
        address specialPrizePlayer;
        uint commercePrizeNum;
        uint specialPrizeNum;
        uint specialLayerNum;
        uint cf2PlayerPer;
        uint cf2FundPer;

        uint addCF;
        uint addSF;
        uint addGen;
        uint addOP;
    }

    struct BuildingLayerInfo {
        uint idx;
        bytes layers;
    }

    // event
    // <<
    event onBuy
    (
        address playerAddress,
        bytes playerBoughtFloorData,
        uint256 buildingHeight,
        address commercePrizePlayer,
        uint256 commercePrizeNum,
        address specialPrizePlayer,
        uint256 specialPrizeNum,
        uint256 specialLayerNum,
        uint256 blockTime
    );

    event onEndRound
    (
        address winnerAddress,
        uint256 amountWinnerWon,
        uint256 newRoundStartTime,
        uint256 newRoundEndTime,
        uint256 blockTime
    );

    event onBuyPredict(
        address player,
        uint256 amount,
        uint256 blockTime
    );

    event onWithdraw
    (
        address playerAddress,
        uint256 amount,
        uint256 predictAmount,
        uint256 blockTime
    );
    // >>

    using SafeMath for *;
    using SkyscraperLayersCalc for uint256;

    uint constant private gameDur = 18 hours;
    uint constant private gameRest = 5 minutes;
    uint constant private gameInc = 30 seconds;
    address constant private dev = 0x09e797dd3e328716e20c81e49dde9f9bd42b4871;


    bool private gRIsEnd;
    address private gRLastPlayer;

    uint private gameRound;
    uint private gRTF;
    uint private gRSF;
    uint private gRCF;
    uint private gRETH;
    uint private gRAddTime;
    uint private gRLayerN;
    uint private gRLast10PlayerIdx;
    uint private startT;
    uint private endT;
    uint private gRContinueLayer;
    uint private gRMaxContinueLayer;

    mapping(uint => uint8) private gRLastLayerT;
    mapping(uint => uint) private gROP;
    mapping(uint => uint[4]) private gROPType;
    mapping(uint => uint256) private gRMask;
    mapping(uint => address) private gRLast10PlayerAddr;
    mapping(uint => uint) private gRLast10PlayerLayer;

    mapping(address => uint) private playerLR;
    mapping(uint => mapping(address => uint)) private playerLayerN;
    mapping(uint => mapping(address => uint)) private playerMask;
    mapping(uint => mapping(address => uint)) private playerOPMask;
    mapping(uint => mapping(address => uint[4])) private playerOPNum;
    mapping(address => GamePlayer) private player;
    mapping(uint256 => BuildingLayerInfo) private allBuildingLayerInfo;

    bool private isSetContract;
    address private playerInfoContract;

    SkyscraperPlayerInfoInterface private playerInfo;
    SkyscraperHistoryBuildInterface private historyBuild;

    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 10000000000000000, "eth not enough");
        require(_eth <= 10000000000000000000000, "eth is too match");
        _;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    modifier isFatherContract() {
        address _addr = msg.sender;
        require(_addr == playerInfoContract, "is not fatherContract");
        _;
    }

    constructor() public {}

    function setContractAddr(address _playerInfo, address _historyBuilding) public
    {
        require((msg.sender == address(0x1bF4e46F68B40B97237C47696cd9334bDE5b621B) || msg.sender == address(0x15686ae97C475a09b3c8E0eDC92C7cAD979FF517)), "not developer");
        require(isSetContract == false, "has set player info");
        isSetContract = true;
        playerInfoContract = _playerInfo;

        playerInfo = SkyscraperPlayerInfoInterface(_playerInfo);
        historyBuild = SkyscraperHistoryBuildInterface(_historyBuilding);

        for(uint i=0; i < 10; i++) {
            gRLast10PlayerAddr[i] = address(1);
            gRLast10PlayerLayer[i] = 1;
        }

        gameRound = 1;
        startT = now + 15 * 60;
        endT = (startT).add(gameDur);
    }

    function updateTimer(uint _layers) private
    {
        uint _newTime;
        if (now > endT && gRLayerN == 0)
            _newTime = gameDur.add(now);
        else
            _newTime = (_layers.mul(gameInc)).add(endT);

        if (_newTime < (gameDur).add(now))
            endT = _newTime;
        else
            endT = gameDur.add(now);

        gRAddTime = (_layers.mul(gameInc)).add(gRAddTime);
    }

    function getPlayerGenMask(address _addr, uint256 _gameRoundID) private view returns (
        uint256
    ) {
        return ((gRMask[_gameRoundID].mul(playerLayerN[_gameRoundID][_addr])).sub(playerMask[_gameRoundID][_addr]));
    }

    function getPlayerPredictMask(address _addr, uint256 _gameRoundID) public view returns (
        uint256
    ) {
        if (_gameRoundID == gameRound || gROPType[_gameRoundID][gRLastLayerT[_gameRoundID]] <= 0) {
            return 0;
        }
        return (gROP[_gameRoundID].mul(playerOPNum[_gameRoundID][_addr][gRLastLayerT[_gameRoundID]]) / gROPType[_gameRoundID][gRLastLayerT[_gameRoundID]]);
    }

    function updateMasks(address _addr, uint _gen, uint _layers, uint _totalLayers) private
    {
        gRMask[gameRound] = (_gen / _totalLayers).add(gRMask[gameRound]);
        playerMask[gameRound][_addr] = ((gRMask[gameRound].mul(_layers)).sub((_gen / _totalLayers).mul(_layers))).add(playerMask[gameRound][_addr]);
    }

    function withdrawCount(address _addr) private returns (
        uint256 maskEarnings,
        uint256 predictEarnings
    ) {
        if (playerLR[_addr] != 0) {
            maskEarnings = getPlayerGenMask(_addr, playerLR[_addr]);
            playerMask[playerLR[_addr]][_addr] = maskEarnings.add(playerMask[playerLR[_addr]][_addr]);
            if (playerLR[_addr] != gameRound) {
                predictEarnings = getPlayerPredictMask(_addr, playerLR[_addr]).sub(playerOPMask[playerLR[_addr]][_addr]);
                playerOPMask[playerLR[_addr]][_addr] = predictEarnings.add(playerOPMask[playerLR[_addr]][_addr]);
            }
            playerInfo.updateCurGamePrizeInfoWithDraw(playerLR[_addr], _addr, maskEarnings);
        }
    }

    function mergePlayer(address _addr) private returns (
        uint256 maskEarnings,
        uint256 predictEarnings
    ) {
        (maskEarnings, predictEarnings) = withdrawCount(_addr);
        if (playerLR[_addr] != 0) {
            delete player[_addr];
        }
        playerLR[_addr] = gameRound;
    }

    function randomBuildType(address _addr, uint256 _buyNum, uint _totalLayerNum, uint8 _oldLastLayerType) private returns (
        uint _toPlayerPercent,
        uint _toFundPercent,
        uint8 _lastLayerType,
        bytes _result
    ) {
        if (allBuildingLayerInfo[gameRound].layers.length <= 0) {
            allBuildingLayerInfo[gameRound].layers.length = 20;
        }
        
        _lastLayerType = _oldLastLayerType;
        uint256 seed;

        _result = new bytes(_buyNum);
        for (uint i = 0; i < _buyNum; i++) {
            if (i % 64 == 0) {
                seed = uint256(keccak256(abi.encodePacked(
                        (block.timestamp).add
                        (block.difficulty).add
                        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                        (block.gaslimit).add
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                        (block.number).add
                        (_totalLayerNum + _buyNum * i)
                    )));
            }

            _result[i] = byte(uint8(seed & ((1 << 4) - 1)) % 4 + 48);


            if (i >= (_buyNum - 10)) {
                gRLast10PlayerAddr[gRLast10PlayerIdx] = _addr;
                gRLast10PlayerLayer[gRLast10PlayerIdx] = _totalLayerNum + i + 1;
                gRLast10PlayerIdx = (gRLast10PlayerIdx + 1) % 10;
            }

            if (_lastLayerType != (uint8(_result[i]) - 48)) {
                _toPlayerPercent = _toFundPercent.add(_toPlayerPercent);
                _toFundPercent = 0;
                if (gRMaxContinueLayer < gRContinueLayer) {
                    gRMaxContinueLayer = gRContinueLayer;
                }
                gRContinueLayer = 0;
            } else {
                _toFundPercent++;
                gRContinueLayer++;
            }
            _lastLayerType = (uint8(_result[i]) - 48);

            seed = seed >> 4;

            if (_buyNum > 20) {
                if (i >= (_buyNum-20)) {
                    allBuildingLayerInfo[gameRound].layers[allBuildingLayerInfo[gameRound].idx] = _result[i];
                    allBuildingLayerInfo[gameRound].idx = (allBuildingLayerInfo[gameRound].idx + 1)%20;
                }
            } else {
                allBuildingLayerInfo[gameRound].layers[allBuildingLayerInfo[gameRound].idx] = _result[i];
                allBuildingLayerInfo[gameRound].idx = (allBuildingLayerInfo[gameRound].idx + 1)%20;
            }
        }
    }

    function core(address _addr, uint _eth, uint _inputBuyNum) private returns (
        bytes buildLayerList
    ) {
        CurBuyEvent memory curBuy;

        if (playerLayerN[gameRound][_addr] == 0) {
            (curBuy.addGen, curBuy.addOP) = mergePlayer(_addr);
        }

        uint _buyNum = gRETH.layersRec(_eth);
        if (_inputBuyNum > 0 && _inputBuyNum <= _buyNum){
            _buyNum = _inputBuyNum;
        }
        if (_buyNum > 0) {
            uint _realEth = _buyNum.eth();
            curBuy.addGen = ((_eth).sub(_realEth)).add(curBuy.addGen);

            (curBuy.cf2PlayerPer, curBuy.cf2FundPer, curBuy.lastLayerType, buildLayerList) = randomBuildType(_addr, _buyNum, gRLayerN, gRLastLayerT[gameRound]);
            updateTimer(_buyNum);
            // basic count
            // <<
            updateMasks(_addr, (_realEth.mul(30) / 100), _buyNum, (gRLayerN + _buyNum));
            // >>

            // commerce count
            // <<
            if (gRLastLayerT[gameRound] != (uint8(buildLayerList[0]) - 48)) {
                playerInfo.updatePlayerContinusFund(gRLastPlayer, gRCF, gameRound);
                player[gRLastPlayer].curPrize = gRCF.add(player[gRLastPlayer].curPrize);
                historyBuild.addPlayerHistory(gRLastPlayer, gameRound, gRCF, 0, 0, 0, 0);
                if (curBuy.cf2PlayerPer <= 0) {
                    curBuy.commercePrizePlayer = gRLastPlayer;
                    curBuy.commercePrizeNum = gRCF;
                }
                gRCF = 0;
            }

            if (curBuy.cf2PlayerPer > 0) {
                curBuy.addCF = ((_realEth.mul(20) / 100).mul(curBuy.cf2PlayerPer) / _buyNum).add(gRCF).add(curBuy.addCF);
                gRCF = 0;
            }
            gRCF = ((_realEth.mul(20) / 100).mul(curBuy.cf2FundPer) / _buyNum).add(gRCF);
            // >>

            // special count
            // <<
            uint _base = gRLayerN.specialBaseLayer();
            if (((gRLayerN + _buyNum) / _base - gRLayerN / _base) >= 1) {
                curBuy.addSF = (((_realEth.mul(5)) / 100).mul(_buyNum - ((gRLayerN + _buyNum) % _base)) / _buyNum).add(gRSF);
                gRSF = ((_realEth.mul(5)) / 100).mul((gRLayerN + _buyNum) % _base) / _buyNum;
            } else {
                gRSF = ((_realEth.mul(5)) / 100).add(gRSF);
            }
            // >>

            // top count
            // <<
            gRTF = ((_realEth.mul(26)) / 100).add(((_realEth.mul(20) / 100).mul(_buyNum - curBuy.cf2FundPer - curBuy.cf2PlayerPer) / _buyNum)).add(gRTF);
            // >>

            // dev count
            // <<
            uint df = playerInfo.recommendFundToPlayer(_realEth, _addr, gameRound);
            dev.transfer(((_realEth.mul(2)) / 100).add(df));
            // >>

            // update and emit event
            // <<
            gRETH = gRETH.add(_realEth);
            gRLayerN = gRLayerN.add(_buyNum);
            gRLastPlayer = _addr;
            gRLastLayerT[gameRound] = curBuy.lastLayerType;
            playerLayerN[gameRound][_addr] = _buyNum.add(playerLayerN[gameRound][_addr]);
            player[_addr].eth = _realEth.add(player[_addr].eth);

            playerInfo.updatePlayerFund(gameRound, _addr, curBuy.addGen, curBuy.addCF, curBuy.addSF, curBuy.addOP);
            player[_addr].curPrize = (curBuy.addGen + curBuy.addCF + curBuy.addSF + curBuy.addOP).add(player[_addr].curPrize);
            if (curBuy.addCF > 0) {
                curBuy.commercePrizePlayer = _addr;
                curBuy.commercePrizeNum = curBuy.addCF;
            }
            if (curBuy.addSF > 0) {
                curBuy.specialPrizePlayer = _addr;
                curBuy.specialPrizeNum = curBuy.addSF;
                curBuy.specialLayerNum = gRLayerN / _base * _base;
            }
            if (curBuy.addSF > 0 || curBuy.addCF > 0) {
                historyBuild.addPlayerHistory(_addr, gameRound, curBuy.addCF, curBuy.specialLayerNum, curBuy.addSF, 0, 0);
            }
            emit onBuy(
                _addr,
                buildLayerList,
                gRLayerN,
                curBuy.commercePrizePlayer,
                curBuy.commercePrizeNum,
                curBuy.specialPrizePlayer,
                curBuy.specialPrizeNum,
                curBuy.specialLayerNum,
                block.timestamp
            );
            // >>
        }
    }

    function endGame() private
    {
        uint _win = (gRTF.mul(50) / 100);
        uint _lnum = gRLayerN;
        if (_lnum >= 10) {
            _lnum = 9;
        }
        uint256 _ppt = ((gRTF.mul(38)) / 100) / _lnum;
        for (uint8 i = 0; i < 10; i++) {
            if (gRLast10PlayerAddr[i] != address(1) && gRLast10PlayerLayer[i] != gRLayerN) {
                playerInfo.updatePlayerWin(gRLast10PlayerAddr[i], _ppt);
                if (gRLast10PlayerAddr[i] == gRLastPlayer) {
                    player[gRLastPlayer].curPrize = _ppt.add(player[gRLastPlayer].curPrize);
                }
                gRLast10PlayerAddr[i] = address(1);
            }
        }
        playerInfo.updatePlayerWin(gRLastPlayer, _win);
        dev.transfer((gRTF.mul(2) / 100).add(gRSF).add(gRCF));

        uint256[4] memory info;
        info[0] = gameRound;
        info[1] = gRTF;
        info[2] = _win;
        info[3] = gRLayerN;

        historyBuild.addHistory(
            gRLastPlayer,
            info
        );

        // start next gameRound
        gameRound++;
        startT = now.add(gameRest);
        endT = (now.add(gameRest)).add(gameDur);

        emit onEndRound(
            gRLastPlayer,
            _win,
            startT,
            endT,
            block.timestamp
        );

        gRTF = gRTF.sub(((gRTF.mul(90)) / 100));
        gRSF = 0;
        gRCF = 0;
        gRETH = 0;
        gRAddTime = 0;
        gRLayerN = 0;
        gRLast10PlayerIdx = 0;
        gRContinueLayer = 0;
        gRMaxContinueLayer = 0;
        gRLastPlayer = address(0);

        gRIsEnd = false;
    }

    function buyCore(address _buyPlayer, uint256 _eth, uint pID, uint _buyNum) private {
        core(_buyPlayer, _eth, _buyNum);
    }

    // action
    // <<
    function()
    public
    payable
    {
        require(false, "no function can do");
    }

    function buyXaddrForContract(address _buyPlayer, uint pID) isFatherContract() isWithinLimits(msg.value)
    public
    payable
    {
        if (now > startT && (now <= endT || (now > endT && gRLayerN == 0))) {
            buyCore(_buyPlayer, msg.value, pID, 0);
        } else {
            playerInfo.updatePlayerGen(_buyPlayer, msg.value);
            if (now > endT && gRIsEnd == false) {
                gRIsEnd = true;
                endGame();
                historyBuild.addPlayerHistory(_buyPlayer, gameRound, 0, 0, 0, msg.value, 1);
            } else {
                historyBuild.addPlayerHistory(_buyPlayer, gameRound, 0, 0, 0, msg.value, 2);
            }
        }
    }

    function buyXwithdrawForContract(address _buyPlayer, uint pID, uint _buyNum) isFatherContract()
    public
    {
        if (now > startT && (now <= endT || (now > endT && gRLayerN == 0))) {
            uint256 _maskE;
            uint256 _predictE;
            uint256 _withdrawV;
            _withdrawV = playerInfo.getWithdraw(_buyPlayer);
            (_maskE, _predictE) = withdrawCount(_buyPlayer);

            require(((_buyNum.eth()) <= (_withdrawV + _maskE + _predictE)), "eth not enough");

            playerInfo.clearPlayerPrize(_buyPlayer);
            buyCore(_buyPlayer, (_withdrawV + _maskE + _predictE), pID, _buyNum);
        } else {
            if (now > endT && gRIsEnd == false) {
                gRIsEnd = true;
                endGame();
                historyBuild.addPlayerHistory(_buyPlayer, gameRound, 0, 0, 0, 0, 3);
            }
        }
    }

    function buyPredictForContract(address _buyPlayer, uint8 _buildType) isFatherContract() isWithinLimits(msg.value)
    public
    payable
    {
        if (now > startT && (now <= endT || (now > endT && gRLayerN == 0))) {
            uint256 _tokens = (msg.value).tokens();
            gROP[gameRound] = (msg.value).add(gROP[gameRound]);

            gROPType[gameRound][_buildType] = _tokens.add(gROPType[gameRound][_buildType]);
            playerOPNum[gameRound][_buyPlayer][_buildType] = _tokens.add(playerOPNum[gameRound][_buyPlayer][_buildType]);

            emit onBuyPredict(
                _buyPlayer,
                msg.value,
                block.timestamp
            );
        } else {
            playerInfo.updatePlayerGen(_buyPlayer, msg.value);
            if (now > endT && gRIsEnd == false) {
                gRIsEnd = true;
                endGame();
                historyBuild.addPlayerHistory(_buyPlayer, gameRound, 0, 0, 0, msg.value, 1);
            } else {
                historyBuild.addPlayerHistory(_buyPlayer, gameRound, 0, 0, 0, msg.value, 2);
            }
        }
    }

    function withdraw() isHuman()
    public
    {
        uint256 _maskE;
        uint256 _predictE;
        uint256 _withdrawV;
        if (now > startT && (now <= endT || (now > endT && gRLayerN == 0))) {    
            _withdrawV = playerInfo.getWithdraw(msg.sender);
            (_maskE, _predictE) = withdrawCount(msg.sender);
            playerInfo.clearPlayerPrize(msg.sender);

            require((_withdrawV + _maskE + _predictE) > 0, "withdraw value is zero!");
            (msg.sender).transfer(_withdrawV + _maskE + _predictE);

            emit onWithdraw(
                msg.sender,
                (_withdrawV + _maskE + _predictE),
                _predictE,
                block.timestamp
            );
        } else {
            if (now > endT && gRIsEnd == false) {
                gRIsEnd = true;
                endGame();
            }

            _withdrawV = playerInfo.getWithdraw(msg.sender);
            (_maskE, _predictE) = withdrawCount(msg.sender);
            playerInfo.clearPlayerPrize(msg.sender);

            require((_withdrawV + _maskE + _predictE) > 0, "withdraw value is zero!");
            (msg.sender).transfer(_withdrawV + _maskE + _predictE);

            emit onWithdraw(
                msg.sender,
                (_withdrawV + _maskE + _predictE),
                _predictE,
                block.timestamp
            );
        }
    }
    // >>

    // info
    // <<
    function getGameInfo()
    external
    view
    returns (
        address lastPlayer,
        uint[4] predict,
        uint[4] playerPredict,
        uint[12] info
    ) {
        lastPlayer = gRLastPlayer;

        predict = gROPType[gameRound];
        playerPredict = playerOPNum[gameRound][msg.sender];

        info[0] = startT;
        info[1] = endT;
        info[2] = gRAddTime;
        info[3] = now;
        info[4] = gRTF;
        info[5] = gROP[gameRound];
        info[6] = gRLayerN;
        info[7] = gameRound;
        info[8] = getPlayerGenMask(msg.sender, gameRound);
        info[9] = playerLayerN[gameRound][msg.sender];
        if (playerLR[msg.sender] != 0) {
            info[10] = getPlayerGenMask(msg.sender, playerLR[msg.sender]);
            info[11] = getPlayerPredictMask(msg.sender, playerLR[msg.sender]).sub(playerOPMask[playerLR[msg.sender]][msg.sender]);
        } else {
            info[10] = 0;
            info[11] = 0;
        }
    }
    // >>

    function getBuildingLayers(uint _gameRound) public view returns
    (
        uint idx,
        bytes layers
    ) {
        idx = allBuildingLayerInfo[_gameRound].idx;
        layers = allBuildingLayerInfo[_gameRound].layers;
    }
}