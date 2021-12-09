// SPDX-License-Identifier: MIT
//   
//                    ▄█           
//                  ▄███           
//               ,▓█████           
//        ╓▓█████████████████████▀`
//      ╓████████████████████▀╓╛   
//     ▐█████████████████▀╙ ,╛     
//     ███████████████▀─  ╓╜       
//     ███████████▀╙    ╓╙         
//     ╟█████████      ╟██▄,       
//      ╙████████      ╟█████▄     
//        ╙▀█████      ╟███████    
//            └╟▀    ,▄█████████   
//           #╙   ▄▓████████████   
//         #└ ,▄███████████████▌   
//       é─▄▓█████████████████▀    
//    ,Q▄███████████████████▀─     
//   "▀▀▀▀▀▀▀▀▀▀██████▀▀▀╙─        
//              ████▀              
//              ██▀                
//              └      
//   
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ConvertorConfig.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IRouter.sol";

contract ConvertorRegistry is Ownable {
    uint256 public convertor_deadline = 20000;
    mapping(address => mapping(address => ConvertorConfig)) private convertorConfig;

    // convertor governance
    function configureConvertorDeadline(uint256 _convertor_deadline) public onlyOwner {
        convertor_deadline = _convertor_deadline;
    }
    function configureConvertor(address _from_token, address _to_token, address _exchange_router, address[] calldata _exchange_path) public onlyOwner {
        convertorConfig[_from_token][_to_token] = ConvertorConfig({router: _exchange_router, path:_exchange_path});
        IBEP20(_from_token).approve(_exchange_router, type(uint256).max);
    }
    function configureConvertorPath(address _exchange_router, address[] calldata _exchange_path) public onlyOwner {
        address _from_token = _exchange_path[0];
        address _to_token = _exchange_path[_exchange_path.length-1];
        convertorConfig[_from_token][_to_token] = ConvertorConfig({router: _exchange_router, path:_exchange_path});
        IBEP20(_from_token).approve(_exchange_router, type(uint256).max);
    }
    
    // conversion methods
    function getConvertorConfig(address _from_token, address _to_token) public view returns (address router, address[] memory path) {
        ConvertorConfig storage config = convertorConfig[_from_token][_to_token];
        return (config.router, config.path);
    }

    function estimateConversion(uint256 amount, address _from_token, address _to_token) public view returns (uint256) {
        if (amount == 0) return 0;
        ConvertorConfig storage config = convertorConfig[_from_token][_to_token];
        require(config.router != address(0), "Unable to estimate conversion due to missing router configuration!");
        uint[] memory amounts = IRouter(config.router).getAmountsOut(amount, config.path);
        uint256 amountOut = amounts[amounts.length - 1];
        return amountOut;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function initOwnerAfterCloning(address newOwner) public {
        require(_owner == address(0), "Ownable: owner has already been initialized");
        emit OwnershipTransferred(address(0), newOwner);
        _owner = newOwner;
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
        _owner = address(0x000000000000000000000031337000b017000d0114);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;

struct ConvertorConfig {
    address router;
    address[] path;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;
interface IBEP20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
        
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}