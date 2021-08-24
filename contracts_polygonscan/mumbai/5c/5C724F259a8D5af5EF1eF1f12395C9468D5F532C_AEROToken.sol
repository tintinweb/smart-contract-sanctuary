/**
 *Submitted for verification at polygonscan.com on 2021-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.5;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.0;

contract BasicMetaTransaction {

    using SafeMath for uint256;

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Main function to be called when user wants to execute meta transaction.
     * The actual function to be called should be passed as param with name functionSignature
     * Here the basic signature recovery is being used. Signature is expected to be generated using
     * personal_sign method.
     * @param userAddress Address of user trying to do meta transaction
     * @param functionSignature Signature of the actual function to be called via meta transaction
     * @param sigR R part of the signature
     * @param sigS S part of the signature
     * @param sigV V part of the signature
     */
    function executeMetaTransaction(address userAddress, bytes memory functionSignature,
        bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns(bytes memory) {

        require(verify(userAddress, nonces[userAddress], getChainID(), functionSignature, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] = nonces[userAddress].add(1);

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);
        return returnData;
    }

    function getNonce(address user) external view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function verify(address owner, uint256 nonce, uint256 chainID, bytes memory functionSignature,
        bytes32 sigR, bytes32 sigS, uint8 sigV) public view returns (bool) {

        bytes32 hash = prefixed(keccak256(abi.encodePacked(nonce, this, chainID, functionSignature)));
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
		return (owner == signer);
    }

    function _msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            return msg.sender;
        }
    }
}


pragma solidity ^0.8.0;

interface ItokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external returns (bool); 
}

interface IERC20Token {
    function totalSupply() external view returns (uint256 supply);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract StandardToken is IERC20Token, BasicMetaTransaction {
    
    using SafeMath for uint256;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public _totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function totalSupply() override public view returns (uint256 supply) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) override virtual public returns (bool success) {
        require(_to != address(0x0), "Use burn function instead");                              
		require(_value >= 0, "Invalid amount"); 
		require(balances[_msgSender()] >= _value, "Not enough balance");
		balances[_msgSender()] = balances[_msgSender()].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_msgSender(), _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override virtual public returns (bool success) {
        require(_to != address(0x0), "Use burn function instead");                               
		require(_value >= 0, "Invalid amount"); 
		require(balances[_from] >= _value, "Not enough balance");
		require(allowed[_from][_msgSender()] >= _value, "You need to increase allowance");
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) override public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) override public returns (bool success) {
        allowed[_msgSender()][_spender] = _value;
        emit Approval(_msgSender(), _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
}

contract AEROToken is Ownable, StandardToken {

    using SafeMath for uint256;
    string public name = "AfterEarth";
    uint8 public decimals = 18;
    string public symbol = "AERO";

    // Time lock for progressive release of team, marketing and platform balances
    struct TimeLock {
        uint256 totalAmount;
        uint256 lockedBalance;
        uint128 baseDate;
        uint64 step;
        uint256 tokensStep;
    }
    mapping (address => TimeLock) public timeLocks; 

    // Prevent Bots - If true, limits transactions to 1 transfer per block (whitelisted can execute multiple transactions)
    bool public limitTransactions;
    mapping (address => bool) public contractsWhiteList;
    mapping (address => uint) public lastTXBlock;
    event Burn(address indexed from, uint256 value);

// token sale

    // Wallet for the tokens to be sold, and receive ETH
    address payable public salesWallet;
    uint256 public soldOnCSale;
    uint256 public constant CROWDSALE_START = 1629732600; //Monday, 23 August 2021 15:30:00
    uint256 public constant CROWDSALE_END = 1630078200; //Friday, 27 August 2021 15:30:00
    uint256 public constant CSALE_WEI_FACTOR = 100000; //1 MATIC = 21 AEROs.
    uint256 public constant CSALE_HARDCAP = 2250000 ether;
    
    constructor() {
        _totalSupply = 250000000 ether;
        
        // Base date to calculate tokens lock release.
        uint256 lockStartDate = 1630454400; //Wednesday, 1 September 2021 00:00:00
        
        // Team wallet - 10000000 tokens
        // // 0 tokens free, 10000000 tokens locked - progressive release of 5% every 30 days (after 180 days of waiting period)
        // address team = 0x4ef5B3d10fD217AC7ddE4DDee5bF319c5c356723;
        // balances[team] = 10000000 ether;
        // timeLocks[team] = TimeLock(10000000 ether, 10000000 ether, uint128(lockStartDate + (180 days)), 30 days, 500000);
        // emit Transfer(address(0x0), team, balances[team]);

        // // Marketing wallet - 5000000 tokens
        // // 1000000 tokens free, 4000000 tokens locked - progressive release of 5% every 30 days
        // address marketingWallet = 0x056F878d4Ac07E66C9a46a8db4918E827c6fD71c;
        // balances[marketingWallet] = 5000000 ether;
        // timeLocks[marketingWallet] = TimeLock(4000000 ether, 4000000 ether, uint128(lockStartDate), 30 days, 200000);
        // emit Transfer(address(0x0), marketingWallet, balances[marketingWallet]);
        
        // // Private sale wallet - 2500000 tokens
        // address privateWallet = 0xED854fCF86efD8473F174d6dE60c8A5EBDdCc37A;
        // balances[privateWallet] = 2500000 ether;
        // emit Transfer(address(0x0), privateWallet, balances[privateWallet]);
        
        // // Sales wallet, holds Pre-Sale balance - 7500000 tokens
        // salesWallet = payable(0x4bb74E94c1EB133a6868C53aA4f6BD437F99c347);
        // balances[salesWallet] = 7500000 ether;
        // emit Transfer(address(0x0), salesWallet, balances[salesWallet]);
        
        // // Exchanges - 25000000 tokens
        // address exchanges = 0xE50d4358425a93702988eCd8B66c2EAD8b41CE5d;  
        // balances[exchanges] = 25000000 ether;
        // emit Transfer(address(0x0), exchanges, balances[exchanges]);
        
        // // Platform wallet - 200000000 tokens
        // // 50000000 tokens free, 150000000 tokens locked - progressive release of 25000000 every 90 days
        // address platformWallet = 0xAD334543437EF71642Ee59285bAf2F4DAcBA613F;
        // balances[platformWallet] = 200000000 ether;
        // timeLocks[platformWallet] = TimeLock(150000000 ether, 150000000 ether, uint128(lockStartDate), 90 days, 25000000);
        // emit Transfer(address(0x0), platformWallet, balances[platformWallet]);
        
        // Airdrop Wallet, Releases 250,000 Tokens
        address airdropWallet = 0xe41C1F91DA61CbCF9273E4A7890cA8a95647b173;
        balances[airdropWallet] = 250000 ether;
        emit Transfer(address(0x0), airdropWallet, balances[airdropWallet]);

        // Sales wallet, holds Pre-Sale balance - 2250000 tokens
        salesWallet = payable(0x7ea1f79122d66eB0a8611B3959351630200BdF93);
        balances[salesWallet] = 2250000 ether;
        emit Transfer(address(0x0), salesWallet, balances[salesWallet]);

        // Exchanges - 25000000 tokens
        address exchanges = 0x97F30b93E045D107e50b82206669be4B9Fcc0828;
        balances[exchanges] = 35000000 ether;
        emit Transfer(address(0x0), exchanges, balances[exchanges]);

        // Platform wallet - 212500000 tokens
        // 62500000 tokens free, 150000000 tokens locked - progressive release of 25000000 every 90 days
        address platformWallet = 0xBEa5f83a8Cd3D8Ff24aF97821c0a93857F07aa9a;
        balances[platformWallet] = 212500000 ether;
        timeLocks[platformWallet] = TimeLock(150000000 ether, 150000000 ether, uint128(lockStartDate), 90 days, 25000000);
        emit Transfer(address(0x0), platformWallet, balances[platformWallet]);        

    }
    
    function transfer(address _to, uint256 _value) override public returns (bool success) {
        require(checkTransferLimit(), "Transfers are limited to 1 per block");
        require(_value <= (balances[_msgSender()] - timeLocks[_msgSender()].lockedBalance));
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(checkTransferLimit(), "Transfers are limited to 1 per block");
        require(_value <= (balances[_from] - timeLocks[_from].lockedBalance));
        return super.transferFrom(_from, _to, _value);
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balances[_msgSender()] >= _value, "Not enough balance");
		require(_value >= 0, "Invalid amount"); 
        balances[_msgSender()] = balances[_msgSender()].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(_msgSender(), _value);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        allowed[_msgSender()][_spender] = _value;
        emit Approval(_msgSender(), _spender, _value);
        ItokenRecipient recipient = ItokenRecipient(_spender);
        require(recipient.receiveApproval(_msgSender(), _value, address(this), _extraData));
        return true;
    }
    

    function releaseTokens(address _account) public {
        uint256 timeDiff = block.timestamp - uint256(timeLocks[_account].baseDate);
        require(timeDiff > uint256(timeLocks[_account].step), "Unlock point not reached yet");
        uint256 steps = (timeDiff / uint256(timeLocks[_account].step));
        uint256 unlockableAmount = ((uint256(timeLocks[_account].tokensStep) * 1 ether) * steps);
        if (unlockableAmount >=  timeLocks[_account].totalAmount) {
            timeLocks[_account].lockedBalance = 0;
        } else {
            timeLocks[_account].lockedBalance = timeLocks[_account].totalAmount - unlockableAmount;
        }
    }
    
       
    function checkTransferLimit() internal returns (bool txAllowed) {
        address _caller = _msgSender();
        if (limitTransactions == true && contractsWhiteList[_caller] != true) {
            if (lastTXBlock[_caller] == block.number) {
                return false;
            } else {
                lastTXBlock[_caller] = block.number;
                return true;
            }
        } else {
            return true;
        }
    }
    
    function enableTXLimit() public onlyOwner {
        limitTransactions = true;
    }
    
    function disableTXLimit() public onlyOwner {
        limitTransactions = false;
    }
    
    function includeWhiteList(address _contractAddress) public onlyOwner {
        contractsWhiteList[_contractAddress] = true;
    }
    
    function removeWhiteList(address _contractAddress) public onlyOwner {
        contractsWhiteList[_contractAddress] = false;
    }
    
    function getLockedBalance(address _wallet) public view returns (uint256 lockedBalance) {
        return timeLocks[_wallet].lockedBalance;
    }
    
    function buy() public payable {
        require((block.timestamp > CROWDSALE_START) && (block.timestamp < CROWDSALE_END), "Contract is not selling tokens");
        uint weiValue = msg.value;
        require(weiValue >= (5 * (10 ** 16)), "Minimum amount is 0.05 eth");
        require(weiValue <= (20 ether), "Maximum amount is 20 eth");
        uint amount = CSALE_WEI_FACTOR * weiValue;
        uint256 amountLocked = amount / 2; 
        uint256 unlockAmount = ((5 * amountLocked) / 100) / 1000000000000000000;
        uint128 startTime = 1630454400;

        require((soldOnCSale) <= (CSALE_HARDCAP), "That quantity is not available");
        soldOnCSale += amount;
        // timeLocks[_msgSender()] = TimeLock(amountLocked, amountLocked, startTime, 3 minutes, uint256(unlockAmount));
        timeLocks[_msgSender()].totalAmount += amountLocked;
        timeLocks[_msgSender()].lockedBalance += amountLocked;
        timeLocks[_msgSender()].baseDate = startTime;
        timeLocks[_msgSender()].step = 3 minutes;
        timeLocks[_msgSender()].tokensStep += uint256(unlockAmount);
        balances[salesWallet] = balances[salesWallet].sub(amount);
        balances[_msgSender()] = balances[_msgSender()].add(amount);
        require(salesWallet.send(weiValue));
        emit Transfer(salesWallet, _msgSender(), amount);
    }

    // function buy() public payable {
    //     require((block.timestamp > CROWDSALE_START) && (block.timestamp < CROWDSALE_END), "Contract is not selling tokens");
    //     uint weiValue = msg.value;
    //     require(weiValue >= (100 ether), "Minimum amount is 100 MATIC");
    //     require(weiValue <= (50000 ether), "Maximum amount is 50000 MATIC");
    //     uint amount = CSALE_WEI_FACTOR * weiValue; //
    //     uint256 amountLocked = amount / 2; 
    //     uint256 unlockAmount = ((5 * amountLocked) / 100) / 1000000000000000000;
    //     uint128 startTime = 1630454400;
    //     require((soldOnCSale) <= (CSALE_HARDCAP), "That quantity is not available");
    //     soldOnCSale += amount;
    //     // timeLocks[_msgSender()] = TimeLock(amountLocked, amountLocked, startTime, 3 minutes, uint256(unlockAmount));
    //     timeLocks[_msgSender()].totalAmount += amountLocked;
    //     timeLocks[_msgSender()].lockedBalance += amountLocked;
    //     timeLocks[_msgSender()].baseDate = startTime;
    //     timeLocks[_msgSender()].step = 3 minutes;
    //     timeLocks[_msgSender()].tokensStep += uint256(unlockAmount);

    //     _transfer(salesWallet, _msgSender(), amount);
    //     Address.sendValue(payable(salesWallet), weiValue);
    // }

    
    function burnUnsold() public onlyOwner {
        require(block.timestamp > CROWDSALE_END);
        uint currentBalance = balances[salesWallet];
        balances[salesWallet] = 0;
        _totalSupply = _totalSupply.sub(currentBalance);
        emit Burn(salesWallet, currentBalance);
    }
}