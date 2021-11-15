// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import './libraries/TransferHelper.sol';
import './modules/Initializable.sol';
import './modules/ReentrancyGuard.sol';
import './modules/Pausable.sol';
import './modules/UserTokenLimit.sol';
import './interfaces/IWETH.sol';
import "./interfaces/IERC20.sol";
import './interfaces/ISwitchTreasury.sol';
import './interfaces/ISwitchSigner.sol';
import './interfaces/ISwitchTicketFactory.sol';
import './interfaces/IRewardToken.sol';

contract SwitchAcross is UserTokenLimit, Pausable, ReentrancyGuard, Initializable{
    using SafeMath for uint;
    address public weth;
    address public treasury;
    address public signer;
    address public ticketFactory;
    uint public constant DENOMINATOR = 10000;
    address public feeWallet;
    address public gasWallet;
    
    uint public totalGas;
    uint public totalFee;
    //(token => total fee)
    mapping (address => uint) public totalSlideOfToken;
    

    uint public collectedAccuGas;
    uint public collectedAccuFee;
    //(token => total fee)
    mapping (address => uint) public collectedAccuSlideOfToken;

    //(chainIdOut, tokenOut, tokenIn)
    mapping (uint => mapping (address => address)) public tokenMap;

    struct TargetToken {
        address tokenOut;
        uint decimals;
        uint fee;
        uint slideMin;
        uint slideMax;
        uint slidePre;
        uint limit;
    }

    //(source token, chainIdOut)
    mapping (address => mapping (uint => TargetToken)) public targetTokens;

    struct SourceToken {
        uint decimals;
        bool enabledIn;
        bool enabledOut;
        uint rewardRate; // its denominator is 1e18
        bool added;
    }
    //key: (token address)
    mapping (address => SourceToken) public sourceTokens;

    address[] public tokens;
    uint public inSn;
    uint public outSn;

    //(chainId => fee)
    mapping (uint => uint) public chainFees;
    uint public baseFee;
    uint public mode;     // supported mode(0: none, 1:self, 2:other)

    // from chainId=>from inSn=> outSn
    mapping (uint => mapping (uint => uint)) public outOrders;
    address public rewardToken;
    mapping (address => uint) public rewards;

    event ChianFeeChanged(uint indexed chainId, uint indexed fee);
    event TokenMapChanged(address indexed tokenIn, address indexed tokenOut, uint indexed chainIdOut);
    event TransferIned(
        uint indexed sn,
        address user,
        uint chainId,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOut,
        uint mode,
        uint slide,
        uint fee
    );
    event TransferOuted(
        uint indexed sn,
        address user,
        uint chainId,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOut,
        uint mode,
        uint slide,
        uint inSn
    );

    event ConfigureChanged(address indexed _user, address _treasury, address _signer, address _ticketFactory, uint _mode);
    event FeeWalletChanged(address indexed _user, address _old, address _new);
    event GasWalletChanged(address indexed _user, address _old, address _new);
    event BaseFeeChanged(address indexed _user, uint _old, uint _new);
    event TokenEnableChanged(address indexed _tokenIn, bool _enabledIn, bool _enabledOut);
    event RewardRateChanged(address indexed _tokenIn, uint _old, uint _new);

    function initialize(address _weth, address _rewardToken) external initializer {
        require(_weth != address(0), 'SwitchAcross: ZERO_ADDRESS');
        owner = msg.sender;
        feeWallet = msg.sender;
        gasWallet = msg.sender;
        weth = _weth;
        rewardToken = _rewardToken;
        inSn = 1;
        outSn = 1;
    }


    modifier onlyFeeWallet() {
        require(msg.sender == owner || msg.sender == feeWallet, 'SwitchAcross: FEE_FORBIDDEN');
        _;
    }

    modifier onlyGasWallet() {
        require(msg.sender == owner || msg.sender == gasWallet, 'SwitchAcross: GAS_FORBIDDEN');
        _;
    }
    
    receive() external payable {
        assert(msg.sender == weth);
    }

    function pause() external onlyManager whenNotPaused {
        _pause();
    }

    function unpause() external onlyManager whenPaused {
        _unpause();
    }

    function configure(address _treasury, address _signer, address _ticketFactory, uint _mode, uint _baseFee) external onlyDev {
        require(_treasury != address(0) && _signer != address(0) && _ticketFactory != address(0), 'SwitchAcross: ZERO_ADDRESS');
        emit ConfigureChanged(msg.sender, _treasury, _signer, _ticketFactory, _mode);
        emit BaseFeeChanged(msg.sender, baseFee, _baseFee);
        treasury = _treasury;
        signer = _signer;
        ticketFactory = _ticketFactory;
        mode = _mode;
        baseFee = _baseFee;
    }
    
    function countToken() public view returns (uint) {
        return tokens.length;
    }

    function changeFeeWallet(address _user) external onlyFeeWallet {
        require(feeWallet != _user, 'SwitchAcross: NO_CHANGE');
        emit FeeWalletChanged(msg.sender, feeWallet, _user);
        feeWallet = _user;
    }

    function changeGasWallet(address _user) external onlyGasWallet {
        require(gasWallet != _user, 'SwitchAcross: NO_CHANGE');
        emit GasWalletChanged(msg.sender, gasWallet, _user);
        gasWallet = _user;
    }

    function checkMode(uint _mode) public view returns (bool) {
        return (mode & _mode) == _mode;
    }

    function setBaseFee(uint _baseFee) external onlyDev {
        emit BaseFeeChanged(msg.sender, baseFee, _baseFee);
        baseFee = _baseFee;
    }

    function setTokenMap(address _tokenIn, address _tokenOut, uint _chainIdOut, uint _tokenOutDecimals, uint _tokenOutLimit, uint _fee, uint _slideMin, uint _slideMax, uint _slidePre, uint _rewardRate) public onlyDev {
        require(_slideMax >= _slideMin, "SwitchAcross: INVALID_PARAM");
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        tokenMap[_chainIdOut][_tokenOut] = _tokenIn;

        SourceToken storage sourceToken = sourceTokens[_tokenIn];
        if(sourceToken.added == false) {
            tokens.push(_tokenIn);
            sourceToken.added = true;
            sourceToken.enabledIn = true;
            sourceToken.enabledOut = true;
            sourceToken.decimals = IERC20(_tokenIn).decimals();
        }
        
        if(sourceToken.rewardRate != _rewardRate) sourceToken.rewardRate = _rewardRate;

        TargetToken storage targetToken = targetTokens[_tokenIn][_chainIdOut];
        if(targetToken.tokenOut == address(0) && targetToken.decimals != _tokenOutDecimals) targetToken.decimals = _tokenOutDecimals;
        if(targetToken.tokenOut != _tokenOut) targetToken.tokenOut = _tokenOut;
        if(targetToken.fee != _fee) targetToken.fee = _fee;
        if(targetToken.limit != _tokenOutLimit) targetToken.limit = _tokenOutLimit;
        if(targetToken.slideMin != _slideMin) targetToken.slideMin = _slideMin;
        if(targetToken.slideMax != _slideMax) targetToken.slideMax = _slideMax;
        if(targetToken.slidePre != _slidePre) targetToken.slidePre = _slidePre;

        emit TokenMapChanged(_tokenIn, _tokenOut, _chainIdOut);
    }

    function setTokenMaps(address[] memory _tokenIn, address[] memory _tokenOut, uint[] memory _chainIdOut, uint[] memory _tokenOutDecimals, uint[] memory _tokenOutLimit, uint[] memory _fee, uint[] memory _slideMin, uint[] memory _slideMax, uint[] memory _slidePre, uint[] memory _rewardRate) external onlyDev {
        require(
            _tokenIn.length == _tokenOut.length 
            && _tokenOut.length == _chainIdOut.length 
            && _chainIdOut.length == _tokenOutDecimals.length 
            && _tokenOutDecimals.length == _tokenOutLimit.length 
            && _tokenOutLimit.length == _fee.length 
            && _fee.length == _slideMin.length 
            && _slideMin.length == _slideMax.length 
            && _slideMax.length == _slidePre.length 
            && _slidePre.length == _rewardRate.length 
            , "SwitchAcross: INVALID_PARAM"
        );
        for (uint i; i < _tokenIn.length; i++) {
            setTokenMap(_tokenIn[i], _tokenOut[i], _chainIdOut[i], _tokenOutDecimals[i], _tokenOutLimit[i], _fee[i], _slideMin[i], _slideMax[i], _slidePre[i], _rewardRate[i]);
        }
    }

    function setTokenEnable(address _tokenIn, bool _enabledIn, bool _enabledOut) public onlyDev {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        SourceToken storage sourceToken = sourceTokens[_tokenIn];
        if(sourceToken.enabledIn != _enabledIn) sourceToken.enabledIn = _enabledIn;
        if(sourceToken.enabledOut != _enabledOut) sourceToken.enabledOut = _enabledOut;
        emit TokenEnableChanged(_tokenIn, _enabledIn, _enabledOut);
    }

    function setTokenEnables(address[] memory _tokenIn, bool[] memory _enabledIn, bool[] memory _enabledOut) external onlyDev {
        require(
            _tokenIn.length == _enabledIn.length 
            && _enabledIn.length == _enabledOut.length 
            , "SwitchAcross: INVALID_PARAM"
        );
        for (uint i; i < _tokenIn.length; i++) {
            setTokenEnable(_tokenIn[i], _enabledIn[i], _enabledOut[i]);
        }
    }

    function setRewardRate(address _tokenIn, uint _rewardRate) public onlyDev {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        SourceToken storage sourceToken = sourceTokens[_tokenIn];
        emit RewardRateChanged(_tokenIn, sourceToken.rewardRate, _rewardRate);
        sourceToken.rewardRate = _rewardRate;
    }

    function setRewardRates(address[] memory _tokenIn, uint[] memory _rewardRate) external onlyDev {
        require(
            _tokenIn.length == _rewardRate.length 
            , "SwitchAcross: INVALID_PARAM"
        );
        for (uint i; i < _tokenIn.length; i++) {
            setRewardRate(_tokenIn[i], _rewardRate[i]);
        }
    }

    function setChainFee(uint _chainId, uint _fee) public onlyDev {
        chainFees[_chainId] = _fee;
        emit ChianFeeChanged(_chainId, _fee);
    }

    function setChainFees(uint[] memory _chainId, uint[] memory _fee) external onlyDev {
        require(_chainId.length == _fee.length, "SwitchAcross: INVALID_PARAM");
        for (uint i; i < _chainId.length; i++) {
            setChainFee(_chainId[i], _fee[i]);
        }
    }

    function collectGasFee() external onlyGasWallet nonReentrant returns (uint amount) {
        require(totalGas > 0, "SwitchAcross: NO_GAS_FEE");
        amount = totalGas;
        collectedAccuGas += amount;
        ISwitchTreasury(treasury).withdraw(true, gasWallet, weth, amount);
        totalGas = 0;
    }

    function collectFee() external onlyFeeWallet nonReentrant returns (uint amount) {
        require(totalFee > 0, "SwitchAcross: NO_FEE");
        amount = totalFee;
        collectedAccuFee += amount;
        ISwitchTreasury(treasury).withdraw(true, feeWallet, weth, amount);
        totalFee = 0;
    }

    function collectSlide(address _token) external onlyFeeWallet nonReentrant returns (uint amount) {
        amount = totalSlideOfToken[_token];
        require(amount > 0, "SwitchAcross: NO_SLIDE");
        collectedAccuSlideOfToken[_token] += amount;
        ISwitchTreasury(treasury).withdraw(false, feeWallet, _token, amount);
        totalSlideOfToken[_token] = 0;
    }

    function getSlide(address _tokenIn, uint _toChainId, uint amountIn) public view returns (uint) {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        TargetToken memory targetToken = targetTokens[_tokenIn][_toChainId];
        uint amount = amountIn.mul(targetToken.slidePre).div(DENOMINATOR);
        if(amount > targetToken.slideMax) {
            amount = targetToken.slideMax;
        }
        if(amount < targetToken.slideMin) {
            amount = targetToken.slideMin;
        }
        return amount;
    }

    function getAmountIn(address _tokenIn, uint _toChainId, uint _amountOut) public view returns (uint amount, uint slide) {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        TargetToken memory targetToken = targetTokens[_tokenIn][_toChainId];
        SourceToken memory sourceToken = sourceTokens[_tokenIn];
        amount = _amountOut;
        if(sourceToken.decimals < targetToken.decimals) {
            amount = amount / 10** (targetToken.decimals - sourceToken.decimals);
        } else if(sourceToken.decimals > targetToken.decimals) {
            amount = amount * 10** (sourceToken.decimals - targetToken.decimals);
        }
        slide = getSlide(_tokenIn, _toChainId, amount);
        amount = amount.add(slide);
    }

    function getAmountOut(address _tokenIn, uint _toChainId, uint _amountIn) public view returns (uint amount, uint slide) {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        TargetToken memory targetToken = targetTokens[_tokenIn][_toChainId];
        SourceToken memory sourceToken = sourceTokens[_tokenIn];
        slide = getSlide(_tokenIn, _toChainId, _amountIn);
        if(_amountIn <= slide) {
            slide = _amountIn;
        }

        amount = _amountIn.sub(slide);
        if(sourceToken.decimals < targetToken.decimals) {
            amount = amount * 10** (targetToken.decimals - sourceToken.decimals);
            slide = slide * 10** (targetToken.decimals - sourceToken.decimals);
        } else if(sourceToken.decimals > targetToken.decimals) {
            amount = amount / 10** (sourceToken.decimals - targetToken.decimals);
            slide = slide / 10** (sourceToken.decimals - targetToken.decimals);
        }
        return (amount, slide);
    }

    function getOutInfo(address _tokenIn, uint _toChainId, uint _amountIn, uint _mode) public view returns (uint amountIn, address tokenOut, uint amountOut, uint slide, uint fee, uint inLimit, uint outLimit) {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        TargetToken memory targetToken = targetTokens[_tokenIn][_toChainId];
        tokenOut = targetToken.tokenOut;
        fee = baseFee.add(targetToken.fee);
        // mode != 1
        if(_mode != 1) {
            fee = fee.add(chainFees[_toChainId]);
        }
        amountIn = _amountIn;
        (uint _amountOut, uint _slide) = getAmountOut(_tokenIn, _toChainId, _amountIn);
        amountOut = _amountOut;
        slide = _slide;
        inLimit = getUserLimit(msg.sender, _tokenIn, _amountIn);
        outLimit = targetToken.limit;
    }

    function getInInfo(address _tokenIn, uint _toChainId, uint _amountOut, uint _mode) public view returns (uint amountIn, address tokenOut, uint amountOut, uint slide, uint fee, uint inLimit, uint outLimit) {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        (amountIn,) = getAmountIn(_tokenIn, _toChainId, _amountOut);
        return getOutInfo(_tokenIn, _toChainId, amountIn, _mode);
    }

    function isTicket(address _token) public view returns (bool) {
        return ISwitchTicketFactory(ticketFactory).isTicket(_token);
    }
    
    /**
        transferIn 
        address _to
        address[] _tokens, 0:_tokenIn, 1:_tokenOut
        uint[] _values, 0:_amountIn, 1:_amountOut, 2:_toChainId, 3:_mode
     */
    function transferIn(address _to, address[] memory _tokens, uint[] memory _values) external payable whenNotPaused nonReentrant  {
        require(_values[0] > 0 && _values[1] > 0, "SwitchAcross: ZERO_AMOUNT");
        require(checkMode(_values[3]), "SwitchAcross: INVALID_MODE");
        require(ISwitchSigner(signer).checkUser(_to), 'SwitchAcross: DENNY');
        bool isETH;
        if(_tokens[0] == address(0)) {
            isETH = true;
            _tokens[0] = weth;
        }
        SourceToken storage sourceToken = sourceTokens[_tokens[0]];
        require(sourceToken.enabledIn, "SwitchAcross: TOKEN_DISABLED");
        TargetToken memory targetToken = targetTokens[_tokens[0]][_values[2]];
        require(_tokens[1] == targetToken.tokenOut, "SwitchAcross: INVALID_TOKENOUT");
        require(getUserLimit(msg.sender, _tokens[0],  _values[0]) >= _values[0], "SwitchAcross: USER_LIMIT_OVERFLOW");
        (uint amountOut, uint slide) = getAmountOut(_tokens[0], _values[2], _values[0]);
        require(_values[1] == amountOut, "SwitchAcross: AMOUNTOUT_INCORRECT");
        require(targetToken.limit >= _values[1], "SwitchAcross: AMOUNTOUT_OVERFLOW");

        uint fee = baseFee.add(targetToken.fee);
        totalFee = totalFee.add(fee);
        uint gas = fee;
        // mode != 1
        if(_values[3] != 1) {
            gas = gas.add(chainFees[_values[2]]);
            totalGas = totalGas.add(chainFees[_values[2]]);
        }
        { // avoid Stack too deep, try removing local variables.
        uint depositAmount;
        if(isETH) {
            require(msg.value >= gas.add(_values[0]), "SwitchAcross: INSUFFICIENT_GAS_TOKEN_VALUE");
            _values[0] = msg.value.sub(gas);
            depositAmount = ISwitchTreasury(treasury).deposit{value: _values[0]}(msg.sender, address(0), _values[0]);
        } else {
            require(msg.value >= gas, "SwitchAcross: INSUFFICIENT_GAS_VALUE");
            if(isTicket(_tokens[0])) {
                depositAmount = ISwitchTreasury(treasury).burn(_tokens[0], msg.sender, _values[0]);
            } else {
                depositAmount = ISwitchTreasury(treasury).deposit(msg.sender, _tokens[0], _values[0]);
            }
        }
        require(depositAmount == _values[0], "SwitchAcross: TREASURY_DEPOSIT_FAIL");
        }

        _updateUserTokenLimit(_tokens[0],  _values[0]);

        emit TransferIned(inSn, _to, _values[2], _tokens[0], _tokens[1], _values[0], _values[1], _values[3], slide, fee);
        inSn = inSn.add(1);
    }

    function getDataHash(address _from, address[] memory _tokens, uint[] memory _values) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_from, _values[2], _tokens[0], _tokens[1], _values[0], _values[1], _values[3], _values[4], _values[5], msg.sender));
    }

    /**
        transferOut 
        address _from
        address[] _tokens, 0:_tokenIn, 1:_tokenOut
        uint[] _values, 0:_amountIn, 1:_amountOut, 2:from chainId, 3:_mode, 4:slide, 5:from inSn
        bytes calldata _signature
     */
    function transferOut(address _from, address[] memory _tokens, uint[] memory _values, bytes[] memory _signatures) external whenNotPaused nonReentrant  {
        SourceToken storage sourceToken = sourceTokens[_tokens[1]];
        require(sourceToken.enabledOut, "SwitchAcross: TOKEN_DISABLED");
        require(outOrders[_values[2]][_values[5]] == 0, "SwitchAcross: ALREADY_EXECUTED");
   
        require(_values[1] > 0, "SwitchAcross: NOTHING_TO_WITHDRAW");
        require(queryWithdraw(_tokens[1], _values[1]) >= _values[1], 'SwitchAcross: INSUFFICIENT_BALANCE');
        
        bytes32 message = getDataHash(_from, _tokens, _values);
        require(signer != address(0), 'SwitchAcross: NO_SIGNER');
        require(ISwitchSigner(signer).mverify(_values[3], _from, msg.sender, message, _signatures), "SwitchAcross: INVALID_SIGNATURE");

        if(isTicket(_tokens[1])) {
            ISwitchTreasury(treasury).mint(_tokens[1], _from, _values[1]);
            if(_values[4] > 0) {
                address _token = ISwitchTicketFactory(ticketFactory).getTokenMap(_tokens[1]);
                require(_token != address(0), 'SwitchAcross: INVALID_TICKET');
                totalSlideOfToken[_token] = totalSlideOfToken[_token].add(_values[4]);
            }
        } else {
            bool isETH = false;
            if(_tokens[1] == weth) {
                isETH = true;
            }
            ISwitchTreasury(treasury).withdraw(isETH, _from, _tokens[1], _values[1]);
            totalSlideOfToken[_tokens[1]] = totalSlideOfToken[_tokens[1]].add(_values[4]);
        }
     
        outOrders[_values[2]][_values[5]] = outSn;

        rewards[_from] = rewards[_from].add(computeReward(_tokens[1], _values[1]));
 
        emit TransferOuted(outSn, _from, _values[2], _tokens[0], _tokens[1], _values[0], _values[1], _values[3], _values[4], _values[5]);
        outSn = outSn.add(1);
    }

    function computeReward(address token, uint amount) public view returns (uint) {
        SourceToken memory sourceToken = sourceTokens[token];
        if(sourceToken.decimals < 18) {
            amount = amount.mul(10**(18-sourceToken.decimals));
        } else {
            amount = amount.div(10**(sourceToken.decimals-18));
        }
        uint reward = amount.mul(sourceToken.rewardRate).div(1e18);
        if(reward > IRewardToken(rewardToken).take()) {
            reward = 0;
        }
        return reward;
    }

    function queryWithdraw(address _token, uint _value) public view returns (uint) {
        if(!isTicket(_token)) {
            uint amount = ISwitchTreasury(treasury).queryWithdraw(address(this), _token);
            if(amount < _value) {
                _value = amount;
            }
        }
        return _value;
    }

    function claimReward() external nonReentrant returns (uint) {
        uint reward = rewards[msg.sender];
        require(reward > 0, 'SwitchAcross: ZERO');
        require(reward <= IRewardToken(rewardToken).take(), 'SwitchAcross: STOP');
        rewards[msg.sender] = 0;
        IRewardToken(rewardToken).mint(msg.sender, reward);
        return reward;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused();

    bool private _paused;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() virtual {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import '../libraries/SafeMath.sol';
import '../modules/Configable.sol';

contract UserTokenLimit is Configable {
    using SafeMath for uint;

    struct TokenLimit {
        bool enabled;
        uint blocks;
        uint amount;
    }
    //key:(token)
    mapping(address => TokenLimit) public tokenLimits;

    struct UserLimit {
        uint lastBlock;
        uint consumption;
    }
    //key:(white user, token)
    mapping(address => mapping(address => UserLimit)) public userLimits;

    function setTokenLimit(address _token, bool _enabled, uint _blocks, uint _amount) public onlyManager {
        TokenLimit storage limit = tokenLimits[_token];
        limit.enabled = _enabled;
        limit.blocks = _blocks;
        limit.amount = _amount;
    }

    function setTokenLimits(address[] memory _token, bool[] memory _enabled, uint[] memory _blocks, uint[] memory _amount) external onlyManager {
        require(
            _token.length == _enabled.length 
            && _enabled.length == _blocks.length 
            && _blocks.length == _amount.length 
            , "UserTokenLimit: INVALID_PARAM"
        );
        for (uint i; i < _token.length; i++) {
            setTokenLimit(_token[i], _enabled[i], _blocks[i], _amount[i]);
        }
    }

    function setTokenLimitEnable(address _token, bool _enabled) public onlyManager {
        TokenLimit storage limit = tokenLimits[_token];
        limit.enabled = _enabled;
    }

    function setTokenLimitEnables(address[] memory _token, bool[] memory _enabled) external onlyManager {
        require(
            _token.length == _enabled.length 
            , "UserTokenLimit: INVALID_PARAM"
        );
        for (uint i; i < _token.length; i++) {
            setTokenLimitEnable(_token[i], _enabled[i]);
        }
    }

    function getUserLimit(address _user, address _token, uint _value) public view returns (uint) {
        TokenLimit memory tokenLimit = tokenLimits[_token];
        if (tokenLimit.enabled == false) {
            return _value;
        }
        
        if(_value > tokenLimit.amount) {
            _value = tokenLimit.amount;
        }

        UserLimit memory limit = userLimits[_user][_token];
        if (block.number.sub(limit.lastBlock) >= tokenLimit.blocks) {
            return _value;
        }

        if (limit.consumption.add(_value) > tokenLimit.amount) {
            _value = tokenLimit.amount.sub(limit.consumption);
        }
        return _value;
    }

    function _updateUserTokenLimit(address _token, uint _value) internal {
        TokenLimit memory tokenLimit = tokenLimits[_token];
        if(tokenLimit.enabled == false) {
            return;
        }

        UserLimit storage limit = userLimits[msg.sender][_token];
        if(block.number.sub(limit.lastBlock) > tokenLimit.blocks) {
            limit.consumption = 0;
        }
        limit.lastBlock = block.number;
        limit.consumption = limit.consumption.add(_value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchTreasury {
    function tokenBalanceOf(address _token) external returns (uint);
    function mint(address _token, address _to, uint _value) external returns (uint);
    function burn(address _token, address _from, uint _value) external returns (uint);
    function deposit(address _from, address _token, uint _value) external payable returns (uint);
    function queryWithdraw(address _user, address _token) external view returns (uint);
    function withdraw(bool _isETH, address _to, address _token, uint _value) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ISwitchSigner {
    function checkUser(address _user) external view returns (bool);
    function verify(uint _mode, address _user, address _singer, bytes32 _message, bytes memory _signature) external view returns (bool);
    function mverify(uint _mode, address _user, address _singer, bytes32 _message, bytes[] memory _signatures) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchTicketFactory {
    function treasury() external view returns (address);
    function getTokenMap(address _token) external view returns (address);
    function isTicket(address _ticket) external view returns (bool);
    function deposit(address _token, uint _value, address _to) external payable returns (address);
    function queryWithdrawInfo(address _user, address _ticket) external view returns (uint balance, uint amount);
    function queryWithdraw(address _user, address _ticket) external view returns (uint);
    function withdraw(bool isETH, address _to, address _ticket, uint _value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IRewardToken {
    function balanceOf(address owner) external view returns (uint);
    function take() external view returns (uint);
    function funds(address user) external view returns (uint);
    function mint(address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IConfig {
    function dev() external view returns (address);
    function admin() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event ConfigChanged(address indexed _user, address indexed _old, address indexed _new);
    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);
 
    function setupConfig(address _config) external onlyOwner {
        emit ConfigChanged(msg.sender, config, _config);
        config = _config;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }

    function admin() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).admin();
        }
        return owner;
    }

    function dev() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).dev();
        }
        return owner;
    }

    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'Owner: NO CHANGE');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }
    
    modifier onlyDev() {
        require(msg.sender == dev() || msg.sender == owner, 'dev FORBIDDEN');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin(), 'admin FORBIDDEN');
        _;
    }
  
    modifier onlyManager() {
        require(msg.sender == dev() || msg.sender == admin() || msg.sender == owner, 'manager FORBIDDEN');
        _;
    }
}

