// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import './modules/Initializable.sol';
import './modules/Configable.sol';

contract SwitchSigner is Configable, Initializable{
    address[] public signWallets;
    mapping(address => uint) public signerStatus; // 1; on, 2: off
    bool public isMultSign;
    uint public minSigner;

    event MinSignerChanged(address indexed user, uint minSigner);
    event SignerStatusChanged(address indexed user, address wallet, uint value);

    function initialize() external initializer {
        owner = msg.sender;
        minSigner = 1;
    }

    function setMultSign(bool _value) external onlyDev {
        isMultSign = _value;
    }

    function setMinSigner(uint _minSigner) external onlyDev {
        require(_minSigner >0, 'SwitchSigner: MUST_BE_GREATE_ZERO');
        minSigner = _minSigner;
        emit MinSignerChanged(msg.sender, _minSigner);
    }

    function setSigner(address _wallet, uint _value) external onlyDev {
        require(signerStatus[_wallet] != _value, 'SwitchSigner: NO_CHANGE');
        require(1 == _value || 2 == _value, 'SwitchSigner: INVALID_PARAM');
        if(signerStatus[_wallet] == 0) {
            signWallets.push(_wallet);
        }
        signerStatus[_wallet] = _value;
        emit SignerStatusChanged(msg.sender, _wallet, _value);
    }

    function countSigner() external view returns (uint) {
        return signWallets.length;
    }

    function checkUser(address _user) external view returns (bool) {
        return signerStatus[_user] != 1;
    }

    function verify(uint _mode, address _user, address _signer, bytes32 _message, bytes memory _signature) public view returns (bool) {
        bytes32 hash = _toEthBytes32SignedMessageHash(_message);
        address[] memory signList = _recoverAddresses(hash, _signature);
        if(isMultSign) {
            require(signList[0] != _signer, 'SwitchSigner: MUST_BE_ANOTHER');
        }
        if(_mode == 1) {
            require(signList[0] != _user, 'SwitchSigner: MUST_BE_NOT_SELF');
        }
        return signerStatus[signList[0]] == 1;
    }

    function mverify(uint _mode, address _user, address _signer, bytes32 _message, bytes[] memory _signatures) external view returns (bool) {
        require(minSigner >0, 'SwitchSigner: MINSIGER_MUST_BE_GREATE_ZERO');
        if(_signatures.length == 1 && minSigner == 1) {
            return verify(_mode, _user, _signer, _message, _signatures[0]);
        }

        bytes32 hash = _toEthBytes32SignedMessageHash(_message);
        address[] memory signers = new address[](_signatures.length);
        for(uint i; i<_signatures.length; i++) {
            address[] memory signList = _recoverAddresses(hash, _signatures[i]);
            require(signerStatus[signList[0]] ==1, 'SwitchSigner: INVALID_SIGNATURE');   
            signers[i] = signList[0];
        }

        uint passed;
        for(uint i; i<signers.length; i++) {
            require(_checkSigners(signers[i], signers), 'SwitchSigner: DUPLICATED_SIGNER');
            passed++;
        }
        
        if(passed >= minSigner) {
            return true;
        }
        return false;
    }
      
    function _checkSigners(address _signer, address[] memory signers) internal pure returns (bool) {
        uint count;
        for(uint i; i<signers.length; i++) {
            if(signers[i] == _signer) {
                count++;
            }
        }
        if(count == 1) {
            return true;
        } else {
            return false;
        }
    }
    
    function _toEthBytes32SignedMessageHash (bytes32 _msg) pure internal returns (bytes32 signHash) {
        signHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _msg));
    }
    
    function _recoverAddresses(bytes32 _hash, bytes memory _signatures) pure internal returns (address[] memory addresses) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }
    
    function _parseSignature(bytes memory _signatures, uint _pos) pure internal returns (uint8 v, bytes32 r, bytes32 s) {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;

        require(v == 27 || v == 28);
    }
    
    function _countSignatures(bytes memory _signatures) pure internal returns (uint) {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IConfig {
    function dev() external view returns (address);
    function admin() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event ConfigChanged(address indexed _user, address indexed _old, address indexed _new);
    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);
 
    function setupConfig(address _config) external onlyOwner {
        emit ConfigChanged(msg.sender, config, _config);
        config = _config;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }

    function admin() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).admin();
        }
        return owner;
    }

    function dev() public view returns(address) {
        if(config != address(0)) {
            return IConfig(config).dev();
        }
        return owner;
    }

    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'Owner: NO CHANGE');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }
    
    modifier onlyDev() {
        require(msg.sender == dev() || msg.sender == owner, 'dev FORBIDDEN');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin(), 'admin FORBIDDEN');
        _;
    }
  
    modifier onlyManager() {
        require(msg.sender == dev() || msg.sender == admin() || msg.sender == owner, 'manager FORBIDDEN');
        _;
    }
}

