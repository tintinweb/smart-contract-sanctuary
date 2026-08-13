/**
 *Submitted for verification at hecoinfo.com on 2022-05-05
*/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: Unlicensed

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// owner
contract Ownable {
    address public _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, 'DividendTracker: owner error');
        _;
    }

    function changeOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;       
    }
}

contract LPTokenWrapper is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable _htLPToken;
    IERC20 public immutable _usdtLPToken;    
    IERC20 public immutable _hsbToken;
    IERC20 public immutable _shjToken;        

    uint256 private _totalSupply;
    uint256 private _totalPower;
    uint256 private _totalMint;
    
    uint256 public _htLpPct;
    uint256 public _usdtLpPct;
    uint256 public _totalHTlp;
    uint256 public _totalUSDTlp;                    

    mapping(address => uint256) public _lastLpSHJ;
    mapping(address => uint256) public _isLpSHJ;
    mapping(address => uint256) public _myLpSHJ;         
    uint256 public _totalLpSHJ;
    uint256 public _isTotalLpSHJ;       

    mapping(address => uint256) private _balancesHTlp;
    mapping(address => uint256) private _balancesUSDTlp;    
    mapping(address => uint256) private _power;
    mapping(address => uint256) private _mint;
    mapping(address => uint256) public _isMint;
    mapping(address => uint256) public _mintTime;

    mapping(address => uint256) private _numTokenList;
    mapping(address => mapping(uint256 => uint256)) private _tokenListNum;
    mapping(address => mapping(uint256 => uint256)) private _tokenListTime;
    mapping(address => mapping(uint256 => uint256)) private _tokenListStatus;
    mapping(address => mapping(uint256 => uint256)) private _tokenListType;
    mapping(address => mapping(uint256 => uint256)) private _tokenListCoin;

    bool public _openFund;                    
  
    event Deposited(address indexed user, uint256 amount, string typeCoin);
    event Withdrawed(address indexed user, uint256 amount, string typeCoin);
    event WithdrawFund(address indexed user, uint256 amount);    
    event WithdrawMint(address indexed user, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(IERC20 htLPToken, IERC20 usdtLPToken, IERC20 hsbToken, IERC20 shjToken) {
        _htLPToken = htLPToken;
        _usdtLPToken = usdtLPToken;        
        _hsbToken = hsbToken;
        _shjToken = shjToken;
        _htLpPct = 27728451411;
        _usdtLpPct = 1;
        _owner = msg.sender;
        _openFund = false;
    }
          
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function totalPower() public view returns (uint256) {
        return _totalPower;
    }

    function totalMint() public view returns (uint256) {
        return _totalMint;
    }          

    function balanceOfHTlp(address account) public view returns (uint256) {
        return _balancesHTlp[account];
    }

    function balanceOfUSDTlp(address account) public view returns (uint256) {
        return _balancesUSDTlp[account];
    }          

    function powerOf(address account) public view returns (uint256) {
        return _power[account];
    }

    function mintOf(address account) public view returns (uint256) {
        return _mint[account];
    }  

    function myDayMint(address account) public view returns (uint256) {
        if(_totalPower == 0){
            return 0;
        }
        else{
            return _power[account].div(_totalPower).mul(5*10**18);
        }
    }

    function myFund() public view returns (uint256) {
        uint256 shjBalances = _shjToken.balanceOf(address(this));             
        uint256 totalLpSHJ = shjBalances + _isTotalLpSHJ;
        if(_lastLpSHJ[msg.sender] > 0 && totalLpSHJ >= _lastLpSHJ[msg.sender] && _totalPower>0){
            uint256 myLpSHJ =  totalLpSHJ - _lastLpSHJ[msg.sender];
            return _power[msg.sender].mul(myLpSHJ).div(_totalPower);                                
        }
        else{
            return 0;
        }
    }    

    function tokenListStatus(address owner, uint256 num)
        public
        view
        returns (uint256)
    {
        uint256 status;
        uint256 tokenType = _tokenListType[owner][num];
        if(tokenType == 1)status=_tokenListTime[owner][num] + 1 days <= block.timestamp?_tokenListStatus[owner][num]:2;
        if(tokenType == 2)status=_tokenListTime[owner][num] + 90 days <= block.timestamp?_tokenListStatus[owner][num]:2;
        if(tokenType == 3)status=_tokenListTime[owner][num] + 180 days <= block.timestamp?_tokenListStatus[owner][num]:2;
        if(tokenType == 4)status=_tokenListTime[owner][num] + 270 days <= block.timestamp?_tokenListStatus[owner][num]:2;
        if(tokenType == 5)status=_tokenListTime[owner][num] + 365 days <= block.timestamp?_tokenListStatus[owner][num]:2;                
        if(tokenType == 6)status=_tokenListTime[owner][num] + 730 days <= block.timestamp?_tokenListStatus[owner][num]:2;
        return status;
    }

    function tokenList(address owner)
        public
        view
        returns(
            uint256[] memory token_List_Num, 
            uint256[] memory token_List_Time, 
            uint256[] memory token_List_Status, 
            uint256[] memory token_List_Type, 
            uint256[] memory token_List_Coin
        )
    {
        uint256 num = _numTokenList[owner];
        // 初始化数组大小
        token_List_Num = new uint256[](num);
        token_List_Time = new uint256[](num);
        token_List_Status = new uint256[](num);
        token_List_Type = new uint256[](num);
        token_List_Coin = new uint256[](num);                        
        
        // 给数组赋值
		for(uint256 i =1; i<=num; i++){
            token_List_Num[i-1] = _tokenListNum[owner][i];
            token_List_Time[i-1] =  _tokenListTime[owner][i];
            token_List_Status[i-1] = tokenListStatus(owner, i);
            token_List_Type[i-1] = _tokenListType[owner][i];
            token_List_Coin[i-1] = _tokenListCoin[owner][i];
        }

        return (token_List_Num, token_List_Time, token_List_Status, token_List_Type, token_List_Coin);
    }        

    function _updateTokenList(uint256 amount, uint256 typeNum, uint256 typeCoin) private {
        _numTokenList[msg.sender] += 1;
        _tokenListNum[msg.sender][_numTokenList[msg.sender]] = amount;
        _tokenListTime[msg.sender][_numTokenList[msg.sender]] = block.timestamp;
        _tokenListStatus[msg.sender][_numTokenList[msg.sender]] =  1; 
        _tokenListType[msg.sender][_numTokenList[msg.sender]] = typeNum;
        _tokenListCoin[msg.sender][_numTokenList[msg.sender]] = typeCoin;               
    }                   

    function _depositTran(uint256 amount, uint256 typeNum, uint256 typeCoin) private {
        if(typeNum == 1){
            _updateTokenList(amount, typeNum, typeCoin);
        }
        if(typeNum == 2){
            _updateTokenList(amount, typeNum, typeCoin);
            amount += amount.div(2);                      
        }
        if(typeNum == 3){
            _updateTokenList(amount, typeNum, typeCoin);
            amount += amount;                       
        }
        if(typeNum == 4){
            _updateTokenList(amount, typeNum, typeCoin);
            amount += amount.mul(2);                                 
        }
        if(typeNum == 5){
            _updateTokenList(amount, typeNum, typeCoin);
            amount += amount.mul(4);                                 
        }
        if(typeNum == 6){
            _updateTokenList(amount, typeNum, typeCoin);
            amount += amount.mul(9);                                   
        }
        if(typeCoin == 1) amount = amount.mul(_htLpPct).div(100);
        if(typeCoin == 2) amount = amount.mul(_usdtLpPct).div(100);                                        
        _power[msg.sender] += amount;
        _totalPower += amount;
    }  

    function _deposit(uint256 amount, uint256 typeNum, uint256 typeCoin) private {
        _totalSupply = _totalSupply.add(amount);
        if(typeCoin == 1){
            _htLPToken.safeTransferFrom(msg.sender, address(this), amount);
            _balancesHTlp[msg.sender] = _balancesHTlp[msg.sender].add(amount);
            _totalHTlp += amount;                    
        }
        else{
            _usdtLPToken.safeTransferFrom(msg.sender, address(this), amount);
            _balancesUSDTlp[msg.sender] = _balancesUSDTlp[msg.sender].add(amount);
            _totalUSDTlp += amount;             
        }
        //SHJ  LP分红
        uint256 shjBalances = _shjToken.balanceOf(address(this));             
        _totalLpSHJ = shjBalances + _isTotalLpSHJ;
        if(_lastLpSHJ[msg.sender] > 0 && _totalLpSHJ >= _lastLpSHJ[msg.sender] && _totalPower>0){
            uint256 totalLpSHJ =  _totalLpSHJ - _lastLpSHJ[msg.sender];
            _myLpSHJ[msg.sender] += _power[msg.sender].mul(totalLpSHJ).div(_totalPower);                                
        }
        _lastLpSHJ[msg.sender] = _totalLpSHJ;
        if(_mintTime[msg.sender] == 0)_mintTime[msg.sender] = block.timestamp;
        _updateMint();
        if(_mint[msg.sender]>0 && _mintTime[msg.sender] <= block.timestamp)_withdrawMint();
        _depositTran(amount, typeNum, typeCoin);
    }

    function _withdrawTran(uint256 amount, uint256 typeNum, uint256 listNum) private {
        uint256 typeCoin = _tokenListCoin[msg.sender][listNum];        
        if(_numTokenList[msg.sender]<1)return;
        if(typeNum == 2){
            amount += amount.div(2);           
        }
        if(typeNum == 3){
            amount += amount;          
        }
        if(typeNum == 4){
            amount += amount.mul(2);          
        }
        if(typeNum == 5){
            amount += amount.mul(4);          
        }
        if(typeNum == 6){
            amount += amount.mul(9);
        }
        if(typeCoin == 1) amount = amount.mul(_htLpPct).div(100);
        if(typeCoin == 2) amount = amount.mul(_usdtLpPct).div(100);        
        if(_power[msg.sender]>= amount){
            _power[msg.sender] -= amount;
        }
        else{
           _power[msg.sender] = 0; 
        }  
        if(_totalPower>= amount){
            _totalPower -= amount;
        }
        else{
            _totalPower = 0; 
        }  
        _tokenListStatus[msg.sender][listNum] = 0;
        if(_power[msg.sender] == 0 || _totalPower == 0){
            _lastLpSHJ[msg.sender] = 0;
            _mintTime[msg.sender] = 0;
            _mint[msg.sender] = 0;
        }         
    }

    function _updateMint() private {
        uint256 dayMint = 0;
        if(_totalPower > 0)dayMint = _power[msg.sender].mul(5*10**18).div(_totalPower);
        if(_mintTime[msg.sender] <= block.timestamp && _mintTime[msg.sender] > 0){
            uint256 passDays = block.timestamp.sub(_mintTime[msg.sender]).div(86400);
            uint256 tokenBalance = _hsbToken.balanceOf(address(this));
            if(tokenBalance < dayMint.mul(passDays)){
                _mint[msg.sender] = tokenBalance;
            }
            else{
                _mint[msg.sender] = dayMint.mul(passDays);
            }
        }
    }    

    function _withdrawMint() private {
        require(_mint[msg.sender]>0, "less than zero");
        require(_mintTime[msg.sender] <= block.timestamp, "waiting time");
        uint256 tokenBalance = _hsbToken.balanceOf(address(this));
        if(tokenBalance < _mint[msg.sender])return;
        _hsbToken.safeTransfer(msg.sender, _mint[msg.sender]);        
        _totalMint = _totalMint.add(_mint[msg.sender]);
        _isMint[msg.sender] = _isMint[msg.sender].add(_mint[msg.sender]);
        _mintTime[msg.sender] = block.timestamp + 86400;
        _mint[msg.sender] = 0;        
    }    

    function _withdraw(uint256 amount, uint256 typeNum, uint256 listNum) private {
        uint256 typeCoin = _tokenListCoin[msg.sender][listNum];
        if(typeCoin > 2)return;
        if(typeCoin == 1){
            _htLPToken.safeTransfer(msg.sender, amount);
            _totalSupply = _totalSupply.sub(amount);
            _balancesHTlp[msg.sender] = _balancesHTlp[msg.sender].sub(amount);
            _totalHTlp -= amount;            
        }
        if(typeCoin == 2){
            _usdtLPToken.safeTransfer(msg.sender, amount);
            _totalSupply = _totalSupply.sub(amount);
            _balancesUSDTlp[msg.sender] = _balancesUSDTlp[msg.sender].sub(amount);
            _totalUSDTlp -= amount;            
        }
        _updateMint();
        if(_mint[msg.sender]>0 && _mintTime[msg.sender] <= block.timestamp)_withdrawMint();               
        _withdrawTran(amount, typeNum, listNum); 
    }

    function _updateFund() private {
        uint256 shjBalances = _shjToken.balanceOf(address(this));             
        _totalLpSHJ = shjBalances + _isTotalLpSHJ;
        if(_lastLpSHJ[msg.sender] > 0 && _totalLpSHJ >= _lastLpSHJ[msg.sender] && _totalPower>0){
            uint256 totalLpSHJ =  _totalLpSHJ - _lastLpSHJ[msg.sender];
            _myLpSHJ[msg.sender] += _power[msg.sender].mul(totalLpSHJ).div(_totalPower);
            _lastLpSHJ[msg.sender] = _totalLpSHJ;                                
        }
    }

    function _withdrawFund() private{
        require(_myLpSHJ[msg.sender] > 1*10**6, "less than withdraw Min");
        require(_myLpSHJ[msg.sender]<=_shjToken.balanceOf(address(this)), "balance not enough");
        require(_openFund, "not open");        
        _shjToken.safeTransfer(msg.sender, _myLpSHJ[msg.sender]);
        _isLpSHJ[msg.sender] += _myLpSHJ[msg.sender];
        _isTotalLpSHJ += _myLpSHJ[msg.sender];
        _myLpSHJ[msg.sender] = 0;
        emit WithdrawFund(msg.sender, _myLpSHJ[msg.sender]);            
    }      

    function withdrawMint() public { 
        uint256 dayMint = _power[msg.sender].div(_totalPower).mul(5*10**18);
        _updateMint();
        _withdrawMint();
        emit WithdrawMint(msg.sender, dayMint);
    }

    function updateMint() public returns(bool) { 
        _updateMint();
        return true;
    }

    function changePct(uint256 htLpPct, uint256 usdtLpPct)  public onlyOwner returns (bool){ 
        _htLpPct = htLpPct;
        _usdtLpPct = usdtLpPct;
        return true;
    } 

    function updateFund() public returns (bool){
        _updateFund();
        return true;
    }

    function changeOpenFund(bool value) public onlyOwner returns (bool){
        _openFund = value;
        return true;
    }         

    function withdrawFund() public returns (bool){
        _updateFund();
        _withdrawFund();
        return true;
    }        

    function deposit(uint256 amount, uint256 typeNum, uint256 typeCoin) public { 
        require(amount > 0, "Cannot stake 0");
        require(typeNum <= 6, "Out off 6 type");
        require(typeCoin <= 2, "Out off 2 type");
        string memory coin;
        if(typeCoin == 1){
            require(_htLPToken.balanceOf(msg.sender) >= amount, "LP not enough");
            coin = "HTLP";
        }
        if(typeCoin == 2){
            require(_usdtLPToken.balanceOf(msg.sender) >= amount, "LP not enough");            
            coin = "USDTTLP";
        }
        _deposit(amount, typeNum, typeCoin);     
        emit Deposited(msg.sender, amount, coin);
    }

    function withdraw(uint256 amount, uint256 typeNum, uint256 listNum) public {
        require(amount > 0, "Cannot withdraw 0");
        require(typeNum <= 6, "Out off 6 type");
        require(_tokenListType[msg.sender][listNum] == typeNum, "typeNum ERROR");
        if(typeNum == 1){
            require(block.timestamp >= _tokenListTime[msg.sender][listNum] + 1 days, "can not withdraw by this time");
        }         
        if(typeNum == 2){
            require(block.timestamp >= _tokenListTime[msg.sender][listNum] + 90 days, "can not withdraw by this time");
        }
        if(typeNum == 3){
            require(block.timestamp >= _tokenListTime[msg.sender][listNum] + 180 days, "can not withdraw by this time");
        } 
        if(typeNum == 4){
            require(block.timestamp >= _tokenListTime[msg.sender][listNum] + 270 days, "can not withdraw by this time");
        } 
        if(typeNum == 5){
            require(block.timestamp >= _tokenListTime[msg.sender][listNum] + 365 days, "can not withdraw by this time");
        } 
        if(typeNum == 6){
            require(block.timestamp >= _tokenListTime[msg.sender][listNum] + 730 days, "can not withdraw by this time");
        }             
        _withdraw(amount, typeNum, listNum);
        uint256 typeCoin = _tokenListCoin[msg.sender][listNum];        
        string memory coin;
        if(typeCoin == 1)coin = "HTLP";
        if(typeCoin == 2)coin = "USDTLP";
        emit Withdrawed(msg.sender, amount, coin);
    }

    function withdrawToken(IERC20 token, address to, uint256 value) public onlyOwner {
        token.safeTransfer(to, value);
    }        

}