/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenPreSale is Ownable {
    // address of admin
    IERC20 public token;
    // token price variable
    uint256 public tokenprice;
    // count of token sold vaariable
    uint256 public totalsold; 
     
    event Sell(address sender,uint256 totalvalue); 
    event SetTokenPrice(uint256 tokenprice);
    event SetTokenAddress(address tokenaddress);

    // constructor 
    constructor(address _tokenaddress, uint256 _tokenvalue){
        tokenprice = _tokenvalue;
        token  = IERC20(_tokenaddress);
    }

    function setTokenAddress(address _tokenaddress) external onlyOwner {
        token  = IERC20(_tokenaddress);

        emit SetTokenAddress(_tokenaddress);
    }
   
    function setTokenPrice(uint256 _tokenvalue) external onlyOwner {
        tokenprice = _tokenvalue;

        emit SetTokenPrice(tokenprice);
    }

    function getTokenPrice() external view returns (uint256){
        return tokenprice;
    }

    // buyTokens function
    function buyTokens() public payable{
        address buyer = msg.sender;
        uint256 bnbAmount = msg.value;
        // check if the contract has the tokens or not
        require(token.balanceOf(address(this)) >= bnbAmount * tokenprice,'the smart contract dont hold the enough tokens');
        // transfer the token to the user
        token.transfer(buyer, bnbAmount * tokenprice);
        // increase the token sold
        totalsold += bnbAmount * tokenprice;
        // emit sell event for ui
        emit Sell(buyer, bnbAmount * tokenprice);
    }

    // end sale
    function endsale() public onlyOwner {
        // transfer all the remaining tokens to admin
        token.transfer(msg.sender, token.balanceOf(address(this)));
        // transfer all the etherum to admin and self selfdestruct the contract
        selfdestruct(payable(msg.sender));
    }
}