/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

pragma solidity >=0.5.0 <0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

//声明token接口需要用到的函数
interface token {
    function transfer(address receiver, uint amount) external returns(bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns(bool);
    function balanceOf(address account) external view returns (uint);
    function decimals() external returns(uint);
}

contract Lottery {
    /* 导入安全运算库 */
    using SafeMath for uint;
    address owner;
    //声明token变量
    token public tokenReward;
    //定义是否结束变量
    bool public closed;
    //
    uint singleNotePrice = 3;
    // 记录每个中奖者能获得的代币
    mapping(address => uint) public winnerToken;
    //每期中奖用户地址数组
    mapping(uint => address[]) public roundWinners;
    uint rewardsPool = 0;
    //当前中奖用户数组
    address[] public currentWinnersArr;
    //定义投注信息的结构体
    struct BetItem{
        address bettor;
        uint256 betStrFirst;
        uint256 betStrSecond;
        uint256 betStrThird;
        uint256 betNo;
    }
    BetItem[] private currentBets;

    struct winnerItem{
        address bettor;
        uint256 betNo;
    }
    winnerItem[] private currentWinners;
    
    mapping(address=>BetItem[]) betForUser;
    //彩票期数
    uint256 round = 1;
    //声明需要记录在区块链上的日志
    event GetWinner(address[] winner, uint pahse, uint fee, uint rewards, uint round);
    event Bet(address bettor, uint256  betStrFirst, uint256  betStrSecond,uint256  betStrThird, uint256 betNo);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    /*constructor(address _tokenAddress) public {
        closed = false;
        owner = msg.sender;
        tokenReward = token(_tokenAddress);
    }*/
    
    constructor() public {
        closed = false;
        owner = msg.sender;
        tokenReward = token(0x68e8832fb890C5a59c2ac04BC241Ff97A56dC9E3);
    }
    
    function getContractBalance() public view returns(uint) {
        return tokenReward.balanceOf(address(this));
    }
    
    function payToken(uint _multiple) public payable {
        tokenReward.transferFrom(msg.sender, address(this), _multiple);//
        rewardsPool = rewardsPool.add(_multiple.mul(singleNotePrice));
    }
    
    function getDecimals(uint _sum) public returns(uint) {
        uint tokenDecimal = tokenReward.decimals();
        //return tokenDecimal;
        return _sum.mul(singleNotePrice).mul(10 ** tokenDecimal).div(10);
    }
    
    function getRewardsPool() public view returns (uint) {
        return rewardsPool;
    }
    
    //投注
    function bet(uint256  betStrFirst, uint256  betStrSecond, uint256  betStrThird, uint256 sum) public payable {//投注函数
        require(closed == false);                    //检查投注是否截止
        //uint tokenDecimal = tokenReward.decimals();
        BetItem memory item  = BetItem({             //生成一个投注信息
            bettor:msg.sender,
            betStrFirst:betStrFirst,
            betStrSecond:betStrSecond,
            betStrThird:betStrThird,
            betNo:sum
        });

        currentBets.push(item);                      //记录投注数据

        betForUser[msg.sender].push(item);
        //tokenReward.approve(address(this), sum);//用户授权给合约，让合约可以提取固定金额的token
        //支付token
        tokenReward.transferFrom(msg.sender, address(this), sum.mul(msg.value));//这个sum是投注的倍数，这里是1个代币投一次，如果是多个代币投一次，总支付代币则是（单注代币数*sum）

        emit Bet(msg.sender, betStrFirst, betStrSecond, betStrThird, sum);           //记录日志
    }
    
    //开奖
    function closeAndFindWinner() onlyOwner public {
        require(closed == false);
        require(currentBets.length > 4);
        closed = true;
        
        uint256[] memory currentNum;
        //currentNum = new uint256[](3);
        currentNum = random(10);
        //return (currentNum[0],currentNum[1],currentNum[2]);
        uint fee = tokenReward.balanceOf(address(this)).div(5);

        tokenReward.transferFrom(address(this), owner, fee);

        uint rewards =  tokenReward.balanceOf(address(this));
        uint allSum = 0;
        //通过循环遍历当前参与的购买彩票用户的信息数组匹配开奖号码，三个数字完全匹配则放入当前获奖数组里
        for (uint i=0; i<currentBets.length; i++)
        {
            BetItem memory item = currentBets[i];
            if(item.betStrFirst==currentNum[0] && item.betStrSecond==currentNum[1] && item.betStrThird==currentNum[2]) {
                //currentWinners.push(item.bettor);
                winnerItem memory witem = winnerItem({             //生成一个中奖信息
                    bettor:item.bettor,
                    betNo:item.betNo
                });
            allSum += item.betNo;
            currentWinners.push(witem);                      //记录中奖数据
            currentWinnersArr.push(item.bettor);
            }
        }
        //如果当前获奖数组长度大于0，则说明有人中奖，奖池里的钱平分给获奖者
        if(currentWinners.length > 0) {
            uint singleRewards = rewards.div(allSum);
            
            for (uint k = 0; k < currentWinners.length; k++)
            {
                winnerItem memory witem = currentWinners[k];
                uint winnerRewards = witem.betNo.mul(singleRewards);//每个获奖者根据投注数获得的奖金
                //奖金存入用户数组里
                winnerToken[witem.bettor] = winnerToken[witem.bettor].add(winnerRewards);
            }
            
            roundWinners[round] = currentWinnersArr;
        }
        
        emit GetWinner(currentWinnersArr, round, fee, rewards, round);
        
        round++;
    }
    
    //用户投注次数
    function myCurrentBetTimes() public view returns (uint){
        return betForUser[msg.sender].length;
    }
    
    //获取奖池余额
    function getJackpotBalance() public view returns(uint) {
        return tokenReward.balanceOf(address(this));
    }
    
    //获取用户余额
    function getUserBalance(address _address) public view returns(uint) {
        return winnerToken[_address];
    }
    
    function userWithdrawToken() public {
        tokenReward.transfer(msg.sender, winnerToken[msg.sender]);
        winnerToken[msg.sender] = 0;
    }
    
    //重开一期彩票
    function reOpen() public onlyOwner{
        require(closed == true);
        closed = false;
        for (uint i = 0; i < currentBets.length; i++){
            delete betForUser[currentBets[i].bettor];
        }
        delete currentBets;
        delete currentWinners;
        delete currentWinnersArr;
    }
    
    //生成随机数
    function random(uint256 _length) private view returns (uint256[] memory){
        uint256 random1 = uint256(keccak256(abi.encodePacked(block.difficulty, now+1)));
        uint256 random2 = uint256(keccak256(abi.encodePacked(block.difficulty, now+2)));
        uint256 random3 = uint256(keccak256(abi.encodePacked(block.difficulty, now+3)));
        uint256[] memory currentNum;
        //currentNum = new uint256[](3);
        currentNum[0] = random1%_length;
        currentNum[1] = random2%_length;
        currentNum[2] = random3%_length;
        // currentNum.push(random1%_length);
        // currentNum.push(random2%_length);
        // currentNum.push(random3%_length);
        return currentNum;
    }
}