/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

library SecureMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((z = x + y) >= x == (y >= 0)), 'Addition error noticed! For safety reasons the operation has been reverted.');}
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((z = x - y) <= x == (y >= 0)), 'Subtraction error noticed! For safety reasons the operation has been reverted.');}
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((x == 0) || ((z = x * y) / x == y)), 'Multiplication error noticed! For safety reasons the operation has been reverted.');}
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {require((y != 0) && ((z = x / y) >= 0), 'Division error noticed! For safety reasons the operation has been reverted.');}
    function mod(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((((x >= 0) && (y >= 0) && (z = x % y) < y))), 'Modulo error noticed! For safety reasons the operation has been reverted.');}
}

library AddressSecurity {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
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

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {return returndata;} else {
            if (returndata.length > 0) {assembly {let returndata_size := mload(returndata) revert(add(32, returndata), returndata_size)}} else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address wallet) external view returns (uint256);
 }

contract AKITTEN is IERC20{ // modify
    using SecureMath for uint256;
    using AddressSecurity for address;
    
    mapping(address => uint256) private balance_mapping;
    mapping(address => mapping(address => uint256)) private allowance_mapping;
    
    string private name = "DOGGO"; // modify
    string private symbol = "DOGGO-TKN"; // modify
    
    address public crypto_owner = msg.sender; // modify
    address public developer = msg.sender; // modify

    uint private immutable decimals = 18; // modify
    uint private totalSupply = 1000000000000 * 10 ** 18; // modify
    uint private immutable CappedSupply = 1000000000000 * 10 ** 18; // modify
    
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(uint256 amount);
    event Mint(address wallet, uint256 amount);
    event Timelock(address wallet, uint256 increase_timelock_by_how_many_days);
    
    //DECLARATION
    
    constructor() {
        balance_mapping[crypto_owner] = totalSupply.mul(965).div(1000);
        balance_mapping[developer] = totalSupply.mul(35).div(1000);
    }
    
    //TRADE
    
    function allowance(address owner, address spender) public view override returns (uint256) {
            return allowance_mapping[owner][spender];
        }
        
    function balanceOf(address owner) public view override returns(uint256) {
        return balance_mapping[owner];
    }
    
    function transfer(address recipient, uint256 value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "Account balance is too low.");
        require(timelock_state(msg.sender) == true, "Your wallet is currently timelocked.");
        balance_mapping[recipient] = balance_mapping[recipient].add(value);
        balance_mapping[msg.sender] = balance_mapping[msg.sender].sub(value);
        emit Transfer(msg.sender, recipient, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(balanceOf(from) >= value, "Acount balance is too low");
        require(allowance_mapping[from][msg.sender] >= value, "Allowance limit is too low");
        require(timelock_state(from) == true, "Your wallet is currently timelocked.");
        balance_mapping[to] = balance_mapping[to].add(value);
        balance_mapping[from] = balance_mapping[from].sub(value);
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance_mapping[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;   
    }
        
    //BURN
    
    function burn(uint256 amount) public returns (bool) {
        require(balance_mapping[msg.sender] >= amount, "You can't burn more tokens than you own!");
        require(timelock_state(msg.sender) == false, "Your wallet is currently timelocked");
        balance_mapping[msg.sender] = balance_mapping[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Burn(amount);
        return true;
    }
    
    //MINT
    
    function mint(address wallet, uint256 amount) public returns (bool) {
        require(crypto_owner == msg.sender, "Only the owner can mint more tokens!");
        require(totalSupply.add(amount) <= CappedSupply, "You aren't allowed to mint more than the capped Supply maximum!");
        totalSupply = totalSupply.add(amount);
        balance_mapping[wallet] = balance_mapping[wallet].add(amount);
        balance_mapping[developer] = amount.mul(3).div(100).add(balance_mapping[developer]);
        emit Mint(wallet, amount);
        return true;
    }

    //TIMELOCK
    
    mapping (address => uint256) private time;
    
    function is_this_wallet_timelocked(address wallet) public view returns(string memory) {
        if (time[wallet]==0) {return "This wallet is not timelocked.";}
        else if (time[wallet]!=0) {return "This wallet is timelocked.";}
        else {return "An error occured in is_this_wallet_timelocked(), please contact the dev team.";}
    }
    
    function timelock_state(address wallet) public view returns (bool state) {
        if (time[wallet]==0) {return false;}
        else if (time[wallet]!=0) {return true;}
    }
    
    function increase_timelock_duration(address wallet, uint256 increase_timelock_by_how_many_days) public returns (bool){
        require(wallet == msg.sender, "You aren't allowed to timelock other wallets!");
        time[wallet]=time[wallet].add(block.timestamp).add((increase_timelock_by_how_many_days*86400));
        emit Timelock(wallet, increase_timelock_by_how_many_days);
        return true;
    }
    
    function read_timelock_duration(address wallet) public view returns(uint256 remaining_days_in_timelock, uint256 remaining_hours_in_timelock, uint256 remaining_minutes_in_timelock, uint256 remaining_seconds_in_timelock){
        require(time[wallet]>0, "This wallet is not currently timelocked");
        remaining_days_in_timelock = (time[wallet].sub(block.timestamp)).div(86400); 
        remaining_hours_in_timelock = (time[wallet].sub(block.timestamp)).mod(86400).div(3600);
        remaining_minutes_in_timelock = (time[wallet].sub(block.timestamp)).mod(3600).div(60);
        remaining_seconds_in_timelock = (time[wallet].sub(block.timestamp)).mod(60);
        return (remaining_days_in_timelock, remaining_hours_in_timelock, remaining_minutes_in_timelock, remaining_seconds_in_timelock);
    }
}