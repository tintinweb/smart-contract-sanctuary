/**
 *Submitted for verification at Etherscan.io on 2021-07-06
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
    event Deposit(address indexed from, address referrer, uint256 amount, address bncwallet);
    event Release(address indexed from, uint256 amount);

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Shiba Deposit";
    uint256 public decimals = 18;
    mapping(address  => uint) public totalUserDeposit;
    mapping(address  => uint) public totalRelasable;
    mapping(address  => address) public userreferrer;
    mapping(address  => address) public userbncwallet;
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

    function release(address useraddress, uint256 amount) public onlyAdministrator returns(bool)
    {
      require(!isContract(msg.sender),  'No contract address allowed to release');
        require(totalRelasable[useraddress] >= amount, "Invalid amount");
        //totalRelasable[useraddress] -= amount;
        tokenInterface(tokenAddress).transfer(useraddress, amount);
        emit Release(useraddress, amount);
        return true;
    }
    function deposit(address referrer, uint256 amount,address bncwallet) public returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed to deposit');
        require( amount > 0, "Invalid amount");
        totalUserDeposit[msg.sender] += amount;
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), amount);
        userreferrer[msg.sender] = referrer;
        userbncwallet[msg.sender]= bncwallet;
        emit Deposit(msg.sender, referrer, amount, bncwallet);
        return true;
    }

    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    function sendToken(address[] memory recipients,uint256[] memory tokenAmount) public onlyAdministrator returns(bool) {
        require(!isContract(msg.sender),  'No contract address allowed to Send Token');
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          totalRelasable[recipients[i]] += tokenAmount[i] ;
        }
        return true;
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