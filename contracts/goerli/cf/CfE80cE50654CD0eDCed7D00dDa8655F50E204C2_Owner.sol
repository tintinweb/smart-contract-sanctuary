/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract bee is Owner {
    
    address public owner;
    
    IERC20 public bzz;
    
    constructor(IERC20 _bzz) {
        bzz = _bzz;
    }
    
    function addEthAndBzz(address[]  memory _to, uint256 _ethAmount, uint256 _bzzAmount) public isOwner {
        for(uint i = 0; i < _to.length; i++){
            // eth 
            // transfer(_to[i], _ethAmount);
            payable(_to[i]).transfer(_ethAmount);
            // bzz
            bzz.transfer(_to[i], _bzzAmount);
        }
        
    }
    
    receive() external payable {
            // React to receiving ether
    }
    
    function withdrawAll() external {
        bzz.transfer(msg.sender, bzz.balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function transfer(address payable receiver, uint256 _amount) public isOwner {
        receiver.transfer(_amount);
    }
    
}