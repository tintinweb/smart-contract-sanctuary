/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity ^0.8.0;

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

contract Eth2BnbBridge {

    address public phnxAddress;
    address private signer;
    mapping(address=>uint256) public _nonce;
    mapping(bytes32=>bool) public sigRepeated;
    bytes32 private constant Hash_1 = 0x63c7f5cdb1d38bbec4fca06b08adbb3c338e225bf61b79696076f193b0a70f07;
    bytes32 private constant Hash_2 = 0xc17d317ce8d3846b73214929c7cc4a2a2679e1c043b10e5612748890112fb726;
    bytes32 private constant Hash_3 = 0x521953684645f878093bce1437e3c6d4d19a8a16cb0cb7379b2da2e14f5bb7cb;

    event TokenDeposited(address user,uint256 amount,uint8 v, bytes32 r, bytes32 s, uint256 _nonce);
    event TokenWithdrawn(address user,uint256 amount,uint8 v, bytes32 r, bytes32 s,uint256 _nonce);

    constructor(address _phnxAddress,address _signer) public{
        phnxAddress = _phnxAddress;
        signer = _signer;
    }
    function depositToken(uint256 amount,uint8 v, bytes32 r, bytes32 s) public {
        bytes32 encodeData = keccak256(abi.encode(msg.sender, amount,_nonce[msg.sender]));
        require(sigRepeated[encodeData]==false,"Same Signature Cannot Repeat");
        sigRepeated[encodeData] = true;
        _validateSignedData(encodeData,v,r,s);
        IERC20(phnxAddress).transferFrom(msg.sender,address(this),amount);
        emit TokenDeposited(msg.sender,amount,v,r,s,_nonce[msg.sender]);
        _nonce[msg.sender] += 1; 
    }

    function withdrawToken(uint256 amount ,uint256 _nonce ,uint8 v1, bytes32 r1, bytes32 s1,uint8 v2, bytes32 r2, bytes32 s2) public {
        bytes32 encodeData = keccak256(abi.encode(v1,r1,s1,_nonce));
        require(sigRepeated[encodeData]==false,"Same Signature Cannot Repeat");
        sigRepeated[encodeData] = true;
        _validateSignedData(encodeData,v2,r2,s2);
        IERC20(phnxAddress).transfer(msg.sender,amount);
        emit TokenWithdrawn(msg.sender,amount,v2,r2,s2,_nonce);
    }

    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(Hash_1, Hash_2, Hash_3, 4, address(this)));
    }

    function _validateSignedData(
        bytes32 encodeData,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), encodeData));
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "Eth2BnbBridge:: INVALID_SIGNATURE");
    }
}