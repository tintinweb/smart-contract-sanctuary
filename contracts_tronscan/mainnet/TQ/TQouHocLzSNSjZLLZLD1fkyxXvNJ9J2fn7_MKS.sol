//SourceUnit: mks.sol

pragma solidity 0.5.9;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract MKS is SafeMath {
    uint public currentUserID;

    mapping (uint => User) public users;
    mapping (address => uint) public userWallets;
    uint[2] public levelBase;
    uint public roundsAmount;
    uint public rpCoeff;
    address[2] private techAccounts;
    

    struct User {
        bool exists;
        address wallet;
        uint referrer;
        mapping (uint => uint) uplines;
        mapping (uint => uint[]) referrals;
        mapping (uint => uint) levelExpiry;
    }

    event RegisterUserEvent(address indexed user, address indexed referrer, uint time);
    event BuyLevelEvent(address indexed user, uint indexed level, uint time);
    event TransferEvent(address indexed recipient, address indexed sender, uint indexed amount, uint time, uint recipientID, uint senderID, bool superprofit);
    event LostProfitEvent(address indexed recipient, address indexed sender, uint indexed amount, uint time, uint senderID);

    constructor(address _owner) public {

      techAccounts = [address(0x418277e00bdbfc83e1a97103937d041cd45d6f81d7), address(0x41e655661306a06e87fdcd68b161de8c285c7d8883)];
      currentUserID++;
      levelBase = [450, 600];
      roundsAmount = 12;
      rpCoeff = 2;

      users[currentUserID] =  User({ exists: true, wallet: _owner, referrer: 1});
      userWallets[_owner] = currentUserID;
      emit RegisterUserEvent(_owner, _owner, now);

      for (uint i = 0; i < 24; i++) {
        users[currentUserID].levelExpiry[i] = 1 << 37;
      }
      
      for (uint i = 1; i < 8; i++) {
          users[currentUserID].uplines[i] = 1;
          users[currentUserID].referrals[i] = new uint[](0);
      }
      
      for(uint i = 0; i < techAccounts.length; i++){
          currentUserID++;
          users[currentUserID] =  User({ exists: true, wallet: techAccounts[i], referrer: 1});
          userWallets[techAccounts[i]] = currentUserID;
          emit RegisterUserEvent(techAccounts[i], _owner, now);
          
          for(uint levelID = 0; levelID < 24; levelID++){
             users[currentUserID].levelExpiry[levelID] = 1 << 37;
          }
          
        for (uint j = 1; j < 8; j++) {
        users[currentUserID].uplines[j] = 1;
        users[currentUserID].referrals[j] = new uint[](0);
        users[1].referrals[j].push(currentUserID);
        }
          
      }
      
    }

    function () external payable {
        if (userWallets[msg.sender] == 0) {
            registerUser(userWallets[bytesToAddress(msg.data)]);
        } else {
            buyLevel(0);
        }
    }

    function registerUser(uint _referrer) public payable {
        require(msg.value == levelBase[0] * 1e6, 'Wrong amount');
        require(_referrer > 0 && _referrer <= currentUserID, 'Invalid referrer ID');
        require(userWallets[msg.sender] == 0, 'User already registered');

        currentUserID++;
        users[currentUserID] = User({ exists: true, wallet: msg.sender, referrer: _referrer });
        userWallets[msg.sender] = currentUserID;

        levelUp(0, 1, 1, currentUserID, _referrer);
        
        emit RegisterUserEvent(msg.sender, users[_referrer].wallet, now);
    }

    function buyLevel(uint _upline) public payable {
        uint userID = userWallets[msg.sender];
        require (userID > 0, 'User not registered');
        (uint round, uint level, uint levelID) = getLevel(msg.value);
        
        if (level == 1 && round > 1) {
            bool prev = false;
            for (uint l = levelID - 1; l < levelID; l++) {
                if (users[userID].levelExpiry[l] >= now) {
                    prev = true;
                    break;
                }
                require(prev == true, 'Previous round not active');
            }
        } else {
            for (uint l = level - 1; l > 0; l--) {
                require(users[userID].levelExpiry[levelID - level + l] >= now, 'Previous level not active');
            }
        }

        levelUp(levelID, level, round, userID, _upline);

        if (level == 4 && round < 7 && users[userID].levelExpiry[levelID + 3] <= now) levelUp(levelID + 2, 1, round + 1, userID, _upline);

        if (address(this).balance > 0) msg.sender.transfer(address(this).balance);
    }
    
    function levelUp(uint _levelid, uint _level, uint _round, uint _userid, uint _upline) internal {

        uint duration = 20 days * _round + 70 days;

        if (users[_userid].levelExpiry[_levelid] == 0 || users[_userid].levelExpiry[_levelid] < now) {
            users[_userid].levelExpiry[_levelid] = now + duration;
        } else {
            users[_userid].levelExpiry[_levelid] += duration;
        }
        
        if (_level == 1 && users[_userid].uplines[_round] == 0) {
            if (_upline == 0) _upline = users[_userid].referrer;
            if (_round > 1) _upline = findUplineUp(_upline, _round);
            _upline = findUplineDown(_upline, _round);
            users[_userid].uplines[_round] = _upline;
            users[_upline].referrals[_round].push(_userid);
        }

        payForLevel(_levelid, _userid, _level, _round, false);
        emit BuyLevelEvent(msg.sender, _levelid, now);
    }

    function payForLevel(uint _levelid, uint _userid, uint _height, uint _round, bool _superprofit) internal {
        
        uint referrer = getUserUpline(_userid, _height, _round);
        uint amount = lvlAmount(_levelid);
      
        if (users[referrer].levelExpiry[_levelid] < now) { // does upline have these level?
            if(users[referrer].levelExpiry[_levelid - 1] < now){ // does upline have previous level?
                //no previous level either => emit lost profit event
                emit LostProfitEvent(users[referrer].wallet, msg.sender, amount, now, userWallets[msg.sender]);
                payForLevel(_levelid, referrer, _height, _round, true);
            } else {
                //has previous level => autolevelup
                levelUp(_levelid, _height, _round, referrer, 0);
            }
            return;
        }
        
        if (address(uint160(users[referrer].wallet)).send(amount)) {
            emit TransferEvent(users[referrer].wallet, msg.sender, amount, now, referrer, userWallets[msg.sender], _superprofit);
        }

    }

    function getUserUpline(uint _user, uint _height, uint _round) public view returns (uint) {
        while (_height > 0) {
            _user = users[_user].uplines[_round];
            _height--;
        }
        return _user;
    }

    function findUplineUp(uint _user, uint _round) public view returns (uint) {
        while (users[_user].uplines[_round] == 0) {
            _user = users[_user].uplines[1];
        }
        return _user;
    }

    function findUplineDown(uint _user, uint _round) public view returns (uint) {
      if (users[_user].referrals[_round].length < 2) {
        return _user;
      }

      uint[1024] memory referrals;
      referrals[0] = users[_user].referrals[_round][0];
      referrals[1] = users[_user].referrals[_round][1];

      uint referrer;

      for (uint i = 0; i < 1024; i++) {
        if (users[referrals[i]].referrals[_round].length < 2) {
          referrer = referrals[i];
          break;
        }

        if (i >= 512) {
          continue;
        }

        referrals[(i+1)*2] = users[referrals[i]].referrals[_round][0];
        referrals[(i+1)*2+1] = users[referrals[i]].referrals[_round][1];
      }

      require(referrer != 0, 'Referrer not found');
      return referrer;
    }


    function getLevel(uint _amount) public view returns(uint, uint, uint) {
        require(_amount > 0, 'Wrong amount');
        uint amount = _amount / 1e6;
        uint level = 0;
        uint round = 0;
        uint levelID = 0;
        uint tmp;
        for(uint i = 0; i < levelBase.length; i++) {
            if(amount % levelBase[i] != 0) continue;
            tmp = amount / levelBase[i];
            if((tmp&(tmp - 1)) != 0) continue;
            round = calc_log2(tmp) + 1;
            level = i + 1;
            levelID = (round - 1) * levelBase.length + i;
            break;
        }
        require(level > 0, 'Wrong amount');
        return (round, level, levelID);
    }

    function lvlAmount (uint _levelID) public view returns(uint) {
         uint level = _levelID % levelBase.length;
         uint round = (_levelID - level) / levelBase.length;
         uint price = (rpCoeff ** round) * levelBase[level];
        return price * 1e6;
    }

    function getReferralTree(uint _user, uint _treeLevel, uint _round) external view returns (uint[] memory, uint[] memory, uint) {

        uint tmp = 2 ** (_treeLevel + 1) - 2;
        uint[] memory ids = new uint[](tmp);
        uint[] memory lvl = new uint[](tmp);

        ids[0] = (users[_user].referrals[_round].length > 0)? users[_user].referrals[_round][0]: 0;
        ids[1] = (users[_user].referrals[_round].length > 1)? users[_user].referrals[_round][1]: 0;
        lvl[0] = getMaxLevel(ids[0], _round);
        lvl[1] = getMaxLevel(ids[1], _round);

        for (uint i = 0; i < (2 ** _treeLevel - 2); i++) {
            tmp = i * 2 + 2;
            ids[tmp] = (users[ids[i]].referrals[_round].length > 0)? users[ids[i]].referrals[_round][0]: 0;
            ids[tmp + 1] = (users[ids[i]].referrals[_round].length > 1)? users[ids[i]].referrals[_round][1]: 0;
            lvl[tmp] = getMaxLevel(ids[tmp], _round);
            lvl[tmp + 1] = getMaxLevel(ids[tmp + 1], _round);
        }
        
        uint curMax = getMaxLevel(_user, _round);

        return(ids, lvl, curMax);
    }

    function getMaxLevel(uint _user, uint _round) private view returns (uint){
        uint max = 0;
        if (_user == 0) return 0;
        if (!users[_user].exists) return 0;
        for (uint i = 1; i <= levelBase.length; i++) {
            if (users[_user].levelExpiry[_round * levelBase.length - i] > now) {
                max = levelBase.length - i + 1;
                break;
            }
        }
        return max;
    }
    
    function getUplines(uint _user, uint _round) public view returns (uint[2] memory uplines, address[2] memory uplinesWallets) {
        for(uint i = 0; i < levelBase.length; i++) {
            _user = users[_user].uplines[_round];
            uplines[i] = _user;
            uplinesWallets[i] = users[_user].wallet;
        }
    }

    function getUserLevels(uint _user) external view returns (uint[24] memory levels) {
        for (uint i = 0; i < levelBase.length * roundsAmount; i++) {
            levels[i] = users[_user].levelExpiry[i];
        }
    }

    function bytesToAddress(bytes memory _addr) private pure returns (address addr) {
        assembly {
            addr := mload(add(_addr, 20))
        }
    }
    
    function calc_log2(uint x) private pure returns (uint y){
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }  
    }
}