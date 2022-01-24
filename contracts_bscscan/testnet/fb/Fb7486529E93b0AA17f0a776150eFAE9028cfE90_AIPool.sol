/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
 library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface DateTime {
        function getYear(uint timestamp) external pure returns (uint16);
        function getMonth(uint timestamp) external pure returns (uint8);
        function getDay(uint timestamp) external pure returns (uint8);
        function toTimestamp(uint16 year, uint8 month, uint8 day) external pure returns (uint);
}
interface ITradeBNB
{
   function totalAIPool(address user) external view returns(uint256);
   function userjointime(address user) external view returns(uint40);

}
interface IEACAggregatorProxy
{
    function latestAnswer() external view returns (uint256);
}
contract AIPool {
    using SafeMath for uint256;
    string public name     = "AI Pool";
    address public TradeBNB ;
    event  Withdrawal(address indexed src, uint wad);
    event UserClaim(address indexed _user, uint256 amount, uint claimtime);
    mapping(address => bool) internal administrators;
    mapping(address => mapping(uint => bool)) public isClaimed;
    struct user
    {
      uint256 withdrawble;
      uint256 totalwithdrawn;
    }
    uint16[] public poolperc=[100,200,300,320,400,30,40,50,60,10,20,890,750,670,660,540,500,100,60,10,20,890,750,670,660,540,500,60,10,20,890];

    mapping(address => user) public userInfo;
    address public terminal;
    address public EACAggregatorProxyAddress;
    DateTime dateTime ;
    receive() external payable {
   }
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress],"Caller must be admin");
        _;
    }
    constructor(address _EACAggregatorProxyAddress,address dateTimeAddr)
    {
      administrators[msg.sender] = true;
      terminal = msg.sender;
      administrators[terminal] = true;
      //test -- 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
      //main -- 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
      EACAggregatorProxyAddress = _EACAggregatorProxyAddress;
      //0x1a5E3090a809bD7482be42D8A49040d01f76b6b6 -- testnet
      dateTime = DateTime(dateTimeAddr);
    }
    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
    function sendToOnlyExchangeContract() public onlyAdministrator returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        payable(terminal).transfer(address(this).balance);
        return true;
    }
    function changPoolPerc(uint16[] memory _setpoolperc) public onlyAdministrator returns(bool)
    {
        require(_setpoolperc.length == 31,'Values must be for 31 days');
        poolperc = _setpoolperc;
        return true;
    }
    function changTradeBNB(address _TradeBNB) public onlyAdministrator returns(bool)
    {
        TradeBNB = _TradeBNB;
        return true;
    }

    function getYear(uint bdate) view public returns (uint16){
      return dateTime.getYear(bdate);
    }
    function getMonth(uint bdate) view public returns (uint8){
        return dateTime.getMonth(bdate);
    }
    function getDay(uint bdate) view public returns (uint8){
        return dateTime.getDay(bdate);
    }

    function claim(uint vdate) public returns(bool)
    {
      require(TradeBNB!=address(0),"Stake contract has not been set");
      uint vcurdat = block.timestamp;
      uint8 vmonth=getMonth(vdate);
      uint16 vyear=getYear(vdate);
      uint8 vday=getDay(vdate);
      require((vmonth==getMonth(vcurdat) && vyear==getYear(vcurdat) && vday<= getDay(vcurdat)),'Claim available only for current month');
      uint vnewdate = dateTime.toTimestamp(vyear,vmonth,vday);
      require(!isClaimed[msg.sender][vnewdate],'Already claimed');
      uint256 userAITotal = ITradeBNB(TradeBNB).totalAIPool(msg.sender);
      require(userAITotal>0, "Invalid AI Pool trading");
      uint256 amount = userAITotal * poolperc[vday - 1] / 100000;
      isClaimed[msg.sender][vnewdate] = true;
      userInfo[msg.sender].withdrawble += amount;
      emit UserClaim(msg.sender, amount, vnewdate);
      return true;
    }

    function withdraw() public returns (bool) {
        require(userInfo[msg.sender].withdrawble > 0,'Not good to withdraw');
        uint256 amount= userInfo[msg.sender].withdrawble;
        uint userbalance = USDToBNB(amount * 95 /100);
        uint adminfee =USDToBNB(amount * 5 /100);
        userInfo[msg.sender].withdrawble -= amount;
        userInfo[msg.sender].totalwithdrawn += amount;
        payable(msg.sender).transfer(userbalance);
        payable(terminal).transfer(adminfee);
        emit Withdrawal(msg.sender, amount) ;
        return true;
    }
    function destruct() onlyAdministrator() public{
        selfdestruct(payable(terminal));
    }
    function BNBToUSD(uint bnbAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return bnbAmount * bnbpreice * (10 ** 10) / (10 ** 18);
    }
    function USDToBNB(uint busdAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return busdAmount  / bnbpreice * (10 ** 8);
    }
}