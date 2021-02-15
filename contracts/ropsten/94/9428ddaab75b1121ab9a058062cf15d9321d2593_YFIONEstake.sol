/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: none

pragma solidity >=0.5.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract YFIONEstake is Context {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    struct periodList{
        uint256 periodTime;
        uint256 cooldownTime;
        uint256 formulaParam1;
        uint256 formulaParam2;
        uint256 formulaPenalty1;
        uint256 formulaPenalty2;
    }
    
    struct userstaking{
        bool activestake;
        uint periodChoosed;
        address tokenWantstake;
        uint256 amountstaked;
        uint256 startstake;
        uint256 claimstake;
        uint256 endstake;
        uint256 cooldownDate;
        uint256 claimed;
    }
    
    struct rewardDetail{
        string symboltoken;
        uint256 equalReward;
        uint256 minimalstake;
        uint decimaltoken;
    }
    
    mapping (uint => periodList) private period;
    mapping (address => rewardDetail) private ERC20perYFIONE;
    mapping (address => userstaking) private stakeDetail;
    mapping (address => uint256) private devBalance;
    
    address private _owner;
    address private _YFIONEtoken;
    address[] private _tokenstakeList;
    address[] private _stakeerList;
    uint[] private _periodList;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event stake(address indexed staker, address indexed tokenstakeTarget, uint256 indexed amountTokenstaked);
    event Unstake(address indexed staker, address indexed tokenstakeTarget, uint256 indexed amountTokenstaked);
    event Claim(address indexed staker, address indexed tokenstakeTarget, uint256 indexed amountReward);
    
    constructor(address YFIONEAddress){
        rewardDetail storage est = ERC20perYFIONE[YFIONEAddress];
        rewardDetail storage nul = ERC20perYFIONE[address(0)];
        require(YFIONEAddress.isContract() == true,"This address is not Smartcontract");
        require(IERC20(YFIONEAddress).totalSupply() != 0, "This address is not ERC20 Token");
        address msgSender = _msgSender();
        _YFIONEtoken = YFIONEAddress;
        _owner = msgSender;
        _tokenstakeList.push(YFIONEAddress);
        _tokenstakeList.push(address(0));
        est.symboltoken = "YFO";
        est.decimaltoken = 18;
        est.minimalstake = 10**16;
        est.equalReward = 10**18;
        nul.symboltoken = "ETH";
        nul.minimalstake = 10**16;
        nul.equalReward = (10**18) / 2;
        nul.decimaltoken = 18;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function addTokenReward(address erc20Token, uint256 amountEqual, uint256 minstake, uint decimall, string memory symboltokens) public virtual onlyOwner{
        if(erc20Token != address(0)){
            require(erc20Token.isContract() == true,"This address is not Smartcontract");
            require(IERC20(erc20Token).totalSupply() != 0, "This address is not ERC20 Token");
        }
        
        rewardDetail storage est = ERC20perYFIONE[erc20Token];
        est.equalReward = amountEqual;
        est.symboltoken = symboltokens;
        est.minimalstake = minstake;
        est.decimaltoken = decimall;
        
        _tokenstakeList.push(erc20Token);
    }
    
    function editTokenReward(address erc20Token, uint256 amountEqual, uint256 minstake, uint decimall, string memory symboltokens) public virtual onlyOwner{
        if(erc20Token != address(0)){
            require(erc20Token.isContract() == true,"This address is not Smartcontract");
            require(IERC20(erc20Token).totalSupply() != 0, "This address is not ERC20 Token");
        }
        
        rewardDetail storage est = ERC20perYFIONE[erc20Token];
        est.equalReward = amountEqual;
        est.symboltoken = symboltokens;
        est.minimalstake = minstake;
        est.decimaltoken = decimall;
    }
    
    function addPeriod(uint256 timePeriodstake, uint256 timeCooldownUnstake, uint256 formula1, uint256 formula2, uint256 fpel1, uint256 fpel2) public virtual onlyOwner{
        uint newPeriod = _periodList.length;
        if(newPeriod == 0){
            newPeriod = 1;
        }else{
            newPeriod = newPeriod + 1;
        }
        
        periodList storage sys = period[newPeriod];
        sys.periodTime = timePeriodstake;
        sys.cooldownTime = timeCooldownUnstake;
        sys.formulaParam1 = formula1;
        sys.formulaParam2 = formula2;
        sys.formulaPenalty1 = fpel1;
        sys.formulaPenalty2 = fpel2;
        
        _periodList.push(newPeriod);
    }
    
    function editPeriod(uint periodEdit, uint256 timePeriodstake, uint256 timeCooldownUnstake, uint256 formula1, uint256 formula2, uint256 fpel1, uint256 fpel2) public virtual onlyOwner{
        periodList storage sys = period[periodEdit];
        sys.periodTime = timePeriodstake;
        sys.cooldownTime = timeCooldownUnstake;
        sys.formulaParam1 = formula1;
        sys.formulaParam2 = formula2;
        sys.formulaPenalty1 = fpel1;
        sys.formulaPenalty2 = fpel2;
    }
    
    function claimDevBalance(address target) public virtual onlyOwner{
        if(target == address(0)){
            payable(_owner).transfer(devBalance[target]);
        }else{
            IERC20(target).safeTransfer(_owner, devBalance[target]);
        }
        
        devBalance[target] = 0;
    }
    
    function claimReward() public virtual{
        address msgSender = _msgSender();
        userstaking storage usr = stakeDetail[msgSender];
        uint256 getrewardbalance = IERC20(_YFIONEtoken).balanceOf(address(this));
        uint256 getReward = getRewardClaimable(msgSender);
        uint256 today = block.timestamp;
        
        require(getrewardbalance >= getReward, "Please wait until reward pool filled, try again later.");
        require(usr.claimstake < block.timestamp, "Please wait until wait time reached.");
        
        usr.claimed = usr.claimed.add(getReward);
        usr.claimstake = today.add(7 days);
        IERC20(_YFIONEtoken).safeTransfer(msgSender, getReward);
        emit Claim(msgSender, _YFIONEtoken, getReward);
    }
    
    function stakeNow(address tokenTargetstake, uint256 amountWantstake, uint periodwant) public payable virtual{
        address msgSender = _msgSender();
        uint256 getallowance;
        if(tokenTargetstake != address(0)){
            getallowance = IERC20(tokenTargetstake).allowance(msgSender, address(this));
        }
        
        if(getRewardClaimable(msgSender) > 0){
            revert("Please claim your reward from previous stakeing");
        }
        
        uint256 today = block.timestamp;
        userstaking storage usr = stakeDetail[msgSender];
        periodList storage sys = period[periodwant];
        rewardDetail storage est = ERC20perYFIONE[tokenTargetstake];
        
        if(tokenTargetstake == address(0)){
            require(msg.value >= est.minimalstake, "Minimum stakeing value required");
        }else{
            require(amountWantstake >= est.minimalstake, "Minimum stakeing value required");
            require(getallowance >= amountWantstake, "Insufficient token approval balance, you must increase your allowance" );
        }
        
        usr.activestake = true;
        usr.periodChoosed = periodwant;
        usr.tokenWantstake = tokenTargetstake;
        usr.amountstaked = amountWantstake;
        usr.startstake = today;
        usr.claimstake = today.add(7 days);
        usr.cooldownDate = today.add(sys.cooldownTime);
        usr.endstake = today.add(sys.periodTime);
        usr.claimed = 0;
        
        bool checkregis = false;
        for(uint i = 0; i < _stakeerList.length; i++){
            if(_stakeerList[i] == msgSender){
                checkregis = true;
            }
        }
        
        if(checkregis == false){
            _stakeerList.push(msgSender);
        }
        
        if(tokenTargetstake != address(0)){
            IERC20(tokenTargetstake).safeTransferFrom(msgSender, address(this), amountWantstake);
        }
        
        emit stake(msgSender, tokenTargetstake, amountWantstake);
    }
    
    function unstakeNow() public virtual{
        address msgSender = _msgSender();
        userstaking storage usr = stakeDetail[msgSender];
        periodList storage sys = period[usr.periodChoosed];
        
        require(usr.activestake == true, "stake not active yet" );
        
        uint256 tokenUnstake;
        if(block.timestamp < usr.cooldownDate){
            uint256 penfee = usr.amountstaked.mul(sys.formulaPenalty1);
            penfee = penfee.div(sys.formulaPenalty2);
            penfee = penfee.div(100);
            tokenUnstake = usr.amountstaked.sub(penfee);
            devBalance[usr.tokenWantstake] = devBalance[usr.tokenWantstake].add(penfee);
        }else{
            tokenUnstake = usr.amountstaked;
        }
        
        usr.activestake = false;
        if(block.timestamp < usr.endstake){
            usr.endstake = block.timestamp;
        }
        
        if(usr.tokenWantstake == address(0)){
            payable(msgSender).transfer(tokenUnstake);
        }else{
            IERC20(usr.tokenWantstake).safeTransfer(msgSender, tokenUnstake);
        }
        
        uint256 getCLaimableRwt = getRewardClaimable(msgSender);
        
        if(getCLaimableRwt > 0){
            IERC20(_YFIONEtoken).safeTransfer(msgSender, getCLaimableRwt);
            usr.claimed = usr.claimed.add(getCLaimableRwt);
        }
        
        emit Unstake(msgSender, usr.tokenWantstake, usr.amountstaked);
        emit Claim(msgSender, _YFIONEtoken, getCLaimableRwt);
    }
    
    function getDevBalance(address target) public view returns(uint256){
        return devBalance[target];
    }
    
    function getEqualReward(address erc20Token) public view returns(uint256, string memory, uint256, uint){
        rewardDetail storage est = ERC20perYFIONE[erc20Token];
        return(
            est.equalReward,
            est.symboltoken,
            est.minimalstake,
            est.decimaltoken
        );
    }
    
    function getTotalstakeer() public view returns(uint256){
        return _stakeerList.length;
    }
    
    function getActivestakeer() view public returns(uint256){
        uint256 activestake;
        for(uint i = 0; i < _stakeerList.length; i++){
            userstaking memory l = stakeDetail[_stakeerList[i]];
            if(l.activestake == true){
                activestake = activestake + 1;
            }
        }
        return activestake;
    }
    
    function getTokenList() public view returns(address[] memory){
        return _tokenstakeList;
    }
    
    function getPeriodList() public view returns(uint[] memory){
        return _periodList;
    }
    
    function getPeriodDetail(uint periodwant) public view returns(uint256, uint256, uint256, uint256, uint256, uint256){
        periodList storage sys = period[periodwant];
        return(
            sys.periodTime,
            sys.cooldownTime,
            sys.formulaParam1,
            sys.formulaParam2,
            sys.formulaPenalty1,
            sys.formulaPenalty2
        );
    }
    
    function getUserInfo(address stakerAddress) public view returns(bool, uint, address, string memory, uint256, uint256, uint256, uint256, uint256, uint256){
        userstaking storage usr = stakeDetail[stakerAddress];
        rewardDetail storage est = ERC20perYFIONE[usr.tokenWantstake];
        
        uint256 amountTotalstaked;
        if(usr.activestake == false){
            amountTotalstaked = 0;
        }else{
            amountTotalstaked = usr.amountstaked;
        }
        return(
            usr.activestake,
            usr.periodChoosed,
            usr.tokenWantstake,
            est.symboltoken,
            amountTotalstaked,
            usr.startstake,
            usr.claimstake.add(1 minutes),
            usr.endstake,
            usr.cooldownDate,
            usr.claimed
        );
    }
    
    function getRewardClaimable(address stakerAddress) public view returns(uint256){
        userstaking storage usr = stakeDetail[stakerAddress];
        periodList storage sys = period[usr.periodChoosed];
        rewardDetail storage est = ERC20perYFIONE[usr.tokenWantstake];
        
        uint256 rewards;
        
        if(usr.amountstaked == 0 && usr.tokenWantstake == address(0)){
            rewards = 0;
        }else{
            uint256 today = block.timestamp;
            uint256 diffTime;
            if(today > usr.endstake){
                diffTime = usr.endstake.sub(usr.startstake);
            }else{
                diffTime = today.sub(usr.startstake);
            }
            rewards = usr.amountstaked.mul(diffTime);
            uint256 getTokenEqual = est.equalReward;
            rewards = rewards.mul(getTokenEqual);
            rewards = rewards.mul(sys.formulaParam1);
            rewards = rewards.div(10**est.decimaltoken);
            rewards = rewards.div(sys.formulaParam2);
            rewards = rewards.div(100);
            rewards = rewards.sub(usr.claimed);
        }
        return rewards;
    }
    
    function getRewardObtained(address stakerAddress) public view returns(uint256){
        userstaking storage usr = stakeDetail[stakerAddress];
        periodList storage sys = period[usr.periodChoosed];
        rewardDetail storage est = ERC20perYFIONE[usr.tokenWantstake];
        uint256 rewards;
        
        if(usr.amountstaked == 0 && usr.tokenWantstake == address(0)){
            rewards = 0;
        }else{
            uint256 today = block.timestamp;
            uint256 diffTime;
            if(today > usr.endstake){
                diffTime = usr.endstake.sub(usr.startstake);
            }else{
                diffTime = today.sub(usr.startstake);
            }
            rewards = usr.amountstaked.mul(diffTime);
            uint256 getTokenEqual = est.equalReward;
            rewards = rewards.mul(getTokenEqual);
            rewards = rewards.mul(sys.formulaParam1);
            rewards = rewards.div(10**est.decimaltoken);
            rewards = rewards.div(sys.formulaParam2);
            rewards = rewards.div(100);
        }
        return rewards;
    }
    
    function getRewardCalculator(address tokenWantstake, uint256 amountWantstake, uint periodwant) public view returns(uint256){
        periodList storage sys = period[periodwant];
        rewardDetail storage est = ERC20perYFIONE[tokenWantstake];
        
        uint256 startDate = block.timestamp;
        uint256 endDate = startDate.add(sys.periodTime);
        uint256 diffTime = endDate.sub(startDate);
        uint256 rewards = amountWantstake.mul(diffTime);
        uint256 getTokenEqual = est.equalReward;
        rewards = rewards.mul(getTokenEqual);
        rewards = rewards.mul(sys.formulaParam1);
        rewards = rewards.div(10**est.decimaltoken);
        rewards = rewards.div(sys.formulaParam2);
        rewards = rewards.div(100);
        return rewards;
    }
}