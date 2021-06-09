/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity >=0.4.21 <0.6.0;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface token {
    function transfer(address receiver, uint amount) external returns(bool);
    function transferFrom(address from, address to, uint amount) external returns(bool);
    function balanceOf(address account) external view returns (uint);
}

contract LotteryShop is owned{

    token public tokenReward;
    bool public closed;

    /** 赌约结构体 */
    struct BetItem{
        address bettor; // 下注人
        bytes3  betStr; // 下注号码
        uint256 betNo;  // 下注数量
    }
    BetItem[] private currentBets;          // 赌约列表
    mapping(address=>BetItem[]) betForUser; // 用户下注对应表
    address[] public allWinners;            // 所有中奖者列表
    address public currentWinner;           // 本期中奖者

    // 事件: 记录中奖者,通知节点客户端;
    event GetWinner(address winner, uint pahse, uint fee, uint rewards);
    // 事件: 记录赌约,通知节点客户端;
    event Bet(address bettor, bytes3 betStr, uint256 betNo);
    
    /**
     * 构造方法,
     * 传入作为赌注的token合约地址
     * addressOfTokenUsedAsReward:部署合约LotteryCoin的合约地址
     */
    constructor(address addressOfTokenUsedAsReward) public{
        tokenReward = token(addressOfTokenUsedAsReward);
        closed = false;
    }

    /** 下注 */
    function bet(bytes3 betStr, uint256 sum) public {
        // 判断下注是否已经关闭
        require(closed == false); 
        // 构建赌约结构体
        BetItem memory item  = BetItem({
            bettor:msg.sender,
            betStr:betStr,
            betNo:sum
        });
        // 写入赌约列表
        currentBets.push(item);
        // 写入用户下注对应表
        betForUser[msg.sender].push(item);
        // 调用token合约进行transfer方法交易
        tokenReward.transfer(address(this), sum);
        // 调用事件
        emit Bet(msg.sender, betStr, sum);
    }

    /** 查询自己的赌约 */
    function allMyBets()public view returns (bytes3[] memory, uint256[] memory, bool, address){
        // 获取自己的赌约
        BetItem[] memory myBets = betForUser[msg.sender];
        // 赌约数量
        uint length = myBets.length;
        // 创建同等容量的数组,用于存储返回数据
        bytes3[] memory strs = new bytes3[](length);
        uint256[] memory nos = new uint256[](length);
        // 循环处理数据
        for(uint i = 0; i <length; i++){
            BetItem memory item = myBets[i];
            strs[i]=(item.betStr);
            nos[i] = (item.betNo);
        }
        // 返回: strs=下注号码, nos=下注数量, closed=是否关闭, currentWinner=中奖者
        return (strs, nos, closed, currentWinner);
    }

    /** 查询用户本期赌约数量 */
    function myCurrentBetTimes() public view returns (uint){
        return betForUser[msg.sender].length;
    }

    /** 查询用户的赌约详情 */
    function myBets(uint itemNo) public view returns(bytes3, uint256){
        BetItem[] storage items = betForUser[msg.sender];

        if (items.length < itemNo){
            return ("", 0);
        }

        BetItem memory item = items[itemNo];
        return (item.betStr, item.betNo);
    }

    function closeAndFindWinner() public onlyOwner{
        require(closed == false);
        require(currentBets.length > 4);
        closed = true;

        currentWinner = random();

        allWinners.push(currentWinner);


        uint fee = tokenReward.balanceOf(address(this)) / 10;

        tokenReward.transferFrom(address(this), owner, fee);

        uint rewards =  tokenReward.balanceOf(address(this));

        tokenReward.transferFrom(address(this), currentWinner, fee);

        emit GetWinner(currentWinner, allWinners.length, fee, rewards);
    }

    function random() private view returns (address){
        uint randIdx = (block.number^block.timestamp) % currentBets.length;
        BetItem memory item = currentBets[randIdx] ;
        return item.bettor;
    }

    function reOpen() public onlyOwner{
        require(closed == true);
        closed = false;
        for (uint i = 0; i < currentBets.length; i++){
            delete betForUser[currentBets[i].bettor];
        }
        delete currentBets;
        delete currentWinner;
    }
}