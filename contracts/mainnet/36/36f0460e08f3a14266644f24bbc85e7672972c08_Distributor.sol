/**
 *Submitted for verification at Etherscan.io on 2020-12-25
*/

pragma solidity ^0.6.10;
    
    // SPDX-License-Identifier: MIT;
    
    
    library SafeMath {
        /**
         * @dev Returns the addition of two unsigned integers, reverting on
         * overflow.
         *
         * Counterpart to Solidity's `+` operator.
         *
         * Requirements:
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
         * - Subtraction cannot overflow.
         *
         * _Available since v2.4.0._
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
         * - The divisor cannot be zero.
         *
         * _Available since v2.4.0._
         */
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            // Solidity only automatically asserts when dividing by 0
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
         * - The divisor cannot be zero.
         *
         * _Available since v2.4.0._
         */
        function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b != 0, errorMessage);
            return a % b;
        }
    }
    
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
    
    contract Mutex {
        bool isLocked;
        modifier noReentrance() {
            require(!isLocked);
            isLocked = true;
            _;
            isLocked = false;
        }
        
    }
    
    contract Distributor is Mutex {
      using SafeMath for uint256;
    
    
      IERC20 public token;
  
      address payable public wallet = 0x93B3a464aF66Ce7b73cD5a2acBB927A8Ea5BaB0e;
      uint256 public rate = 333;
     
     
      uint256 public trxnCount;
      uint256 public weiRaised;
    
    
      event Bought(uint256 amount);
      event Transfer(address _to, uint256 amount);
      event TransferMultiple(address[] _receivers, uint256 amount);
      event TotalBalance(address sender,uint256 vlue,uint256 balance);
    
      modifier onlyOwner{
          require(msg.sender==wallet);
          _;
      }
      
    constructor(address _token) public {
        token = IERC20(_token);
    }
  


    receive() external payable {
        (bool success,) = wallet.call{value:msg.value}("");
        require(success, "can not transfer funds");
        buy(msg.sender);
        weiRaised = weiRaised.add(msg.value);
    }


    function buy(address _buyer) payable public noReentrance {
        uint256 amountTobuy = _getTokenAmount(msg.value);
        uint256 thisBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= thisBalance, "Not enough tokens in the reserve");
        TransferHelper.safeTransfer(address(token), _buyer, amountTobuy);
        emit Bought(amountTobuy);
        trxnCount++;
    }

  
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(rate);
    }
    
  
    function getEthTokenBal() public view returns(uint256, uint256) {
        return ( address(this).balance, token.balanceOf(address(this)));
    }
  
    function withdrawToken() public onlyOwner{
        uint bal = token.balanceOf(address(this));
        TransferHelper.safeTransfer(address(token), wallet, bal);
        emit Transfer(wallet, bal);
    }
  
    function burn()public onlyOwner {
        
        uint256 bal = token.balanceOf(address(this));
        TransferHelper.safeTransfer(address(token), address(0), bal);
        emit Transfer(address(0), bal);
    }
    

  
}


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