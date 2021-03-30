/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional

            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract WolfyRiskPlatform is Ownable {
    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;


    uint256 public startTime = block.timestamp;

    constructor(address _wolfy){
      WOLFY = IERC20(_wolfy);
    }
    
    uint256 snp500; 
    uint256 defiPulse;

    uint256 netSNP;
    uint256 netDefi;
    uint256 performanceValue;
    bool A;
    bool B;

    uint256 sessionStart;
    bool isSessionEnding;
    uint256 counterLowRisk = 0;
    uint256 counterHighRisk = 0;

    uint256 winner;
    bool who;
    address[] lowRiskUsers; 
    address[] highRiskUsers; 
    uint256 wolfyLimit = 20*10**3*10**18;

    IERC20 public WOLFY;
    
    mapping(address => uint256) private _balances;
  
    mapping(address => mapping(bool => uint256)) private _balancesRiskPool;
    mapping(address =>  mapping(bool => uint256)) private _ethBalanceRiskPool;
 
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account]; 
    }

    function balanceOf(address account, bool _isLowRisk) public view returns (uint256) {
        return _balancesRiskPool[account][_isLowRisk];
        
    }

    function checkETHBalRisPool(address account, bool _isLowRisk) public view returns (uint256) {
        return _ethBalanceRiskPool[account][_isLowRisk];
    }

    function stake(uint256 amount, bool _isLowRisk) public payable{
     require(isSessionEnding, "Pool has not been started by admin yet");
     require(block.timestamp <= startTime.add(12 hours) ); // Can stake upto 12 hours from start pool.
     require(WOLFY.balanceOf(msg.sender) >= wolfyLimit || msg.sender == owner(), "You must possess 20K WOLFY Tokens to Participate");
      
      if(_isLowRisk){
       
       lowRiskUsers.push(msg.sender);

      }else
        
        highRiskUsers.push(msg.sender);
     
     _stake(amount, _isLowRisk);

    }

    function _stake(uint256 amount, bool _isLowRisk) internal {

        _balancesRiskPool[msg.sender][_isLowRisk] = _balancesRiskPool[msg.sender][_isLowRisk].add(amount);
        _ethBalanceRiskPool[msg.sender][_isLowRisk] = _ethBalanceRiskPool[msg.sender][_isLowRisk].add(msg.value);          //______| Record of ETH deposit |______

        WOLFY.safeTransferFrom(msg.sender, address(this), amount);
        counterLowRisk += 1; 
    }


    function raisePercent(uint256 _v1, uint256 _v2) internal pure returns (uint256, bool) {
        if(_v1 > _v2){
          return (_v1.sub(_v2).mul(1000).div(_v1), false);          //___| Deprecation over time |______
       } else {
          return (_v2.sub(_v1).mul(1000).div(_v1), true);           //___| Increase over time |____
       }
    }

    function checkPerformance(uint256 _inputDeFi, uint256 _inputSNP, bool _polarityDeFi, bool _polaritySnp) public pure returns (uint256 _winner, bool _who) {
        
        if(!_polarityDeFi && !_polaritySnp){
        
            if(_inputDeFi > _inputSNP){
                return (_inputDeFi.div(_inputSNP), false); 
            } else
                return (_inputSNP.div(_inputDeFi), true);

        }else if(_polarityDeFi && !_polaritySnp){
            
            return (_inputDeFi.add(_inputSNP), true);

        }else if(!_polarityDeFi && _polaritySnp){
            
            return (_inputDeFi.add(_inputSNP), false);
  
        }else if(_polarityDeFi && _polaritySnp){
            
                if(_inputDeFi > _inputSNP){
                return (_inputDeFi.div(_inputSNP), true);
            } else
                return (_inputSNP.div(_inputDeFi), false);

        }

    }

    function magicBox(uint256 _factor, bool _champ) internal {

       if(_factor > 150 && _champ == true){

        for(uint i = 0 ; i < lowRiskUsers.length ; i++){

            _balancesRiskPool[lowRiskUsers[i]][true] += _balancesRiskPool[lowRiskUsers[i]][true].mul(120).div(1000);
            _ethBalanceRiskPool[lowRiskUsers[i]][true] += _ethBalanceRiskPool[lowRiskUsers[i]][true].mul(120).div(1000);

        }

       } else {
         
         for(uint i = 0 ; i < lowRiskUsers.length ; i++){
            _balancesRiskPool[lowRiskUsers[i]][true] += _balancesRiskPool[lowRiskUsers[i]][true].mul(150).div(1000);
            _ethBalanceRiskPool[lowRiskUsers[i]][true] += _ethBalanceRiskPool[lowRiskUsers[i]][true].mul(150).div(1000);
        }

       }

        if(_factor > 500 && _champ == true){

          for(uint i = 0 ; i < highRiskUsers.length ; i++){
             _balancesRiskPool[highRiskUsers[i]][false] += _balancesRiskPool[highRiskUsers[i]][false].mul(300).div(1000);
            _ethBalanceRiskPool[highRiskUsers[i]][false] += _ethBalanceRiskPool[highRiskUsers[i]][false].mul(300).div(1000);
        }

        }else{

          for(uint i = 0 ; i < highRiskUsers.length ; i++){
             _balancesRiskPool[highRiskUsers[i]][false] += _balancesRiskPool[highRiskUsers[i]][false].mul(350).div(1000);
            _ethBalanceRiskPool[highRiskUsers[i]][false] += _ethBalanceRiskPool[highRiskUsers[i]][false].mul(350).div(1000);
        }

        }
    }

    function startPool(uint256 amount, uint256 _defiPulse, uint256 _snp500) public payable onlyOwner { 

        if(isSessionEnding == false){
            snp500 = _snp500;
            defiPulse = _defiPulse;
            sessionStart = block.timestamp;
                
            } else if(isSessionEnding == true){
        
               (netSNP, A)  = raisePercent(snp500,_snp500);           //___either positive or negative
               (netDefi, B) = raisePercent(defiPulse,_defiPulse);     //___either positive or negative

              (winner , who) = checkPerformance(netSNP, netDefi, A, B);

               magicBox(winner, who);

            }

        if(!isSessionEnding){
            isSessionEnding = true;
            
        } else {
            isSessionEnding = false;
        }

            _stake(amount, true); // Defauts to Low Risk pool
            startTime = block.timestamp;
    }

    function withdrawToken(uint256 _amount, bool _isLowRisk) public {
       require(_amount <= _balancesRiskPool[msg.sender][_isLowRisk], "Insufficient Tokens in your wallet");
        _balancesRiskPool[msg.sender][_isLowRisk] = _balancesRiskPool[msg.sender][_isLowRisk].sub(_amount);
        WOLFY.safeTransfer(msg.sender, _amount);
    }


    function withdrawETH(uint256 _ether, bool _isLowRisk) public {
         require(_ether <= _ethBalanceRiskPool[msg.sender][_isLowRisk], "Insufficient Tokens in your wallet");
        _ethBalanceRiskPool[msg.sender][_isLowRisk] = _ethBalanceRiskPool[msg.sender][_isLowRisk].sub(_ether);
        payable(msg.sender).transfer(_ether);                                     
    }


}