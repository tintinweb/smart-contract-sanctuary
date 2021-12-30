/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.4;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor()  {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


interface IBEP20 {

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
    function exchange(address user,uint8 flag,uint amount)external;

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

interface Iexchange {
    function exchange(address user,uint amount,uint8 flag)external;
}

contract Prediction is Ownable {
     using ECDSA for address;
    
    struct userDetails {
        address referer;
        address[] referals;
        uint earnings;
        uint8 directCount;
        bool status;
    }
    
    IBEP20 public token;
    Iexchange public Exchange;
    address public signer;
    uint public dollar = 10;
    uint public withdrawDollar = 25;
    uint public price = 1e18;
    bool public lockStatus;
    uint[5] public refCommisssion = [5,2,1,1,1];
    uint public adminCommisson;
    
    mapping(address => userDetails)public users;
    mapping(bytes32 => bool)public msgHash;
    
    event PlaceBid(address indexed from,address Pair,uint Amount,uint Commission,uint8 Flag,uint256 time);
    event Register(address indexed from,address referer,uint time);
    event Withdraw(address indexed from,uint Refamount,uint time);
    event ReferalCommission(address indexed from,address ref,uint amount,uint time);
     event SetSigner(address indexed user,address indexed signer);
    
    constructor (address _token,address _signer,address _exchange) {
        token = IBEP20(_token);
        Exchange = Iexchange(_exchange);
        signer = _signer;
        users[msg.sender].status = true;
    }
    
     modifier isLock() {
        require(lockStatus == false, "Piknwin: Contract Locked");
        _;
    }
    
    function checkPrice(
       uint8 _flag
    ) public view returns(uint _price){
        if (_flag == 1)
        _price = dollar*price;
        else if(_flag == 2)
        _price = withdrawDollar*price;
    }
    
    function updateDollarPrice(
        uint _withdraw,
        uint _dollar,
        uint _price
    ) public onlyOwner {
        withdrawDollar = _withdraw;
        price = _price;
        dollar = _dollar;
    }
    
    function register(
        address _ref
    ) public isLock{
        userDetails storage user = users[msg.sender];
        require(users[_ref].status,"Referer not exist");
        require(!user.status,"Already register");
        user.referer = _ref;
        user.status = true;
        users[_ref].referals.push(msg.sender);
        users[_ref].directCount++;
        emit Register(msg.sender,_ref,block.timestamp);
    }
    
    function placeBid(
       address _pair,
       uint _amount,
       uint8 _flag
    ) public isLock{
        require(_amount == checkPrice(1)+(checkPrice(1)*15/100),"Incorrect amt");
       // require(_amount >= checkPrice(1) && token.balanceOf(msg.sender) >= _amount+(_amount*15/100),"Invalid amt");
        require(_flag ==1 || _flag == 2 && _pair != address(0),"Incorect params");
        require(users[msg.sender].referer != address(0),"Not yet register");
        token.transferFrom(msg.sender,address(this),_amount);
        _refPayout(msg.sender,checkPrice(1)*15/100);
        emit PlaceBid(msg.sender,_pair,checkPrice(1),checkPrice(1)*15/100,_flag,block.timestamp);
    }
    
    function _refPayout(address _user,uint _amt)internal {
        (address ref) = users[_user].referer;
        for (uint8 i = 0;i<5;i++){
            ref = ref != address(0)?ref:owner();
            token.transfer(ref,_amt*refCommisssion[i]/15);
            emit ReferalCommission(_user,ref,_amt*refCommisssion[i]/15,block.timestamp);
            (ref) = users[ref].referer; 
        }
        adminCommisson += _amt*5/15;
    }
    
    function withdraw(uint _amount,uint time,bytes calldata signature)public {
        require(users[msg.sender].directCount >= 2 || _amount >= checkPrice(2),"Not eligible for withdraw");
        bytes32 messageHash = message(msg.sender,_amount,time);
        require(!msgHash[messageHash], "claim: signature duplicate");
        
           //Verifes signature    
        address src = verifySignature(messageHash, signature);
        require(signer == src, " claim: unauthorized");
        uint refPay = _amount*15/100;
        token.approve(address(Exchange),_amount - refPay);
        Exchange.exchange(msg.sender,_amount - refPay,2);
        msgHash[messageHash] = true;
        _refPayout(msg.sender,refPay);
        emit Withdraw(msg.sender,_amount - refPay,block.timestamp);
    }

    function verifySignature(bytes32 _messageHash, bytes memory _signature) public pure returns (address signatureAddress)
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(_messageHash);
        signatureAddress = ECDSA.recover(hash, _signature);
    }
    
    /**
    * @dev Returns hash for given data
    */
    function message(address _receiver ,uint amount,uint time)
        public pure returns(bytes32 messageHash)
    {
        messageHash = keccak256(abi.encodePacked(_receiver,amount,time));
    }
    
    function failSafe(address _toUser,uint _amount)public onlyOwner {
        require(_toUser != address(0),"Invalid address");
        require(_amount > 0,"Invalid amount");
        require(token.balanceOf(address(this)) >= _amount,"Insufficent amount");
        token.transfer(_toUser,_amount);
    }
    
    // updaate signer address
    function setSigner(address _signer)public onlyOwner{
        signer = _signer;
        emit SetSigner(msg.sender, _signer);
    }
    
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
}