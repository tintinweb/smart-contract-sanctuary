pragma solidity ^0.4.25;

contract Brave3d {

    struct Stage {
        uint8 cnt;
        uint256 blocknumber;
        bool isFinish;
        uint8 deadIndex;
        mapping(uint8 => address) playerMap;
    }


    HourglassInterface constant p3dContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);

    address constant private  OFFICIAL = 0x97397C2129517f82031a28742247465BC75E1849;
    address constant private  OFFICIAL_P3D = 0x97397C2129517f82031a28742247465BC75E1849;

    uint8 constant private MAX_PLAYERS = 3;
    uint256 constant private PRICE = 0.1 ether;
    uint256 constant private P3D_VALUE = 0.019 ether;
    uint256 constant private REFEREE_VALUE = 0.007 ether;
    uint256 constant private  WIN_VALUE = 0.13 ether;

    mapping(address => uint256) private _valueMap;
    mapping(address => uint256) private _referredMap;
    mapping(address => address) private _addressMap;
    mapping(string => address)  private _nameAddressMap;
    mapping(address => string)  private _addressNameMap;

    mapping(uint8 => mapping(uint256 => Stage)) private _stageMap;
    mapping(uint8 => uint256) private _finishMap;
    mapping(uint8 => uint256) private _currentMap;

    event BravePlayer(address indexed player, uint8 rate);
    event BraveDeadPlayer(address indexed deadPlayer, uint8 rate);
    event BraveWithdraw(address indexed player, uint256 indexed amount);
    event BraveInvalidateStage(uint256 indexed stage, uint8 rate);


    modifier hasEarnings()
    {
        require(_valueMap[msg.sender] > 0);
        _;
    }

    modifier isExistsOfNameAddressMap(string name){
        require(_nameAddressMap[name]==0);
        _;
    }

    modifier isExistsOfAddressNameMap(){
        require(bytes(_addressNameMap[msg.sender]).length<=0);
        _;
    }

    constructor()
    public
    {
        _stageMap[1][0] = Stage(0, 0, false, 0);
        _stageMap[5][0] = Stage(0, 0, false, 0);
        _stageMap[10][0] = Stage(0, 0, false, 0);

        _currentMap[1] = 1;
        _currentMap[5] = 1;
        _currentMap[10] = 1;

        _finishMap[1] = 0;
        _finishMap[5] = 0;
        _finishMap[10] = 0;

        _nameAddressMap[""] = OFFICIAL;
    }

    function() external payable {}

    function buyByAddress(address referee)
    external
    payable
    {
        uint8 rate = 1;
        if (msg.value == PRICE) {
            rate = 1;
        } else if (msg.value == PRICE * 5) {
            rate = 5;
        } else if (msg.value == PRICE * 10) {
            rate = 10;
        } else {
            require(false);
        }

        resetStage(rate);

        buy(rate);

        overStage(rate);

        if (_addressMap[msg.sender] == 0) {
            if (referee != 0x0000000000000000000000000000000000000000 && referee != msg.sender && _valueMap[referee] > 0) {
                _addressMap[msg.sender] = referee;
            } else {
                _addressMap[msg.sender] = OFFICIAL;
            }
        }
    }

    function setName(string name)
    external
    isExistsOfNameAddressMap(name)
    isExistsOfAddressNameMap
    {
        _nameAddressMap[name] = msg.sender;
        _addressNameMap[msg.sender] = name;

        overStage(1);
        overStage(5);
        overStage(10);
    }

    function getName()
    external
    view
    returns (string)
    {
        return _addressNameMap[msg.sender];
    }


    function buyByName(string name)
    external
    payable
    {
        uint8 rate = 1;
        if (msg.value == PRICE) {
            rate = 1;
        } else if (msg.value == PRICE * 5) {
            rate = 5;
        } else if (msg.value == PRICE * 10) {
            rate = 10;
        } else {
            require(false);
        }

        resetStage(rate);

        buy(rate);

        overStage(rate);

        if (_addressMap[msg.sender] == 0) {

            if (_nameAddressMap[name] == 0) {

                _addressMap[msg.sender] = OFFICIAL;

            } else {

                address referee = _nameAddressMap[name];
                if (referee != 0x0000000000000000000000000000000000000000 && referee != msg.sender && _valueMap[referee] > 0) {

                    _addressMap[msg.sender] = referee;
                } else {

                    _addressMap[msg.sender] = OFFICIAL;
                }
            }
        }
    }


    function buyFromValue(uint8 rate)
    external
    {
        require(rate == 1 || rate == 5 || rate == 10);
        require(_valueMap[msg.sender] >= PRICE * rate);

        resetStage(rate);

        _valueMap[msg.sender] -= PRICE * rate;

        buy(rate);

        overStage(rate);
    }

    function withdraw()
    external
    hasEarnings
    {

        uint256 amount = _valueMap[msg.sender];
        _valueMap[msg.sender] = 0;

        emit BraveWithdraw(msg.sender, amount);

        msg.sender.transfer(amount);

        overStage(1);
        overStage(5);
        overStage(10);
    }

    function forceOverStage()
    external
    {
        overStage(1);
        overStage(5);
        overStage(10);
    }

    function myEarnings()
    external
    view
    hasEarnings
    returns (uint256)
    {
        return _valueMap[msg.sender];
    }

    function getEarnings(address adr)
    external
    view
    returns (uint256)
    {
        return _valueMap[adr];
    }

    function myReferee()
    external
    view
    returns (uint256)
    {
        return _referredMap[msg.sender];
    }

    function getReferee(address adr)
    external
    view
    returns (uint256)
    {
        return _referredMap[adr];
    }

    function getRefereeAddress(address adr)
    external
    view
    returns (address)
    {
        return _addressMap[adr];
    }

    function currentStageData(uint8 rate)
    external
    view
    returns (uint256, uint256)
    {
        require(rate == 1 || rate == 5 || rate == 10);
        uint256 curIndex = _currentMap[rate];
        return (curIndex, _stageMap[rate][curIndex - 1].cnt);
    }

    function getStageData(uint8 rate, uint256 index)
    external
    view
    returns (address, address, address, bool, uint8)
    {
        require(rate == 1 || rate == 5 || rate == 10);
        require(_finishMap[rate] >= index - 1);

        Stage storage finishStage = _stageMap[rate][index - 1];

        return (finishStage.playerMap[0], finishStage.playerMap[1], finishStage.playerMap[2], finishStage.isFinish, finishStage.deadIndex);
    }

    function buy(uint8 rate)
    private
    {
        Stage storage curStage = _stageMap[rate][_currentMap[rate] - 1];

        assert(curStage.cnt < MAX_PLAYERS);

        address player = msg.sender;

        curStage.playerMap[curStage.cnt] = player;
        curStage.cnt++;

        emit BravePlayer(player, rate);

        if (curStage.cnt == MAX_PLAYERS) {
            curStage.blocknumber = block.number;
        }
    }

    function overStage(uint8 rate)
    private
    {
        uint256 curStageIndex = _currentMap[rate];
        uint256 finishStageIndex = _finishMap[rate];

        assert(curStageIndex >= finishStageIndex);

        if (curStageIndex == finishStageIndex) {return;}

        Stage storage finishStage = _stageMap[rate][finishStageIndex];

        assert(!finishStage.isFinish);

        if (finishStage.cnt < MAX_PLAYERS) {return;}

        assert(finishStage.blocknumber != 0);

        if (block.number - 256 <= finishStage.blocknumber) {

            if (block.number == finishStage.blocknumber) {return;}

            uint8 deadIndex = uint8(blockhash(finishStage.blocknumber)) % MAX_PLAYERS;
            address deadPlayer = finishStage.playerMap[deadIndex];
            emit BraveDeadPlayer(deadPlayer, rate);
            finishStage.deadIndex = deadIndex;

            for (uint8 i = 0; i < MAX_PLAYERS; i++) {
                address player = finishStage.playerMap[i];
                if (deadIndex != i) {
                    _valueMap[player] += WIN_VALUE * rate;
                }

                address referee = _addressMap[player];
                _valueMap[referee] += REFEREE_VALUE * rate;
                _referredMap[referee] += REFEREE_VALUE * rate;
            }


            uint256 dividends = p3dContract.myDividends(true);
            if (dividends > 0) {
                p3dContract.withdraw();
                _valueMap[deadPlayer] += dividends;
            }

            p3dContract.buy.value(P3D_VALUE * rate)(address(OFFICIAL_P3D));

        } else {

            for (uint8 j = 0; j < MAX_PLAYERS; j++) {
                _valueMap[finishStage.playerMap[j]] += PRICE * rate;
            }

            emit BraveInvalidateStage(finishStageIndex, rate);
        }

        finishStage.isFinish = true;
        finishStageIndex++;
        _finishMap[rate] = finishStageIndex;
    }

    function resetStage(uint8 rate)
    private
    {
        uint256 curStageIndex = _currentMap[rate];
        if (_stageMap[rate][curStageIndex - 1].cnt == MAX_PLAYERS) {
            _stageMap[rate][curStageIndex] = Stage(0, 0, false, 0);
            curStageIndex++;
            _currentMap[rate] = curStageIndex;
        }
    }
}

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns (uint256);
    function withdraw() external;
    function myDividends(bool _includeReferralBonus) external view returns (uint256);
}