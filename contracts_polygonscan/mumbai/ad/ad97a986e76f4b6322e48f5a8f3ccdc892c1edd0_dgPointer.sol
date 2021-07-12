/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// SPDX-License-Identifier: -- 🎲 --

pragma solidity ^0.7.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'SafeMath: modulo by zero');
        return a % b;
    }
}

contract AccessController {

    address public ceoAddress;
    address public workerAddress;

    bool public paused = false;

    // mapping (address => enumRoles) accessRoles; // multiple operators idea

    event CEOSet(address newCEO);
    event WorkerSet(address newWorker);

    event Paused();
    event Unpaused();

    constructor() {
        ceoAddress = msg.sender;
        workerAddress = msg.sender;
        emit CEOSet(ceoAddress);
        emit WorkerSet(workerAddress);
    }

    modifier onlyCEO() {
        require(
            msg.sender == ceoAddress,
            'AccessControl: CEO access denied'
        );
        _;
    }

    modifier onlyWorker() {
        require(
            msg.sender == workerAddress,
            'AccessControl: worker access denied'
        );
        _;
    }

    modifier whenNotPaused() {
        require(
            !paused,
            'AccessControl: currently paused'
        );
        _;
    }

    modifier whenPaused {
        require(
            paused,
            'AccessControl: currenlty not paused'
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(
            _newCEO != address(0x0),
            'AccessControl: invalid CEO address'
        );
        ceoAddress = _newCEO;
        emit CEOSet(ceoAddress);
    }

    function setWorker(address _newWorker) external {
        require(
            _newWorker != address(0x0),
            'AccessControl: invalid worker address'
        );
        require(
            msg.sender == ceoAddress || msg.sender == workerAddress,
            'AccessControl: invalid worker address'
        );
        workerAddress = _newWorker;
        emit WorkerSet(workerAddress);
    }

    function pause() external onlyWorker whenNotPaused {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyCEO whenPaused {
        paused = false;
        emit Unpaused();
    }
}

interface ERC20Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));

    bytes32 internal domainSeperator;

    constructor(string memory name, string memory version) {
      domainSeperator = keccak256(abi.encode(
			EIP712_DOMAIN_TYPEHASH,
			keccak256(bytes(name)),
			keccak256(bytes(version)),
			getChainID(),
			address(this)
		));
    }

    function getChainID() internal pure returns (uint256 id) {
		assembly {
			id := 5 // set to Goerli for now, Mainnet later
		}
	}

    function getDomainSeperator() private view returns(bytes32) {
		return domainSeperator;
	}

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash));
    }

}

abstract contract ExecuteMetaTransaction is EIP712Base {

    using SafeMath for uint256;

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    bytes32 internal constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    mapping(address => uint256) internal nonces;

    struct MetaTransaction {
		uint256 nonce;
		address from;
        bytes functionSignature;
	}

    function getNonce(address user) public view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

}

contract dgPointer is AccessController, ExecuteMetaTransaction {

    using SafeMath for uint256;

    uint256 constant MAX_BONUS = 140;
    uint256 constant MIN_BONUS = 100;

    bool public collectingEnabled;
    bool public distributionEnabled;

    ERC20Token public distributionToken;

    mapping(address => bool) public declaredContracts;
    mapping(address => uint256) public pointsBalancer;
    mapping(address => uint256) public tokenToPointRatio;
    mapping(address => address) public affiliateData;

    constructor(
        address _distributionToken,
        string memory name,
        string memory version
    ) EIP712Base(name, version) {
        distributionToken = ERC20Token(_distributionToken);
    }

    function assignAffiliate(
        address _affiliate,
        address _player
    )
        external
        onlyWorker
        returns (bool)
    {
        require(
            affiliateData[_player] == address(0x0),
            'Pointer: player already affiliated'
        );
        affiliateData[_player] = _affiliate;
    }

    function addPoints(
        address _player,
        uint256 _points,
        address _token
    )
        external
        returns (
            uint256 newPoints,
            uint256 multiplierA,
            uint256 multiplierB
        )
    {
        return addPoints(
            _player,
            _points,
            _token,
            1,
            0
        );
    }

    function addPoints(
        address _player,
        uint256 _points,
        address _token,
        uint256 _numPlayers
    )
        public
        returns (
            uint256 newPoints,
            uint256 multiplier,
            uint256 multiplierB
        )
    {
        return addPoints(
            _player,
            _points,
            _token,
            _numPlayers,
            0
        );
    }

    function addPoints(
        address _player,
        uint256 _points,
        address _token,
        uint256 _numPlayers,
        uint256 _wearableBonus
    )
        public
        returns (
            uint256 newPoints,
            uint256 multiplierA,
            uint256 multiplierB
        )
    {
      if (_isDeclaredContract(msg.sender) && collectingEnabled) {

            multiplierA = getPlayerMultiplier(_numPlayers);
            multiplierB = getWearableMultiplier(_wearableBonus);

            newPoints = _points
                .div(tokenToPointRatio[_token])
                .mul(multiplierA + multiplierB)
                .div(100);

            pointsBalancer[_player] =
            pointsBalancer[_player].add(newPoints);

            _applyAffiliatePoints(
                _player,
                newPoints
            );
        }
    }

    function _applyAffiliatePoints(
        address _player,
        uint256 _points
    )
        internal
    {
        if (_isAffiliated(_player)) {
            pointsBalancer[affiliateData[_player]] =
            pointsBalancer[affiliateData[_player]] + _points.mul(20).div(100);
        }
    }

    function getPlayerMultiplier(
        uint256 baseAmount
    )
        internal
        pure
        returns (uint256)
        // possible return values 100, 110, 120, 130, 140
    {
        if (baseAmount == 1) return MIN_BONUS;
        return baseAmount > 4
            ? MAX_BONUS
            : MIN_BONUS.add(baseAmount.mul(10));
    }

    function getWearableMultiplier(
        uint256 baseAmount
    )
        internal
        pure
        returns (uint256)
        // possible return values 0, 10, 20, 30, 40
    {
        return baseAmount > 4
            ? MAX_BONUS - MIN_BONUS
            : baseAmount.mul(10);
    }

    function _isAffiliated(address _player) internal view returns (bool) {
        return affiliateData[_player] != address(0x0);
    }

    function getMyTokens() external returns(uint256 tokenAmount) {
        return distributeTokens(msg.sender);
    }

    function distributeTokensBulk(
        address[] memory _player
    )
        external
    {
        for(uint i = 0; i < _player.length; i++) {
            distributeTokens(_player[i]);
        }
    }

    function distributeTokens(
        address _player
    )
        public
        returns (uint256 tokenAmount)
    {
        require(
            distributionEnabled == true,
            'Pointer: distribution disabled'
        );
        tokenAmount = pointsBalancer[_player];
        pointsBalancer[_player] = 0;
        distributionToken.transfer(_player, tokenAmount);
    }

    // for easier testing on testnet - can be removed on mainnet
    function changeDistributionToken(address _newDistributionToken) external onlyCEO {
        distributionToken = ERC20Token(_newDistributionToken);
    }

    function setPointToTokenRatio(address _token, uint256 _ratio) external onlyCEO {
        tokenToPointRatio[_token] = _ratio;
    }

    function enableCollecting(bool _state) external onlyCEO {
        collectingEnabled = _state;
    }

    function enableDistribtion(bool _state) external onlyCEO {
        distributionEnabled = _state;
    }

    function declareContract(address _contract) external onlyCEO returns(bool) {
        declaredContracts[_contract] = true;
    }

    function unDeclareContract(address _contract) external onlyCEO returns(bool) {
        declaredContracts[_contract] = false;
    }

    function _isDeclaredContract(address _contract) internal view returns (bool) {
        return declaredContracts[_contract];
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        distributeTokens(userAddress);

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress, msg.sender)
        );

        require(success, "dgPointer: Function call not successfull");
        nonces[userAddress] = nonces[userAddress] + 1;

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        return returnData;
    }
}