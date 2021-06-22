/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() {
		owner = msg.sender;
		newOwner = address(0);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "only the owner can call this method");
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, "ownership cannot be transferred to address 0");
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
	    require(newOwner != address(0), "no new owner has been set up");
		require(msg.sender == newOwner, "only the new owner can accept ownership");
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

abstract contract tokenInterface {
	function balanceOf(address _owner) public virtual view returns (uint256 balance);
	function transfer(address _to, uint256 _value) public virtual returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool);
}

library ArrayManager {
    function add(bytes32[] storage arr, mapping(bytes32 => uint256) storage indexMapping, bytes32 element) internal {
        require(indexMapping[element] == 0, "The hash is already in the array.");
        arr.push(element);
        indexMapping[element] = arr.length;
    }

    function remove(bytes32[] storage arr, mapping(bytes32 => uint256) storage indexMapping, bytes32 element) internal {
        require(indexMapping[element] != 0, "The address is not in the array.");
        uint256 index = indexMapping[element]-1;
        
        bytes32 assetMoved = arr[arr.length-1];
        
        arr[index] = assetMoved;
        indexMapping[assetMoved] = index+1;
        
		indexMapping[element] = 0;
        arr.pop();
    }
}


contract AtomicBridge is Ownable {
    using SafeMath for uint256;
    using ArrayManager for bytes32[];
    
    uint256 public constant aliceRecoveryTime = 48 * 60 * 60;
    uint256 public constant bobRecoveryTime = 24 * 60 * 60;
    
    uint256 public DOSMitigationFee;
    uint256 public proposalDOSMitigationFee;
    uint256 public newFeeActivationTime;
    
    mapping (address => mapping (address => uint256)) public tknLockedOf;
    
    function setDOSMitigationFee(uint256 _newFee) public onlyOwner {
        proposalDOSMitigationFee = _newFee;
        newFeeActivationTime = block.timestamp;
    }
    
    function activeDOSMitigationFee() public onlyOwner {
        require( newFeeActivationTime != 0, "there is no new fee to be activated");
        uint256 activationDate = newFeeActivationTime + aliceRecoveryTime + bobRecoveryTime;
        require( block.timestamp > activationDate, "not enough time has passed not to change the rules");
        DOSMitigationFee = proposalDOSMitigationFee;
        proposalDOSMitigationFee = 0;
        newFeeActivationTime = 0;
    }
    
    struct deposit { 
        address payable from;
        address payable to;
        uint256 msgValue;
        address tokenAddress;
        uint256 tokenAmount;
        bool spent;
        uint256 recoveryStarted;
        bool isAlice;
    }
    mapping (bytes32 => deposit) public depositList;
    
    mapping (address => bytes32[]) public recoveryList;
    mapping(bytes32 => uint256) public indexOfrecoveryList;
    
    function readRecovery(address _user) public view returns(bytes32[] memory) {
        return recoveryList[_user];
    }
    
    function depositTkn(bytes32 _secretHash, uint256 _tokenAmount, address _tokenAddress, address payable _to, bool _isAlice) internal returns (bool) {
        require( depositList[_secretHash].from == address(0), "secret already used");
        

        tknLockedOf[msg.sender][_tokenAddress] = tknLockedOf[msg.sender][_tokenAddress].add(_tokenAmount);

        
        deposit memory d;
        d.from = payable(msg.sender);
        d.to = _to;
        d.tokenAddress = _tokenAddress;
        
        if ( _tokenAddress != address(0) && _tokenAmount > 0 ) {
            tokenInterface tkn = tokenInterface(_tokenAddress);
            tkn.transferFrom(msg.sender, address(this), _tokenAmount);
            d.tokenAmount = _tokenAmount;
        }
        
        if ( msg.value > 0 ) {
            d.msgValue = msg.value;
        }
        
        d.isAlice = _isAlice;
        depositList[_secretHash] = d;
        
        return true;
    }
    
    event DepositStarted(bytes32 indexed secretHash, bytes msg);
    function depositToken(bytes32 _secretHash, uint256 _tokenAmount, address _tokenAddress, address payable _to, bool _isAlice, bytes memory _msg) internal returns (bool) {
        depositTkn(_secretHash, _tokenAmount, _tokenAddress, _to, _isAlice);
        emit DepositStarted(_secretHash, _msg);
        return true;
    }
    
    event DepositStarted(bytes32 indexed secretHash);
    function depositWithoutMsg(bytes32 _secretHash, uint256 _tokenAmount, address _tokenAddress, address payable _to, bool _isAlice) internal returns (bool) {
        depositTkn(_secretHash, _tokenAmount, _tokenAddress, _to, _isAlice);
        emit DepositStarted(_secretHash);
        return true;
    }
    
    
    function depositTokenAlice(bytes32 _secretHash, uint256 _tokenAmount, address _tokenAddress, address payable _to, bytes memory _msg) public payable returns (bool) {
        return depositToken(_secretHash, _tokenAmount, _tokenAddress, _to, true, _msg);
    }
    
    function depositTokenBob(bytes32 _secretHash, uint256 _tokenAmount, address _tokenAddress, address payable _to, bytes memory _msg) public payable returns (bool) {
        return depositToken(_secretHash, _tokenAmount, _tokenAddress, _to, false, _msg);
    }
    
    function depositAliceWithoutMsg(bytes32 _secretHash, uint256 _tokenAmount, address _tokenAddress, address payable _to) public payable returns (bool) {
        return depositWithoutMsg(_secretHash, _tokenAmount, _tokenAddress, _to, true);
    }
    
    function depositBobWithoutMsg(bytes32 _secretHash, uint256 _tokenAmount, address _tokenAddress, address payable _to) public payable returns (bool) {
        return depositWithoutMsg(_secretHash, _tokenAmount, _tokenAddress, _to, false);
    }
    
    event withdrawStarted(bytes32 indexed secretHash, bytes32 secret);
    function withdrawToken(bytes32 _secret) public returns (bool) {
        bytes32 secretHash = keccak256(abi.encodePacked(_secret));
        deposit memory d = depositList[secretHash];
        
        require( d.from != address(0), "the secret hash does not exist");
        
        require( !d.spent, "withdrawal already done" );
        d.spent = true;

        depositList[secretHash] = d;
        
        tknLockedOf[d.from][d.tokenAddress] = tknLockedOf[d.from][d.tokenAddress].sub(d.tokenAmount);

        if (d.tokenAmount > 0) {
            tokenInterface tkn = tokenInterface(d.tokenAddress);
            tkn.transfer(d.to, d.tokenAmount);
        }
        
        if ( d.msgValue > 0 ) {
            d.to.transfer(d.msgValue);
        }
        
        emit withdrawStarted(secretHash, _secret);
        return true;
    }
    
    event RecoveryStarted(bytes32 indexed secretHash);
    function startRecovery(bytes32 _secretHash) public returns (bool) {
        deposit memory d = depositList[_secretHash];
        
        require( d.from == msg.sender, "only the same sender can start a recovery" );
        require( d.recoveryStarted == 0, "recovery is already started" );
        
        d.recoveryStarted = block.timestamp;
        depositList[_secretHash] = d;
        
		recoveryList[msg.sender].add(indexOfrecoveryList,_secretHash);
        emit RecoveryStarted(_secretHash);
        return true;
    }
    
    function recoveryWithdraw(bytes32 _secretHash) public payable returns (bool) {
        deposit memory d = depositList[_secretHash];
        require( d.from == msg.sender, "only the same sender can withdraw a recovery." );
        
        if( d.isAlice ) {
            require( block.timestamp >= d.recoveryStarted + aliceRecoveryTime, "You are not waiting long enough! You need to wait 48 hours" ); 
            
            require( msg.value >= DOSMitigationFee, "Not enough DOSMitigationFee");
            d.to.send(msg.value);
        } else {
            require( msg.value == 0, "only the creator of the secret has to pay the DOS Mitigation Fee");
            require( block.timestamp >= d.recoveryStarted + bobRecoveryTime, "You are not waiting long enough! You need to wait 24 hours" );
        }
        
        require( !d.spent, "deposit already spent" );
        d.spent = true;
        depositList[_secretHash] = d;

        tknLockedOf[d.from][d.tokenAddress] = tknLockedOf[d.from][d.tokenAddress].sub(d.tokenAmount);
		recoveryList[msg.sender].remove(indexOfrecoveryList,_secretHash);
        
        if (d.tokenAmount > 0) {
            tokenInterface tkn = tokenInterface(d.tokenAddress);
            tkn.transfer(d.from, d.tokenAmount);
        }   
        
        if ( d.msgValue > 0 ) {
            d.from.transfer(d.msgValue);
        }    
        
        return true;
    }
}