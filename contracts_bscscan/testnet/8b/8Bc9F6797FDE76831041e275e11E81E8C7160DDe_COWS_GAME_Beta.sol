// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import {IUserCowsBoy} from './IUserCowsBoy.sol';
import {IERC20} from './IERC20.sol';
import {SafeMath} from './SafeMath.sol';
import {IERC721} from './IERC721.sol';
import {IERC721Enumerable} from './IERC721Enumerable.sol';
import {IERC721Metadata} from './IERC721Metadata.sol';
import {IUserCowsBoy} from './IUserCowsBoy.sol';
import {IVerifySignature} from './IVerifySignature.sol';
import './ReentrancyGuard.sol';


contract COWS_GAME_Beta is ReentrancyGuard {
    using SafeMath for uint256;
    address public operator;
    address public owner;
    bool public _paused = false;

    address public NFTOwner;
    address public COWS_TOKEN;
    address public RIM_TOKEN;   
    address public NSC_NFT_TOKEN;
    address public NEC_NFT_TOKEN;
    address public NEP_NFT_TOKEN;
    address public VERIFY_SIGNATURE;
    address public USER_COWSBOY;

    uint256 public constant DECIMAL_18 = 10**18;
    uint256 public constant PERCENTS_DIVIDER = 1000000000;

    struct UserInfo {
            uint256 cowsDeposit;
            uint256 rimDeposit;
            uint256 nscDeposit;
            uint256 necDeposit;
            uint256 nepDeposit;
            uint256 lastUpdatedAt;
            uint256 cowsRewardClaimed;
            uint256 rimRewardClaimed;
            uint256 nscRewardClaimed;
            uint256 necRewardClaimed;
            uint256 nepRewardClaimed;  
            uint8 status;  // 0 : not active ; 1 active ; 2 is lock ; 2 is ban
    }

    struct DepositedNFT {
        uint256[] depositedTokenIds;
        mapping(uint256 => uint256) tokenIdToIndex; //index + 1
    }
    
    mapping(address => UserInfo) public userInfo;
    //nft => user => DepositedNFT
    mapping(address => mapping(address => DepositedNFT)) nftUserInfo;
    //events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ChangeOperator(address indexed previousOperator, address indexed newOperator);
    event TokenDeposit(address token, address depositor, uint256 amount);
    event TokenWithdraw(
        address token,
        address withdrawer,
        uint256 amount,
        uint256 balance,
        uint256 spent,
        uint256 win
    );


    
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'INVALID owner');
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, 'INVALID operator');
        _;
    }

    constructor(address _operator) public {
        owner  = tx.origin;
        operator = _operator;
        COWS_TOKEN = 0xB084b320Da2a9AC57E06e143109cD69d495275e8;
        RIM_TOKEN = 0x7949636e8a517c48569872213723994443ACc00E;   
        NSC_NFT_TOKEN = 0x8Da85A0337141CDB9Adba71EC0106a2d564069D2;
        NEC_NFT_TOKEN = 0xe5b5fB222be8F1903D9cc61fC6E7895A03cdB4A2;
        NEP_NFT_TOKEN = 0x45c6b67C37183d5140c7334E3D56a62102b4F60a;
        USER_COWSBOY = 0x009fbfe571f29c3b994a0cd84B2f47b7e7D73CDC;
        VERIFY_SIGNATURE = 0x4f0736236903E5042abCc5F957fD0ae32f142405;
    }

    fallback() external {

    }

    receive() payable external {
        
    }

    function pause() public onlyOwner {
        _paused=true;
    }

    function unpause() public onlyOwner {
        _paused=false;
    }

    
    modifier ifPaused(){
        require(_paused,"");
        _;
    }

    modifier ifNotPaused(){
        require(!_paused,"");
        _;
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
    function _transferOwnership(address newOwner) internal onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`operator`).
     * Can only be called by the current owner.
     */
    function transferOperator(address _operator) public onlyOwner {
        emit ChangeOperator(operator , _operator);
        operator = _operator;
    }

    /**
    * @dev Withdraw Token to an address, revert if it fails.
    * @param recipient recipient of the transfer
    */
    function clearToken(address recipient, address token) public onlyOwner {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    /**
    * @dev Withdraw  BNB to an address, revert if it fails.
    * @param recipient recipient of the transfer
    */
    function clearBNB(address payable recipient) public onlyOwner {
        _safeTransferBNB(recipient, address(this).balance);
    }

    /**
    * @dev transfer BNB to an address, revert if it fails.
    * @param to recipient of the transfer
    * @param value the amount to send
    */
    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'BNB_TRANSFER_FAILED');
    }
    
    /**
    * @dev Update updateNFTOwner
    */
    function updateNFTOwner(address _NFTOwner) public onlyOwner {
        NFTOwner = _NFTOwner;
    }


    function getUserInfo (address account) public view returns(
            uint256 cowsDeposit,
            uint256 rimDeposit,
            uint256 nscDeposit,
            uint256 necDeposit,
            uint256 nepDeposit,
            uint256 lastUpdatedAt,
            uint256 cowsRewardClaimed,
            uint256 rimRewardClaimed,
            uint256 nscRewardClaimed,
            uint256 necRewardClaimed,
            uint256 nepRewardClaimed      
            ) {

            UserInfo storage _user = userInfo[account];      
            return (
                _user.cowsDeposit,
                _user.rimDeposit, 
                _user.nscDeposit,
                _user.necDeposit,
                _user.nepDeposit,
                _user.lastUpdatedAt,
                _user.cowsRewardClaimed,
                _user.rimRewardClaimed,
                _user.nscRewardClaimed,
                _user.necRewardClaimed,
                _user.nepRewardClaimed);
    }

   

    function depositCOWSToGame(uint256 amount) public ifNotPaused returns (bool)
    {
        require(IUserCowsBoy(USER_COWSBOY).isRegister(msg.sender) == true , "Address not whitelist registed system");
        uint256 allowance = IERC20(COWS_TOKEN).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        uint256 balance = IERC20(COWS_TOKEN).balanceOf(msg.sender);
        require(balance >= amount, "Sorry : not enough balance to buy ");
        _depositTokenToGame(msg.sender,COWS_TOKEN,amount);
        return true;
    }

    function depositRIMToGame(uint256 amount) public ifNotPaused returns (bool)
    {
        require(IUserCowsBoy(USER_COWSBOY).isRegister(msg.sender) == true , "Address not whitelist registed system");
        uint256 allowance = IERC20(RIM_TOKEN).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        uint256 balance = IERC20(RIM_TOKEN).balanceOf(msg.sender);
        require(balance >= amount, "Sorry : not enough balance to buy ");
        _depositTokenToGame(msg.sender,RIM_TOKEN,amount);
        return true;
    }

    function _depositTokenToGame(address depositor , address token, uint256 _amount) internal {
        require(token == COWS_TOKEN || token == RIM_TOKEN," Invalid token deposit");
        IERC20(token).transferFrom(depositor, address(this), _amount);
        if(token == COWS_TOKEN){
            userInfo[depositor].cowsDeposit += _amount;
        }
        if(token == RIM_TOKEN){
            userInfo[depositor].rimDeposit += _amount;
        }
        userInfo[depositor].lastUpdatedAt = block.timestamp;
        emit TokenDeposit(token,depositor,_amount);
    }


    function isSignOperator(uint256 _amount, string memory _message, uint256 _expiredTime, bytes memory _signature) public view returns (bool) 
    {
        return IVerifySignature(VERIFY_SIGNATURE).verify(operator, msg.sender, _amount, _message, _expiredTime, _signature);    
    }
        
    function withdrawCOWSTokens(
        uint256 amount,
        uint256 _amountSpent, // Spent in game 
        uint256 _amountWin, // Profit in game 
        string memory _message,
        uint256 _expiredTime,
        bytes memory signature
    ) external {
        require(block.timestamp < _expiredTime, "withdrawTokens: !expired");
    
        require(
            IVerifySignature(VERIFY_SIGNATURE).verify(operator, msg.sender, amount, _message, _expiredTime, signature) == true ,
            "invalid operator"
        );
        UserInfo storage _user = userInfo[msg.sender];

        require(_user.cowsDeposit - _amountSpent + _amountWin > 0 , "invalid balance ");
        require(_user.cowsDeposit - _amountSpent + _amountWin >= amount, "invalid amount");
        
        //return token 
        IERC20(COWS_TOKEN).transfer(msg.sender, amount);

       emit TokenWithdraw(
        COWS_TOKEN,
        msg.sender,
        amount,
        _user.cowsDeposit,
        _amountSpent,
        _amountWin);
        
        _user.cowsDeposit = _user.cowsDeposit - _amountSpent + _amountWin -  amount;
        _user.cowsRewardClaimed += amount;
        _user.lastUpdatedAt = block.timestamp;
    }
    
    function withdrawRIMTokens(
        uint256 amount,
        uint256 _amountSpent, // Spent in game 
        uint256 _amountWin, // Profit in game 
        string memory _message,
        uint256 _expiredTime,
        bytes memory signature
    ) external {
        require(block.timestamp < _expiredTime, "withdrawTokens: !expired");
    
        require(
            IVerifySignature(VERIFY_SIGNATURE).verify(operator, msg.sender, amount, _message, _expiredTime, signature) == true ,
            "invalid operator"
        );
        UserInfo storage _user = userInfo[msg.sender];

        require(_user.rimDeposit - _amountSpent + _amountWin > 0 , "invalid balance ");
        require(_user.rimDeposit - _amountSpent + _amountWin >= amount, "invalid amount");
        
        //return token 
        IERC20(RIM_TOKEN).transfer(msg.sender, amount);

       emit TokenWithdraw(
        RIM_TOKEN,
        msg.sender,
        amount,
        _user.rimDeposit,
        _amountSpent,
        _amountWin);
        
        _user.rimDeposit = _user.rimDeposit - _amountSpent + _amountWin -  amount;
        _user.rimRewardClaimed += amount;
        _user.lastUpdatedAt = block.timestamp;
    }

}