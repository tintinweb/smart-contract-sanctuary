pragma solidity > 0.6.0;

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract AdminAccount {
    using SafeMath for uint256;

    uint256 public constant MAG = 10 ** 18;
    
    address[] public ambassadorList  = [0x6d9AA5B78eF61b5A57aA6855015CFe778E4dE6eE,
                                        0x42aF27DEB32DC1E701C3D56e993A8a878c9aefCb,
                                        0xB4C0F2E31a22fB0A5387638b3A85BcdB2eFb0DFE];
    
    mapping(address => uint256) public shares;
    
    modifier isAmbassador() {
        require(shares[msg.sender] > uint256(0));
        _;
    }
    
   constructor() public {
       shares[ambassadorList[0]] = 44e16;
       shares[ambassadorList[1]] = 44e16;
       shares[ambassadorList[2]] = 12e16;
   }
    
   function disburseFees(address _token) isAmbassador external {
       uint256 balance_ = IERC20(_token).balanceOf(address(this));
       require(balance_ > uint256(0), "Nothing to withdraw");
       for(uint256 i = 0; i < ambassadorList.length; i++) {
           address ambassador_ = ambassadorList[i];
           uint256 share_ = shares[ambassador_];
           uint256 amount_ = (share_.mul(balance_)).div(MAG);
           TransferHelper.safeTransfer(_token, ambassador_, amount_);
       }
   }
    
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}