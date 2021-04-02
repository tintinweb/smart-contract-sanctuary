/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.5.2;

// ./interface/IERC20.sol

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

// ./lib/SafeMath.sol

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }
}

// ./lib/Roles.sol

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), "Roles: account already has role");
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), "Roles: account does not have role");
    role.bearer[account] = false;
  }

  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), "Roles: account is the zero address");
    return role.bearer[account];
  }
}

// ./lib/AuditorRole.sol


contract AuditorRole {
  using Roles for Roles.Role;

  event AuditorAdded(address indexed account);
  event AuditorRemoved(address indexed account);

  Roles.Role private _auditors;

  address[] public indexedAuditors;
  mapping (address => bool) public auditorIndex;

  constructor () internal {
    _addAuditor(msg.sender);
  }

  modifier onlyAuditor() {
    require(isAuditor(msg.sender), "AuditorRole: caller does not have the Auditor role");
    _;
  }

  function isAuditor(address account) public view returns (bool) {
    return _auditors.has(account);
  }

  function addAuditor(address account) public onlyAuditor {
    _addAuditor(account);
  }

  function removeAuditor(address account) public onlyAuditor {
    _removeAuditor(account);
  }

  function getIndexedAuditorCount() public view returns(uint256) {
    return indexedAuditors.length;
  }

  function _addAuditor(address account) internal {
    _auditors.add(account);

    if(!auditorIndex[account]) {
      indexedAuditors.push(account);
      auditorIndex[account] = true;
    }

    emit AuditorAdded(account);
  }

  function _removeAuditor(address account) internal {
    _auditors.remove(account);
    emit AuditorRemoved(account);
  }
}

// StackStorageIncentive.sol


contract StackStorageIncentive is AuditorRole {
    using SafeMath for uint256;

    uint256 public rewardPerScore;
    uint256 public auditorFeeRate;
    address public payableTokenAddr;

    mapping (string => uint256) private depositedAmount;
    mapping (string => bool) private depositedIpfsHashIndex;
    string[] public depositedIpfsHashs;
    mapping (bytes => bool) depositedSignatures;
    mapping (bytes => bool) withdrawSignatures;
    mapping (address => mapping(string => uint256)) private passedScores;
    mapping (address => string[]) public passedIpfsHashs;
    mapping (address => mapping(string => bool)) private passedIpfsHashIndex;

    event Deposited(address sender, string ipfsHash, uint256 amount);
    event AddedPassedScore(address miner, string ipfsHash, uint256 passedScore);
    event Withdraw(address recipient, string ipfsHash, uint256 reward, uint256 minerReward);
    event PaymentAuditorFee(address auditor, uint256 paidAuditorFee);

    constructor(address _payableTokenAddr) internal {
        payableTokenAddr = _payableTokenAddr;
    }

    function setRewardPerScore (uint256 _rewardPerScore) public onlyAuditor returns(bool) {
        rewardPerScore = _rewardPerScore;
        return true;
    }

    function setAuditorFeeRate (uint256 _auditorFeeRate) public onlyAuditor returns(bool) {
        auditorFeeRate = _auditorFeeRate;
        return true;
    }

    function depositPreSigned(string memory _ipfsHash, uint256 _amount, uint256 _fee, uint256 _nonce, bytes memory _signature) public returns(bool) {
        require(!depositedSignatures[_signature]);
        bytes32 hash = depositPreSignedHashing(_ipfsHash, _amount, _fee, _nonce);
        address _signer = recover(hash, _signature);

        IERC20 token = IERC20(payableTokenAddr);
        token.transferFrom(_signer, msg.sender, _fee);

        _deposit(_signer, _ipfsHash, _amount);

        depositedSignatures[_signature] = true;

        return true;
    }

    function depositPreSignedHashing(string memory _ipfsHash, uint256 _amount, uint256 _fee, uint256 _nonce) public pure returns (bytes32) {
        /* "9fa57d26: depositPreSignedHashing(string,uint256,uint256,uint256) */
        return keccak256(abi.encodePacked(bytes4(0x9fa57d26), _ipfsHash, _amount, _fee, _nonce));
    }

    function deposit(string memory _ipfsHash, uint256 _amount) public returns(bool) {
        _deposit(msg.sender, _ipfsHash, _amount);
        return true;
    }

    function _deposit(address _sender, string memory _ipfsHash, uint256 _amount) internal {
        IERC20 token = IERC20(payableTokenAddr);
        token.transferFrom(_sender, address(this), _amount);

        depositedAmount[_ipfsHash] = depositedAmount[_ipfsHash].add(_amount);

        if(!depositedIpfsHashIndex[_ipfsHash]) {
            depositedIpfsHashs.push(_ipfsHash);
            depositedIpfsHashIndex[_ipfsHash] = true;
        }

        emit Deposited(_sender, _ipfsHash, _amount);
    }

    function getDepositedIpfsHashCount() public view returns(uint256) {
        return depositedIpfsHashs.length;
    }

    function getDepositedAmount(string memory _ipfsHash) public view returns(uint256) {
        return depositedAmount[_ipfsHash];
    }

    function addPassedScore(address _miner, string memory _ipfsHash, uint256 _passedScore) public onlyAuditor returns(bool) {
        passedScores[_miner][_ipfsHash] = passedScores[_miner][_ipfsHash].add(_passedScore);
        if(!passedIpfsHashIndex[_miner][_ipfsHash]) {
            passedIpfsHashs[_miner].push(_ipfsHash);
            passedIpfsHashIndex[_miner][_ipfsHash] = true;
        }
        emit AddedPassedScore(_miner, _ipfsHash, _passedScore);
        return true;
    }

    function getPassedIpfsHashCount(address _miner) public view returns(uint256) {
        return passedIpfsHashs[_miner].length;
    }

    function getPassedScore(address _miner, string memory _ipfsHash) public view returns(uint256) {
        return passedScores[_miner][_ipfsHash];
    }

    function withdrawPreSigned(string memory _ipfsHash, uint256 _fee, uint256 _nonce, bytes memory _signature) public returns(bool) {
        require(!withdrawSignatures[_signature]);

        bytes32 hash = withdrawPreSignedHashing(_ipfsHash, _fee, _nonce);
        address _signer = recover(hash, _signature);

        uint256 _reward = calcReward(_signer, _ipfsHash);
        uint256 _paidAuditorFee = paymentAuditorFee(calcAuditorFee(_reward));

        uint256 _minerReward = _reward.sub(_paidAuditorFee).sub(_fee);

        _withdraw(_signer, _ipfsHash, _reward, _minerReward);

        IERC20 token = IERC20(payableTokenAddr);
        token.transfer(msg.sender, _fee);

        withdrawSignatures[_signature] = true;

        return true;
    }

    function withdrawPreSignedHashing(string memory _ipfsHash, uint256 _fee, uint256 _nonce) public pure returns (bytes32) {
        /* "4248bc99: withdrawPresignedHashing(string,uint256,uint256) */
        return keccak256(abi.encodePacked(bytes4(0x4248bc99), _ipfsHash, _fee, _nonce));
    }

    function withdraw(address _recipient, string memory _ipfsHash) public returns(bool) {
        uint256 _reward = calcReward(msg.sender, _ipfsHash);
        uint256 _paidAuditorFee = paymentAuditorFee(calcAuditorFee(_reward));
        uint256 _minerReward = _reward.sub(_paidAuditorFee);

        _withdraw(_recipient, _ipfsHash, _reward, _minerReward);

        return true;
    }

    function _withdraw(address _recipient, string memory _ipfsHash, uint256 _reward, uint256 _minerReward) internal {
        depositedAmount[_ipfsHash] = depositedAmount[_ipfsHash].sub(_reward);
        passedScores[_recipient][_ipfsHash] = 0;

        IERC20 token = IERC20(payableTokenAddr);
        token.transfer(_recipient, _minerReward);

        emit Withdraw(_recipient, _ipfsHash, _reward, _minerReward);
    }

    function paymentAuditorFee(uint256 _auditorFee) internal returns(uint256) {
        IERC20 token = IERC20(payableTokenAddr);
        uint256 count = getIndexedAuditorCount();
        uint256 eachOneFee = _auditorFee / count;
        uint256 paidTotalFee = 0;
        for (uint256 i=0; i<count; i++) {
            address auditor = indexedAuditors[i];
            if(isAuditor(auditor)) {
                token.transfer(auditor, eachOneFee);
                paidTotalFee = paidTotalFee + eachOneFee;
                emit PaymentAuditorFee(auditor, eachOneFee);
            }
        }
        return paidTotalFee;
    }

    function calcReward(address _recipient, string memory _ipfsHash) public view returns(uint256) {
        uint256 _reward = rewardPerScore * passedScores[_recipient][_ipfsHash];
        if (depositedAmount[_ipfsHash] < _reward) {
            _reward = depositedAmount[_ipfsHash];
        }
        return _reward;
    }

    function calcAuditorFee(uint256 _reward) public view returns(uint256) {
        return _reward * auditorFeeRate / 100;
    }

    function recover(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        bytes32 r; bytes32 s; uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_hash, v, r, s);
    }
}

// StackStorage.sol


contract StackStorage is StackStorageIncentive {
    mapping (address => mapping(string => string)) private keyValues;
    mapping (address => string[]) public keys;
    mapping (address => mapping(string => bool)) private keyIndex;
    mapping (address => bool) public userIndex;
    mapping (bytes => bool) setKeyValueSignatures;
    address[] public users;
    event SetKeyValue(address indexed _user, string _key, string value);

    constructor(address _payableTokenAddr) StackStorageIncentive(_payableTokenAddr) public {}

    function setKeyValueDepositPreSigned(string memory _key, string memory _value, uint256 _amount, uint256 _fee, uint256 _nonce, bytes memory _signature) public returns (bool) {
        require(!setKeyValueSignatures[_signature]);

        bytes32 hash = setKeyValueDepositPreSignedHashing(_key, _value, _amount, _fee, _nonce);
        address _signer = recover(hash, _signature);

        _setKeyValue(_signer, _key, _value);

        IERC20 token = IERC20(payableTokenAddr);
        token.transferFrom(_signer, msg.sender, _fee);

        _deposit(_signer, _value, _amount);

        setKeyValueSignatures[_signature] = true;

        return true;
    }

    function setKeyValueDepositPreSignedHashing(string memory _key, string memory _value, uint256 _amount, uint256 _fee, uint256 _nonce) public pure returns (bytes32) {
        /* "9887b117: setKeyValueDepositPreSignedHashing(string,string,uint256,uint256,uint256) */
        return keccak256(abi.encodePacked(bytes4(0x9887b117), _key, _value, _amount, _fee, _nonce));
    }

    function setKeyValueDeposit(string memory _key, string memory _value, uint256 _amount) public returns(bool){
        _setKeyValue(msg.sender, _key, _value);
        _deposit(msg.sender, _value, _amount);
        return true;
    }

    function setKeyValuePreSigned(string memory _key, string memory _value, uint256 _fee, uint256 _nonce, bytes memory _signature) public returns(bool){
        require(!setKeyValueSignatures[_signature]);

        bytes32 hash = setKeyValuePreSignedHashing(_key, _value, _fee, _nonce);
        address _signer = recover(hash, _signature);

        _setKeyValue(_signer, _key, _value);

        IERC20 token = IERC20(payableTokenAddr);
        token.transferFrom(_signer, msg.sender, _fee);

        setKeyValueSignatures[_signature] = true;

        return true;
    }

    function setKeyValuePreSignedHashing(string memory _key, string memory _value, uint256 _fee, uint256 _nonce) public pure returns (bytes32) {
        /* "9a9a0477: setKeyValuePreSignedHashing(string,string,uint256,uint256) */
        return keccak256(abi.encodePacked(bytes4(0x9a9a0477), _key, _value, _fee, _nonce));
    }

    function setKeyValue(string memory _key, string memory _value) public returns(bool){
        _setKeyValue(msg.sender, _key, _value);
        return true;
    }

    function _setKeyValue(address _owner, string memory _key, string memory _value) internal {
        pushUserIfNoExist(_owner);
        pushKeyIfNoExist(_owner, _key);
        keyValues[_owner][_key] = _value;
        emit SetKeyValue(_owner, _key, _value);
    }

    function getKeyValue(address _owner, string memory _key) public view returns (string memory) {
        return keyValues[_owner][_key];
    }

    function pushUserIfNoExist (address _user) private returns(bool) {
        if(!userIndex[_user]) {
            users.push(_user);
            userIndex[_user] = true;
        }
        return true;
    }

    function pushKeyIfNoExist(address _owner, string memory _key) private returns(bool) {
        if(!keyIndex[_owner][_key]) {
            keys[_owner].push(_key);
            keyIndex[_owner][_key] = true;
        }
        return true;
    }

    function getUserCount() public view returns(uint256) {
        return users.length;
    }

    function getKeyCount(address _owner) public view returns(uint256) {
        return keys[_owner].length;
    }

    function recover(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        bytes32 r; bytes32 s; uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_hash, v, r, s);
    }
}