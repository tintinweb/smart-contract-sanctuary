/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity = 0.8.3;


interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256 supply);

    function approve(address spender, uint256 value) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address to, uint256 value) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0
contract LQFGiveaway {

	address private owner;
    ERC20 public immutable lqf;
	uint  public immutable registerDate;
	uint  private registeredCount;
	uint  public immutable giveawayAmount;
	
	struct WalletStatus {
		bool registered;
		bool claimed;
	}

	mapping(address => WalletStatus) private walletStatus;
	
    constructor(address _lqf, uint _registerDate, uint _giveawayAmount) {
		owner = msg.sender;
        lqf = ERC20(_lqf);
		registerDate = _registerDate;
		giveawayAmount = _giveawayAmount;
    }

    function register() external {
		require(block.timestamp <= registerDate, "Register date passed");
		require(!walletStatus[msg.sender].registered, "Wallet already registered");
		walletStatus[msg.sender].registered = true;
		registeredCount++;
    }

    function claim() external {
		require(block.timestamp > registerDate, "Register date not passed");
		require(walletStatus[msg.sender].registered, "Wallet not registered");
		require(!walletStatus[msg.sender].claimed, "Wallet already claimed");
		
		require(lqf.transfer(msg.sender, giveawayAmount / registeredCount), "LQF transfer failed");
		walletStatus[msg.sender].claimed = true;
    }

    function withdraw(address to) external {
		require(msg.sender == owner, "Sender is not owner");
		lqf.transfer(to, lqf.balanceOf(address(this)));
    }

    function checkRegistered(address w) external view returns (bool) {
		return walletStatus[w].registered;
    }

    function checkClaimed(address w) external view returns (bool) {
		return walletStatus[w].claimed;
    }

    function getRegisteredCount() external view returns (uint) {
		return registeredCount;
	}
	
}