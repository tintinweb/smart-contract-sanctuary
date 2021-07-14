/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-01-14
*/

pragma solidity >=0.4.22 <0.8.0;

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function TokensPurchased(address buyer, uint256 amount) external  returns (bool success);
    function burn(uint256 _value) external returns (bool success);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        
        _notEntered = true;
    }

    
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        
        _notEntered = true;
    }
}

contract NMJ_CROWDSALE is Context, ReentrancyGuard{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public governance;
    
    uint256 public rate;
    uint256 private _weiRaised;
    uint256 public totalSold;
    IERC20 public tokenAddress;
    //uint256 public startTime = 1608483600; //
    //uint256 public endTime = 1608407761; //
    
    uint256 public minimumBuyAmount = 10 ** 8;
    uint256 public maximumBuyAmount = 20 ether;
    address payable public walletAddress;
    event TokensPurchased(address indexed to, uint256 amount);
    
    constructor () public {
        governance = tx.origin;
        rate = uint256(1000);
        walletAddress = 0xDC110D1F175b9517EA4e64615A6EF65f14070955; //TEAM
        tokenAddress = IERC20(0x0);
    }
    
    function () external payable {
        buy();
    }
    
    function changeWallet (address payable _walletAddress) public {
        require(msg.sender == governance, "!governance");
        walletAddress = _walletAddress;
    }
    
    function setToken(IERC20 _tokenAddress) public {
        require(msg.sender == governance, "!governance");
        tokenAddress = _tokenAddress;
    }
    
    function buy() public payable {
        //require((block.timestamp > startTime ) && (block.timestamp < endTime)  , "D01 Token Crowdsate is not active");
        uint256 weiValue = msg.value;
        require((weiValue >= minimumBuyAmount) &&(weiValue<= maximumBuyAmount), "Minimum amount is 0.1 eth and Maximum amount is 5 Eth");
        uint256 amount = weiValue.mul(rate);
        _weiRaised = _weiRaised.add(weiValue);
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(msg.sender, amount);
        walletAddress.transfer(weiValue);
        //require(walletAddress.send(weiValue)); //_fundRaisingWallet.transfer(msg.value);
        //require(token.TokensPurchased(msg.sender, amount));
        totalSold += amount;
        emit TokensPurchased(msg.sender, amount);
    }
    
    function burnUnsold() private {
        require(msg.sender == governance, "!governance");
        //require((block.timestamp > endTime), Crowdsate is still active");
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        token.burn(amount);
    }
    
    //Spyro was here...:
    //                 /      /                                               
   //             /' .,,,,  ./                                                 
   //            /';'     ,/                                                   
   //           / /   ,,//,`'`                                                 
   //          ( ,, '_,  ,,,' ``                                               
   //          |    /@  ,,, ;" `                                               
   //         /    .   ,''/' `,``                                              
   //        /   .     ./, `,, ` ;                                             
   //     ,./  .   ,-,',` ,,/''\,'                                             
   //    |   /; ./,,'`,,'' |   |                                               
   //    |     /   ','    /    |                                               
   //     \___/'   '     |     |                                               
   //       `,,'  |      /     `\                                              
   //            /      |        ~\                                            
   //          (                                                      
   //          :                                                               
   //         ; .         \--                                                  
   //       :   \         ;
    
}