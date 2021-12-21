/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

/**
 *Submitted for verification at polygonscan.com on 2021-12-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RaceICO is Ownable {
    using SafeMath for uint256;
    bool public startSale=false;
    bool public startReward=false;
    address public seedAddr;
    address public teamAddr;
    address public advisorAddr;
    address public reserveAddr;
    address public marketingAddr;
    address public developmentAddr;
    address public RACEADDR;
    uint256 public seedStartrewardTime;
     uint256 public seedUptrewardTime;
    uint256 public icoStartrewardTime;
    uint256 public icoUptRewardTime;
    uint256 public teamStartRewardTime;
    uint256 public teamUptRewardTime;
    uint256 public adviserStartRewardTime;
    uint256 public advisorUptRewardTime;
    uint256 public reserveStartRewardTime;
    uint256 public reservUptRewardTime;
    uint256 public marketingStartRewardTime;
    uint256 public marketUptRewardTime;
    uint256 public developmentStartRewardTime;
    uint256 public devUptRewardTime;
    uint256 public earnRewardStartRewardTime;
    uint256 public earnUptRewardTime;
    uint256 public seedAlloc=10000000e18;
    uint256 public ICOAlloc=20000000e18;
    uint256 public availICO=20000000e18;
    uint256 public devAlloc=16200000e18;
    uint256 public teamAlloc=24000000e18;
    uint256 public advisorAlloc=16000000e18;
    uint256 public reservAlloc=36000000e18;
    uint256 public earnrewardAlloc=56000000e18;
    uint256 public marketAlloc=10000000e18;
    uint256 public per_matic_price;

    event SaleEvent(address from,address indexed to,uint256 saletoken);
    constructor(address _seedAddr,address _teamAddr,address _advisorAddr,address _marketingAddr,address _devaddr,address _raceaddr) public {
       seedAddr=_seedAddr;
       teamAddr=_teamAddr;
       advisorAddr=_advisorAddr;
       reserveAddr=_marketingAddr;
       marketingAddr=_marketingAddr;
       developmentAddr=_devaddr;
       RACEADDR=_raceaddr;
    }   

    function openSale(uint256 _maticprice) public onlyOwner() {
      startSale=true;
      startReward=true;
      per_matic_price=_maticprice;
    //seedAddr
      seedStartrewardTime= (block.timestamp).add(50 days);
      seedUptrewardTime=seedStartrewardTime;
      //ICO
      availICO = availICO.div(4);
      ICOAlloc = ICOAlloc.sub(availICO);
      icoStartrewardTime = (block.timestamp).add(1 days);
      //teamAddr
      teamStartRewardTime=(block.timestamp).add(60 days);
      teamUptRewardTime=teamStartRewardTime;
      //advisorAddr
      adviserStartRewardTime=(block.timestamp).add(60 days);
      advisorUptRewardTime=adviserStartRewardTime;
      //reserveAddr
      reserveStartRewardTime=(block.timestamp).add(50 days);
      reservUptRewardTime=reserveStartRewardTime;
      //public sale
      IERC20(RACEADDR).transfer(_msgSender(),10000000e18);
    //marketingAddr
      marketingStartRewardTime=(block.timestamp);
      marketUptRewardTime=marketingStartRewardTime;
      //developmentAddr
      developmentStartRewardTime=(block.timestamp);
      devUptRewardTime=developmentStartRewardTime;
      IERC20(RACEADDR).transfer(developmentAddr,180000e18);

      // pay to earns 
    earnRewardStartRewardTime=(block.timestamp).add(90 days);
    earnUptRewardTime=earnRewardStartRewardTime;
    }

    function setAdminFee(uint256 _maticprice) public onlyOwner()
    {
        per_matic_price=_maticprice;
    }

    function BuyRace() payable public {
        uint256 saletoken = (msg.value).mul(per_matic_price).div(1e18);
        require(startSale==true,"Sale Not Enabled");
        require(availICO >= saletoken,"ICO Sale Token Ended");
        availICO=availICO.sub(saletoken);
        IERC20(RACEADDR).transfer(_msgSender(),saletoken);
        emit SaleEvent(address(this),msg.sender,saletoken);
    }

    function safeGuard(address _token,uint256 amount) public onlyOwner() 
    {
        if(_token==address(0))
        {
            payable(owner()).transfer(amount);
        }
        else
        {
             IERC20(RACEADDR).transfer(owner(),amount);
        }
    }

    function updateICO(uint256 amount) public onlyOwner() {
      availICO=availICO.add(amount);  
    }
    function updateSaleRewardtatus(bool _sale,bool _reward) public onlyOwner() {
       startSale=_sale;
       startReward=_reward;
    }
    function seedRewardCalc() public  view returns(uint256){
        require(seedStartrewardTime<=block.timestamp);
        require(startReward==true);
        uint256 seedcalc = seedAlloc.div(47304000); // 18 months
        uint256 seeddiff=(block.timestamp).sub(seedUptrewardTime);
        return seedcalc.mul(seeddiff);
    
    }
    
    function claimSeedReward() public {
        require(msg.sender==seedAddr,"Seed Address only Allowed");
        uint256 claimAmt=seedRewardCalc();
        require(seedAlloc>=claimAmt,"Seed Alloc Insufficient");
        seedAlloc=seedAlloc.sub(claimAmt);
        seedUptrewardTime=(block.timestamp);
        IERC20(RACEADDR).transfer(seedAddr,claimAmt);

    }

    function icoRewardCalc() public  view returns(uint256){
        require(icoStartrewardTime<=block.timestamp);
        require(startReward==true);
        uint256 icocalc = ICOAlloc.div(7776000); // 3 months
        uint256 icodiff=(block.timestamp).sub(icoUptRewardTime);
        return icocalc.mul(icodiff);
    
    }

    function claimIcoReward() public onlyOwner() {
        uint256 claimicoAmt=icoRewardCalc();
        require(ICOAlloc>=claimicoAmt,"ICO Alloc Insufficient");
        ICOAlloc=ICOAlloc.sub(claimicoAmt);
        icoUptRewardTime=(block.timestamp);
        IERC20(RACEADDR).transfer(owner(),claimicoAmt);
    }

     function teamRewardCalc() public  view returns(uint256){
        require(teamStartRewardTime<=block.timestamp);
        require(startReward==true);
        uint256 teamcalc = teamAlloc.div(108864000); // 42 months
        uint256 teamdiff=(block.timestamp).sub(teamUptRewardTime);
        return teamcalc.mul(teamdiff);
    
    }

    function ClaimTeamReward() public {
         require(msg.sender==teamAddr,"Team Address only Allowed");
          uint256 claimteamAmt=teamRewardCalc();
          require(teamAlloc>=claimteamAmt,"Team Alloc Insufficient");
          teamAlloc=teamAlloc.sub(claimteamAmt);
          teamUptRewardTime=(block.timestamp);
          IERC20(RACEADDR).transfer(owner(),claimteamAmt);
    }

    function advisorRewardCalc() public  view returns(uint256){
        require(adviserStartRewardTime<=block.timestamp);
        require(startReward==true);
        uint256 advcalc = advisorAlloc.div(108864000); // 42 months
        uint256 advdiff=(block.timestamp).sub(advisorUptRewardTime);
        return advcalc.mul(advdiff);
    
    }

     function ClaimAdvisorReward() public {
         require(msg.sender==advisorAddr,"Advisor Address only Allowed");
          uint256 claimadvAmt=advisorRewardCalc();
          require(advisorAlloc>=claimadvAmt,"Team Alloc Insufficient");
          advisorAlloc=advisorAlloc.sub(claimadvAmt);
          advisorUptRewardTime=(block.timestamp);
          IERC20(RACEADDR).transfer(advisorAddr,claimadvAmt);
    }

     function reservRewardCalc() public  view returns(uint256){
        require(reserveStartRewardTime<=block.timestamp);
        require(startReward==true);
        uint256 reservcalc = reservAlloc.div(155520000); // 60 months
        uint256 reservdiff=(block.timestamp).sub(reservUptRewardTime);
        return reservcalc.mul(reservdiff);
    }

     function ClaimReservReward() public {
         require(msg.sender==reserveAddr,"Reserv Address only Allowed");
          uint256 claimreservAmt=reservRewardCalc();
          require(reservAlloc>=claimreservAmt,"Reserv Alloc Insufficient");
          reservAlloc=reservAlloc.sub(claimreservAmt);
          reservUptRewardTime=(block.timestamp);
          IERC20(RACEADDR).transfer(reserveAddr,claimreservAmt);
    }

      function paytoearnRewardCalc() public  view returns(uint256){
        require(earnRewardStartRewardTime<=block.timestamp);
        require(startReward==true);
        uint256 paytoearncalc = earnrewardAlloc.div(108864000); // 42 months
        uint256 earndiff=(block.timestamp).sub(earnUptRewardTime);
        return paytoearncalc.mul(earndiff);
    }

      function EarnReservReward() public onlyOwner(){
          uint256 claimearnAmt=paytoearnRewardCalc();
          require(earnrewardAlloc>=claimearnAmt,"Earn Alloc Insufficient");
          earnrewardAlloc=earnrewardAlloc.sub(claimearnAmt);
          earnUptRewardTime=(block.timestamp);
          IERC20(RACEADDR).transfer(owner(),claimearnAmt);
    }

     function devRewardCalc() public  view returns(uint256){
        require(developmentStartRewardTime<=block.timestamp);
        require(startReward==true);
        uint256 devcalc = devAlloc.div(155520000); // 60 months
        uint256 devdiff=(block.timestamp).sub(devUptRewardTime);
        return devcalc.mul(devdiff);
    }

     function ClaimDevReward() public {
         require(msg.sender==developmentAddr,"Dev Address only Allowed");
          uint256 claimdevAmt=devRewardCalc();
          require(devAlloc>=claimdevAmt,"Dev Alloc Insufficient");
          devAlloc=devAlloc.sub(claimdevAmt);
          devUptRewardTime=(block.timestamp);
          IERC20(RACEADDR).transfer(developmentAddr,claimdevAmt);
    }

    function marketRewardCalc() public  view returns(uint256){
        require(marketingStartRewardTime<=block.timestamp);
        require(startReward==true);
        uint256 marcalc = marketAlloc.div(155520000); // 60 months
        uint256 mardiff=(block.timestamp).sub(marketUptRewardTime);
        return marcalc.mul(mardiff);
    }

      function ClaimMarketReward() public {
         require(msg.sender==marketingAddr,"Marketing Address only Allowed");
          uint256 claimmarAmt=marketRewardCalc();
          require(marketAlloc>=claimmarAmt,"Market Alloc Insufficient");
          marketAlloc=marketAlloc.sub(claimmarAmt);
          marketUptRewardTime=(block.timestamp);
          IERC20(RACEADDR).transfer(marketingAddr,claimmarAmt);
    }

    function updateValuts(address _seedAddr,address _teamAddr,address _advisorAddr,address _marketingAddr,address _devaddr) public onlyOwner()
    {
       seedAddr=_seedAddr;
       teamAddr=_teamAddr;
       advisorAddr=_advisorAddr;
       reserveAddr=_marketingAddr;
       marketingAddr=_marketingAddr;
       developmentAddr=_devaddr;
    }

}