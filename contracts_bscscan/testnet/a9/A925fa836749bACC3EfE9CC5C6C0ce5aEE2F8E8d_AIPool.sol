/**
 *Submitted for verification at BscScan.com on 2021-07-15
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

interface tokenInterface
{
   function transfer(address _to, uint _amount) external returns (bool);
   function transferFrom(address _from, address _to, uint _amount) external returns (bool);
   function balanceOf(address user) external view returns(uint);
}
interface IStakeShiba
{
   function totalAIPool(address user) external view returns(uint256);
   function tokenAddress() external view returns(address);
   function userjointime(address user) external view returns(uint40);

}
contract AIPool {
    using SafeMath for uint256;
    string public name     = "Shiba AI";
    uint public setpoolperc = 200; // for 0.2 -- 3 decimals
    address public stakeshiba ;
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  TransferAI(address indexed src, address indexed dst, uint256 wad, uint percent, uint _daysPassed);
    event  Withdrawal(address indexed src, uint wad);
    event  PoolPercChange(uint previous_val, uint new_val);
    mapping(address => bool) internal administrators;
    address public terminal;
    mapping(address => uint40) public last_AI_draw ;
    receive() external payable {
   }
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress],"Caller must be admin");
        _;
    }
    constructor() public
    {
      administrators[msg.sender] = true;
      terminal = msg.sender;
      administrators[terminal] = true;
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
        address token_Address =  IStakeShiba(stakeshiba).tokenAddress();
        uint tokenBalance = tokenInterface(token_Address).balanceOf(address(this));
        tokenInterface(token_Address).transfer(terminal, tokenBalance);
        return true;
    }
    function changPoolPerc(uint _setpoolperc) public onlyAdministrator returns(bool)
    {
        emit PoolPercChange(setpoolperc, _setpoolperc);
        setpoolperc = _setpoolperc;
        return true;
    }
    function changStakeShiba(address _stakeshiba) public onlyAdministrator returns(bool)
    {
        stakeshiba = _stakeshiba;
        return true;
    }

    function setlastwithdrawtime(address user, uint40 _time) public returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        require(stakeshiba == msg.sender,  'Invalid Caller');
        last_AI_draw[user] = _time;
        return true;
    }

    function withdraw() public returns (bool) {
        require(stakeshiba!=address(0),"ShibaStake contract has not been set");
        address token_Address =  IStakeShiba(stakeshiba).tokenAddress();
        uint256 userAITotal = IStakeShiba(stakeshiba).totalAIPool(msg.sender);
        if(last_AI_draw[msg.sender]==0)
        {
          last_AI_draw[msg.sender] = IStakeShiba(stakeshiba).userjointime(msg.sender);
        }
        require(userAITotal>0, "Invalid AI Pool trading");
        //require((last_AI_draw[msg.sender] + 1 days < block.timestamp) , "withdraw time has not reached");
        require((last_AI_draw[msg.sender] + 1800 < block.timestamp) , "withdraw time has not reached");

        uint256 amount = userAITotal * setpoolperc / 100000;
        //uint daysPassed = ((block.timestamp).sub(last_AI_draw[msg.sender])).div(86400);
        uint daysPassed = ((block.timestamp).sub(last_AI_draw[msg.sender])).div(1800);
        last_AI_draw[msg.sender] = uint40(block.timestamp);
        amount = amount.mul(daysPassed);

        uint userbalance = amount * 95 /100;
        uint adminfee = amount * 5 /100;
        tokenInterface(token_Address).transfer(msg.sender, userbalance);
        tokenInterface(token_Address).transfer(terminal, adminfee);
        emit TransferAI(address(this),  msg.sender, userbalance, setpoolperc, daysPassed);
        emit Transfer(address(this),  terminal , adminfee);
        return true;
    }
    function destruct() onlyAdministrator() public{
        selfdestruct(payable(terminal));
    }
}