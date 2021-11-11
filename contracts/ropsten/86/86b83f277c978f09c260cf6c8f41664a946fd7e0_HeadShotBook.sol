/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

contract HeadShotBook is Ownable, IERC20 {
    string private _name = "HeadShotBookTest";
    string private _symbol = "HSBT";

    uint256 _totalSupply = 1;
    uint256 nonce = 0;

    address public tokenAddress;

    struct TokenInfo {
        uint256 index;
        uint256 code;
        string name;
        string symbol;
        string desc;
        string logo;
        string chain;
        address creator;
        address scAddress;
        uint256 supply;
        uint256 marketCap;
        uint256 price;
        uint256 launch;
        uint256 created;
        uint256 updated;
        uint256 verified;
        uint256 votes;
        bool presale;
        uint status;
    }

    mapping (uint256 => TokenInfo) private tokenMap;
    TokenInfo[] tokenList;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    /*
    function getTokenInfo(uint256 code) public view returns (
        uint256,
        uint256,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        bool,
        uint
    ) {
        TokenInfo memory info = tokenMap[code];
        return (
        info.index,
        info.code,
        info.name,
        info.symbol,
        info.desc,
        info.logo,
        info.chain,
        info.creator,
        info.scAddress,
        info.supply,
        info.marketCap,
        info.price,
        info.launch,
        info.created,
        info.updated,
        info.verified,
        info.votes,
        info.presale,
        info.status
        );
    }
    
    function tokenRegister(
        string memory name_,
        string memory symbol_,
        string memory desc,
        string memory logo,
        string memory chain,
        address creator,
        address scAddress,
        uint256 supply,
        uint256 marketCap,
        uint256 price,
        uint256 launch,
        uint256 created,
        uint256 updated,
        uint256 verified,
        uint256 votes,
        bool presale,
        uint status
    ) private returns (bool){
        uint256 index = tokenList.length + 1;
        uint256 code = generateCode();
        TokenInfo memory info = TokenInfo(
            index,
            code,
            name_,
            symbol_,
            desc,
            logo,
            chain,
            creator,
            scAddress,
            supply,
            marketCap,
            price,
            launch,
            created,
            updated,
            verified,
            votes,
            presale,
            status
        );
        info.code = code;
        tokenMap[code] = info;
        tokenList.push(info);
        return true;
    }
    */
    
    function tokenUnregister(uint256 code) public returns (bool){
        require(code > 0, "SHOT: code can't 0");
        for (uint i = 0; i < tokenList.length; i++) {
            if (tokenList[i].code == code) {
                delete tokenList[i];
                return true;
            }
        }
        return false;
    }

    function tokenVote(uint256 code) public returns (bool){
        require(code > 0, "SHOT: code can't 0");
        //TokenInfo memory info = tokenMap[code];
        if (tokenMap[code].code == code){
            tokenMap[code].votes++;
        }
        return true;
    }

    function tokenUnvote(uint256 code) public returns (bool){
        require(code > 0, "SHOT: code can't 0");
        //TokenInfo memory info = tokenMap[code];
        if (tokenMap[code].code == code){
            tokenMap[code].votes--;
        }
        return true;
    }

    function tokenStatus(uint256 code, uint newStatus) public returns (bool){
        require(code > 0, "SHOT: code can't 0");
        TokenInfo memory info = tokenMap[code];
        if (tokenMap[code].code == code){
            info.status = newStatus;
            tokenMap[code].updated = block.timestamp;
        }
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return IERC20(tokenAddress).balanceOf(account);
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("RLOKI_DividendTracker: method not implemented");
    }

    function allowance(address, address) public pure override returns (uint256) {
        revert("RLOKI_DividendTracker: method not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("RLOKI_DividendTracker: method not implemented");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("RLOKI_DividendTracker: method not implemented");
    }

    function generateCode() private returns (uint256){
        uint result = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100;
        result = result + 1;
        nonce++;
        return uint256(result);
    }
}