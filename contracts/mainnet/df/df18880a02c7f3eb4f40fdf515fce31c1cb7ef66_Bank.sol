pragma solidity ^0.4.24;

/*
*   gibmireinbier
*   0xA4a799086aE18D7db6C4b57f496B081b44888888
*   <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="8aede3e8e7e3f8efe3e4e8e3eff8caede7ebe3e6a4e9e5e7">[email&#160;protected]</a>
*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface F2mInterface {
    function joinNetwork(address[6] _contract) public;
    // one time called
    function disableRound0() public;
    function activeBuy() public;
    // Dividends from all sources (DApps, Donate ...)
    function pushDividends() public payable;
    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    //function reinvest() public;
    //function buy() public payable;
    function buyFor(address _buyer) public payable;
    function sell(uint256 _tokenAmount) public;
    function exit() public;
    function devTeamWithdraw() public returns(uint256);
    function withdrawFor(address sender) public returns(uint256);
    function transfer(address _to, uint256 _tokenAmount) public returns(bool);
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    function setAutoBuy() public;
    /*==========================================
    =            public FUNCTIONS            =
    ==========================================*/
    // function totalEthBalance() public view returns(uint256);
    function ethBalance(address _address) public view returns(uint256);
    function myBalance() public view returns(uint256);
    function myEthBalance() public view returns(uint256);

    function swapToken() public;
    function setNewToken(address _newTokenAddress) public;
}

interface CitizenInterface {
 
    function joinNetwork(address[6] _contract) public;
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    function devTeamWithdraw() public;

    /*----------  WRITE FUNCTIONS  ----------*/
    function updateUsername(string _sNewUsername) public;
    //Sources: Token contract, DApps
    function pushRefIncome(address _sender) public payable;
    function withdrawFor(address _sender) public payable returns(uint256);
    function devTeamReinvest() public returns(uint256);

    /*----------  READ FUNCTIONS  ----------*/
    function getRefWallet(address _address) public view returns(uint256);
}

interface LotteryInterface {
    function joinNetwork(address[6] _contract) public;
    // call one time
    function activeFirstRound() public;
    // Core Functions
    function pushToPot() public payable;
    function finalizeable() public view returns(bool);
    // bounty
    function finalize() public;
    function buy(string _sSalt) public payable;
    function buyFor(string _sSalt, address _sender) public payable;
    //function withdraw() public;
    function withdrawFor(address _sender) public returns(uint256);

    function getRewardBalance(address _buyer) public view returns(uint256);
    function getTotalPot() public view returns(uint256);
    // EarlyIncome
    function getEarlyIncomeByAddress(address _buyer) public view returns(uint256);
    // included claimed amount
    // function getEarlyIncomeByAddressRound(address _buyer, uint256 _rId) public view returns(uint256);
    function getCurEarlyIncomeByAddress(address _buyer) public view returns(uint256);
    // function getCurEarlyIncomeByAddressRound(address _buyer, uint256 _rId) public view returns(uint256);
    function getCurRoundId() public view returns(uint256);
    // set endRound, prepare to upgrade new version
    function setLastRound(uint256 _lastRoundId) public;
    function getPInvestedSumByRound(uint256 _rId, address _buyer) public view returns(uint256);
    function cashoutable(address _address) public view returns(bool);
    function isLastRound() public view returns(bool);
}

interface DevTeamInterface {
    function setF2mAddress(address _address) public;
    function setLotteryAddress(address _address) public;
    function setCitizenAddress(address _address) public;
    function setBankAddress(address _address) public;
    function setRewardAddress(address _address) public;
    function setWhitelistAddress(address _address) public;

    function setupNetwork() public;
}

contract Bank {
    using SafeMath for uint256;

    mapping(address => uint256) public balance;
    mapping(address => uint256) public claimedSum;
    mapping(address => uint256) public donateSum;
    mapping(address => bool) public isMember;
    address[] public member;

    uint256 public TIME_OUT = 7 * 24 * 60 * 60;
    mapping(address => uint256) public lastClaim;

    CitizenInterface public citizenContract;
    LotteryInterface public lotteryContract;
    F2mInterface public f2mContract;
    DevTeamInterface public devTeamContract;

    constructor (address _devTeam)
        public
    {
        // add administrators here
        devTeamContract = DevTeamInterface(_devTeam);
        devTeamContract.setBankAddress(address(this));
    }

    // _contract = [f2mAddress, bankAddress, citizenAddress, lotteryAddress, rewardAddress, whitelistAddress];
    function joinNetwork(address[6] _contract)
        public
    {
        require(address(citizenContract) == 0x0,"already setup");
        f2mContract = F2mInterface(_contract[0]);
        //bankContract = BankInterface(bankAddress);
        citizenContract = CitizenInterface(_contract[2]);
        lotteryContract = LotteryInterface(_contract[3]);
    }

    // Core functions

    function pushToBank(address _player)
        public
        payable
    {
        uint256 _amount = msg.value;
        lastClaim[_player] = block.timestamp;
        balance[_player] = _amount.add(balance[_player]);
    }

    function collectDividends(address _member)
        public
        returns(uint256)
    {
        require(_member != address(devTeamContract), "no right");
        uint256 collected = f2mContract.withdrawFor(_member);
        claimedSum[_member] += collected;
        return collected;
    }

    function collectRef(address _member)
        public
        returns(uint256)
    {
        require(_member != address(devTeamContract), "no right");
        uint256 collected = citizenContract.withdrawFor(_member);
        claimedSum[_member] += collected;
        return collected;
    }

    function collectReward(address _member)
        public
        returns(uint256)
    {
        require(_member != address(devTeamContract), "no right");
        uint256 collected = lotteryContract.withdrawFor(_member);
        claimedSum[_member] += collected;
        return collected;
    }

    function collectIncome(address _member)
        public
        returns(uint256)
    {
        require(_member != address(devTeamContract), "no right");
        //lastClaim[_member] = block.timestamp;
        uint256 collected = collectDividends(_member) + collectRef(_member) + collectReward(_member);
        return collected;
    }

    function restTime(address _member)
        public
        view
        returns(uint256)
    {
        uint256 timeDist = block.timestamp - lastClaim[_member];
        if (timeDist >= TIME_OUT) return 0;
        return TIME_OUT - timeDist;
    }

    function timeout(address _member)
        public
        view
        returns(bool)
    {
        return lastClaim[_member] > 0 && restTime(_member) == 0;
    }

    function memberLog()
        private
    {
        address _member = msg.sender;
        lastClaim[_member] = block.timestamp;
        if (isMember[_member]) return;
        member.push(_member);
        isMember[_member] = true;
    }

    function cashoutable()
        public
        view
        returns(bool)
    {
        return lotteryContract.cashoutable(msg.sender);
    }

    function cashout()
        public
    {
        address _sender = msg.sender;
        uint256 _amount = balance[_sender];
        require(_amount > 0, "nothing to cashout");
        balance[_sender] = 0;
        memberLog();
        require(cashoutable() && _amount > 0, "need 1 ticket or wait to new round");
        _sender.transfer(_amount);
    }

    // ref => devTeam
    // div => div
    // lottery => div
    function checkTimeout(address _member)
        public
    {
        require(timeout(_member), "member still got time to withdraw");
        require(_member != address(devTeamContract), "no right");
        uint256 _curBalance = balance[_member];
        uint256 _refIncome = collectRef(_member);
        uint256 _divIncome = collectDividends(_member);
        uint256 _rewardIncome = collectReward(_member);
        donateSum[_member] += _refIncome + _divIncome + _rewardIncome;
        balance[_member] = _curBalance;
        f2mContract.pushDividends.value(_divIncome + _rewardIncome)();
        citizenContract.pushRefIncome.value(_refIncome)(0x0);
    }

    function withdraw() 
        public
    {
        address _member = msg.sender;
        collectIncome(_member);
        cashout();
        //lastClaim[_member] = block.timestamp;
    } 

    function lotteryReinvest(string _sSalt, uint256 _amount)
        public
        payable
    {
        address _sender = msg.sender;
        uint256 _deposit = msg.value;
        uint256 _curBalance = balance[_sender];
        uint256 investAmount;
        uint256 collected = 0;
        if (_deposit == 0) {
            if (_amount > balance[_sender]) 
                collected = collectIncome(_sender);
            require(_amount <= _curBalance + collected, "balance not enough");
            investAmount = _amount;//_curBalance + collected;
        } else {
            collected = collectIncome(_sender);
            investAmount = _deposit.add(_curBalance).add(collected);
        }
        balance[_sender] = _curBalance.add(collected + _deposit).sub(investAmount);
        lastClaim [_sender] = block.timestamp;
        lotteryContract.buyFor.value(investAmount)(_sSalt, _sender);
    }

    function tokenReinvest(uint256 _amount) 
        public
        payable
    {
        address _sender = msg.sender;
        uint256 _deposit = msg.value;
        uint256 _curBalance = balance[_sender];
        uint256 investAmount;
        uint256 collected = 0;
        if (_deposit == 0) {
            if (_amount > balance[_sender]) 
                collected = collectIncome(_sender);
            require(_amount <= _curBalance + collected, "balance not enough");
            investAmount = _amount;//_curBalance + collected;
        } else {
            collected = collectIncome(_sender);
            investAmount = _deposit.add(_curBalance).add(collected);
        }
        balance[_sender] = _curBalance.add(collected + _deposit).sub(investAmount);
        lastClaim [_sender] = block.timestamp;
        f2mContract.buyFor.value(investAmount)(_sender);
    }

    // Read
    function getDivBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _amount = f2mContract.ethBalance(_sender);
        return _amount;
    }

    function getEarlyIncomeBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _amount = lotteryContract.getCurEarlyIncomeByAddress(_sender);
        return _amount;
    }

    function getRewardBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _amount = lotteryContract.getRewardBalance(_sender);
        return _amount;
    }

    function getRefBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _amount = citizenContract.getRefWallet(_sender);
        return _amount;
    }

    function getBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _sum = getUnclaimedBalance(_sender);
        return _sum + balance[_sender];
    }

    function getUnclaimedBalance(address _sender)
        public
        view
        returns(uint256)
    {
        uint256 _sum = getDivBalance(_sender) + getRefBalance(_sender) + getRewardBalance(_sender) + getEarlyIncomeBalance(_sender);
        return _sum;
    }

    function getClaimedBalance(address _sender)
        public
        view
        returns(uint256)
    {
        return balance[_sender];
    }

    function getTotalMember() 
        public
        view
        returns(uint256)
    {
        return member.length;
    }
}