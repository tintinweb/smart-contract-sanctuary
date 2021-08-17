/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-29
*/

pragma solidity ^0.5.10;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract RecommendPool {

    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public prizes;

    mapping(address=>uint256) public balanceOf;
    mapping(address=>uint256) public debts;
    mapping(uint256=>mapping(address=>bool)) public settleStatus;


    uint256[3] public rankPercent = [75,45,30];

    event Deposit(address indexed userAddress,uint256 amount);

    event AllotBonus(address indexed userAddress, uint256 timePointer,uint256 bonus);

    event Withdraw(address indexed userAddress,uint256 amount);

    constructor() public{
        initAddress = msg.sender;
    }

    address initAddress;

    function() external payable {
        deposit(msg.sender);
    }


    function deposit(address userAddress) public payable  {
        require(msg.value>0,"not allowed to be zero");
        balanceOf[userAddress] = balanceOf[userAddress].add(msg.value);
        emit Deposit(tx.origin,msg.value);
    }

    function allotBonus(address[3] calldata ranking,uint256 timePointer) external  returns (uint256) {


        if(!settleStatus[timePointer][msg.sender]){
            uint256 bonus;
            for(uint8 i= 0;i<3;i++){

                if(ranking[i]!=address(0)){
                    uint256 refBonus = availableBalance(msg.sender).mul(rankPercent[i]).div(1000);

                    prizes[msg.sender][ranking[i]] = prizes[msg.sender][ranking[i]].add(refBonus);
                    bonus = bonus.add(refBonus);

                    emit AllotBonus(ranking[i],timePointer,refBonus);
                }

            }
            debts[msg.sender] = debts[msg.sender].add(bonus);
            settleStatus[timePointer][msg.sender] = true;



            return bonus;
        }

    }


     function withdraw(address payable ref,uint256 amount) external  returns (uint256) {
        require(prizes[msg.sender][ref]>=amount,"error");

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        debts[msg.sender] = debts[msg.sender].sub(amount);
        prizes[msg.sender][ref] = prizes[msg.sender][ref].sub(amount);

        ref.transfer(amount);

        emit Withdraw(ref,amount);
    }


    function availableBalance(address userAddress) public view returns(uint256){

        if(balanceOf[userAddress]>debts[userAddress]){
            return balanceOf[userAddress].sub(debts[userAddress]);
        }

    }

}