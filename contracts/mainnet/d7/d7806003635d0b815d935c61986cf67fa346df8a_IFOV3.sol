/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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



contract Whitelist is Ownable {

 // 1 => whitelisted; 0 => NOT whitelisted
  mapping (address => uint8) public whitelistedMap;

 // true => whitelist is activated; false => whitelist is deactivated
  bool public WhitelistStatus;
  
  event WhitelistStatusChanged(bool indexed Status);

  constructor() {
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

contract IFOV3 is Whitelist{
    using SafeERC20 for IERC20;

    // The LP token used
    IERC20 public lpToken;

    // The offering token
    IERC20 public offeringToken;

    // Number of pools
    uint8 public constant numberPools = 3;

    uint public HarvestDelay;

    // The block number when IFO starts
    uint256 public startBlock;

    // The block number when IFO ends
    uint256 public endBlock;

    PoolCharacteristics[numberPools] private _poolInformation;

    mapping(address => mapping(uint8 => uint256)) private amountPool;

    struct PoolCharacteristics {
        uint256 offeringAmountPool; 
        uint256 priceA; 
        uint256 priceB; 
        uint256 totalAmountPool; 
    }

    event AdminWithdraw(uint256 amountLP, uint256 amountOfferingToken, uint256 amountWei);

    event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);

    event Deposit(address indexed user, uint256 amount, uint8 indexed pid);

    event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount, uint8 indexed pid);

    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);

    event PoolParametersSet(uint256 offeringAmountPool, uint priceA_, uint priceB_, uint8 pid);

    modifier TimeLock() {
        require(block.number > endBlock + 90000, 'Admin must wait before calling this function');
    _;}

    constructor(
        IERC20 _lpToken,
        IERC20 _offeringToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint _harvestdelay
    ) {
        lpToken = _lpToken;
        offeringToken = _offeringToken;
        startBlock = _startBlock;
        endBlock = _endBlock;
        HarvestDelay = _harvestdelay;
    }

    function depositPool(uint256 _amount, uint8 _pid) external {

        require(_pid < numberPools, "Non valid pool id");

        require(_poolInformation[_pid].offeringAmountPool > 0, "Pool not set");

        require(block.number > startBlock, "Too early");

        require(block.number < endBlock, "Too late");

        require(_amount > 0, "Amount must be > 0");


        if(_pid == 0){
          require(
            _poolInformation[_pid].offeringAmountPool >= (_poolInformation[_pid].totalAmountPool + (_amount)) * (_poolInformation[_pid].priceA),
            'not enough Offering Tokens left in Pool1');
        }

        lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        amountPool[msg.sender][_pid] += _amount;

        _poolInformation[_pid].totalAmountPool += _amount;

        emit Deposit(msg.sender, _amount, _pid);
    }

    function harvestPool(uint8 _pid) external {

        require(block.number > endBlock + HarvestDelay, "Too early to harvest");

        require(_pid < numberPools, "Non valid pool id");

        require(amountPool[msg.sender][_pid] > 0, "Did not participate");

        if(whitelistedMap[msg.sender] != 1 && WhitelistStatus == true){
          uint amount = amountPool[msg.sender][_pid];
          amountPool[msg.sender][_pid] = 0;
          lpToken.safeTransfer(address(msg.sender), amount);
          emit Harvest(msg.sender, 0, amount, _pid);
        }else{

          uint256 offeringTokenAmount;
          uint256 refundingTokenAmount;

          (offeringTokenAmount, refundingTokenAmount) = _calculateOfferingAndRefundingAmountsPool(
            msg.sender,
            _pid
          );

          amountPool[msg.sender][_pid] = 0;

          if (offeringTokenAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
          }

          if (refundingTokenAmount > 0) {
            lpToken.safeTransfer(address(msg.sender), refundingTokenAmount);
          }

          emit Harvest(msg.sender, offeringTokenAmount, refundingTokenAmount, _pid);
        }
    }

    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount, uint256 _weiAmount) external  onlyOwner TimeLock {
        require(_lpAmount <= lpToken.balanceOf(address(this)), "Not enough LP tokens");
        require(_offerAmount <= offeringToken.balanceOf(address(this)), "Not enough offering token");

        if (_lpAmount > 0) {
            lpToken.safeTransfer(address(msg.sender), _lpAmount);
        }

        if (_offerAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), _offerAmount);
        }

        if (_weiAmount > 0){
            payable(address(msg.sender)).transfer(_weiAmount);
        }

        emit AdminWithdraw(_lpAmount, _offerAmount, _weiAmount);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(lpToken), "Cannot be LP token");
        require(_tokenAddress != address(offeringToken), "Cannot be offering token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
    function setPool(
        uint256 _offeringAmountPool,
        uint256 _priceA,
        uint _priceB,
        uint8 _pid
    ) external  onlyOwner TimeLock {
        require(_pid < numberPools, "Pool does not exist");

        _poolInformation[_pid].offeringAmountPool = _offeringAmountPool;
        _poolInformation[_pid].priceA = _priceA;
        _poolInformation[_pid].priceB = _priceB;

        uint sum = 0;
        for (uint j = 0; j < numberPools; j++){
            sum += _poolInformation[j].offeringAmountPool;
        }
        require(sum <= offeringToken.balanceOf(address(this)),
        'cant offer more than balance');

        emit PoolParametersSet(_offeringAmountPool, _priceA, _priceB, _pid);
    }

    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external onlyOwner TimeLock {
        require(_startBlock < _endBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");
        for(uint j = 0; j < numberPools; j++){
            _poolInformation[j].totalAmountPool = 0;
        }
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
      if(amountPool[_user][_pid] == 0){
        return(0, 0);
      }

      uint256 userOfferingAmount;
      uint256 userRefundingAmount;
      if (_pid == 0){
        userOfferingAmount = amountPool[_user][0] * (_poolInformation[0].priceA);
        return (userOfferingAmount, 0);
      }

      uint256 allocation = _getUserAllocationPool(_user, _pid);
      if (_pid == 2){
        userOfferingAmount = _poolInformation[2].offeringAmountPool * (allocation) / (1e12);
        return (userOfferingAmount, 0);
      }
      if (_poolInformation[1].totalAmountPool * (_poolInformation[1].priceA) > _poolInformation[1].offeringAmountPool){
        userOfferingAmount = _poolInformation[1].offeringAmountPool * (allocation) / (1e12);
      }else{
        userOfferingAmount = amountPool[_user][1] * (_poolInformation[1].priceA);
        return(userOfferingAmount, 0);
      }
      if (_poolInformation[1].totalAmountPool * (_poolInformation[1].priceB) <= _poolInformation[1].offeringAmountPool){
        return (userOfferingAmount, 0);
      }else{
        uint notcompensatedAmount = _poolInformation[1].totalAmountPool - (_poolInformation[1].offeringAmountPool / (_poolInformation[1].priceB));
        userRefundingAmount = allocation * (notcompensatedAmount) / (1e12);
        return (userOfferingAmount, userRefundingAmount);
      }
    }

    function _getUserAllocationPool(address _user, uint8 _pid) internal view returns (uint256) {
        if (_poolInformation[_pid].totalAmountPool > 0) {
            return amountPool[_user][_pid] * (1e12) / _poolInformation[_pid].totalAmountPool;
        } else {
            return 0;
        }
    }
    function SetHarvestDelay(uint _HarvestDelay) external onlyOwner {
        require( _HarvestDelay < 90000, 'max delay is 90000 blocks');
        HarvestDelay = _HarvestDelay;
    }
    fallback() external payable{}
}