// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './interface/IERC20.sol';
import './interface/IUniswapV2Router02.sol';

library AddressArrayUtil {

  /** Finds the index of a given value in an array. */
  function IndexOf(address[] storage values, address value) internal view returns(uint) {
    uint index;
    uint i;
    for (i=0; i<values.length; i++){
        if (values[i] == value){
            index = i;
        }
    }
    return index;
  }

  /** Removes the given value in an array. */
  function RemoveByValue(address[] storage values, address value) internal {
    uint index = IndexOf(values, value);
    RemoveByIndex(values, index);
  }

  /** Removes the value at the given index in an array. */
  function RemoveByIndex(address[] storage values, uint index) internal {
    values[index] = values[values.length-1];
    values.pop();
  }
}


library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
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

contract MultiSigAccess {

  using AddressArrayUtil for address[];

  address[] public trustees;
  address[] public voted;
  address public beneficiary;
  address public tokenToSend;

  IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

  struct Trustee {
    bool canVote;
    bool hasVoted;
  }

  mapping (address => Trustee) public account;

  string public proposal;

  uint quorum = 55; //Quorum is a percentage needed to pass the vote.
  // quorum calculation = (votes*100)/trustees.length()

  uint disbursementAmount;

  bool nowVoting;

  constructor(address[] memory _initialTrustees){
      trustees = _initialTrustees;
  }


  modifier onlyTrustee(){
    require(account[msg.sender].canVote == true, "You are not a trustee.");
    _;
  }

  modifier voteLocked(){
      require(nowVoting == true, "Voting is not open.");
      _;
  }

  modifier voteNotLocked(){
      require(nowVoting == false, "Voting is already open.");
      _;
  }

  modifier onlyOneVote(){
      require(account[msg.sender].hasVoted == false, "You have already voted.");
      _;
  }

  function _clearProposalAndVotes() internal {
      for (uint i = 0; i<voted.length; i++){
        account[voted[i]].hasVoted = false;
      }
      delete voted;
      delete beneficiary;
      delete tokenToSend;
      delete disbursementAmount;
      delete proposal;
      nowVoting = false;
  }

  function clearProposalAndVotes() public onlyTrustee {
      _clearProposalAndVotes();
  }

  function proposeAddTrustee(address _beneficiary) external onlyTrustee voteNotLocked {
    //if hasVoted checks are populated, clear them.

    if(beneficiary != address(0)) {
      for (uint i = 0; i<voted.length; i++){
        account[voted[i]].hasVoted = false;
      }
      delete voted;
    }
    beneficiary = _beneficiary;
    nowVoting = true;
    proposal = "addTrustee";
  }

  function addTrustee(address _beneficiary) external onlyTrustee voteLocked onlyOneVote {
    //Check to see if user has already voted.
    //Check to see if user is confirming intialized values.
    //If number of votes >= quorum, perform transaction.
    require(
        keccak256(abi.encodePacked(proposal)) ==
        keccak256(abi.encodePacked("addTrustee")),
        "Wrong proposal intialized."
        );
    require(_beneficiary == beneficiary, "You have entered a non-proposed beneficiary.");
    account[msg.sender].hasVoted = true;
    voted.push(msg.sender);

    if ((voted.length*100)/trustees.length >= quorum){
      _clearProposalAndVotes();
      trustees.push(_beneficiary);
      account[_beneficiary].canVote = true;
    }
  }

  function proposeRemoveTrustee(address _beneficiary) external onlyTrustee voteNotLocked {

    if(beneficiary != address(0)) {
      for (uint i = 0; i<voted.length; i++){
        account[voted[i]].hasVoted = false;
      }
      delete voted;
    }
    beneficiary = _beneficiary;
    nowVoting = true;
    proposal = "removeTrustee";
  }

  function removeTrustee(address _beneficiary) external onlyTrustee voteLocked onlyOneVote {
    require(
        keccak256(abi.encodePacked(proposal)) ==
        keccak256(abi.encodePacked("removeTrustee")),
        "Wrong proposal intialized."
        );
    require(_beneficiary == beneficiary, "You have entered a non-proposed beneficiary.");
    account[msg.sender].hasVoted = true;
    voted.push(msg.sender);

    if ((voted.length*100)/trustees.length >= quorum){
      _clearProposalAndVotes();
      trustees.RemoveByValue(_beneficiary);
      account[_beneficiary].canVote = false;
    }
  }

  function proposeSendEth(address _beneficiary, uint _amount) external onlyTrustee voteNotLocked {

    if(beneficiary != address(0) || disbursementAmount != 0) {
      for (uint i = 0; i<voted.length; i++){
        account[voted[i]].hasVoted = false;
      }
      delete voted;
    }
    beneficiary = _beneficiary;
    disbursementAmount = _amount;
    nowVoting = true;
    proposal = "sendEth";
  }

  function sendEth(address _beneficiary, uint _amount) external onlyTrustee voteLocked onlyOneVote {
    require(
        keccak256(abi.encodePacked(proposal)) ==
        keccak256(abi.encodePacked("sendEth")),
        "Wrong proposal intialized."
        );
    require(_beneficiary == beneficiary, "You have entered a non-proposed beneficiary.");
    require(_amount == disbursementAmount, "You have entered a non-proposed transfer value.");
    account[msg.sender].hasVoted = true;
    voted.push(msg.sender);

    if ((voted.length*100)/trustees.length >= quorum){
      _clearProposalAndVotes();
      payable(_beneficiary).transfer(_amount);
    }
  }

  function proposeSendToken(address _beneficiary, address _token, uint _amount) external onlyTrustee voteNotLocked {

    if(beneficiary != address(0) || disbursementAmount != 0) {
      for (uint i = 0; i<voted.length; i++){
        account[voted[i]].hasVoted = false;
      }
      delete voted;
    }
    beneficiary = _beneficiary;
    tokenToSend = _token;
    disbursementAmount = _amount;
    nowVoting = true;
    proposal = "sendToken";
  }

  function sendToken(address _beneficiary, address _token, uint _amount) external onlyTrustee voteLocked onlyOneVote {
    require(
        keccak256(abi.encodePacked(proposal)) ==
        keccak256(abi.encodePacked("sendToken")),
        "Wrong proposal intialized."
        );
    require(_beneficiary == beneficiary, "You have entered a non-proposed beneficiary.");
    require(_token == tokenToSend, "You have entered a non-proposed token.");
    require(_amount == disbursementAmount, "You have entered a non-proposed transfer value.");
    account[msg.sender].hasVoted = true;
    voted.push(msg.sender);

    if ((voted.length*100)/trustees.length >= quorum){
      _clearProposalAndVotes();
      IERC20(_token).transfer(_beneficiary, _amount);
    }
  }

  receive() external payable {
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20Metadata.sol";

interface IERC20 is IERC20Metadata {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

