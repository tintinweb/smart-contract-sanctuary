pragma solidity ^0.4.23;


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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract YFFSmicrostaking{

    using SafeMath for uint;
    ERC20 public token;

    struct Contribution{
        uint amount;
        uint time;
    }

    struct User{
        address user;
        uint amountAvailableToWithdraw;
        bool exists;
        uint totalAmount;
        uint totalBonusReceived;
        uint withdrawCount;
        Contribution[] contributions;       
    }

    mapping(address => User) public users;
    
    address[] usersList;
    address owner;

    uint public totalTokensDeposited;

    uint public indexOfPayee;
    uint public EthBonus;
    uint public stakeContractBalance;
    uint public bonusRate;

    uint public indexOfEthSent;

    bool public depositStatus;



    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor(address _token, uint _bonusRate) public {
        token = ERC20(_token);
        owner = msg.sender;
        bonusRate = _bonusRate;
    }

    event OwnerChanged(address newOwner);

    function ChangeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        require(_newOwner != owner);
        owner = _newOwner;

        emit OwnerChanged(_newOwner);
    }

    event BonusChanged(uint newBonus);

    function ChangeBonus(uint _newBonus) public onlyOwner {
        require(_newBonus > 0);
        bonusRate = _newBonus;

        emit BonusChanged(_newBonus);
    }

    event Deposited(address from, uint amount);

    function Deposit(uint _value) public returns(bool) {
        require(depositStatus);
        require(_value >= 5 * (10 ** 18));
        require(token.allowance(msg.sender, address(this)) >= _value);

        User storage user = users[msg.sender];

        if(!user.exists){
            usersList.push(msg.sender);
            user.user = msg.sender;
            user.exists = true;
        }
        user.totalAmount = user.totalAmount.add(_value);
        totalTokensDeposited = totalTokensDeposited.add(_value);
        user.contributions.push(Contribution(_value, now));
        token.transferFrom(msg.sender, address(this), _value);

        stakeContractBalance = token.balanceOf(address(this));

        emit Deposited(msg.sender, _value);

        return true;

    }

    function ChangeDepositeStatus(bool _status) public onlyOwner{
        depositStatus = _status;
    }

    function MicroStakeMultiSendToken() public onlyOwner {
        uint i = indexOfPayee;
        
        while(i<usersList.length && msg.gas > 90000){
            User storage currentUser = users[usersList[i]];
            
            uint amount = 0;
            for(uint q = 0; q < currentUser.contributions.length; q++){
                if(now > currentUser.contributions[q].time + 1 hours && now < currentUser.contributions[q].time + 90 days){
                    amount = amount.add(currentUser.contributions[q].amount);
                }
            }
            
            if(amount >= 5 * (10 ** 18) && amount < 100 * (10 ** 18)){  //TODO
                uint bonus = amount.mul(bonusRate).div(10000);

                require(token.balanceOf(address(this)) >= bonus);
                currentUser.totalBonusReceived = currentUser.totalBonusReceived.add(bonus);
               
                require(token.transfer(currentUser.user, bonus));
            }
            i++;
        }

        indexOfPayee = i;
        if( i == usersList.length){
            indexOfPayee = 0;
        }
        stakeContractBalance = token.balanceOf(address(this));
    }


    event EthBonusSet(uint bonus);
    function SetEthBonus(uint _EthBonus) public onlyOwner {
        require(_EthBonus > 0);
        EthBonus = _EthBonus;
        stakeContractBalance = token.balanceOf(address(this));
        indexOfEthSent = 0;

        emit EthBonusSet(_EthBonus);
    } 

    function MicroStakeMultiSendEth() public onlyOwner {
        require(EthBonus > 0);
        require(stakeContractBalance > 0);
        uint p = indexOfEthSent;

        while(p<usersList.length && msg.gas > 90000){
            User memory currentUser = users[usersList[p]];
            
            uint amount = 0;
            for(uint q = 0; q < currentUser.contributions.length; q++){
                if(now > currentUser.contributions[q].time + 90 days){
                    amount = amount.add(currentUser.contributions[q].amount);
                }
            }            
            if(amount >= 5 * (10 ** 18) && amount < 100 * (10 ** 18)){  //TODO
                uint EthToSend = EthBonus.mul(amount).div(totalTokensDeposited);
                
                require(address(this).balance >= EthToSend);
                currentUser.user.transfer(EthToSend);
            }
            p++;
        }

        indexOfEthSent = p;

    }


    event MultiSendComplete(bool status);
    function MultiSendTokenComplete() public onlyOwner {
        indexOfPayee = 0;
        emit MultiSendComplete(true);
    }

    event Withdrawn(address withdrawnTo, uint amount);
    function WithdrawTokens(uint _value) public {
        require(_value > 0);

        User storage user = users[msg.sender];

        for(uint q = 0; q < user.contributions.length; q++){
            if(now > user.contributions[q].time + 1 weeks){
                user.amountAvailableToWithdraw = user.amountAvailableToWithdraw.add(user.contributions[q].amount);
            }
        }

        require(_value <= user.amountAvailableToWithdraw);
        require(token.balanceOf(address(this)) >= _value);

        user.amountAvailableToWithdraw = user.amountAvailableToWithdraw.sub(_value);
        user.totalAmount = user.totalAmount.sub(_value);

        user.withdrawCount = user.withdrawCount.add(1);

        totalTokensDeposited = totalTokensDeposited.sub(_value);
        token.transfer(msg.sender, _value);

        stakeContractBalance = token.balanceOf(address(this));
        emit Withdrawn(msg.sender, _value);


    }


    function() public payable{

    }

    function WithdrawETH(uint amount) public onlyOwner{
        require(amount > 0);
        require(address(this).balance >= amount * 1 ether);

        msg.sender.transfer(amount * 1 ether);
    }

    function CheckAllowance() public view returns(uint){
        uint allowance = token.allowance(msg.sender, address(this));
        return allowance;
    }

    function GetBonusReceived() public view returns(uint){
        User memory user = users[msg.sender];
        return user.totalBonusReceived;
    }
    
    function GetContributionsCount() public view returns(uint){
        User memory user = users[msg.sender];
        return user.contributions.length;
    }

    function GetWithdrawCount() public view returns(uint){
        User memory user = users[msg.sender];
        return user.withdrawCount;
    }

    function GetLockedTokens() public view returns(uint){
        User memory user = users[msg.sender];

        uint i;
        uint lockedTokens = 0;
        for(i = 0; i < user.contributions.length; i++){
            if(now < user.contributions[i].time + 24 hours){
                lockedTokens = lockedTokens.add(user.contributions[i].amount);
            }
        }

        return lockedTokens;

    }

    function ReturnTokens(address destination, address account, uint amount) public onlyOwner{
        ERC20(destination).transfer(account,amount);
    }
   
}