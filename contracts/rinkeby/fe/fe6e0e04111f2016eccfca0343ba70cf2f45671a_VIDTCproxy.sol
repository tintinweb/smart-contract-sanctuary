/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface VIDTC {
    function tokenURI(uint256 tokenID) external returns (string memory);
    function isApprovedForAll(address owner, address operator) external returns (bool);
	function tokenProvenance(uint256 tokenID) external returns (address, string memory, uint32, string memory);
    function transferFrom(address from, address to, uint256 tokenID) external;
    function transferFromByProxy(address from, address to, uint256 tokenID) external;
    function safeTransferFrom(address from, address to, uint256 tokenID) external;
    function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory _data) external;
    function safeTransferFrom(address from, address to, uint256 tokenID, uint256 value, bytes memory _data) external;
    function setTokenURI(uint256 tokenID,string memory newTokenURI) external;
	function tokenHash(uint256 _tokenID) external view returns (string memory);
	function tokenCreator(uint256 _tokenID) external view returns (address);
	function findToken(string calldata fileHash) external view returns (uint256);
	function createNFT(bytes memory data) external returns (uint256);
	function createNFTbyProxy(bytes memory data) external returns (uint256);
	function deployNFT(address Publisher, bytes memory data) external returns (uint256);
	function listNFTs(uint256 startAt, uint256 stopAt) external returns (bool);
	event ListNFT(uint256 indexed nft, string indexed hash) anonymous;
}

contract Context {
	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this;
		return msg.data;
	}
}

library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a - b;
		assert(b <= a && c <= a);
		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a && c>=b);
		return c;
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		uint256 c = a - b;
		require(b <= a && c <= a, errorMessage);
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
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		return c;
	}
}

contract Controllable is Context {
    // List of controller addresses
    mapping (address => bool) public controllers;
	address private mainWallet = address(0x57E6B79FC6b5A02Cb7bA9f1Bb24e4379Bdb9CAc5);

	constructor () {
		address msgSender = _msgSender();
		controllers[msgSender] = true;
	}

	modifier onlyController() {
		require(controllers[_msgSender()] || mainWallet == _msgSender(), "Controllable: caller is not the owner");
		_;
	}

    function addController(address _address) public onlyController {
        controllers[_address] = true;
    }

    // Revoke the trust of address to do a call for a user.
    function removeController(address _address) public onlyController {
        delete controllers[_address];
    }
}

contract Pausable is Controllable {
	event Pause();
	event Unpause();

	bool public paused = false;

	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	modifier whenPaused() {
		require(paused);
		_;
	}

	function pause() public onlyController whenNotPaused {
		paused = true;
		emit Pause();
	}

	function unpause() public onlyController whenPaused {
		paused = false;
		emit Unpause();
	}
}

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract VIDTCproxy is Pausable {
    using SafeMath for uint256;

    VIDTC private deployer;
    address payable private feeAddress;
	string private _name = "NFT-WARS";

    struct Fee {
        address payable donationAddress;               
        uint256 price;   
        uint256 fee;
    }
    mapping (ERC20 => Fee) private feeStructure;
 
    constructor (VIDTC _deployer) {
        deployer = _deployer;
    	controllers[msg.sender] = true;
    }
   
    function receiveEther() external payable {
        revert();
    }

    function withdrawEther() public onlyController {
        msg.sender.transfer(address(this).balance);
    }
    
    function setNFTcontract(VIDTC _address) public onlyController {
        deployer = _address;
    }
    
    function getNFTcontract() public view returns (address) {
        return address(deployer);
    }
    
    function setFeeAddress(address payable _address) public onlyController {
        feeAddress = _address;
    }
    
    function addPaymentToken(ERC20 _address, address payable _donationAddress, uint256 _price, uint256 _fee, uint256 _feeDivider) public onlyController {
	    feeStructure[_address] = Fee({
            donationAddress: _donationAddress,
            price: _price,
            fee: _fee.mul(1e36) / _feeDivider
        });        
    }
    
    function removePaymentToken(ERC20 _tokenaddress) public onlyController {
        delete feeStructure[_tokenaddress];
    }
    
    function getDonationAddress(ERC20 _tokenaddress) public view returns (address) {
        Fee storage setfee = feeStructure[_tokenaddress];
        return setfee.donationAddress;
    }

    function getPrice(ERC20 _tokenaddress) public view returns (uint256) {
        Fee storage setfee = feeStructure[_tokenaddress];
        return setfee.price;
    }

    function getFee(ERC20 _tokenaddress) public view returns (uint256) {
        Fee storage setfee = feeStructure[_tokenaddress];
        return setfee.price.mul(setfee.fee.div(1e36));
    }
    
    function createNFT(bytes memory data) public payable whenNotPaused returns (uint256) {
        Fee storage setfee = feeStructure[ERC20(0x0000000000000000000000000000000000000000)];

        require(setfee.price > 0,"PC0 - Not a valid payment option (yet)");
        require(msg.value.mul(setfee.fee.div(1e36)) >= setfee.price,"PC1 - Payment too low");
        require(feeAddress.send(msg.value.mul(setfee.fee.div(1e36))),"PC2 - Payment failed");
        require(setfee.donationAddress.send(msg.value.sub(msg.value.mul(setfee.fee.div(1e36)))),"PC3 - Donation failed");

        return deployer.createNFTbyProxy(data);
    }
    
    function createNFT(bytes memory data, ERC20 payToken, uint256 payFee) public whenNotPaused returns (uint256) {
        Fee storage setfee = feeStructure[payToken];
            
        require(setfee.price > 0,"PC4 - Not a valid payment token (yet)");
        require(payFee.mul(setfee.fee.div(1e36)) >= setfee.price,"PC5 - Fee too low");
        require(payToken.transfer(feeAddress, payFee.mul(setfee.fee.div(1e36))),"PC6 - No allowance for payment of fee");
        require(payToken.transfer(setfee.donationAddress, payFee.sub(payFee.mul(setfee.fee.div(1e36)))),"PC7 - Donation failed");

        return deployer.createNFTbyProxy(data);
    }
}