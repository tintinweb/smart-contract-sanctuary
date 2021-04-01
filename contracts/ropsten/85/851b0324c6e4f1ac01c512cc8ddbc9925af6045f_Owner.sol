/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
 
 interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
}
 
contract Owner {
    struct Exchange {
        address fromAddr;
        uint amount;
    }
    mapping (uint => Exchange[]) public exchanges;
    address private owner;
    
    
    
    IERC20 usdt;
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    function add(address fromAddr, uint amount) public {
        exchanges[block.number].push(Exchange({fromAddr:fromAddr,amount:amount}));
    }
    
    function get(uint blocknumber) external view returns(address[] memory,uint[] memory){
        address[] memory addrs = new address[](exchanges[blocknumber].length);
        uint[]    memory amounts = new uint[](exchanges[blocknumber].length);

        for (uint i = 0; i < exchanges[blocknumber].length; i++) {
            Exchange storage exchange = exchanges[blocknumber][i];
            addrs[i] = exchange.fromAddr;
            amounts[i] = exchange.amount;
        }

        return (addrs, amounts);
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
     
	constructor(IERC20 _usdt)  {
        usdt = _usdt;
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }
    
    function  transferIn(address fromAddr, uint amount) external {
        usdt.transferFrom(fromAddr,owner, amount);
        add(fromAddr,amount);
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