/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


// ----------------------------------------------------------------------------
// SafeMath library
// ----------------------------------------------------------------------------


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "ERC20: sending to the zero address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);
    function burnTokens(uint256 _amount) external;
    
    function calculateFeesBeforeSend(
        address sender,
        address recipient,
        uint256 amount
    ) external view returns (uint256, uint256);
    
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


interface stakeContract {
    function DisributeTxFunds() external;
    function ADDFUNDS(uint256 tokens) external;
    function ADDFUNDS1(uint256 tokens) external;
}

interface stakeContract1 {
    function ADDFUNDS1(uint256 tokens) external;
    function ADDFUNDS2(uint256 tokens) external;
    function ADDFUNDS3(uint256 tokens) external;
    function totalSupply() external returns (uint);
}

interface FEGex2 {
    function SELL(
        address to,
        uint tokenAmountIn,
        uint minAmountOut
    ) 
        external
        returns (uint tokenAmountOut, uint spotPriceAfter);
}

interface wrap {
    function deposit() external payable;
    function withdraw(uint amt) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract ShareDistributor is Owned {
    using SafeMath for uint256;
    
    address public fETH    = 0xf786c34106762Ab4Eeb45a51B42a62470E9D5332;
    address public fUSDT   = 0x979838c9C16FD365C9fE028B0bEa49B1750d86e9;
    address public fBTC    = 0xe3cDB92b094a3BeF3f16103b53bECfb17A3558ad;
    address public other   = 0x94D4Ac11689C6EbbA91cDC1430fc7dfa9a858753;
    address public deploy  = 0x3B30Bac3c331168e40FC6338BA2295A2F3adDe52;
    address public FEG     = 0x389999216860AB8E0175387A0c90E5c52522C945;
    address public v2pair  = 0xa40462266dC28dB1d570FC8F8a0F4B72B8618f7a;
    address public stake1  = 0x5bCF1f407c0fc922074283B4e11DaaF539f6644D;
    address public stake2  = 0x4a9D6b95459eb9532B7E4d82Ca214a3b20fa2358;
    uint public v1Share = 36;
    uint public v2Share = 12;
    uint public give = 50;
    bool public sell = true;
    uint256 public must  = 5e17;
    uint256 public must1 = 200e18;
    uint256 public must2 = 5e15;
    uint256 public totaldist  = 0; // Total other rewards fETH
    uint256 public totaldist1 = 0; // Total other rewards fUSDT
    uint256 public totaldist2 = 0; // Total other rewards fBTC
    
    
    stakeContract stakingContract; //FEG staking v1 contract address
    stakeContract1 v2stakingContract; //FEG v2 staking contract address
    FEGex2 fegexpair;
    wrap wrapp;
    
    receive() external payable {
    }

    constructor() {
        owner = msg.sender;
        stakingContract     = stakeContract(stake1);
        v2stakingContract   = stakeContract1(stake2);
        fegexpair = FEGex2(v2pair);
        wrapp = wrap(fETH);
    }
    
    function changeWrap(wrap _wrapp) external onlyOwner{ // Incase FEGex updates in future
        require(address(_wrapp) != address(0), "setting 0 to contract"); 
        wrapp = _wrapp;
    }
    
    function updateBase(address _BTC, address _ETH, address _USDT) external onlyOwner{ // Incase wraps ever update
        fBTC = _BTC;
        fETH = _ETH;
        fUSDT = _USDT;
    }
    
    function changeStakingContract(stakeContract _stakingContract) external onlyOwner{
        require(address(_stakingContract) != address(0), "setting 0 to contract");
        stakingContract = _stakingContract;
    }
    
    function changeLPStakingContract(stakeContract1 _v2StakingContract) external onlyOwner{
        require(address(_v2StakingContract) != address(0), "setting 0 to contract");
        v2stakingContract = _v2StakingContract;
    }
    
    function changeFEGExPair(FEGex2 _fegexpair) external onlyOwner{
        require(address(_fegexpair) != address(0), "setting 0 to contract");
        fegexpair = _fegexpair;
    }
    
    function changeDeploy(address _deploy) external onlyOwner{
        require(address(_deploy) != address(0), "setting 0 to contract");
        deploy = _deploy;
    }
    
    function changeV2Pair(address _V2) external onlyOwner{
        v2pair = _V2;
    }
    
    function changeOther(address _other) external onlyOwner{
        other = _other;
    }
    
    function changeMust(uint256 _must, uint256 _must1, uint256 _must2) external onlyOwner{
        require(_must >= 5e17, "_must must be greater then 0.5");
        require(_must1 >= 200e18, "_must1 must be greater then 20");
        require(_must2 >= 5e15, "_must2 must be greater then 0.005");
        must = _must;
        must1 = _must1;
        must2 = _must2;
    } 

    function changeSell(bool _bool) external onlyOwner{
        sell = _bool;
    }
    
    function changeGive(uint _give) external onlyOwner{
        require(_give >= 20, "over 20% required");
        give = _give;
    }
    
    function changeRewardShare(uint _v1rs, uint _v2rs) external onlyOwner{
        require(_v1rs + _v2rs <= 48, "Must be under 0.12%"); // Total of both v1 and v2 share is 48% of the 0.25% collected from FEGex, this determines the reward split to each pool.
        require(_v1rs !=0 && _v2rs !=0, "Cannot set to 0");
        v1Share = _v1rs;
        v2Share = _v2rs;
    }
   

    function distributeAll() public{
        
        if(IERC20(fETH).balanceOf(address(this)) > must){
        uint256 amount = (IERC20(fETH).balanceOf(address(this)).mul(995).div(1000)).sub(totaldist);
        uint256 v1Balance = IERC20(FEG).balanceOf(address(stakingContract));
        uint256 v2Balance = IERC20(FEG).balanceOf(address(v2stakingContract));
        uint256 fETHbalanceToDistribute = amount.mul(v1Share.add(v2Share)).div(100);
        uint256 total = v1Balance.add(v2Balance);
        uint256 fETHbalanceToDistributeToV1 = fETHbalanceToDistribute.mul(v1Balance).div(total);
        uint256 fETHbalanceToDistributeToV2 = fETHbalanceToDistribute - fETHbalanceToDistributeToV1;
        
        require(IERC20(fETH).transfer(address(stakingContract), fETHbalanceToDistributeToV1), "Tokens cannot be transferred from funder account");
        stakingContract.ADDFUNDS(fETHbalanceToDistributeToV1);
        
        require(IERC20(fETH).transfer(address(v2stakingContract), fETHbalanceToDistributeToV2), "Tokens cannot be transferred from funder account");
        v2stakingContract.ADDFUNDS1(fETHbalanceToDistributeToV2);  
        
        uint256 amountFinal     = amount.sub(fETHbalanceToDistributeToV2.add(fETHbalanceToDistributeToV1));
        totaldist = totaldist.add(amountFinal);
        
        }
    
        if(IERC20(fUSDT).balanceOf(address(this)) > must1){
        uint256 amountmust1 = (IERC20(fUSDT).balanceOf(address(this)).mul(995).div(1000)).sub(totaldist1);
        uint256 stakeshare = amountmust1.mul(48).div(100); 
        uint256 othershare = amountmust1.sub(stakeshare);
        v2stakingContract.ADDFUNDS2(stakeshare); 
        totaldist1 = totaldist1.add(othershare);
        }
    
        if(IERC20(fBTC).balanceOf(address(this)) > must2){
        uint256 amountmust2 = (IERC20(fBTC).balanceOf(address(this)).mul(995).div(1000)).sub(totaldist2);
        uint256 stakeshare2 = amountmust2.mul(48).div(100); 
        uint256 othershare2 = amountmust2.sub(stakeshare2);
        v2stakingContract.ADDFUNDS3(stakeshare2); 
        totaldist2 = totaldist2.add(othershare2);
        }   
    
        if(sell==true){
        distributeSell();
        }
    } 
    
    function distributeSell() internal{ 
        stakingContract.DisributeTxFunds();
        uint256 stakesell       = IERC20(FEG).balanceOf(address(deploy)).div(give);
        bool xfer = IERC20(FEG).transferFrom(deploy, address(this), stakesell);
        require(xfer, "ERR_ERC20_FALSE");
        fegexpair.SELL(address(this), IERC20(FEG).balanceOf(address(this)), 100);
        wrap(fETH).deposit{value: address(this).balance}();
        uint256 wrapped = (IERC20(fETH).balanceOf(address(this)).mul(uint256(995)).div(1000)).sub(totaldist);
        stakingContract.ADDFUNDS1(wrapped);
    }
    
    function distributeV2() public{
       if(IERC20(fETH).balanceOf(address(this)) > must){
        uint256 amount = (IERC20(fETH).balanceOf(address(this)).mul(995).div(1000)).sub(totaldist);
        uint256 v1Balance = IERC20(FEG).balanceOf(address(stakingContract));
        uint256 v2Balance = IERC20(FEG).balanceOf(address(v2stakingContract));
        uint256 fETHbalanceToDistribute = amount.mul(v1Share.add(v2Share)).div(100);
        uint256 total = v1Balance.add(v2Balance);
        uint256 fETHbalanceToDistributeToV1 = fETHbalanceToDistribute.mul(v1Balance).div(total);
        uint256 fETHbalanceToDistributeToV2 = fETHbalanceToDistribute - fETHbalanceToDistributeToV1;
        
        require(IERC20(fETH).transfer(address(stakingContract), fETHbalanceToDistributeToV1), "Tokens cannot be transferred from funder account");
        stakingContract.ADDFUNDS(fETHbalanceToDistributeToV1);
        
        require(IERC20(fETH).transfer(address(v2stakingContract), fETHbalanceToDistributeToV2), "Tokens cannot be transferred from funder account");
        v2stakingContract.ADDFUNDS1(fETHbalanceToDistributeToV2);  
        
        uint256 amountFinal     = amount.sub(fETHbalanceToDistributeToV2.add(fETHbalanceToDistributeToV1));
        totaldist = totaldist.add(amountFinal);
        
        }
    
        if(IERC20(fUSDT).balanceOf(address(this)) > must1){
        uint256 amountmust1 = (IERC20(fUSDT).balanceOf(address(this)).mul(995).div(1000)).sub(totaldist1);
        uint256 stakeshare = amountmust1.mul(48).div(100); 
        uint256 othershare = amountmust1.sub(stakeshare);
        v2stakingContract.ADDFUNDS2(stakeshare); 
        totaldist1 = totaldist1.add(othershare);
        }
    
        if(IERC20(fBTC).balanceOf(address(this)) > must2){
        uint256 amountmust2 = (IERC20(fBTC).balanceOf(address(this)).mul(995).div(1000)).sub(totaldist2);
        uint256 stakeshare2 = amountmust2.mul(48).div(100); 
        uint256 othershare2 = amountmust2.sub(stakeshare2);
        v2stakingContract.ADDFUNDS3(stakeshare2); 
        totaldist2 = totaldist2.add(othershare2);
        }
    }     
    
    function setup() public {
        IERC20(address(FEG)).approve(address(v2pair), 100000000000000000e18);        
        IERC20(address(fETH)).approve(address(stakingContract), 1000000000000000000e18);   
        IERC20(address(fETH)).approve(address(v2stakingContract), 1000000000000000000e18); 
        IERC20(address(fUSDT)).approve(address(v2stakingContract), 1000000000000000000e18); 
        IERC20(address(fBTC)).approve(address(v2stakingContract), 1000000000000000000e18); 
    }  
    
    function emergencySaveLostTokens(address _token) public onlyOwner {
        require(_token != FEG, "Cannot remove users FEG");
        require(_token != fETH, "Cannot remove users fETH");
        require(_token != fUSDT, "Cannot remove users fUSDT");
        require(_token != fBTC, "Cannot remove users fBTC");
        require(IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this))), "Error in retrieving tokens");
        payable(owner).transfer(address(this).balance);
    }
    
    function claimDist() public onlyOwner {
        require(IERC20(fETH).transfer(other, totaldist), "Error in retrieving tokens");
        totaldist = 0;
        require(IERC20(fUSDT).transfer(other, totaldist1), "Error in retrieving tokens");
        totaldist1 = 0;
        require(IERC20(fBTC).transfer(other, totaldist2), "Error in retrieving tokens");
        totaldist2 = 0;
    }
}