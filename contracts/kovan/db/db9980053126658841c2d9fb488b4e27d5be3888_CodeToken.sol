pragma solidity ^0.5.16;

import './Address.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './ERC20Detailed.sol';
import './ERC20.sol';


contract CodeToken is ERC20, ERC20Detailed {

    
    using SafeERC20 for IERC20;
    
    using Address for address;
    
    using SafeMath for uint;

    
    address public governance;

    
    mapping (address => bool) public minters;


    
    constructor () public ERC20Detailed("Label.service", "LLS", 18) {
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
        
        require(msg.sender == governance, "!governance");
        
        minters[_minter] = false;
    }
}