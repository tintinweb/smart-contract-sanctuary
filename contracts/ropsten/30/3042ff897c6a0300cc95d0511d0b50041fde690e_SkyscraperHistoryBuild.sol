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

// File: contracts/SkyscraperHistoryBuild.sol

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

interface SkyscraperHistoryBuildInterface {
    function addPlayerHistory(address _addr, uint _gameRound, uint cR, uint sL, uint sR, uint rebackToVaults, uint rebackType) external;

    function addHistory(address _winner, uint256[4] _infos) external;
}

contract SkyscraperHistoryBuild
{
    using NameFilter for string;

    struct MsgHistory {
        uint layer;
        uint reward;
        uint timestamp;
        uint rebackToVaults;
        uint rebackType;
        uint gameRound;
    }

    struct PlayerHistory {
        uint msgNum;
        mapping(uint => MsgHistory) history;
    }

    struct BuildingInfo {
        address winner;
        uint256 topFund;
        uint256 winGet;
        uint256 lnum;
        uint256 buildTime;
        bool isEdit;
        bytes32 name;
    }

    event onEditBuildName (
        address players,
        uint256 blockTime
    );

    bool private isSetGame = false;
    address private gameAddr;

    mapping(uint256 => BuildingInfo) private allBuildingInfo;
    mapping(address => uint) private playerLR;
    mapping(address => PlayerHistory) private playerH;

    modifier isGameContract() {
        address _addr = msg.sender;
        require(_addr == gameAddr, "is not Skyscraper contract");
        _;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    constructor() public{}

    function setGame(address _addr) public
    {
        require((msg.sender == address(0x1bF4e46F68B40B97237C47696cd9334bDE5b621B) || msg.sender == address(0x15686ae97C475a09b3c8E0eDC92C7cAD979FF517)), "not developer");
        require(isSetGame == false, "has set game");
        gameAddr = _addr;
        isSetGame = true;
    }

    function() public payable {
        require(false, "no payable");
    }

    function addHistory(address _winner, uint256[4] _infos) isGameContract() public
    {
        uint256 _now = now;
        allBuildingInfo[_infos[0]].winner = _winner;
        allBuildingInfo[_infos[0]].topFund = _infos[1];
        allBuildingInfo[_infos[0]].winGet = _infos[2];
        allBuildingInfo[_infos[0]].lnum = _infos[3];
        allBuildingInfo[_infos[0]].buildTime = _now;
        allBuildingInfo[_infos[0]].isEdit = false;
        allBuildingInfo[_infos[0]].name = "someone";
    }

    function addPlayerHistory(address _addr, uint _gameRound, uint cR, uint sL, uint sR, uint rebackToVaults, uint rebackType) isGameContract() public
    {
        if (playerLR[_addr] != 0 && playerLR[_addr] != _gameRound) {
            delete playerH[_addr];
        }

        playerLR[_addr] = _gameRound;
        if (cR > 0) {
            playerH[_addr].history[playerH[_addr].msgNum].reward = cR;
            playerH[_addr].history[playerH[_addr].msgNum].timestamp = now;
            playerH[_addr].history[playerH[_addr].msgNum].gameRound = _gameRound;
            playerH[_addr].msgNum++;
        }
        if (sR > 0 && sL > 0) {
            playerH[_addr].history[playerH[_addr].msgNum].layer = sL;
            playerH[_addr].history[playerH[_addr].msgNum].reward = sR;
            playerH[_addr].history[playerH[_addr].msgNum].timestamp = now;
            playerH[_addr].history[playerH[_addr].msgNum].gameRound = _gameRound;
            playerH[_addr].msgNum++;
        }
        if (rebackToVaults > 0) {
            playerH[_addr].history[playerH[_addr].msgNum].rebackToVaults = rebackToVaults;
            playerH[_addr].history[playerH[_addr].msgNum].rebackType = rebackType;
            playerH[_addr].history[playerH[_addr].msgNum].timestamp = now;
            if (rebackType == 2) {
                playerH[_addr].history[playerH[_addr].msgNum].gameRound = _gameRound;
            } else {
                playerH[_addr].history[playerH[_addr].msgNum].gameRound = _gameRound - 1;
            }
            playerH[_addr].msgNum++;
        }
        if (rebackType == 3) {
            playerH[_addr].history[playerH[_addr].msgNum].rebackToVaults = rebackToVaults;
            playerH[_addr].history[playerH[_addr].msgNum].rebackType = rebackType;
            playerH[_addr].history[playerH[_addr].msgNum].timestamp = now;
            playerH[_addr].history[playerH[_addr].msgNum].gameRound = _gameRound - 1;
            playerH[_addr].msgNum++;
        }
    }

    function editName(string name, uint256 _gameRound) isHuman() public
    {
        require(allBuildingInfo[_gameRound].isEdit == false, "name has edit");

        bytes32 _name = name.nameFilter();
        allBuildingInfo[_gameRound].name = _name;
        allBuildingInfo[_gameRound].isEdit = true;

        emit onEditBuildName(
            msg.sender,
            block.timestamp
        );
    }

    function getBuildingInfo(uint256 _gameRound) public view returns
    (
        address,
        uint256[],
        bool,
        bytes32
    ) {
        uint256[] memory info = new uint256[](4);
        info[0] = allBuildingInfo[_gameRound].topFund;
        info[1] = allBuildingInfo[_gameRound].winGet;
        info[2] = allBuildingInfo[_gameRound].lnum;
        info[3] = allBuildingInfo[_gameRound].buildTime;
        return (
        allBuildingInfo[_gameRound].winner,
        info,
        allBuildingInfo[_gameRound].isEdit,
        allBuildingInfo[_gameRound].name
        );
    }

    function getPlayerHistory(uint idx) public view returns
    (
        uint layer,
        uint reward,
        uint timestamp,
        uint rebackToVaults,
        uint rebackType,
        uint gameRound
    ) {
        layer = playerH[msg.sender].history[idx].layer;
        reward = playerH[msg.sender].history[idx].reward;
        timestamp = playerH[msg.sender].history[idx].timestamp;
        rebackToVaults = playerH[msg.sender].history[idx].rebackToVaults;
        rebackType = playerH[msg.sender].history[idx].rebackType;
        gameRound = playerH[msg.sender].history[idx].gameRound;
    }
}