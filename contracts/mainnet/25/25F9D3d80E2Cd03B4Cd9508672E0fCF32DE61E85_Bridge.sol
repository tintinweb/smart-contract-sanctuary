// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


contract Bridge is Ownable{

    using SafeMath for uint256;

    uint256 public feeAmount;

    struct TxInfo{
        address from;
        address to;
        uint256 amount;
    }

    mapping(bytes32 => bool) depositTxHash;
    mapping(address => bool) verifier;
    mapping(bytes32 => TxInfo) txInfo;
    mapping(address => address) tokenOwner;
    mapping(address => address) tokenPair;
    mapping(address => address) reTokenPair;

    event Deposit(address indexed tokenAddr, address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed tokenAddr, address indexed from, address to, uint256 amount, bytes32 indexed txHash);
    event WithdrawInit(address indexed tokenAddr, address indexed to, uint256 amount);
    event WithdrawFee(address indexed to, uint256 amount);

    constructor (
       address _homeToken,
       address _foreignToken,
       address _verifier,
       uint256 _feeAmount
    ) public {
        tokenPair[_foreignToken] = _homeToken;
        reTokenPair[_homeToken] = _foreignToken;
        verifier[_verifier] = true;
        feeAmount = _feeAmount;
    }

    function deposit(address _homeToken, address _to, uint256 _amount) public payable {
        require(reTokenPair[_homeToken] != address(0), "deposit: pair not exist");
        IERC20 token = IERC20(_homeToken);
        require(msg.value >= feeAmount, "deposit: insufficient for fee");
        require(token.balanceOf(msg.sender) >= _amount, "deposit: insufficient token balance");
        token.transferFrom(msg.sender, address(this), _amount);
        emit Deposit(_homeToken, msg.sender, _to, _amount);
    }

    function withdraw(address _foreignToken, address _from, address _to, uint256 _amount, bytes32 _txHash) public {
        require(tokenPair[_foreignToken] != address(0), "withdraw: pair not exist");
        require(verifier[msg.sender] == true, "withdraw: permission denied");
        require(depositTxHash[_txHash] == false, "withdraw: duplicated hash");
        address homeTokenAddr = tokenPair[_foreignToken];
        safeTenTransfer(homeTokenAddr, _to, _amount);
        depositTxHash[_txHash] = true;
        TxInfo storage info = txInfo[_txHash];
        info.from = _from;
        info.to = _to;
        info.amount = _amount;
        emit Withdraw(homeTokenAddr, _from, _to, _amount, _txHash);
    }

    function withdrawInit(address _tokenAddr, address _to) public {
        require(tokenOwner[_tokenAddr] == msg.sender, "withdrawInit: permission denied");
        IERC20 token = IERC20(_tokenAddr);
        uint256 amount = token.balanceOf(address(this));
        safeTenTransfer(_tokenAddr, _to, amount);
        emit WithdrawInit(_tokenAddr, _to, amount);
    }

    function withdrawFee(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
        emit WithdrawFee(_to, address(this).balance);
    } 

    function addVerifier(address _verifier) public onlyOwner {
        verifier[_verifier] = true;
    }

    function subVerifier(address _verifier) public onlyOwner {
        verifier[_verifier] = false;
    }

    function setFee(uint256 _feeAmount) public onlyOwner {
        feeAmount = _feeAmount;
    }

    function setTokenOwner(address _tokenAddr, address _tokenOwner) public onlyOwner {
        tokenOwner[_tokenAddr] = _tokenOwner;
    }

    function setTokenPair(address _homeAddr, address _foreignAddr) public onlyOwner {
        tokenPair[_foreignAddr] = _homeAddr;
        reTokenPair[_homeAddr] = _foreignAddr;
    }

    function getBalance(address _tokenAddr) public view returns (uint256) {
        return IERC20(tokenPair[_tokenAddr]).balanceOf(address(this));
    }

    function safeTenTransfer(address _tokenAddr, address _to, uint256 _amount) internal {
        IERC20 token = IERC20(_tokenAddr);
        uint256 bal = token.balanceOf(address(this));
        if (_amount > bal) {
            token.transfer(_to, bal);
        } else {
            token.transfer(_to, _amount);
        }
    }

}