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

 */

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC223 {
    
    function totalSupply() external view returns (uint256);
    function name() external view returns (string);
    function symbol() external view returns (string);
    function decimals() external view returns (uint8);
    function balanceOf(address _token_holder) external view returns (uint256 user_balance);
    function transfer(address _to, uint _value, bytes _data) external returns (bool success);
        
}

interface ERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    
}

contract ERC165MappingImplementation is ERC165 {
    /// @dev You must not set element 0xffffffff to true
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() public {
        supportedInterfaces[bytes4(keccak256("supportsInterface(bytes4)"))] = true;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return supportedInterfaces[interfaceID];
    }
    
}

contract Timelord is ERC165MappingImplementation, ERC223, ERC20 {
    
    string public name = "Proof of Double"; 
    string public symbol = "POD";           
    uint8 public decimals = 18;
    
    constructor() public {
        
        supportedInterfaces[ // 223
            bytes4(keccak256("totalSupply()")) ^
            bytes4(keccak256("name()")) ^
            bytes4(keccak256("symbol()")) ^
            bytes4(keccak256("decimals()")) ^
            bytes4(keccak256("balanceOf(address)")) ^
            bytes4(keccak256("transfer(address,uint,bytes)"))
        ] = true;
        
        supportedInterfaces[ // 20
            bytes4(keccak256("totalSupply()")) ^
            bytes4(keccak256("balanceOf(address)")) ^
            bytes4(keccak256("transfer(address,uint256)")) ^
            bytes4(keccak256("transferFrom(address,address,uint256)")) ^
            bytes4(keccak256("approve(address,uint256)")) ^
            bytes4(keccak256("allowance(address,address)"))
        ] = true;
        
    }
    
    // CONSTANTS
    
    //address constant iron_hands_address = address(0xE58b65d1c0C8e8b2a0e3A3AcEC633271531084ED);
    //address constant weak_hands_address = address(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    
    address constant iron_hands_address = address(0x33AE65Aa80969f2E22DB876DE8851F3b78E5F243); // ROPSTEN
    address constant weak_hands_address = address(0x86a8EfB0f79dAccCb533D9A5e66527074B8a5d76); // ROPSTEN
    
    IH iron_hands = IH(iron_hands_address);
    POWH weak_hands = POWH(weak_hands_address);
    
    uint256 constant internal magnitude = 2**64;
    
    // EVENTS
    
    event TokensMinted(uint256 amount, uint256 total_supply);
    event TokensBurned(uint256 amount, uint256 total_supply);
    event Reinvested(address user);
    event Redeemed(address user);
    event Donation(uint256 amount);
    event Transfer(address from, address to, uint256 value, bytes data);
    event Approval(address from, address spender, uint256 value);
    
    // VARIABLES

    uint256 public total_supply;
    uint256 public payout_pool; // How much ETH is awaiting redemption or reinvestment
    uint256 public paid_out; // How much total ETH has been paid out to users.
    uint256 internal profit_per_token;

    // MAPPINGS
    
    mapping (address => uint256) public balances;
    mapping (address => int256) public payouts;
    mapping (address => mapping (address => uint256)) public allowance;

    // PUBLIC FUNCTIONS
    
    function buyTokens() payable public {
        
        require(msg.value > 1000000);
        
        mintTokens(msg.value, msg.sender);
        
        payout();
        
    }
    
    function reinvest() public {
        
        reinvestTokens(msg.sender);
        
        payout();
        
    }
    
    function redeem() public {
        
        burnTokens(msg.sender);
        
        payout();
        
        emit Redeemed(msg.sender);
        
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
        
        iron_hands.deposit.value(1000000).gas(1000000)();
        iron_hands.deposit.value(incoming_eth-1000000).gas(1000000)();
        
        uint256 num_tokens = incoming_eth * 2;
        
        balances[user] += num_tokens;
        payouts[user] += (int256)(num_tokens * profit_per_token);
        
        total_supply += num_tokens;
        
        emit TokensMinted(num_tokens, total_supply);
        
    }
    
    function burnTokens(address user) private {
        
        uint256 owed = dividendsOf(user);
        
        require(owed > 0);
        
        balances[user] -= owed;
        total_supply -= owed;
        
        payout_pool -= owed;
        
        payouts[user] = (int256)(balances[user] * profit_per_token);
        
        if (!user.call.value(owed).gas(1000000)()){
            revert();
        }
        
        emit TokensBurned(owed, total_supply);
        
    }
    
    function reinvestTokens(address user) private {
        
        uint256 owed = dividendsOf(user);
        
        require(owed > 0);
        
        mintTokens(owed, user);
        
        payout_pool -= owed;
        
        payouts[user] = (int256)(balances[user] * profit_per_token);
        
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
        return (uint256) ((int256)(profit_per_token * balances[user_address]) - payouts[user_address]) / magnitude;
    }
    
    function myBalances() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    // ERC-223 & ERC-20
    
    function totalSupply() external view returns (uint256){
        return total_supply;
    }
    
    function balanceOf(address _token_holder) external view returns (uint256 balance) {
        return balances[_token_holder];
    }
    
    // ERC-223
    
    function name() external view returns (string){
        return name;
    }
    
    function symbol() external view returns (string){
        return symbol;
    }
    
    function decimals() external view returns (uint8){
        return decimals;
    }
    
    function transfer(address _to, uint _value, bytes _data) external returns (bool success) {
        
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);
        
        if (myDividends() > 0) reinvestTokens(msg.sender);
        
        payouts[msg.sender] -= (int256)(_value * profit_per_token);
        payouts[_to] += (int256)(_value * profit_per_token);
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        uint codeLength;
        
        assembly {
            codeLength := extcodesize(_to)
        }
        
        if (codeLength > 0) {
            
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            
        }
        
        emit Transfer(msg.sender, _to, _value, _data);
        
        return true;
        
    }
    
    // ERC-20
    
    function transfer(address _to, uint256 _value) external returns (bool success) {
        
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        
        if (myDividends() > 0) reinvestTokens(msg.sender);
        
        payouts[msg.sender] -= (int256)(_value * profit_per_token);
        payouts[_to] += (int256)(_value * profit_per_token);
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value, msg.data);
        
        return true;
        
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        
        require(_value > 0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        require(allowance[_from][msg.sender] >= _value);
        
        if (dividendsOf(_from) > 0) reinvestTokens(_from);
        
        payouts[_to] += (int256)(_value * profit_per_token);
        payouts[_from] -= (int256)(_value * profit_per_token);
        
        balances[_to] += _value;
        balances[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value, msg.data);
        
        return true;
        
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
        
    }
    
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowance[_owner][_spender];
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

contract ERC223Receiver {
    
    function tokenFallback(address, uint256, bytes) public;
    
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
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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