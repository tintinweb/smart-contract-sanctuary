// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./SafeMath256.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SignMessage.sol";

contract WalletOwner {
    uint16  constant MIN_REQUIRED = 1;
    uint256 required;
    mapping(address => uint256) activeOwners;
    address[] owners;

    event OwnerRemoval(address indexed owner);
    event OwnerAddition(address indexed owner);
    event SignRequirementChanged(uint256 required);
}

contract WalletSecurity {
    uint256 constant MIN_INACTIVE_INTERVAL = 3 days; // 3days;
    uint256 constant securityInterval = 3 days;
    bool initialized;
    bool securitySwitch = false;
    uint256 deactivatedInterval = 0;
    uint256 lastActivatedTime = 0;

    mapping(bytes32 => uint256) transactions;
    event SecuritySwitchChange(bool swithOn, uint256 interval);

    modifier onlyNotInitialized() {
        require(!initialized, "the wallet already initialized");
        _;
        initialized = true;
    }

    modifier onlyInitialized() {
        require(initialized, "the wallet not init yet");
        _;
    }
}

contract MultiSignWallet is WalletOwner, WalletSecurity {
    using SafeMath256 for uint256;

    event Deposit(address indexed from, uint256 value);
    event Transfer(address indexed token, address indexed to, uint256 value);
    event TransferWithData(address indexed token, uint256 value);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "the wallet operation is expired");
        _;
    }

    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    function initialize(address[] memory _owners, uint256 _required, bool _switchOn, uint256 _deactivatedInterval) external onlyNotInitialized returns(bool) {
        require(_required >= MIN_REQUIRED, "the signed owner count must than 1");
        if (_switchOn) {
            require(_deactivatedInterval >= MIN_INACTIVE_INTERVAL, "inactive interval must more than 3days");
            securitySwitch = _switchOn;
            deactivatedInterval = _deactivatedInterval;
            emit SecuritySwitchChange(securitySwitch, deactivatedInterval);
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            if (_owners[i] == address(0x0)) {
                revert("the address can't be 0x");
            }

            if (activeOwners[_owners[i]] > 0 ) {
                revert("the owners must be distinct");
            }

            activeOwners[_owners[i]] = block.timestamp;
            emit OwnerAddition(_owners[i]);
        }

        require(_owners.length >= _required, "wallet owners must more than the required.");
        required = _required;
        emit SignRequirementChanged(required);
        owners = _owners;
        _updateActivatedTime();
        return true;
    }

    function addOwner(address[] memory _newOwners, uint256 _required, bytes32 salt, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss, uint256 deadline) public onlyInitialized ensure(deadline) returns (bool) {
        require(_validOwnerAddParams(_newOwners, _required), "invalid params");
        bytes32 message = SignMessage.ownerModifyMessage(address(this), getChainID(), _newOwners, _required, salt);
        require(getTransactionMessage(message) == 0, "transaction may has been excuted");
        transactions[message] = block.number;
        require(_validSignature(message, vs, rs, ss), "invalid signatures");
        address[] memory _oldOwners;
        return _updateOwners(_oldOwners, _newOwners, _required);
    }

    function removeOwner(address[] memory _oldOwners, uint256 _required, bytes32 salt, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss, uint256 deadline) public onlyInitialized ensure(deadline) returns (bool) {
        require(_validOwnerRemoveParams(_oldOwners, _required), "invalid params");
        bytes32 message = SignMessage.ownerModifyMessage(address(this), getChainID(), _oldOwners, _required, salt);
        require(getTransactionMessage(message) == 0, "transaction may has been excuted");
        transactions[message] = block.timestamp;
        require(_validSignature(message, vs, rs, ss), "invalid signatures");
        address[] memory _newOwners;
        return _updateOwners(_oldOwners, _newOwners, _required);
    }

    function replaceOwner(address[] memory _oldOwners, address[] memory _newOwners, uint256 _required, bytes32 salt, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss, uint256 deadline) public onlyInitialized ensure(deadline) returns (bool) {
        require(_validOwnerReplaceParams(_oldOwners, _newOwners, _required), "invalid params");
        bytes32 message = SignMessage.ownerReplaceMessage(address(this), getChainID(), _oldOwners, _newOwners, _required, salt);
        require(getTransactionMessage(message) == 0, "transaction may has been excuted");
        transactions[message] = block.number;
        require(_validSignature(message, vs, rs, ss), "invalid signatures");
        return _updateOwners(_oldOwners, _newOwners, _required);
    }

    function changeOwnerRequirement(uint256 _required, bytes32 salt, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss, uint256 deadline) public onlyInitialized ensure(deadline) returns (bool) {
        require(_required >= MIN_REQUIRED, "the signed owner count must than 1");
        require(owners.length >= _required, "the owners must more than the required");
        bytes32 message = SignMessage.ownerRequiredMessage(address(this), getChainID(), _required, salt);
        require(getTransactionMessage(message) == 0, "transaction may has been excuted");
        transactions[message] = block.number;
        require(_validSignature(message, vs, rs, ss), "invalid signatures");
        required = _required;
        emit SignRequirementChanged(required);

        return true;
    }

    function changeSecurityParams(bool _switchOn, uint256 _deactivatedInterval, bytes32 salt, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss, uint256 deadline) public onlyInitialized ensure(deadline) returns (bool) {
        bytes32 message = SignMessage.securitySwitchMessage(address(this), getChainID(), _switchOn, _deactivatedInterval, salt);
        require(getTransactionMessage(message) == 0, "transaction may has been excuted");
        transactions[message] = block.number;
        require(_validSignature(message, vs, rs, ss), "invalid signatures");

        if (_switchOn) {
            securitySwitch = true;
            require(_deactivatedInterval >= MIN_INACTIVE_INTERVAL, "inactive interval must more than 3days");
            deactivatedInterval = _deactivatedInterval;
        } else {
            securitySwitch = false;
            deactivatedInterval = 0;
        }

        emit SecuritySwitchChange(_switchOn, deactivatedInterval);

        return true;
    }

    function transfer(address tokenAddress, address payable to, uint256 value, bytes32 salt, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss, uint256 deadline) public onlyInitialized ensure(deadline) returns (bool) {
        if(tokenAddress == address(0x0)) {
            return _transferNativeToken(to, value, salt, vs, rs, ss);
        }
        return _transferContractToken(tokenAddress, to, value, salt, vs, rs, ss);
    }

    function transferWithData(address contractAddress, uint256 value, bytes32 salt, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss, bytes memory data, uint256 deadline) public onlyInitialized ensure(deadline) returns (bool) {
        require(contractAddress != address(this), "not allow transfer to yourself");
        bytes32 message = SignMessage.transferWithDataMessage(address(this), getChainID(), contractAddress, value, salt, data);
        require(getTransactionMessage(message) == 0, "transaction may has been excuted");
        transactions[message] = block.number;
        require(_validSignature(message, vs, rs, ss), "invalid signatures");
        (bool success,) = contractAddress.call{value: value}(data);
        require(success, "contract execution Failed");
        emit TransferWithData(contractAddress, value);
        return true;
    }

    function isOwner(address addr) public view returns (bool) {
        return activeOwners[addr] > 0;
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function getRequired() public view returns (uint256) {
        if(!securitySwitch) {
            return required;
        }

        uint256 _deactivate = block.timestamp;
        if (_deactivate <= lastActivatedTime + deactivatedInterval) {
            return required;
        }

        _deactivate = _deactivate.sub(lastActivatedTime).sub(deactivatedInterval).div(securityInterval);
        if (required > _deactivate) {
            return required.sub(_deactivate);
        }

        return MIN_REQUIRED;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getOwnerRequiredParam() public view returns (uint256) {
        return required;
    }

    function getTransactionMessage(bytes32 message) public view returns (uint256) {
        return transactions[message];
    }

    function isSecuritySwitchOn() public view returns (bool) {
        return securitySwitch;
    }

    function getDeactivatedInterval() public view returns (uint256) {
        return deactivatedInterval;
    }

    function getLastActivatedTime() public view returns (uint256) {
        return lastActivatedTime;
    }

    function _transferContractToken(address tokenAddress, address to, uint256 value, bytes32 salt, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) internal returns (bool) {
        require(to != address(this), "not allow transfer to yourself");
        bytes32 message = SignMessage.transferMessage(address(this), getChainID(), tokenAddress, to, value, salt);
        require(getTransactionMessage(message) == 0, "transaction may has been excuted");
        transactions[message] = block.number;
        require(_validSignature(message, vs, rs, ss), "invalid signatures");
        SafeERC20.safeTransfer(IERC20(tokenAddress), to, value);
        emit Transfer(tokenAddress, to, value);
        return true;
    }

    function _transferNativeToken(address payable to, uint256 value, bytes32 salt, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) internal returns (bool) {
        require(to != address(this), "not allow transfer to yourself");
        require(value > 0, "transfer value must more than 0");
        require(address(this).balance >= value, "balance not enough");
        bytes32 message = SignMessage.transferMessage(address(this), getChainID(), address(0x0), to, value, salt);
        require(getTransactionMessage(message) == 0, "transaction may has been excuted");
        transactions[message] = block.number;
        require(_validSignature(message, vs, rs, ss), "invalid signatures");
        to.transfer(value);
        emit Transfer(address(0x0), to, value);
        return true;
    }

    function _updateActivatedTime() internal {
        lastActivatedTime = block.timestamp;
    }

    function _validOwnerAddParams(address[] memory _owners, uint256 _required) private view returns (bool) {
        require(_owners.length > 0, "the new owners list can't be emtpy");
        require(_required >= MIN_REQUIRED, "the signed owner count must than 1");
        uint256 ownerCount = _owners.length;
        ownerCount = ownerCount.add(owners.length);
        require(ownerCount >= _required, "the owner count must more than the required");
        return _distinctAddOwners(_owners);
    }

    function _validOwnerRemoveParams(address[] memory _owners, uint256 _required) private view returns (bool) {
        require(_owners.length > 0 && _required >= MIN_REQUIRED, "invalid parameters");
        uint256 ownerCount = owners.length;
        ownerCount = ownerCount.sub(_owners.length);
        require(ownerCount >= _required, "the owners must more than the required");
        return _distinctRemoveOwners(_owners);
    }

    function _validOwnerReplaceParams(address[] memory _oldOwners, address[] memory _newOwners, uint256 _required) private view returns (bool) {
        require(_oldOwners.length >0 || _newOwners.length > 0, "the two input owner list can't both be empty");
        require(_required >= MIN_REQUIRED, "the signed owner's count must than 1");
        _distinctRemoveOwners(_oldOwners);
        _distinctAddOwners(_newOwners);
        uint256 ownerCount = owners.length;
        ownerCount = ownerCount.add(_newOwners.length).sub(_oldOwners.length);
        require(ownerCount >= _required, "the owner's count must more than the required");
        return true;
    }

    function _distinctRemoveOwners(address[] memory _owners) private view returns (bool) {
        for(uint256 i = 0; i < _owners.length; i++) {
            if (_owners[i] == address(0x0)) {
                revert("the remove address can't be 0x.");
            }

            if(activeOwners[_owners[i]] == 0) {
                revert("the remove address must be a owner.");
            }

            for(uint256 j = 0; j < i; j++) {
                if(_owners[j] == _owners[i]) {
                    revert("the remove address must be distinct");
                }
            }
        }
        return true;
    }

    function _distinctAddOwners(address[] memory _owners) private view returns (bool) {
        for(uint256 i = 0; i < _owners.length; i++) {
            if (_owners[i] == address(0x0)) {
                revert("the new address can't be 0x.");
            }

            if (activeOwners[_owners[i]] != 0) {
                revert("the new address is already a owner");
            }

            for(uint256 j = 0; j < i; j++) {
                if(_owners[j] == _owners[i]) {
                    revert("the new address must be distinct");
                }
            }
        }
        return true;
    }

    function _validSignature(bytes32 recoverMsg, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) private returns (bool) {
        require(vs.length == rs.length);
        require(rs.length == ss.length);
        require(vs.length <= owners.length);
        require(vs.length >= getRequired());

        address[] memory signedAddresses = new address[](vs.length);
        for (uint256 i = 0; i < vs.length; i++) {
            signedAddresses[i] = ecrecover(recoverMsg, vs[i]+27, rs[i], ss[i]);
        }

        require(_distinctSignedOwners(signedAddresses), "signed owner must be distinct");
        _updateActiveOwners(signedAddresses);
        _updateActivatedTime();
        return true;
    }

    function _updateOwners(address[] memory _oldOwners, address[] memory _newOwners, uint256 _required) private returns (bool) {
        for(uint256 i = 0; i < _oldOwners.length; i++) {
            for (uint256 j = 0; j < owners.length; j++) {
                if (owners[j] == _oldOwners[i]) {
                    activeOwners[owners[j]] = 0;
                    owners[j] = owners[owners.length - 1];
                    owners.pop();
                    emit OwnerRemoval(_oldOwners[i]);
                    break;
                }
            }
        }

        for(uint256 i = 0; i < _newOwners.length; i++) {
            owners.push(_newOwners[i]);
            activeOwners[_newOwners[i]] = block.timestamp;
            emit OwnerAddition(_newOwners[i]);
        }

        require(owners.length >= _required, "the owners must more than the required");
        required = _required;
        emit SignRequirementChanged(required);

        return true;
    }

    function _updateActiveOwners(address[] memory _owners) private returns (bool){
        for (uint256 i = 0; i < _owners.length; i++) {
            activeOwners[_owners[i]] = block.timestamp;
        }
        return true;
    }

    function _distinctSignedOwners(address[] memory _owners) private view returns (bool) {
        if (_owners.length > owners.length) {
            return false;
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            if(activeOwners[_owners[i]] == 0) {
                return false;
            }

            for (uint256 j = 0; j < i; j++) {
                if(_owners[j] == _owners[i]) {
                    return false;
                }
            }
        }
        return true;
    }
}