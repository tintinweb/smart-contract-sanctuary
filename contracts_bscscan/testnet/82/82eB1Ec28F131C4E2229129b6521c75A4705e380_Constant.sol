/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// File: contracts/MerkleProof.sol

pragma solidity ^0.6.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// File: contracts/IERC20.sol

pragma solidity ^0.6.0;

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

// File: contracts/SafeMath.sol

pragma solidity  ^0.6.0;

contract SafeMath {
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
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeSub(a, b, "SafeMath: subtraction overflow");
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
    function safeSub(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        require(b <= a, error);
        uint256 c = a - b;
        return c;
    }

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
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeDiv(a, b, "SafeMath: division by zero");
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
    function safeDiv(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        require(b > 0, error);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function safeExponent(uint256 a,uint256 b) internal pure returns (uint256) {
        uint256 result;
        assembly {
            result:=exp(a, b)
        }
        return result;
    }
}

// File: contracts/Constant.sol

pragma solidity  ^0.6.0;

contract Constant {
    string constant ERR_CONTRACT_SELF_ADDRESS = "ERR_CONTRACT_SELF_ADDRESS";
    string constant ERR_ZERO_ADDRESS = "ERR_ZERO_ADDRESS";
    string constant ERR_NOT_OWN_ADDRESS = "ERR_NOT_OWN_ADDRESS";
    string constant ERR_VALUE_IS_ZERO = "ERR_VALUE_IS_ZERO";
    string constant ERR_AUTHORIZED_ADDRESS_ONLY = "ERR_AUTHORIZED_ADDRESS_ONLY";
    string constant ERR_NOT_ENOUGH_BALANCE = "ERR_NOT_ENOUGH_BALANCE";

    modifier notOwnAddress(address _which) {
        require(msg.sender != _which, ERR_NOT_OWN_ADDRESS);
        _;
    }

    // validates an address is not zero
    modifier notZeroAddress(address _which) {
        require(_which != address(0), ERR_ZERO_ADDRESS);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThisAddress(address _which) {
        require(_which != address(this), ERR_CONTRACT_SELF_ADDRESS);
        _;
    }

    modifier notZeroValue(uint256 _value) {
        require(_value > 0, ERR_VALUE_IS_ZERO);
        _;
    }
}

// File: contracts/Ownable.sol

pragma solidity  ^0.6.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Constant {
    
    address payable public owner;
    
    address payable public newOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _trasnferOwnership(msg.sender);
    }
    
    function _trasnferOwnership(address payable _whom) internal {
        emit OwnershipTransferred(owner,_whom);
        owner = _whom;
    }
    

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, ERR_AUTHORIZED_ADDRESS_ONLY);
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable _newOwner)
        external
        virtual
        notZeroAddress(_newOwner)
        onlyOwner
    {
        // emit OwnershipTransferred(owner, newOwner);
        newOwner = _newOwner;
    }
    
    function acceptOwnership() external
        virtual
        returns (bool){
            require(msg.sender == newOwner,"ERR_ONLY_NEW_OWNER");
            owner = newOwner;
            emit OwnershipTransferred(owner, newOwner);
            newOwner = address(0);
            return true;
        }
    
    
}

// File: contracts/MerkleDrop.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;





contract TokenVault {
    address public owner;
    address public token;

    constructor(address _owner, address _token) public {
        owner = _owner;
        token = _token;
    }
     /**
     * @dev transfers token to 'whom' address with 'amount'.
     */
    function transferToken(address _whom, uint256 _amount)
        public
        returns (bool)
    {
        require(msg.sender == owner, "caller should be owner");
        safeTransfer(_whom, _amount);
        return true;
    }

    function safeTransfer(address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))),"TransferHelper: TRANSFER_FAILED" );
    }
}

abstract contract MerkleDropStorage {
    
    /**
     *  airdropCreator - token airdropCreator
     * 'tokenAddress '  - token's contract address
     *  'amount' - amount of tokens to be airdropped
     *  'rootHash' -  merkle root hash
     *  'airdropDate' - airdrop creation date
     *  'airdropExpirationDate'- token's airdrop Exipration Date
     */
    struct MerkleAirDrop {
        address airdropCreator; 
        address tokenAddress; 
        bytes32 rootHash; 
        uint256 amount; 
        uint256 airdropStartDate; 
        uint256 airdropExpirationDate;
       
    }
    
    //Events
    event AirDropSubmitted(
        address indexed _airdropCreator,
        address indexed _token,
        uint256 _amount,
        uint256 _airdropDate,
        uint256 _airdropExpirationDate
    );

    event Claimed(address indexed account, uint256 amount, address vault);

    //Mapping
    mapping(address => MerkleAirDrop) public airdroppedtokens;
    mapping(address => mapping(uint256 => bool)) public claimedMap;
    mapping(bytes32 => address) public vaultAddress;
    
}

contract MerkleDrop is MerkleDropStorage,SafeMath,Ownable {
    using MerkleProof for bytes32[];
    
    address public tokenAddress;
    
    uint256 public feeInToken;
    
    uint256 public feeInEth;
    
    address public walletAddress;
    
    constructor(address _token,uint256 _feeToken,uint256 _feeEth,address _walletAddress)public{
        tokenAddress = _token;
        feeInToken = _feeToken;
        feeInEth = _feeEth;
        walletAddress = _walletAddress;
    }
    
    //To perform safe transfer of token
    function safeTransferFrom(
        address _token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))),"TransferHelper: TRANSFER_FROM_FAILED");
    }
    
    /**
     * @dev creates token airdrop.
     * 
     * @param
     * ' _token '  - token's contract address
     *  ' _amount' - amount of tokens to be airdropped
     *  '_root' -  merkle root hash
     *  '_airdropStartDate' airdrop start date
     *  '_airdropExpirationDate'- token's airdrop Exipration Date
     *  '_paymentInToken' - pay in tokens
     */
    function createAirDrop(
        address _token, 
        uint256 _amount, 
        bytes32 _root, 
        uint256  _airdropStartDate,
        uint256 _airdropExpirationDate,
        bool _paymentInToken
    ) external payable returns (bool) {
        if(_paymentInToken){
            IERC20(tokenAddress).transferFrom(msg.sender,walletAddress,feeInToken);
        }
        else{
            (bool success,) = walletAddress.call{value:feeInEth}(new bytes(0));
            require(success,"ERR_TRANSFER_FAILED");
        }
        require(vaultAddress[_root] == address(0),"ERR_HASH_ALREADY_CREATED");
        TokenVault vault = new TokenVault(address(this), _token);
        safeTransferFrom(_token, msg.sender, address(vault), _amount);
        MerkleAirDrop memory merkledrop = MerkleAirDrop(msg.sender,_token, _root,_amount,_airdropStartDate,_airdropExpirationDate);
        airdroppedtokens[address(vault)] = merkledrop;
        vaultAddress[_root] = address(vault);
        emit AirDropSubmitted(msg.sender,_token,_amount,now,_airdropExpirationDate);
        return true;
    }

    //To set token fee 
    function setTokenFee(uint256 _fee) external onlyOwner(){
        feeInToken = _fee;
    }
    
    //To set eth fee
    function setEthFee(uint256 _fee) external onlyOwner(){
        feeInEth = _fee;
    }
    
    //To set walletAddress
    function setWalletAddress(address _walletAddress)external onlyOwner(){
        walletAddress = _walletAddress;
    }
    
     /**
     * @dev to claim the airdropped tokens.
     * 
     *  @param
     * ' _hex'  - hex bytes
     *  ' _proof' - merkle proof
     *  'index' - address index
     *  '_amount' -  amount of token to be claimed
     */
    function claim(
        bytes32[] memory _hex,
        bytes32[][] memory _proof,
        uint256[] memory index,
        uint256[] memory amount
    ) external returns (bool) {
        address _userAddress = msg.sender;
        for (uint256 i = 0; i < _hex.length; i++) {
            address vault = vaultAddress[_hex[i]];
            MerkleAirDrop memory merkledrop = airdroppedtokens[vault];
            require(now > merkledrop.airdropStartDate ,"ERR_AIRDROP_NOT_STARTED");
            require(merkledrop.airdropExpirationDate > now,"ERR_AIRDROP_HAS_EXPIRED");
            require(!claimedMap[vault][index[i]],"ERR_AIRDROP_ALREADY_CLAIMED");
            bytes32 root = merkledrop.rootHash;
            bytes32 node = keccak256(abi.encodePacked(index[i], _userAddress, amount[i]));
            bytes32[] memory proof = _proof[i];
            if (MerkleProof.verify(proof, root, node)){
                TokenVault(vault).transferToken(msg.sender,amount[i]);
                claimedMap[vault][index[i]] = true;
                emit Claimed(msg.sender, amount[i],vault);
            }
        }
        return true;
    }

     /**
     * @dev to send the airdropped tokens back to AirDropper.
     * 
     *  @param
     * ' _vault'  - vault Address
     */
    function sendTokenBackToAirDropperByVault(address _vault) external returns (bool) {
        MerkleAirDrop memory merkledrop = airdroppedtokens[_vault];
        require(merkledrop.airdropCreator == msg.sender, "ERR_NOT_AUTHORIZED");
        require(merkledrop.airdropExpirationDate < now, "ERR_TOKEN_AIRDROP_HASNOT_EXPIRED");
        TokenVault(_vault).transferToken(merkledrop.airdropCreator,IERC20(TokenVault(_vault).token()).balanceOf(_vault));
        return true;
    }
    
    /**
     * @dev to send the airdropped tokens back to AirDropper.
     * 
     *  @param
     * ' _hex'  - hex bytes
     */
    function sendTokenBackToAirDropperByHex(bytes32 _hex) external returns (bool) {
        address _vault = vaultAddress[_hex];
        MerkleAirDrop memory merkledrop = airdroppedtokens[_vault];
        require(merkledrop.airdropCreator == msg.sender, "ERR_NOT_AUTHORIZED");
        require(merkledrop.airdropExpirationDate < now, "ERR_TOKEN_AIRDROP_HASNOT_EXPIRED");
        TokenVault(_vault).transferToken(merkledrop.airdropCreator,IERC20(TokenVault(_vault).token()).balanceOf(_vault));
        return true;
    }
    
    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }  
}