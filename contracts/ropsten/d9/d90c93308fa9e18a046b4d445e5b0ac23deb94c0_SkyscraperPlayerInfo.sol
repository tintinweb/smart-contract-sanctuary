pragma solidity ^0.4.24;

// File: contracts/NameFilter.sol

/**
* Name filter
* from: https://hackmd.io/s/HkkT9H5NX#MIT-License
*/
library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
    internal
    pure
    returns (bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //sorry limited to 32 characters
        require(_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length - 1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);

                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                // require character is a space
                    _temp[i] == 0x20 ||
                // OR lowercase a-z
                (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                // or 0-9
                (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require(_temp[i + 1] != 0x20, "string cannot contain consecutive spaces");

                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

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

// File: contracts/SkyscraperPlayerInfo.sol

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

interface SkyscraperBinaryInterface {


    function buyPredictForContract(address _buyPlayer, uint8 _buildType) external payable;

    function buyXaddrForContract(address _buyPlayer, uint pID) external payable;

    function buyXwithdrawForContract(address _buyPlayer, uint pID, uint _buyNum) external payable;
}

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

contract SkyscraperPlayerInfo {
    using NameFilter for string;
    using SafeMath for *;
    using SkyscraperLayersCalc for *;

    struct PlayerInfo {
        uint256 pID;
        address key;
        bytes32 name;
        uint256 win;
        uint256 gen;
        address recommendKey;
        uint256[6] recommendNum; // 0:one 1:two 2:three 3:four 4:five 5:six
        bool isPlay;
    }

    struct CurGamePrizeInfo {
        uint256 curGameRound;
        uint256 genFund;
        uint256 specialFund;
        uint256 continusFund;
        uint256 recommendFund;
    }

    event onEditName
    (
        address indexed playerAddress,
        bytes32 playerName,
        uint256 blockTime
    );

    mapping(address => PlayerInfo) private allPlayer;
    mapping(address => CurGamePrizeInfo) private allPlayerCurPrize;
    mapping(uint256 => address) private pIDplayer;
    mapping(bytes32 => address) private namePlayer;

    uint256 private _pID = 1;
    bool private isSetGame = false;

    address private game = 0x0;

    SkyscraperBinaryInterface private skyscraper;

    address constant private dev = 0x09e797dd3e328716e20c81e49dde9f9bd42b4871;

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    modifier isGame() {
        address _addr = msg.sender;
        require(_addr == game, "is not game contract");
        _;
    }

    constructor() public{}

    function setGame(address _game) public
    {
        require(isSetGame == false, "has set game");
        isSetGame = true;
        game = _game;
        skyscraper = SkyscraperBinaryInterface(_game);
    }

    function initPlayer(address _addr) private
    {
        if (allPlayer[_addr].pID == 0) {
            allPlayer[_addr].pID = _pID;
            allPlayer[_addr].key = _addr;

            pIDplayer[_pID] = _addr;
            _pID++;
        }
    }

    function updatePlayerRecommend(address _addr, address _recommend) private
    {
        if (allPlayer[_addr].pID > 0 && _recommend != address(0) && allPlayer[_addr].recommendKey == address(0)) {
            if (allPlayer[_recommend].pID > 0 && allPlayer[_addr].recommendNum[0] == 0 && allPlayer[_addr].isPlay == false) {
                allPlayer[_addr].recommendKey = _recommend;
                address _rq = _recommend;
                for (uint i = 0; i < 6; i++) {
                    if (allPlayer[_rq].pID > 0) {
                        allPlayer[_rq].recommendNum[i] = allPlayer[_rq].recommendNum[i] + 1;
                        _rq = allPlayer[_rq].recommendKey;
                    } else {
                        break;
                    }
                }
            }
        }
    }

    function clearCurPrize(address _addr, uint _gameRound) private
    {
        if (allPlayerCurPrize[_addr].curGameRound < _gameRound) {
            allPlayerCurPrize[_addr].curGameRound = _gameRound;
            allPlayerCurPrize[_addr].specialFund = 0;
            allPlayerCurPrize[_addr].continusFund = 0;
            allPlayerCurPrize[_addr].recommendFund = 0;
            allPlayerCurPrize[_addr].genFund = 0;
        }
    }

    function updatePlayerRecommendFund(address _addr, uint256 _prize, uint _gameRound) private returns
    (
        uint256
    ){
        if (_addr != address(0) && allPlayer[_addr].isPlay == true) {
            allPlayer[_addr].gen = _prize.add(allPlayer[_addr].gen);
            clearCurPrize(_addr, _gameRound);
            if (allPlayerCurPrize[_addr].curGameRound == _gameRound) {
                allPlayerCurPrize[_addr].recommendFund = _prize.add(allPlayerCurPrize[_addr].recommendFund);
            }
            return 0;
        }
        return _prize;
    }

    function() isHuman() public payable
    {
        revert();
    }

    function editName(string name) isHuman() public payable
    {
        bytes32 _name = name.nameFilter();

        require(namePlayer[_name] == address(0), "name has register");
        require(msg.value >= 10000000000000000, "eth not enough");

        address _addr = msg.sender;
        initPlayer(_addr);
        namePlayer[allPlayer[_addr].name] = address(0);
        allPlayer[_addr].name = _name;
        namePlayer[_name] = _addr;
        dev.transfer(msg.value);
        emit onEditName(_addr, _name, block.timestamp);
    }

    function buyXname(bytes32 recommend) isHuman() public payable
    {
        address _addr = msg.sender;
        address _recommend;

        if (recommend != "") {
            _recommend = namePlayer[recommend];
        }
        if (_recommend == _addr) {
            _recommend = address(0);
        }

        initPlayer(_addr);
        updatePlayerRecommend(_addr, _recommend);

        skyscraper.buyXaddrForContract.value(msg.value)(_addr, allPlayer[_addr].pID);
    }

    function buyPredictXname(bytes32 recommend, uint8 buildType) isHuman() public payable
    {
        address _addr = msg.sender;
        address _recommend;

        if (recommend != "") {
            _recommend = namePlayer[recommend];
        }

        if (_recommend == _addr) {
            _recommend = address(0);
        }

        initPlayer(_addr);
        skyscraper.buyPredictForContract.value(msg.value)(_addr, buildType);
    }

    function buyXwithdraw(bytes32 recommend, uint _buyNum) isHuman() public payable
    {
        address _recommend;

        if (recommend != "") {
            _recommend = namePlayer[recommend];
        }
        if (_recommend == msg.sender) {
            _recommend = address(0);
        }

        initPlayer(msg.sender);
        updatePlayerRecommend(msg.sender, _recommend);

        skyscraper.buyXwithdrawForContract.value(msg.value)(msg.sender, allPlayer[msg.sender].pID, _buyNum);
    }

    function updatePlayerWin(address _addr, uint256 _prize) isGame() public returns (uint256)
    {
        allPlayer[_addr].win = _prize.add(allPlayer[_addr].win);
        return allPlayer[_addr].win;
    }

    function updatePlayerGen(address _addr, uint256 _prize) isGame() public
    {
        allPlayer[_addr].gen = _prize.add(allPlayer[_addr].gen);
    }

    function updatePlayerContinusFund(address _addr, uint256 _prize, uint256 _gameRound) isGame() public
    {
        allPlayer[_addr].gen = _prize.add(allPlayer[_addr].gen);
        clearCurPrize(_addr, _gameRound);
        if (allPlayerCurPrize[_addr].curGameRound == _gameRound) {
            allPlayerCurPrize[_addr].continusFund = _prize.add(allPlayerCurPrize[_addr].continusFund);
        }
    }

    function updateCurGamePrizeInfoWithDraw(uint256 _gameRound, address _addr, uint256 _gen) isGame() public
    {
        clearCurPrize(_addr, _gameRound);

        if (allPlayerCurPrize[_addr].curGameRound == _gameRound) {
            allPlayerCurPrize[_addr].genFund = _gen.add(allPlayerCurPrize[_addr].genFund);
        }
    }

    function clearPlayerPrize(address _addr) isGame() public
    {
        allPlayer[_addr].win = 0;
        allPlayer[_addr].gen = 0;
    }

    function getWithdraw(address _addr) isGame() public view returns (uint256)
    {
        return (allPlayer[_addr].win + allPlayer[_addr].gen);
    }

    function updatePlayerFund(uint _gameRound, address _addr, uint _gen, uint _cf, uint _sf, uint _op) isGame() public {
        allPlayer[_addr].gen = (_gen+_cf+_sf+_op).add(allPlayer[_addr].gen);
        allPlayer[_addr].isPlay = true;

        clearCurPrize(_addr, _gameRound);
        if (allPlayerCurPrize[_addr].curGameRound == _gameRound) {
            allPlayerCurPrize[_addr].specialFund = _sf.add(allPlayerCurPrize[_addr].specialFund);
            allPlayerCurPrize[_addr].continusFund = _cf.add(allPlayerCurPrize[_addr].continusFund);
        }
    }

    function getPlayerRecommond(address _addr) public view returns
    (
        address
    ){
        return (allPlayer[_addr].recommendKey);
    }

    function recommendFundToPlayer(uint256 _eth, address _curPlayer, uint256 _gameRound)
    isGame()
    public
    returns (uint256)
    {
        uint256[7] memory _recommendFund;
        (_recommendFund[0], _recommendFund[1], _recommendFund[2], _recommendFund[3], _recommendFund[4], _recommendFund[5]) = _eth.countRecommendFund();

        address _recommendKey = _curPlayer;
        uint256 _prize;
        for (uint256 i = 0; i < 6; i++) {
            (_recommendKey) = getPlayerRecommond(_recommendKey);
            _prize = updatePlayerRecommendFund(_recommendKey, _recommendFund[i], _gameRound);
            if (_prize > 0) {
                _recommendFund[6] = _prize.add(_recommendFund[6]);
            }
        }
        return _recommendFund[6];
    }

    function getPlayerName(address _addr) public view returns
    (bytes32) {
        return allPlayer[_addr].name;
    }

    function getPlayerByName(string name) public view returns
    (address) {
        bytes32 _name = name.nameFilter();
        return namePlayer[_name];
    }

    function getPlayerWallet(uint gameRound) public view returns
    (
        uint256 allValut,
        uint256 curSF,
        uint256 curCF,
        uint256 curRF,
        uint256[6] recommendNum,
        uint256 pID,
        uint256 genF
    ) {
        allValut = allPlayer[msg.sender].win + allPlayer[msg.sender].gen;

        if (allPlayerCurPrize[msg.sender].curGameRound == gameRound) {
            curSF = allPlayerCurPrize[msg.sender].specialFund;
        } else {
            curSF = 0;
        }

        if (allPlayerCurPrize[msg.sender].curGameRound == gameRound) {
            curCF = allPlayerCurPrize[msg.sender].continusFund;
        } else {
            curCF = 0;
        }

        if (allPlayerCurPrize[msg.sender].curGameRound == gameRound) {
            curRF = allPlayerCurPrize[msg.sender].recommendFund;
        } else {
            curRF = 0;
        }

        if (allPlayerCurPrize[msg.sender].curGameRound == gameRound) {
            genF = allPlayerCurPrize[msg.sender].genFund;
        } else {
            genF = 0;
        }

        recommendNum = allPlayer[msg.sender].recommendNum;
        pID = allPlayer[msg.sender].pID;
    }
}