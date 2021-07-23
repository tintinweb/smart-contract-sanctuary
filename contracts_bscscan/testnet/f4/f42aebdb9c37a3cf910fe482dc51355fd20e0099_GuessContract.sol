/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-25
*/

pragma solidity ^0.6.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


interface BEP20Interface{
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function transferGuess(address recipient, uint256 _amount) external returns (bool success);
    function transferGuessUnstake(address recipient, uint256 _amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract GuessContract {
    
    using SafeMath for uint;
    
    address public owner ;
    uint randomNumber=0;
    uint tokenPerWeek = 1000;
    uint timeBtwLastWinner;
    
    /* stoch contract address */    
    BEP20Interface public stochContractAddress = BEP20Interface(0xf2F531E97ed7Fc7956dBFF8DCFbB7AfF714439DA);
    
    uint public totalTokenStakedInContract; 
    uint public winnerTokens;
      
    struct StakerInfo {
        bool isStaking;
        uint stakingBalance;
        uint[] choosedNumbers;
        uint maxNumberUserCanChoose;
        uint currentNumbers;
    }
    
    struct numberMapStruct {
        bool isChoosen;
        address userAddress;
    }
    
    mapping(address=>StakerInfo) StakerInfos;
    mapping(uint => numberMapStruct) numerMap;
    

 //////////////////////////////////////////////////////////////////////////////Constructor Function///////////////////////////////////////////////////////////////////////////////////////////////////
     

    constructor() public {
        timeBtwLastWinner = now;
        owner = msg.sender;
        
    }


//////////////////////////////////////////////////////////////////////////////////////Modifier Definitations////////////////////////////////////////////////////////////////////////////////////////////

    /* onlyAdmin modifier to verify caller to be owner */
    modifier onlyAdmin {
        require (msg.sender ==  0xad7b72b4F775C24fD31a921490248A4Ea382E7fA  , 'Only Admin has right to execute this function');
        _;
        
    }
    
    /* modifier to verify caller has already staked tokens */
    modifier onlyStaked() {
        require(StakerInfos[msg.sender].isStaking == true);
        _;
    }
    
    
//////////////////////////////////////////////////////////////////////////////////////Staking Function//////////////////////////////////////////////////////////////////////////////////////////////////



    /* function to stake tokens in contract. This will make staker to be eligible for guessing numbers 
    * 100 token => 1 guess
    */
    
     function stakeTokens(uint _amount) public  {
       require(_amount > 0); 
       require ( StakerInfos[msg.sender].isStaking == false, "You have already staked once in this pool.You cannot staked again.Wait for next batch") ;
       require (BEP20Interface(stochContractAddress).transferFrom(msg.sender, address(this), _amount.mul(10**17)));
       StakerInfos[msg.sender].stakingBalance =  _amount;
       totalTokenStakedInContract = totalTokenStakedInContract.add(_amount);
       StakerInfos[msg.sender].isStaking = true;
       StakerInfos[msg.sender].maxNumberUserCanChoose = _amount.div(100); 
        
    }
    
    
    /* funtion to guess numbers as per tokens staked by the user. User can choose any numbers at a time but not more than max allocated count 
     * All choosen numbers must be in the range of 1 - 1000 
     * One number can be choosed by only one person
    */
    function chooseNumbers(uint[] memory _number) public onlyStaked() returns(uint[] memory){
        require(StakerInfos[msg.sender].maxNumberUserCanChoose > 0);
        require(StakerInfos[msg.sender].currentNumbers < StakerInfos[msg.sender].maxNumberUserCanChoose);
        require(StakerInfos[msg.sender].maxNumberUserCanChoose - StakerInfos[msg.sender].currentNumbers > 0);
        require(_number.length <= StakerInfos[msg.sender].maxNumberUserCanChoose - StakerInfos[msg.sender].choosedNumbers.length);
        require(_number.length <= StakerInfos[msg.sender].maxNumberUserCanChoose - StakerInfos[msg.sender].currentNumbers);
        for(uint i=0;i<_number.length;i++)
        require(_number[i] >= 1 && _number[i] <= 1000);
        uint[] memory rejectedNumbers = new uint[](_number.length);
        uint t=0;
        for(uint i=0;i<_number.length;i++) {
            if (numerMap[_number[i]].isChoosen == true) {
                rejectedNumbers[t] = _number[i];
                t = t.add(1);
            }
            else {
                StakerInfos[msg.sender].currentNumbers = StakerInfos[msg.sender].currentNumbers.add(1);
                StakerInfos[msg.sender].choosedNumbers.push(_number[i]);
                numerMap[_number[i]].isChoosen = true;
                numerMap[_number[i]].userAddress = msg.sender;
            }
        }
        
        return rejectedNumbers;
    }
    
    
    /*  Using this function user can unstake his/her tokens at any point of time.
    *   After unstaking history of user is deleted (choosed numbers, staking balance, isStaking)
    */
    
    function unstakeTokens() public onlyStaked() {
        uint balance = StakerInfos[msg.sender].stakingBalance;
        require(balance > 0, "staking balance cannot be 0 or you cannot stake before pool expiration period");
        require(BEP20Interface(stochContractAddress).transferGuess(msg.sender, balance.mul(10**17)));
        totalTokenStakedInContract = totalTokenStakedInContract.sub(StakerInfos[msg.sender].stakingBalance);
        StakerInfos[msg.sender].stakingBalance = 0;
        StakerInfos[msg.sender].isStaking = false;
        StakerInfos[msg.sender].maxNumberUserCanChoose = 0;
        delete StakerInfos[msg.sender].choosedNumbers;
        StakerInfos[msg.sender].currentNumbers = 0;
        for(uint i=0;i<StakerInfos[msg.sender].choosedNumbers.length;i++) {
            numerMap[StakerInfos[msg.sender].choosedNumbers[i]].isChoosen = false;
            numerMap[StakerInfos[msg.sender].choosedNumbers[i]].userAddress = address(0);
        }
        
        
    } 
    

    
    function chooseWinner() public onlyAdmin returns(address) {
        require(randomNumber != 0);
        require(numerMap[randomNumber].userAddress != address(0));
        address user;
        user = numerMap[randomNumber].userAddress;
        uint winnerRewards;
        uint _time = now-timeBtwLastWinner;
        winnerRewards = calculateReedemToken(_time);
        require(BEP20Interface(stochContractAddress).transferGuess(user, winnerRewards));
        winnerTokens = winnerRewards;
        timeBtwLastWinner = now;
        randomNumber = 0;
        return user;
    }
    
    function checkRandomOwner() public view returns(address) {
        require(numerMap[randomNumber].userAddress != address(0), "No matched");
        return numerMap[randomNumber].userAddress;
    }
    
    function checkRandomNumber() view public returns(uint) {
        require(randomNumber != 0, "Random number not generated yet");
        return randomNumber;
    } 
    
    
    function viewNumbersSelected() view public returns(uint[] memory) {
        return StakerInfos[msg.sender].choosedNumbers;
    }
    
    function maxNumberUserCanSelect() view public returns(uint) {
        return StakerInfos[msg.sender].maxNumberUserCanChoose;
    }
    
    function remainingNumbersToSet() view public returns(uint) {
        return (StakerInfos[msg.sender].maxNumberUserCanChoose - StakerInfos[msg.sender].currentNumbers);
    }
        
    function countNumberSelected() view public returns(uint) {
        return StakerInfos[msg.sender].currentNumbers;
    }
    
    function checkStakingBalance() view public returns(uint) {
       return StakerInfos[msg.sender].stakingBalance; 
    }
    
    function isUserStaking() view public returns(bool) {
        return StakerInfos[msg.sender].isStaking;
    }
    
    
    function calculateReedemToken(uint _time) view internal returns(uint) {
        uint amount = tokenPerWeek;
        amount = amount.mul(_time);
        amount = amount.mul(10**17);
        amount = amount.div(7);
        amount = amount.div(24);
        amount = amount.div(60);
        amount = amount.div(60);
        return amount;
    } 
    
    
    function calculateCurrentTokenAmount() view public returns(uint) {
        uint amount = calculateReedemToken(now-timeBtwLastWinner);
        return amount;
    }
    
    
    function lastWinsTime() view public returns(uint) {
        return timeBtwLastWinner;
    }
    
    
    function winnerTokensReceived() public view returns(uint) {
        return winnerTokens;
    }

    
    function generateRandomNumber(uint _seed) public onlyAdmin returns (uint) {
        uint ranNumber = uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,_seed)))%1000+1;
        randomNumber = ranNumber;
        return ranNumber;
    }
    
}