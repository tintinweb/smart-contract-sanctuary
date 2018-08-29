pragma solidity ^0.4.24;

/* ================================================================================================ *
 * ================================================================================================ *
 * ================================================================================================ *
 *                                                                                                  *
 *            __            __    __         _                                       __             *
 *        ___/ /___  __ __ / /   / /____    (_)___    ___   ____ ___  ___ ___  ___  / /_ ___        *
 *       / _  // _ \/ // // _ \ / // __/_  / // _ \  / _ \ / __// -_)(_-</ -_)/ _ \/ __/(_-<        *
 *       \_,_/ \___/\_,_//_.__//_//_/  (_)/_/ \___/ / .__//_/   \__//___/\__//_//_/\__//___/        *
 *                                                 /_/                                              *
 *                                                                                                  *
 *                                                                                                  *
 *                                                                                                  *
 *                      _____                   _    _                 _                            *
 *                     |_   _|                 | |  | |               | |                           *
 *                       | |  _ __ ___  _ __   | |__| | __ _ _ __   __| |___                        *
 *                       | | | &#39;__/ _ \| &#39;_ \  |  __  |/ _` | &#39;_ \ / _` / __|                       *
 *                      _| |_| | | (_) | | | | | |  | | (_| | | | | (_| \__ \                       *
 *                     |_____|_|  \___/|_| |_| |_|  |_|\__,_|_| |_|\__,_|___/                       *
 *                                                                                                  *
 *                                                                                                  *
 *   ::::::::::: ::::::::::: ::::     :::: :::::::::: :::        ::::::::  :::::::::  :::::::::     *
 *       :+:         :+:     +:+:+: :+:+:+ :+:        :+:       :+:    :+: :+:    :+: :+:    :+:    *
 *       +:+         +:+     +:+ +:+:+ +:+ +:+        +:+       +:+    +:+ +:+    +:+ +:+    +:+    *
 *       +#+         +#+     +#+  +:+  +#+ +#++:++#   +#+       +#+    +:+ +#++:++#:  +#+    +:+    *
 *       +#+         +#+     +#+       +#+ +#+        +#+       +#+    +#+ +#+    +#+ +#+    +#+    *
 *       #+#         #+#     #+#       #+# #+#        #+#       #+#    #+# #+#    #+# #+#    #+#    *
 *       ###     ########### ###       ### ########## ########## ########  ###    ### #########     *
 *                                                                                                  *
 *                                                                                                  *
 *                                         _n____n__                                                *
 *                                        /         \---||--<                                       *
 *                                       /___________\                                              *
 *                                       _|____|____|_                                              *
 *                                       _|____|____|_                                              *
 *                                        |    |    |                                               *
 *                                       --------------                                             *
 *                                       | || || || ||\                                             *
 *                                       | || || || || \++++++++------<                             *
 *                                       ===============                                            *
 *                                       |   |  |  |   |                                            *
 *                                      (| O | O| O| O |)                                           *
 *                                      |   |   |   |   |                                           *
 *                                     (| O | O | O |  O |)                                         *
 *                                      |   |   |    |    |                                         *
 *                                    (| O |  O |  O  | O  |)                                       *
 *                                     |   |    |     |    |                                        *
 *                                    (| O |  O  |   O |  O |)                                      *
 *                                   /========================\                                     *
 *                                   \vvvvvvvvvvvvvvvvvvvvvvvv/                                     *
 *                                                                                                  *
 * ================================================================================================ *
 * ================================================================================================ *
 * ================================================================================================ *
 

 ----------------------------------------- < How it Works > -----------------------------------------
 
This contract is an ERC-20 token that represents positions in the Doublr line. POD tokens are sold 
for 0.5 ETH, and are redeemable for 1 ETH each. POD tokens become redeemable as ETH flows in from the 
Doublr contract (0xE58b65d1c0C8e8b2a0e3A3AcEC633271531084ED).

This functions similarly to the dividend system in POWH3D, with the twist that the tokens are
burned once they are redeemed. This enforces a maximum 2x profit, and ensures that the positive sum 
nature of the Doublr contract is maintained.

TESTING >>>

buyTokens() is the primary entry point. You will receive POD tokens at the price of 0.5 ETH/POD.
The ERC-20 interface still needs tested, as well as making sure the dividend tracker is working correctly.

 */

contract Owned {
    
    address public owner;
    address public ownerCandidate;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);  
        owner = ownerCandidate;
    }
    
}

contract Timelord is Owned {
    
    string public name = "Proof of Double"; 
    string public symbol = "POD";           
    uint256 constant public decimals = 18;
    
    // CONSTANTS
    
    //address constant iron_hands_address = address(0xE58b65d1c0C8e8b2a0e3A3AcEC633271531084ED);
    //address constant weak_hands_address = address(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    
    address constant iron_hands_address = address(0x80339DB00737f200b9C91e391aCc5099b9d81e9e); // ROPSTEN
    address constant weak_hands_address = address(0x8Ef3176DE6a5e42C243d356Dbb8bcc6E72f3dC6C); // ROPSTEN
    
    IH iron_hands = IH(iron_hands_address);
    POWH weak_hands = POWH(weak_hands_address);
    
    uint256 constant internal magnitude = 2**64;
    
    // EVENTS
    
    event TokensMinted(uint256 amount, uint256 total_supply);
    event TokensBurned(uint256 amount, uint256 total_supply);
    event Reinvested(address user);
    event Redeemed(address user);
    event Donation(uint256 amount);
    event Transfer(address from, address to, uint256 value);
    event Approval(address from, address spender, uint256 value);
    
    // VARIABLES

    uint256 public total_supply;
    uint256 public payout_pool; // How much ETH is awaiting redemption or reinvestment
    uint256 public paid_out; // How much total ETH has been paid out to users.
    uint256 internal profit_per_token;

    // MAPPINGS
    
    mapping (address => uint256) public balance;
    mapping (address => int256) public payouts;
    mapping (address => mapping (address => uint256)) public allowance;

    // PUBLIC FUNCTIONS
    
    function buyTokens() payable public {
        
        require(msg.value > 100);
        
        mintTokens(msg.value, msg.sender);
        
        payout();
        
    }
    
    function reinvest() public {
        
        reinvestTokens(msg.sender);
        
        payout();
        
    }
    
    function redeem() public {
        
        burnTokens(msg.sender);
        
        emit Redeemed(msg.sender);
        
        payout();
        
    }
    
    function takeProfit() public {
        
        profit(msg.sender);
        
        payout();
        
    }
    
    function donate() payable public {
        
        require(msg.value > 0);
        
        payout();
        
        emit Donation(msg.value);
        
    }
    
    function() payable public {
        
        require(msg.sender == iron_hands_address || msg.sender == weak_hands_address);
        
    }
    
    function payout() public {
        
        withdrawPowhDivs();
        
        uint256 amount = SafeMath.sub(address(this).balance, payout_pool);
        
        if (amount > 0) {
            
            payout_pool += amount;
            
            profit_per_token += ((amount * magnitude) / total_supply);
            
        }
        
    }

    // PRIVATE FUNCTIONS
    
    function mintTokens(uint256 incoming_eth, address user) private {
        
        iron_hands.deposit.value(incoming_eth).gas(1000000)();
        
        uint256 num_tokens = incoming_eth * 2;
        
        balance[user] += num_tokens;
        payouts[user] += (int256)(num_tokens * profit_per_token);
        
        total_supply += num_tokens;
        
        emit TokensMinted(num_tokens, total_supply);
        
    }
    
    function burnTokens(address user) private {
        
        uint256 owed = dividendsOf(user);
        
        require(owed > 0);
        
        balance[user] -= owed;
        total_supply -= owed;
        
        payout_pool -= owed;
        
        payouts[user] = (int256)(balance[user] * profit_per_token);
        
        if (!user.call.value(owed).gas(1000000)()){
            revert();
        }
        
        emit TokensBurned(owed, total_supply);
        
    }
    
    function profit(address user) private {
        
        uint256 owed = dividendsOf(user);
        
        require(owed > 0);
        
        payouts[user] = (int256)(balance[user] * profit_per_token);
        
        uint256 half_owed = SafeMath.div(owed, 2);
        
        payout_pool -= half_owed;
        
        if (!user.call.value(half_owed).gas(1000000)()){
            revert();
        }
        
    }
    
    function reinvestTokens(address user) private {
        
        uint256 owed = dividendsOf(user);
        
        require(owed > 0);
        
        mintTokens(owed, user);
        
        payout_pool -= owed;
        
        payouts[user] = (int256)(balance[user] * profit_per_token);
        
        emit Reinvested(user);
        
    }
    
    function withdrawPowhDivs() private {
        
        if (weak_hands.myDividends(true) > 0) {
            weak_hands.withdraw.gas(1000000)();
        }
        
    }
    
    // VIEW FUNCTIONS
   
    function myDividends() public view returns (uint256) {
        return dividendsOf(msg.sender);
    }
    
    function dividendsOf(address user_address) public view returns (uint256) {
        return (uint256) ((int256)(profit_per_token * balance[user_address]) - payouts[user_address]) / magnitude;
    }
    
    function myBalance() public view returns (uint256) {
        return balance[msg.sender];
    }
    
    // ERC-20
    
    function balanceOf(address _token_holder) public view returns (uint256 user_balance) {
        return balance[_token_holder];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        require(_value > 0);
        require(balance[msg.sender] >= _value);
        require(balance[_to] + _value >= balance[_to]);
        
        if (myDividends() > 0) reinvestTokens(msg.sender);
        
        payouts[msg.sender] -= (int256)(_value * profit_per_token);
        payouts[_to] += (int256)(_value * profit_per_token);
        
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
        
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        require(_value > 0);
        require(balance[_from] >= _value);
        require(balance[_to] + _value >= balance[_to]);
        require(allowance[_from][msg.sender] >= _value);
        
        if (dividendsOf(_from) > 0) reinvestTokens(_from);
        
        payouts[_from] -= (int256)(_value * profit_per_token);
        payouts[_to] += (int256)(_value * profit_per_token);
        
        balance[_to] += _value;
        balance[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
        
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
        
    }

}

contract IH {
    
    function deposit() payable public;
    function backlogAmount() public view returns (uint256);
    function totalSpent() public view returns (uint256);
    function transferAnyERC20Token(address, address, uint) public returns (bool success);
    
}

contract POWH {
    
    function buy(address) public payable returns(uint256);
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
}