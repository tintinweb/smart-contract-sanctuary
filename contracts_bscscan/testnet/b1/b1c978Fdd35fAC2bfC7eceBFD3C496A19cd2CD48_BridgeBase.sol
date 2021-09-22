/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
/*
 * Copyright © 2020 reflect.finance. ALL RIGHTS RESERVED.
 */

pragma solidity ^0.8.4;

 abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }
}

library SafeMath {
  function add(uint a, uint b) internal pure returns(uint) {
    uint c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint a, uint b) internal pure returns(uint) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
    require(b <= a, errorMessage);
    uint c = a - b;

    return c;
  }

  function mul(uint a, uint b) internal pure returns(uint) {
    if (a == 0) {
        return 0;
    }

    uint c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint a, uint b) internal pure returns(uint) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint c = a / b;

    return c;
  }
}

  contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

  
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

abstract contract IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract BridgeBase is Context, Ownable {
    using SafeMath for uint256;
    
    struct Limit{
        uint256 amount;
        uint256 lastTransfered;
    }
    
    mapping(uint256 => uint256) private _nonces;
    mapping (uint256 => mapping(uint256 => bool)) private nonceProcessed;
    mapping(uint256 => uint256) private _processedFees;
    mapping(address => Limit) private _walletLimit;
    uint256 private _bridgeFee = 2;
    
    mapping(address => bool) private _blacklisted;


    address dogex;
    address system;
    address bridgeFeesAddress = 0xDF4aFe2711A3f42769958f1049e6256fB8865E69;
    address uniswapV2Pair;
    bool private pairSwapped = false;

    
    event SwapRequest(
      address indexed to,
      uint256 amount,
      uint256 nonce,
      uint256 toChainID
    );
    
    event WalletTransfer(
        address from,
        uint256 amount,
        address indexed to
    );

    modifier onlySystem() {
        require(system == _msgSender(), "Ownable: caller is not the system");
        _;
    }

    constructor(address _dogex, address _system, address _uniswapV2Pair)  {
      dogex = _dogex;
      system = _system;
      uniswapV2Pair = _uniswapV2Pair;
      
    //   initializing processed fees
        _processedFees[1] = 1000000000000000;
        _processedFees[250] = 1000000000000;
        
    }
   
   function getTokenAmount(uint256 amount) public view returns(uint256) {
        IERC20 token0 = IERC20(IUniswapV2Pair(uniswapV2Pair).token0());//bnb
        IERC20 token1 = IERC20(IUniswapV2Pair(uniswapV2Pair).token1());//dogex
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        if(pairSwapped) {
            token0 = IERC20(IUniswapV2Pair(uniswapV2Pair).token1());//bnb
            token1 = IERC20(IUniswapV2Pair(uniswapV2Pair).token0());//dogex
            (Res1, Res0,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        }

        uint res1 = Res1*(10**token0.decimals());
        return((amount*res1)/(Res0*(10**token0.decimals()))); 
}
   
   function updatePairSwapped(bool swapped) external onlyOwner() {
        pairSwapped = swapped;
    }
   /**
   * @dev Function for setting mint fee by owner
   * @param bridgeFee Bridge Fee
   */
    function setBridgeFee(uint256 bridgeFee) external onlyOwner returns(bool){
        require(bridgeFee > 0, "Invalid Percentage");
        _bridgeFee = bridgeFee;
        return true;
  }
    
      function getBridgeFee() external view returns(uint256){
        return _bridgeFee;
      }
      
      function setSystem(address _system) external onlyOwner returns(bool){
          system = _system;
          return true;
      }
      
      function isBlacklisted(address account) external view returns(bool) {
          return _blacklisted[account];
      }
      
      
      function setProcessedFess(uint256 chainID, uint256 processedFees) external onlyOwner {
          _processedFees[chainID] = processedFees;
      }
  

    function getBridgeStatus(uint256 nonce, uint256 fromChainID) external view returns(bool) {
        return nonceProcessed[fromChainID][nonce];
    }
    
    function getUserWalletLimit(address account) external view returns(Limit memory) {
        uint256 tokenLimit = getTokenAmount(20000000000000000000);
        Limit memory limit = _walletLimit[account];
        if(block.timestamp.sub(limit.lastTransfered) > 1 days) {
            limit.amount = tokenLimit;
            limit.lastTransfered = 0;
        } else {
            limit.amount = tokenLimit.sub(limit.amount);
            limit.lastTransfered = 1 days - block.timestamp.sub(limit.lastTransfered);
        }
        
        return limit;
        
        
        
    }
    
    // function update(uint256 amount) external {
    //     Limit memory limit = _walletLimit[_msgSender()];
    //     limit.amount = limit.amount.add(amount);
    //     limit.lastTransfered = block.timestamp;
    //     _walletLimit[_msgSender()] = limit;
    // }
    function walletTransfer(address to, uint256 amount) external {
        Limit memory limit = _walletLimit[_msgSender()];
        if(block.timestamp.sub(limit.lastTransfered) > 1 days) {
            limit.amount = 0;
            limit.lastTransfered = block.timestamp;
        }
        uint256 tokenLimit = getTokenAmount(20000000000000000000);
        // require(msg.value>= _processedFees[56], "Insufficient processed fees");
        require(limit.amount + amount < tokenLimit, "Exceeds token Limit for today!");
        limit.amount = limit.amount + amount;
        _walletLimit[_msgSender()] = limit;
        
        TransferHelper.safeTransferFrom(dogex, _msgSender(), address(this), amount);
        TransferHelper.safeTransfer(dogex, to, amount);
        // payable(system).transfer(msg.value);
        emit WalletTransfer(_msgSender(),amount,to);
        
    }
    
    // function TransferBack(address to, uint256 amount, uint256 nonce) external onlySystem {
    //     require(!nonceProcessed[56][nonce], "Swap is already proceeds");
    //     nonceProcessed[56][nonce] = true;
        
    //     TransferHelper.safeTransfer(dogex, to, amount);
    // }
    
    function swap (uint256 amount, uint256 toChainID) external payable {
        require(msg.value>= _processedFees[toChainID], "Insufficient processed fees");
        uint256 _nonce = _nonces[toChainID];
        _nonce.add(1);
        _nonces[toChainID] = _nonce;
        TransferHelper.safeTransferFrom(dogex, _msgSender(), address(this), amount);
        payable(system).transfer(msg.value);
        emit SwapRequest(_msgSender(),amount,_nonce,toChainID);
    }
    
    function feeCalculation(uint256 amount) public view returns(uint256) { 
       uint256 _amountAfterFee = (amount-(amount.mul(_bridgeFee)/1000));
        return _amountAfterFee;
    }  
    
    function swapBack (address to, uint256 amount,uint256 nonce, uint256 fromChainID) external onlySystem {
        require(!nonceProcessed[fromChainID][nonce], "Swap is already proceeds");
        nonceProcessed[fromChainID][nonce] = true;
        
        uint256 temp = feeCalculation(amount);
        uint256 fees = amount.sub(temp);
      
    //   TransferHelper.safeApprove(dogex,address(this),fees);
      TransferHelper.safeTransfer(dogex,bridgeFeesAddress, fees);
      
    //   TransferHelper.safeApprove(dogex,address(this),temp);
      TransferHelper.safeTransfer(dogex, to, temp);

    }  
}