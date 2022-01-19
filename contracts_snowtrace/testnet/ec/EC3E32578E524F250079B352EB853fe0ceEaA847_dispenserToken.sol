/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: Ownable.sol


pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
    constructor() {
        _transferOwnership(_msgSender());
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }

  
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

   
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: dispenserContract.sol


pragma solidity ^0.8.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract dispenserToken is Ownable{

    event payUser(address indexed walletUser, uint256 amount);
    address public _oracleWallet;
    address private _contractToken;

    IERC20 Ierc20;
    
   /* modifier onlyOracle() {
        require(_oracleWallet==msg.sender, "you are not the oracle");
        _;
    }*/


    constructor(){
        _contractToken=0x5BE9A5CcA3b8D0b2e20ed760A597e7Ad72AAB5ce;
        Ierc20=IERC20(_contractToken);
        _oracleWallet=0x9280b68557f27d35a359b4cBeA70424D8D8bf141;
    }

    receive() external payable {}

    fallback() external payable {}

    function rever()internal view{
        require(_oracleWallet==_msgSender(),"error de wallet");
    }
    function sendToken(address walletUser,uint amount)external returns(bool){     
        rever();   
        _sendToken(walletUser,amount);
        return true;
    }

    function withdrawLiquidity()external onlyOwner returns(bool){

     uint amount= Ierc20.balanceOf(address(this));

    _sendToken(owner(),amount);

    return true;
    }

    /*function setOracle(address _newOracle)external onlyOwner returns(bool){

        _oracleWallet=_newOracle;

        return true;

    }*/

    function _sendToken(address walletUser,uint amount)internal {
        require(Ierc20.balanceOf(address(this)) > 0 ,"no balance in the contract");
        Ierc20.transfer(walletUser,amount);
        emit payUser(walletUser,amount);  

    }

    function getBalance() external view returns(uint){

        return Ierc20.balanceOf(address(this));

    }

    function sendValue() external onlyOwner returns(bool){

        require(address(this).balance > 0,"without funds");

        (bool success, ) = payable(owner()).call{value:address(this).balance}("");

        require(success, "Address: unable to send value, recipient may have reverted");

        return true;
    }

}