/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity 0.8.0;

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}



pragma solidity 0.8.0;

library Address {
  
    function isContract(address account) internal view returns (bool) {
     
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

  
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}



pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

  
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

  
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity 0.8.0;

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

  
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

  
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
      

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



pragma solidity 0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.8.0;


contract Whitelist is Ownable {

 // 1 => whitelisted; 0 => NOT whitelisted
  mapping (address => uint8) public whitelistedMap;

 // true => whitelist is activated; false => whitelist is deactivated
  bool public WhitelistStatus;
  
  event WhitelistStatusChanged(bool indexed Status);

  constructor() public{
    WhitelistStatus = true;
  }

  modifier Whitelisted() {
    require(whitelistedMap[msg.sender] == 1 || WhitelistStatus == false, 'You are not whitelisted');
  _;}

  function whitelistAddress(address[] calldata AddressList)
    public
    onlyOwner
  {
    uint j;
    for (j = 0; j < AddressList.length; ++j)
    {
    whitelistedMap[AddressList[j]] = 1;
    }
  }

  function blacklistAddress(address[] calldata AdressList)
    public
    onlyOwner
    
  {
    uint j;
    for (j = 0; j < AdressList.length; ++j)
    {
    whitelistedMap[AdressList[j]] = 2;
    }
  }

  function changeWhitelistStatus()
    public
    onlyOwner
  {
    if (WhitelistStatus == true){
      WhitelistStatus = false;
      emit WhitelistStatusChanged(false);
    }else{
      WhitelistStatus = true;
      emit WhitelistStatusChanged(true);
    }
  }
}
  


pragma solidity "0.8.0";

contract IFOV2 is Whitelist{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The LP token used
    IERC20 public lpToken;

    // The offering token
    IERC20 public offeringToken;

    // Number of pools
    uint8 public constant numberPools = 3;

    // The block number when IFO starts
    uint256 public startBlock;

    // The block number when IFO ends
    uint256 public endBlock;

    // Array of PoolCharacteristics of size numberPools
    PoolCharacteristics[numberPools] private _poolInformation;

    // It maps the address to pool id to UserInfo
    mapping(address => mapping(uint8 => uint256)) private amountPool;

    // Struct that contains each pool characteristics
    struct PoolCharacteristics {
        uint256 offeringAmountPool; // amount of tokens offered for the pool (in offeringTokens)
        // price in MGH/USDT => for 1 MGH/USDT price would be 10^12 
        // for Pool0 the price is set to priceA;
        // for Pool1 priceA is the higher bound (IN MGH/USDT) and priceB is the lower bound (IN MGH/USDT) of the price;
        // for Pool2 both prices can be set to 0
        uint256 priceA; 
        uint256 priceB; 
        uint256 totalAmountPool; // total amount pool deposited (in LP tokens)
    }

    // Deposit event
    event Deposit(address indexed user, uint256 amount, uint8 indexed pid);

    // Harvest event
    event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount, uint8 indexed pid);

    // Event for new start & end blocks
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);

    // Event when parameters are set for one of the pools
    event PoolParametersSet(uint256 offeringAmountPool, uint priceA_, uint priceB_, uint8 pid);

    constructor(
        IERC20 _lpToken,
        IERC20 _offeringToken,
        uint256 _startBlock,
        uint256 _endBlock,
        address _adminAddress
    ) public {
      //  require(_lpToken.totalSupply() >= 0);
      //  require(_offeringToken.totalSupply() >= 0);
      //  require(_lpToken != _offeringToken, "Tokens must be be different");

        lpToken = _lpToken;
        offeringToken = _offeringToken;
        startBlock = _startBlock;
        endBlock = _endBlock;
        transferOwnership(_adminAddress);
    }

    function depositPool(uint256 _amount, uint8 _pid) external {

        // Checks whether the pool id is valid
        require(_pid < numberPools, "Non valid pool id");

        // Checks that pool was set
        require(
            _poolInformation[_pid].offeringAmountPool > 0,
            "Pool not set"
        );

        // Checks whether the block number is not too early
        require(block.number > startBlock, "Too early");

        // Checks whether the block number is not too late
        require(block.number < endBlock, "Too late");

        // Checks that the amount deposited is not inferior to 0
        require(_amount > 0, "Amount must be > 0");

        // if its pool1, check if new total amount will be smaller or equal to "raisingAmount"
        if(_pid == 0){
          require(
            _poolInformation[_pid].offeringAmountPool.mul(_poolInformation[_pid].priceA) <= _poolInformation[_pid].totalAmountPool.add(_amount),
            'not enough Offering Tokens left in Pool1');
        }

        // Transfers funds to this contract
        lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        // Update the user status
        amountPool[msg.sender][_pid] = amountPool[msg.sender][_pid].add(_amount);

        // Updates the totalAmount for pool
        _poolInformation[_pid].totalAmountPool = _poolInformation[_pid].totalAmountPool.add(_amount);

        emit Deposit(msg.sender, _amount, _pid);
    }

    function harvestPool(uint8 _pid) external {
        // Checks whether it is too early to harvest
        require(block.number > endBlock, "Too early to harvest");

        // Checks whether pool id is valid
        require(_pid < numberPools, "Non valid pool id");

        // Checks whether the user has participated
        require(amountPool[msg.sender][_pid] > 0, "Did not participate");

        // check if not whitelisted and whitelist active
        if(whitelistedMap[msg.sender] != 1 && WhitelistStatus == true){
          uint amount = amountPool[msg.sender][_pid];
          amountPool[msg.sender][_pid] = 0;
          lpToken.safeTransfer(address(msg.sender), amount);
          emit Harvest(msg.sender, 0, amount, _pid);
        }else{

          // Initialize the variables for offering, refunding user amounts, and tax amount
          uint256 offeringTokenAmount;
          uint256 refundingTokenAmount;

          (offeringTokenAmount, refundingTokenAmount) = _calculateOfferingAndRefundingAmountsPool(
            msg.sender,
            _pid
          );

          amountPool[msg.sender][_pid] = 0;

          // Transfer these tokens back to the user if quantity > 0
          if (offeringTokenAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
          }

          if (refundingTokenAmount > 0) {
            lpToken.safeTransfer(address(msg.sender), refundingTokenAmount);
          }

          emit Harvest(msg.sender, offeringTokenAmount, refundingTokenAmount, _pid);
        }
    }

    function setPool(
        uint256 _offeringAmountPool,
        uint256 _priceA,
        uint _priceB,
        uint8 _pid
    ) external  onlyOwner {
        require(_pid < numberPools, "Pool does not exist");
   //     require(block.number > endBlock.add(1e5), 'wait 100000 blocks after endBlock');

        _poolInformation[_pid].offeringAmountPool = _offeringAmountPool;
        _poolInformation[_pid].priceA = _priceA;
        _poolInformation[_pid].priceB = _priceB;

        assert(viewtotalOfferingAmountPools() <= offeringToken.balanceOf(address(this)));

        emit PoolParametersSet(_offeringAmountPool, _priceA, _priceB, _pid);
    }

    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external onlyOwner {
    //    require(block.number > endBlock.add(1e5), 'wait 100000 blocks after endBlock');
        require(_startBlock < _endBlock, "New startBlock must be lower than new endBlock");
   //     require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        endBlock = _endBlock;

        emit NewStartAndEndBlocks(_startBlock, _endBlock);
    }

    function viewPoolInformation(uint256 _pid)
        external
        view
        
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _poolInformation[_pid].offeringAmountPool,
            _poolInformation[_pid].priceA,
            _poolInformation[_pid].priceB,
            _poolInformation[_pid].totalAmountPool
        );
    }

    function viewUserAllocationPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allocationPools = new uint256[](_pids.length);
        for (uint8 i = 0; i < _pids.length; i++) {
            allocationPools[i] = _getUserAllocationPool(_user, _pids[i]);
        }
        return allocationPools;
    }

    function viewUserAmount(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory amountPools = new uint256[](_pids.length);

        for (uint8 i = 0; i < numberPools; i++) {
            amountPools[i] = amountPool[_user][i];
        }
        return (amountPools);
    }

    function viewUserOfferingAndRefundingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[2][] memory)
    {
        uint256[2][] memory amountPools = new uint256[2][](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            uint256 userOfferingAmountPool;
            uint256 userRefundingAmountPool;

            if (_poolInformation[_pids[i]].offeringAmountPool > 0) {
                (
                    userOfferingAmountPool,
                    userRefundingAmountPool
                ) = _calculateOfferingAndRefundingAmountsPool(_user, _pids[i]);
            }

            amountPools[i] = [userOfferingAmountPool, userRefundingAmountPool];
        }
        return amountPools;
    }

    function _calculateOfferingAndRefundingAmountsPool(address _user, uint8 _pid)
        internal
        view
        returns (
            uint256,
            uint256
        )
    {
      uint256 userOfferingAmount;
      uint256 userRefundingAmount;
     // calculate for Pool1
      if (_pid == 0){
        userOfferingAmount = amountPool[_user][0].mul(_poolInformation[0].priceA);
        return (userOfferingAmount, 0);
      }

      uint256 allocation = _getUserAllocationPool(_user, _pid);
     // calculate for Pool3
      if (_pid == 2){
        userOfferingAmount = _poolInformation[2].offeringAmountPool.mul(allocation).div(1e12);
        return (userOfferingAmount, 0);
      }
     //calculate for Pool2
      // calculate userOfferingAmount, if priceA is reached then allocation*OfferingAmount, otherwise amountPool[user]*priceA
      if (_poolInformation[1].totalAmountPool.mul(_poolInformation[1].priceA) > _poolInformation[1].offeringAmountPool){
        userOfferingAmount = amountPool[_user][1].mul(allocation).div(1e12);
      }else{
        userOfferingAmount = amountPool[_user][1].mul(_poolInformation[1].priceA);
        return(userOfferingAmount, 0);
      }
      // calculate userRefundingAmount, if priceB is NOT reached then 0, otherwise allocation*totalAmountPool
      if (_poolInformation[1].totalAmountPool.mul(_poolInformation[1].priceB) <= _poolInformation[1].offeringAmountPool){
        userRefundingAmount = 0;
        return (userOfferingAmount, userRefundingAmount);
      }else{
        uint notcompensatedAmount = _poolInformation[1].totalAmountPool.sub(_poolInformation[1].offeringAmountPool.div(_poolInformation[1].priceB));
        userRefundingAmount = allocation.mul(notcompensatedAmount).div(1e12);
        return (userOfferingAmount, userRefundingAmount);
      }
    }

    function _getUserAllocationPool(address _user, uint8 _pid) internal view returns (uint256) {
        if (_poolInformation[_pid].totalAmountPool > 0) {
            return amountPool[_user][_pid].mul(1e18).div(_poolInformation[_pid].totalAmountPool.mul(1e6));
        } else {
            return 0;
        }
    }

    function viewtotalOfferingAmountPools() internal view returns(uint256){
        uint sum = 0;
        for (uint j = 0; j < numberPools; j++){
            sum = sum.add(_poolInformation[j].offeringAmountPool);
        }return sum;
    }

    function adminofferingdeposit(uint amount) external onlyOwner{
        offeringToken.safeTransferFrom(address(msg.sender), address(this), amount);
    }
}