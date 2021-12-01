/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

interface IERC20Leven {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function airdrop(address _to, uint256 amount) external returns(bool);
    function presale(address _to, uint256 amount) external returns(bool);
    function getRemainPresalCnt() external view returns(uint256);
    function getRemainAirDropCnt() external view returns(uint256);
    function getAirdropStatus(address account) external view returns(bool);
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

contract ERC20Leven is Context, IERC20, Ownable {
    using Address for address;
    
    mapping (address => mapping (address => uint256)) private _allowances; // allowancement
    mapping (address => uint256) private balances; // user's balance
    
    mapping (address => bool) private airdropWallet; // flag for airdrop wallets
    mapping (address => uint256) private airdropBalance; // balance for airdrop wallets
    mapping (address => uint256) private airdropTime; // timestamp when get airdrop
    
    
    string private _name = "Leven Token";
    string private _symbol = "LEVEN";
    uint8 private _decimals = 18;
    string public version = "1.0";
    
    uint256 private _tDev = 25 * (10 ** 6) * (10 ** _decimals); // 25000000
    uint256 private _tAirDrop = 75 * (10 ** 6) * (10 ** _decimals); // 75000000
    uint256 private _tPresale = 1 * (10 ** 8) * (10 ** _decimals);
    uint256 private _tReserve = 8 * (10 ** 8) * (10 ** _decimals);
    uint256 public _tTotal = 1 * ( 10 ** 9 ) * (10 ** _decimals);
    
    uint256 private airdropLockTime = 60 * 60 * 24 * 365 * 1; // lock time for airdrop is one year.
    uint256 private devLockTime = 60 * 60 * 24 * 60;          // lock time for dev is 2 months.

    address private poolAccount = 0x9d37f958E959F3286e04cb52c942e1E8EF2C1298;
    uint256 private devTimeStamp = 0;
    
    // constructor for LVN token
    constructor () {
        balances[poolAccount] = _tDev;
        devTimeStamp = block.timestamp;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        if (account == address(0)) {
            return 0;
        }
        return balances[account];
    }
    
    function allowance(address _from, address _to) public view override returns (uint256) {
        return _allowances[_from][_to];
    }
    
    function _approve(address _from, address _to, uint256 amount) private {
        require(_from != address(0), "ERC20 approve from zero address");
        require(_to != address(0), "ERC20 approve from zero address");
        
        _allowances[_from][_to] = amount;
        Approval(_from, _to, amount);
    }
    
    function approve(address _to, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), _to, amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 amount) public override returns (bool) {
        if (balances[_from] < amount || 
            amount <= 0 || 
            _allowances[_from][_to] < amount) {
            return false;
        }

        if (lockingCheck(_from, amount) == false) {
            return false;
        }
        
        balances[_from] -= amount;
        balances[_to] += amount;
        Transfer(_from, _to, amount);
        _allowances[_from][_to] -= amount;
        
        return true;
    }

    function lockingCheck(address _from, uint256 amount) private returns (bool) {

        if ((balances[_from] - amount) < airdropBalance[_from]) {
            uint256 spentTime = block.timestamp - airdropTime[_from];
            if (spentTime < airdropLockTime) {
                return false;
            } else {
                airdropBalance[_from] = 0;
            }
        }

        if (_from == poolAccount) {
            if ((balances[_from] - amount) < _tDev) {
                uint256 spentTime = block.timestamp - devTimeStamp;
                if (spentTime < devLockTime) {
                    return false;
                } else {

                }
            }
        }

        return true;
    }
    
    function transfer(address _to, uint256 amount) public override returns (bool) {
        if (balances[msg.sender] < amount || 
            amount <= 0) {
            return false;
        }

        if (lockingCheck(msg.sender, amount) == false) {
            return false;
        }        
        
        balances[msg.sender] -= amount;
        balances[_to] += amount;
        Transfer(msg.sender, _to, amount);
        
        return true;
    }

    function airdrop(address _to, uint256 amount) public returns(bool) {
        if (airdropWallet[_to] == true || _to == address(0)) {
            return false;
        }

        balances[_to] += amount;
        airdropWallet[_to] = true;
        airdropBalance[_to] += amount;
        airdropTime[_to] = block.timestamp;
        _tAirDrop -= amount;
        
        
        return true;
    }

    function presale(address _to, uint256 amount) public returns(bool) {
        if (_tPresale <= 0 || _to == address(0) || amount <= 0) { // check the preslae balance
            return false;
        }
        
        if (_tPresale < amount) {
            amount = _tPresale;
        }
        
        balances[_to] += amount;
        _tPresale -= amount;
        
        return true;
    }

    function getRemainPresalCnt() public view returns(uint256) {
        return _tPresale;
    }
    
    function getRemainAirDropCnt() public view returns(uint256) {
        return _tAirDrop;
    }

    function getAirdropStatus(address account) public view returns(bool) {
        return airdropWallet[account];
    }
}