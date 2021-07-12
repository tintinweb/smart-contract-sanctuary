/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// File: contracts/common-contracts/SafeMath.sol

pragma solidity ^0.5.17;

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

// File: contracts/common-contracts/ERC20Token.sol

pragma solidity ^0.5.17;

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

// File: contracts/common-contracts/HashChain.sol

pragma solidity ^0.5.17;

contract HashChain {
    bytes32 public tail;

    function _setTail(bytes32 _tail) internal {
        tail = _tail;
    }

    function _consume(bytes32 _parent) internal {
        require(
            keccak256(
                abi.encodePacked(_parent)
            ) == tail,
            'hash-chain: wrong parent'
        );
        tail = _parent;
    }
}

// File: contracts/common-contracts/AccessController.sol

pragma solidity ^0.5.17;

contract AccessController {

    address public ceoAddress;
    address public workerAddress;

    bool public paused = false;

    event CEOSet(address newCEO);
    event WorkerSet(address newWorker);

    event Paused();
    event Unpaused();

    constructor() public {
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

// File: contracts/common-contracts/EIP712Base.sol

pragma solidity ^0.5.17;

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));

    bytes32 internal domainSeperator;

    constructor(string memory name, string memory version) public {
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

// File: contracts/treasury-example/Treasury.sol

pragma solidity ^0.5.17;






contract BiconomyHelper is EIP712Base {

    using SafeMath for uint256;

    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    uint256 constant defaultTimeFrame = 12 hours;

    mapping(address => uint256) nonces;
    mapping(address => uint256) public enabledTill;
    mapping(address => uint256) public timeFrame;

    modifier onlyEnabledOrNewAccount(address _account) {
        require(
            enabledTill[_account] > now ||
            enabledTill[_account] == 0,
            'Treasury: disabled account'
        );
        _;
    }

    modifier onlyEnabledAccountStrict(address _account) {
        require(
            enabledTill[_account] > now,
            'Treasury: disabled account'
        );
        _;
    }

     /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function enableAccountMetaTx(
        address userAddress,
        bytes memory functionSignature,
        uint256 sessionDuration,
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
        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress, msg.sender)
        );

        require(success, "Treasury: Function call not successfull");
        nonces[userAddress] = nonces[userAddress] + 1;

        _enableAccount(userAddress, sessionDuration);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        return returnData;
    }

    function getNonce(address user) public view returns(uint256 nonce) {
        nonce = nonces[user];
    }


    function enableAccount(uint256 _sessionDuration) external {
        _enableAccount(msg.sender, _sessionDuration);
    }

    function _enableAccount(address _user, uint256 _sessionDuration) internal {
        timeFrame[_user] = _sessionDuration;
        enabledTill[_user] = now.add(
            timeFrame[_user]
        );
    }

    function getTimeFrame(address _account) internal view returns (uint256) {
        return timeFrame[_account] > 0 ? timeFrame[_account] : defaultTimeFrame;
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

contract TransferHelper {

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)' // 0xa9059cbb
            )
        )
    );

    bytes4 private constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                'transferFrom(address,address,uint256)' // 0x23b872dd
            )
        )
    );

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER, // 0xa9059cbb
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            'TransferHelper: TRANSFER_FAILED'
        );
    }

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            'TransferHelper: TRANSFER_FROM_FAILED'
        );
    }

}

contract GameController is AccessController {

    using SafeMath for uint256;

    enum GameStatus { Empty, Enabled, Disabled }

    struct Game {
        address gameAddress;
        string gameName;
    }

    struct GameSettings {
        uint8 index;
        GameStatus status;
    }

    Game[] public treasuryGames;
    mapping(address => GameSettings) public settings;
    mapping(uint8 => mapping(uint8 => uint256)) gameTokens;
    mapping(uint8 => mapping(uint8 => uint128)) maximumBet;

    modifier onlyDeclaredGame(uint8 _gameIndex) {
        require(
            settings[
                treasuryGames[_gameIndex].gameAddress
            ].status != GameStatus.Empty,
            "Treasury: game is not declared!"
        );
        _;
    }

    modifier onlyEnabledGame(uint8 _gameIndex) {
        require(
            settings[
                treasuryGames[_gameIndex].gameAddress
            ].status == GameStatus.Enabled,
            "Treasury: game must be enabled!"
        );
        _;
    }

    modifier onlyDisabledGame(uint8 _gameIndex) {
        require(
            settings[
                treasuryGames[_gameIndex].gameAddress
            ].status == GameStatus.Disabled,
            "Treasury: game must be disabled!"
        );
        _;
    }

   function addGame(
        address _newGameAddress,
        string calldata _newGameName,
        bool _isActive
    ) external onlyCEO {
        require(
            settings[_newGameAddress].status == GameStatus.Empty,
            'Treasury: game already declared!'
        );
        treasuryGames.push(
            Game({
                gameAddress: _newGameAddress,
                gameName: _newGameName
            })
        );
        settings[_newGameAddress].index = uint8(treasuryGames.length - 1);
        settings[_newGameAddress].status = _isActive == true
            ? GameStatus.Enabled
            : GameStatus.Disabled;
    }

    function getGameIndex(
        address _gameAddress
    ) internal view returns (uint8) {
        require(
            settings[_gameAddress].status != GameStatus.Empty,
            'Treasury: game is not declared!'
        );
        return settings[_gameAddress].index;
    }

    function updateGameAddress(
        uint8 _gameIndex,
        address _newGameAddress
    ) external onlyCEO onlyDeclaredGame(_gameIndex) {

        require(
            settings[_newGameAddress].status == GameStatus.Empty,
            'Treasury: game with new address already declared!'
        );

        settings[_newGameAddress] = settings[treasuryGames[_gameIndex].gameAddress];
        delete settings[treasuryGames[_gameIndex].gameAddress];
        treasuryGames[_gameIndex].gameAddress = _newGameAddress;
    }

    function updateGameName(
        uint8 _gameIndex,
        string calldata _newGameName
    ) external onlyCEO {
        treasuryGames[_gameIndex].gameName = _newGameName;
    }

    function enableGame(
        uint8 _gameIndex
    ) external onlyCEO onlyDisabledGame(_gameIndex) {
        settings[
            treasuryGames[_gameIndex].gameAddress
        ].status = GameStatus.Enabled;
    }

    function disableGame(
        uint8 _gameIndex
    ) external onlyCEO onlyEnabledGame(_gameIndex) {
        settings[
            treasuryGames[_gameIndex].gameAddress
        ].status = GameStatus.Disabled;
    }

    function addGameTokens(uint8 _gameIndex, uint8 _tokenIndex, uint256 _amount) internal {
        gameTokens[_gameIndex][_tokenIndex] = gameTokens[_gameIndex][_tokenIndex].add(_amount);
    }

    function subGameTokens(uint8 _gameIndex, uint8 _tokenIndex, uint256 _amount) internal {
        gameTokens[_gameIndex][_tokenIndex] = gameTokens[_gameIndex][_tokenIndex].sub(_amount);
    }

}

contract TokenController is AccessController {

    struct Token {
        address tokenAddress;
        string tokenName;
    }

    Token[] public treasuryTokens;

    function addToken(
        address _tokenAddress,
        string memory _tokenName
    ) public onlyCEO {
        treasuryTokens.push(Token({
            tokenAddress: _tokenAddress,
            tokenName: _tokenName
        }));
    }

    function getTokenInstance(
        uint8 _tokenIndex
    ) internal view returns (ERC20Token) {
        return ERC20Token(treasuryTokens[_tokenIndex].tokenAddress);
    }

    function getTokenAddress(
        uint8 _tokenIndex
    ) public view returns (address) {
        return treasuryTokens[_tokenIndex].tokenAddress;
    }

    function getTokenName(
        uint8 _tokenIndex
    ) external view returns (string memory) {
        return treasuryTokens[_tokenIndex].tokenName;
    }

    function updateTokenAddress(
        uint8 _tokenIndex,
        address _newTokenAddress
    ) external onlyCEO {
        treasuryTokens[_tokenIndex].tokenAddress = _newTokenAddress;
    }

    function updateTokenName(
        uint8 _tokenIndex,
        string calldata _newTokenName
    ) external onlyCEO {
        treasuryTokens[_tokenIndex].tokenName = _newTokenName;
    }

    function deleteToken(
        uint8 _tokenIndex
    ) external onlyCEO {
        ERC20Token token = getTokenInstance(_tokenIndex);
        require(
            token.balanceOf(address(this)) == 0,
            'TokenController: balance detected'
        );
        delete treasuryTokens[_tokenIndex];
    }
}

contract Treasury is GameController, TokenController, HashChain, TransferHelper, BiconomyHelper {

    using SafeMath for uint256;

    constructor(
        address _defaultTokenAddress,
        string memory _defaultTokenName
    ) public EIP712Base('Treasury', 'v2.1') {
        addToken(_defaultTokenAddress, _defaultTokenName);
    }

    function disableAccount(
        address _account
    )
        external
        onlyWorker
    {
        enabledTill[_account] = now;
    }

    function tokenInboundTransfer(
        uint8 _tokenIndex,
        address _from,
        uint256 _amount
    )
        external
        onlyEnabledOrNewAccount(_from)
        returns (bool)
    {
        uint8 _gameIndex = getGameIndex(msg.sender);
        address _token = getTokenAddress(_tokenIndex);
        addGameTokens(_gameIndex, _tokenIndex, _amount);
        safeTransferFrom(_token, _from, address(this), _amount);
        enabledTill[_from] = now.add(getTimeFrame(msg.sender));
        return true;
    }

    function tokenOutboundTransfer(
        uint8 _tokenIndex,
        address _to,
        uint256 _amount
    )
        external
        onlyEnabledAccountStrict(_to)
        returns (bool)
    {
        uint8 _gameIndex = getGameIndex(msg.sender);
        address _token = getTokenAddress(_tokenIndex);
        subGameTokens(_gameIndex, _tokenIndex, _amount);
        safeTransfer(_token, _to, _amount);
        return true;
    }

    function setMaximumBet(
        uint8 _gameIndex,
        uint8 _tokenIndex,
        uint128 _maximumBet
    ) external onlyCEO onlyDeclaredGame(_gameIndex) {
        maximumBet[_gameIndex][_tokenIndex] = _maximumBet;
    }

    function gameMaximumBet(
        uint8 _gameIndex,
        uint8 _tokenIndex
    ) external view onlyDeclaredGame(_gameIndex) returns (uint256) {
        return maximumBet[_gameIndex][_tokenIndex];
    }

    function getMaximumBet(
        uint8 _tokenIndex
    ) external view returns (uint128) {
        uint8 _gameIndex = getGameIndex(msg.sender);
        return maximumBet[_gameIndex][_tokenIndex];
    }

    function deleteGame(
        uint8 _gameIndex
    ) public onlyCEO {
        for (uint8 _tokenIndex = 0; _tokenIndex < treasuryTokens.length; _tokenIndex++) {
            _withdrawGameTokens(
                _gameIndex, _tokenIndex, gameTokens[_gameIndex][_tokenIndex]
            );
            gameTokens[_gameIndex][_tokenIndex] = 0;
            maximumBet[_gameIndex][_tokenIndex] = 0;
        }
        delete treasuryGames[_gameIndex];
    }

    function checkApproval(
        address _userAddress,
        uint8 _tokenIndex
    ) external view returns (uint256) {
        return getTokenInstance(_tokenIndex).allowance(
            _userAddress,
            address(this)
        );
    }

    function() external payable {
        revert();
    }

    function addFunds(
        uint8 _gameIndex,
        uint8 _tokenIndex,
        uint256 _tokenAmount
    ) external {

        require(
            _gameIndex < treasuryGames.length,
            'Treasury: unregistered gameIndex'
        );

        require(
            _tokenIndex < treasuryTokens.length,
            'Treasury: unregistered tokenIndex'
        );

        ERC20Token token = getTokenInstance(_tokenIndex);
        addGameTokens(_gameIndex, _tokenIndex, _tokenAmount);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
    }

    function checkAllocatedTokens(
        uint8 _tokenIndex
    ) external view returns (uint256) {
        uint8 _gameIndex = getGameIndex(msg.sender);
        return _checkAllocatedTokens(_gameIndex, _tokenIndex);
    }

    function _checkAllocatedTokens(
        uint8 _gameIndex,
        uint8 _tokenIndex
    ) internal view returns (uint256) {
        return gameTokens[_gameIndex][_tokenIndex];
    }

    function checkGameTokens(
        uint8 _gameIndex,
        uint8 _tokenIndex
    ) external view returns (uint256) {
        return _checkAllocatedTokens(_gameIndex, _tokenIndex);
    }

    function _withdrawGameTokens(
        uint8 _gameIndex,
        uint8 _tokenIndex,
        uint256 _amount
    ) internal {
        ERC20Token token = getTokenInstance(_tokenIndex);
        subGameTokens(_gameIndex, _tokenIndex, _amount);
        token.transfer(ceoAddress, _amount);
    }

    function withdrawGameTokens(
        uint8 _gameIndex,
        uint8 _tokenIndex,
        uint256 _amount
    ) external onlyCEO {
        _withdrawGameTokens(_gameIndex, _tokenIndex, _amount);
    }

    function withdrawTreasuryTokens(
        uint8 _tokenIndex
    ) public onlyCEO {

        ERC20Token token = getTokenInstance(_tokenIndex);

        uint256 amount = token.balanceOf(
            address(this)
        );

        for (uint256 i = 0; i < treasuryGames.length; i++) {
            uint8 _gameIndex = settings[
                treasuryGames[i].gameAddress
            ].index;
            gameTokens[_gameIndex][_tokenIndex] = 0;
        }
        token.transfer(ceoAddress, amount);
    }

    function setTail(
        bytes32 _tail
    ) external onlyCEO {
        _setTail(_tail);
    }

    function consumeHash(
        bytes32 _localhash
    ) external returns (bool) {
        require(
            settings[msg.sender].status == GameStatus.Enabled,
            'Treasury: active-game not present'
        );
        _consume(_localhash);
        return true;
    }
}