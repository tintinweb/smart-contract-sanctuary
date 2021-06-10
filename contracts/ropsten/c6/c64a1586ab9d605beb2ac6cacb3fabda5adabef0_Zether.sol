/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT

//--------------------------------------------------------------------------------------
//
//Author by Azrehargun
//
//--------------------------------------------------------------------------------------

pragma solidity ^0.5.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b; assert(a == 0 || c / a == b); return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b; return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a); return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; assert(c >= a); return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0); return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory){
        require(isContract(target));
        return functionCall(target, data);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory){
        require(isContract(target));
        return functionCallWithValue(target, data, value);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory){
        require(isContract(target));
        return functionStaticCall(target, data);
    }
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data);
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            // Delete the slot where the moved value was stored
            set._values.pop();
            // Delete the index for the deleted slot
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract Ownable {
    address payable public owner;
    address payable public newOwner;
    modifier onlyOwner {require(msg.sender == owner);_;}
    function transferOwnership(address payable _newOwner) public onlyOwner {newOwner = _newOwner;}
    function acceptOwnership() public {require(msg.sender == newOwner); owner = newOwner;}
}

contract Destructible is Ownable {}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed account, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {}
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeIBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)));
        }
    }
}

contract TimeLockedWallet {
    address internal vault;
    uint256 internal unlockDate;
    uint256 internal timelockStart;
}

contract ProofOfStakeProtocol {
    uint256 public stakeStartTime;
    uint256 public proofOfStakeRewards;
    function deposit(address to, uint256 value) public;
    function withdraw(address to, uint256 value) public;
    function claimStakingReward() public;
    event ProofOfStakeMinting(address indexed _address, uint256 _stakeMinting);
    event Deposit(address indexed _address, uint256 value);
    event Withdraw(address indexed _address, uint256 value);
}

contract ProofOfAgeProtocol {
    uint256 public coinAgeStartTime;
    uint256 public proofOfAgeRewards;
    uint256 internal minimumAge;
    uint256 internal maximumAge;
    function proofOfAgeMinting() public returns (bool);
    function coinAge() internal view returns (uint);
    function annualCoinAgeRate() internal view returns (uint256);
    event ProofOfAgeMinting(address indexed _address, uint256 _coinAgeMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract Zether is ERC20, ProofOfAgeProtocol, ProofOfStakeProtocol, TimeLockedWallet, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public name = "Zether";
    string public symbol = "ZETHER";
    uint public decimals = 18;

    uint256 public totalSupply;
    uint256 public maxTotalSupply;
    uint256 internal circulatingSupply;
    
    uint256 internal chainStartTime; //Chain start time
    uint256 internal chainStartBlockNumber; //Chain start block number
    
    //Contract owner can not trigger internal Proof-of-Age minting
    address internal contractOwner = 0x5b37A82BA40D897f75e5609CFAb189B3418B00Ab;
    
    //Team and developer can not trigger internal Proof-of-Age minting
    address internal teamDevs = 0xB3fbDDf0126175B2EbAE1364D58D6e2851f24D6D;
    
    //Vault wallet locked automatically until specified time 
    //Vault wallet can not trigger internal Proof-of-Age minting
    address internal vault = 0x6c9837778FD411490bf1EBd6b73d2e0f68CD59Fa;
    
    uint256 internal timelockStart;
    uint256 internal unlockDate = 1623376297;
    
    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    constructor() public {
        owner = msg.sender;
        maxTotalSupply = 1000000000 * (10**decimals); //1 Billion
        circulatingSupply = 4000000 * (10**decimals); //4 Million
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = circulatingSupply;
        totalSupply = circulatingSupply;
        timelockStart = now;
    }

//--------------------------------------------------------------------------------------
//ERC20 function
//--------------------------------------------------------------------------------------
    
    function transfer(address to, uint256 value) onlyPayloadSize(2 * 32) external returns (bool) {
        require(balances[msg.sender] > 0, "Token holder cannot transfer if balances is 0");
        if(balances[msg.sender] <= 0) revert();
        
        //--------------------------------------------------------------
        //Function to trigger internal Proof-of-Age minting :
        //--------------------------------------------------------------
        //Send transaction with 0 amount of token
        //to same address that stored token
        //Best option wallet is Metamask. 
        //It's pretty easy.
        //--------------------------------------------------------------
        
        if(msg.sender == to && balances[msg.sender] > 0) return proofOfAgeMinting();
        if(msg.sender == to && balances[msg.sender] <= 0) revert();
        if(msg.sender == to && coinAgeStartTime < 0) revert();
        if(msg.sender == to && contractOwner == msg.sender) revert();
        if(msg.sender == to && teamDevs == msg.sender) revert();
        if(msg.sender == to && vault == msg.sender) revert();
        if(operator[to] && operator[msg.sender] == true) revert();
        
        if(msg.sender == to && coinAgePaused == true) revert();
        
        //Blacklist cannot transfer tokens
        //Blacklist cannot trigger internal Proof-of-Age minting
        
        if(blacklist[msg.sender] == true) revert();
        if(blacklist[to] && blacklist[msg.sender] == true) revert();
        if(blacklist[to]) revert();
        
        //Locked wallets cannot make transfers after specified time
        
        if(vault == msg.sender && now < unlockDate) revert();
        if(vault == msg.sender && now >= unlockDate) unlockDate = 0;
        
        //Function to deducting a transfer fees from transfering token
        
        uint256 tokensFee = value.mul(tokenTax).div(1e4); {
            
            //Excluded addresses from being deducting a transfer fees
            
            if(contractOwner == msg.sender) tokensFee = 0;
            if(teamDevs == msg.sender) tokensFee = 0;
            if(vault == msg.sender) tokensFee = 0;
            if(tokenContract == msg.sender) tokensFee = 0;
            if(address(0) == msg.sender) tokensFee = 0;
            if(excluded[msg.sender] == true) tokensFee = 0;
            if(operator[msg.sender] == true) tokensFee = 0;
        }
        
        uint256 shareFee = value.mul(shareTax).div(1e4); {
            
            //Excluded addresses from being deducting a transfer fees
            
            if(contractOwner == msg.sender) shareFee = 0;
            if(teamDevs == msg.sender) shareFee = 0;
            if(vault == msg.sender) shareFee = 0;
            if(tokenContract == msg.sender) shareFee = 0;
            if(address(0) == msg.sender) shareFee = 0;
            if(excluded[msg.sender] == true) shareFee = 0;
            if(operator[msg.sender] == true) shareFee = 0;
        }

        uint256 valueAfterFee = value.sub(tokensFee).sub(shareFee);
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(valueAfterFee);
        proofOfAgeRewards = proofOfAgeRewards.add(tokensFee);
        
        address _shareReceiver = getShareReceiverAddress();

        emit Transfer(msg.sender, to, valueAfterFee);
        emit TokenTransfer(msg.sender, tokensFee);
        emit ShareTransfer(msg.sender, _shareReceiver, shareFee);
        
        //Function to reset coin age to zero for tokens receiver.

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));

        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) onlyPayloadSize(3 * 32) external returns (bool) {
        require(balances[from] > 0, "Token holder cannot transfer if balances is 0");
        require(balances[from] >= value, "Token holder does not have enough balance");
        require(allowed[from][msg.sender] >= value, "Token holder does not have enough balance");
        
        //Locked wallet cannot make transfers after specified time
        
        if(vault == from && now < unlockDate) revert();
        if(vault == from && now >= unlockDate) unlockDate = 0;
        
        //Blacklist cannot transfer tokens
        //Blacklist cannot receive tokens
        
        if(blacklist[to]) revert();
        if(blacklist[from]) revert();
        
        uint256 allowance = allowed[from][msg.sender];
        allowed[from][msg.sender] = allowance.sub(value);
        
        //Function to deducting a transfer fees from transfering token
        
        uint256 tokensFee = value.mul(tokenTax).div(1e4); {
            
            //Excluded addresses from being deducting a transfer fees
            
            if(contractOwner == msg.sender) tokensFee = 0;
            if(teamDevs == msg.sender) tokensFee = 0;
            if(vault == msg.sender) tokensFee = 0;
            if(tokenContract == msg.sender) tokensFee = 0;
            if(tokenContract == to) tokensFee = 0;
            if(address(0) == msg.sender) tokensFee = 0;
            if(excluded[msg.sender] == true) tokensFee = 0;
            if(operator[msg.sender] == true) tokensFee = 0;
        }
        
        uint256 shareFee = value.mul(shareTax).div(1e4); {
            
            //Excluded addresses from being deducting a transfer fees
            
            if(contractOwner == msg.sender) shareFee = 0;
            if(teamDevs == msg.sender) shareFee = 0;
            if(vault == msg.sender) shareFee = 0;
            if(tokenContract == msg.sender) shareFee = 0;
            if(tokenContract == to) shareFee = 0;
            if(address(0) == msg.sender) shareFee = 0;
            if(excluded[msg.sender] == true) shareFee = 0;
            if(operator[msg.sender] == true) shareFee = 0;
        }

        uint256 valueAfterFee = value.sub(tokensFee).sub(shareFee);
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(valueAfterFee);
        proofOfAgeRewards = proofOfAgeRewards.add(tokensFee);
        
        address _shareReceiver = getShareReceiverAddress();
        
        emit Transfer(from, to, valueAfterFee);
        emit TokenTransfer(from, tokensFee);
        emit ShareTransfer(msg.sender, _shareReceiver, shareFee);
        
        //Function to reset coin age to zero for tokens receiver.
        
        if(transferIns[from].length > 0) delete transferIns[from];
        uint64 _now = uint64(now);
        transferIns[from].push(transferInStruct(uint128(balances[from]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256 balance) {
        return balances[account];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        if(blacklist[msg.sender] == true) revert();
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address account, address spender) external view returns (uint256) {
        if(blacklist[account] == true) revert();
        return allowed[account][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        if(blacklist[msg.sender] == true) revert();
        emit Approval(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        if(blacklist[msg.sender] == true) revert();
        emit Approval(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function burn(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        balances[msg.sender] = balances[msg.sender].sub(value);
        maxTotalSupply = maxTotalSupply.sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(account, address(0), value);
    }

    function mint(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        balances[msg.sender] = balances[msg.sender].add(value);
        totalSupply = totalSupply.add(value);
        emit Transfer(address(0), msg.sender, value);
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Age minting protocol function
//--------------------------------------------------------------------------------------

    uint256 public proofOfAgeRewards;
    uint256 public coinAgeStartTime; //Coin age start time

    uint256 internal coinAgeBaseRate = 10**17; //Base rate minting
    uint256 internal minimumAge = 1 days; //Minimum Age for minting : 1 day
    uint256 internal maximumAge = 90 days; //Age of full weight : 90 days
    
    modifier ProofOfAgeMinter() {
        require(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] > 0);
        _;
    }
    
    function proofOfAgeMinting() ProofOfAgeMinter public returns (bool) {
        require(balances[msg.sender] > 0);
        require(coinAgePaused == false);
        if(coinAgePaused == true) revert();
        
        if(balances[msg.sender] <= 0) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        
        //Excluded addresses from triggering internal Proof-of-Age minting

        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        if(vault == msg.sender) revert();
        if(operator[msg.sender] == true) revert();
        if(blacklist[msg.sender] == true) revert();
        
        uint256 coinAgeMinting = getProofOfAgeMinting(msg.sender);

        if(proofOfAgeRewards <= 0) return false;
        if(proofOfAgeRewards == maxTotalSupply) return false;
        
        assert(coinAgeMinting <= proofOfAgeRewards);
        
        totalSupply = totalSupply.add(coinAgeMinting);
        proofOfAgeRewards = proofOfAgeRewards.sub(coinAgeMinting);
        balances[msg.sender] = balances[msg.sender].add(coinAgeMinting);
        
        //Function to reset coin age to zero after receiving minting token
        //and token holders must hold for certain period of time again
        //before triggering internal Proof-of-Age minting protocol.
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Transfer(address(0), msg.sender, coinAgeMinting);
        emit ProofOfAgeMinting(msg.sender, coinAgeMinting);
        
        return true;
    }

    function annualCoinAgeRate() internal view returns (uint coinAgeRate) {
        coinAgeRate = coinAgeBaseRate;
        
        //Annual minting rate is 100%
        //once circulating supply less 25 million
        
        if(totalSupply < 25000000 * (10**decimals)) {
            coinAgeRate = (1000 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 50% once circulating supply
        //over 25 million - less than 50 million
        
        } else if(totalSupply >= 25000000 * (10**decimals) && totalSupply < 50000000 * (10**decimals)) {
            coinAgeRate = (500 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 25% once circulating supply
        //over 50 million - less than 75 million
        
        } else if(totalSupply >= 50000000 * (10**decimals) && totalSupply < 75000000 * (10**decimals)) {
            coinAgeRate = (250 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 12.5% once circulating supply
        //over 75 million - less than 100 million
        
        } else if(totalSupply >= 75000000 * (10**decimals) && totalSupply < 100000000 * (10**decimals)) {
            coinAgeRate = (125 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 10% once circulating supply
        //over 100 million - less than 250 million
        
        } else if(totalSupply >= 100000000 * (10**decimals) && totalSupply < 250000000 * (10**decimals)) {
            coinAgeRate = (100 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 5% once circulating supply
        //over 250 million - less than 500 million
        
        } else if(totalSupply >= 250000000 * (10**decimals) && totalSupply < 500000000 * (10**decimals)) {
            coinAgeRate = (50 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 2.5% once circulating supply
        //over 500 million - less than 750 million
        
        } else if(totalSupply >= 500000000 * (10**decimals) && totalSupply < 750000000 * (10**decimals)) {
            coinAgeRate = (25 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 1% once circulating supply
        //over 750 million
        
        } else if(totalSupply >= 750000000 * (10**decimals)) {
            coinAgeRate = (10 * coinAgeBaseRate).div(100);
        }
    }

    function getProofOfAgeMinting(address _address) internal view returns (uint) {
        require((now >= coinAgeStartTime) && (coinAgeStartTime > 0));
        require(coinAgePaused == false);
        if(coinAgePaused == true) revert();
        uint _now = now;
        uint _coinAge = getProofOfAge(_address, _now);
        if(_coinAge <= 0) return 0;
        uint coinAgeRate = coinAgeBaseRate;
        
        //Annual minting rate is 100%
        //once circulating supply less 25 million
        
        if(totalSupply < 25000000 * (10**decimals)) {
            coinAgeRate = (1000 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 50% once circulating supply
        //over 25 million - less than 50 million
        
        } else if(totalSupply >= 25000000 * (10**decimals) && totalSupply < 50000000 * (10**decimals)) {
            coinAgeRate = (500 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 25% once circulating supply
        //over 50 million - less than 75 million
        
        } else if(totalSupply >= 50000000 * (10**decimals) && totalSupply < 75000000 * (10**decimals)) {
            coinAgeRate = (250 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 12.5% once circulating supply
        //over 75 million - less than 100 million
        
        } else if(totalSupply >= 75000000 * (10**decimals) && totalSupply < 100000000 * (10**decimals)) {
            coinAgeRate = (125 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 10% once circulating supply
        //over 100 million - less than 250 million
        
        } else if(totalSupply >= 100000000 * (10**decimals) && totalSupply < 250000000 * (10**decimals)) {
            coinAgeRate = (100 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 5% once circulating supply
        //over 250 million - less than 500 million
        
        } else if(totalSupply >= 250000000 * (10**decimals) && totalSupply < 500000000 * (10**decimals)) {
            coinAgeRate = (50 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 2.5% once circulating supply
        //over 500 million - less than 750 million
        
        } else if(totalSupply >= 500000000 * (10**decimals) && totalSupply < 750000000 * (10**decimals)) {
            coinAgeRate = (25 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 1% once circulating supply
        //over 750 million
        
        } else if(totalSupply >= 750000000 * (10**decimals)) {
            coinAgeRate = (10 * coinAgeBaseRate).div(100);
        }
        //Approximately 30 - 35 years
        return (_coinAge * coinAgeRate).div(365 * (10**decimals));
    }
    
    function coinAge() internal view returns (uint myCoinAge) {
        myCoinAge = getProofOfAge(msg.sender, now);
    }

    function getProofOfAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(minimumAge)) continue;
            uint coinAgeSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(coinAgeSeconds > maximumAge) coinAgeSeconds = maximumAge;
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * coinAgeSeconds.div(1 days));
        }
    }
    
    function getBlockNumber() internal view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

//--------------------------------------------------------------------------------------
//Set function for Proof-of-Age minting protocol
//--------------------------------------------------------------------------------------
    
    event ChangeCoinAgeRate(uint256 value);
    
    function setProofOfAgeRewards(uint256 value) public onlyOwner onlyOperator {
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        proofOfAgeRewards = proofOfAgeRewards.add(value);
    }
    
    function cutProofOfAgeRewards(uint256 value) public onlyOwner onlyOperator {
        proofOfAgeRewards = proofOfAgeRewards.sub(value);
    }
    
    function setMinimumAge(uint timestamp) public onlyOwner onlyOperator {
        minimumAge = timestamp;
    }
    
    function setMaximumAge(uint timestamp) public onlyOwner onlyOperator {
        maximumAge = timestamp;
    }
    
    function coinAgeInfo(address account) public view returns (address, uint myCoinAge) {
        myCoinAge = getProofOfAge(msg.sender, now);
        return (account, myCoinAge);
    }
    
    function changeCoinAgeRate(uint256 _coinAgeBaseRate) public onlyOwner onlyOperator {
        coinAgeBaseRate = _coinAgeBaseRate;
        emit ChangeCoinAgeRate(coinAgeBaseRate);
    }

//--------------------------------------------------------------------------------------
//Pause and continue internal Proof-of-Age minting protocol function
//--------------------------------------------------------------------------------------

    bool public coinAgePaused;
    
    function coinAgeMintingStart() public onlyOwner {
        require(msg.sender == owner && coinAgeStartTime == 0);
        coinAgeStartTime = now;
    }
    
    function coinAgeContinue() public onlyOwner onlyOperator {
        coinAgePaused = false;
    }
    
    function coinAgePause() public onlyOwner onlyOperator {
        coinAgePaused = true;
    }

    function isCoinAgePaused() public view returns (bool) {
        return coinAgePaused;
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Stake minting function
//--------------------------------------------------------------------------------------
    
    address internal stakeTokenAddress;
    address internal tokenContract = address(this);

    uint256 public proofOfStakeRewards;
    uint256 public stakeStartTime; //Staking start time
    uint256 public minimumStake; //Mininum tokens to Stake
    
    uint256 internal stakeRate = 5000;
    uint internal constant rewardInterval = 365 days;
    
    uint256 public totalParticipant = 0;
    uint256 public totalClaimedRewards = 0;
    
    event ChangeStakeRate(uint256 value);
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;

    function deposit(address to, uint256 stakingAmount) public {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        require(stakingAmount >= minimumStake, "Cannot deposit less than minimum stake");
        require(ERC20(stakeTokenAddress).transfer(tokenContract, stakingAmount));

        require(stakePaused == false);
        if(stakePaused == true) revert();
        
        //Excluded addresses to deposit
        
        if(blacklist[msg.sender] == true) revert();
        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        if(vault == msg.sender) revert();
        if(blacklist[msg.sender] == true) revert();
        if(operator[msg.sender] == true) revert();
        
        uint256 tokensFee = stakingAmount.mul(tokenTax).div(1e4);{
            if(tokenContract == to) tokensFee = 0;
        }
        
         uint256 shareFee = stakingAmount.mul(shareTax).div(1e4);{
            if(tokenContract == to) shareFee = 0;
        }
        
        updateAccount(msg.sender);
        
        stakingAmount = depositedTokens[msg.sender];
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(stakingAmount);
        balances[address(tokenContract)] = balances[address(tokenContract)].add(stakingAmount);
        balances[msg.sender] = balances[msg.sender].sub(stakingAmount);
        
        if(stakingAmount >= minimumStake) totalParticipant = totalParticipant.add(1);
        if(stakingAmount >= minimumStake) stakingTime[msg.sender] = now;
        
        emit Deposit(address(tokenContract), stakingAmount);
        emit Transfer(msg.sender, address(tokenContract), stakingAmount);
        emit Approval(msg.sender, address(tokenContract), allowed[msg.sender][address(tokenContract)].sub(stakingAmount));
    }
    
    function withdraw(address to, uint256 withdrawAmount) public {
        require(depositedTokens[msg.sender] >= withdrawAmount, "Invalid amount to withdraw");
        require(ERC20(stakeTokenAddress).transfer(msg.sender, withdrawAmount));

        uint256 tokensFee = withdrawAmount.mul(tokenTax).div(1e4);{
            if(msg.sender == to) tokensFee = 0;
        }
        
         uint256 shareFee = withdrawAmount.mul(shareTax).div(1e4);{
            if(msg.sender == to) shareFee = 0;
        }
        
        updateAccount(msg.sender);
        
        withdrawAmount = depositedTokens[msg.sender];
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(withdrawAmount);
        balances[address(tokenContract)] = balances[address(tokenContract)].sub(withdrawAmount);
        balances[msg.sender] = balances[msg.sender].add(withdrawAmount);
        
        if(depositedTokens[msg.sender] < minimumStake) totalParticipant = totalParticipant.sub(1);
        if(depositedTokens[msg.sender] < minimumStake) stakingTime[msg.sender] = 0;
        
        emit Withdraw(msg.sender, withdrawAmount);
        emit Transfer(address(tokenContract), msg.sender, withdrawAmount);
        
        //Function to reset coin age to zero for tokens receiver.

        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
    }
    
    function claimStakingReward() public {
        updateAccount(msg.sender);
    }

    function updateAccount(address account) public {
        if(blacklist[msg.sender] == true) revert();
        uint stakeMinting = getStakeRewards(account);
        
        totalEarnedTokens[account] = totalEarnedTokens[account].add(stakeMinting);
        totalClaimedRewards = totalClaimedRewards.add(stakeMinting);
        
        emit Transfer(address(0), account, stakeMinting);
        emit ProofOfStakeMinting(account, stakeMinting);
        
        lastClaimedTime[account] = now;
        
        //Function to reset coin age to zero for tokens receiver.
        
        delete transferIns[account];
        transferIns[account].push(transferInStruct(uint128(balances[account]),uint64(now)));
    }
    
    function getStakeRewards(address _holder) public view returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        require(stakePaused == false);
        if(stakePaused == true) revert();
        if(depositedTokens[_holder] < minimumStake) return 0;
        
        uint timeDiff = now.sub(lastClaimedTime[_holder]);
        uint stakeAmount = depositedTokens[_holder];
        uint stakingRate = stakeRate;
        
        if(totalParticipant < 2500) {
            stakingRate = stakeRate.mul(2); //100%
            
        } else if(totalParticipant >= 2500 && totalParticipant < 5000) {
            stakingRate = stakeRate.mul(1); //50%
            
        } else if(totalParticipant >= 5000 && totalParticipant < 10000) {
            stakingRate = stakeRate.div(2); //25%
            
        } else if(totalParticipant >= 10000 && totalParticipant < 25000) {
            stakingRate = stakeRate.div(4); //12.5%
            
        } else if(totalParticipant >= 25000 && totalParticipant < 50000) {
            stakingRate = stakeRate.div(8); //6.25%
            
        } else if(totalParticipant >= 50000) {
            stakingRate = stakeRate.div(16); //3.125%
        }
        
        uint stakeMinting = stakeAmount.mul(stakingRate).mul(timeDiff).div(rewardInterval).div(1e4);
        return stakeMinting;
    }
    
    function getStakeMintingRewards() public view returns (uint) {
        if(totalClaimedRewards >= proofOfStakeRewards) return 0;
        uint remaining = proofOfStakeRewards.sub(totalClaimedRewards);
        return remaining;
    }
    
    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }
    
    function getTotalParticipant() public view returns (uint) {
        return totalParticipant;
    }
    
    function tokenWithdraw(uint256 value) public onlyOwner {
        balances[address(this)] = balances[address(this)].sub(value);
        balances[msg.sender] = balances[msg.sender].add(value);
        
        emit Transfer(address(this), msg.sender, value);
        
        //Function to reset coin age to zero for tokens receiver.

        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
    }

    function setStakeTokenAddress(address _stakeTokenAddress) public onlyOwner onlyOperator {
        stakeTokenAddress = _stakeTokenAddress;
    }

//--------------------------------------------------------------------------------------
//Pause and continue Proof-of-Stake minting protocol function
//--------------------------------------------------------------------------------------
    
    bool public stakePaused;
    
    function stakeMintingStart() public onlyOwner {
        require(msg.sender == owner && stakeStartTime == 0);
        stakeStartTime = now;
    }
    
    function stakeContinue() public onlyOwner onlyOperator {
        stakePaused = false;
    }
    
    function stakePause() public onlyOwner onlyOperator {
        stakePaused = true;
    }

    function isStakePaused() public view returns (bool) {
        return stakePaused;
    }
    
//--------------------------------------------------------------------------------------
//Set function for Proof-of-Stake minting protocol
//--------------------------------------------------------------------------------------
    
    function setProofOfStakeReward(uint256 value) public onlyOwner onlyOperator {
        proofOfStakeRewards = proofOfStakeRewards.add(value);
    }
    
    function cutProofOfStakeReward(uint256 value) public onlyOwner onlyOperator {
        proofOfStakeRewards = proofOfStakeRewards.sub(value);
    }
    
    function setMinimumStake(uint256 _minimumStake) public onlyOwner onlyOperator {
        minimumStake = _minimumStake;
    }
    
    function changeStakeRate(uint256 _stakeRate) public onlyOwner onlyOperator {
        stakeRate = _stakeRate;
        emit ChangeStakeRate(stakeRate);
    }

//--------------------------------------------------------------------------------------
//Timelock wallet function
//--------------------------------------------------------------------------------------

    function timelockWallet(address _vault, uint256 _unlockDate) internal {
        vault = _vault; timelockStart = now; unlockDate = _unlockDate;
    }
    
    function lockExtended(uint timestamp) public onlyOwner {
        require(now >= unlockDate);
        unlockDate = timestamp;
    }
    
    function lockInfo() public view returns(address, uint256, uint256) {
        return (vault, timelockStart, unlockDate);
    }

//--------------------------------------------------------------------------------------
//Exclude addresses status / revoking exclude addresses status function
//--------------------------------------------------------------------------------------
    
    mapping(address => bool) excluded;
    
    function shareExcluded(address account) public onlyOwner {
        excluded[account] = true;
    }
    
    function shareRevoke(address account) public onlyOwner {
        excluded[account] = false;
    }
    
    function isExcluded(address account) public view returns (bool) {
        return excluded[account];
    }

//--------------------------------------------------------------------------------------
//Marking blacklist addresses status / revoking blacklist addresses status function
//--------------------------------------------------------------------------------------

    mapping(address => bool) blacklist;
    
    function blacklistTag(address account) public onlyOwner {
        blacklist[account] = true;
    }
    
    function blacklistRevoke(address account) public onlyOwner {
        blacklist[account] = false;
    }
    
    function isBlacklist(address account) public view returns (bool) {
        return blacklist[account];
    }

//--------------------------------------------------------------------------------------
//Add and remove operator function
//--------------------------------------------------------------------------------------

    mapping(address => bool) operator;

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }
    
    function addOperator(address account) public onlyOwner {
        operator[account] = true;
    }
    
    function removeOperator(address account) public onlyOwner {
        operator[account] = false;
    }
    
    function isOperator(address account) public view returns (bool) {
        return operator[account];
    }
    
//--------------------------------------------------------------------------------------
//Sharing function
//--------------------------------------------------------------------------------------
    
    event TokenTransfer(address indexed from, uint256 value);
    event ChangeTokenTax(uint256 value);
    
    uint256 public tokenTax = 250; //Transfer fee is 2,5%
    
    function changeTokenTax(uint256 _tokenTax) public onlyOwner onlyOperator {
        tokenTax = _tokenTax;
        emit ChangeTokenTax(tokenTax);
    }

    event ShareTransfer(address indexed from, address receiver, uint256 value);
    event ChangeShareTax(uint256 value);

    address public shareReceiver;
    uint256 public shareTax = 250; //Share fee is 2,5%
    uint256 public tokenStored;

    function registerShareReceiver(address _addr) public {
        require(balances[msg.sender] >= tokenStored);
        
        //Excluded addresses to register as share receiver
        
        if(blacklist[msg.sender] == true) revert();
        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        if(vault == msg.sender) revert();
        if(blacklist[msg.sender] == true) revert();
        if(operator[msg.sender] == true) revert();
        
        shareReceiver = _addr;
    }

    function getShareReceiverAddress() public view returns(address) {
        return shareReceiver;
    }
    
    function changeShareTax(uint256 _shareTax) public onlyOwner onlyOperator {
        shareTax = _shareTax;
        emit ChangeShareTax(shareTax);
    }

//--------------------------------------------------------------------------------------
//Multi / bulk transfer function
//--------------------------------------------------------------------------------------
    
    function multiTransfer(address[] memory recipients, uint[] memory values) onlyOwner public returns (bool) {
        require(recipients.length > 0 && recipients.length == values.length);
        uint total = 0; for(uint i = 0; i < values.length; i++) {total = total.add(values[i]);}
        
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);
        
        for(uint j = 0; j < recipients.length; j++){
            balances[recipients[j]] = balances[recipients[j]].add(values[j]);
            transferIns[recipients[j]].push(transferInStruct(uint128(values[j]),_now));
            emit Transfer(msg.sender, recipients[j], values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        if(balances[msg.sender] > 0) transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));

        return true;
    }

//--------------------------------------------------------------------------------------
//Presale function
//--------------------------------------------------------------------------------------
    
    event Purchase(address indexed _purchaser, uint256 _purchasedAmount, uint256 _bonusAmount);
    event ChangePriceRate (uint256 value);
    
    uint internal startDate;
    bool internal closed;
    
    uint256 internal presaleSupply = 400000 * (10**decimals);
    uint256 internal bonusPurchase = 200000 * (10**decimals);
    
    uint256 internal priceRate = 2000;
    uint256 internal constant minimumPurchase = 0.1 ether; //Minimum purchase
    uint256 internal constant maximumPurchase = 100 ether; //Maximum purchase

    function() external payable {
        uint purchasedAmount = msg.value * priceRate;
        uint bonusAmount = purchasedAmount.div(2);
        
        owner.transfer(msg.value);

        require((now >= startDate) && (startDate > 0));
        require(msg.value >= minimumPurchase && msg.value <= maximumPurchase);
        require(purchasedAmount <= presaleSupply, "Not have enough available tokens");
        assert(purchasedAmount <= presaleSupply);
        assert(bonusAmount <= bonusPurchase);
        
        if(purchasedAmount > presaleSupply) revert();
        if(msg.value == 0) revert();
        if(presaleSupply == 0) revert();
        
        totalSupply = circulatingSupply.add(purchasedAmount + bonusAmount);
        
        presaleSupply = presaleSupply.sub(purchasedAmount);
        bonusPurchase = bonusPurchase.sub(bonusAmount);
        
        balances[msg.sender] = balances[msg.sender].add(purchasedAmount);
        balances[msg.sender] = balances[msg.sender].add(bonusAmount);
        
        require(!closed);
        
        emit Transfer(address(0), msg.sender, purchasedAmount);
        emit Transfer(address(0), msg.sender, bonusAmount);
        emit Purchase(msg.sender, purchasedAmount, bonusAmount);
    }
    
    function startSale() public onlyOwner {
        require(msg.sender == owner && startDate == 0);
        startDate = now;
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function setPresaleSupply(uint256 value) public onlyOwner {
        presaleSupply = presaleSupply.add(value);
    }
    
    function setBonusPurchase(uint256 value) public onlyOwner {
        bonusPurchase = bonusPurchase.add(value);
    }

    function changePriceRate(uint256 _priceRate) public onlyOwner {
        priceRate = _priceRate;
        emit ChangePriceRate(priceRate);
    }
}