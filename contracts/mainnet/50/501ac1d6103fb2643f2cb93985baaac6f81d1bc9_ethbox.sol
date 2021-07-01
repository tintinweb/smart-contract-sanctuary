/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


//------------------------------------------------------------------------------------------------------------------
//
// ethbox
//
// https://www.ethbox.org/
//
//
// ethbox is a smart contract based escrow service. Instead of sending funds from A to B,
// users send funds through ethbox. This enables users to abort outgoing transactions
// in case of a wrong recipient address.
//
// Funds are put in "boxes". Each box contains all the relevant data for that transaction.
// Boxes can be secured with a passphrase. Users can request ETH or tokens in return
// for their deposit (= OTC trade).
//
// The passphrase gets hashed twice. This is because the smart contract needs to do
// its own hashing so that it cannot be manipulated - But the passphrase shouldn't
// be submitted in clear-text all over the web, so it gets hashed, and the hash of
// that is stored on the smart contract, so it can recognize when it is given the
// correct passphrase.
//
// Depositing funds into contract = createBox(...)
// Retrieving funds from contract = clearBox(...)
//
//------------------------------------------------------------------------------------------------------------------


contract ethbox
{
    // Transaction data
    struct Box {
        address         payable sender;
        address         recipient;
        bytes32         passHashHash;
        ERC20Interface  sendToken;
        uint            sendValue;
        ERC20Interface  requestToken;
        uint            requestValue;
        uint            timestamp;
        bool            taken;
    }

	struct BoxWithPrivacy {
        bytes32         senderHash;
        bytes32         recipientHash;
        bytes32         passHashHash;
        ERC20Interface  sendToken;
        uint            sendValue;
        uint            timestamp;
        bool            taken;
    }
    
	address owner;
	bool public stopDeposits = false; 

	Box[] boxes;
	BoxWithPrivacy[] boxesWithPrivacy;   

    // Map box indexes to addresses for easier handling / privacy, so users are shown only their own boxes by the contract
    mapping(address => uint[]) senderMap;
    mapping(address => uint[]) recipientMap;
	mapping(bytes32 => uint[]) senderMapWithPrivacy;
    mapping(bytes32 => uint[]) recipientMapWithPrivacy;


    // Deposit funds into contract
    function createBox(address _recipient, ERC20Interface _sendToken, uint _sendValue, ERC20Interface _requestToken, uint _requestValue, bytes32 _passHashHash) external payable
    {
        // Make sure deposits haven't been disabled (will be done when switching to new contract version)
        require(!stopDeposits, "Depositing to this ethbox contract has been disabled. You can still withdraw funds.");
        
        // Max 20 outgoing boxes per address, for now
        require(senderMap[msg.sender].length < 20, "ethbox currently supports a maximum of 20 outgoing transactions per address.");
    
        Box memory newBox;
        newBox.sender       = payable(msg.sender);
        newBox.recipient    = _recipient;
        newBox.passHashHash = _passHashHash;
        newBox.sendToken    = _sendToken;
        newBox.sendValue    = _sendValue;
        newBox.requestToken = _requestToken;
        newBox.requestValue = _requestValue;
        newBox.timestamp    = block.timestamp;
        newBox.taken        = false;
        boxes.push(newBox);
        
        // Save box index to mappings for sender & recipient
        senderMap[msg.sender].push(boxes.length - 1);
        recipientMap[_recipient].push(boxes.length - 1);
        
        if(_sendToken == ERC20Interface(address(0)))
            // Sending ETH
            require(msg.value == _sendValue, "Insufficient ETH!");
        else {
            // Sending tokens
            require(_sendToken.balanceOf(msg.sender) >= _sendValue, "Insufficient tokens!");
            require(_sendToken.transferFrom(msg.sender, address(this), _sendValue), "Transferring tokens to ethbox smart contract failed!");
        }
    }

	function createBoxWithPrivacy(bytes32 _recipientHash, ERC20Interface _sendToken, uint _sendValue, bytes32 _passHashHash) external payable
    {
        // Make sure deposits haven't been disabled (will be done when switching to new contract version)
        require(!stopDeposits, "Depositing to this ethbox contract has been disabled. You can still withdraw funds.");
        
        // Max 20 outgoing boxes per address, for now
        require(senderMapWithPrivacy[keccak256(abi.encodePacked(msg.sender))].length < 20, "ethbox currently supports a maximum of 20 outgoing transactions per address.");
    
        BoxWithPrivacy memory newBox;
        newBox.senderHash       = keccak256(abi.encodePacked(msg.sender));
        newBox.recipientHash    = _recipientHash;
        newBox.passHashHash     = _passHashHash;
        newBox.sendToken        = _sendToken;
        newBox.sendValue        = _sendValue;
        newBox.timestamp        = block.timestamp;
        newBox.taken            = false;
        boxesWithPrivacy.push(newBox);
        
        // Save box index to mappings for sender & recipient
        senderMapWithPrivacy[newBox.senderHash].push(boxesWithPrivacy.length - 1);
        recipientMapWithPrivacy[newBox.recipientHash].push(boxesWithPrivacy.length - 1);
        
        if(_sendToken == ERC20Interface(address(0)))
            // Sending ETH
            require(msg.value == _sendValue, "Insufficient ETH!");
        else {
            // Sending tokens
            require(_sendToken.balanceOf(msg.sender) >= _sendValue, "Insufficient tokens!");
            require(_sendToken.transferFrom(msg.sender, address(this), _sendValue), "Transferring tokens to ethbox smart contract failed!");
        }
    }
    
    // Retrieve funds from contract, only as recipient (when sending tokens: have to ask for approval beforehand in web browser interface)
    function clearBox(uint _boxIndex, bytes32 _passHash) external payable
    {
        require((_boxIndex < boxes.length) && (!boxes[_boxIndex].taken), "Invalid box index!");
        require(msg.sender != boxes[_boxIndex].sender, "Please use 'cancelBox' to cancel transactions as sender!");

        // Recipient needs to have correct passphrase (hashed) and requested ETH / tokens
        require(
            (msg.sender == boxes[_boxIndex].recipient)
            && (boxes[_boxIndex].passHashHash == keccak256(abi.encodePacked(_passHash)))
        ,
            "Deposited funds can only be retrieved by recipient with correct passphrase."
        );
        
		// Mark box as taken, so it can't be taken another time
        boxes[_boxIndex].taken = true;
        
        // Transfer requested ETH / tokens to sender
        if(boxes[_boxIndex].requestValue != 0) {
            if(boxes[_boxIndex].requestToken == ERC20Interface(address(0))) {
                require(msg.value == boxes[_boxIndex].requestValue, "Incorrect amount of ETH attached to transaction, has to be exactly as much as requested!");
                payable(boxes[_boxIndex].sender).transfer(msg.value);
            } else {
                require(boxes[_boxIndex].requestToken.balanceOf(msg.sender) >= boxes[_boxIndex].requestValue, "Recipient does not have enough tokens to fulfill sender's request!");
                require(boxes[_boxIndex].requestToken.transferFrom(msg.sender, boxes[_boxIndex].sender, boxes[_boxIndex].requestValue), "Transferring requested tokens to sender failed!");
            }
        }

        // Transfer sent ETH / tokens to recipient
        if(boxes[_boxIndex].sendToken == ERC20Interface(address(0)))
            payable(msg.sender).transfer(boxes[_boxIndex].sendValue);
        else
            require(boxes[_boxIndex].sendToken.transfer(msg.sender, boxes[_boxIndex].sendValue), "Transferring tokens to recipient failed!");
    }

	function clearBoxWithPrivacy(uint _boxIndex, bytes32 _passHash) external payable
    {
        require((_boxIndex < boxesWithPrivacy.length) && (!boxesWithPrivacy[_boxIndex].taken), "Invalid box index!");
        require(keccak256(abi.encodePacked(msg.sender)) != boxesWithPrivacy[_boxIndex].senderHash, "Please use 'cancelBox' to cancel transactions as sender!");

        // Recipient needs to have correct passphrase (hashed)
        require(
            (keccak256(abi.encodePacked(msg.sender)) == boxesWithPrivacy[_boxIndex].recipientHash)
            && (boxesWithPrivacy[_boxIndex].passHashHash == keccak256(abi.encodePacked(_passHash)))
        ,
            "Deposited funds can only be retrieved by recipient with correct passphrase."
        );
        
        // Mark box as taken, so it can't be taken another time
        boxesWithPrivacy[_boxIndex].taken = true;
        
        // Transfer sent ETH / tokens to recipient
        if(boxesWithPrivacy[_boxIndex].sendToken == ERC20Interface(address(0)))
            payable(msg.sender).transfer(boxesWithPrivacy[_boxIndex].sendValue);
        else
            require(boxesWithPrivacy[_boxIndex].sendToken.transfer(msg.sender, boxesWithPrivacy[_boxIndex].sendValue), "Transferring tokens to recipient failed!");
    }
    
    // Cancel transaction, only as sender (when sending tokens: have to ask for approval beforehand in web browser interface)
    function cancelBox(uint _boxIndex) external payable
    {
        require((_boxIndex < boxes.length) && (!boxes[_boxIndex].taken), "Invalid box index!");
        require(msg.sender == boxes[_boxIndex].sender, "Transactions can only be cancelled by sender.");
        
        // Mark box as taken, so it can't be taken another time
        boxes[_boxIndex].taken = true;
        
        // Transfer ETH / tokens back to sender
        if(boxes[_boxIndex].sendToken == ERC20Interface(address(0)))
            payable(msg.sender).transfer(boxes[_boxIndex].sendValue);
        else
            require(boxes[_boxIndex].sendToken.transfer(msg.sender, boxes[_boxIndex].sendValue), "Transferring tokens back to sender failed!");
    }

	function cancelBoxWithPrivacy(uint _boxIndex) external payable
    {
        require((_boxIndex < boxesWithPrivacy.length) && (!boxesWithPrivacy[_boxIndex].taken), "Invalid box index!");
        require(keccak256(abi.encodePacked(msg.sender)) == boxesWithPrivacy[_boxIndex].senderHash, "Transactions can only be cancelled by sender.");
        
         // Mark box as taken, so it can't be taken another time
        boxesWithPrivacy[_boxIndex].taken = true;
        
        // Transfer ETH / tokens back to sender
        if(boxesWithPrivacy[_boxIndex].sendToken == ERC20Interface(address(0)))
            payable(msg.sender).transfer(boxesWithPrivacy[_boxIndex].sendValue);
        else
            require(boxesWithPrivacy[_boxIndex].sendToken.transfer(msg.sender, boxesWithPrivacy[_boxIndex].sendValue), "Transferring tokens back to sender failed!");
    }
      
    // Retrieve single box by index - only for sender / recipient & contract owner
    function getBox(uint _boxIndex) external view returns(Box memory)
    {
        require(
            (msg.sender == owner)
            || (msg.sender == boxes[_boxIndex].sender)
            || (msg.sender == boxes[_boxIndex].recipient)
        , 
            "Transaction data is only accessible by sender or recipient."
        );
        
        return boxes[_boxIndex];
    }

	function getBoxWithPrivacy(uint _boxIndex) external view returns(BoxWithPrivacy memory)
    {
        require(
            (msg.sender == owner)
            || (keccak256(abi.encodePacked(msg.sender)) == boxesWithPrivacy[_boxIndex].senderHash)
            || (keccak256(abi.encodePacked(msg.sender)) == boxesWithPrivacy[_boxIndex].recipientHash)
        , 
            "Transaction data is only accessible by sender or recipient."
        );
        
        return boxesWithPrivacy[_boxIndex];
    }
    
    // Retrieve sender address => box index mapping for user
    function getBoxesOutgoing() external view returns(uint[] memory)
    {
        return senderMap[msg.sender];
    }

	function getBoxesOutgoingWithPrivacy() external view returns(uint[] memory)
    {
        return senderMapWithPrivacy[keccak256(abi.encodePacked(msg.sender))];
    }
    
    // Retrieve recipient address => box index mapping for user
    function getBoxesIncoming() external view returns(uint[] memory)
    {
        return recipientMap[msg.sender];
    }

	function getBoxesIncomingWithPrivacy() external view returns(uint[] memory)
    {
        return recipientMapWithPrivacy[keccak256(abi.encodePacked(msg.sender))];
    }
    
    // Retrieve complete boxes array, only for contract owner
    function getBoxesAll() external view returns(Box[] memory)
    {
        require(msg.sender == owner, "Non-specific transaction data is not accessible by the general public.");
        return boxes;
    }

	function getBoxesAllWithPrivacy() external view returns(BoxWithPrivacy[] memory)
    {
        require(msg.sender == owner, "Non-specific transaction data is not accessible by the general public.");
        return boxesWithPrivacy;
    }
    
    // Retrieve number of boxes, only for contract owner
    function getNumBoxes() external view returns(uint)
    {
        require(msg.sender == owner, "Non-specific transaction data is not accessible by the general public.");
        return boxes.length;
    }

	function getNumBoxesWithPrivacy() external view returns(uint)
    {
        require(msg.sender == owner, "Non-specific transaction data is not accessible by the general public.");
        return boxesWithPrivacy.length;
    }

	function cancelAllNonPrivacyBoxes() external
    {
		require(msg.sender == owner, "This function is reserved for administration.");

		for(uint i = 0; i < boxes.length; i++)
			if(!boxes[i].taken) {
				// Mark box as taken, so it can't be taken another time
				boxes[i].taken = true;

				// Transfer ETH / tokens back to sender
				if(boxes[i].sendToken == ERC20Interface(address(0)))
					boxes[i].sender.transfer(boxes[i].sendValue);
				else
					require(boxes[i].sendToken.transfer(boxes[i].sender, boxes[i].sendValue), "Transferring tokens back to sender failed!");
			}
    }

	function setStopDeposits(bool _state) external
	{
		require(msg.sender == owner, "This function is reserved for administration.");

		stopDeposits = _state;
	}
    
    // Don't accept incoming ETH
    fallback() external payable
    {
        revert("Please don't send funds directly to the ethbox smart contract.");
    }
    
    constructor()
    {
        owner = msg.sender;
    }
}


interface ERC20Interface
{
    // Standard ERC 20 token interface

    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}