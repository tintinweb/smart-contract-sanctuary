//SourceUnit: CoinFlip.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CoinFlip is Ownable {

    constructor() payable public{ }

    using SafeMath for uint256;    
   
    bool private _gamePaused = false;
    bool private _gettokenPaused = false;    
    trcToken private _tokenid = 1004168;

    uint256 public _minSellamount = 1 trx;
    uint256 public _sellPrice = 100;

    uint256 public _minBetamount = 1000000;
    uint256 public _awardRate = 2;

    event Won(address winner, bool choice, uint256 bet, uint256 award);
    event Lost(address loser, bool choice, uint256 bet); 
    event Buy(address addr, uint256 amount);   

    function _getBit() view internal returns (bool){
        if( ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (address(this).tokenBalance(_tokenid) + address(msg.sender).tokenBalance(_tokenid) + address(msg.sender).balance)) % 2 == 0 )
            return false;
        else
            return true;
    }

    function BitBet(bool choice) payable public returns (bool){
        return _BitBet(choice);
    }

    function _BitBet(bool choice) internal returns (bool){
        require(!_gamePaused, "Game Paused");
        require(address(this).tokenBalance(_tokenid) >= (msg.tokenvalue * _awardRate), "Out of Balance in Contract");
        require(msg.tokenid == _tokenid, "Sent the wrong token");
        require(msg.tokenvalue >= _minBetamount, "Less than the minimum betting amount");    

        if ( _getBit() == choice ) {
            msg.sender.transferToken( (msg.tokenvalue * _awardRate), _tokenid );
            emit Won(msg.sender, choice, msg.tokenvalue, (msg.tokenvalue * _awardRate));
            return true;
        } else {
            emit Lost(msg.sender, choice, msg.tokenvalue);
            return false;
        }
    }  

    function getToken() payable public returns (bool){
        _getToken();
        return true;
    }

    function _getToken() internal {
        require(!_gettokenPaused, "getToken Paused");
        require(address(this).tokenBalance(_tokenid) >= (msg.value * _sellPrice), "Out of Balance in Contract");
        require(msg.value >= _minSellamount, "Less than the minimum purchase price"); 

        emit Buy(msg.sender, msg.value); 
        msg.sender.transferToken( (msg.value * _sellPrice), _tokenid );
    }    

    function setTokenid(trcToken tokenid) public onlyOwner {
        _tokenid = tokenid;
    }  

    function setAwardrate(uint256 value) public onlyOwner {
        _awardRate = value;
    }  

    function setMinbetamount(uint256 value) public onlyOwner {
        _minBetamount = value;
    }  

    function setMinsellamount(uint256 value) public onlyOwner {
        _minSellamount = value;
    }  

    function setSellprice(uint256 value) public onlyOwner {
        _sellPrice = value;
    }      

    function setGettokenpaused(bool paused) public onlyOwner {
        _gettokenPaused = paused;
    }

    function setGamepaused(bool paused) public onlyOwner {
        _gamePaused = paused;
    }    

    function withdrawal_all_token() public onlyOwner returns (bool) {
        msg.sender.transferToken(address(this).tokenBalance(_tokenid), _tokenid);
        return true;
    }

    function withdrawal_all_trx() public onlyOwner returns (bool) {
        msg.sender.transfer(address(this).balance);
        return true;        
    }      

    function withdrawal_token(uint256 amount) public onlyOwner returns (bool) {
        _withdrawal_token(amount);
        return true;
    }        

    function _withdrawal_token(uint256 amount) internal {
        if (address(this).tokenBalance(_tokenid) > 0) {        
            msg.sender.transferToken(amount, _tokenid);
        }
    }    

    function withdrawal_trx(uint256 amount) public onlyOwner returns (bool) {
        _withdrawal_trx(amount);
        return true;        
    }        
       
    function _withdrawal_trx(uint256 amount) internal {
        if (address(this).balance > 0) {
            msg.sender.transfer(amount);
        }
    }
}