// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableCustom.sol";
import "./ERC20.sol";  
import "./SafeMath.sol"; 

contract FeeCollector is OwnableCustom {
    using SafeMath for uint256;

    event SetFee(uint256 fee);
    event SetFeeByMultisig(address indexed multisigAddress, uint256 fee);
    event SetFeeCollector(address indexed feeCollector);
    event Whitelist(address indexed multisigAddress, bool isWhitelisted);
    event Withdraw(address indexed token, address indexed receiver, uint256 amount);

    mapping(address => uint256) private _feeByMultisig;
    mapping(address => bool) private _isWhitelisted;

    address private _feeCollector;
    
    uint256 private _fee;

    //upgradability
    bool internal _initialized;

    /** @param feeCollector Address that will receive tokens when withdraw function is called*/
    /** @param fee Global fee charged, i.e. 300 means 30%, 30 means 3%, 3 means 0.3%*/
    function initialize(address feeCollector, uint256 fee) public {
        require(feeCollector != address(0), "Fee Collector address cannot be 0");
        require(!_initialized, "Already initialized");
        require(fee.div(1000) == 0, "Fee cannot have more than 3 digits");
        _feeCollector = feeCollector;
        _fee = fee;
        _setOwner(feeCollector); 
        _initialized = true;
        emit SetFee(fee);
        emit SetFeeCollector(feeCollector);
    }

    /** @param feeCollector Address that will receive tokens when withdraw function is called*/
    function setFeeCollector(address feeCollector) external virtual onlyOwner {
        require(feeCollector != address(0), "Fee Collector address cannot be 0");
        _feeCollector = feeCollector;
        emit SetFeeCollector(feeCollector);
    }

    /** @param fee Global fee charged, i.e. 300 means 30%, 30 means 3%, 3 means 0.3%*/
    function setFee(uint256 fee) external virtual onlyOwner {
        require(fee.div(1000) == 0, "Fee cannot have more than 3 digits");
        _fee = fee;
        emit SetFee(fee);
    }

    /** @param multisigAddress Address of multisig tha will have a custom fee*/
    /** @param fee Custom fee charged, i.e. 3*10^18 (3000000000000000000) means 3%, 0.3*10^18 (300000000000000000) means 0.3%*/
    function setFeeByMultisig(address multisigAddress, uint256 fee) external virtual onlyOwner {
        _isWhitelisted[multisigAddress] = false;
        _feeByMultisig[multisigAddress] = fee;
        emit SetFeeByMultisig(multisigAddress, fee);
        emit Whitelist(multisigAddress, false);
    }

    /** @param multisigAddress Address of multisig tha will be whitelisted, fee will be 0*/
    /** @param allow True to add to whitelist and false to remove from whitelist*/
    function whitelistMultisig(address multisigAddress, bool allow) external virtual onlyOwner { 
        require(multisigAddress != address(0), "Multisig Address cannot be 0");
        _isWhitelisted[multisigAddress] = allow;
        emit Whitelist(multisigAddress, allow);
    }

    /** @dev Withdraws token balance from the wallet and sends all balance to feeCollector*/ 
    /** @param _token Token Address to withdraw*/
    function withdraw(address _token) external virtual onlyOwner {
        require(_token != address(0), "Token address cannot be 0");
        ERC20 erc20 = ERC20(_token); 
        uint256 _amount = erc20.balanceOf(address(this));
        require(_amount > 0, "Contract does not have any balance");
        erc20.transfer(_feeCollector, _amount);
        emit Withdraw(_token, _feeCollector, _amount);
    }

    /** Getters */
    function getFeeByMultisig(address multisigAddress) external virtual view returns(uint256) {
        if(_isWhitelisted[multisigAddress]) return 0;
        if(_feeByMultisig[multisigAddress] == 0) {
            return _fee;
        }
        return _feeByMultisig[multisigAddress];
    }

    function getFee() external virtual view returns(uint256) { 
        return _fee;
    }

    function getFeeCollector() external virtual view returns(address) {  
        return _feeCollector;
    }

    function isWhitelisted(address multisigAddress) external virtual view returns(bool) { 
        return _isWhitelisted[multisigAddress];
    }

    
}