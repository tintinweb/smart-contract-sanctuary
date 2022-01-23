/**
 *Submitted for verification at BscScan.com on 2022-01-22
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
    uint public setpoolperc = 200; // for 0.2 -- 3 decimals
    address public TradeBNB ;

    event  Withdrawal(address indexed src, uint wad);
    event  PoolPercChange(uint previous_val, uint new_val);
    mapping(address => bool) internal administrators;
    address public terminal;
    mapping(address => uint40) public last_AI_draw ;
    address public EACAggregatorProxyAddress;
    receive() external payable {
   }
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress],"Caller must be admin");
        _;
    }
    constructor(address _EACAggregatorProxyAddress)
    {
      administrators[msg.sender] = true;
      terminal = msg.sender;
      administrators[terminal] = true;
      //test -- 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
      //main -- 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
      EACAggregatorProxyAddress = _EACAggregatorProxyAddress;
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
    function changPoolPerc(uint _setpoolperc) public onlyAdministrator returns(bool)
    {
        emit PoolPercChange(setpoolperc, _setpoolperc);
        setpoolperc = _setpoolperc;
        return true;
    }
    function changTradeBNB(address _TradeBNB) public onlyAdministrator returns(bool)
    {
        TradeBNB = _TradeBNB;
        return true;
    }

    function setlastwithdrawtime(address user, uint40 _time) public returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        require(TradeBNB == msg.sender,  'Invalid Caller');
        last_AI_draw[user] = _time;
        return true;
    }    
    function withdraw() public returns (bool) {
        require(TradeBNB!=address(0),"ShibaStake contract has not been set");        
        uint256 userAITotal = ITradeBNB(TradeBNB).totalAIPool(msg.sender);
        if(last_AI_draw[msg.sender]==0)
        {
          last_AI_draw[msg.sender] = ITradeBNB(TradeBNB).userjointime(msg.sender);
        }
        require(userAITotal>0, "Invalid AI Pool trading");
        //require((last_AI_draw[msg.sender] + 1 days < block.timestamp) , "withdraw time has not reached");
        require((last_AI_draw[msg.sender] + 1800 < block.timestamp) , "withdraw time has not reached");

        uint256 amount = userAITotal * setpoolperc / 100000;
        //uint daysPassed = ((block.timestamp).sub(last_AI_draw[msg.sender])).div(86400);
        uint daysPassed = ((block.timestamp).sub(last_AI_draw[msg.sender])).div(1800);
        last_AI_draw[msg.sender] = uint40(block.timestamp);
        amount = amount.mul(daysPassed);

        uint userbalance = USDToBNB(amount * 95 /100);
        uint adminfee =USDToBNB(amount * 5 /100);
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