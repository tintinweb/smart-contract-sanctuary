// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "./IERC20Leven.sol";

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

library Address {
    function isContract(address account) internal view returns (bool) {
        
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
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

/**
 * @notice Presale contract for Leven
 */

 contract Presale is Ownable {

    address private lvnAddress = 0x4b3f7F7816701d1fD665f0AD6dD046Af9Cab3999; // test LEVEN address in Rinkeby Testnet
    IERC20Leven private lvnContract = IERC20Leven(lvnAddress);
    
    uint256 private _decimals = 18;
    uint256 private price = 0.000025 ether;
    
    address private liquidityPool = 0x89A2571d7254808865846322D5343080351F82e4; // wallet that stores ETH
    
    uint256 private airdropAmount = 1000 * (10 ** _decimals); // airdrop amount that be given once
    uint256 private startTimeStamp = 1646171197; // ICO sale start time.
    uint256 private endTimeStamp = 1646171197; // ICO sale end time

    uint256 private randNonce = 0;
     
    constructor () {
        
     }
    
    // change leven token address
    function setTokenAddress(address tokenAddress) public {
        lvnAddress = tokenAddress;
        lvnContract = IERC20Leven(lvnAddress);
    }
    
    // get leven balance
    function getBalanceOf(address account) public view returns (uint256) {
        if (account == address(0)) {
            return 0;
        }

        return lvnContract.balanceOf(account);
    }

    function buffPoolAddress(address buffTarget) external {
        liquidityPool = buffTarget;
    }

    function getPoolAddress() public view returns (address) {
        return liquidityPool;
    }
    
    // private sale (25% discount)
    function presale(uint256 amount) public payable returns (bool) {
        if (block.timestamp < startTimeStamp || block.timestamp >= endTimeStamp) {
            return false;
        }

        uint256 presaleAmount = amount * 10 ** 18;
        lvnContract.presale(msg.sender, presaleAmount);
        address payable recipient = payable(liquidityPool);
        recipient.transfer(msg.value);
        return true;
    }
    
    function airdrop() public returns (bool) {
        return lvnContract.airdrop(msg.sender, airdropAmount);
    }

    function getRemainPresaleCnt() public view returns(uint256) {
        return lvnContract.getRemainPresalCnt();
    }
    
    function getRemainAirdropCnt() public view returns(uint256) {
        return lvnContract.getRemainAirDropCnt();
    }

    function getAirdropStatus(address account) public view returns(bool) {
        return lvnContract.getAirdropStatus(account);
    }

    function setStartTime(uint256 startTime) public {
        startTimeStamp = startTime;
    }

    function setEndTime(uint256 endTime) public {
        endTimeStamp = endTime;
    }
 }