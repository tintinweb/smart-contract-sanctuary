/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

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

contract GuildMachine is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public FCBToken;

    uint256 public Guild_Creation_Fee = 5 * 1E18;
    uint256 public Guild_Utility_Fee = 1 * 1E18;

    struct Guild {
        string guild_id;
        uint role;
    }

    mapping (address => Guild) public guilds;

    event GuildCreation(address indexed account, uint256 fee, string guildId);

    constructor(address _fcb) {
        FCBToken = IERC20(_fcb);
    }
    
    function guildIdOf(address _account) public view returns (string memory) {
        string memory g = guilds[_account].guild_id;
        return g;
    }

    function roleOf(address _account) public view returns (uint) {
        return guilds[_account].role;
    }

    function setFCBToken(address _fcb) external onlyOwner {
        FCBToken = IERC20(_fcb);
    }

    function setGuildFee(uint256 _creation, uint256 _utility) external onlyOwner {
        Guild_Creation_Fee = _creation;
        Guild_Utility_Fee = _utility;
    }
    
    function createGuild(string calldata _guild_id) external {
        require(FCBToken.balanceOf(msg.sender) >= Guild_Creation_Fee , "Insufficient balance.");
        require(FCBToken.allowance(msg.sender, address(this)) >= Guild_Creation_Fee , "Insufficient allowance.");  
        string memory empty = "";
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(empty)), "Caller already joined a guild.");
        guilds[msg.sender].guild_id = _guild_id;
        guilds[msg.sender].role = 0;  
        FCBToken.safeTransferFrom(msg.sender, address(this), Guild_Creation_Fee);
        emit GuildCreation(msg.sender, Guild_Creation_Fee, _guild_id);
    }

    function joinGuild(string calldata _guild_id) external {
        require(FCBToken.balanceOf(msg.sender) >= Guild_Utility_Fee , "Insufficient balance.");
        require(FCBToken.allowance(msg.sender, address(this)) >= Guild_Utility_Fee , "Insufficient allowance.");  
        string memory empty = "";
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(empty)), "Caller already joined a guild.");
        guilds[msg.sender].guild_id = _guild_id;
        guilds[msg.sender].role = 3;
        FCBToken.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }

    function approveGuildMember(address _account, string calldata _guild_id) external {
        require(FCBToken.balanceOf(msg.sender) >= Guild_Utility_Fee  , "Insufficient balance.");   
        require(FCBToken.allowance(msg.sender, address(this)) >= Guild_Utility_Fee , "Insufficient allowance.");    
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(_guild_id)), "Wrong guild.");
        require(keccak256(bytes(guilds[_account].guild_id)) == keccak256(bytes(_guild_id)), "Member does not request for this guild.");
        require(guilds[msg.sender].role <= 1, "Leader or co-leader permission required.");
        guilds[_account].guild_id = _guild_id;
        guilds[_account].role = 2;
        FCBToken.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }

    function promoteGuildMember(address _account, string calldata _guild_id) external {
        require(FCBToken.balanceOf(msg.sender) >= Guild_Utility_Fee  , "Insufficient balance.");   
        require(FCBToken.allowance(msg.sender, address(this)) >= Guild_Utility_Fee , "Insufficient allowance.");    
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(_guild_id)), "Wrong guild.");  
        require(guilds[msg.sender].role <= 1, "Leader or co-leader permission required.");
        require(guilds[msg.sender].role < guilds[_account].role, "Higher role required.");
        if (guilds[_account].role > 0) {
            guilds[_account].role = guilds[_account].role - 1;
        }
        FCBToken.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }


    function demoteGuildMember(address _account, string calldata _guild_id) external {
        require(FCBToken.balanceOf(msg.sender) >= Guild_Utility_Fee  , "Insufficient balance.");   
        require(FCBToken.allowance(msg.sender, address(this)) >= Guild_Utility_Fee , "Insufficient allowance.");    
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(_guild_id)), "Wrong guild.");  
        require(guilds[msg.sender].role <= 1, "Leader or co-leader permission required.");
        require(guilds[msg.sender].role < guilds[_account].role, "Higher role required.");
        if (guilds[_account].role < 2) {
            guilds[_account].role = guilds[_account].role + 1;
        }
        FCBToken.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }

    function kickGuildMember(address _account, string calldata _guild_id) external {
        require(FCBToken.balanceOf(msg.sender) >= Guild_Utility_Fee  , "Insufficient balance.");   
        require(FCBToken.allowance(msg.sender, address(this)) >= Guild_Utility_Fee , "Insufficient allowance.");    
        require(keccak256(bytes(guilds[msg.sender].guild_id)) == keccak256(bytes(_guild_id)), "Wrong guild.");  
        require(guilds[msg.sender].role <= 1, "Leader or co-leader permission required.");
        require(guilds[msg.sender].role < guilds[_account].role, "Higher role required.");
        guilds[_account].guild_id = "";
        guilds[_account].role = 4;
        FCBToken.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }

    function leaveGuildMember() external {
        require(FCBToken.balanceOf(msg.sender) >= Guild_Utility_Fee  , "Insufficient balance.");   
        require(FCBToken.allowance(msg.sender, address(this)) >= Guild_Utility_Fee , "Insufficient allowance.");   
        string memory empty = "";
        require(keccak256(bytes(guilds[msg.sender].guild_id)) != keccak256(bytes(empty)), "Wrong guild.");  
        guilds[msg.sender].guild_id = "";
        guilds[msg.sender].role = 4;
        FCBToken.safeTransferFrom(msg.sender, address(this), Guild_Utility_Fee);
    }



}