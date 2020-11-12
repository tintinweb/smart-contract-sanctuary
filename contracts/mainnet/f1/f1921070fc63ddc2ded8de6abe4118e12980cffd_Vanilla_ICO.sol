pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
abstract contract IERC20 {
    function transfer(address to, uint256 tokens) external virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external virtual returns (bool success);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        require(m != 0, "SafeMath: to ceil number shall not be zero");
        return (a + m - 1) / m * m;
    }
}

contract Vanilla_ICO is Owned{
    
    using SafeMath for uint256;
    address constant private MYX = 0x2129fF6000b95A973236020BCd2b2006B0D8E019;
    address private VANILLA = address(0);
    
    uint256 private SWAP_END;
    
    event TokensSwapped(address indexed _purchaser, uint256 indexed myx, uint256 indexed vanilla);
    event TokensPurchased(address indexed _purchaser, uint256 indexed weis, uint256 indexed vanilla);
    
    
    address payable constant private assetsReceivingWallet1 = 0xE88820E7b990e25E3265833AB29D00fA6B0593E4;
    address payable constant private assetsReceivingWallet2 = 0x6753bbB687a04AA0eCB59ACB4cdf957432EF82dA;
    address payable constant private assetsReceivingWallet3 = 0xa763502F386D8226a59206a2A6F6393e0D88228f;
    address payable constant private assetsReceivingWallet4 = 0xf37DBd0508bD06Ef9b4701d50b7DA7a9C8369B14;
    
    
    uint256 public ethsReceived;
    uint256 public myxReceived;
    uint256 public vanillaDistributed;
    
    modifier swappingOpen{
        require(block.timestamp <= SWAP_END, "Swap sale is close");
        _;
    }
    
    constructor() public {
        owner = 0xFa50b82cbf2942008A097B6289F39b1bb797C5Cd;
        SWAP_END = 1605182399; // 12 november, 2020 23:59:59 GMT
    }
    
    function MYX_VANILLA(uint256 tokens) external swappingOpen{
       require(tokens > 0, "myx should not be zero");
       uint256 myxInContract_before = IERC20(MYX).balanceOf(address(this));
       require(IERC20(MYX).transferFrom(msg.sender, address(this), tokens), "Insufficient tokens in user wallet");
       uint256 myxInContract_after = IERC20(MYX).balanceOf(address(this));
       
       uint256 vanilla = tokens.mul(10 ** (18)); // tokens actually sent will used to calculate vanilla in swap
       vanilla = vanilla.div(500);
       vanilla = vanilla.div(10 ** 18);
       
       
       myxInContract_after = myxInContract_after.sub(myxInContract_before);
       
       myxReceived = myxReceived.add(tokens);
       
       vanillaDistributed = vanillaDistributed.add(vanilla);
       
       require(IERC20(VANILLA).transfer(msg.sender, vanilla), "All tokens sold");
       
       // send the received funds to the 4 owner wallets
       distributeReceivedAssets(true, myxInContract_after);
       
       emit TokensSwapped(msg.sender, tokens, vanilla);
    }
    
    receive() external payable{
       ETH_VANILLA(); 
    }
    
    function ETH_VANILLA() public payable swappingOpen{
       require(msg.value > 0, "investment should be greater than zero");
       uint256 vanilla = msg.value.mul(2750); // 1 ether = 2750 vanilla
       
       ethsReceived = ethsReceived.add(msg.value);
       vanillaDistributed = vanillaDistributed.add(vanilla);
       
       require(IERC20(VANILLA).transfer(msg.sender, vanilla), "All tokens sold");
       
       // send the received funds to the 4 owner wallets
       distributeReceivedAssets(false, msg.value);
       
       emit TokensPurchased(msg.sender, msg.value, vanilla);
    }
    
    function getUnSoldTokens() external onlyOwner{
        require(block.timestamp > SWAP_END, "ICO is not over");
        
        require(IERC20(VANILLA).transfer(owner, IERC20(VANILLA).balanceOf(address(this))), "No tokens in contract");
    }
    
    function setVanillaAddress(address _vanillaContract) external onlyOwner{
        require(VANILLA == address(0), "address already linked");
        VANILLA = _vanillaContract;
    }
    
    function distributeReceivedAssets(bool myx, uint256 amount) private{
        if(myx){
            if(divideAssetByFour(amount) > 0){
                // send the received funds to the 4 owner wallets
                IERC20(MYX).transfer(assetsReceivingWallet1, divideAssetByFour(amount));
                IERC20(MYX).transfer(assetsReceivingWallet2, divideAssetByFour(amount));
                IERC20(MYX).transfer(assetsReceivingWallet3, divideAssetByFour(amount));
                
            }
            IERC20(MYX).transfer(assetsReceivingWallet4, divideAssetByFour(amount).add(getRemainings(amount)));
        }
        else{
            if(divideAssetByFour(amount) > 0){
                // send the received funds to the 4 owner wallets
                assetsReceivingWallet1.transfer(divideAssetByFour(amount));
                assetsReceivingWallet2.transfer(divideAssetByFour(amount));
                assetsReceivingWallet3.transfer(divideAssetByFour(amount));
            }
            assetsReceivingWallet4.transfer(divideAssetByFour(amount).add(getRemainings(amount)));
        }
    }
    
    function divideAssetByFour(uint256 amount) public pure returns(uint256){
        return amount.div(4);
    }
    
    function getRemainings(uint256 amount) public pure returns(uint256){
        return amount.mod(4);
    }
}