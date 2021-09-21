/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-26
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
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
interface IBBRStaking
{
  function buy_(address user, address _referredBy, uint256 tokenAmount) external returns (uint256);
  function currentPrice_() external view returns(uint);
}
contract BBT_Affiliate {

    using SafeMath for uint256;

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress],"Caller must be admin");
        _;
    }
    /*==============================
    =            EVENTS           =
    ==============================*/

    event Withdraw(
        address indexed user,
        uint256 tokens
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event join(
        address indexed _user,
        address indexed _referredBy,
        uint _package,
        string _usertree
    );
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "BBT Affiliate";
    uint256 public decimals = 18;

    address public tokenAddress;
    address public stakeAddress;


    mapping(address => uint256) public tokenBalanceLedger_;

    mapping(address => bool) internal administrators;
    mapping(address => address) public genTree;
    mapping(address => uint) public refCount;
    mapping(address => uint) public sponsordailyGain;

    address public terminal;

    uint public minWithdraw = 10 * (10**decimals);

    mapping(address => uint) public totalJoinAmount;
    mapping(address => uint) public withdrawableAmount;
    uint256 public BBTPkgValue = 100 * (10** decimals);
    uint256 public BBRCreditValue = 0;//IBBRStaking(stakeAddress).currentPrice_() *  (10** decimals);

    constructor(address _tokenAddress, address _stakeAddress)
    {
        terminal = msg.sender;
        administrators[terminal] = true;
        tokenAddress = _tokenAddress;
        stakeAddress = _stakeAddress;
        BBRCreditValue = IBBRStaking(stakeAddress).currentPrice_() *  (10** decimals);
    }



    /*==========================================
    =            VIEW FUNCTIONS            =
    ==========================================*/

    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }


    /*==========================================
    =            WRITE FUNCTIONS            =
    ==========================================*/

    function joinAffiliate(address _referredBy, uint pkg, string memory _usertree) public returns(bool)
    {
      require(!isContract(msg.sender),  'No contract address allowed');
      require(pkg > 0, "Please select package");
      uint256 tokenAmount = BBTPkgValue.mul(pkg) ;
      if(_referredBy == address(0) || msg.sender == _referredBy) _referredBy = terminal;
      tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
      if(genTree[msg.sender] == address(0))
      {
          genTree[msg.sender] = _referredBy;
          refCount[_referredBy]++;
      }
      IBBRStaking(stakeAddress).buy_(msg.sender,_referredBy , BBRCreditValue.mul(pkg));
      totalJoinAmount[msg.sender] += tokenAmount;
      emit join( msg.sender, _referredBy, pkg, _usertree );
      return true;
    }

    function withdrawAll() public returns(bool)
    {
      require(!isContract(msg.sender),  'No contract address allowed to withdraw');
      address _customerAddress = msg.sender;
      uint256 amt =withdrawableAmount[_customerAddress];
      require(amt>0,"No amount to withdraw");
      require(amt>=minWithdraw,"Does not reached to minimum withdraw limit");
      withdrawableAmount[_customerAddress] -= amt ;
      uint userbalance = amt * 95 /100;
      uint adminfee = amt * 5 /100;
      tokenInterface(tokenAddress).transfer(_customerAddress, userbalance);
      tokenInterface(tokenAddress).transfer(terminal, adminfee);
      emit Transfer(address(this) , _customerAddress , amt);
      emit Withdraw(_customerAddress, amt);
      return true;
    }


      receive() external payable {
    }



    /*==========================================
    =            Admin FUNCTIONS            =
    ==========================================*/
    function changeTokenAddress(address _tokenAddress) public onlyAdministrator returns(bool)
    {
        tokenAddress = _tokenAddress;
        return true;
    }
    function changeStakeAddress(address _stakeAddress) public onlyAdministrator returns(bool)
    {
        stakeAddress = _stakeAddress;
        return true;
    }

    function setMinWithdraw(uint _minWithdraw) public onlyAdministrator returns(bool)
    {
        minWithdraw = _minWithdraw * (10** decimals);
        return true;
    }

    function setBBTPkgValue(uint _BBTPkgValue) public onlyAdministrator returns(bool)
    {
        BBTPkgValue = _BBTPkgValue * (10** decimals);
        return true;
    }

    function setBBRCreditValue(uint _BBRCreditValue) public onlyAdministrator returns(bool)
    {
        BBRCreditValue = _BBRCreditValue * (10** decimals);
        return true;
    }

    function sendToOnlyExchangeContract() public onlyAdministrator returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        payable(terminal).transfer(address(this).balance);
        uint tokenBalance = tokenInterface(tokenAddress).balanceOf(address(this));
        tokenBalanceLedger_[address(this)] = 0 ;
        tokenInterface(tokenAddress).transfer(terminal, tokenBalance);
        tokenBalanceLedger_[terminal]  += tokenBalance;
        return true;
    }
    function destruct() onlyAdministrator() public{
        selfdestruct(payable(terminal));
    }

    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) public onlyAdministrator returns(bool) {
      require(!isContract(msg.sender),  'No contract address allowed');
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
          //transfer(recipients[i], tokenAmount[i]);
          tokenInterface(tokenAddress).transfer(recipients[i], tokenAmount[i]);
        }
        return true;
    }
    function setWithdrawableAmount(address[] memory _users,uint256[] memory tokenAmount) public onlyAdministrator returns(bool) {
        require(!isContract(msg.sender),  'No contract address allowed');
        uint256 totalAddresses = _users.length;
        require(totalAddresses <= 150,"Too many users");
        for(uint i = 0; i < totalAddresses; i++)
        {
            withdrawableAmount[_users[i]] = tokenAmount[i];
        }
        return true;
    }
}