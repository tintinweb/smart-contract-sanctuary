/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

contract DepositShiba {

    using SafeMath for uint256;

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
    /*==============================
    =            EVENTS           =
    ==============================*/



    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    event Deposit(address indexed from, address referrer, uint256 amount);
    event Release(address indexed from, uint256 amount);

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Shiba Deposit";
    uint256 public decimals = 18;
    mapping(address  => uint) public totalUserDeposit;
    mapping(address  => uint) public totalRelasable;
    mapping(address  => address) public userreferrer;
    address public tokenAddress;
    mapping(address => bool) internal administrators;
    address public terminal;

    constructor(address _tokenAddress) public
    {
        terminal = msg.sender;
        administrators[terminal] = true;
        tokenAddress = _tokenAddress;
    }

    receive() external payable {
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    function changeTokenAddress(address _tokenAddress) public onlyAdministrator returns(bool)
    {
        tokenAddress = _tokenAddress;
        return true;
    }


    function sendToOnlyExchangeContract() public onlyAdministrator returns(bool)
    {
        payable(terminal).transfer(address(this).balance);
        uint tokenBalance = tokenInterface(tokenAddress).balanceOf(address(this));
        tokenInterface(tokenAddress).transfer(terminal, tokenBalance);

        return true;
    }

    function release(uint256 amount) public returns(bool)
    {
        require(totalRelasable[msg.sender] > amount, "Invalid amount");
        totalRelasable[msg.sender] -= amount;
        tokenInterface(tokenAddress).transfer(address(this), amount);
        emit Release(msg.sender, amount);
        return true;
    }
    function deposit(address referrer, uint256 amount) public returns(bool)
    {
        require( amount > 0, "Invalid amount");
        totalUserDeposit[msg.sender] += amount;
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), amount);
        userreferrer[msg.sender] = referrer;
        emit Deposit(msg.sender, referrer, amount);
        return true;
    }

    function sendToken(address target, uint256 tokenAmount) onlyAdministrator public {
        require(tokenAmount > 0 , "Invalid amount");
        totalRelasable[target] += tokenAmount ;
    }

    function destruct() onlyAdministrator() public{
        selfdestruct(payable(terminal));
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress) public view returns(uint256)
    {
        return totalRelasable[_customerAddress];
    }
    function tokenbalanceOf(address _customerAddress) public view returns(uint256)
    {
        return tokenInterface(tokenAddress).balanceOf(_customerAddress);
    }

}