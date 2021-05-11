/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

/**

Licenses
@openzeppelin/contracts: (MIT) https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/LICENSE
darknode-sol: (GNU GPL V3) https://github.com/renproject/darknode-sol/blob/master/LICENSE

*/

pragma solidity 0.5.16;


interface IRelayRecipient {
    
    function getHubAddr() external view returns (address);

    
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    )
        external
        view
        returns (uint256, bytes memory);

    
    function preRelayedCall(bytes calldata context) external returns (bytes32);

    
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external;
}

interface IRelayHub {
    

    
    function stake(address relayaddr, uint256 unstakeDelay) external payable;

    
    event Staked(address indexed relay, uint256 stake, uint256 unstakeDelay);

    
    function registerRelay(uint256 transactionFee, string calldata url) external;

    
    event RelayAdded(address indexed relay, address indexed owner, uint256 transactionFee, uint256 stake, uint256 unstakeDelay, string url);

    
    function removeRelayByOwner(address relay) external;

    
    event RelayRemoved(address indexed relay, uint256 unstakeTime);

    
    function unstake(address relay) external;

    
    event Unstaked(address indexed relay, uint256 stake);

    
    enum RelayState {
        Unknown, 
        Staked, 
        Registered, 
        Removed    
    }

    
    function getRelay(address relay) external view returns (uint256 totalStake, uint256 unstakeDelay, uint256 unstakeTime, address payable owner, RelayState state);

    

    
    function depositFor(address target) external payable;

    
    event Deposited(address indexed recipient, address indexed from, uint256 amount);

    
    function balanceOf(address target) external view returns (uint256);

    
    function withdraw(uint256 amount, address payable dest) external;

    
    event Withdrawn(address indexed account, address indexed dest, uint256 amount);

    

    
    function canRelay(
        address relay,
        address from,
        address to,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata signature,
        bytes calldata approvalData
    ) external view returns (uint256 status, bytes memory recipientContext);

    
    enum PreconditionCheck {
        OK,                         
        WrongSignature,             
        WrongNonce,                 
        AcceptRelayedCallReverted,  
        InvalidRecipientStatusCode  
    }

    
    function relayCall(
        address from,
        address to,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata signature,
        bytes calldata approvalData
    ) external;

    
    event CanRelayFailed(address indexed relay, address indexed from, address indexed to, bytes4 selector, uint256 reason);

    
    event TransactionRelayed(address indexed relay, address indexed from, address indexed to, bytes4 selector, RelayCallStatus status, uint256 charge);

    
    enum RelayCallStatus {
        OK,                      
        RelayedCallFailed,       
        PreRelayedFailed,        
        PostRelayedFailed,       
        RecipientBalanceChanged  
    }

    
    function requiredGas(uint256 relayedCallStipend) external view returns (uint256);

    
    function maxPossibleCharge(uint256 relayedCallStipend, uint256 gasPrice, uint256 transactionFee) external view returns (uint256);

     
     
    
    

    
    function penalizeRepeatedNonce(bytes calldata unsignedTx1, bytes calldata signature1, bytes calldata unsignedTx2, bytes calldata signature2) external;

    
    function penalizeIllegalTransaction(bytes calldata unsignedTx, bytes calldata signature) external;

    
    event Penalized(address indexed relay, address sender, uint256 amount);

    
    function getNonce(address from) external view returns (uint256);
}

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract GSNRecipient is IRelayRecipient, Context {
    
    address private _relayHub = 0xD216153c06E857cD7f72665E0aF1d7D82172F494;

    uint256 constant private RELAYED_CALL_ACCEPTED = 0;
    uint256 constant private RELAYED_CALL_REJECTED = 11;

    
    uint256 constant internal POST_RELAYED_CALL_MAX_GAS = 100000;

    
    event RelayHubChanged(address indexed oldRelayHub, address indexed newRelayHub);

    
    function getHubAddr() public view returns (address) {
        return _relayHub;
    }

    
    function _upgradeRelayHub(address newRelayHub) internal {
        address currentRelayHub = _relayHub;
        require(newRelayHub != address(0), "GSNRecipient: new RelayHub is the zero address");
        require(newRelayHub != currentRelayHub, "GSNRecipient: new RelayHub is the current one");

        emit RelayHubChanged(currentRelayHub, newRelayHub);

        _relayHub = newRelayHub;
    }

    
    
    
    function relayHubVersion() public view returns (string memory) {
        this; 
        return "1.0.0";
    }

    
    function _withdrawDeposits(uint256 amount, address payable payee) internal {
        IRelayHub(_relayHub).withdraw(amount, payee);
    }

    
    
    
    

    
    function _msgSender() internal view returns (address payable) {
        if (msg.sender != _relayHub) {
            return msg.sender;
        } else {
            return _getRelayedCallSender();
        }
    }

    
    function _msgData() internal view returns (bytes memory) {
        if (msg.sender != _relayHub) {
            return msg.data;
        } else {
            return _getRelayedCallData();
        }
    }

    
    

    
    function preRelayedCall(bytes calldata context) external returns (bytes32) {
        require(msg.sender == getHubAddr(), "GSNRecipient: caller is not RelayHub");
        return _preRelayedCall(context);
    }

    
    function _preRelayedCall(bytes memory context) internal returns (bytes32);

    
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external {
        require(msg.sender == getHubAddr(), "GSNRecipient: caller is not RelayHub");
        _postRelayedCall(context, success, actualCharge, preRetVal);
    }

    
    function _postRelayedCall(bytes memory context, bool success, uint256 actualCharge, bytes32 preRetVal) internal;

    
    function _approveRelayedCall() internal pure returns (uint256, bytes memory) {
        return _approveRelayedCall("");
    }

    
    function _approveRelayedCall(bytes memory context) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_ACCEPTED, context);
    }

    
    function _rejectRelayedCall(uint256 errorCode) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_REJECTED + errorCode, "");
    }

    
    function _computeCharge(uint256 gas, uint256 gasPrice, uint256 serviceFee) internal pure returns (uint256) {
        
        
        return (gas * gasPrice * (100 + serviceFee)) / 100;
    }

    function _getRelayedCallSender() private pure returns (address payable result) {
        
        
        
        
        

        
        

        
        bytes memory array = msg.data;
        uint256 index = msg.data.length;

        
        assembly {
            
            result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function _getRelayedCallData() private pure returns (bytes memory) {
        
        

        uint256 actualDataLength = msg.data.length - 20;
        bytes memory actualData = new bytes(actualDataLength);

        for (uint256 i = 0; i < actualDataLength; ++i) {
            actualData[i] = msg.data[i];
        }

        return actualData;
    }
}

interface IInShifter {
    

    function shiftIn(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);
    function shiftInFee() external view returns (uint256);
}

interface IOutShifter {
    

    function shiftOut(bytes calldata _to, uint256 _amount)
        external
        returns (uint256);
    function shiftOutFee() external view returns (uint256);
}

interface IShifter {
    
    function shiftIn(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);
    function shiftInFee() external view returns (uint256);
    
    function shiftOut(bytes calldata _to, uint256 _amount)
        external
        returns (uint256);
    function shiftOutFee() external view returns (uint256);
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

interface IShifterRegistry {

    
    
    event LogShifterRegistered(string _symbol, string indexed _indexedSymbol, address indexed _tokenAddress, address indexed _shifterAddress);
    event LogShifterDeregistered(string _symbol, string indexed _indexedSymbol, address indexed _tokenAddress, address indexed _shifterAddress);
    event LogShifterUpdated(address indexed _tokenAddress, address indexed _currentShifterAddress, address indexed _newShifterAddress);

    
    function getShifters(address _start, uint256 _count) external view returns (IShifter[] memory);

    
    function getShiftedTokens(address _start, uint256 _count) external view returns (IERC20[] memory);

    
    
    
    
    function getShifterByToken(address _tokenAddress) external view returns (IShifter);

    
    
    
    
    function getShifterBySymbol(string calldata _tokenSymbol) external view returns (IShifter);

    
    
    
    
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (IERC20);
}

contract BasicAdapter is GSNRecipient {
    IShifterRegistry registry;

    constructor(IShifterRegistry _registry) public {
        registry = _registry;
    }

    function shiftIn(
        
        string calldata _symbol,
        address _recipient,
        
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external {
        bytes32 payloadHash = keccak256(abi.encode(_symbol, _recipient));
        uint256 amount = registry.getShifterBySymbol(_symbol).shiftIn(
            payloadHash,
            _amount,
            _nHash,
            _sig
        );
        registry.getTokenBySymbol(_symbol).transfer(_recipient, amount);
    }

    function shiftOut(
        string calldata _symbol,
        bytes calldata _to,
        uint256 _amount
    ) external {
        require(
            registry.getTokenBySymbol(_symbol).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "token transfer failed"
        );
        registry.getShifterBySymbol(_symbol).shiftOut(_to, _amount);
    }

    

    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    ) external view returns (uint256, bytes memory) {
        return _approveRelayedCall();
    }

    
    function _preRelayedCall(bytes memory context) internal returns (bytes32) {}

    function _postRelayedCall(
        bytes memory context,
        bool,
        uint256 actualCharge,
        bytes32
    ) internal {}
}