//SourceUnit: etf.sol

pragma solidity ^0.5.4;

interface IERC20 {
    
    function balanceOf(address _owner) external view returns (uint256 );
    function allowance(address _owner, address _spender)external  view returns (uint256);
     function transfer(address _to, uint256 _value) external  returns (bool);
    function approve(address _spender, uint256 _value)external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool);
}

contract EntherFoundStake{
    using SafeMath for uint256;
      uint256 constant DAY = 1 days;            // 1 day
   

    uint256 constant POOL1ROI = 200;            // 0.02 %  
    uint256 constant POOL2ROI = 500;            // 0.05 %
    uint256 constant POOL3ROI = 10000;           // 1 %
    uint256 constant MONTH = 2592000;         // 1 month

    uint256 constant MAXPOOL1 = 360;          // 3.6 %
    uint256 constant MAXPOOL2 = 1825;         // 18.25 %
    uint256 constant MAXPOOL3 = 73000;        // 730 %

    uint256 public pool1Investments;
    uint256 public pool2Investments;
    uint256 public pool3Investments;

    address owner;
    
    // token address
    address public stakeToken ;

    struct User{
        uint256 investedAmount;
        uint256 withdrawnAmount;
        Deposit[] deposits;
        bool isExist;
        uint256 checkpoint;
    }

    struct Deposit{
        uint256 amount;
        uint256 start;
        uint256 withdrawn;
        bool principleWithdrawn;
    }

    mapping(address => User) public pool1Users;
    mapping(address => User) public pool2Users;
    mapping(address => User) public pool3Users;

    event depositedAmountSuccessFully(address _user, uint256 _amount, uint256 _pool);
    event withdrawnPoolAmountSuccessFully(uint256 _amount, uint256 _start, uint256 _now, uint256 _diff);
    event withdrawnPrincipleAmountSuccessFully(uint256 _amount, uint256 _start, uint256 _now, uint256 _diff);

    constructor(address _stakingToken) public{
        owner = msg.sender;
        stakeToken = _stakingToken;
    }
    
    
    
    
    function setStakingToken(address token) public{
        if(msg.sender ==owner){
            stakeToken = token;

        }
    }
    
    
    
    // internal functions
    function deposit(address _user, uint256 _pool, uint256 _amount) internal{
        if (_pool == 1) {
            pool1Users[_user].investedAmount = pool1Users[_user].investedAmount.add(_amount);
            pool1Users[_user].deposits.push(Deposit(_amount, block.timestamp, 0, false));
            pool1Investments = pool1Investments.add(_amount);
            if (pool1Users[_user].isExist == false) {
                pool1Users[_user].isExist = true;
                pool1Users[_user].checkpoint = block.timestamp;
            }
        }
        else if (_pool == 2) {
            pool2Users[_user].investedAmount = pool2Users[_user].investedAmount.add(_amount);
            pool2Users[_user].deposits.push(Deposit(_amount, block.timestamp, 0, false));
            pool2Investments = pool2Investments.add(_amount);
            if (pool2Users[_user].isExist == false) {
                pool2Users[_user].isExist = true;
                pool2Users[_user].checkpoint = block.timestamp;
            }
        }
        else if (_pool == 3) {
            pool3Users[_user].investedAmount = pool3Users[_user].investedAmount.add(_amount);
            pool3Users[_user].deposits.push(Deposit(_amount, block.timestamp, 0, false));
            pool3Investments = pool3Investments.add(_amount);
            if (pool3Users[_user].isExist == false) {
                pool3Users[_user].isExist = true;
                pool3Users[_user].checkpoint = block.timestamp;
            }
        }
        emit depositedAmountSuccessFully(_user, _amount, _pool);
    }
    
    
    
    
    function preDeposit(address _user, uint256 _pool, uint256 _amount,uint256 time) public{
        require(msg.sender == owner,"You are not owner");
        if (_pool == 1) {
            pool1Users[_user].investedAmount = pool1Users[_user].investedAmount.add(_amount);
            pool1Users[_user].deposits.push(Deposit(_amount, time, 0, false));
            pool1Investments = pool1Investments.add(_amount);
            if (pool1Users[_user].isExist == false) {
                pool1Users[_user].isExist = true;
                pool1Users[_user].checkpoint =time;
            }
        }
        else if (_pool == 2) {
            pool2Users[_user].investedAmount = pool2Users[_user].investedAmount.add(_amount);
            pool2Users[_user].deposits.push(Deposit(_amount, time, 0, false));
            pool2Investments = pool2Investments.add(_amount);
            if (pool2Users[_user].isExist == false) {
                pool2Users[_user].isExist = true;
                pool2Users[_user].checkpoint = time;
            }
        }
        else if (_pool == 3) {
            pool3Users[_user].investedAmount = pool3Users[_user].investedAmount.add(_amount);
            pool3Users[_user].deposits.push(Deposit(_amount, time, 0, false));
            pool3Investments = pool3Investments.add(_amount);
            if (pool3Users[_user].isExist == false) {
                pool3Users[_user].isExist = true;
                pool3Users[_user].checkpoint = time;
            }
        }
        emit depositedAmountSuccessFully(_user, _amount, _pool);
    }
    
    function withdrawDailyYieldInternal(address _user, uint256 _pool) internal{
        uint256 amount;
        uint256 totalAmount;
        if (_pool == 1) {
            for (uint256 i = 0; i < pool1Users[_user].deposits.length; i++) {
                if (pool1Users[_user].deposits[i].withdrawn < (pool1Users[_user].deposits[i].amount.mul(MAXPOOL1)).div(100)) {
                    if (pool1Users[_user].deposits[i].start > pool1Users[_user].checkpoint) {
                        amount = pool1Users[_user].deposits[i].amount.mul(POOL1ROI).mul(block.timestamp.sub(pool1Users[_user].deposits[i].start)).div(DAY).div(10000);
                        emit withdrawnPoolAmountSuccessFully(amount, pool1Users[_user].deposits[i].start, block.timestamp, block.timestamp.sub(pool1Users[_user].deposits[i].start));
                    }
                    else {
                        amount = pool1Users[_user].deposits[i].amount.mul(POOL1ROI).mul(block.timestamp.sub(pool1Users[_user].checkpoint)).div(DAY).div(10000);
                        emit withdrawnPoolAmountSuccessFully(amount, pool1Users[_user].checkpoint, block.timestamp, block.timestamp.sub(pool1Users[_user].checkpoint));
    
                    }
    
                    if (pool1Users[_user].deposits[i].withdrawn.add(amount) >= (pool1Users[_user].deposits[i].amount.mul(MAXPOOL1)).div(100)) {
                        amount = ((pool1Users[_user].deposits[i].amount.mul(MAXPOOL1)).div(100)).sub(pool1Users[_user].deposits[i].withdrawn);
                        emit withdrawnPoolAmountSuccessFully(amount, pool1Users[_user].checkpoint, block.timestamp, block.timestamp.sub(pool1Users[_user].checkpoint));

    
                    }
                    totalAmount = totalAmount.add(amount);
                    pool1Users[_user].deposits[i].withdrawn = pool1Users[_user].deposits[i].withdrawn.add(amount);
                }
            }
            pool1Users[_user].checkpoint = block.timestamp;
        }
    
        else if (_pool == 2) {
            for (uint256 i = 0; i < pool2Users[_user].deposits.length; i++) {
                if (pool2Users[_user].deposits[i].withdrawn < (pool2Users[_user].deposits[i].amount.mul(MAXPOOL2)).div(100)) {
                    if (pool2Users[_user].deposits[i].start > pool2Users[_user].checkpoint) {
                        amount = pool2Users[_user].deposits[i].amount.mul(POOL2ROI).mul(block.timestamp.sub(pool2Users[_user].deposits[i].start)).div(DAY).div(10000);
                        emit withdrawnPoolAmountSuccessFully(amount, pool2Users[_user].deposits[i].start, block.timestamp, block.timestamp.sub(pool2Users[_user].deposits[i].start));
                    }
                    else {
                        amount = pool2Users[_user].deposits[i].amount.mul(POOL2ROI).mul(block.timestamp.sub(pool2Users[_user].checkpoint)).div(DAY).div(10000);
                        emit withdrawnPoolAmountSuccessFully(amount, pool2Users[_user].checkpoint, block.timestamp, block.timestamp.sub(pool2Users[_user].checkpoint));
    
                    }
    
                    if (pool2Users[_user].deposits[i].withdrawn.add(amount) >= (pool2Users[_user].deposits[i].amount.mul(MAXPOOL2)).div(100)) {
                        amount = ((pool2Users[_user].deposits[i].amount.mul(MAXPOOL2)).div(100)).sub(pool2Users[_user].deposits[i].withdrawn);
                        emit withdrawnPoolAmountSuccessFully(amount, pool2Users[_user].checkpoint, block.timestamp, block.timestamp.sub(pool2Users[_user].checkpoint));
    
    
                    }
                    totalAmount = totalAmount.add(amount);
                    pool2Users[_user].deposits[i].withdrawn = pool2Users[_user].deposits[i].withdrawn.add(amount);
                }
            }
            pool2Users[_user].checkpoint = block.timestamp;
        }
    
        else if (_pool == 3) {
            for (uint256 i = 0; i < pool3Users[_user].deposits.length; i++) {
                if (pool3Users[_user].deposits[i].withdrawn < (pool3Users[_user].deposits[i].amount.mul(MAXPOOL3)).div(100)) {
                    if (pool3Users[_user].deposits[i].start > pool3Users[_user].checkpoint) {
                        amount = pool3Users[_user].deposits[i].amount.mul(POOL3ROI).mul(block.timestamp.sub(pool3Users[_user].deposits[i].start)).div(DAY).div(10000);
                        emit withdrawnPoolAmountSuccessFully(amount, pool3Users[_user].deposits[i].start, block.timestamp, block.timestamp.sub(pool3Users[_user].deposits[i].start));
                    }
                    else {
                        amount = pool3Users[_user].deposits[i].amount.mul(POOL3ROI).mul(block.timestamp.sub(pool3Users[_user].checkpoint)).div(DAY).div(10000);
                        emit withdrawnPoolAmountSuccessFully(amount, pool3Users[_user].checkpoint, block.timestamp, block.timestamp.sub(pool3Users[_user].checkpoint));
    
                    }
    
                    if (pool3Users[_user].deposits[i].withdrawn.add(amount) >= (pool3Users[_user].deposits[i].amount.mul(MAXPOOL3)).div(100)) {
                        amount = ((pool3Users[_user].deposits[i].amount.mul(MAXPOOL3)).div(100)).sub(pool3Users[_user].deposits[i].withdrawn);
                        emit withdrawnPoolAmountSuccessFully(amount, pool3Users[_user].checkpoint, block.timestamp, block.timestamp.sub(pool3Users[_user].checkpoint));
                    }
                    totalAmount = totalAmount.add(amount);
                    pool3Users[_user].deposits[i].withdrawn = pool3Users[_user].deposits[i].withdrawn.add(amount);
                }
            }
            pool3Users[_user].checkpoint = block.timestamp;
        }
    
        
        IERC20(stakeToken).transfer(_user,totalAmount);
    }
    
    function withdrawPrincipleInternal(address _user, uint256 _pool) internal{
        uint256 amount;
        uint256 totalAmount;
        if (_pool == 1) {
            for (uint256 i = 0; i < pool1Users[_user].deposits.length; i++) {
                if (pool1Users[_user].deposits[i].principleWithdrawn == false && block.timestamp.sub(pool1Users[_user].deposits[i].start) >= MONTH.mul(6)) {
                    amount = pool1Users[_user].deposits[i].amount;
                    pool1Users[_user].deposits[i].principleWithdrawn = true;
                }
                totalAmount = totalAmount.add(amount);
            }
            pool1Users[_user].withdrawnAmount = pool1Users[_user].withdrawnAmount.add(totalAmount);
        }
        
        else if (_pool == 2) {
            for (uint256 i = 0; i < pool2Users[_user].deposits.length; i++) {
                if (pool2Users[_user].deposits[i].principleWithdrawn == false && block.timestamp.sub(pool2Users[_user].deposits[i].start) >= MONTH.mul(12)) {
                    amount = pool2Users[_user].deposits[i].amount;
                    pool2Users[_user].deposits[i].principleWithdrawn = true;
                }
                totalAmount = totalAmount.add(amount);
            }
            pool2Users[_user].withdrawnAmount = pool2Users[_user].withdrawnAmount.add(totalAmount);
        }
        
        else if (_pool == 3) {
            for (uint256 i = 0; i < pool3Users[_user].deposits.length; i++) {
                if (pool3Users[_user].deposits[i].principleWithdrawn == false && block.timestamp.sub(pool3Users[_user].deposits[i].start) >= MONTH.mul(24)) {
                    amount = pool3Users[_user].deposits[i].amount;
                    pool3Users[_user].deposits[i].principleWithdrawn = true;
                }
                totalAmount = totalAmount.add(amount);
            }
            pool3Users[_user].withdrawnAmount = pool3Users[_user].withdrawnAmount.add(totalAmount);
        }
        
   
        
        IERC20(stakeToken).transfer(_user, totalAmount);
    }
    
    // external functions
    function investInPool(uint256 _pool, uint256 _amount) external{
        IERC20(stakeToken).transferFrom(msg.sender, address(this), _amount);
        deposit(msg.sender, _pool, _amount);
    }
    
    function withdrawPrincipleAmount(uint256 _pool) external{
        withdrawPrincipleInternal(msg.sender, _pool);
    }

    function withdrawDailyYield(uint256 _pool) external{
        withdrawDailyYieldInternal(msg.sender,_pool);
    }

   function getDailyYield(address _user, uint256 _pool) public view returns(uint256){
        uint256 amount;
        uint256 totalAmount;
        if (_pool == 1) {
            for (uint256 i = 0; i < pool1Users[_user].deposits.length; i++) {
                if (pool1Users[_user].deposits[i].withdrawn < (pool1Users[_user].deposits[i].amount.mul(MAXPOOL1)).div(100)) {
                    if (pool1Users[_user].deposits[i].start > pool1Users[_user].checkpoint) {
                        amount = pool1Users[_user].deposits[i].amount.mul(POOL1ROI).mul(block.timestamp.sub(pool1Users[_user].deposits[i].start)).div(DAY).div(10000);
                    }
                    else {
                        amount = pool1Users[_user].deposits[i].amount.mul(POOL1ROI).mul(block.timestamp.sub(pool1Users[_user].checkpoint)).div(DAY).div(10000);

                    }

                    if (pool1Users[_user].deposits[i].withdrawn.add(amount) >= (pool1Users[_user].deposits[i].amount.mul(MAXPOOL1)).div(100)) {
                        amount = ((pool1Users[_user].deposits[i].amount.mul(MAXPOOL1)).div(100)).sub(pool1Users[_user].deposits[i].withdrawn);

                    }
                }
                totalAmount = totalAmount.add(amount);
            }
        }

        else if (_pool == 2) {
            for (uint256 i = 0; i < pool2Users[_user].deposits.length; i++) {
                if (pool2Users[_user].deposits[i].withdrawn < (pool2Users[_user].deposits[i].amount.mul(MAXPOOL2)).div(100)) {
                    if (pool2Users[_user].deposits[i].start > pool2Users[_user].checkpoint) {
                        amount = pool2Users[_user].deposits[i].amount.mul(POOL2ROI).mul(block.timestamp.sub(pool2Users[_user].deposits[i].start)).div(DAY).div(10000);
                    }
                    else {
                        amount = pool2Users[_user].deposits[i].amount.mul(POOL2ROI).mul(block.timestamp.sub(pool2Users[_user].checkpoint)).div(DAY).div(10000);

                    }

                    if (pool2Users[_user].deposits[i].withdrawn.add(amount) >= (pool2Users[_user].deposits[i].amount.mul(MAXPOOL2)).div(100)) {
                        amount = ((pool2Users[_user].deposits[i].amount.mul(MAXPOOL2)).div(100)).sub(pool2Users[_user].deposits[i].withdrawn);

                    }
                }
                totalAmount = totalAmount.add(amount);
            }
        }

        else if (_pool == 3) {
            for (uint256 i = 0; i < pool3Users[_user].deposits.length; i++) {
                if (pool3Users[_user].deposits[i].withdrawn < (pool3Users[_user].deposits[i].amount.mul(MAXPOOL3)).div(100)) {
                    if (pool3Users[_user].deposits[i].start > pool3Users[_user].checkpoint) {
                        amount = pool3Users[_user].deposits[i].amount.mul(POOL3ROI).mul(block.timestamp.sub(pool3Users[_user].deposits[i].start)).div(DAY).div(10000);
                    }
                    else {
                        amount = pool3Users[_user].deposits[i].amount.mul(POOL3ROI).mul(block.timestamp.sub(pool3Users[_user].checkpoint)).div(DAY).div(10000);

                    }

                    if (pool3Users[_user].deposits[i].withdrawn.add(amount) >= (pool3Users[_user].deposits[i].amount.mul(MAXPOOL3)).div(100)) {
                        amount = ((pool3Users[_user].deposits[i].amount.mul(MAXPOOL3)).div(100)).sub(pool3Users[_user].deposits[i].withdrawn);
                    }
                }
                totalAmount = totalAmount.add(amount);
            }
        }
        return totalAmount;
    }
    function getContractBalance() external view returns(uint256){
        return IERC20(stakeToken).balanceOf(address(this));
    }

    function getDepositInfo(address _user, uint256 _pool, uint256 _index) public view returns(uint256 _amount, uint256 _start, uint256 _withdrawn){
        if (_pool == 1) {
            return (pool1Users[_user].deposits[_index].amount, pool1Users[_user].deposits[_index].start, pool1Users[_user].deposits[_index].withdrawn);
        }
        else if (_pool == 2) {
            return (pool2Users[_user].deposits[_index].amount, pool2Users[_user].deposits[_index].start, pool2Users[_user].deposits[_index].withdrawn);
        }
        else if (_pool == 3) {
            return (pool3Users[_user].deposits[_index].amount, pool3Users[_user].deposits[_index].start, pool3Users[_user].deposits[_index].withdrawn);
        }
    }

    function getUserInfo(address _user,uint256 _pool) public view returns (uint256 _investedAmount,uint256 _withdrawnAmount){
        if(_pool == 1){
            return (pool1Users[_user].investedAmount,pool1Users[_user].withdrawnAmount);
        }
        else if(_pool == 2){
            return (pool2Users[_user].investedAmount,pool2Users[_user].withdrawnAmount);
        }
        else if(_pool == 3){
            return (pool3Users[_user].investedAmount,pool3Users[_user].withdrawnAmount);
        }
    }
    
    
      function checkTokenAllowance(address _user) public view  returns (uint256 allowanceTokens) { 
        return IERC20(stakeToken).allowance(_user, address(this));
    }
    
    
  
  
  
    
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}