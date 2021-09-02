/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Context {

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor (){
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
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

contract bridge is Ownable {
    ERC20Interface public atariToken;
    uint256 public chainId;
    mapping(uint256 => bool) public supportedChainIds ;

    event Deposit(address indexed from,uint256 indexed amount,uint256 indexed toChainId);
    event Withdraw(address indexed to, uint256 indexed amount);

    constructor(address atariAddress,uint256 _chainId){
        atariToken = ERC20Interface(atariAddress);
        chainId = _chainId;

        //supported chain : Ethereum, BSC, Matic, Fantom
        supportedChainIds[1] = true;
        supportedChainIds[56] = true;
        supportedChainIds[137] = true;
        supportedChainIds[250] = true;

        //test
        // supportedChainIds[4002] = true;
        // supportedChainIds[31337] = true;
    }

    function deposit(uint256 amount, uint256 toChainId) external {
        require(toChainId != chainId&&supportedChainIds[toChainId],"deposit : unsupported chain");
        atariToken.transferFrom(msg.sender,address(this),amount);
        emit Deposit(msg.sender,amount,toChainId);
    }

    function withDraw(address to,uint256 amount) external onlyOwner {
        atariToken.transfer(to, amount);
        emit Withdraw(to,amount);
    }

    // claim tokens that sent by accidentally
    function claimToken(address token,address to,uint256 amount) external onlyOwner {
        ERC20Interface(token).transfer(to,amount);
    }
}