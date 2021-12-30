/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract LudoGame is Ownable, Pausable {
    using SafeMath for uint256;
    
    IBEP20 public PRBToken;
    address public signer;
    address public feeWallet;

    uint256 public depositFee;
    uint256 public withdrawFee;

    struct UserInfo{
        address user;
        uint256 lastDepositTime;
    }

    mapping (address => UserInfo) userDetails;
    mapping (bytes32 => bool) public hashVerify;

    event UpdateSigner(address indexed owner, address indexed newSigner);
    event DepositToken (address indexed user, uint256 TokenAmount, uint256 depositTime);
    event WithdrawTokens (address indexed user, uint256 TokenAmount, uint256 blockTime);
    event Emergency(address indexed tokenAddres, address receiver, uint256 tokenAmount);

    constructor( address _PRBToken, address _signer, address _feeWallet) {
        PRBToken = IBEP20(_PRBToken);
        signer = _signer;
        feeWallet = _feeWallet;
    }

    function deposit(uint256 _tokenAmount) external payable whenNotPaused {
        require(msg.value >= depositFee,"Invalid depositFee");
        UserInfo storage user = userDetails[_msgSender()];
        user.user = _msgSender();
        user.lastDepositTime = block.timestamp;

        PRBToken.transferFrom(_msgSender(), address(this), _tokenAmount);
        require(payable(feeWallet).send(msg.value),"Fee transaction failed");

        emit DepositToken(_msgSender(), _tokenAmount, block.timestamp);
    }

    function withdraw(uint256 _tokenAmount, uint256 _blockTime, uint8 v, bytes32 r, bytes32 s) external payable whenNotPaused {
        require(msg.value >= withdrawFee,"Invalid depositFee");

        bytes32 msgHash = prepareHash(msg.sender, _tokenAmount, _blockTime);
        require(!hashVerify[msgHash],"Claim :: signature already used");
        require(verifySignature(msgHash, v,r,s) == signer,"Claim :: not a signer address");
        hashVerify[msgHash] = true;

        PRBToken.transfer(msg.sender, _tokenAmount);
        require(payable(feeWallet).send(msg.value),"Fee transaction failed");

        emit WithdrawTokens(msg.sender, _tokenAmount, _blockTime);
    }

    function setSigner(address _signer)external onlyOwner{
        require(_signer != address(0),"signer address not Zero address");
        signer = _signer;
        
        emit UpdateSigner(msg.sender, signer);
    }
    
    function verifySignature(bytes32 msgHash, uint8 v,bytes32 r, bytes32 s)public pure returns(address signerAdd){
        signerAdd = ecrecover(msgHash, v, r, s);
    }
    
    function prepareHash(address user, uint256 _tokenAmount, uint256 _blockTime)public view returns(bytes32){
        bytes32 hash = keccak256(abi.encodePacked(abi.encodePacked(user, _tokenAmount, _blockTime),address(this)));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    function emergency(address _tokenAddress, address _to, uint256 _tokenAmount) external onlyOwner {
        if(_tokenAddress == address(0x0)){
            require(payable(_to).send(_tokenAmount),"transaction failed");
        } else {
            IBEP20(_tokenAddress).transfer(_to, _tokenAmount);
        }

        emit Emergency(_tokenAddress, _to, _tokenAmount);
    }



}