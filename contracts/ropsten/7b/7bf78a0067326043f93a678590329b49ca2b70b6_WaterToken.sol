pragma solidity ^0.5.16;

import './Address.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './ERC20Detailed.sol';
import './ERC20.sol';

/**
 * 发布的token
 */
contract WaterToken is ERC20, ERC20Detailed {

    
    using SafeERC20 for IERC20;
    
    using Address for address;
    
    using SafeMath for uint;

    
    address public governance;

    
    mapping (address => bool) public minters;


    // 构造函数，设置代币名称、简称、精度；将发布合约的账号设置为治理账号
    constructor () public ERC20Detailed("WaterCoin.finance", "WFC", 18) {
        governance = tx.origin;
    }

    
    function mint(address account, uint256 amount) public {
        require(minters[msg.sender], "!minter");
        _mint(account, amount);
    }

    
    function setGovernance(address _governance) public {
        
        require(msg.sender == governance, "!governance");
        
        governance = _governance;
    }

    
    function addMinter(address _minter) public {
        
        require(msg.sender == governance, "!governance");
       
        minters[_minter] = true;
    }

    
    function removeMinter(address _minter) public {
        // 要求调用者必须为当前治理管理员地址
        require(msg.sender == governance, "!governance");
        // 变更指定地址_minter的铸币权限为false
        minters[_minter] = false;
    }
}