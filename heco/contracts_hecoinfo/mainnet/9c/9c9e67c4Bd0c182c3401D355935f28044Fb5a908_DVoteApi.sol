/**
 *Submitted for verification at hecoinfo.com on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

struct Poll {
    uint256 pollId;
    address tokenContract;
    uint256 dropAmount;
    uint256 dropNumber;
    uint256 foundationPrizePool;
    uint256 additionalPrizePool;
    uint256 numberOfVote;
    uint256 amountOfVote;
    string title;
    string context;
    string[] url;
    string[] options;
    uint earningsRatio; // denominator 10000
    uint creationTime;
    uint endTime;
    uint level;
    bool isQualified;
    bool isFinished;
    address sender;
}

struct PollSimple {
    uint256 pollId;
    address tokenContract;
    string title;
    string context;
    uint creationTime;
    uint endTime;
    uint level;
    bool isQualified;
    address sender;
}

struct PollVoterRecord {
    uint256 voterId;
    uint256 pollId;
    uint256 optionId;
    uint256 amount;
    uint256 income;
    uint time;
    bool isFinished;
    address sender;
}

contract ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library StringHelper {

    function append(string memory _str1, string memory _str2, string memory _str3) internal pure returns (string memory)
    {
        bytes memory _str1ToBytes = bytes(_str1);
        bytes memory _str2ToBytes = bytes(_str2);
        bytes memory _str3ToBytes = bytes(_str3);

        string memory ret = new string(_str1ToBytes.length + _str2ToBytes.length + _str3ToBytes.length);
        bytes memory retTobytes = bytes(ret);

        uint index = 0;
        for (uint i = 0; i < _str1ToBytes.length; i++) 
            retTobytes[index++] = _str1ToBytes[i];

        for (uint i = 0; i < _str2ToBytes.length; i++) 
            retTobytes[index++] = _str2ToBytes[i];

        for (uint i = 0; i < _str3ToBytes.length; i++) 
            retTobytes[index++] = _str3ToBytes[i];

        return string(retTobytes);
    }
}

interface DVote {

    function verifyTokenContract(address __tokenContract, address __sender, uint256 __amount) external returns (bool);

    function createPoll(string memory __title, address __tokenContract, uint256 __dropAmount, uint256 __dropNumber, string memory __context, uint __endTime, string[] memory __options, string[] memory __url, uint __level, uint256 __additionalPrizePool, address __sender) external returns (bool);

    function vote(uint256 __pollId, uint __index, uint256 __amount, address __sender) external returns (bool);

    function receiveVotingProfit(uint256 __voterId, address __sender) external returns (uint256 amount, uint256 income);

    function endPoll(uint256 __pollId) external;

    function shielding(uint256 __pollId) external;

    function setTdexTokenManager(address __tdexTokenManager) external;

    function subTdexToken(uint256 __pollId, address __sender) external;

    /*****************************************/

    function isVerifyTokenContractResults(address __tokenContract) external view returns (bool);

    function getPollsLength() external view returns (uint256);

    function getPoll(uint256 __pollId) external view returns (Poll memory);

    function getPollVotingInfo(uint256 __pollId) external view returns (uint256[] memory numberOfOptions, uint256[] memory amountOfOptions);

    function getPollVotingDetailCount10Desc(uint256 __pollId, uint256 __index) external view returns(uint256[10] memory);

    function getUserVoteStatistical(address __sender) external view returns (uint256 totalAmount, uint256 totalIncome, uint256 totalNumber);

    function getUserVoteIdOfPolls(uint256 __pollId, address __sender) external view returns (uint256);

    function getUserCreatePollRecordsLength(address __sender) external view returns (uint256);

    function getUserCreatePollRecord(address __sender, uint __index) external view returns (uint256);

    function getPollsInTheVoteLength() external view returns (uint);

    function getPollsInTheVote(uint __index) external view returns (uint256);

    function getPollsVotingClosedLength() external view returns (uint256);

    function getPollsVotingClosed(uint __index) external view returns (uint256);

    function getPollVoterRecordsLength() external view returns (uint256);

    function getPollVoterRecord(uint256 __voterId) external view returns (PollVoterRecord memory);

    function getUserVoterRecordsLength(address __sender) external view returns (uint256);

    function getUserVoterRecords(address __sender, uint __index) external view returns (uint256);

    function getDVoteInfo() external view returns (uint256 totalPublisherConsumption, uint256 totalPoolConsumption, uint256 totalVoterConsumption, uint256 balanceOf);
}

contract DVoteApi {

    address private _owner;
    address private _admin;
    address private _body;
    DVote private _dvote;

    mapping(address => bool) private _blackList;

    bool private _running;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender || _owner == msg.sender, "caller is not the admin");
        _;
    }

    function setAdmin(address __admin) external onlyOwner
    {
        _admin = __admin;
    }

    function add(address __sender) external onlyAdmin
    {
        _blackList[__sender] = true;
    }

    function remove(address __sender) external onlyAdmin
    {
        require(_blackList[__sender] == true, "no");
        _blackList[__sender] = false;
        delete _blackList[__sender];
    }

    function setTdexTokenManager(address __tdexTokenManager) external onlyAdmin
    {
        return _dvote.setTdexTokenManager(__tdexTokenManager);
    }

    function setRunning(bool __running) external onlyOwner
    {
        _running = __running;
    }

    constructor (address __dvote) {
        _owner = msg.sender;
        _body = __dvote;
        _dvote = DVote(__dvote);
        _running = true;
    }

    function verifyTokenContract(address __tokenContract, uint256 __amount) external returns (bool)
    {
        return _dvote.verifyTokenContract(__tokenContract, msg.sender, __amount);
    }

    function createTDexPoll(address __tokenContract, uint256 __dropAmount, uint256 __dropNumber, string memory __context, string memory __url) external returns (bool)
    {
        require(_running == true, "Suspended!");
        require(_blackList[msg.sender] == false, "no");
        string memory __title = StringHelper.append("Vote for ", ERC20(__tokenContract).name(), "/USDT on TDEX");
        uint __endTime = block.timestamp + 86400 * 3;
        // uint __endTime = block.timestamp + 60 * 30; // TEST
        string[] memory __options = new string[](2);
        __options[0] = "Agree";
        __options[1] = "Disagree";
        string[] memory _url = new string[](1);
        _url[0] = __url;
        return _dvote.createPoll(__title, __tokenContract, __dropAmount, __dropNumber, __context, __endTime, __options, _url, 2, 0, msg.sender);
        // return _dvote.createPoll(__title, __tokenContract, __dropAmount, __dropNumber, __context, __endTime, __options, _url, 5, 0, msg.sender);
    }

    function createPoll(string memory __title, string memory __context, uint __endTime, string[] memory __options, string[] memory __url, uint __level, uint256 __additionalPrizePool) external returns (bool)
    {
        require(_running == true, "Suspended!");
        require(_blackList[msg.sender] == false, "no");
        return _dvote.createPoll(__title, address(0), 0, 0, __context, __endTime, __options, __url, __level, __additionalPrizePool, msg.sender);
    }

    function vote(uint256 __pollId, uint __index, uint256 __amount) external returns (bool)
    {
        return _dvote.vote(__pollId, __index, __amount, msg.sender);
    }

    function receiveVotingProfit(uint256 __voterId) external returns (uint256 amount, uint256 income)
    {
        return _dvote.receiveVotingProfit(__voterId, msg.sender);
    }

    function subTdexToken(uint256 __pollId) external
    {
        _dvote.subTdexToken(__pollId, msg.sender);
    }

    function endPoll(uint256 __pollId) external onlyAdmin
    {
        _dvote.endPoll(__pollId);
    }

    function shielding(uint256 __pollId) external onlyAdmin
    {
        _dvote.shielding(__pollId);
    }

    /*****************************************/

    function getDVoteAddress() external view returns (address)
    {
        return _body;
    }

    function getPollsLength() external view returns (uint256)
    {
        return _dvote.getPollsLength();
    }

    function getPollInfo(uint256 __pollId) external view returns (Poll memory poll, uint256[] memory numberOfOptions, uint256[] memory amountOfOptions)
    {
        poll = _dvote.getPoll(__pollId);
        (numberOfOptions, amountOfOptions) = _dvote.getPollVotingInfo(__pollId);
    }

    function getPollVotingDetailCount10Desc(uint256 __pollId, uint256 __index) external view returns(PollVoterRecord[10] memory list)
    {
        uint256[10] memory voterIds = _dvote.getPollVotingDetailCount10Desc(__pollId, __index);
        for (uint i=0; i<10; i++)
        {
            list[i] = _dvote.getPollVoterRecord(voterIds[i]);
        }
    }
    function getUserVoteStatistical(address __sender) external view returns (uint256 totalAmount, uint256 totalIncome, uint256 totalNumber)
    {
        return _dvote.getUserVoteStatistical(__sender);
    }

    function getUserVoteIdOfPolls(uint256 __pollId, address __sender) external view returns (uint256)
    {
        return _dvote.getUserVoteIdOfPolls(__pollId, __sender);
    }

    function getUserCreatePollRecordsLength(address __sender) external view returns (uint256)
    {
        return _dvote.getUserCreatePollRecordsLength(__sender);
    }

    function getPollsInTheVoteLength() external view returns (uint)
    {
        return _dvote.getPollsInTheVoteLength();
    }

    function getPollSimple(uint256 __pollId) internal view returns (PollSimple memory)
    {
        Poll memory _poll = _dvote.getPoll(__pollId);
        return PollSimple({
            pollId:_poll.pollId,
            tokenContract:_poll.tokenContract,
            title:_poll.title,
            context:_poll.context,
            creationTime:_poll.creationTime,
            endTime:_poll.endTime,
            level:_poll.level,
            isQualified:_poll.isQualified,
            sender:_poll.sender
        });
    }

    function getPollsInTheVoteCount10(uint __index) external view returns (PollSimple[10] memory list)
    {
        uint length = _dvote.getPollsInTheVoteLength();
        if (__index < length)
        {
            uint begin = __index;
            uint end = length;
            if (__index + 10 < length)
            {
                end = __index + 10;
            }
            uint i = begin;
            for (uint j=0; j<10; j++)
            {
                uint256 __pollId = _dvote.getPollsInTheVote(i);
                if (__pollId > 0) list[j] = getPollSimple(__pollId);
                i++;
                if (i == length) break;
            }
        }
    }

    function getPollsVotingClosedLength() external view returns (uint256)
    {
        return _dvote.getPollsVotingClosedLength();
    }

    function getPollsVotingClosedCount10Desc(uint256 __index, address __sender) external view returns (PollSimple[10] memory list, PollVoterRecord[10] memory voterList)
    {
        uint256 length = _dvote.getPollsVotingClosedLength();
        if (__index > 0 && __index <= length)
        {
            uint256 begin = __index-1;
            uint256 end = 0;
            if (__index >= 10)
            {
                end = __index-10;
            }
            uint256 j = 0;
            uint256 i = begin;
            while(true)
            {
                list[j] = getPollSimple(_dvote.getPollsVotingClosed(i));
                uint256 __voterId = _dvote.getUserVoteIdOfPolls(list[j].pollId, __sender);
                voterList[j] = _dvote.getPollVoterRecord(__voterId);
                if (i == end) break;
                i--;
                j++;
            }
        }
    }

    function getPollVoterRecord(uint256 __pollId, address __sender) external view returns (PollVoterRecord memory)
    {
        uint256 __voterId = _dvote.getUserVoteIdOfPolls(__pollId, __sender);
        return _dvote.getPollVoterRecord(__voterId);
    }

    function getUserVoterRecordsLength(address __sender) external view returns (uint256)
    {
        return _dvote.getUserVoterRecordsLength(__sender);
    }

    function getUserVoterRecordsCount10Desc(address __sender, uint256 __index) external view returns (PollVoterRecord[10] memory list, Poll[10] memory pollsList)
    {
        uint256 length = _dvote.getUserVoterRecordsLength(__sender);
        if (__index > 0 && __index <= length)
        {
            uint256 begin = __index-1;
            uint256 end = 0;
            if (__index >= 10)
            {
                end = __index-10;
            }
            uint j = 0;
            uint256 i = begin;
            while(true)
            {
                list[j] = _dvote.getPollVoterRecord(_dvote.getUserVoterRecords(__sender, i));
                pollsList[j] = _dvote.getPoll(list[j].pollId);
                if (i == end) break;
                i--;
                j++;
            }
        }
    }

    function getDVoteInfo() external view returns (uint256 totalPublisherConsumption, uint256 totalPoolConsumption, uint256 totalVoterConsumption, uint256 balanceOf)
    {
        return _dvote.getDVoteInfo();
    }

    function isVerifyTokenContractResults(address __tokenContract) external view returns (bool)
    {
        return _dvote.isVerifyTokenContractResults(__tokenContract);
    }

    function getTokenInfo(address __tokenContract) external view returns (
        string memory name,
        string memory symbol,
        uint decimals,
        uint256 totalSupply)
    {
        name = ERC20(__tokenContract).name();
        symbol = ERC20(__tokenContract).symbol();
        decimals = ERC20(__tokenContract).decimals();
        totalSupply = IERC20(__tokenContract).totalSupply();

    }

    function isAdmin(address __sender) external view returns (bool)
    {
        if (__sender == _admin)
            return true;
        return false;
    }
}