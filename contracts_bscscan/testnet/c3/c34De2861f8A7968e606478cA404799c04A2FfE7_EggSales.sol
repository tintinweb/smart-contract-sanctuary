/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

abstract contract TokenRecover is Ownable {
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function mint(address to) external;
    function totalSupply() external view returns (uint256);
}

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
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



contract EggSales is Ownable, TokenRecover, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    uint256 public CHARACTER_MAX_SUPPLY = 1000000;
    uint256 public MINT_PRICE;
    uint256 public TOTAL_SUPPLY = 0;
    uint256 public MAX_EVOLUTION_STATE = 2;
    address public DESTINATION_ADDRESS;
    
    
    IERC20 public TOKEN;
    IERC721 public FACTORY;
    
    uint public STAMINA_MAX_CAP = 15;
    uint public STAMINA_PER_BATTLE = 3;
    uint256 public STAMINA_RECHARGE_DURATION = 7200; // 2 HOURS
    
    struct Character {
        uint stamina;
        uint256 stamina_timestamp;
        uint evolution_state;
        uint level;
    }
    
    mapping (uint256 => Character) public characterOf;
    mapping (address => bool) public gameMaster;
    
    event Mint(address indexed account, uint256 id);
    event Evolve(uint256 id, uint level);

    constructor(address _token, address _factory, uint256 _price, address _destination, address _gm) {
        TOKEN = IERC20(_token);
        FACTORY = IERC721(_factory);
        MINT_PRICE = _price;
        DESTINATION_ADDRESS = _destination;
        gameMaster[msg.sender] = true;
        gameMaster[_gm] = true;
    }
    
    modifier gameMasterOnly(address _address) {
        require(gameMaster[msg.sender], "Address is not game master.");
        _;
    }
    
    function setGameMaster(address _address) external onlyOwner {
        gameMaster[_address] = true;
    }
    
    function setToken(address _token) external onlyOwner {
        TOKEN = IERC20(_token);
    }
    
    function setFactory(address _factory) external onlyOwner {
        FACTORY = IERC721(_factory);
    }
    
    function setPrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
    }
    
    function mint() external whenNotPaused {
        
        require(TOKEN.balanceOf(msg.sender) >= MINT_PRICE, "Insufficient token balance.");
        require(TOKEN.allowance(msg.sender, address(this)) >= MINT_PRICE, "Insufficient token allowance.");
        require((TOTAL_SUPPLY + 1) <= CHARACTER_MAX_SUPPLY, "Booking closed.");
        
        TOTAL_SUPPLY += 1;
        TOKEN.safeTransferFrom(msg.sender, DESTINATION_ADDRESS, MINT_PRICE);
        
        uint256 card = FACTORY.totalSupply();
        characterOf[card].stamina = STAMINA_MAX_CAP;
        characterOf[card].stamina_timestamp = block.timestamp;
        characterOf[card].evolution_state = 0;
        characterOf[card].level = 0;
        FACTORY.mint(msg.sender);
        
        emit Mint(msg.sender, card);
    }
    
    function staminaOf(uint256 _nftId) public view returns (uint) {
        if(characterOf[_nftId].stamina_timestamp > block.timestamp) {
            uint256 time_diff = characterOf[_nftId].stamina_timestamp - block.timestamp;
            uint replenish_stamina = time_diff / STAMINA_RECHARGE_DURATION;
            if((replenish_stamina * STAMINA_RECHARGE_DURATION) < time_diff) {
                replenish_stamina += 1;
            }
            uint current_stamina = STAMINA_MAX_CAP - replenish_stamina;
            return current_stamina;
        }
        return STAMINA_MAX_CAP;
    }
    
    function battle(uint256 _nftId) external whenNotPaused gameMasterOnly(msg.sender) {
        if(block.timestamp > characterOf[_nftId].stamina_timestamp) {
            characterOf[_nftId].stamina_timestamp = block.timestamp + (STAMINA_RECHARGE_DURATION * STAMINA_PER_BATTLE);
        } else {
            characterOf[_nftId].stamina_timestamp = characterOf[_nftId].stamina_timestamp + (STAMINA_RECHARGE_DURATION * STAMINA_PER_BATTLE);
        }
        characterOf[_nftId].stamina = staminaOf(_nftId);
    }
    
    function evolve(uint256 _nftId) external whenNotPaused nonReentrant gameMasterOnly(msg.sender) {
        require(characterOf[_nftId].evolution_state <= MAX_EVOLUTION_STATE, "Character reached max evolution");
        characterOf[_nftId].evolution_state += 1;
        emit Evolve(_nftId, characterOf[_nftId].evolution_state);
    }
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    

}