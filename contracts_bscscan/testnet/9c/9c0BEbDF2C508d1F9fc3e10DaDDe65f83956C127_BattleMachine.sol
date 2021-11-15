/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

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


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract TokenRecover is Ownable {
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Pausable is Context {

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function mint(address to) external;
    function totalSupply() external view returns (uint256);
}


contract BattleMachine is Ownable, Pausable, TokenRecover, ReentrancyGuard {
    
    
    using SafeERC20 for IERC20;
    using Roles for Roles.Role;
    Roles.Role private gameMaster;
    
    uint256 public NORMAL_BATTLE_FEE = 0.001 * 1E18;
    
    IERC20 public FCBToken;
    IERC721 public Factory;
    
    event Battle(address indexed account, string id, uint256 nftId, uint256 fee); 
    event SendReward(address indexed gameMaster, address indexed account, uint256 reward);
    
    constructor(address _fcb, address _factory) {
        FCBToken = IERC20(_fcb);
        Factory = IERC721(_factory);
        gameMaster.add(msg.sender);
    }
    
    function battle(string calldata _id, uint256 _nftId) external payable {
        
        require(msg.value >= NORMAL_BATTLE_FEE, "Insufficient fee");
        (bool success,) = address(this).call{value: NORMAL_BATTLE_FEE}("");
        require(success, "Failed to send Ether");
        require(Factory.ownerOf(_nftId) == msg.sender, "Caller is not NFT Owner.");
        
        emit Battle(msg.sender, _id, _nftId, NORMAL_BATTLE_FEE);
        
    }
    
    function withdrawBNB(address _account) external onlyOwner {
        (bool success,) = _account.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }
    
    function useFaucet(address[] calldata _account, uint256 amount) external {
        require(gameMaster.has(msg.sender), "Need Game Master Role.");
        
        for(uint i=0; i<_account.length; i++){
            require(gameMaster.has(_account[i]), "Only Send to Game Master.");
            (bool success,) = _account[i].call{value: amount}("");
            require(success, "Failed to send Ether");
        }
    }
    
    function isGameMaster(address _account) public view returns (bool) {
        return gameMaster.has(_account);
    }
    
    function setGameMaster(address[] calldata _account, bool _permission) external onlyOwner {
        if (_permission) {
            for(uint i=0; i<_account.length; i++){
                gameMaster.add(_account[i]);    
            }
        } else {
            for(uint i=0; i<_account.length; i++){
                gameMaster.remove(_account[i]);    
            }
        }
    }
    
    receive() external payable { }
    
    
    function distributeReward(address account, uint256 amount) external {
        require(gameMaster.has(msg.sender), "Need Game Master Role.");
        require(amount > 0, "Require more than 0");
        require(FCBToken.balanceOf(address(this)) >= amount, "Insufficient FCB balance in contract.");
        
        FCBToken.safeTransfer(account, amount);
        emit SendReward(msg.sender, account, amount);
    }
    
}