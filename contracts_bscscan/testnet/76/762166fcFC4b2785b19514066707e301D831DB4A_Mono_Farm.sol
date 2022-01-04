/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT



pragma solidity 0.8.0;

    interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}



interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**

    * @dev Multiplies two unsigned integers, reverts on overflow.

    */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

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

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

    * @dev Adds two unsigned integers, reverts on overflow.

    */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

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

contract Ownable   {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor()  {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    /**

     * @dev Returns the address of the current owner.

     */

    function owner() public view returns (address) {
        return _owner;
    }

    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}




contract Mono_Farm is Ownable{
    using SafeMath for uint256;

    ITRC20 public FlafelToken;
    IPancakePair public LpToken;
    IPancakePair public Token2;
    uint lpCount;
    uint256 public TotalLpstaked;




    struct userInfo {
        uint256 DepositeToken;
        uint256 lastUpdated;
        uint256 lockableDays;
        uint256 WithdrawReward;
        uint256 WithdrawAbleReward;
        uint256 depositeTime;
        uint256 WithdrawDepositeAmount;
        uint256 WithdrawAble_LPAmount;
    }
    
     event Deposite_(address indexed to,address indexed From, uint256 amount, uint256 day,uint256 time);

    
    mapping(uint256 => uint256) public allocation;
    mapping(address => uint256[] ) public depositeToken;
    mapping(address => uint256[] ) public lockabledays;
    mapping(address => uint256[] ) public depositetime;  
    mapping(address => uint256[] ) public lpsAmount; 
    mapping(address =>  userInfo) public Users;
    uint256 minimumDeposit = 1E18;
    
    uint256 time = 1 seconds ;

    constructor(ITRC20 _flafeltoken,IPancakePair _FlafeltoBnbLp, IPancakePair bnbtoBusd)  {
        FlafelToken = _flafeltoken;
      
        allocation[30] = 12500000000000000000;
        allocation[90] = 50000000000000000000;
        allocation[180] = 150000000000000000000;
        allocation[365] = 400000000000000000000;

    LpToken=_FlafeltoBnbLp;
    Token2=bnbtoBusd;
        
    }

    function farm(uint256 _amount, uint256 _lockableDays) public 
    {
        require(_amount >= minimumDeposit, "Invalid amount");
        require(allocation[_lockableDays] > 0, "Invalid day selection");
        uint256 lpAmount = bnbtoflafel();

        LpToken.transferFrom(msg.sender, address(this), _amount);

        uint256 LP_TO_Token = (_amount*lpAmount)/1E18;
        TotalLpstaked+=_amount;

        depositeToken[msg.sender].push(LP_TO_Token);
        depositetime[msg.sender].push(uint40(block.timestamp));
        Users[msg.sender].DepositeToken += LP_TO_Token;
        lpsAmount[msg.sender].push(_amount);
        lockabledays[msg.sender].push(_lockableDays);
        emit Deposite_(msg.sender,address(this),LP_TO_Token,_lockableDays,block.timestamp);
    }

    // uint256[]  rewardArray;
    



        function pendindRewards(address _add,uint256 z) public view  returns(uint256 reward)
    {
        uint256 Reward;
        uint256 lockTime = depositetime[_add][z]+(lockabledays[_add][z]*time);
        if(block.timestamp > lockTime ){
        reward = ((allocation[lockabledays[_add][z]].mul(depositeToken[_add][z]).div(100))).div(1E18);
        Reward += reward;
        }
    return (Reward);
    }

    
    function harvest(uint256 [] memory _index) public 
    {
          for(uint256 z=0 ; z< _index.length;z++){
              
        require( Users[msg.sender].DepositeToken > 0, " Deposite not ");
        uint256 lockTime =depositetime[msg.sender][_index[z]]+(lockabledays[msg.sender][_index[z]].mul(time));
        if(block.timestamp > lockTime ){
        uint256 reward = ((allocation[lockabledays[msg.sender][_index[z]]].mul(depositeToken[msg.sender][_index[z]]).div(100))).div(1E18);
        
        Users[msg.sender].WithdrawAbleReward += reward;
        Users[msg.sender].DepositeToken -= depositeToken[msg.sender][_index[z]];
        Users[msg.sender].WithdrawDepositeAmount += depositeToken[msg.sender][_index[z]];
        Users[msg.sender].WithdrawAble_LPAmount += lpsAmount[msg.sender][_index[z]];
        depositeToken[msg.sender][_index[z]] = 0;
        lockabledays[msg.sender][_index[z]] = 0;
        depositetime[msg.sender][_index[z]] = 0;
        lpsAmount[msg.sender][_index[z]] = 0;
    }
    }
            for(uint256 t=0 ; t< _index.length;t++){
            for(uint256 i = _index[t]; i <  depositeToken[msg.sender].length - 1; i++) 
        {
            depositeToken[msg.sender][i] = depositeToken[msg.sender][i + 1];
            lockabledays[msg.sender][i] = lockabledays[msg.sender][i + 1];
            depositetime[msg.sender][i] = depositetime[msg.sender][i + 1];
            lpsAmount[msg.sender][i] = lpsAmount[msg.sender][i + 1];
        }

          depositeToken[msg.sender].pop();
          lockabledays[msg.sender].pop();
          depositetime[msg.sender].pop();
          lpsAmount[msg.sender].pop();
    }
             uint256 totalwithdrawAmount;
            
             require(Users[msg.sender].WithdrawAbleReward > 0 , "No Balance found" );
             
             totalwithdrawAmount = Users[msg.sender].WithdrawDepositeAmount.add(Users[msg.sender].WithdrawAbleReward);
             FlafelToken.transfer(msg.sender,  totalwithdrawAmount);
             Users[msg.sender].WithdrawReward =Users[msg.sender].WithdrawReward.add(Users[msg.sender].WithdrawAbleReward );
             
            //  emit Harvest(Users[msg.sender].WithdrawAbleReward,Users[msg.sender].WithdrawReward,block.timestamp);
             Users[msg.sender].WithdrawAbleReward =0;
             Users[msg.sender].WithdrawDepositeAmount = 0;
         
    }
    
    function UserInformation(address _add) public view returns(uint256 [] memory , uint256 [] memory,uint256 [] memory){
        return(depositeToken[_add],lockabledays[_add],depositetime[_add]);
    }
 
 
    function emergencyWithdrawLP(uint256 WORTHWHILEAmount) public onlyOwner {
         LpToken.transfer(msg.sender, WORTHWHILEAmount);
    }

    function emergencyWithdrawFlafel(uint256 WORTHWHILEAmount) public onlyOwner {
         FlafelToken.transfer(msg.sender, WORTHWHILEAmount);
    }

    function emergencyWithdrawBNB(uint256 Amount) public onlyOwner {
        payable(msg.sender).transfer(Amount);
    }
    

    function UnstakeLp() public 
    {
       require(Users[msg.sender].WithdrawAble_LPAmount > 0,"Lp not found for unstake");
       LpToken.transfer(msg.sender, Users[msg.sender].WithdrawAble_LPAmount);
       Users[msg.sender].WithdrawAble_LPAmount = 0;
    }



// ....................................CalculateLPS...............................................................................................................................
    

        function totalSupplyOfLpToken() public view returns(uint256){
            return LpToken.totalSupply();
        }


        function bnbtobusd() public view returns (uint256 BNBperBUSD,uint256 BUSDperBNB)
        {
                    uint256 a;
                    uint256 b;
                    uint256 c;
                     ( a, b,c) = Token2.getReserves();
                     BNBperBUSD=(b*1E18)/a;
                     BUSDperBNB=(a*1E18)/b;
                     return(BNBperBUSD,BUSDperBNB);
            }

        function bnbtoflafel() public view returns (uint256 PerLP)
        {
                      uint256 c;
                      uint256 a;
                      uint256 b;
                      uint256 BNBperflafel;
                      uint256 flafelperBNB;
                      uint256 Total_Flafel_In_BNB;
                      uint256 usdt1;
                      uint256 usdt2;

                     (a, b, c) = LpToken.getReserves();
                     BNBperflafel=(b*1E18)/a;
                     flafelperBNB=(a*1E18)/b;

                    uint256 falafel_in_bnb = (a*BNBperflafel)/1E18;
                    (uint256 x ,uint256 y ) = bnbtobusd();
                    uint256 flafelTousdt = (falafel_in_bnb*1E18) / x;
                    uint256 bnbTousdt =  (b*1E18)/ x ;

                    uint256 lpValue = (flafelTousdt+bnbTousdt)*1E18/totalSupplyOfLpToken();

                     return lpValue;
            
            }

        function TokenInLP() public view returns(uint256 TokenIn1LP) {

                    (uint256 Tokens,uint256 b,uint256 c) = LpToken.getReserves();
                    TokenIn1LP=(Tokens*1E18)/totalSupplyOfLpToken();
        
        }   

    // flafel address= 0x05CEB2E500563DC6ec477611F3bA40a94EBDd53C
    // Flafel LPtoken= 0x9746C52F564D437F1C68A0CeC8c26295fCfCB0FD;
    //    address bnbTOBusd= 0xF855E52ecc8b3b795Ac289f85F6Fd7A99883492b;
   
    




}