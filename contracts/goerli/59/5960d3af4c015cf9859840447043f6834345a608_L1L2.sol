/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity ^0.6.12;
//SPDX-License-Identifier: UNLICENSED

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
        
     /**
      Message registry
     */
    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
}


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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


//////////////////////////////////////////////////////////////////////////////////////////////////
    
/**
  Demo contract for L1 <-> L2 interaction between an L2 StarkNet contract and this L1 solidity
  contract.
*/


contract L1L2 {
    // The StarkNet core contract.
    IStarknetCore public starknetCore;
	//l2 Gateway contract address
	uint256 public l2GatewayAddress;	
    
    // The selector of the "bridgeFromL2" , to get message from l1_handler.
    uint256 constant BRIDGE_FROM_L1_SELECTOR =
        1608925829256686334882985760601214942716272403838759250340789998968531558237;
        
    uint256 constant MESSAGE_WITHDRAW = 0;


    /**
      Initializes the contract state.
      The two contracts, cairo-solidit, have to be initialied in the following order: 1 deploy the cairo contract, 2 sol deploy with cairo address, 3 set the address of the sol contract on cairo. 
    */
    constructor(IStarknetCore starknetCore_, uint256 l2GatewayAddress_) public {
        starknetCore = starknetCore_;
        l2GatewayAddress = l2GatewayAddress_;
    }
    
    //events to be emitted
    event BridgeToStarknet(
        address indexed l1ERC20,
        uint256 indexed l2ERC20,
        uint256 indexed l2Account,
        uint256 amount
    );
    
    event BridgeFromStarknet(
        address indexed l1ERC20,
        uint256 indexed l2ERC20,
        address indexed l1Account,
        uint256 amount
    );
    
    
    function bridgeToL2(
        IERC20 l1ERC20Contract,
        uint256 l2ERC20Address,
        uint256 l2Owner,
        uint256 amount
    ) external {
        
    	// optimistic transfer, should revert if no approved or not owner
        l1ERC20Contract.transferFrom(msg.sender, address(this), amount);    
        
		uint256 amountLow = amount % 2**128;
		uint256 amountHigh = amount / 2**128;
        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](5);
        payload[0] = uint256(uint160(address(l1ERC20Contract)));
        payload[1] = l2ERC20Address;
        payload[2] = l2Owner;
        payload[3] = amountLow;
        payload[4] = amountHigh;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2ERC20Address, BRIDGE_FROM_L1_SELECTOR, payload);
        
        emit BridgeToStarknet(
            address(l1ERC20Contract),
            l2ERC20Address,
            l2Owner,
            amount
        );
    }

	

    function bridgeFromL2(
    	IERC20 l1ERC20Contract,
        uint256 l2ERC20Address,
        uint256 amount
    ) external {
        
        
		//do the processing for cairo
		uint256 amountLow = amount % 2**128;
		uint256 amountHigh = amount / 2**128;

		// Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](6);
        payload[0] = MESSAGE_WITHDRAW;
        payload[1] = uint256(uint160(address(l1ERC20Contract)));
        payload[2] = l2ERC20Address;
        payload[3] = uint256(uint160(address(msg.sender)));
        payload[4] = amountLow;
        payload[5] = amountHigh;

    
        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2GatewayAddress, payload);

        l1ERC20Contract.transfer(msg.sender, amount);
        
        emit BridgeFromStarknet(
            address(l1ERC20Contract),
            l2ERC20Address,
            address(msg.sender),
            amount
        );
    }    
    
    
    
    function bridgeEthToL2(
        IERC20 l1ERC20Contract,
        uint256 l2ERC20Address,
        uint256 l2Owner
    ) external payable {
        
        uint256 amount=msg.value;   
        
		uint256 amountLow = amount % 2**128;
		uint256 amountHigh = amount / 2**128;
        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](5);
        payload[0] = 0;
        payload[1] = l2ERC20Address;
        payload[2] = l2Owner;
        payload[3] = amountLow;
        payload[4] = amountHigh;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2ERC20Address, BRIDGE_FROM_L1_SELECTOR, payload);
        
        emit BridgeToStarknet(
            address(l1ERC20Contract),
            l2ERC20Address,
            l2Owner,
            amount
        );
    }
    
    function bridgeEthFromL2(
        uint256 l2ERC20Address, 
        uint256 amount
    ) external {
        
        
		//do the processing for cairo
		uint256 amountLow = amount % 2**128;
		uint256 amountHigh = amount / 2**128;

        uint256[] memory payload = new uint256[](6);
        payload[0] = MESSAGE_WITHDRAW;
        payload[1] = 0;
        payload[2] = l2ERC20Address;
        payload[3] = uint256(uint160(address(msg.sender)));
        payload[4] = amountLow;
        payload[5] = amountHigh;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ERC20Address, payload);

        // Update the L1 balance.
        (bool success, )=msg.sender.call{value:amount}("");
        require(success, "Transfer failed.");
        
    }
} 

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////