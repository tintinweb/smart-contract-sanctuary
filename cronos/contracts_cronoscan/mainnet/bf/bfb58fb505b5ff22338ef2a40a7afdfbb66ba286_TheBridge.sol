/**
 *Submitted for verification at cronoscan.com on 2022-05-27
*/

/**
 *Submitted for verification at cronoscan.com on 2022-05-23
*/

/*  
TOKEN - CRO <-> BSC Bridge
*/

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None

pragma solidity 0.8.14;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {owner = _owner;authorizations[_owner] = true;}

    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}

    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}

    function setBridgeWallet(address adr) public onlyOwner {authorizations[adr] = true;}

    function unauthorize(address adr) public onlyOwner {authorizations[adr] = false;}

    function isOwner(address account) public view returns (bool) {return account == owner;}

    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
}



contract TheBridge is Auth {
    address public TOKEN;
    address public theBridgeWallet = 0x5288009820Ff073Bb664e7330F5f0C9868878888;

    mapping (address => uint256) tokensToBeClaimed;
    mapping (address => uint256) lastTimeStamp;
    mapping (address => mapping (uint256 => uint256)) tokensDepositedAtTimeStamp;

    uint256 feeForBridgingWithoutManualClaim = 10 * 10**(_decimals - feeDecimals);
    uint256 feeForBridgingWithManualClaim = 1 * 10**(_decimals - feeDecimals);
    uint256 feeDecimals = 1;
    uint256 _decimals;

    event TokensHaveArrived(address account, uint256 amount);
    event TokensCanBeClaimed(address account, uint256 amount);
    event TokensHaveBeenSent(address account, uint256 amount);
    event TokensHaveBeenClaimed(address account, uint256 amount);


    constructor(address whichToken) Auth(msg.sender) {
        TOKEN = whichToken;
        setBridgeWallet(theBridgeWallet);
        _decimals = IBEP20(TOKEN).decimals();
    }

    function sendTokensToBridge(address account, uint256 amount, uint256 timeStamp) external {
        require(IBEP20(TOKEN).allowance(account, address(this)) >= amount, "Amount exceeds allowance, please approve the bridge to use your tokens");
        IBEP20(TOKEN).transferFrom(account, address(this), amount);
        tokensDepositedAtTimeStamp[account][timeStamp] = amount;
        emit TokensHaveArrived(account, amount);
    }
    
    function checkDeposit(address account, uint256 amount, uint256 timeStamp) public view returns(uint256) {
        require(tokensDepositedAtTimeStamp[account][timeStamp] == amount, "We can't find your tokens, please check your wallet to see if they have actually been sent");
        return amount;
    }

    function registerBridgedTokensToBeClaimed(address account, uint256 amount, uint256 timeStamp) external authorized {
        if(timeStamp == lastTimeStamp[account]) return;
        lastTimeStamp[account] = timeStamp;
        
        tokensToBeClaimed[account] += amount;
        emit TokensCanBeClaimed(account, amount);
    }

    function sendTokensToClient(address account, uint256 amount, uint256 timeStamp) external authorized {
        if(timeStamp == lastTimeStamp[account]) return;
        lastTimeStamp[account] = timeStamp;

        amount -= feeForBridgingWithoutManualClaim;

        IBEP20(TOKEN).transfer(account, amount);
        emit TokensHaveBeenSent(account, amount);
    }
    
    function claimAllTokens(address account) external {
        uint256 amount = tokensToBeClaimed[account];
        claimExactTokens(account, amount);
    }

    function claimExactTokens(address account, uint256 amount) public {
        require(amount > 0, "You can't claim zero tokens");
        tokensToBeClaimed[account] -= amount;
        amount -= feeForBridgingWithManualClaim;
        IBEP20(TOKEN).transfer(account, amount);
        emit TokensHaveBeenClaimed(account, amount);
    }

    function setFeeForBridgingWithoutManualClaim(uint256 fee) external onlyOwner {
        feeForBridgingWithoutManualClaim = fee;
    }

    function setFeeForBridgingWithManualClaim(uint256 fee) external onlyOwner {
        feeForBridgingWithManualClaim = fee;
    }
    
    function setFeeDivisor(uint256 newFeeDecimals) external onlyOwner {
        feeDecimals = newFeeDecimals;
    }

    function mrGreenRescueTokens() external onlyOwner{
        IBEP20(TOKEN).transfer(owner, IBEP20(TOKEN).balanceOf(address(this)));
    }
}