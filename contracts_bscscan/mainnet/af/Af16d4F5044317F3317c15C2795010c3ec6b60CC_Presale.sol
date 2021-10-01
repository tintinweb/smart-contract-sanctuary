// SPDX-License-Identifier: MIT
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";

pragma solidity 0.6.12;

// For interacting with our own strategy
interface IStrategy {
    // Total want tokens managed by stratfegy
    function wantLockedTotal() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens yetiFarm -> strategy
    function deposit(uint256 _wantAmt)
        external
        returns (uint256);

    // Transfer want tokens strategy -> yetiFarm
    function withdraw(uint256 _wantAmt)
        external
        returns (uint256);

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}



pragma solidity 0.6.12;


contract Presale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct UserInfo {uint256 amount; // How many amount tokens the user has provided.
    }


    // BUSD
    address public TOKEN = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // ANUBIS
    address public ANUBIS = 0xA7805d7B0F07EdC37825a52aDdb2f48D48DB6C7A;

     // Dev address.
    address public devaddr = 0x5d4DCD9631Dc2dFF83DaC0cc0bE170982F95f80B;
    
    // Factor: TOKEN mul factor div 1000 = ANUBIS (10000 = 1:1, 1 = 10000:1)
    uint256 public factor = 5000;
    

    event MigrateToANUBIS(address indexed user,uint256 amount);
    event SetDEVAddress(address indexed user, address indexed newAddress);
    event SetFactor(address indexed user, uint256 _Factor);
    event SetTokenAddress(address indexed user,address indexed newAddress);
    event SetANUBISAddress(address indexed user, address indexed newAddress);



    // Safe ANUBIS transfer function, just in case if rounding error causes pool to not have enough
    function ANUBISTransfer(address _to, uint256 _ANUBISAmt) internal {
        uint256 ANUBISBal = IERC20(ANUBIS).balanceOf(address(this));
        if (_ANUBISAmt > ANUBISBal) {
            IERC20(ANUBIS).transfer(_to, ANUBISBal);
        } else {
            IERC20(ANUBIS).transfer(_to, _ANUBISAmt);
        }
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }


      // Update TOKEN address by the previous dev.
    function SetTokenaddress(address _TOKEN) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");
        TOKEN = _TOKEN;
        emit SetTokenAddress(msg.sender, _TOKEN);
    }
    
     // Update ANUBIS address by the previous dev.
    function SetaNUBISAddress(address _ANUBIS) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");
        ANUBIS = _ANUBIS;
        emit SetANUBISAddress(msg.sender, _ANUBIS);
    }
    
     // Update dev address by the previous dev.
    function SetDevAddress(address _devaddr) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");
        devaddr = _devaddr;
        emit SetDEVAddress(msg.sender, _devaddr);
    }
    
    // update factor
    function setFactor(uint256 _Factor) public {
        require(msg.sender == devaddr, "dev: you are not DEV?");    
        factor = _Factor;
        emit SetFactor(msg.sender, _Factor);
    }


    function migrateToANUBIS(uint256 _inputAmt) public {
        require(factor > 0, "MigrateToANUBIS: No more Selling");
        
        uint256 sendAmount = _inputAmt.mul(factor).div(10000);
        
        uint256 ANUBISBal = IERC20(ANUBIS).balanceOf(address(this));
        
        require(ANUBISBal >= sendAmount, "MigrateToANUBIS: No ANUBIS left to buy");
        
        IERC20(TOKEN).safeTransferFrom(address(msg.sender),address(this),_inputAmt);

        IERC20(ANUBIS).transfer(msg.sender, sendAmount);
        
        emit MigrateToANUBIS(msg.sender, sendAmount);
    }
}