//SourceUnit: tree.sol

pragma solidity ^0.5.0;

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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

    function sub0(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract Tree {
    address public accept1;
    address public accept2;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public currency;
    address public token;
    uint public tokenRate;                      //1e6=1
    uint public promotionRate;                  //1e6=1
    uint public fundRate;                       //1e6=1
    uint public maxRate;                        //1e6=1
    uint public acceleratorPrice;               //to currency
    uint public currencyToToken;
    mapping (uint => uint) public yieldOfGrade; //1e6=1
    mapping (uint => uint) public treesOfGrade; 
    mapping (uint => uint) public priceOfGrade;
    
    mapping (address => uint) public lastPickedTimeOf;
    mapping (address => uint) public gradeOf;
    mapping (address => uint) public gradeTimeOf;

    mapping (address => uint) receivedPromotionOf;
    mapping (address => uint) pickedPoolOf;
    mapping (address => uint) fruitOf;
    mapping (address => uint) fundOf;
    mapping (address => uint) burnOf;
    mapping (address => uint) public investOf;
    mapping (address => uint) public poolOf;
    mapping (address => uint) public tokenOf;
    uint256 totalInvest;
    uint256 totalAccelerator;
    mapping (uint => uint) public numberOfGrade;
    address[] internal addressIndexes;
    constructor (address accept1_, address accept2_, address currency_, address token_) public {
        accept1 = accept1_;
        accept2 = accept2_;
        currency = currency_;
        token = token_;
        tokenRate = 200000;
        promotionRate = 200000;
        fundRate = 60000;
        maxRate = 1e6;
        yieldOfGrade[0] = 100000;
        yieldOfGrade[1] = 1000000;
        yieldOfGrade[2] = 1000000;
        yieldOfGrade[3] = 1000000;
        treesOfGrade[0] = 1;
        treesOfGrade[1] = 5;
        treesOfGrade[2] = 12;
        treesOfGrade[3] = 40;
        priceOfGrade[1] = 900*10**6;
        priceOfGrade[2] = 2000*10**6;
        priceOfGrade[3] = 6000*10**6;
        acceleratorPrice = 50*10**6;
        currencyToToken = 10;
    }
    
    function changeGrade(uint256 grade, uint256 amount) external  returns(bool){
        require(grade >= 1 && grade <= 4, "grade is error");
        require(priceOfGrade[grade] == amount, "amount is error");
        require(grade >= gradeOf[msg.sender],"grade too low");
        IERC20(currency).safeTransferFrom(msg.sender, accept1, amount.mul(8).div(10));
        IERC20(currency).safeTransferFrom(msg.sender, accept2, amount.mul(2).div(10));
        totalInvest = totalInvest.add(amount);
        investOf[msg.sender] = investOf[msg.sender].add(amount);
        if(gradeTimeOf[msg.sender] >0){
            numberOfGrade[gradeOf[msg.sender]] = numberOfGrade[gradeOf[msg.sender]].sub(1);
        }
        lastPickedTimeOf[msg.sender] =0;
        gradeTimeOf[msg.sender] = now;
        gradeOf[msg.sender] = grade;
        numberOfGrade[grade] = numberOfGrade[grade].add(1);
        bool hasAddress = false;
        for(uint256 i=0; i< addressIndexes.length; i++){
            if(addressIndexes[i] == msg.sender){
                hasAddress = true;
            }
        }
        if(!hasAddress){
            addressIndexes.push(msg.sender);
        }
        emit ChangeGrade(grade, amount);
        return true;
    }
    event ChangeGrade(uint256 level, uint256 amount);
    function freeTree() external returns(bool){
      require(gradeTimeOf[msg.sender] == 0, "no free tree");
      gradeTimeOf[msg.sender] = now;
      numberOfGrade[0] = numberOfGrade[0].add(1);
      gradeOf[msg.sender] = 0;
      addressIndexes.push(msg.sender);
      emit FreeTree(1);
      return true;
    }
    event FreeTree( uint256 count);
    
    mapping (address => address) public inviterOf;
    mapping (address => uint) invitecountOf;
    function invited(address inviter) external returns(bool){
        require(msg.sender != inviter, 'cannot invite yourself');
        require(inviterOf[msg.sender]==address(0), 'repeated');
        address addr = inviterOf[inviter];
        do {
            require(addr != msg.sender, 'the inviter is lower than you');
            addr = inviterOf[addr];
        }while(addr!= address(0));
        inviterOf[msg.sender] = inviter;
        invitecountOf[inviter] = invitecountOf[inviter].add(1);
        emit Invited(msg.sender, inviter);
        return true;
    }
    event Invited(address indexed invitee, address indexed inviter);
    
     function pickFruit() public returns(bool){
        (uint256 amount_, uint256 left_) = waitFruit(msg.sender);
        require(amount_ >0 || left_ > 0,"no fruit");
        // burnOf[msg.sender] = burnOf[msg.sender].add(left_.mul(maxRate.sub(promotionRate.add(tokenRate))).div(maxRate));
        burnOf[msg.sender] = burnOf[msg.sender].add(left_);
        fruitOf[msg.sender] = fruitOf[msg.sender].add(amount_).add(left_);
        pickedPoolOf[msg.sender] = pickedPoolOf[msg.sender].add(amount_);
        lastPickedTimeOf[msg.sender] = now;
        // uint256 promotionFruit_ = (left_.add(amount_)).mul(promotionRate).div(maxRate);
        uint256 promotionFruit_ = (amount_).mul(promotionRate).div(maxRate);
        address invitee = msg.sender;
        uint upper = 0;
        while(promotionFruit_ >0 && inviterOf[invitee] != address(0) && upper <20){
            uint256 promotionToPool_ = 0;
            if(upper ==0){
                promotionToPool_ = promotionFruit_.mul(30).div(100);
            }else if(upper ==1){
              promotionToPool_ = promotionFruit_.mul(20).div(100);
            }else if(upper >=2 && upper <=9){
                promotionToPool_ = promotionFruit_.mul(5).div(100);
            }else if(upper >=10 && upper <=19){
                promotionToPool_ = promotionFruit_.mul(1).div(100);
            }else{
                break;
            }
            poolOf[inviterOf[invitee]] = poolOf[inviterOf[invitee]].add(promotionToPool_);
            receivedPromotionOf[inviterOf[invitee]] = receivedPromotionOf[inviterOf[invitee]].add(promotionToPool_);
            invitee = inviterOf[invitee];
            upper++;
        }
        poolOf[msg.sender] = poolOf[msg.sender].add(amount_);
        uint256 tokenOfLeft_ = left_.mul(tokenRate).div(maxRate);
        uint256 tokenFruit_ = amount_.mul(tokenRate).div(maxRate).add(tokenOfLeft_);
        uint256 tokenAmount_ = tokenFruit_.mul(currencyToToken).mul(10**uint256(IERC20(token).decimals())).div(maxRate);
        tokenOf[msg.sender] = tokenOf[msg.sender].add(tokenAmount_);
        emit PickFruit(amount_, left_, promotionFruit_);
        return true;
    }
     event PickFruit(uint256 amount, uint256 left, uint256 promotion);
    function withdraw() public returns(bool){
        require(gradeOf[msg.sender] >0, "grade too low");
        require(poolOf[msg.sender] >0 || tokenOf[msg.sender] > 0,"no fruit");
        uint256 currencyAmount_ = poolOf[msg.sender].mul(maxRate.sub(fundRate.add(tokenRate.add(promotionRate)))).div(maxRate).mul(10**uint256(IERC20(currency).decimals())).div(maxRate);
        if(poolOf[msg.sender] > 0){
            IERC20(currency).safeTransfer(msg.sender, currencyAmount_);
        }
        if(tokenOf[msg.sender] > 0){
            IERC20(token).safeTransfer(msg.sender, tokenOf[msg.sender]);
        }
        uint256 fund_ = poolOf[msg.sender].mul(fundRate).div(1e6);
        if( fund_ > 0){
            fundOf[msg.sender] = fundOf[msg.sender].add(fund_);
        }
        poolOf[msg.sender] = 0;
        tokenOf[msg.sender] = 0;
        emit Withdraw(currencyAmount_, tokenOf[msg.sender]);
        return true;
    }
    event Withdraw(uint256 currencyAmount, uint256 tokenAmount);
    mapping (address => mapping (uint => uint)) internal acceleratorCountOf;
    mapping (address => mapping (uint => uint)) internal acceleratorTimeOf;
    mapping (address => uint) public lastAcceleratorOf;
    function buyAccelerator(uint count, uint amount) public returns(bool){
        require(gradeOf[msg.sender] == 0, "grade is wrong");
        require(gradeTimeOf[msg.sender] > 0, "no tree");
        require(acceleratorPrice.mul(count) == amount,"count or amount is wrong");
        acceleratorCountOf[msg.sender][lastAcceleratorOf[msg.sender]] = count;
        acceleratorTimeOf[msg.sender][lastAcceleratorOf[msg.sender]] = now;
        lastAcceleratorOf[msg.sender] = lastAcceleratorOf[msg.sender].add(1);
        IERC20(currency).safeTransferFrom(msg.sender, accept1, amount.mul(8).div(10));
        IERC20(currency).safeTransferFrom(msg.sender, accept2, amount.mul(2).div(10));
        // totalInvest = totalInvest.add(amount);
        totalAccelerator = totalAccelerator.add(count);
        emit BuyAccelerator(count, amount);
        return true;
    } 
    event BuyAccelerator( uint256 count, uint256 amount);
    function historyOf() public view returns(uint256 fund_, uint256 pickedFruit_, uint256 burn_, uint256 totalFruit_){
        fund_ = fundOf[msg.sender];
        pickedFruit_ = pickedPoolOf[msg.sender];
        burn_ = burnOf[msg.sender];
        (uint256 _pool, uint256 _left) = waitFruit(msg.sender);
        totalFruit_ = _pool.add(_left).add(fruitOf[msg.sender]);
    }
    function total() public view returns(uint256 totalPickedFruit_, uint256 totalPickedBurn_, uint256 totalAccelerator_, uint256 totalInvest_, uint256 waitFruit_, uint256 totalOutput_, uint256 totalFund_){
        uint256 pickedOutput = 0;
        totalAccelerator_ = totalAccelerator;
        totalInvest_ = totalInvest;
        for(uint256 i=0; i< addressIndexes.length; i++){
            totalPickedFruit_ = totalPickedFruit_.add(pickedPoolOf[addressIndexes[i]]);
            totalPickedBurn_ = totalPickedBurn_.add(burnOf[addressIndexes[i]]);
            pickedOutput = pickedOutput.add(fruitOf[addressIndexes[i]]);
            (uint256 count_, uint256 left_) = waitFruit(addressIndexes[i]);
            waitFruit_ = waitFruit_.add(count_).add(left_);
            totalFund_ = totalFund_.add(fundOf[addressIndexes[i]]);
        }
    }
    function totalNumber() public view returns(uint256 grade0_, uint256 grade1_, uint256 grade2_, uint256 grade3_){
        grade0_ = numberOfGrade[0];
        grade1_ = numberOfGrade[1];
        grade2_ = numberOfGrade[2];
        grade3_ = numberOfGrade[3];
    }
    function waitFruit(address owner_) internal view returns(uint256 amount_, uint256 left_) {
        uint _nowTime = now;
        if(gradeTimeOf[owner_] >0 && _nowTime.sub(gradeTimeOf[owner_]) >= 1 days){
            uint _leftTime = lastPickedTimeOf[owner_]== 0 ? gradeTimeOf[owner_] : gradeTimeOf[owner_].add((lastPickedTimeOf[owner_].sub(gradeTimeOf[owner_])).div(1 days).mul(1 days));
            if((_nowTime.sub(_leftTime)).div(1 days) >= 1 &&  _nowTime.sub(_leftTime).sub((_nowTime.sub(_leftTime)).div(1 days).mul(1 days)) <= 12 hours){
                uint256 _yield = yieldOfGrade[gradeOf[owner_]].div(2**((_nowTime.sub(gradeTimeOf[owner_].add(1 days))).div(360 days)));
                if(gradeOf[owner_]==0){
                    uint256 _mult = 0;
                    for(uint j = 0; j< lastAcceleratorOf[owner_]; j++){
                        if(acceleratorTimeOf[owner_][j] <_nowTime && acceleratorTimeOf[owner_][j].add(360 days) > _nowTime){
                           _mult = _mult.add(acceleratorCountOf[owner_][j]);
                        }
                    }
                     if(_mult > 0){
                        _yield = _yield.mul(5).mul(_mult);
                     }
                }
                amount_ = _yield.mul(treesOfGrade[gradeOf[owner_]]);
            }
            uint _count = (_nowTime.sub(_leftTime)).div(360 days);
            for (uint i = 0; i <= _count; i++){
                uint _rightTime = _leftTime.add(360 days)>=_nowTime || (_leftTime.add(360 days) < _nowTime && _nowTime.sub(_leftTime.add(360 days)) < 1 days) ? _nowTime : _leftTime.add(360 days);
                uint256 _yield = yieldOfGrade[gradeOf[owner_]].div( 2**i);
                if(gradeOf[owner_] == 0 && this.acceleratorCountsOf(owner_) >= 1){
                    for( uint j = 1; j <= (_rightTime.sub(_leftTime)).div(1 days); j++ ){
                        uint256 _mult = 0;
                        if(j < (_rightTime.sub(_leftTime)).div(1 days) || (j == (_rightTime.sub(_leftTime)).div(1 days)) && _rightTime.sub(_leftTime.add(j.mul(1 days))) > 12 hours){
                            for(uint k = 0; k < lastAcceleratorOf[owner_]; k++){
                                uint acceleratorTime = acceleratorTimeOf[owner_][k];
                                if(acceleratorTimeOf[owner_][k] < _leftTime.add(j.mul(1 days)) && acceleratorTime.add(360 days) > _leftTime.add(j.mul(1 days))){
                                    _mult = _mult.add(acceleratorCountOf[owner_][k]);
                                }
                            }
                            if(_mult >= 1){
                                _mult = _mult.mul(5);
                            }else{
                                _mult = 1;
                            }
                            uint256 trees_ = treesOfGrade[gradeOf[owner_]];
                            uint256 newYield_ = _yield.mul(_mult).mul(trees_);
                            left_ = left_.add(newYield_);
                        }
                    }
                }else{
                    if((_rightTime.sub(_leftTime)).div(1 days) >=1){
                        if(_rightTime == _nowTime && _rightTime.sub(_leftTime).sub((_rightTime.sub(_leftTime)).div(1 days).mul(1 days)) <= 12 hours){
                             left_ = left_.add((((_rightTime.sub(_leftTime)).div(1 days)).sub(1)).mul(_yield).mul(treesOfGrade[gradeOf[owner_]]));
                        }else{
                           left_ = left_.add(((_rightTime.sub(_leftTime)).div(1 days)).mul(_yield).mul(treesOfGrade[gradeOf[owner_]]));
                        }
                    }
                }
                if( _rightTime == _nowTime){
                    break;
                }
                _leftTime = _rightTime;
            }
        }
    }
    function checkFruit() public view returns(uint256 pool_, uint256 left_){
        (uint256 _count, uint256 _left) = waitFruit(msg.sender);
        pool_ = _count;
        left_ = _left;
    }
    function hold() public view returns(uint256 pool_, uint256 token_){
        pool_ = poolOf[msg.sender];
        token_ = tokenOf[msg.sender];
    }
    function nextPickTime() public view returns(uint256){
        if(gradeTimeOf[msg.sender] == 0){
            return 0;
        }
        return gradeTimeOf[msg.sender].add((now.sub(gradeTimeOf[msg.sender]).div(1 days).add(1)).mul(1 days));
    } 
    function acceleratorCountsOf(address owner_) external view returns(uint256 counts_){
        for(uint i = 0; i< lastAcceleratorOf[owner_]; i++){
            counts_ = counts_.add(acceleratorCountOf[owner_][i]);
        }
    }
    function investInfoOf() public view returns(uint256 investCount_, uint256 investProfit_){
        investProfit_ = receivedPromotionOf[msg.sender].mul(10**uint256(IERC20(currency).decimals())).div(maxRate);
        investCount_ = invitecountOf[msg.sender];
    }
    function dayrateOf() public view returns(uint256){
        if( gradeTimeOf[msg.sender] ==0){
            return 0;
        }
        uint256 _yield = yieldOfGrade[gradeOf[msg.sender]].div(2**((now.sub(gradeTimeOf[msg.sender])).div(360 days)));
        if(gradeOf[msg.sender]==0){
            uint256 _mult = 0;
            for(uint j = 0; j< lastAcceleratorOf[msg.sender]; j++){
                if(acceleratorTimeOf[msg.sender][j] <now && acceleratorTimeOf[msg.sender][j].add(360 days) > now){
                   _mult = _mult.add(acceleratorCountOf[msg.sender][j]);
                }
            }
             if(_mult > 0){
                _yield = _yield.mul(5).mul(_mult);
             }
        }
        return _yield.mul(treesOfGrade[gradeOf[msg.sender]]);
    }
}