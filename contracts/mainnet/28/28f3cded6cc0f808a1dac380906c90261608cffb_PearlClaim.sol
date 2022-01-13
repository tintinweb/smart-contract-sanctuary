/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "ERC20: sending to the zero address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

interface IERC20 {
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function transfer(address to, uint256 tokens) external returns (bool success);
}

interface ILooksRareAirdrop {
    function hasClaimed(address wallet) external view returns (bool claimed);
}

interface ILooksRareStaking {
    function userInfo(address wallet) external view returns (uint256 amount, uint256 rewardDebt);
}

contract PearlClaim is Ownable {
    
    event Claimed(address indexed wallet, address indexed token);
    event Burned(address indexed token, uint256 amount);
    event Recovered(address indexed token, uint256 amount, address indexed recipient);

    mapping(address => bool) public walletHasClaimed;
    mapping(address => bool) public claimEnded;
    IERC20 public token;
    IERC20 public constant looksRareToken = IERC20(0xf4d2888d29D722226FafA5d9B24F9164c092421E);
    ILooksRareAirdrop public constant looksAirdrop = ILooksRareAirdrop(0xA35dce3e0E6ceb67a30b8D7f4aEe721C949B5970);
    ILooksRareStaking public constant looksStaking = ILooksRareStaking(0x465A790B428268196865a3AE2648481ad7e0d3b1);
    uint256 public multiplier = 22500;
        
    constructor() {
        token = IERC20(address(0xe3451FD6c9f259fdB065834C719f40b64DCa09F0));
    }

    function updateToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function updateMultiplier(uint256 multi) external onlyOwner {
        multiplier = multi;
    }

    function userAmountToClaim(address wallet) public view returns (uint256){
        if(!looksAirdrop.hasClaimed(wallet) || walletHasClaimed[wallet]){
            return 0;
        }
        (uint256 amountStaked,) = looksStaking.userInfo(wallet);
        uint256 totalAmountOfLooks = amountStaked + looksRareToken.balanceOf(wallet);
        uint256 transferToAmount = totalAmountOfLooks * multiplier;
        return transferToAmount;
    }

    function claimTokens() external {
        require(!walletHasClaimed[msg.sender], "Wallet has already claimed these tokens.");
        require(looksAirdrop.hasClaimed(msg.sender), "You are not eligible to claim");
        uint256 transferToAmount = userAmountToClaim(msg.sender);

        walletHasClaimed[msg.sender] = true;

        require(token.balanceOf(address(this)) >= transferToAmount, "Not enough tokens to transfer");
        require(token.transfer(address(msg.sender), transferToAmount), "Error in withdrawing tokens");
        emit Claimed(msg.sender, address(token));
    }

    function transferToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_to != address(0), "_to address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        if(_sent){
            emit Recovered(_token, _contractBalance, _to);
        }
    }
}