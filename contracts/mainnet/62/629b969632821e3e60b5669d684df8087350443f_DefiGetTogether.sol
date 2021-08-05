/**
 *Submitted for verification at Etherscan.io on 2020-12-14
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.6.11;

interface ICurve {
    function get_dy(int128 i, int128 j, uint256 dx) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

interface ICDaiErc20{
    function mint(uint256) external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function borrow(uint256) external returns (uint256);
    function repayBorrow(uint256) external returns (uint256);
    function balanceOfUnderlying(address) external returns (uint);
    function borrowBalanceCurrent(address) external returns (uint256);

    function claimComp(address holder) external;
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

library SafeERC20 {
   using SafeMath for uint256;
   using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        if(token.allowance(address(this),spender) < value){
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
        }
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
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
         
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library Address {
  
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract DefiGetTogether {

    using SafeMath for uint;
    enum DefiStatus {
        UNUSED,CROWDFUNDING,WAITDART,DARTSUCCESS               
     }           
                  
    uint256 constant MaxUint256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint [] private supplySection;  
    uint public totalInvestor; 

    uint public crowdfundNumber; 
    uint public crowdfundPeriod; 

    uint public dartNumber;  
    uint public dartPeriod;   
    uint public intervalNumber = 11520; 
    uint public minCrowdFundingAmount = 1000;
    uint public mortgageFactor = 69;
    uint public maxMortgageFactor = 75;
    uint public platformCoefficient = 15;

    address private uniSwapContract;    
    address private curvePoolContract;
    address private usdtContract;     
    address private daiContract;      
    address private cDaiContract;     
    address private compContract;   
    address private compComptrollerContract;  
    address public platformAddr;      
    address public owner;         
    address[] public investors;
    mapping(address => bool) public admins;    
    mapping(address => uint) public investments; 
    DefiStatus public status = DefiStatus.UNUSED; 

    bool private isUniswapWay = false;
    int128 private curveUsdtIndex = 2;
    int128 private curveDaiIndex = 0;

    constructor(address _uniSwapContract,address _curvePoolContract,address _usdtContract,address _daiContract,address _cDaiContract,address _compContract,address _compComptrollerContract,address _platformAddr) public{
        uniSwapContract = _uniSwapContract;
        curvePoolContract = _curvePoolContract;
        usdtContract = _usdtContract;
        daiContract = _daiContract;
        cDaiContract = _cDaiContract;
        compContract = _compContract;
        compComptrollerContract = _compComptrollerContract;
        platformAddr = _platformAddr;
        uint power = IERC20(usdtContract).decimals();
        minCrowdFundingAmount = uint256(minCrowdFundingAmount).mul(10 ** power);
        owner = msg.sender;
    }

    function _isContainsInvestors(address _investor) private view returns(bool) {
        return investments[_investor] != 0;
    }

     function _isAdmin(address _address) private view returns(bool) {
        return admins[_address];
    }
    
    function _addInverstorInfo(address _investor, uint _amount) private {
        if (_isContainsInvestors(_investor)) {
            investments[_investor] = investments[_investor].add(_amount);
        } else {
            investors.push(_investor);
            investments[_investor] = _amount;
        }
    }

    function _deleteAllInvestorInfo() private {
        for (uint i = 0; i < investors.length; i ++) {
            delete investments[investors[i]];
        }
        delete investors;
    }

    function _getTotalInvestment() private view returns(uint) {
        uint amount = 0;
        for (uint i = 0; i < investors.length; i ++) {
            amount = amount.add(investments[investors[i]]);
        }
        return amount;
    }

    function _curveSwap(address _address,int128 _from, int128 _to, uint256 _amount) private {
        SafeERC20.safeApprove(IERC20(_address),curvePoolContract,_amount);
        ICurve curve = ICurve(curvePoolContract);
        uint256 min_dy = curve.get_dy(_from, _to, _amount);
        curve.exchange(_from, _to, _amount, min_dy);
    }

    function _uniswap(address _from, address _to, uint256 _amount) private {
        IUniswapV2Router router = IUniswapV2Router(uniSwapContract);
        SafeERC20.safeApprove(IERC20(_from),address(router),_amount);
        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = router.WETH();
        path[2] = _to;
        uint[] memory amounts = router.getAmountsOut(_amount, path);
        uint amountOutMin = amounts[amounts.length - 1];
        router.swapExactTokensForTokens(_amount, amountOutMin, path, address(this), MaxUint256);
    }

    function _swap(address _from, address _to) private {
        uint amountIn = IERC20(_from).balanceOf(address(this));
        if(amountIn > 0){
        
            if (((_from == usdtContract && _to == daiContract) || (_from == daiContract && _to == usdtContract)) &&  isUniswapWay == false) {
        
                  if (_from == usdtContract) {
                       _curveSwap(_from,curveUsdtIndex, curveDaiIndex, amountIn);
                  } else {
                      _curveSwap(_from,curveDaiIndex, curveUsdtIndex, amountIn);
                     }
            } else{
                _uniswap(_from, _to, amountIn); 
              }
        }
    }
   
    function _batchTransferPrincipal() private {
        uint amountUsdt = IERC20(usdtContract).balanceOf(address(this));
        uint totalInvestment = _getTotalInvestment();
        require(amountUsdt >= totalInvestment, "usdt balance no enouth");
        for (uint i = 0; i < investors.length; i ++) {
            address investor = investors[i];
            uint investment = investments[investor];
            SafeERC20.safeTransfer(IERC20(usdtContract), investor, investment);
        }
    }

    function _batchTransferPrincipalAndIncome() private {
        uint totalUsdtAmount = IERC20(usdtContract).balanceOf(address(this)); 
        require(totalUsdtAmount > 0, "batch transfer balance failed");
        uint totalInvestment = _getTotalInvestment();

        if (totalUsdtAmount > totalInvestment) {
            uint income = totalUsdtAmount.sub(totalInvestment);
            uint totalInvestorsIncome = income.mul(uint256(100).sub(platformCoefficient)).div(uint256(100)).add(totalInvestment);
            for (uint i = 0; i < investors.length; i ++) {
                address investor = investors[i];
                uint investment = investments[investor];
                uint investorIncome = totalInvestorsIncome.mul(investment).div(totalInvestment);
                SafeERC20.safeTransfer(IERC20(usdtContract), investor, investorIncome);
            }
        } else if (totalUsdtAmount < totalInvestment) {
            for (uint i = 0; i < investors.length; i ++) {
                address investor = investors[i];
                uint investment = investments[investor];
                uint investorIncome = totalUsdtAmount.mul(investment).div(totalInvestment);
                SafeERC20.safeTransfer(IERC20(usdtContract), investor, investorIncome);
            }
        } else {
            for (uint i = 0; i < investors.length; i ++) {
                address investor = investors[i];
                uint investment = investments[investor];
                SafeERC20.safeTransfer(IERC20(usdtContract), investor, investment);
            }
        }

        uint leftUsdtAmount = IERC20(usdtContract).balanceOf(address(this));
        if (leftUsdtAmount > 0) {
            SafeERC20.safeTransfer(IERC20(usdtContract), platformAddr, leftUsdtAmount);
        }
    }

    function _getTogetherSupply(uint _count) private {
        uint _num = IERC20(daiContract).balanceOf(address(this));
        require(_num > 0,"invalid param");
        for (uint i = 0; i < _count;i++) {
            SafeERC20.safeApprove(IERC20(daiContract),cDaiContract,_num);
            require(ICDaiErc20(cDaiContract).mint(_num) == 0,"supply fail");
            supplySection.push(_num);
            if(i != _count - 1){
                _num = _num.mul(mortgageFactor).div(100);
                require(ICDaiErc20(cDaiContract).borrow(_num) == 0,"borrow fail");     
            }
       }
    }

    function _getTogetherRedeem() private {
        uint _totalSupplyCurrrent;
        uint _totalBorrowCurrrent;
        uint _value;
        uint _length = supplySection.length;
        for(uint i = 0; i < _length ;i++){
            _totalBorrowCurrrent = ICDaiErc20(cDaiContract).borrowBalanceCurrent(address(this));
            if(_totalBorrowCurrrent == 0){
                break;
            }
            _totalSupplyCurrrent = ICDaiErc20(cDaiContract).balanceOfUnderlying(address(this));
            _value = _totalSupplyCurrrent.sub(_totalBorrowCurrrent.mul(100).div(maxMortgageFactor));
    
            require(ICDaiErc20(cDaiContract).redeemUnderlying(_value) == 0,"redeemUnderlying fail");  
            
            if(_value > _totalBorrowCurrrent){
                _value = _totalBorrowCurrrent;
            }
            SafeERC20.safeApprove(IERC20(daiContract),cDaiContract,_value);
            require(ICDaiErc20(cDaiContract).repayBorrow(_value) == 0,"repayBorrow fail"); 
        }

        
        _value = ICDaiErc20(cDaiContract).balanceOf(address(this));
        if(_value > 0){
             require(ICDaiErc20(cDaiContract).redeem(_value) == 0,"redeem fail"); 
        }
      
    }
    
    function repayAllBorrow() external onlyOwner(){
       uint value;    
       uint totalBorrowCurrrent = ICDaiErc20(cDaiContract).borrowBalanceCurrent(address(this));
       uint balance = IERC20(daiContract).balanceOf(address(this));
       require(balance >= totalBorrowCurrrent ,"dai balance no enouth");
       value = ICDaiErc20(cDaiContract).borrowBalanceCurrent(address(this)); 
       if(value > 0){
           SafeERC20.safeApprove(IERC20(daiContract),cDaiContract,value);
           require(ICDaiErc20(cDaiContract).repayBorrow(value) == 0,"repayBorrow fail");
       }
       
    }

    function _cleanAllInfo() private {
        _deleteAllInvestorInfo();
        delete totalInvestor;
        delete supplySection;
        delete crowdfundNumber;  
        delete crowdfundPeriod;
        delete dartNumber;
        delete dartPeriod;
        status = DefiStatus.UNUSED;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function startCrowdFunding(uint _totalInvestment, uint _crowdfundPeriod) external onlyOwner() {
        require(status == DefiStatus.UNUSED, "not unused status");
        require(_totalInvestment > 0 && _crowdfundPeriod > 0, "error crowdFunding time");
        status = DefiStatus.CROWDFUNDING;
        totalInvestor = _totalInvestment;
        crowdfundNumber = block.number;
        crowdfundPeriod = _crowdfundPeriod.div(15);
    }
    
    function crowdFunding(uint amount) external {
        require(status == DefiStatus.CROWDFUNDING, "not crowdfunding status");
        require(amount >= minCrowdFundingAmount,"not enough amount");
        require(block.number < crowdfundNumber.add(crowdfundPeriod), "crowdfunding time has passed");
        SafeERC20.safeTransferFrom(IERC20(usdtContract), msg.sender, address(this), amount);
        _addInverstorInfo(msg.sender, amount);
        uint currentAmount = _getTotalInvestment();
        if (currentAmount >= totalInvestor) {
            status = DefiStatus.WAITDART;
        }
    }
    
    function cancelCrowdfunding() external {
        require(status == DefiStatus.CROWDFUNDING || status == DefiStatus.WAITDART);
        uint allowInvestmentNumber = crowdfundNumber.add(crowdfundPeriod).add(intervalNumber);
        require(msg.sender == owner || (_isContainsInvestors(msg.sender) && (block.number > allowInvestmentNumber)));
        _batchTransferPrincipal();
        _cleanAllInfo();
    }

    function startDart(uint count, uint duration) external onlyOwner() {
        require(status == DefiStatus.WAITDART, "not wait dart status");
        require(count > 0 && duration > 0, "error startDart time");
        _swap(usdtContract, daiContract); 
        _getTogetherSupply(count);
        status = DefiStatus.DARTSUCCESS;
        dartNumber = block.number;
        dartPeriod = duration.div(15);
    }
    
    function startLiquidation() external {
        require(status == DefiStatus.DARTSUCCESS);
        uint allowInvestmentNumber = dartNumber.add(dartPeriod).add(intervalNumber);
        require(msg.sender == owner || (_isContainsInvestors(msg.sender) && (block.number > allowInvestmentNumber)) || _isAdmin(msg.sender));
        _getTogetherRedeem();
        _swap(daiContract, usdtContract);
        _swap(compContract, usdtContract);
        _batchTransferPrincipalAndIncome();
        _cleanAllInfo();
    }


    function claimComp() external onlyOwner() {
        ICDaiErc20(compComptrollerContract).claimComp(address(this));
        _swap(compContract, usdtContract);

    }

    function setOwner(address _address) external onlyOwner() {
         owner = _address;
    }

    function setIsUniswapWay(bool _isUniswapWay) external onlyOwner() {
        isUniswapWay = _isUniswapWay;
    }

    function setCurveInfo(address _poolAddr, int128 _usdtIndex, int128 _daiIndex) external onlyOwner() {
        curvePoolContract = _poolAddr;
        curveUsdtIndex = _usdtIndex;
        curveDaiIndex = _daiIndex;
    }

    function setMinCrowdFundingAmount(uint minAmount) external onlyOwner() {
        minCrowdFundingAmount = minAmount;
    }

    function setPlatformIncomeAddress(address _address) external onlyOwner() {
        platformAddr = _address;
    }

    function setPlatformCoefficient(uint8 _platformCoefficient) external onlyOwner() {
        platformCoefficient = _platformCoefficient;
    }

    function setMortgageFactor(uint _mortgageFactor) external onlyOwner() {
         mortgageFactor = _mortgageFactor;
    }
    
    function setMaxMortgageFactor(uint _mortgageFactor) external onlyOwner() {
         maxMortgageFactor = _mortgageFactor;
    }

    function addAdmin(address _address) external onlyOwner() {
        admins[_address] = true;
    }

    function removeAdmin(address _address) external onlyOwner() {
        delete admins[_address];
    }

    function investorAmount(address investor) external view returns(uint) {
        return investments[investor];
    }

    function currentTotalAmount() external view returns(uint) {
        return _getTotalInvestment();
    }
 
    function currentInvestors()  external view returns(address[] memory,uint[] memory amountArray) {
        amountArray = new uint[](investors.length);
        for(uint i = 0; i < investors.length ;i++){
           amountArray[i] = investments[investors[i]];
        }
        return (investors,amountArray);
    }

}