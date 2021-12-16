/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later

        pragma solidity 0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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



        library SafeMath {
        function mul(uint a, uint b) internal pure  returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
        }

        function div(uint a, uint b) internal pure  returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
        }

        function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
        }

        function add(uint a, uint b) internal  pure   returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
        }
        }
        contract Stake {
        using SafeMath for uint;
        address private owner;
        address private contractCreator;
        mapping(uint => uint) private rules;
        mapping(uint => uint)periods;
        uint totalPeriods=0;
        mapping(uint => uint)commissionPercentages;
        mapping(uint => uint) private removeRules;
        mapping(uint => mapping(address => uint)) private stakes;
        mapping(uint => mapping(address => uint)) private stakesStartTime;
        string private gsonUri;
        uint private totalStakeAmount;
        string stakeName="Stake";
        uint oneDaySeconds=86400;
        //uint oneDaySeconds=60;

        /**
        * @dev Fix for the BEP20 short address attack.
        */
        modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4) ;
        _;
        }
        constructor(string memory  uri) {
        owner=address(this);
        contractCreator=msg.sender;
        gsonUri=uri;
        emit ContractCreated(stakeName);
        }

        function contractInfo() public view returns(string memory){
        return gsonUri;
        }

        function getTokenOwnerAddress() public view returns(address){
        return contractCreator;
        }




        function addRule(uint period,uint percentage) public returns(bool){
        require(period!=0,"period must not be 0");
        require(percentage!=0,"percentage must not be 0");
        require(rules[period]==0,"period already exists");
        require(msg.sender==contractCreator,"you're not permitted to add rule.");
        rules[period]=percentage;
        periods[totalPeriods]=period;
        commissionPercentages[totalPeriods]=percentage;
        removeRules[period]=totalPeriods;
        totalPeriods++;
        emit NewRule(period,percentage,"New rule added.");
        return true;
        }


        function removeRule(uint period) public returns(bool){
        require(period!=0,"period must not be 0");
        require(msg.sender==contractCreator,"you're not permitted to add rule.");
        rules[period]=0;
        periods[removeRules[period]]=0;
        commissionPercentages[removeRules[period]]=0;
        removeRules[period]=0;
        emit RuleRemoved(period,"Rule removed.");
        return true;
        }



        function stake(IERC20 tcontract,uint period,uint tokenAmountInWEI) public returns(uint,uint){
        require(period!=0,"period must not be 0");
        require(rules[period]!=0,"period is invalid");
        require(tokenAmountInWEI!=0,"token amount must not be 0");
        require(stakes[period][msg.sender]==0,"You already have active stake");
        require(tcontract.allowance(msg.sender,address(this))>=tokenAmountInWEI,"No approval for spending");
        require(tcontract.transferFrom(msg.sender,owner, tokenAmountInWEI), "Don't have enough balance");
        stakes[period][msg.sender]=tokenAmountInWEI;
        stakesStartTime[period][msg.sender]=block.timestamp;
        totalStakeAmount+=tokenAmountInWEI;

        uint startTime= stakesStartTime[period][msg.sender];
        uint stakeTotalTime=(period*oneDaySeconds);
        uint endTime=startTime+stakeTotalTime;


        emit StakeAdded(msg.sender,tokenAmountInWEI,"New stake listed.");
        return (startTime,endTime);
        }



        function getStakeInfo(uint period) public view returns(uint,uint,uint){
        require(period!=0,"period must not be 0");
        require(rules[period]!=0,"period is invalid");
        require(stakes[period][msg.sender]!=0,"You dont have active stake");
        uint amount= stakes[period][msg.sender];
        uint startTime= stakesStartTime[period][msg.sender];
        uint stakeTotalTime=(period*oneDaySeconds);
        uint endTime=startTime+stakeTotalTime;

        return (amount,startTime,endTime);
        }




        function getMaturityDate(uint period) public view returns(uint){
        require(period!=0,"period must not be 0");
        require(rules[period]!=0,"period is invalid");
        require(stakes[period][msg.sender]!=0,"You dont have active stake");
        uint startTime= stakesStartTime[period][msg.sender];
        uint stakeTotalTime=(period*oneDaySeconds);
        uint time=startTime+stakeTotalTime;
        return time;
        }





        function getPeriodList() public view returns(uint[]memory,uint[]memory){
        uint[] memory pp=new uint[](totalPeriods);
        uint[] memory cp=new uint[](totalPeriods);
        for(uint i=0;i<totalPeriods;i++){

        if(periods[i]!=0){
        pp[i]= periods[i];
        cp[i]= rules[pp[i]];
        }
        }
        return (pp,cp);
        }




        function getTotalPooledToken() public view returns (uint){
        return totalStakeAmount;
        }


        function unstakeWithReward(IERC20 tcontract,uint period) public payable returns(bool){
        require(period!=0,"period must not be 0");
        require(rules[period]!=0,"period is invalid");
        require(stakes[period][msg.sender]!=0,"You dont have active stake");
        require(stakesStartTime[period][msg.sender]!=0,"You dont have active stake");

        uint stakeStartingSeconds=stakesStartTime[period][msg.sender];
        uint currentSeconds=block.timestamp;

        uint secondsDiff=currentSeconds-stakeStartingSeconds;
        uint periodSeconds=period*oneDaySeconds;
        require(secondsDiff>=periodSeconds,"Your stake is not matured yet.");

        uint stakeAmount=stakes[period][msg.sender];
        uint rewardAmount=(((stakeAmount * (rules[period]))/100)/365)*period;
        uint totalAmount=stakeAmount+rewardAmount;

        require(tcontract.transfer(msg.sender,totalAmount), "Don't have enough balance");
        uint zero=0;
        stakes[period][msg.sender]=zero;
        stakesStartTime[period][msg.sender]=zero;
        totalStakeAmount-=stakeAmount;
        emit RewardDisbursed(msg.sender,stakeAmount,rewardAmount,"Unstake with reward.");
        return true;
        }




        function unstakeWithoutReward(IERC20 tcontract,uint period) public payable returns (bool){
        require(period!=0,"period must not be 0");
        require(rules[period]!=0,"period is invalid");
        require(stakes[period][msg.sender]!=0,"You dont have active stake");
        require(stakesStartTime[period][msg.sender]!=0,"You dont have active stake");

        uint stakeStartingSeconds=stakesStartTime[period][msg.sender];
        uint currentSeconds=block.timestamp;

        uint secondsDiff=currentSeconds-stakeStartingSeconds;
        uint periodSeconds=period*oneDaySeconds;
        require(secondsDiff<periodSeconds,"Your stake is already matured.");
        uint stakeAmount=stakes[period][msg.sender];

        require(tcontract.transfer(msg.sender,stakeAmount), "Don't have enough balance");
        uint zero=0;
        stakes[period][msg.sender]=zero;
        stakesStartTime[period][msg.sender]=zero;
        totalStakeAmount-=stakeAmount;
        emit UnStake(msg.sender,stakeAmount,"UnStake without reward.");
        return true;
        }

        function getCurrentBlockTime() public view returns(uint){
        return block.timestamp;
        }


        fallback() external payable {
        // custom function code
        }

        receive() external payable {
        // custom function code
        }


        event StakeAdded(address indexed stakeHolder,uint amount,string info);
        event UnStake(address indexed stakeHolder,uint amount,string info);
        event Approval(address indexed indexer,address indexed spender,uint amount);
        event ContractCreated(string name);
        event NewRule(uint period,uint percentage,string info);
        event RuleRemoved(uint period,string info);
        event RewardDisbursed(address indexed stakeHolder,uint stakeAmount,uint rewardAmount,string info);

        }