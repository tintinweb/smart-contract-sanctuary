pragma solidity ^0.4.24;

contract F3Devents {
    // 注册
    event onNewName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 amountPaid,
        uint256 timeStamp
    );
    
    // 购买
    event onEndTx
    (
        uint256 compressedData,     
        uint256 compressedIDs,      
        bytes32 playerName,
        address playerAddress,
        uint256 ethIn,
        uint256 keysBought,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount,
        uint256 potAmount,
        uint256 airDropPot
    );
    
	// 提取
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );
    
    // 提取触发结束
    event onWithdrawAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
    );
    
    // 购买触发结束.
    event onBuyAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
    );
    
    // 使用金库购买触发结束.
    event onReLoadAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
    );
    
    // 被推荐人付费
    event onAffiliatePayout
    (
        uint256 indexed affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );
}

contract modularLong is F3Devents {}

contract FoMo3Dlong is modularLong {
    using SafeMath for *;
    using NameFilter for string;
    using F3DKeysCalcLong for uint256;
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0xa6fd21aa986247357f404aa37a7bc90809da1ad8);


    address public ceo;
    address public cfo; 
    string constant public name = "Must Be Hit 4D";
    string constant public symbol = "MBT4D";
    uint256 private rndExtra_ = 30 seconds;       
    uint256 private rndGap_ = 30 seconds;         
    uint256 constant private rndInit_ = 1 hours;                // 初始时间
    uint256 constant private rndInc_ = 30 seconds;              // 每一个完整KEY增加
    uint256 constant private rndMax_ = 12 hours;                // 最多允许增加到

    uint256 public airDropPot_;             // 空投
    uint256 public airDropTracker_ = 0;     
    uint256 public rID_;  

    mapping (address => uint256) public pIDxAddr_;          // 玩家地址 =》 玩家ID
    mapping (bytes32 => uint256) public pIDxName_;          // 玩家用户名=》 玩家ID
    mapping (uint256 => F3Ddatasets.Player) public plyr_;   // 玩家ID =》 玩家数据
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;    // 玩家ID =》 第几轮 =》 玩家当轮数据
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // 玩家ID =》 玩家用户名 =》 True/False

    mapping (uint256 => F3Ddatasets.Round) public round_;   // 第几轮 =》 本轮数据
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;      // 第几轮=》TeamID=>该组数据

    mapping (uint256 => F3Ddatasets.TeamFee) public fees_;          // TeamID => 购买分发比例配置
    mapping (uint256 => F3Ddatasets.PotSplit) public potSplit_;     // TeamID => 结束分发比例配置


    constructor()
        public
    {
        ceo = msg.sender;
        cfo = msg.sender;
		//  青龙 奖池 30%, 所有持KEY玩家 -30%, 推荐 - 30%, 开发团队 - 5%, 空投 - 5%
        fees_[0] = F3Ddatasets.TeamFee(30,0);  
        //  白虎 奖池 25%, 所有持KEY玩家 -60%, 推荐 - 10%, 开发团队 - 5%, 空投 - 5%
        fees_[1] = F3Ddatasets.TeamFee(60,0);   
        //  朱雀 奖池 60%, 所有持KEY玩家 -20%, 推荐 - 10%, 开发团队 - 5%, 空投 - 5%
        fees_[2] = F3Ddatasets.TeamFee(20,0);   
        //  玄武 奖池 40%, 所有持KEY玩家 -40%, 推荐 - 10%, 开发团队 - 5%, 空投 - 5%
        fees_[3] = F3Ddatasets.TeamFee(40,0);   
        
        // 青龙 55 - 大赢家 25 -> 所有持KEY玩家 15-> 下一轮 5-> 开发团队
        potSplit_[0] = F3Ddatasets.PotSplit(25,0); 
        // 白虎 55 - 大赢家 30 -> 所有持KEY玩家 10-> 下一轮 5-> 开发团队
        potSplit_[1] = F3Ddatasets.PotSplit(30,0);  
        // 朱雀 55 - 大赢家 10 -> 所有持KEY玩家 30-> 下一轮 5-> 开发团队
        potSplit_[2] = F3Ddatasets.PotSplit(10,0);  
        // 玄武 55 - 大赢家 20 -> 所有持KEY玩家 20-> 下一轮 5-> 开发团队
        potSplit_[3] = F3Ddatasets.PotSplit(20,0);  
	}

    modifier isActivated() {
        require(activated_ == true, "Not Active!"); 
        _;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "Not Human");
        _;
    }

    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "Too Less");
        require(_eth <= 100000000000000000000000, "Too More");
        _;    
    }
    
    // 使用该玩家最近一次购买数据再次购买
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        uint256 _pID = pIDxAddr_[msg.sender];
        buyCore(_pID, plyr_[_pID].laff, 2, _eventData_);
    }

    function modCEOAddress(address newCEO) 
        isHuman() 
        public
    {
        require(address(0) != newCEO, "CEO Can not be 0");
        require(ceo == msg.sender, "only ceo can modify ceo");
        ceo = newCEO;
    }

    function modCFOAddress(address newCFO) 
        isHuman() 
        public
    {
        require(address(0) != newCFO, "CFO Can not be 0");
        require(cfo == msg.sender, "only cfo can modify cfo");
        cfo = newCFO;
    }
    
    // 通过推荐者ID购买
    function buyXid(uint256 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        uint256 _pID = pIDxAddr_[msg.sender];
        
        if (_affCode == 0 || _affCode == _pID)
        {
            _affCode = plyr_[_pID].laff;    
        } 
        else if (_affCode != plyr_[_pID].laff) 
        {
            plyr_[_pID].laff = _affCode;
        }

        _team = verifyTeam(_team);
        buyCore(_pID, _affCode, _team, _eventData_);
    }

    // 通过推荐者地址购买
    function buyXaddr(address _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID;
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            _affID = plyr_[_pID].laff;
        } 
        else 
        {
            _affID = pIDxAddr_[_affCode];
            if (_affID != plyr_[_pID].laff)
            {
                plyr_[_pID].laff = _affID;
            }
        }
        
        _team = verifyTeam(_team);
        buyCore(_pID, _affID, _team, _eventData_);
    }
    // 通过推荐者名字购买
    function buyXname(bytes32 _affCode, uint256 _team)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        F3Ddatasets.EventReturns memory _eventData_ = determinePID(_eventData_);
        
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID;
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name)
        {
            _affID = plyr_[_pID].laff;
        } 
        else 
        {
            _affID = pIDxName_[_affCode];
            if (_affID != plyr_[_pID].laff)
            {
                plyr_[_pID].laff = _affID;
            }
        }
        
        _team = verifyTeam(_team);
        buyCore(_pID, _affID, _team, _eventData_);
    }
    
    // 通过小金库和推荐者ID购买
    function reLoadXid(uint256 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        F3Ddatasets.EventReturns memory _eventData_;
        
        uint256 _pID = pIDxAddr_[msg.sender];
        if (_affCode == 0 || _affCode == _pID)
        {
            _affCode = plyr_[_pID].laff;
        } 
        else if (_affCode != plyr_[_pID].laff) 
        {
            plyr_[_pID].laff = _affCode;
        }

        _team = verifyTeam(_team);
        reLoadCore(_pID, _affCode, _team, _eth, _eventData_);
    }
    
    // 通过小金库和推荐者地址购买
    function reLoadXaddr(address _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        F3Ddatasets.EventReturns memory _eventData_;
        
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID;
        if (_affCode == address(0) || _affCode == msg.sender)
        {
            _affID = plyr_[_pID].laff;
        } 
        else 
        {
            _affID = pIDxAddr_[_affCode];
            if (_affID != plyr_[_pID].laff)
            {
                plyr_[_pID].laff = _affID;
            }
        }
        _team = verifyTeam(_team);
        reLoadCore(_pID, _affID, _team, _eth, _eventData_);
    }

    // 通过小金库和推荐者名字购买
    function reLoadXname(bytes32 _affCode, uint256 _team, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
        F3Ddatasets.EventReturns memory _eventData_;
        
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _affID;
        if (_affCode == &#39;&#39; || _affCode == plyr_[_pID].name)
        {
            _affID = plyr_[_pID].laff;
        } 
        else 
        {
            _affID = pIDxName_[_affCode];
            if (_affID != plyr_[_pID].laff)
            {
                plyr_[_pID].laff = _affID;
            }
        }
        
        _team = verifyTeam(_team);
        reLoadCore(_pID, _affID, _team, _eth, _eventData_);
    }

    // 提取
    function withdraw()
        isActivated()
        isHuman()
        public
    {
        uint256 _rID = rID_;
        uint256 _now = now;
        uint256 _pID = pIDxAddr_[msg.sender];
        uint256 _eth;
        
        // 是否触发结束
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            F3Ddatasets.EventReturns memory _eventData_;
        	round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
            _eth = withdrawEarnings(_pID);
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);    
        
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
        
            emit F3Devents.onWithdrawAndDistribute
            (
                msg.sender, 
                plyr_[_pID].name, 
                _eth, 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.P3DAmount, 
                _eventData_.genAmount
            );
        } 
        else 
        {
            _eth = withdrawEarnings(_pID);
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);
            emit F3Devents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }
    
    // 通过推荐者ID注册
    function registerNameXID(string _nameString, uint256 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXIDFromDapp.value(_paid)(_addr, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];
        
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }
    
    // 通过推荐者地址注册
    function registerNameXaddr(string _nameString, address _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];

        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    // 通过推荐者名字注册
    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXnameFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);
        
        uint256 _pID = pIDxAddr_[_addr];

        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    // 获取单价
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
        
        uint256 _rID = rID_;
        uint256 _now = now;
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else 
            return ( 7500000000000000 );
    }
    
    // 获得剩余时间（秒）
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
        uint256 _rID = rID_;
        uint256 _now = now;
        
        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + rndGap_)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt + rndGap_).sub(_now) );
        else
            return(0);
    }
    
    // 查看玩家小金库
    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256)
    {
        
        uint256 _rID = rID_;
        
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(48)) / 100 ),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   ),
                    plyr_[_pID].aff
                );
            } else {
                return
                (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  ),
                    plyr_[_pID].aff
                );
            }
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
            );
        }
    }
    
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
        private
        view
        returns(uint256)
    {
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }
    
    // 获得当前轮信息
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        uint256 _rID = rID_;
        
        return
        (
            round_[_rID].ico,               //0
            _rID,                           //1
            round_[_rID].keys,              //2
            round_[_rID].end,               //3
            round_[_rID].strt,              //4
            round_[_rID].pot,               //5
            (round_[_rID].team + (round_[_rID].plyr * 10)),     //6
            plyr_[round_[_rID].plyr].addr,  //7
            plyr_[round_[_rID].plyr].name,  //8
            rndTmEth_[_rID][0],             //9
            rndTmEth_[_rID][1],             //10
            rndTmEth_[_rID][2],             //11
            rndTmEth_[_rID][3],             //12
            airDropTracker_ + (airDropPot_ * 1000)              //13
        );
    }

    // 获得玩家信息
    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        
        uint256 _rID = rID_;
        if (_addr == address(0))
        {
            _addr == msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];
        
        return
        (
            _pID,                               //0
            plyr_[_pID].name,                   //1
            plyrRnds_[_pID][_rID].keys,         //2
            plyr_[_pID].win,                    //3
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),       //4
            plyr_[_pID].aff,                    //5
            plyrRnds_[_pID][_rID].eth           //6
        );
    }

    // 核心购买逻辑
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        uint256 _rID = rID_;
        uint256 _now = now;
        
        // 未结束
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
            core(_rID, _pID, msg.value, _affID, _team, _eventData_);    
        } 
        else 
        {
            // 已结束但未执行
            if (_now > round_[_rID].end && round_[_rID].ended == false) 
            {
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);
             
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                
                emit F3Devents.onBuyAndDistribute
                (
                    msg.sender, 
                    plyr_[_pID].name, 
                    msg.value, 
                    _eventData_.compressedData, 
                    _eventData_.compressedIDs, 
                    _eventData_.winnerAddr, 
                    _eventData_.winnerName, 
                    _eventData_.amountWon, 
                    _eventData_.newPot, 
                    _eventData_.P3DAmount, 
                    _eventData_.genAmount
                );
            }
            
            // 玩家的钱放入小金库
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }
    
    // 使用小金库购买核心逻辑
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _team, uint256 _eth, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        
        uint256 _rID = rID_;
        uint256 _now = now;
        
        // 未结束
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0))) 
        {
            // 取出玩家小金库
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);
            core(_rID, _pID, _eth, _affID, _team, _eventData_);
        } 
        // 已结束但未执行
        else if (_now > round_[_rID].end && round_[_rID].ended == false) 
        {
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);
            
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                
            emit F3Devents.onReLoadAndDistribute
            (
                msg.sender, 
                plyr_[_pID].name, 
                _eventData_.compressedData, 
                _eventData_.compressedIDs, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot, 
                _eventData_.P3DAmount, 
                _eventData_.genAmount
            );
        }
    }
    
    // 真正的购买在这里
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);
        
        // 前期购买限制
        if (round_[_rID].eth < 100000000000000000000 && plyrRnds_[_pID][_rID].eth.add(_eth) > 1000000000000000000)
        {
            uint256 _availableLimit = (1000000000000000000).sub(plyrRnds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }
        
        // 最少数额
        if (_eth > 1000000000) 
        {
            // 购买的KEY数量
            uint256 _keys = (round_[_rID].eth).keysRec(_eth);
            // 至少要有一个KEY才可以领头
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys, _rID);
                if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;  
                if (round_[_rID].team != _team)
                    round_[_rID].team = _team; 
                _eventData_.compressedData = _eventData_.compressedData + 100;
            }
            
            // 判断空投
            if (_eth >= 100000000000000000)
            {
                airDropTracker_++;
                if (airdrop() == true)
                {
                    uint256 _prize;
                    if (_eth >= 10000000000000000000)
                    {
                        _prize = ((airDropPot_).mul(75)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        airDropPot_ = (airDropPot_).sub(_prize);
                        _eventData_.compressedData += 300000000000000000000000000000000;
                    } 
                    else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) 
                    {
                        _prize = ((airDropPot_).mul(50)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        airDropPot_ = (airDropPot_).sub(_prize);
                        _eventData_.compressedData += 200000000000000000000000000000000;
                    } 
                    else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) 
                    {
                        _prize = ((airDropPot_).mul(25)) / 100;
                        plyr_[_pID].win = (plyr_[_pID].win).add(_prize);
                        airDropPot_ = (airDropPot_).sub(_prize);
                        _eventData_.compressedData += 300000000000000000000000000000000;
                    }
                    _eventData_.compressedData += 10000000000000000000000000000000;
                    _eventData_.compressedData += _prize * 1000000000000000000000000000000000;
                    airDropTracker_ = 0;
                }
            }
    
            
            _eventData_.compressedData = _eventData_.compressedData + (airDropTracker_ * 1000);
            // 更新数据
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][_team] = _eth.add(rndTmEth_[_rID][_team]);
            // 各种分成，内部和外部
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, _team, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, _team, _keys, _eventData_);
            
            endTx(_pID, _team, _eth, _keys, _eventData_);
        }
    }

    // 计算未统计的分成
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }
    
    // 给定以太的数量，返回KEY的数量
    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
        uint256 _now = now;
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].eth).keysRec(_eth) );
        else
            return ( (_eth).keys() );
    }
    
    // 计算X个KEY需要多少ETH
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
        uint256 _rID = rID_;
        uint256 _now = now;
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( (round_[_rID].keys.add(_keys)).ethRec(_keys) );
        else 
            return ( (_keys).eth() );
    }

    /* test use only
    function setEndAfterSecond(uint256 extraSecond)
        isActivated()
        isHuman()
        public
    {
        require((extraSecond > 0 && extraSecond <= 86400), "TIME Out Of Range");
        require( ceo == msg.sender, "only ceo can setEnd" );
        round_[rID_].end = now + extraSecond;
    }
    */
    
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff)
        external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if (pIDxAddr_[_addr] != _pID)
            pIDxAddr_[_addr] = _pID;
        if (pIDxName_[_name] != _pID)
            pIDxName_[_name] = _pID;
        if (plyr_[_pID].addr != _addr)
            plyr_[_pID].addr = _addr;
        if (plyr_[_pID].name != _name)
            plyr_[_pID].name = _name;
        if (plyr_[_pID].laff != _laff)
            plyr_[_pID].laff = _laff;
        if (plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }
    
    function receivePlayerNameList(uint256 _pID, bytes32 _name)
        external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }   
        
    // 获取玩家PID
    function determinePID(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        if (_pID == 0)
        {
            _pID = PlayerBook.getPlayerID(msg.sender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);
            
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;
            
            if (_name != "")
            {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }
            
            if (_laff != 0 && _laff != _pID)
                plyr_[_pID].laff = _laff;

            _eventData_.compressedData = _eventData_.compressedData + 1;
        } 
        return (_eventData_);
    }
    
    function verifyTeam(uint256 _team)
        private
        pure
        returns (uint256)
    {
        if (_team < 0 || _team > 3)
            return(2);
        else
            return(_team);
    }
    
    function managePlayer(uint256 _pID, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        // 玩家以前玩家。更新一下小金库
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);
        
        plyr_[_pID].lrnd = rID_;

        _eventData_.compressedData = _eventData_.compressedData + 10;
        
        return(_eventData_);
    }
    
    // 结束
    function endRound(F3Ddatasets.EventReturns memory _eventData_)
        private
        returns (F3Ddatasets.EventReturns)
    {
        
        uint256 _rID = rID_;
        
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;
        
        uint256 _pot = round_[_rID].pot;
        
        uint256 _win = (_pot.mul(55)) / 100;
        uint256 _com = (_pot / 20);
        uint256 _gen = (_pot.mul(potSplit_[_winTID].gen)) / 100;
        uint256 _p3d = (_pot.mul(potSplit_[_winTID].p3d)) / 100;
        uint256 _res = (((_pot.sub(_win)).sub(_com)).sub(_gen)).sub(_p3d);
        
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }
        
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

        _com = _com.add(_p3d);
        cfo.transfer(_com);
        
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
        
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.P3DAmount = _p3d;
        _eventData_.newPot = _res;
        
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot = _res;
        
        return(_eventData_);
    }
    
    // 更新玩家未统计的分成
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private 
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }
    
    // 更新本轮时间
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
        uint256 _now = now;
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(round_[_rID].end);
        
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now);
    }
    
    // 空投是否触发判断
    function airdrop()
        private 
        view 
        returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        if((seed - ((seed / 1000) * 1000)) < airDropTracker_)
            return(true);
        else
            return(false);
    }

    
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
        // 5% 开发团队
        uint256 _com = _eth / 20;
        // 10 推荐人
        uint256 _aff = _eth / 10;
        // 第一队推荐人分成30%
        if (_team == 0 ) {
            _aff = _eth.mul(30) / 100;
        }
        
        // MODIFY 如果推荐人不存在 10% -> _com
        if (_affID != _pID && plyr_[_affID].name != &#39;&#39;) {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit F3Devents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _com = _com.add(_aff);
        }

        cfo.transfer(_com);
        
        return(_eventData_);
    }

    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
        returns(F3Ddatasets.EventReturns)
    {
        uint256 _gen = (_eth.mul(fees_[_team].gen)) / 100;
        
        // 5% 到空投
        uint256 _air = (_eth / 20);
        airDropPot_ = airDropPot_.add(_air);
        if (_team == 0){
            _eth = _eth.sub(((_eth.mul(40)) / 100).add((_eth.mul(fees_[_team].p3d)) / 100));
        }else{
            _eth = _eth.sub(((_eth.mul(20)) / 100).add((_eth.mul(fees_[_team].p3d)) / 100));
        }
        
        uint256 _pot = _eth.sub(_gen);
        
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);
        
        round_[_rID].pot = _pot.add(_dust).add(round_[_rID].pot);
        
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _pot;
        
        return(_eventData_);
    }

    // 更新玩家已统计的分成
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {

        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);
        
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }
    

    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
        updateGenVault(_pID, plyr_[_pID].lrnd);
        
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }
    
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);
        
        emit F3Devents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            plyr_[_pID].name,
            msg.sender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.P3DAmount,
            _eventData_.genAmount,
            _eventData_.potAmount,
            airDropPot_
        );
    }

    bool public activated_ = false;
    function activate()
        public
    {
        require( msg.sender == ceo, "ONLY ceo CAN activate" );
        require(activated_ == false, "Already Activated");
        
        activated_ = true;
        
        rID_ = 1;
        round_[1].strt = now + rndExtra_ - rndGap_;
        round_[1].end = now + rndInit_ + rndExtra_;
    }
}

library F3Ddatasets {
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner address
        bytes32 winnerName;         // winner name
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 P3DAmount;          // amount distributed to p3d
        uint256 genAmount;          // amount distributed to gen
        uint256 potAmount;          // amount added to pot
    }
    struct Player {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 aff;    // affiliate vault
        uint256 lrnd;   // last round played
        uint256 laff;   // last affiliate id used
    }
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask 
        uint256 ico;    // ICO phase investment
    }
    struct Round {
        uint256 plyr;   // pID of player in lead
        uint256 team;   // tID of team in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 keys;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask;   // global mask
        uint256 ico;    // total eth sent in during ICO phase
        uint256 icoGen; // total eth for gen during ICO phase
        uint256 icoAvg; // average key price for ICO phase
    }
    struct TeamFee {
        uint256 gen;    // % of buy in thats paid to key holders of current round
        uint256 p3d;    // % of buy in thats paid to p3d holders
    }
    struct PotSplit {
        uint256 gen;    // % of pot thats paid to key holders of current round
        uint256 p3d;    // % of pot thats paid to p3d holders
    }
}

library F3DKeysCalcLong {
    using SafeMath for *;
    // 根据ETH计算KEY
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }
    
    // 根据KEY算ETH
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    // 根据ETH算KEY
    function keys(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(31250000000000000000000000000)).add(56249882812561035156250000000000000000000000000000000000000000000000)).sqrt()).sub(7499992187500000000000000000000000)) / (15625000000);
    }
    
    // 根据KEY算ETH
    function eth(uint256 _keys) 
        internal
        pure
        returns(uint256)  
    {
        return ((7812500000).mul(_keys.sq()).add((7499992187500000).mul(_keys.mul(1000000000000000000)))) / ((1000000000000000000).sq()) ;
    }
}

interface PlayerBookInterface {
    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerName(uint256 _pID) external view returns (bytes32);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getNameFee() external view returns (uint256);
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable returns(bool, uint256);
}

library NameFilter {
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        require (_length <= 32 && _length > 0, "Invalid Length");
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "Can NOT start with SPACE");
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "CAN NOT Start With 0x");
            require(_temp[1] != 0x58, "CAN NOT Start With 0X");
        }
        
        bool _hasNonNumber;
        
        for (uint256 i = 0; i < _length; i++)
        {
            // 大写转小写
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                _temp[i] = byte(uint(_temp[i]) + 32);
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    _temp[i] == 0x20 || 
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "Include Illegal Characters!"
                );
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, 
                    "ONLY One Space Allowed");
                
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "All Numbers Not Allowed");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "Mul Failed");
        return c;
    }
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "Sub Failed");
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "Add Failed");
        return c;
    }
    
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
}