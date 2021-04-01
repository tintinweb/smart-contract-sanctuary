/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
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


pragma experimental ABIEncoderV2;


contract Erc20TokenFaucet is Ownable {
    using Address for address;

    struct TokenConfig {
        address underlying;
        string  symbol;
        uint    numPerRequest;
    }

    // configs mapped by underlying address
    TokenConfig[] public configurations;

    uint public withdrawInterval = 10 minutes;

    mapping(address => uint) public antiAbuseTimeMap;

    modifier antiAbuse(){
        require(block.timestamp > (antiAbuseTimeMap[msg.sender] + withdrawInterval), 
                "each address can only drip every 10 minutes");
        _;
        antiAbuseTimeMap[msg.sender] = block.timestamp;
    }

    function addConfig(address underlying_, string memory symbol_, uint numPerRequest_) public onlyOwner {
        uint index = findTokenConfigIndexByUnderlying(underlying_);
        require(index == uint(-1), "token config already exists");
        TokenConfig memory config = TokenConfig({underlying : underlying_, symbol : symbol_, numPerRequest : numPerRequest_});
        configurations.push(config);
    }

    function removeConfigByUnderlying(address underlying) public onlyOwner {
        uint index = findTokenConfigIndexByUnderlying(underlying);
        require(index != uint(-1), "token config not found");
        configurations[index] = configurations[configurations.length -1];
        configurations.pop();
    }

    // @notice withdraw all the tokens to owner
    function destroyFaucet() public onlyOwner {
        for (uint i = 0; i < configurations.length; i++) {
            emptyTokenByConfigIndex(i);
        }
        delete configurations;
    }

    // @notice withdraw all the tokens to owner
    function emptyTokenByUnderlying(address underlying) public onlyOwner {
        uint index = findTokenConfigIndexByUnderlying(underlying);
        require(index != uint(-1), "token config not found");
        IERC20 erc20 = IERC20(configurations[index].underlying);
        uint supply = erc20.balanceOf(address(this));
        _callOptionalReturn(erc20, abi.encodeWithSelector(erc20.transfer.selector, owner(), supply));
    }

    // @notice withdraw all the tokens to owner
    function emptyTokenByConfigIndex(uint index) internal onlyOwner {
        IERC20 erc20 = IERC20(configurations[index].underlying);
        _callOptionalReturn(erc20, abi.encodeWithSelector(erc20.transfer.selector, owner(), erc20.balanceOf(address(this))));

    }

    function findTokenConfigIndexByUnderlying(address underlying) public view returns (uint){
        for (uint i = 0; i < configurations.length; i++) {
            TokenConfig memory config = configurations[i];
            if (config.underlying == underlying) {
                return i;
            }
        }
        return uint(-1);
    }

    function compareString(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function findTokenConfigIndexBySymbol(string memory symbol) public view returns (uint){
        for (uint i = 0; i < configurations.length; i++) {
            TokenConfig memory config = configurations[i];            
            if(compareString(config.symbol, symbol) == true) {
                return i;
            }
            
        }
        return uint(-1);
    }

    function requestWithdraw(string memory symbol) public antiAbuse {
        uint index = findTokenConfigIndexBySymbol(symbol);
        require(index != uint(-1), "token config not found");
        TokenConfig memory config = configurations[index];
        IERC20 erc20 = IERC20(config.underlying);
        uint supply = erc20.balanceOf(address(this));
        uint amount = supply > config.numPerRequest ? config.numPerRequest : supply;
        require(amount > 0, "not enough left");

        erc20.transfer(msg.sender, amount);
    }

    function requestAll() public antiAbuse {
        for (uint index = 0; index < configurations.length; index++) {
            TokenConfig memory config = configurations[index];
            IERC20 erc20 = IERC20(config.underlying);
            uint supply = erc20.balanceOf(address(this));
            uint amount = supply > config.numPerRequest ? config.numPerRequest : supply;
            if (amount > 0) {
                _callOptionalReturn(erc20, abi.encodeWithSelector(erc20.transfer.selector, msg.sender, amount));
            }
        }
    }

    function donate(string memory symbol, uint amount) public {
        require(amount > 0, "invalid donation");
        uint index = findTokenConfigIndexBySymbol(symbol);
        require(index != uint(-1), "token config not found");
        TokenConfig memory config = configurations[index];
        IERC20 erc20 = IERC20(config.underlying);
        _callOptionalReturn(erc20, abi.encodeWithSelector(erc20.transferFrom.selector, msg.sender, address(this), amount));
    }

    function setWithdrawInterval(uint256 _interval) external onlyOwner {
        withdrawInterval = _interval;
    }

    // handles non-standard token like USDT
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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