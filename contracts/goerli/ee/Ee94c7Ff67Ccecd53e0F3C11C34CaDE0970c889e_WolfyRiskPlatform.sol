/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

/**
    _________________________________________________________________________________________
     1. Stakers can stake upto 12 hours from Pool start time.
     2. The Pool will run for 7 days.
     3. StartPool : Admin will provide DeFi and SNP value initially and start the pools.
     4. StopPool : Admin will provide both value once 7 days is completed.
    __________________________________________________________________________________________
     1. Low Risk  : Stake limit is [6x] of liquidity. 
     2. High Risk : Stake limit is [3x] of liquidity. 
     3. Low Risk is denoted by  [true].
     4. High Risk is denoted by [false]. 
     ___________________________________________________________________________________________
     Stakers must have 20k Wolfy tokens in their wallet to participate in any of the risk pools.
        Test Value : 20
        Mainnet : 20,000

     Pool Duration
        Testnet : 15 minutes 
        Mainet  : 7 days

     Stake Allowed
       Testnet : 5 minues
       Mainnet : 12 hours
     ___________________________________________________________________________________________
     

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

// true = lowRisk
// false = highRisk
contract WolfyRiskPlatform is Ownable {
    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    uint256 public startTime = block.timestamp;

    constructor(address _wolfy){
      WOLFY = IERC20(_wolfy);
    }
    
    uint256 public snp500; 
    uint256 public defiPulse;

    uint256 netSNP;
    uint256 netDefi;
    uint256 performanceValue;
    bool public A;
    bool public B;
    uint256 limitWolfy;
    uint256 limitETH;
    bool public poolStarted;
    uint256 counterHighRisk = 0;

    uint256 public winnerScale;
    bool public who;

    uint8 public thorCheck;

    address[] public _lowRiskWolfyUsers;
    address[] public _highRiskWolfyUsers;
    address[] public _lowRiskETHUsers;
    address[] public _highRiskETHUsers;

    uint256 public depositLowRiskWolfy;
    uint256 public depositLowRiskETH;
    uint256 public depositHighRiskWolfy;
    uint256 public depositHighRiskETH;

    // uint256 wolfyLimit = 20*10**3*10**9; // mainnet
    uint256 wolfyLimit = 20*10**9;       // testnet


    bool checker ;
    uint256 public dummyCheck;
    uint256 public pinkValue;  

    uint256 public inputDefi111;
    uint256 public inputSNP111;

    IERC20 public WOLFY;
    
    mapping(address => uint256) private _balances;
  
    mapping(address => mapping(bool => uint256)) private _balancesRiskPool;
    mapping(address =>  mapping(bool => uint256)) private _ethBalanceRiskPool;

    mapping(address =>  mapping(bool => uint256)) public _lossWOLFYStakers;
    mapping(address =>  mapping(bool => uint256)) public _lossETHStakers;
    
    mapping(address =>  mapping(bool => uint256)) public _profitWOLFYStakers;
    mapping(address =>  mapping(bool => uint256)) public _profitETHStakers;

    // address + isLowRisk + isWolfy + count ==> bool
    mapping(address => mapping(bool => mapping(bool => mapping(uint256 => bool)))) public previousResults;
    
    uint256 public runCount;
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account]; 
    }

    //====== | Get total profits/loss [Wolfy] pool wise |====| Profit{true} and Loss{false} |
    function getProfitLossWolfy(bool _isLowRisk, bool _isProfit) public view returns (uint256) {
        
        if(_isProfit){
            return _profitWOLFYStakers[msg.sender][_isLowRisk]; 
        }
            return _lossWOLFYStakers[msg.sender][_isLowRisk]; 
    }

    //====== | Get total profit/loss [ETH] pool wise |========
    function getProfitLossEth(bool _isLowRisk, bool _isProfit) public view returns (uint256) {
        
        if(_isProfit){
            return _profitETHStakers[msg.sender][_isLowRisk]; 
        }
            return _lossETHStakers[msg.sender][_isLowRisk]; 
    }

    function checkBalanceWOLFY(address account, bool _isLowRisk) public view returns (uint256) {
        return _balancesRiskPool[account][_isLowRisk];
        
    }

    function checkBalanceETH(address account, bool _isLowRisk) public view returns (uint256) {
        return _ethBalanceRiskPool[account][_isLowRisk];
    }


    function storeUsers(address receiver, address[] storage arrayData) internal{

      for(uint i = 0; i < arrayData.length; i++){
        if(arrayData[i] == receiver) {
           checker = true;
        } else {
          checker = false;
        }

      }
        if(checker == false){
          arrayData.push(receiver) ;
        }

    }


    function stakeWolfy(uint256 _amount, bool _isLowRisk) public  {

     require(poolStarted, "Pool has not been started yet");
     require(block.timestamp <= startTime.add(12 hours),"Its more than 12 hours since pool started" ); // Can stake upto 12 hours from start pool.
     require(WOLFY.balanceOf(msg.sender) >= wolfyLimit, "You must possess 20K WOLFY Tokens to Participate");


     if(_isLowRisk){
       require(depositLowRiskWolfy.add(_amount) <= (_balancesRiskPool[owner()][_isLowRisk]).mul(6), "Target 6X reaching");   
       require(_balancesRiskPool[msg.sender][_isLowRisk].add(_amount) <= (_balancesRiskPool[owner()][_isLowRisk]).mul(6), "Exceeding low risk WOLFY limit");
       
       depositLowRiskWolfy += _amount;

     } else {

       require(depositHighRiskWolfy.add(_amount) <= (_balancesRiskPool[owner()][_isLowRisk]).mul(3), "Target 3X reaching");   
       require(_balancesRiskPool[msg.sender][_isLowRisk].add(_amount) <= (_balancesRiskPool[owner()][_isLowRisk]).mul(3), "Exceeding high risk WOLFY limit");
       
       depositHighRiskWolfy += _amount;
    
     }

        //_isLowRisk == true ? _lowRiskWolfyUsers.push(msg.sender): _highRiskWolfyUsers.push(msg.sender); 

        _isLowRisk == true ? storeUsers(msg.sender, _lowRiskWolfyUsers): storeUsers(msg.sender, _highRiskWolfyUsers); 



        _balancesRiskPool[msg.sender][_isLowRisk] = _balancesRiskPool[msg.sender][_isLowRisk].add(_amount);

        WOLFY.safeTransferFrom(msg.sender, address(this), _amount);        //______| Record of ETH deposit |______
    }


    function stakeEth(bool _isLowRisk) public payable {
     require(msg.value > 0 , "Please add some good amount");

     require(poolStarted, "Pool has not been started yet");
     require(block.timestamp <= startTime.add(12 hours),"Its more than 12 hours since pool started" ); // Can stake upto 12 hours from start pool.
     require(WOLFY.balanceOf(msg.sender) >= wolfyLimit, "You must possess 20K WOLFY Tokens to Participate");

     if(_isLowRisk){
      require(depositLowRiskETH.add(msg.value) <= (_ethBalanceRiskPool[owner()][_isLowRisk]).mul(6), "Target 6X reaching");   
      require(msg.value <= (_ethBalanceRiskPool[owner()][_isLowRisk]).mul(6), "Exceeding low risk ETH limit");

      depositLowRiskETH += msg.value;

     } else {

      require(depositHighRiskETH.add(msg.value) <= (_ethBalanceRiskPool[owner()][_isLowRisk]).mul(3), "Target 3X reaching");
      require(msg.value <= (_ethBalanceRiskPool[owner()][_isLowRisk]).mul(3), "Exceeding high risk ETH limit");
     
        depositHighRiskETH += msg.value;

     }

    //   _isLowRisk == true ? _lowRiskETHUsers.push(msg.sender): _highRiskETHUsers.push(msg.sender); 

     _isLowRisk == true ? storeUsers(msg.sender, _lowRiskETHUsers): storeUsers(msg.sender, _highRiskETHUsers); 

     _ethBalanceRiskPool[msg.sender][_isLowRisk] = _ethBalanceRiskPool[msg.sender][_isLowRisk].add(msg.value);          //______| Record of ETH deposit |______

    }


    // Add WOLFY liquidity
    function addWolfy(uint256 amount, bool _isLowRisk) public onlyOwner { 
        _balancesRiskPool[msg.sender][_isLowRisk] = _balancesRiskPool[msg.sender][_isLowRisk].add(amount);
         WOLFY.safeTransferFrom(msg.sender, address(this), amount);
         
    }

    // Add ETH liquidity 
    function addEth(bool _isLowRisk) public payable onlyOwner { 
        _ethBalanceRiskPool[owner()][_isLowRisk] = _ethBalanceRiskPool[msg.sender][_isLowRisk].add(msg.value); 
        
    }

    function raisePercent(uint256 _v1, uint256 _v2) internal pure returns (uint256, bool) {
        if(_v1 > _v2){
          
          return (_v1.sub(_v2).mul(1000) == 0 ? 0 : (_v1.sub(_v2).mul(1000).div(_v1)), false); //___| Deprecation over time |______
      
       } else{

          return (_v2.sub(_v1).mul(1000) == 0 ? 0 : (_v2.sub(_v1).mul(1000).div(_v1)), true); //___| Increase over time |____
       } 
    }

    function checkPerformance(uint256 _inputDeFi, uint256 _inputSNP, bool _polarityDeFi, bool _polaritySnp) public {
        
        if(!_polarityDeFi && !_polaritySnp){
        
            if(_inputDeFi > _inputSNP){
                winnerScale = _inputDeFi.mul(10).div(_inputSNP);
                who = false;
                thorCheck = 1;

            } else {
                winnerScale = _inputSNP.mul(10).div(_inputDeFi);
                who = true;
                thorCheck = 2;
            }

        // DeFi = Positive |=====| SNP = Negative
        } else if(_polarityDeFi && !_polaritySnp){  

            winnerScale = _inputDeFi.add(_inputSNP).mul(10).div(_inputDeFi);
            who = true;
             thorCheck = 3;

        // DeFi = Negative |=====| SNP = Positive 
        }else if(!_polarityDeFi && _polaritySnp){
          
            winnerScale = _inputDeFi.add(_inputSNP).mul(10).div(_inputSNP);
            who = false;
  
            thorCheck = 4;
       //======================================================================
        }else if(_polarityDeFi && _polaritySnp){
            
            if(_inputDeFi > _inputSNP){
               
                winnerScale = _inputDeFi.mul(10).div(_inputSNP);
                who = true;
                thorCheck = 5;

                inputDefi111 = _inputDeFi;
                inputSNP111 = _inputSNP;

            //=======================================

            } else {
        
                winnerScale = _inputSNP.mul(10).div(_inputDeFi);
                who = false;
                thorCheck = 6;

                inputDefi111 = _inputDeFi;
                inputSNP111 = _inputSNP;
            }
            
        } else {

            winnerScale = 0;
            who = false;
            thorCheck = 7;
        }

    }

    function rewardManager(uint256 _factor, bool _champ) internal {
       
       runCount += 1 ;

       // factor >= 1.5x | Low Risk Winning
       if(_factor >= 15 && _champ == true){

        // ########## LR ########## WOLFY ########## PROFIT #############
        // WOLFY : Tokens increased by 12% of all WOLFY stakers.
        for(uint i = 0 ; i <= _lowRiskWolfyUsers.length ; i++){
             
             // Reduce from Admin low risk wallet
            _balancesRiskPool[owner()][true] -= _balancesRiskPool[_lowRiskWolfyUsers[i]][true].mul(120).div(1000);

            // Maintaining Profits | Token 
            _profitWOLFYStakers[_lowRiskWolfyUsers[i]][true] += _balancesRiskPool[_lowRiskWolfyUsers[i]][true].mul(120).div(1000);

             // Increase their balances
            _balancesRiskPool[_lowRiskWolfyUsers[i]][true] += _balancesRiskPool[_lowRiskWolfyUsers[i]][true].mul(120).div(1000);

      
            // // address + isLowRisk + isWolfy + count ==> bool
            previousResults[_lowRiskWolfyUsers[i]][true][true][runCount]= true;
        
        }
          
          
          // ######## LR ##########  ETH  ######## PROFIT ###############
          // ETH : ETH increased by 12% of all WOLFY stakers.
        for(uint i = 0 ; i <= _lowRiskETHUsers.length ; i++){
             
             // Reduce from Admin low risk wallet
            _ethBalanceRiskPool[owner()][true] -= _ethBalanceRiskPool[_lowRiskETHUsers[i]][true].mul(120).div(1000);

            // Maintaining Profits | Token 
            _profitETHStakers[_lowRiskETHUsers[i]][true] += _ethBalanceRiskPool[_lowRiskETHUsers[i]][true].mul(120).div(1000);

             // Increase their balances
            _ethBalanceRiskPool[_lowRiskETHUsers[i]][true] += _ethBalanceRiskPool[_lowRiskETHUsers[i]][true].mul(120).div(1000);

              // // address + isLowRisk + isWolfy + count ==> bool
              previousResults[_lowRiskETHUsers[i]][true][false][runCount] = true;
       
        }
       
        
       } else {

          // ######## LR ############ WOLFY ############ LOSS ###########
         // Tokens decreased by 15% for all stakers.
         for(uint i = 0 ; i < _lowRiskWolfyUsers.length ; i++){

             // Increase for Admin wallet
            _balancesRiskPool[owner()][true] += _balancesRiskPool[_lowRiskWolfyUsers[i]][true].mul(150).div(1000);

             // Reducing stakers balance
            _balancesRiskPool[_lowRiskWolfyUsers[i]][true] -= _balancesRiskPool[_lowRiskWolfyUsers[i]][true].mul(150).div(1000);
       
             // Storing everytime staker is in loss | Token | ETH
            _lossWOLFYStakers[_lowRiskWolfyUsers[i]][true] += _balancesRiskPool[_lowRiskWolfyUsers[i]][true].mul(150).div(1000);
       
             // // address + isLowRisk + isWolfy + count ==> bool
             previousResults[_lowRiskWolfyUsers[i]][true][true][runCount] = false;
        
        }
         
         // ######### LR ########### ETH ############ LOSS ###########
         // ETH decreased by 15% for all stakers.
         for(uint i = 0 ; i < _lowRiskETHUsers.length ; i++){

             // Increase for Admin wallet
            _ethBalanceRiskPool[owner()][true] += _ethBalanceRiskPool[_lowRiskETHUsers[i]][true].mul(150).div(1000);

              // Reducing stakers balance
            _ethBalanceRiskPool[_lowRiskETHUsers[i]][true] -= _ethBalanceRiskPool[_lowRiskETHUsers[i]][true].mul(150).div(1000);
       
             // Storing everytime staker is in loss
            _lossETHStakers[_lowRiskETHUsers[i]][true] += _ethBalanceRiskPool[_lowRiskETHUsers[i]][true].mul(150).div(1000);
       
             //// address + isLowRisk + isWolfy + count ==> bool
             previousResults[_lowRiskETHUsers[i]][true][false][runCount] = false;
        
        }
       
       }

    
        // factor >= 5x | High Risk Winning
        if(_factor >= 50 && _champ == true){
          
          // ######### HR ########### WOLFY ############ PROFIT ###########
          // Tokens increased by 30% of all stakers.
          for(uint i = 0 ; i < _highRiskWolfyUsers.length ; i++){

             // ***** Reduce from Admin wallet *****
            _balancesRiskPool[owner()][false] -= _balancesRiskPool[_highRiskWolfyUsers[i]][false].mul(300).div(1000);
              
              // Adding profits to stakers
             _balancesRiskPool[_highRiskWolfyUsers[i]][false] += _balancesRiskPool[_highRiskWolfyUsers[i]][false].mul(300).div(1000);
        
             // Storing everytime staker is winning | Token | ETH
            _profitWOLFYStakers[_highRiskWolfyUsers[i]][false] += _balancesRiskPool[_highRiskWolfyUsers[i]][false].mul(300).div(1000);
    
             // address + isLowRisk + isWolfy + count ==> bool
             previousResults[_highRiskWolfyUsers[i]][false][true][runCount] = true;
           
        }

        // ######### HR ########### ETH ############ PROFIT ###########
        for(uint i = 0 ; i < _highRiskETHUsers.length ; i++){

             // ***** Reduce from Admin wallet *****
            _ethBalanceRiskPool[owner()][false] -= _ethBalanceRiskPool[_highRiskETHUsers[i]][false].mul(300).div(1000);
             
             // Adding profits to staker balance
            _ethBalanceRiskPool[_highRiskETHUsers[i]][false] += _ethBalanceRiskPool[_highRiskETHUsers[i]][false].mul(300).div(1000);
        
             // Storing everytime staker is winning | Token | ETH
            _profitETHStakers[_highRiskETHUsers[i]][false] += _ethBalanceRiskPool[_highRiskETHUsers[i]][false].mul(300).div(1000);
    
             // address + isLowRisk + isWolfy + count ==> bool
             previousResults[_highRiskETHUsers[i]][true][false][runCount] = true;
        }

        // factor < 5x | High Risk Losing
        } else {

            // ######### HR ########### WOLFY ############ LOSS ###########
            // Tokens decreased by 35% of all stakers.
            for(uint i = 0 ; i < _highRiskWolfyUsers.length ; i++){

             // ***** Reduce from Admin wallet *****
            _balancesRiskPool[owner()][false] += _balancesRiskPool[_highRiskWolfyUsers[i]][false].mul(350).div(1000);
              
              // Adding profits to stakers
             _balancesRiskPool[_highRiskWolfyUsers[i]][false] -= _balancesRiskPool[_highRiskWolfyUsers[i]][false].mul(350).div(1000);
        
             // Storing everytime staker is losing | Token | 
            _lossWOLFYStakers[_highRiskWolfyUsers[i]][false] += _balancesRiskPool[_highRiskWolfyUsers[i]][false].mul(350).div(1000);
    
              // address + isLowRisk + isWolfy + count ==> bool
             previousResults[_highRiskWolfyUsers[i]][false][true][runCount] = false;
       
        }

         // ######### HR ########### ETH ############ LOSS ###########
         // Tokens and ETH decreased by 35% of all stakers.
          for(uint i = 0 ; i < _highRiskETHUsers.length ; i++){

             // ########### Increase for Admin wallet #############
            _ethBalanceRiskPool[owner()][false] += _ethBalanceRiskPool[_highRiskETHUsers[i]][false].mul(350).div(1000);

            // Reducing from staker balances
            _ethBalanceRiskPool[_highRiskETHUsers[i]][false] -= _ethBalanceRiskPool[_highRiskETHUsers[i]][false].mul(350).div(1000);
       
            // _lossWOLFYStakers _lossETHStakers _profitWOLFYStakers _profitETHStakers
            _lossETHStakers[_highRiskETHUsers[i]][false] += _ethBalanceRiskPool[_highRiskETHUsers[i]][false].mul(350).div(1000);

              // address + isLowRisk + isWolfy + count ==> bool
            previousResults[_highRiskETHUsers[i]][false][false][runCount] = false;
        
        }

        }
    }

    function startPool(uint256 _defiPulse, uint256 _snp500) public onlyOwner { 
        require(!poolStarted, "Previous pool not finalized yet!!");
        require( _ethBalanceRiskPool[msg.sender][true] > 0 ,"Please add ETH liquidity");
        require( _balancesRiskPool[owner()][true] > 0 ,"Please add WOLFY liquidity");

        defiPulse = _defiPulse;
        snp500 = _snp500;
       
        startTime = block.timestamp;
        poolStarted = true;

    }

    // Value of DeFi and SNP after 7 days
    function stopPool(uint256 _defiPulse, uint256 _snp500) public onlyOwner { 
        require(block.timestamp > startTime.add(1 minutes), "Can stop once 7 days are finished"); //### 7 days #### Mainnet
        require(poolStarted, "Pool not started yet!!");
      
        
        (netDefi, A) = raisePercent(defiPulse,_defiPulse);     //___either positive or negative
        (netSNP, B)  = raisePercent(snp500,_snp500);           //___either positive or negative

        checkPerformance(netDefi, netSNP, A, B);

        rewardManager(winnerScale, who);
        poolStarted = false;
       
    }

    function getProfits(bool _isWolfy, bool _isLowRisk) public view returns (uint256){
      if(_isWolfy){
        return _profitWOLFYStakers[msg.sender][_isLowRisk];
      }else{
        return _profitETHStakers[msg.sender][_isLowRisk];
      }

    }

    function getLosses(bool _isWolfy, bool _isLowRisk) public view returns (uint256){
      if(_isWolfy){
        return _lossWOLFYStakers[msg.sender][_isLowRisk];
      }else{
        return _lossETHStakers[msg.sender][_isLowRisk];
      }

    }

     //______| Total ETH liquidity low Risk |_______
    function getLiquidityWolfy(address _who, bool _isLowRisk) public view returns (uint256){
       return _balancesRiskPool[_who][_isLowRisk];
    }

     //______| Total ETH liquidity low Risk |_______
    function getLiquidityETH(address _who, bool _isLowRisk) public view returns (uint256){
       return _ethBalanceRiskPool[_who][_isLowRisk];
    }

    //______| Net earning WOLFY |____|Profits must higher than loss|___
    function netEarning(bool _isWolfy, bool _isLowRisk) public view returns (uint256){
       
         if(getProfits(_isWolfy, _isLowRisk).sub(getLosses(_isWolfy, _isLowRisk)) > 0){
           return getProfits(_isWolfy, _isLowRisk).sub(getLosses(_isWolfy, _isLowRisk));
       } else {
            return 0;
       }

    }

 // updateLimitVariables
    function updateWolfyLimitVariables() internal{
        depositLowRiskWolfy = 0;
        depositHighRiskWolfy = 0;

        for(uint i = 0; i < _lowRiskWolfyUsers.length ; i++){
           depositLowRiskWolfy += _balancesRiskPool[_lowRiskWolfyUsers[i]][true];
        }

        for(uint i = 0; i < _highRiskWolfyUsers.length ; i++){
           depositHighRiskWolfy += _balancesRiskPool[_lowRiskWolfyUsers[i]][false];
        }   
    }

    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%% REMOVE THIS METHOD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function prakash() public payable{
      dummyCheck = msg.value;
    }
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function updateETHLimitVariables() internal{
        depositLowRiskETH = 0;
        depositHighRiskETH = 0;

        for(uint i = 0; i < _lowRiskETHUsers.length ; i++){
           depositLowRiskETH += _balancesRiskPool[_lowRiskETHUsers[i]][true];
        }

        for(uint i = 0; i < _highRiskETHUsers.length ; i++){
           depositHighRiskETH += _balancesRiskPool[_highRiskETHUsers[i]][false];
        }
    }
   
   
    //TODO : Not allowed if pools are running
    function withdrawToken(uint256 _amount, bool _isLowRisk) public {
      require(!poolStarted, "Cannot withdraw Wolfy when pool is running");
      require(msg.sender != owner(), "Owner cannot withdraw tokens");
      require(_amount <= _balancesRiskPool[msg.sender][_isLowRisk], "Insufficient Tokens in your wallet");
      _balancesRiskPool[msg.sender][_isLowRisk] = _balancesRiskPool[msg.sender][_isLowRisk].sub(_amount);
      WOLFY.safeTransfer(msg.sender, _amount);

      if(_isLowRisk){
        depositLowRiskWolfy -= _amount;
      } else{
        depositHighRiskWolfy -= _amount;
      }
      
    }


    function withdrawETH(uint256 _ether, bool _isLowRisk) public {
      require(!poolStarted, "Cannot withdraw ETH when pool is running");
      require(msg.sender != owner(), "Owner cannot withdraw ETH");
      require(_ether <= _ethBalanceRiskPool[msg.sender][_isLowRisk], "Insufficient Tokens in your wallet");
      
      _ethBalanceRiskPool[msg.sender][_isLowRisk] = _ethBalanceRiskPool[msg.sender][_isLowRisk].sub(_ether);
      payable(msg.sender).transfer(_ether); 
       
      if(_isLowRisk){
        depositLowRiskETH -= _ether;
      } else{
        depositHighRiskETH -= _ether;
      }
      
    }
}