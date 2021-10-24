/**
 *Submitted for verification at polygonscan.com on 2021-10-23
*/

// File: contracts/EIP712Base.sol

pragma solidity >=0.5.16 <0.6.8;

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));

    bytes32 internal domainSeperator;

    uint256 private _chainid;

    constructor(string memory name, string memory version, uint256 chainid) public {
      _chainid = chainid;
      
      domainSeperator = keccak256(abi.encode(
			EIP712_DOMAIN_TYPEHASH,
			keccak256(bytes(name)),
			keccak256(bytes(version)),
			getChainID(),
			address(this)
		));
    }

    function getChainID() public view returns (uint256) {
		    return _chainid;
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

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

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

    constructor(string memory name, string memory version, uint256 chainid) public EIP712Base(name, version, chainid) {}

    function convertBytesToBytes4(bytes memory inBytes) internal pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(address userAddress,
        bytes memory functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns(bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(destinationFunctionSig != msg.sig, "functionSignature can not be of executeMetaTransaction method");
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionSignature)
        ));
    }

    function getNonce(address user) external view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(address user, MetaTransaction memory metaTx, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
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

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Prediction is Context,EIP712MetaTransaction {
    
     using SafeMath for uint256;
     
    IERC20 token;
    
    enum Options {
        none,
        team1,
        team2,
        tie
    }

    
    mapping(uint256 => string) public matchList;
    mapping(uint256 => bool) public matchIdExists;
    mapping(uint256 => bool) public matchActive;
    
    mapping(uint256 => string) public team1;
    mapping(uint256 => string) public team2;
    
    mapping(uint256 => uint256) public team1TotalEntry;
    mapping(uint256 => uint256) public team2TotalEntry;
    mapping(uint256 => uint256) public team3TotalEntry;
    
    mapping(uint256 => mapping(address => uint256)) public team1EntryByUser;
    mapping(uint256 => mapping(address => uint256)) public team2EntryByUser;
    mapping(uint256 => mapping(address => uint256)) public team3EntryByUser;
    
    mapping(uint256 => address[]) public team1Users;
    mapping(uint256 => address[]) public team2Users;
    mapping(uint256 => address[]) public team3Users;
    
    mapping(uint256 => uint256[]) public team1EntryPrice;
    mapping(uint256 => uint256[]) public team2EntryPrice;
    mapping(uint256 => uint256[]) public team3EntryPrice;
    
    mapping(uint256 => mapping(address => uint256)) public allTeamEntryByUser;
    
    mapping(uint256 => mapping(address => bool)) public matchEntryByUser;
    
    mapping(uint256 => Options) public winnerTeamByMatch;
    
    mapping(address => bool) public adminList;
    
    mapping(uint256 => mapping(address => Options)) public predictionEntryList;
    
    event AdminAdded(address indexed admin, address indexed newAdmin);
    event AdminRemoved(address indexed admin, address indexed oldAdmin);
    
    constructor(address _token) public EIP712MetaTransaction("Prediction", "1", 137) {
        token = IERC20(_token);
        adminList[msgSender()] = true;
    }
    
    function addMatch(uint256 _matchId, string calldata _matchName, string calldata _team1, string calldata _team2) external onlyOwner {
        require(!matchIdExists[_matchId], "Already Allocated");
        matchList[_matchId] = _matchName;
        team1[_matchId] = _team1;
        team2[_matchId] = _team2;
        matchIdExists[_matchId] = true;
        matchActive[_matchId] = true;
    }
    
    function deactivateMatch(uint256 _matchId) external onlyOwner {
        require(matchIdExists[_matchId], "No Match Available");
        matchActive[_matchId] = false;
    }
    
    function predictEntry(
        uint256 _matchId,
        Options _option,
        uint256 _value
    ) external {
        require(matchIdExists[_matchId], "No Match Available");
        require(matchActive[_matchId], "Match Not Active");
        require(!matchEntryByUser[_matchId][msgSender()], "Already Entered");
        if(_option == Options.team1) {
            team1TotalEntry[_matchId] = team1TotalEntry[_matchId] + _value;
            team1EntryByUser[_matchId][msgSender()] = _value;
            team1Users[_matchId].push(msgSender());
            team1EntryPrice[_matchId].push(_value);
        } else if(_option == Options.team2) {
            team2TotalEntry[_matchId] = team2TotalEntry[_matchId] + _value;
            team2EntryByUser[_matchId][msgSender()] = _value;
            team2Users[_matchId].push(msgSender());
            team2EntryPrice[_matchId].push(_value);
        }else if(_option == Options.tie) {
            team3TotalEntry[_matchId] = team3TotalEntry[_matchId] + _value;
            team3EntryByUser[_matchId][msgSender()] = _value;
            team3Users[_matchId].push(msgSender());
            team3EntryPrice[_matchId].push(_value);
        }
        allTeamEntryByUser[_matchId][msgSender()] = _value;
        predictionEntryList[_matchId][msgSender()] = _option;
        matchEntryByUser[_matchId][msgSender()] = true;
        token.transferFrom(msgSender(), address(this), _value);
    }
    
    function team1Wins(uint _matchId) external onlyOwner {
        uint lossTokens = team2TotalEntry[_matchId] + team3TotalEntry[_matchId];
        for(uint i =0;i<team1Users[_matchId].length;i++) {
            address winnerAddress = team1Users[_matchId][i];
            uint joinedToken = team1EntryByUser[_matchId][winnerAddress];
            uint multiplier = calculateDiv(lossTokens, team1TotalEntry[_matchId]);
            uint tokenWon = joinedToken.mul(multiplier);
            uint tokenWonETH = tokenWon.div(1e18);
            uint totalTokenToUser = joinedToken.add(tokenWonETH);
            token.transfer(winnerAddress, totalTokenToUser);
        }
        winnerTeamByMatch[_matchId] = Options.team1;
        matchActive[_matchId] = false;
    }
    
    function team2Wins(uint _matchId) external onlyOwner {
        uint lossTokens = team1TotalEntry[_matchId] + team3TotalEntry[_matchId];
        for(uint i =0;i<team2Users[_matchId].length;i++) {
            address winnerAddress = team2Users[_matchId][i];
            uint joinedToken = team2EntryByUser[_matchId][winnerAddress];
            uint multiplier = calculateDiv(lossTokens, team2TotalEntry[_matchId]);
            uint tokenWon = joinedToken.mul(multiplier);
            uint tokenWonETH = tokenWon.div(1e18);
            uint totalTokenToUser = joinedToken.add(tokenWonETH);
            token.transfer(winnerAddress, totalTokenToUser);
        }
        winnerTeamByMatch[_matchId] = Options.team2;
        matchActive[_matchId] = false;
    }
    
    function team3Wins(uint _matchId) external onlyOwner {
        uint lossTokens = team1TotalEntry[_matchId] + team2TotalEntry[_matchId];
        for(uint i =0;i<team3Users[_matchId].length;i++) {
            address winnerAddress = team3Users[_matchId][i];
            uint joinedToken = team3EntryByUser[_matchId][winnerAddress];
            uint multiplier = calculateDiv(lossTokens, team3TotalEntry[_matchId]);
            uint tokenWon = joinedToken.mul(multiplier);
            uint tokenWonETH = tokenWon.div(1e18);
            uint totalTokenToUser = joinedToken.add(tokenWonETH);
            token.transfer(winnerAddress, totalTokenToUser);
        }
        winnerTeamByMatch[_matchId] = Options.tie;
        matchActive[_matchId] = false;
    }
    
    function getTeam1WinData(uint _matchId) public view returns(uint[] memory, address[] memory) {
        uint lossTokens = team2TotalEntry[_matchId].add(team3TotalEntry[_matchId]);
        uint arrayLength = team1Users[_matchId].length;
        uint[] memory tokensToGive = new uint[](arrayLength);
        address[] memory addresses = new address[](arrayLength);
        for(uint i =0;i<team1Users[_matchId].length;i++) {
            address winnerAddress = team1Users[_matchId][i];
            uint joinedToken = team1EntryByUser[_matchId][winnerAddress];
            uint multiplier = calculateDiv(lossTokens, team1TotalEntry[_matchId]);
            uint tokenWon = joinedToken.mul(multiplier);
            uint tokenWonETH = tokenWon.div(1e18);
            uint totalTokenToUser = joinedToken.add(tokenWonETH);
            tokensToGive[i] = totalTokenToUser;
            addresses[i] = winnerAddress;
        }
        return (tokensToGive, addresses);
    }
    
    function getTeam2WinData(uint _matchId) public view returns(uint[] memory, address[] memory) {
        uint lossTokens = team1TotalEntry[_matchId].add(team3TotalEntry[_matchId]);
        uint arrayLength = team2Users[_matchId].length;
        uint[] memory tokensToGive = new uint[](arrayLength);
        address[] memory addresses = new address[](arrayLength);
        for(uint i =0;i<team2Users[_matchId].length;i++) {
            address winnerAddress = team2Users[_matchId][i];
            uint joinedToken = team2EntryByUser[_matchId][winnerAddress];
            uint multiplier = calculateDiv(lossTokens, team2TotalEntry[_matchId]);
            uint tokenWon = joinedToken.mul(multiplier);
            uint tokenWonETH = tokenWon.div(1e18);
            uint totalTokenToUser = joinedToken.add(tokenWonETH);
            tokensToGive[i] = totalTokenToUser;
            addresses[i] = winnerAddress;
        }
        return (tokensToGive, addresses);
    }
    
    function getTeam3WinData(uint _matchId) public view returns(uint[] memory, address[] memory) {
        uint lossTokens = team1TotalEntry[_matchId].add(team2TotalEntry[_matchId]);
        uint arrayLength = team3Users[_matchId].length;
        uint[] memory tokensToGive = new uint[](arrayLength);
        address[] memory addresses = new address[](arrayLength);
        for(uint i =0;i<team3Users[_matchId].length;i++) {
            address winnerAddress = team3Users[_matchId][i];
            uint joinedToken = team3EntryByUser[_matchId][winnerAddress];
            uint multiplier = calculateDiv(lossTokens, team3TotalEntry[_matchId]);
            uint tokenWon = joinedToken.mul(multiplier);
            uint tokenWonETH = tokenWon.div(1e18);
            uint totalTokenToUser = joinedToken.add(tokenWonETH);
            tokensToGive[i] = totalTokenToUser;
            addresses[i] = winnerAddress;
        }
        return (tokensToGive, addresses);
    }
    
    function calculateDiv(uint a, uint b) pure internal returns ( uint) {
        return a*(10**18)/b;
    }
    
    function cancelMatch(uint _matchId) external onlyOwner {
        for(uint i =0;i<team1Users[_matchId].length;i++) {
            address userAddress = team1Users[_matchId][i];
            token.transfer(userAddress, team1EntryByUser[_matchId][userAddress]);
        }
        for(uint i =0;i<team2Users[_matchId].length;i++) {
            address userAddress = team2Users[_matchId][i];
            token.transfer(userAddress, team2EntryByUser[_matchId][userAddress]);
        }
        for(uint i =0;i<team3Users[_matchId].length;i++) {
            address userAddress = team3Users[_matchId][i];
            token.transfer(userAddress, team3EntryByUser[_matchId][userAddress]);
        }
        matchActive[_matchId] = false;
    }
    
    function cancelTeam1(uint _matchId) external onlyOwner {
        for(uint i =0;i<team1Users[_matchId].length;i++) {
            address userAddress = team1Users[_matchId][i];
            token.transfer(userAddress, team1EntryByUser[_matchId][userAddress]);
        }
        matchActive[_matchId] = false;
    }
    
    function cancelTeam2(uint _matchId) external onlyOwner {
        for(uint i =0;i<team1Users[_matchId].length;i++) {
            address userAddress = team2Users[_matchId][i];
            token.transfer(userAddress, team2EntryByUser[_matchId][userAddress]);
        }
        matchActive[_matchId] = false;
    }
    
    function cancelTeam3(uint _matchId) external onlyOwner {
        for(uint i =0;i<team3Users[_matchId].length;i++) {
            address userAddress = team3Users[_matchId][i];
            token.transfer(userAddress, team3EntryByUser[_matchId][userAddress]);
        }
        matchActive[_matchId] = false;
    }
    
    function refund(address[] calldata _address, uint[] calldata _token) external onlyOwner {
        require(_address.length == _token.length, "Invalid Data");
        for(uint i =0;i<_address.length;i++) {
            address userAddress = _address[i];
            token.transfer(userAddress, _token[i]);
        }
    }
    
    
    function addAdmin(address _newAdmin)
        external
        onlyOwner
        validAddress(_newAdmin)
    {
        adminList[_newAdmin] = true;
        emit AdminAdded(msgSender(), _newAdmin);
    }

    function removeAdmin(address _oldAdmin)
        external
        onlyOwner
        validAddress(_oldAdmin)
    {
        require(adminList[_oldAdmin], "Not an Admin");
        adminList[_oldAdmin] = false;
        emit AdminRemoved(msgSender(), _oldAdmin);
    }

    modifier onlyOwner() {
        require(adminList[msgSender()], "Not owner");
        _;
    }
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }
}