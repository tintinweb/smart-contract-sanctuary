/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

pragma solidity ^0.6.12;



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
}




interface IERC20 {
    
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);   
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

  
}

contract TNReward is Ownable{
    
    using SafeMath for uint256;
    
    uint256 private pledgeTotal;
    
    
    mapping(address => PledgeAmount) private addressPledgeAmount;
    
    address[] pledgeAddresses;
    
    IERC20 private pair;
    
    IERC20 private erc20;
    
    
    struct PledgeAmount{
        uint256 index;
        uint256 pledgeAmount;
    }
    
    
    
    constructor(IERC20 _erc20, IERC20 _pair) public{
        erc20 = _erc20;
        pair = _pair;
    }
    
    
    
    event Pledge(address indexed pledgeAddress, uint256 value);
    
    event Release(address indexed releaseAddress, uint256 value);
    
    event Reward(address indexed rewardAddress, uint256 value);
    
    
    
    
    function getAddressPledgeAmount(address _address) public view returns (uint256) {
        return addressPledgeAmount[_address].pledgeAmount;
    }
    
    
    function getPledgeTotal() public view returns (uint256) {
        return pledgeTotal;
    }
    
    
    
    function setPairAddress(IERC20 _pair) external onlyOwner{
        pair = _pair;
    }
    
    function getPairAddress() public view returns(IERC20) {
        return pair;
    }
    
    
    function setErc20Address(IERC20 _erc20) external onlyOwner{
        erc20 = _erc20;
    }
    
    function getErc20Address() public view returns(IERC20) {
        return erc20;
    }
    
    
    function pledge(uint256 amount) public{
        require(amount > 0, "Amount:  zero");
        
        address msgSender = _msgSender();
        
        require(pair.balanceOf(msgSender) >= amount, "Balance: insufficient");
        require(pair.allowance(msgSender, address(this)) >= amount, "Approve: insufficient");
        
        pair.transferFrom(msgSender, address(this), amount);
        
        pledge(msgSender, amount);
        
        emit Pledge(msgSender, amount);
       
    }
    
    
    
    
    
    function reward() external onlyOwner{
        
        uint256 amount = erc20.balanceOf(address(this));
         
        require(amount > 0, "Balance: insufficient");
         
        for(uint i = 0; i < pledgeAddresses.length; i++) {
            
            reward(pledgeAddresses[i], amount);
            
        }
        
    }
    

    
      
    function release(uint256 amount) public{
        require(amount > 0, "Amount:  zero");
        
        address msgSender = _msgSender();
        require(addressPledgeAmount[msgSender].pledgeAmount >= amount, "PledgeAmount: insufficient");
        
        pair.transfer(msgSender, amount);
        
        
        release(msgSender, amount);
        
        
        
        emit Release(msgSender, amount);
    }
    






    
    function pledge(address _address, uint256 _amount) private {
        
        if(0 == addressPledgeAmount[_address].pledgeAmount){
            pushPledgeAddress(_address);
            pushPledgeAmount(_address);
        }
        
        
        addAddressPledgeAmount(_address, _amount);
        
        addPledgeTotal(_amount);
    }
   
    
    
    function pushPledgeAddress(address _address) private {
        pledgeAddresses[pledgeAddresses.length] = _address;
    }
    
    
    function pushPledgeAmount(address _address) private {
        PledgeAmount memory pledgeAmount = PledgeAmount(pledgeAddresses.length, 0);
        addressPledgeAmount[_address] = pledgeAmount;
    }
    
    
    function addAddressPledgeAmount(address _address, uint256 amount) private {
        addressPledgeAmount[_address].pledgeAmount = addressPledgeAmount[_address].pledgeAmount.add(amount);
    }
    
    
    
    
    
    function reward(address _address, uint256 _amount) private {
       
       uint256 rewardAmount = _amount.mul(addressPledgeAmount[_address].pledgeAmount).div(pledgeTotal);
       
       require(0 < rewardAmount, "RewardAmount: is zero");
       
       erc20.transfer(_address, rewardAmount);
       
       emit Reward(_address, rewardAmount);
       
    }
    
    
    
    function release(address _address, uint256 _amount) private{
        
        subAddressPledgeAmount(_address, _amount);
        
        if(0 == addressPledgeAmount[_address].pledgeAmount){
            removePledgeAddress(_address);
        
            removeAddressPledgeAmount(_address);
        }
        
        subPledgeTotal(_amount);
        
        
    }
    
    
    function removeAddressPledgeAmount(address _address) private {
        delete addressPledgeAmount[_address];
    }
    
    
    function removePledgeAddress(address _address) private {
       
        uint256 indexRemove = addressPledgeAmount[_address].index;
       
        removeAtIndex(indexRemove);
    }
    
    
    function subAddressPledgeAmount(address _address, uint256 _amount) private {
        addressPledgeAmount[_address].pledgeAmount = addressPledgeAmount[_address].pledgeAmount.sub(_amount);
    }
    
    
    function addPledgeTotal(uint256 amount) private {
        pledgeTotal = pledgeTotal.add(amount);
    }
    
    
    function subPledgeTotal(uint256 amount) private {
        pledgeTotal = pledgeTotal.sub(amount);
    }
    
    
    
    
    
    function removeAtIndex(uint index) private {
        
        if (index < pledgeAddresses.length){
            
            uint size = pledgeAddresses.length - 1;
            for (uint i = index; i < size; i++) {
                pledgeAddresses[i] = pledgeAddresses[i + 1];
            }
     
            delete pledgeAddresses[size];
        
            pledgeAddresses.pop();
        }
     
        
    }
}