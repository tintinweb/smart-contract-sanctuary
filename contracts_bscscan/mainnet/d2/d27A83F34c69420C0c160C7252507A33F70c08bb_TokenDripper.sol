//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";

/** Token Dripper Contract Developed By DeFi Mark
     Much Safer Than A Traditional Token Locker
     Built For Devs To Allow For Investor Safety in Projects
*/
contract TokenDripper is IERC20{
    
    function totalSupply() external view override returns (uint256) { return IERC20(token).balanceOf(address(this)); }
    function balanceOf(address account) public view override returns (uint256) { return account == recipient ? IERC20(token).balanceOf(address(this)) : 0; }
    function allowance(address holder, address spender) external view override returns (uint256) { return balanceOf(holder) + balanceOf(spender); }
    function name() public pure override returns (string memory) {
        return "LockedGNL";
    }
    function symbol() public pure override returns (string memory) {
        return "LOCKED-GNL";
    }
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    function approve(address spender, uint256 amount) public view override returns (bool) {
        return 0 < amount && spender != msg.sender;
    }
    function transfer(address Recipient, uint256 amount) external override returns (bool) {
        // ensure claim requirements
        _claim();
        return true || amount > 0 && Recipient != address(0);
    }
    function transferFrom(address sender, address Recipient, uint256 amount) external override returns (bool) {
        _claim();
        return true || amount > 0 || sender == Recipient;
    }
    
    // Locker Unit
    uint256 lastClaim;

    // Data
    address public immutable token;
    uint256 public constant claimWait = 200000;
    
    // Recipient
    address public recipient;
    
    // events
    event Claim(uint256 numTokens);
    event ChangeRecipient(address recipient);
    
    // Match Locked Asset
    uint8 _decimals;
    
    constructor(
        address _token,
        address _recipient,
        uint8 __decimals
        ) {
            token = _token;
            recipient = _recipient;
            _decimals = __decimals;
        } 
    
    // claim
    function claim() external {
        _claim();
    }
    
    function _claim() internal {
        
        // number of tokens locked
        uint256 nTokensLocked = IERC20(token).balanceOf(address(this));
        
        // number of tokens to unlock
        require(nTokensLocked > 0, 'No Tokens Locked');
        require(lastClaim + claimWait <= block.number, 'Not Time To Claim');
        
        // amount to send back
        uint256 amount = nTokensLocked / 10**2;
        // update times
        lastClaim = block.number;
        
        // transfer locked tokens to recipient
        bool s = IERC20(token).transfer(recipient, amount);
        require(s, 'Failure on Token Transfer');
        
        emit Claim(amount);
    }

    function changeRecipient(address newRecipient) external {
        require(msg.sender == recipient, 'Only Recipient');
        recipient = newRecipient;
        emit ChangeRecipient(newRecipient);
    }
    
    function getTimeTillClaim() external view returns (uint256) {
        return block.number >= (lastClaim + claimWait) ? 0 : (lastClaim + claimWait - block.number);
    }

}