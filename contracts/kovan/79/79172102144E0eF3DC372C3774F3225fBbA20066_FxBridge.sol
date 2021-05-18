pragma experimental ABIEncoderV2;
pragma solidity ^0.6.6;

import "./SafeMath.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract FxBridge is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;

    // These are updated often
    bytes32 public state_lastValsetCheckpoint;
    mapping(address => uint256) public state_lastBatchNonces;
    uint256 public state_lastValsetNonce = 0;
    uint256 public state_lastEventNonce = 0;

    // These are set once at initialization
    bytes32 public state_fxBridgeId;
    uint256 public state_powerThreshold;

    address[] public bridgeTokens;

    // address public constant EthAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public state_fxOriginatedToken;

    struct TransferInfo {
        uint256 amount;
        address destination;
        uint256 fee;
        address exchange;
        uint256 minExchange;
    }

    event TransactionBatchExecutedEvent(
        uint256 indexed _batchNonce,
        address indexed _token,
        uint256 _eventNonce
    );
    event SendToFxEvent(
        address indexed _tokenContract,
        address indexed _sender,
        bytes32 indexed _destination,
        bytes32 _targetIBC,
        uint256 _amount,
        uint256 _eventNonce
    );
    event FxOriginatedTokenEvent(
        address indexed _tokenContract,
        string _name,
        string _symbol,
        uint8 _decimals,
        string _fxDenom,
        uint256 _eventNonce
    );
    event ValsetUpdatedEvent(
        uint256 indexed _newValsetNonce,
        address[] _validators,
        uint256[] _powers
    );

    struct BridgeToken {
        address addr;
        string name;
        string symbol;
        uint8 decimals;
    }

    function setFxOriginatedToken(string memory _fxDenom, address _tokenAddr) public onlyOwner returns (bool)  {
        require(_tokenAddr != state_fxOriginatedToken, 'Invalid bridge token');
        state_fxOriginatedToken = _tokenAddr;
        state_lastEventNonce = state_lastEventNonce.add(1);
        emit FxOriginatedTokenEvent(_tokenAddr, IERC20Metadata(_tokenAddr).name(), IERC20Metadata(_tokenAddr).symbol(), IERC20Metadata(_tokenAddr).decimals(), _fxDenom, state_lastEventNonce);
        return true;
    }

    function getBridgeTokenList() public view returns (BridgeToken[] memory) {
        BridgeToken[] memory result = new BridgeToken[](bridgeTokens.length);
        for (uint256 i = 0; i < bridgeTokens.length; i++) {
            address _tokenAddr = address(bridgeTokens[i]);
            BridgeToken memory bridgeToken = BridgeToken(
                _tokenAddr,
                IERC20Metadata(_tokenAddr).name(),
                IERC20Metadata(_tokenAddr).symbol(),
                IERC20Metadata(_tokenAddr).decimals());
            result[i] = bridgeToken;
        }
        return result;
    }

    /*
    * @dev Add `_tokenAddr` into asset list
    * @param `_tokenAddr` token address
    * @notice Only owner is allowed
   */
    function addBridgeToken(address _tokenAddr) public onlyOwner returns (bool)  {
        require(_tokenAddr != state_fxOriginatedToken, 'Invalid bridge token');
        if (bridgeTokens.length == 0) {
            bridgeTokens.push(_tokenAddr);
        } else {
            uint index = _isContainToken(bridgeTokens, _tokenAddr);
            require(bridgeTokens[index] != _tokenAddr, 'Invalid operation');
            bridgeTokens.push(_tokenAddr);
        }
        return true;
    }

    /*
    * @dev Delete `_tokenAddr` form asset list
    * @param `_tokenAddr` token address
    * @notice Only owner is allowed
   */
    function delBridgeToken(address _tokenAddr) public onlyOwner returns (bool) {
        uint index = _isContainToken(bridgeTokens, _tokenAddr);
        require(bridgeTokens[index] == _tokenAddr, 'Invalid operation');

        for (uint i = index; i < bridgeTokens.length - 1; i++) {
            bridgeTokens[i] = bridgeTokens[i + 1];
        }
        bridgeTokens.pop();
        return true;
    }

    /*
    * @dev check whether asset is available
    */
    function checkAssetStatus(address _tokenAddr) public view returns (bool){
        if (state_fxOriginatedToken == _tokenAddr) {
            return true;
        }
        if (bridgeTokens.length == 0) {
            return false;
        } else {
            uint index = _isContainToken(bridgeTokens, _tokenAddr);
            if (bridgeTokens[index] != _tokenAddr) {
                return false;
            }
            return true;
        }
    }

    function _isContainToken(address[] memory list, address _tokenAddr) private pure returns (uint) {
        uint index = 0;
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == _tokenAddr) {
                index = i;
            }
        }
        return index;
    }

    function lastBatchNonce(address _erc20Address) public view returns (uint256) {
        return state_lastBatchNonces[_erc20Address];
    }

    function verifySig(address _signer, bytes32 _theHash, uint8 _v, bytes32 _r, bytes32 _s) private pure returns (bool) {
        bytes32 messageDigest =
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _theHash));
        return _signer == ecrecover(messageDigest, _v, _r, _s);
    }

    function makeCheckpoint(address[] memory _validators, uint256[] memory _powers, uint256 _valsetNonce, bytes32 _fxBridgeId) public pure returns (bytes32) {
        // bytes32 encoding of the string "checkpoint"
        bytes32 methodName = 0x636865636b706f696e7400000000000000000000000000000000000000000000;

        bytes32 checkpoint =
        keccak256(abi.encode(_fxBridgeId, methodName, _valsetNonce, _validators, _powers));

        return checkpoint;
    }

    function checkValidatorSignatures(address[] memory _currentValidators, uint256[] memory _currentPowers,
        uint8[] memory _v, bytes32[] memory _r, bytes32[] memory _s, bytes32 _theHash, uint256 _powerThreshold
    ) public pure {
        uint256 cumulativePower = 0;

        for (uint256 i = 0; i < _currentValidators.length; i++) {

            if (_v[i] != 0) {

                require(
                    verifySig(_currentValidators[i], _theHash, _v[i], _r[i], _s[i]),
                    "Validator signature does not match."
                );

                cumulativePower = cumulativePower + _currentPowers[i];

                if (cumulativePower > _powerThreshold) {
                    break;
                }
            }
        }

        require(
            cumulativePower > _powerThreshold,
            "Submitted validator set signatures do not have enough power."
        );

    }

    function updateValset(address[] memory _newValidators, uint256[] memory _newPowers, uint256 _newValsetNonce,
        address[] memory _currentValidators, uint256[] memory _currentPowers, uint256 _currentValsetNonce,
        uint8[] memory _v, bytes32[] memory _r, bytes32[] memory _s
    ) public {

        require(
            _newValsetNonce > _currentValsetNonce,
            "New valset nonce must be greater than the current nonce"
        );

        require(_newValidators.length == _newPowers.length, "Malformed new validator set");

        require(
            _currentValidators.length == _currentPowers.length &&
            _currentValidators.length == _v.length &&
            _currentValidators.length == _r.length &&
            _currentValidators.length == _s.length,
            "Malformed current validator set"
        );

        require(
            makeCheckpoint(_currentValidators, _currentPowers, _currentValsetNonce, state_fxBridgeId) == state_lastValsetCheckpoint,
            "Supplied current validators and powers do not match checkpoint."
        );

        bytes32 newCheckpoint = makeCheckpoint(_newValidators, _newPowers, _newValsetNonce, state_fxBridgeId);

        checkValidatorSignatures(_currentValidators, _currentPowers, _v, _r, _s, newCheckpoint, state_powerThreshold);

        state_lastValsetCheckpoint = newCheckpoint;

        state_lastValsetNonce = _newValsetNonce;

        emit ValsetUpdatedEvent(_newValsetNonce, _newValidators, _newPowers);
    }

    function submitBatch(address[] memory _currentValidators, uint256[] memory _currentPowers, uint256 _currentValsetNonce,
        uint8[] memory _v, bytes32[] memory _r, bytes32[] memory _s,
        uint256[] memory _amounts, address[] memory _destinations, uint256[] memory _fees,
        uint256 _batchNonce, address _tokenContract, uint256 _batchTimeout
    ) public nonReentrant {
        {
            require(checkAssetStatus(_tokenContract), "Unsupported token address");

            require(
                state_lastBatchNonces[_tokenContract] < _batchNonce,
                "New batch nonce must be greater than the current nonce"
            );

            require(
                block.number < _batchTimeout,
                "Batch timeout must be greater than the current block height"
            );

            require(
                _currentValidators.length == _currentPowers.length &&
                _currentValidators.length == _v.length &&
                _currentValidators.length == _r.length &&
                _currentValidators.length == _s.length,
                "Malformed current validator set"
            );

            require(
                makeCheckpoint(_currentValidators, _currentPowers, _currentValsetNonce, state_fxBridgeId) == state_lastValsetCheckpoint,
                "Supplied current validators and powers do not match checkpoint."
            );


            require(
                _amounts.length == _destinations.length && _amounts.length == _fees.length,
                "Malformed batch of transactions"
            );


            checkValidatorSignatures(
                _currentValidators,
                _currentPowers,
                _v,
                _r,
                _s,
                keccak256(abi.encode(
                    state_fxBridgeId,
                // bytes32 encoding of "transactionBatch"
                    0x7472616e73616374696f6e426174636800000000000000000000000000000000,
                    _amounts,
                    _destinations,
                    _fees,
                    _batchNonce,
                    _tokenContract,
                    _batchTimeout
                )),
                state_powerThreshold
            );

            state_lastBatchNonces[_tokenContract] = _batchNonce;

            {

                uint256 totalFee;
                for (uint256 i = 0; i < _amounts.length; i++) {
                    if (_tokenContract == state_fxOriginatedToken) {
                        IERC20Metadata(state_fxOriginatedToken).mint(_destinations[i], _amounts[i]);
                    } else {
                        IERC20Metadata(_tokenContract).safeTransfer(_destinations[i], _amounts[i]);
                    }
                    totalFee = totalFee.add(_fees[i]);
                }

                if (_tokenContract == state_fxOriginatedToken) {
                    IERC20Metadata(state_fxOriginatedToken).mint(msg.sender, totalFee);
                } else {
                    IERC20Metadata(_tokenContract).safeTransfer(msg.sender, totalFee);
                }
            }
        }

        {
            state_lastEventNonce = state_lastEventNonce.add(1);
            emit TransactionBatchExecutedEvent(_batchNonce, _tokenContract, state_lastEventNonce);
        }
    }

    function sendToFx(address _tokenContract, bytes32 _destination, bytes32 _targetIBC, uint256 _amount) public nonReentrant {
        if (_tokenContract == state_fxOriginatedToken) {
            IERC20Metadata(_tokenContract).burnFrom(msg.sender, _amount);
        } else {
            require(checkAssetStatus(_tokenContract), "Unsupported token address");
            IERC20Metadata(_tokenContract).safeTransferFrom(msg.sender, address(this), _amount);
        }
        state_lastEventNonce = state_lastEventNonce.add(1);
        emit SendToFxEvent(_tokenContract, msg.sender, _destination, _targetIBC, _amount, state_lastEventNonce);
    }

    constructor(bytes32 _fxBridgeId, uint256 _powerThreshold, address[] memory _validators, uint256[] memory _powers) public {

        require(_validators.length == _powers.length, "Malformed current validator set");

        uint256 cumulativePower = 0;
        for (uint256 i = 0; i < _powers.length; i++) {
            cumulativePower = cumulativePower + _powers[i];
            if (cumulativePower > _powerThreshold) {
                break;
            }
        }
        require(
            cumulativePower > _powerThreshold,
            "Submitted validator set signatures do not have enough power."
        );

        bytes32 newCheckpoint = makeCheckpoint(_validators, _powers, 0, _fxBridgeId);

        state_fxBridgeId = _fxBridgeId;
        state_powerThreshold = _powerThreshold;
        state_lastValsetCheckpoint = newCheckpoint;

        emit ValsetUpdatedEvent(0, _validators, _powers);
    }
}