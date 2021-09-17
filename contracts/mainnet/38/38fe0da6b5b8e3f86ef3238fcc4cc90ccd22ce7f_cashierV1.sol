/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


contract owned {
    address public owner;
    address public auditor;

    constructor() {
        owner = msg.sender;
        auditor = 0x241A280362b4ED2CE8627314FeFa75247fDC286B;
    }

    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == auditor);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
// library from openzeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
// library from openzeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol)
library SafeERC20 {
    using Address for address;

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract cashierV1 is owned {
    using SafeERC20 for IERC20;
    string public name;
    bool public online = true;
    address public bucks;
    address public blcks;
    uint256 public period;
    address public mainWallet = msg.sender;
    uint256 public APY = 14;

    struct deposits{
        uint256 amount;
        bool payed;
        uint256 date;
    }

    mapping (address => deposits[]) public investments;

    event SwapToUSDT(address indexed beneficiary, uint256 value);
    
    event SwapToBLACKT(address indexed beneficiary, uint256 value);
 
    event IsOnline(bool status);

    
    constructor(
        string memory Name,
        address initialBucks,
        address initialBlcks,
        uint256 initialPeriod
    ) {           
        name = Name;                                   
        bucks = initialBucks;
        blcks = initialBlcks;
        period = initialPeriod;
    }

    
    function USDtoBLACKT( uint256 value) public returns (bool success) {
        BLACKT b0 = BLACKT(blcks);
        IERC20 b1 = IERC20(bucks);
        require(online);
        b1.safeTransferFrom(msg.sender,mainWallet,value);
        b0.transferFrom(mainWallet,msg.sender,value);
        emit SwapToBLACKT(msg.sender,value);
        return true;
    }

    function BLACKTtoUSD(uint256 value) public returns (bool success) {
        BLACKT b0 = BLACKT(blcks);
        IERC20 b1 = IERC20(bucks);
        require(online);
        b0.transferFrom(msg.sender,mainWallet,value);
        b1.safeTransferFrom(mainWallet,msg.sender,value);
        emit SwapToUSDT(msg.sender,value);
        
        return true;
    }

    function AutoInvestUSD(uint256 investment) public returns (bool success) {
        BLACKT b0 = BLACKT(blcks);
        IERC20 b1 = IERC20(bucks);
        require(online);
        b1.safeTransferFrom(msg.sender,mainWallet,investment);
        b0.lockLiquidity(msg.sender, investment);   
        investments[msg.sender].push(deposits(investment,false,block.timestamp));
        return true;
    }

    function AutoUnlock() public returns (bool success) {
        require(online);
        BLACKT b = BLACKT(blcks);
        for (uint256 j=0; j < investments[msg.sender].length; j++){
            if (block.timestamp-investments[msg.sender][j].date>period && !investments[msg.sender][j].payed) {
                if (b.unlockLiquidity(msg.sender, investments[msg.sender][j].amount)) {
                    b.transferFrom(mainWallet,msg.sender,investments[msg.sender][j].amount*APY/100);
                    investments[msg.sender][j].payed = true;
                }
            }
        }
        return true;
    }

    function zChangeAPY(uint256 newAPY) onlyOwner public returns (bool success) {
        APY = newAPY;
        return true;
    }

    function zChangePeriod(uint256 newPeriod) onlyOwner public returns (bool success) {
        period = newPeriod;
        return true;
    }

    function zChangeBucks(address newBucks) onlyOwner public returns (bool success) {
        bucks = newBucks;
        return true;
    }

    function zChangeBlcks(address newBlcks) onlyOwner public returns (bool success) {
        blcks = newBlcks;
        return true;
    }

    function zChangeOnlineState(bool state) onlyOwner public returns (bool success) {
        online = state;
        return true;
    }

    function zChangeMainWallet(address newWallet) onlyOwner public returns (bool success) {
        mainWallet = newWallet;
        return true;
    }
}

interface BLACKT {
    function transferFrom(address from, address to, uint value) external returns (bool);
    function lockLiquidity(address _beneficiary, uint256 _value) external returns (bool);
    function unlockLiquidity(address _beneficiary, uint _value) external returns (bool);
}

interface IERC20 {
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}