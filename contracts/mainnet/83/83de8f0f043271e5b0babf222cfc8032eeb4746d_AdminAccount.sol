/**
 *Submitted for verification at Etherscan.io on 2020-09-04
*/

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

    address public constant TOKEN = 0x0F7d6242c082FDb399163Bf24380785775f7021d;
    uint256 public constant MAG = 10 ** 18;
    
    address[] ambassadorList  = [0x2D78B2491b384a79E41555CFEF5393450c96697C,
                                 0xCA1F0623DeC82594a124e20024aFCC7F78B4A56f,
                                 0xE42eE793dD4f083EaBcE3Dc77847f7366A482524,
                                 0x5D3D55F4abd9843416254683933B093F06Cb0e72,
                                 0x1343cB2C821848DF7Ac60bDefAE24A329917d3Cc,
                                 0x92D165900a18430052b8434c61eCb35AD4E8faF8,
                                 0xef9f9C7F5E6E4B1bfEF3AaF67D6bE1dD9b2db83b,
                                 0x3dF3766E64C2C85Ce1baa858d2A14F96916d5087,
                                 0x13216D1A245A3dF60cFcE85A84c5fe84b1706fd7,
                                 0xd865697A2aCbBdf280EDD19d81FA1D9a4885a15e];
    
    mapping(address => uint256) public shares;
    
    modifier isAmbassador() {
        require(shares[msg.sender] > uint256(0));
        _;
    }
    
   constructor() public {
       shares[0x2D78B2491b384a79E41555CFEF5393450c96697C] = 5e15;
       shares[0xCA1F0623DeC82594a124e20024aFCC7F78B4A56f] = 15e15;
       shares[0xE42eE793dD4f083EaBcE3Dc77847f7366A482524] = 15e15;
       shares[0x5D3D55F4abd9843416254683933B093F06Cb0e72] = 4e16;
       shares[0x1343cB2C821848DF7Ac60bDefAE24A329917d3Cc] = 5e16;
       shares[0x92D165900a18430052b8434c61eCb35AD4E8faF8] = 65e15;
       shares[0xef9f9C7F5E6E4B1bfEF3AaF67D6bE1dD9b2db83b] = 65e15;
       shares[0x3dF3766E64C2C85Ce1baa858d2A14F96916d5087] = 65e15;
       shares[0x13216D1A245A3dF60cFcE85A84c5fe84b1706fd7] = 34e16;
       shares[0xd865697A2aCbBdf280EDD19d81FA1D9a4885a15e] = 34e16;
   }
    
   function disburseFees() isAmbassador external {
       uint256 balance_ = IERC20(TOKEN).balanceOf(address(this));
       require(balance_ > uint256(0), "Nothing to withdraw");
       for(uint256 i = 0; i < ambassadorList.length; i++) {
           address ambassador_ = ambassadorList[i];
           uint256 share_ = shares[ambassador_];
           uint256 amount_ = (share_.mul(balance_)).div(MAG);
           TransferHelper.safeTransfer(TOKEN, ambassador_, amount_);
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